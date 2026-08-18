@echo off
rem Rebuild the patched Toggl Track MCP venv at <repo>\.venv-toggl.
rem Run this after cloning, or to recreate the venv from scratch.
rem
rem The patch: toggl_track_mcp/tools/*.py use `from __future__ import
rem annotations`, which turns `ctx: Context` into the string "Context". FastMCP
rem identifies its injected context parameter with issubclass(annotation,
rem Context), which then either raises or silently treats `ctx` as a normal
rem required tool argument -- breaking every tool call. Deleting the future
rem import makes the annotation resolve to the real class. Safe on Python 3.12,
rem where `X | None` is native syntax.
setlocal
set "REPO=%~dp0..\.."
set "UV=%APPDATA%\Python\Python312\Scripts\uv.exe"
set SSL_CERT_FILE=

if not exist "%UV%" (
  echo ERROR: uv.exe not found at "%UV%"
  exit /b 1
)

echo Creating venv at "%REPO%\.venv-toggl" ...
"%UV%" venv "%REPO%\.venv-toggl" --python 3.12 || exit /b 1

echo Installing toggl-track-mcp and mcp==1.13.1 ...
set "VIRTUAL_ENV=%REPO%\.venv-toggl"
"%UV%" pip install toggl-track-mcp "mcp==1.13.1" || exit /b 1

echo Stripping 'from __future__ import annotations' from tool modules ...
"%REPO%\.venv-toggl\Scripts\python.exe" -c "import pathlib,sys; d=pathlib.Path(sys.prefix)/'Lib'/'site-packages'/'toggl_track_mcp'/'tools'; n=0; [ (p.write_text(''.join(l for l in p.read_text(encoding='utf-8').splitlines(keepends=True) if l.strip()!='from __future__ import annotations'), encoding='utf-8'), globals().__setitem__('n', n+1)) for p in d.glob('*.py') ]; print('patched', len(list(d.glob('*.py'))), 'files')" || exit /b 1

echo Verifying import ...
set TOGGL_API_TOKEN=dummy
"%REPO%\.venv-toggl\Scripts\python.exe" -c "import toggl_track_mcp; print('OK')" || exit /b 1

echo.
echo Done. Start the server with start-toggl-mcp.bat
endlocal
