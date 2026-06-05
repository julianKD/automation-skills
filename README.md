# toggl-sync

Toggl Track timesheet assistant powered by a Cursor/Claude skill and the
[toggl-track-mcp](https://github.com/dovahkaal/TogglTrackMcp) MCP server.

Paste Outlook calendar screenshots or describe your day verbally -- the skill
maps meetings to projects, fills gaps, and creates 15-minute-rounded entries
in your Toggl account.

## Prerequisites

- Python 3.10+
- [uv](https://docs.astral.sh/uv/) package manager
- A Toggl Track account

## Setup

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

The MCP is already configured in `.cursor/mcp.json`. After updating the token,
restart Cursor. The `toggl-track` MCP server should appear in the MCP panel.

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

If you already have other MCP servers configured, merge the `toggl-track`
entry into your existing `mcpServers` object.

Restart Claude Desktop after saving.

## Skill

The live skill is installed at `~/.cursor/skills/toggl-timesheet/` (personal,
available across all Cursor workspaces). A version-controlled copy lives in
this repo under `skill/`:

- `skill/SKILL.md` -- conversation flow, project patterns, entry rules
- `skill/reference.md` -- per-project description vocabulary (3 years of history)

To sync changes back to the live location after editing in the repo:

```powershell
Copy-Item -Path skill\* -Destination "$env:USERPROFILE\.cursor\skills\toggl-timesheet\" -Force
```

## Usage

Start a new chat and mention timesheets, hours, or Toggl. The skill activates
automatically. Three main workflows:

1. **Screenshot**: Paste an Outlook calendar screenshot.
2. **Verbal**: "I talked with Mo about BIM Standards for 30 min."
3. **Day-fill**: "I left at 18:30 on Wednesday."

The assistant proposes entries in a table, asks only what is missing, and
creates them on confirmation.
