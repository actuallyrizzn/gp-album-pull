# Contributing

This document is licensed under **CC BY-SA 4.0** — see `LICENSE-CC-BY-SA-4.0.txt`.

---

## Code

- **License:** Contributions to `gp_album_pull.sh`, `gp_album_pull.ps1`, and `gp_album_pull.cmd` are accepted under the **GNU Affero General Public License v3.0 or later** (see `LICENSE`). By submitting a patch, you agree your contribution is available under those terms.

- **Parity:** Logic and regexes should stay **aligned** between the shell and PowerShell scripts unless there is a documented platform-specific reason.

- **Comments:** Non-obvious parsing steps and Google-specific assumptions should be documented **in the scripts** (not only in README).

---

## Documentation

- README, `docs/`, `RESEARCH.md`, and GitHub templates are **CC BY-SA 4.0**. Derivatives must credit the project and use the same license for shared adaptations.

---

## Issues

- Use **Breakage / regression** when the scripts stop working against real public albums.
- Include URL, script variant, logs, and environment — see `docs/AGENT_MAINTENANCE.md`.
