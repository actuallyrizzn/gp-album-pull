# Agentic (or human) maintenance cycle

This document is **documentation** (not program code). It is licensed under **CC BY-SA 4.0** — see `LICENSE-CC-BY-SA-4.0.txt`.

---

## Why this exists

`gp-album-pull` does not use a supported Google API. It scrapes **public** album pages. Google can change HTML, script keys (`ds:1`), or URL patterns at any time. Maintenance is **reactive**: fix the extractor when the site shape changes.

An **agent** (or a human on a calendar) can own **periodic triage** and **patches** so the scripts keep working without pretending the integration is stable forever.

---

## Repair cycle (suggested)

| Phase | Action |
|-------|--------|
| **Triage window** | On a fixed schedule (e.g. monthly), or immediately after a **breakage** issue is filed: reproduce with the reported album URL and script variant (`sh` vs `ps1`). |
| **Diagnose** | Compare new HTML to what the scripts expect: presence of `AF_initDataCallback`, `key: 'ds:1'`, `lh3.googleusercontent.com/pw/` tuples, `",width,height,` ordering. |
| **Patch** | Update **both** `gp_album_pull.sh` and `gp_album_pull.ps1` so behavior stays aligned. Adjust comments in-script and this doc if the methodology changes. |
| **Verify** | Run against at least one known-good public test album; confirm non-zero images and sane dimensions/file types. |
| **Release** | Commit with a clear message; tag if you version releases. Close the issue with what changed. |

Optional hardening: add a **CI smoke job** that curls a **pinned** public album URL and asserts `grep` finds at least *N* `/pw/` lines (fragile if the album is deleted — document the test album owner).

---

## Issue quality — what helps the next repair

When something breaks, **file an issue** using the **“Breakage / regression”** template. More detail means faster fixes.

Include when possible:

1. **Which script** — `gp_album_pull.sh` (and OS: Ubuntu, macOS, WSL) or `gp_album_pull.ps1` / `.cmd` (Windows version).
2. **Exact album URL** — must be a **public** (“anyone with the link”) album you’re allowed to share for debugging.
3. **Expected vs actual** — e.g. “0 images found”, “wrong count”, “downloads corrupt”.
4. **Full stderr / stdout** from one run.
5. **Commit or release** — git SHA or “main as of DATE”.
6. **Optional:** save the HTML of the album page once (`curl -L` to a file) and **attach** or paste a **redacted** snippet around `AF_initDataCallback` or `lh3.googleusercontent.com` if present — **do not** paste cookies or private tokens.

The **next repair cycle** (monthly or on-call) should **prioritize** issues with reproducible URLs and logs.

---

## What the agent should *not* assume

- That Google’s markup is stable month-to-month.
- That `ds:1` will always be the key — confirm in live HTML before patching.
- That every album loads all photos in the first HTML response (infinite scroll gaps are a **product** limitation, not always a bug).

---

## Coordination with humans

If a breakage is **ambiguous** (intermittent blocks, geo, rate limits), the agent should **ask for one more data point** in the issue (e.g. different network, `GP_USER_AGENT` test) before large refactors.

---

## License

This file is licensed under **Creative Commons Attribution-ShareAlike 4.0 International** (CC BY-SA 4.0). See `LICENSE-CC-BY-SA-4.0.txt`.
