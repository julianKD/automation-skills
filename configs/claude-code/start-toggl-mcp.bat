@echo off
rem Load .env from repo root and start the Toggl Track MCP server.
for /f "usebackq tokens=1,2 delims==" %%a in ("%~dp0..\..\\.env") do set %%a=%%b
set SSL_CERT_FILE=
"%APPDATA%\Python\Python312\Scripts\uvx.exe" toggl-track-mcp
