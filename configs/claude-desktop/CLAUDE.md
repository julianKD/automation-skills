# Claude Instructions — HdM Workspace

This repo serves as a shared workspace for Claude Code sessions at HdM, storing reusable skills and instructions.

---

## Skills

Skills live in `.claude/skills/` and are automatically available in Claude Code sessions rooted here.

| Skill | Path | Description |
|---|---|---|
| `hdm-timesheet` | `.claude/skills/hdm-timesheet/` | Guide for the HdM PPM timesheet app — table structure, adding attendance slots, adding projects, logging hours |
| `toggl-to-hdm` | `.claude/skills/toggl-to-hdm/` | Transfer a week's Toggl entries into HdM PPM — reads Toggl via MCP, aggregates by project/day, fills PPM via browser |

### Maintaining skills

- **Edit** a skill by modifying `.claude/skills/<skill-name>/SKILL.md`
- **Keep in sync**: the skill also lives at `C:\Users\j.hoell\.claude\skills\hdm-timesheet\SKILL.md` (user-level). After editing here, copy it over:
  ```bash
  cp .claude/skills/hdm-timesheet/SKILL.md "C:/Users/j.hoell/.claude/skills/hdm-timesheet/SKILL.md"
  ```
- **Add a new skill**: create a new folder under `.claude/skills/<skill-name>/` with a `SKILL.md` inside, then copy to the user-level skills folder the same way.

---

### Maintaining skills

- **Edit** a skill by modifying `.claude/skills/<skill-name>/SKILL.md`
- After editing, sync to user-level:
  ```powershell
  Copy-Item -Path skills\hdm-timesheet\* -Destination "$env:USERPROFILE\.claude\skills\hdm-timesheet\" -Force
  Copy-Item -Path skills\toggl-to-hdm\* -Destination "$env:USERPROFILE\.claude\skills\toggl-to-hdm\" -Force
  ```

---

## MCP servers

### toggl-track

Required by the `toggl-to-hdm` skill. The API token is read from the
`.env` file in `C:\temp\gitrepos\automation-skills\` — never hardcoded.

Add to `%APPDATA%\Claude\claude_desktop_config.json` (or the Claude Code
project MCP config):

```json
{
  "mcpServers": {
    "toggl-track": {
      "command": "uvx",
      "args": ["toggl-track-mcp"],
      "env": {
        "TOGGL_API_TOKEN": "load-from-env"
      }
    }
  }
}
```

> To keep the token out of config files, start Claude Code from a shell
> that has already loaded `.env` (e.g. `dotenv -f C:\temp\gitrepos\automation-skills\.env` before launching),
> then set `"TOGGL_API_TOKEN": "$TOGGL_API_TOKEN"` in the MCP env block.
> Alternatively paste the token directly only in the local config, which is
> gitignored.

---

## Key app references

| App | URL |
|---|---|
| HdM PPM Timesheets | `https://ppm.herzogdemeuron.com/ts22/timesheets/` |

---

## Notes

- The browser automation tools (Claude in Chrome) can interact directly with the PPM app — useful for filling in timesheets, testing UI behaviour, etc.
- Public holidays (e.g. May 1st) trigger a warning in the timesheet app when logging attendance — this is expected behaviour.
