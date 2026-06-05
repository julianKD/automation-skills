# automation-skills

A documentation library of AI agent skills used across Cursor and Claude Desktop.
Each skill is version-controlled here and synced to its deployment location(s).

## Skills

### [toggl-timesheet](skills/toggl-timesheet/)

Toggl Track timesheet assistant. Reads Outlook calendar screenshots or verbal
descriptions, maps meetings to HdM projects, fills gaps, and creates
15-minute-rounded entries via the
[toggl-track-mcp](https://github.com/dovahkaal/TogglTrackMcp) MCP server.

| File | Purpose |
|------|---------|
| `SKILL.md` | Conversation flow, project mappings, entry rules, Outlook parsing |
| `reference.md` | Per-project description vocabulary (2023-2025 history) |

**Deployed to:** `~/.cursor/skills/toggl-timesheet/` (Cursor, all workspaces)

**MCP dependency:** `toggl-track` (dovahkaal/TogglTrackMcp)

---

### [hdm-timesheet](skills/hdm-timesheet/)

UI guide for the HdM PPM timesheet web app at `ppm.herzogdemeuron.com`.
Covers table structure, attendance slots, adding projects, and logging hours.
Used by Claude Desktop with browser automation (Claude in Chrome) to interact
with the PPM app directly.

| File | Purpose |
|------|---------|
| `SKILL.md` | Step-by-step guide for the PPM web app |

**Deployed to:**
- `~/.claude/skills/hdm-timesheet/` (Claude Code, user-level)
- `C:\temp\Claude\.claude\skills\hdm-timesheet\` (Claude Code, workspace-level)

**MCP dependency:** Claude in Chrome (browser automation)

---

## Configs

### [claude-desktop](configs/claude-desktop/)

Workspace configuration for the Claude Desktop / Claude Code workspace at
`C:\temp\Claude`. Contains the `CLAUDE.md` workspace instructions and MCP
permission grants for browser automation via Claude in Chrome.

| File | Purpose |
|------|---------|
| `CLAUDE.md` | Workspace-level instructions and skill inventory |
| `settings.local.json` | MCP permission allowlist for Claude in Chrome tools |

---

## Syncing changes

After editing a skill in this repo, copy it to the live location:

```powershell
# Toggl skill → Cursor
Copy-Item -Path skills\toggl-timesheet\* -Destination "$env:USERPROFILE\.cursor\skills\toggl-timesheet\" -Force

# HdM skill → Claude Code (user-level)
Copy-Item -Path skills\hdm-timesheet\* -Destination "$env:USERPROFILE\.claude\skills\hdm-timesheet\" -Force

# HdM skill → Claude Code (workspace-level)
Copy-Item -Path skills\hdm-timesheet\* -Destination "C:\temp\Claude\.claude\skills\hdm-timesheet\" -Force

# Claude Desktop workspace config
Copy-Item -Path configs\claude-desktop\CLAUDE.md -Destination "C:\temp\Claude\CLAUDE.md" -Force
Copy-Item -Path configs\claude-desktop\settings.local.json -Destination "C:\temp\Claude\.claude\settings.local.json" -Force
```

## Setup (for Toggl MCP)

### 1. Get your Toggl API token

1. Log in to [Toggl Track](https://track.toggl.com/).
2. Go to **Profile** (avatar bottom-left > Profile Settings).
3. Scroll to the bottom -- your **API Token** is there.

### 2. Configure the token

Edit `.env` in this repo root and replace the placeholder:

```
TOGGL_API_TOKEN=paste-your-token-here
```

Also paste the same token into `.cursor/mcp.json` (replace `your-token-here`).

### 3. Cursor workspace MCP

The MCP is configured in `.cursor/mcp.json` (gitignored). After updating the
token, restart Cursor. The `toggl-track` MCP server should appear in the MCP
panel.

### 4. Claude Desktop (optional)

Add this to `%APPDATA%\Claude\claude_desktop_config.json` (Windows) or
`~/Library/Application Support/Claude/claude_desktop_config.json` (macOS):

```json
{
  "mcpServers": {
    "toggl-track": {
      "command": "uvx",
      "args": ["toggl-track-mcp"],
      "env": {
        "TOGGL_API_TOKEN": "paste-your-token-here"
      }
    }
  }
}
```
