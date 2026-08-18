@echo off
rem Load .env from repo root and start the Toggl Track MCP server.
rem
rem Runs from the patched venv at <repo>\.venv-toggl instead of `uvx
rem toggl-track-mcp`, because no stock mcp SDK release works with this package:
rem   - mcp >= 1.27 removed mcp.server.fastmcp  -> ModuleNotFoundError
rem   - mcp 1.9.x / 1.13.x  -> TypeError in Tool.from_function
rem   - mcp <= 1.4.1        -> starts, but leaks the injected `ctx` param into
rem                            every tool schema, so all calls fail with
rem                            "Context is not available outside of a request"
rem
rem Cause: toggl_track_mcp/tools/*.py use `from __future__ import annotations`,
rem which turns `ctx: Context` into the string "Context", so FastMCP's
rem issubclass() check cannot recognise the context parameter. Setup strips
rem that import line (safe on 3.12, where `X | None` is native) and pins
rem mcp==1.13.1. See configs/claude-code/setup-toggl-venv.bat to rebuild.
set "REPO=%~dp0..\.."
for /f "usebackq tokens=1,2 delims==" %%a in ("%REPO%\.env") do set %%a=%%b
set SSL_CERT_FILE=
"%REPO%\.venv-toggl\Scripts\python.exe" -m toggl_track_mcp
