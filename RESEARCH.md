# Public Google Photos — download / quick share (no OAuth)

**Google Photos is not Google Drive.** Shared albums use links like `https://photos.app.goo.gl/...` or `https://photos.google.com/share/...`. The usual **Drive** tools (**gdown**, etc.) do **not** apply here.

## What you want (public link only, no “fancy auth”)

Assume the album is shared as **Anyone with the link**. Everything below avoids Google Cloud projects, OAuth clients, and API credential JSON.

---

## Curl-only method (implemented here)

Script: **`gp_album_pull.sh`**

1. `curl -fsSL` the album URL (`photos.app.goo.gl/...` redirects to `photos.google.com/share/...`).
2. The HTML contains `AF_initDataCallback({key: 'ds:1', ...})` with embedded photo metadata. Each photo has a base URL like `https://lh3.googleusercontent.com/pw/AP1Gcz...` followed by **width** and **height** in the JSON array.
3. Grep for: `https://lh3.googleusercontent.com/pw/…",W,H,` → `sort -u` → append **`=wW-hH`** to the base URL (same rule third-party tools use).
4. `curl` each full URL; rename by `file` magic (`.jpg` / `.png` / `.webp`).

**Limits:** Only picks up what appears in that initial HTML blob. Very large albums that load more via infinite scroll may need another fetch pattern (not implemented). If Google renames the `ds:1` shape, adjust the grep.

---

## 1. **google-photos-album-image-url-fetch** (Node/npm) — strongest fit for automation

- **Package:** [google-photos-album-image-url-fetch](https://www.npmjs.com/package/google-photos-album-image-url-fetch) — source [yumetodo/google-photos-album-image-url-fetch](https://github.com/yumetodo/google-photos-album-image-url-fetch)
- **Idea:** Pass the **public album URL**; it returns an array of objects with stable `lh3.googleusercontent.com` (or `.../pw/...`) image URLs plus dimensions.
- **No OAuth:** Scrapes/fetches what the public album page exposes.
- **Full size:** README documents appending `=wWIDTH-hHEIGHT` to the URL (using the reported width/height) to pull larger renditions; you then `fetch`/curl each URL to disk.
- **Caveats:** Google may change page/JSON formats; library is maintained (last publish 2024) but this is always fragile vs. an official API.

Good stack for a small script: **Node** → list URLs → **curl** or `fetch` to `./downloads/`.

---

## 2. **gp-dl** (Python + Selenium)

- **Repo:** [csd4ni3l/gp-dl](https://github.com/csd4ni3l/gp-dl) — `pip install gp-dl`
- **Idea:** Drives a browser to the album and automation (e.g. “download all” style flows).
- **No OAuth:** Browser automation instead of APIs.
- **Caveats:** Heavier (browser, drivers), more moving parts; good when pure HTTP parsing fails.

---

## 3. **scrape-google-photos** (CLI)

- **Repo:** [alexcrist/scrape-google-photos](https://github.com/alexcrist/scrape-google-photos)
- **Idea:** CLI scrape of album; described as **preview-quality** images — fine for thumbnails/quick shares, not always full originals.

---

## Official API (probably *not* what you want here)

- **Google Photos Library API** is aimed at **user** libraries with **OAuth** and Google Cloud setup — that is the “fancy auth integration” you said you want to skip.
- For **public link + script**, prefer **(1)** or accept **(2)/(3)** tradeoffs.

---

## Practical notes

- **Terms of service:** Automated bulk download may conflict with Google’s terms; use for your own shared albums / agreed use cases.
- **Reliability:** Public-page parsers break when Google changes the UI; pin dependency versions and expect occasional fixes.
- **Sharing workflow:** Creating a **link-shared album** in Google Photos and pasting that URL into your tool is the intended input — no login in your app.

---

## In-repo implementation

This project ships **`gp_album_pull.sh`** and **`gp_album_pull.ps1`** / **`gp_album_pull.cmd`** — curl- or `Invoke-WebRequest`-based extraction using the same patterns as above (no Node required). See the repository **README.md** for usage and limitations.

---

## License (this document)

This file is part of **gp-album-pull** documentation and is licensed under [Creative Commons Attribution-ShareAlike 4.0 International](https://creativecommons.org/licenses/by-sa/4.0/). See `LICENSE-CC-BY-SA-4.0.txt`.
