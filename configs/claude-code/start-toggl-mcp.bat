@echo off
rem Load .env from repo root and start the Toggl Track MCP server.
for /f "usebackq tokens=1,2 delims==" %%a in ("%~dp0..\..\\.env") do set %%a=%%b
set SSL_CERT_FILE=
rem Pin the mcp SDK: toggl-track-mcp imports mcp.server.fastmcp, which newer
rem SDKs removed (ModuleNotFoundError), and 1.9.x/1.13.x break on
rem Tool.from_function ("issubclass() arg 1 must be a class"). 1.2.1 works.
"%APPDATA%\Python\Python312\Scripts\uvx.exe" --with "mcp==1.2.1" toggl-track-mcp
