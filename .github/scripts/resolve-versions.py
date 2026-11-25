#!/usr/bin/env python3
"""Resolve latest official MariaDB patch release, gosu release, and Go toolchain."""

from __future__ import annotations

import json
import os
import re
import sys
import urllib.error
import urllib.request
from pathlib import Path


def fetch_json(url: str, github_api: bool = False):
    headers = {"User-Agent": "dgcosenza-mariadb-docker-ci"}
    if github_api:
        headers["Accept"] = "application/vnd.github+json"
        headers["X-GitHub-Api-Version"] = "2022-11-28"
        token = os.environ.get("GH_TOKEN") or os.environ.get("GITHUB_TOKEN")
        if token:
            headers["Authorization"] = f"Bearer {token}"
    req = urllib.request.Request(url, headers=headers)
    with urllib.request.urlopen(req, timeout=30) as resp:
        return json.loads(resp.read().decode("utf-8"))


def url_ok(url: str) -> bool:
    req = urllib.request.Request(url, method="HEAD", headers={"User-Agent": "dgcosenza-mariadb-docker-ci"})
    try:
        with urllib.request.urlopen(req, timeout=20) as resp:
            return 200 <= resp.status < 400
    except urllib.error.HTTPError as exc:
        if exc.code == 405:
            req_get = urllib.request.Request(url, headers={"User-Agent": "dgcosenza-mariadb-docker-ci"})
            try:
                with urllib.request.urlopen(req_get, timeout=20) as resp2:
                    return 200 <= resp2.status < 400
            except Exception:
                return False
        return False
    except Exception:
        return False


def resolve_mariadb(major: str, override: str) -> tuple[str, str]:
    if override:
        return override, f"Manual override requested: MariaDB {override}."

    releases = fetch_json("https://api.github.com/repos/MariaDB/server/releases?per_page=100", github_api=True)
    pat = re.compile(r"^mariadb-" + re.escape(major) + r"\.(\d+)$")
    candidates: list[tuple[int, str, dict]] = []
    for rel in releases:
        if rel.get("draft") or rel.get("prerelease"):
            continue
        tag = rel.get("tag_name", "")
        m = pat.match(tag)
        if m:
            candidates.append((int(m.group(1)), tag.removeprefix("mariadb-"), rel))
    candidates.sort(key=lambda x: x[0], reverse=True)

    for _, ver, rel in candidates:
        repo_pkg = f"https://archive.mariadb.org/mariadb-{ver}/repo/debian/dists/trixie/InRelease"
        if url_ok(repo_pkg):
            notes = (rel.get("body") or "").strip()
            url = rel.get("html_url") or f"https://mariadb.com/kb/en/mariadb-{ver.replace('.', '')}-release-notes/"
            summary = f"Official MariaDB {ver} release ({url})."
            if notes:
                lines = [ln.strip() for ln in notes.splitlines() if ln.strip()][:8]
                summary += "\n\n" + "\n".join(lines)
            return ver, summary

    # Fallback: MariaDB REST API
    rest = fetch_json(f"https://downloads.mariadb.org/rest-api/mariadb/{major}/")
    for ver in rest.get("releases", {}).keys():
        if re.fullmatch(r"\d+\.\d+\.\d+", ver):
            repo_pkg = f"https://archive.mariadb.org/mariadb-{ver}/repo/debian/dists/trixie/InRelease"
            if url_ok(repo_pkg):
                return ver, f"Official MariaDB {ver} release from downloads.mariadb.org."

    raise SystemExit(f"ERROR: Could not resolve a MariaDB {major} release with Debian 13 (trixie) packages")


def resolve_gosu(override: str, default_ver: str) -> str:
    if override:
        return override
    try:
        rel = fetch_json("https://api.github.com/repos/tianon/gosu/releases/latest", github_api=True)
        tag = (rel.get("tag_name") or "").strip()
        if tag:
            return tag
    except Exception:
        pass
    return default_ver


def resolve_go(override: str, default_ver: str) -> str:
    if override:
        return override
    try:
        releases = fetch_json("https://go.dev/dl/?mode=json")
        for rel in releases:
            if not rel.get("stable"):
                continue
            ver = rel.get("version", "").removeprefix("go")
            if not re.fullmatch(r"\d+\.\d+(\.\d+)?", ver):
                continue
            hub_url = f"https://hub.docker.com/v2/repositories/library/golang/tags/{ver}-trixie"
            if url_ok(hub_url):
                return ver
    except Exception:
        pass
    return default_ver


def main() -> None:
    major = os.environ["MARIADB_MAJOR"]
    override_mariadb = os.environ.get("OVERRIDE_MARIADB", "").strip()
    override_gosu = os.environ.get("OVERRIDE_GOSU", "").strip()
    override_go = os.environ.get("OVERRIDE_GO", "").strip()
    default_gosu = os.environ.get("GOSU_VERSION_DEFAULT", "1.20")
    default_go = os.environ.get("GO_VERSION_DEFAULT", "1.27.4")

    mariadb_ver, release_notes = resolve_mariadb(major, override_mariadb)
    if not re.fullmatch(r"\d+\.\d+\.\d+", mariadb_ver):
        raise SystemExit(f"ERROR: Invalid MariaDB version format: {mariadb_ver}")

    gosu_ver = resolve_gosu(override_gosu, default_gosu)
    go_ver = resolve_go(override_go, default_go)

    prev = {}
    vpath = Path("versions.json")
    if vpath.exists():
        prev = json.loads(vpath.read_text(encoding="utf-8"))
    prev_track_ver = prev.get("tracks", {}).get(major, {}).get("version", "")
    prev_go = prev.get("go_version", "")
    prev_gosu = prev.get("gosu_version", "")

    changed = (mariadb_ver != prev_track_ver) or (go_ver != prev_go) or (gosu_ver != prev_gosu)
    changes_md = [
        f"# Upstream changes — MariaDB {major}",
        "",
        f"- **MariaDB {major}:** `{prev_track_ver or 'none'}` -> `{mariadb_ver}`",
        f"- **gosu:** `{prev_gosu or 'none'}` -> `{gosu_ver}`",
        f"- **Go toolchain (gosu builder):** `{prev_go or 'none'}` -> `{go_ver}`",
        f"- **Upstream version changed:** `{'yes' if changed else 'no'}`",
        "",
        "## Release notes",
        "",
        release_notes,
        "",
    ]
    Path(f"upstream-changes-{major}.md").write_text("\n".join(changes_md), encoding="utf-8")

    gh_out = os.environ.get("GITHUB_OUTPUT")
    outputs = {
        "mariadb_version": mariadb_ver,
        "mariadb_major": major,
        "gosu_version": gosu_ver,
        "go_version": go_ver,
        "prev_mariadb_version": prev_track_ver,
        "upstream_changed": "true" if changed else "false",
    }
    if gh_out:
        with open(gh_out, "a", encoding="utf-8") as fh:
            for k, v in outputs.items():
                fh.write(f"{k}={v}\n")
    for k, v in outputs.items():
        print(f"{k}={v}")


if __name__ == "__main__":
    main()
