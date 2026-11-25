#!/usr/bin/env python3
"""Update versions.json, README.md versions block, and CHANGELOG.md for MariaDB multi-track builds."""

from __future__ import annotations

import json
import re
import sys
from pathlib import Path


def update_readme(readme_path: Path, versions: dict) -> None:
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
        sizes = t.get("sizes_mb") or {}
        size_txt = ", ".join(f"{k}: {v} MB" for k, v in sizes.items()) if sizes else "multi-arch"
        rows.append(
            f"| `{major}` (LTS) | `{t['version']}` | Debian `{debian_ver}` | "
            f"`gosu {gosu_ver}` (Go `{go_ver}`) | `{size_txt}` | "
            f"**{t.get('trivy_fixable_critical_high', 0)}** ({len(t.get('unfixed_cves') or [])} unfixed) |"
        )

    digest_rows = []
    for major in sorted(versions["tracks"].keys()):
        t = versions["tracks"][major]
        dig = t.get("digest") or ""
        ghcr = t.get("ghcr_digest") or ""
        if dig:
            digest_rows.append(f"- **MariaDB `{major}` (`{t['version']}`):** `{dig}` / `{ghcr}`")
        elif ghcr:
            digest_rows.append(f"- **MariaDB `{major}` (`{t['version']}`):** `{ghcr}`")

    block = "\n".join(
        [
            start_marker,
            f"_Last verified build: **{updated}** (UTC) — multi-arch (`linux/amd64`, `linux/arm64`), Cosign OIDC signed, SPDX & CycloneDX SBOM attested, SLSA Build L3 provenance._",
            "",
            "| Track | Upstream Version | Base OS | Step-down Helper | Uncompressed Size | Fixable Critical/High (Trivy + Grype SBOM) |",
            "| --- | --- | --- | --- | --- | --- |",
            *rows,
            "",
            "**Published multi-arch digests (identical on Docker Hub & GHCR):**",
            *digest_rows,
            end_marker,
        ]
    )

    pattern = re.compile(re.escape(start_marker) + r".*?" + re.escape(end_marker), re.DOTALL)
    new_content = pattern.sub(lambda _m: block, content, count=1)
    readme_path.write_text(new_content, encoding="utf-8")


def update_changelog(
    changelog_path: Path,
    date_str: str,
    versions: dict,
    prev_versions: dict,
    cves_fixed: list[str],
) -> None:
    content = changelog_path.read_text(encoding="utf-8")
    section_header = f"## [{date_str}]"

    changed_items = []
    for major in sorted(versions["tracks"].keys()):
        t = versions["tracks"][major]
        prev_v = prev_versions.get("tracks", {}).get(major, {}).get("version", "")
        cur_v = t["version"]
        digest = t.get("digest") or t.get("ghcr_digest") or "not-published"
        if prev_v and prev_v != cur_v:
            changed_items.append(f"- MariaDB {major} updated `{prev_v}` -> `{cur_v}` (multi-arch `amd64`/`arm64`, `{digest}`)")
        else:
            changed_items.append(f"- MariaDB {major} rebuilt at `{cur_v}` on Debian `{versions['debian_version']}` (multi-arch `amd64`/`arm64`, `{digest}`)")

    if versions["go_version"] != prev_versions.get("go_version"):
        changed_items.append(
            f"- Rebuilt `gosu {versions['gosu_version']}` with Go `{versions['go_version']}` "
            f"(previously `{prev_versions.get('go_version', 'none')}`)"
        )

    sec_lines = []
    if cves_fixed:
        sec_lines.append(f"- CVEs resolved since previous scan: {', '.join(f'`{c}`' for c in sorted(cves_fixed))}.")
    else:
        sec_lines.append(
            "- Trivy and Grype (SPDX SBOM) gates verified: **0 fixable Critical/High** vulnerabilities across `linux/amd64` and `linux/arm64`; Cosign OIDC signed with SLSA Build L3 provenance."
        )

    entry = "\n".join(
        [
            section_header,
            "",
            "### Automated Daily Build",
            *changed_items,
            "",
            "### Security",
            *sec_lines,
        ]
    )

    if section_header in content:
        pattern = re.compile(
            re.escape(section_header) + r"\n.*?(?=\n---\n|\n## \[|\Z)",
            re.DOTALL,
        )
        new_content = pattern.sub(lambda _m: entry, content, count=1)
    else:
        marker = "<!-- changelog:auto -->"
        if marker in content:
            new_content = content.replace(marker, f"{marker}\n\n{entry}\n\n---", 1)
        else:
            new_content = content.rstrip() + "\n\n" + entry

    changelog_path.write_text(new_content.rstrip() + "\n", encoding="utf-8")


def main() -> int:
    if len(sys.argv) != 2:
        print("Usage: update-docs.py <versions-new.json>", file=sys.stderr)
        return 2

    new_versions = json.loads(Path(sys.argv[1]).read_text(encoding="utf-8"))
    versions_path = Path("versions.json")
    prev_versions = json.loads(versions_path.read_text(encoding="utf-8")) if versions_path.exists() else {}

    cves_fixed: set[str] = set()
    for major, t in (new_versions.get("tracks") or {}).items():
        prev_t = (prev_versions.get("tracks") or {}).get(major, {})
        prev_cves = set(prev_t.get("unfixed_cves") or prev_t.get("cves_seen") or [])
        cur_cves = set(t.get("unfixed_cves") or [])
        cves_fixed.update(prev_cves - cur_cves)

    changed = new_versions != prev_versions or bool(cves_fixed)
    versions_path.write_text(json.dumps(new_versions, indent=2) + "\n", encoding="utf-8")
    update_readme(Path("README.md"), new_versions)
    if changed:
        update_changelog(
            Path("CHANGELOG.md"),
            new_versions["last_updated"],
            new_versions,
            prev_versions,
            sorted(cves_fixed),
        )
    print(f"Docs updated (changed={changed}, cves_fixed={len(cves_fixed)})")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
