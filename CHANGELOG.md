# Changelog

## 0.2.1 — 2026-07-09

- Clean release tarball (no Python bytecode)
- Document Homebrew 6 tap trust


## 0.2.0 — 2026-07-09

- **Structured `pk audit --json`** (`schema_version: 2`) via `lib/audit_json.py`
  - mdm, tcc, trackers, tunnels, listeners, launch, summary flags
- Example artifacts: `docs/example-audit.{txt,json}`, social card SVG
- Homebrew install docs (`brew tap krewdev/tap`)
- Private vulnerability reporting via GitHub Security Advisories
- Fewer tracker false positives (process matching)

## 0.1.1 — 2026-07-09

- CI (ShellCheck + smoke tests), Makefile, issue/PR templates
- Code of Conduct, EditorConfig
- Fix `--no-color` applying after color init
- ShellCheck cleanups (trackers path scan, unused vars)

## 0.1.0 — 2026-07-09

- Initial release
- `pk audit`, `tcc`, `launch`, `listeners`, `tunnels`, `trackers`, `mdm`, `doctor`
- Optional `pk audit --json` summary
- `install.sh` → `~/.local/share/privacy-kit` + `~/bin/pk`
