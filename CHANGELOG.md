# Changelog

All notable changes to **gp-album-pull** are documented here.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/).  
This file is **documentation** — licensed under **CC BY-SA 4.0** (see `LICENSE-CC-BY-SA-4.0.txt`).

## [Unreleased]

### Added
- _(nothing yet)_

---

## [0.1.0] — 2026-03-27

### Added

- **`gp_album_pull.sh`** — Bash downloader using `curl`, `grep`, `sed`, and `file`; extracts `lh3.googleusercontent.com/pw/...` tuples from embedded `AF_initDataCallback` / `ds:1` HTML, dedupes, downloads full size via `=wWIDTH-hHEIGHT`.
- **`gp_album_pull.ps1`** — PowerShell equivalent for Windows (`Invoke-WebRequest`, magic-byte detection for `.jpg` / `.png` / `.webp`).
- **`gp_album_pull.cmd`** — Invokes the `.ps1` beside it with `ExecutionPolicy Bypass`.
- **Documentation:** `README.md`, `RESEARCH.md` (background + alternatives), `docs/AGENT_MAINTENANCE.md` (repair cycle for humans/agents), `CONTRIBUTING.md`, `NOTICE`.
- **Licensing:** `LICENSE` (GNU **AGPL-3.0** full text for program code), `LICENSE-CC-BY-SA-4.0.txt` for non-code materials.
- **GitHub:** issue form **Breakage / regression** (`.github/ISSUE_TEMPLATE/breakage.yml`) and `config.yml`.

### Notes

- Public link–shared albums only; no OAuth. Relies on undocumented Google Photos web markup — expect occasional breakage; see maintenance doc and changelog.

[Unreleased]: https://github.com/actuallyrizzn/gp-album-pull/compare/v0.1.0...HEAD
[0.1.0]: https://github.com/actuallyrizzn/gp-album-pull/releases/tag/v0.1.0
