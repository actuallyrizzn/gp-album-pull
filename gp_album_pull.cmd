@echo off
REM SPDX-License-Identifier: AGPL-3.0-or-later
REM gp_album_pull.cmd — Windows launcher for gp_album_pull.ps1 (same folder).
REM Copyright (C) 2026 gp-album-pull contributors. License: AGPL-3.0-or-later; see LICENSE.
setlocal
set "SCRIPT=%~dp0gp_album_pull.ps1"
if not exist "%SCRIPT%" (
    echo gp_album_pull.ps1 not found next to this file: "%SCRIPT%" 1>&2
    exit /b 1
)
powershell.exe -NoLogo -NoProfile -ExecutionPolicy Bypass -File "%SCRIPT%" %*
exit /b %ERRORLEVEL%
