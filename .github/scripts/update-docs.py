#!/usr/bin/env python3
"""Update versions.json, README.md versions block, and CHANGELOG.md from CI build metadata."""

from __future__ import annotations

import json
import re
import sys
from pathlib import Path


def load_meta(meta_dir: Path) -> dict[str, dict]:
    metas: dict[str, dict] = {}
    for path in sorted(meta_dir.rglob("meta-*.json")):
        data = json.loads(path.read_text(encoding="utf-8"))
        major = data["major"]
        metas[major] = data
    if not metas:
        raise SystemExit(f"ERROR: No meta-*.json files found in {meta_dir}")
    return metas


def update_readme(readme_path: Path, versions: dict, metas: dict[str, dict]) -> None:
    content = readme_path.read_text(encoding="utf-8")
    start_marker = "<!-- versions:start -->"
    end_marker = "<!-- versions:end -->"
    if start_marker not in content or end_marker not in content:
        raise SystemExit("ERROR: README.md missing versions markers")

    debian_ver = versions["debian_version"]
    go_ver = versions["go_version"]
    gosu_ver = versions["gosu_version"]
    updated = versions["last_updated"]

    rows = []
    for major in sorted(versions["tracks"].keys()):
        t = versions["tracks"][major]
        rows.append(
            f"| `{major}` (LTS) | `{t['version']}` | Debian `{debian_ver}` | "
            f"`gosu {gosu_ver}` (Go `{go_ver}`) | "
            f"{t['trivy_fixable_critical_high']} / {t['grype_fixable_critical_high']} |"
        )

    highlights = []
    for major in sorted(metas.keys()):
        m = metas[major]
        prev_v = m.get("prev_version", "")
        cur_v = m["version"]
        if prev_v and prev_v != cur_v:
            highlights.append(f"- MariaDB `{major}` updated from `{prev_v}` to `{cur_v}`.")
    if not highlights:
        highlights.append("- Daily base OS (`debian:trixie-slim`) security refresh and CVE-gated verification.")

    block = "\n".join(
        [
            start_marker,
            f"_Last verified build: **{updated}** (UTC)_",
            "",
            "| Track | Upstream Version | Base OS | Step-down Helper | Fixable Critical/High (Trivy / Grype) |",
            "|-------|------------------|---------|------------------|---------------------------------------|",
            *rows,
            "",
            "**Recent upstream updates:**",
            *highlights,
            end_marker,
        ]
    )

    pattern = re.compile(re.escape(start_marker) + r".*?" + re.escape(end_marker), re.DOTALL)
    new_content = pattern.sub(block, content, count=1)
    readme_path.write_text(new_content, encoding="utf-8")


def update_changelog(
    changelog_path: Path,
    date_str: str,
    versions: dict,
    prev_versions: dict,
    metas: dict[str, dict],
    cves_fixed: list[str],
) -> None:
    content = changelog_path.read_text(encoding="utf-8")
    section_header = f"## [{date_str}]"

    changed_items = []
    for major in sorted(metas.keys()):
        m = metas[major]
        prev_v = prev_versions.get("tracks", {}).get(major, {}).get("version", "")
        cur_v = m["version"]
        digest = m.get("digest") or "not-published"
        if prev_v and prev_v != cur_v:
            changed_items.append(f"- MariaDB {major} updated `{prev_v}` -> `{cur_v}` (`{digest}`)")
        else:
            changed_items.append(f"- MariaDB {major} rebuilt at `{cur_v}` on Debian `{versions['debian_version']}` (`{digest}`)")

    if versions["go_version"] != prev_versions.get("go_version"):
        changed_items.append(
            f"- Rebuilt `gosu {versions['gosu_version']}` with Go `{versions['go_version']}` "
            f"(previously `{prev_versions.get('go_version', 'none')}`)"
        )

    sec_lines = []
    if cves_fixed:
        sec_lines.append(f"- CVEs fixed compared to previous build: {', '.join(sorted(cves_fixed))}")
    else:
        sec_lines.append("- Trivy and Grype gates verified: 0 fixable Critical/High vulnerabilities.")

    entry = "\n".join(
        [
            section_header,
            "",
            "### Changed",
            *changed_items,
            "",
            "### Security",
            *sec_lines,
            "",
        ]
    )

    if section_header in content:
        # Replace existing entry for today
        pattern = re.compile(
            re.escape(section_header) + r"\n.*?(?=\n## \[|\Z)",
            re.DOTALL,
        )
        new_content = pattern.sub(entry.rstrip("\n"), content, count=1)
    else:
        marker = "## [Unreleased]\n"
        if marker in content:
            idx = content.index(marker)
            next_h2 = content.find("\n## [", idx + len(marker))
            if next_h2 == -1:
                new_content = content.rstrip() + "\n\n" + entry
            else:
                new_content = content[: next_h2 + 1] + "\n" + entry + content[next_h2 + 1 :]
        else:
            new_content = content.rstrip() + "\n\n" + entry

    changelog_path.write_text(new_content.rstrip() + "\n", encoding="utf-8")


def main() -> None:
    meta_dir = Path(sys.argv[1]) if len(sys.argv) > 1 else Path("artifacts")
    metas = load_meta(meta_dir)

    versions_path = Path("versions.json")
    prev_versions = json.loads(versions_path.read_text(encoding="utf-8")) if versions_path.exists() else {}

    any_meta = next(iter(metas.values()))
    date_str = any_meta["date_iso"]

    cves_fixed_set: set[str] = set()
    new_tracks: dict[str, dict] = {}
    for major, m in sorted(metas.items()):
        prev_cves = set(prev_versions.get("tracks", {}).get(major, {}).get("cves_seen", []))
        cur_cves = set(m.get("cves_seen", []))
        cves_fixed_set.update(prev_cves - cur_cves)
        new_tracks[major] = {
            "version": m["version"],
            "digest": m.get("digest") or "pending-hub-publish",
            "trivy_fixable_critical_high": m.get("trivy_fixable_critical_high", 0),
            "grype_fixable_critical_high": m.get("grype_fixable_critical_high", 0),
            "cves_seen": sorted(cur_cves),
        }

    new_versions = {
        "last_updated": date_str,
        "debian_version": any_meta["debian_version"],
        "go_version": any_meta["go_version"],
        "gosu_version": any_meta["gosu_version"],
        "tracks": new_tracks,
    }

    versions_changed = (
        new_versions.get("debian_version") != prev_versions.get("debian_version")
        or new_versions.get("go_version") != prev_versions.get("go_version")
        or new_versions.get("gosu_version") != prev_versions.get("gosu_version")
        or new_versions.get("tracks") != prev_versions.get("tracks")
    )

    versions_path.write_text(json.dumps(new_versions, indent=2) + "\n", encoding="utf-8")
    update_readme(Path("README.md"), new_versions, metas)
    if versions_changed or cves_fixed_set:
        update_changelog(
            Path("CHANGELOG.md"),
            date_str,
            new_versions,
            prev_versions,
            metas,
            sorted(cves_fixed_set),
        )
    print(f"Docs updated (versions_changed={versions_changed}, cves_fixed={len(cves_fixed_set)})")


if __name__ == "__main__":
    main()
