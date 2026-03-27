# gp-album-pull

**Repository:** https://github.com/actuallyrizzn/gp-album-pull

Download all images from a **link-shared** Google Photos album — no OAuth, no API keys. Uses the same idea as several community tools: read the public album HTML, extract embedded `lh3.googleusercontent.com/pw/...` URLs and dimensions, then fetch full size with `=wWIDTH-hHEIGHT`.

**Scripts:** `gp_album_pull.sh` (Linux / macOS / Git Bash), `gp_album_pull.ps1` (Windows PowerShell), `gp_album_pull.cmd` (launcher that invokes the `.ps1` next to it).

---

## Requirements

| Platform | Needs |
|----------|--------|
| **Unix-like** | `bash`, `curl`, `grep`, `sed`, `file`, `mktemp` |
| **Windows** | PowerShell **5.1** or later (built into Windows 10+). The `.cmd` wrapper calls `powershell.exe`. |

Optional: set `GP_USER_AGENT` to a custom User-Agent string if requests are blocked.

---

## Usage

**Linux / macOS / WSL / Git Bash**

```bash
chmod +x gp_album_pull.sh
./gp_album_pull.sh 'https://photos.app.goo.gl/XXXXXXXX' ./my_downloads
```

**Windows (PowerShell)**

```powershell
Set-ExecutionPolicy -Scope CurrentUser RemoteSigned   # once, if scripts are blocked
.\gp_album_pull.ps1 'https://photos.app.goo.gl/XXXXXXXX' .\my_downloads
```

**Windows (Command Prompt)**

```cmd
gp_album_pull.cmd "https://photos.app.goo.gl/XXXXXXXX" .\my_downloads
```

Output files are numbered `001.jpg`, `002.jpg`, … (or `.png` / `.webp` / `.bin` depending on bytes on disk).

---

## How it works (for maintainers)

1. **Fetch** the album URL with redirects enabled. Short `photos.app.goo.gl` links resolve to `photos.google.com/share/...`.
2. **Find** embedded JSON: `AF_initDataCallback` with `key: 'ds:1'` contains photo metadata. Each item includes a base URL under `https://lh3.googleusercontent.com/pw/...` followed by width and height.
3. **Regex** (same on sh + ps1):  
   `https://lh3\.googleusercontent\.com/pw/[^"]+",<width>,<height>,`  
   then **dedupe** (`sort -u` / `Sort-Object -Unique`).
4. **Download** `BASE_URL=wWIDTH-hHEIGHT` (Google’s image CDN sizing).
5. **Rename** by magic bytes (Unix `file`; PowerShell reads first bytes) to `.jpg` / `.png` / `.webp`.

This depends on **undocumented** HTML/JSON shape. When Google changes the Photos web app, the regex may need updating — that is expected; see **Maintenance** below.

### Limitations

- Only images **inlined in the first HTML response** are retrieved. Albums that load many items **only** via infinite scroll may be incomplete.
- **Terms of service:** use for albums you’re allowed to bulk-download (e.g. your own shared links). This tool does not bypass authentication; public link only.

---

## Maintenance and breakage

Google can change the page at any time. **Do not expect** a permanent stable API.

- **Human or agent maintainers:** follow **`docs/AGENT_MAINTENANCE.md`** — issue workflow, repair cycle, what detail to collect when something breaks.
- **Users:** when the script fails, open a GitHub issue using **“Breakage / regression”** and paste as much context as you can (URL, OS, script, stderr, screenshot). The next scheduled repair pass uses that.

---

## Licenses

| Material | License |
|----------|---------|
| **Software** (`gp_album_pull.sh`, `gp_album_pull.ps1`, `gp_album_pull.cmd`) | [GNU Affero General Public License v3.0](https://www.gnu.org/licenses/agpl-3.0.html) or later — see `LICENSE`. |
| **Documentation and other non-code** (this README, `docs/`, `RESEARCH.md`, `.github/` issue templates, etc.) | [Creative Commons Attribution-ShareAlike 4.0 International](https://creativecommons.org/licenses/by-sa/4.0/) — see `LICENSE-CC-BY-SA-4.0.txt`. |

See `NOTICE` for a short summary. If you modify the scripts and provide access to them over a network, AGPL obligations apply — read `LICENSE`.

---

## Changelog

See **`CHANGELOG.md`** ([Keep a Changelog](https://keepachangelog.com/) style). Document user-visible fixes and behavior changes each release.

## Contributing

Improvements welcome: keep **sh** and **ps1** behavior aligned (same regex and steps). Document behavior changes in **`CHANGELOG.md`**, this README, and `docs/AGENT_MAINTENANCE.md` if they affect triage or testing.
