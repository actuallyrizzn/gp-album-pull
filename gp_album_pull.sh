#!/usr/bin/env bash
# SPDX-License-Identifier: AGPL-3.0-or-later
#
# gp_album_pull.sh — Download images from a link-shared Google Photos album (Linux/macOS/Git Bash).
#
# Copyright (C) 2026 gp-album-pull contributors
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU Affero General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# See LICENSE for the full license text.
#
# --- Methodology (keep in sync with gp_album_pull.ps1) ---
#
# 1. curl GET the public album URL (short goo.gl links redirect to photos.google.com/share/...).
# 2. Parse the HTML. Google embeds media in AF_initDataCallback({ key: 'ds:1', ... }) with tuples
#    like:  "https://lh3.googleusercontent.com/pw/...", WIDTH, HEIGHT, ...
# 3. Extract lines matching:  https://lh3.googleusercontent.com/pw/...",W,H,
#    Pipe through `sort -u` to dedupe duplicate rows in the HTML.
# 4. Full resolution: append =wWIDTH-hHEIGHT to the base /pw/ URL (Google CDN sizing).
# 5. curl each image; rename using `file --mime-type` magic (JPEG/PNG/WebP).
#
# Limitations: Only items present in the initial HTML payload are downloaded. Very large albums
# that rely on infinite scroll may be incomplete until the extraction logic is extended.
#
# Environment:
#   GP_USER_AGENT — optional override for the HTTP User-Agent (default: Chrome-like string).
#
set -euo pipefail

UA="${GP_USER_AGENT:-Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/122.0.0.0 Safari/537.36}"

usage() {
  echo "usage: $0 <album URL (photos.app.goo.gl/... or photos.google.com/share/...)> [output_dir]" >&2
  exit 1
}

[[ $# -lt 1 ]] && usage
ALBUM="$1"
OUT="${2:-./gp_download}"
mkdir -p "$OUT"

TMP="$(mktemp)"
trap 'rm -f "$TMP"' EXIT

echo "Fetching album page..."
curl -fsSL --compressed -A "$UA" "$ALBUM" -o "$TMP"

# Photo rows: /pw/ base URL plus width and height from embedded JSON (see header comment).
mapfile -t lines < <(grep -oE 'https://lh3\.googleusercontent\.com/pw/[^"]+",[0-9]+,[0-9]+,' "$TMP" | sort -u) || true

if [[ ${#lines[@]} -eq 0 ]]; then
  echo "No lh3 /pw/ photo URLs found. Google may have changed the page shape, or the album is not public." >&2
  echo "File an issue using the breakage template; see docs/AGENT_MAINTENANCE.md" >&2
  exit 1
fi

echo "Found ${#lines[@]} image(s). Downloading..."
i=0
for line in "${lines[@]}"; do
  [[ -z "$line" ]] && continue
  # Split: baseUrl",W,H,  ->  baseUrl|W|H
  parsed="$(echo "$line" | sed -E 's/^(.+)",([0-9]+),([0-9]+),$/\1|\2|\3/')"
  [[ "$parsed" == *'|'*'|'* ]] || { echo "skip malformed: ${line:0:80}..." >&2; continue; }
  url="${parsed%%|*}"
  rest="${parsed#*|}"
  w="${rest%%|*}"
  h="${rest##*|}"
  ((i++)) || true
  full="${url}=w${w}-h${h}"
  out="$OUT/$(printf '%03d' "$i").img"
  echo "  [$i] ${w}x${h}"
  curl -fsSL --compressed -A "$UA" "$full" -o "$out"
  # Extension from libmagic (file(1)); avoids trusting URL or Content-Type alone.
  mt="$(file -b --mime-type "$out")"
  case "$mt" in
    image/jpeg) mv "$out" "${out%.img}.jpg" ;;
    image/png)  mv "$out" "${out%.img}.png" ;;
    image/webp) mv "$out" "${out%.img}.webp" ;;
    *)          mv "$out" "${out%.img}.bin" ;;
  esac
done

echo "Done -> $OUT"
