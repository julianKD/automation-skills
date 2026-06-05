# Claude Instructions — HdM Workspace

This repo serves as a shared workspace for Claude Code sessions at HdM, storing reusable skills and instructions.

---

## Skills

Skills live in `.claude/skills/` and are automatically available in Claude Code sessions rooted here.

| Skill | Path | Description |
|---|---|---|
| `hdm-timesheet` | `.claude/skills/hdm-timesheet/` | Guide for the HdM PPM timesheet app — table structure, adding attendance slots, adding projects, logging hours |

### Maintaining skills

- **Edit** a skill by modifying `.claude/skills/<skill-name>/SKILL.md`
- **Keep in sync**: the skill also lives at `C:\Users\j.hoell\.claude\skills\hdm-timesheet\SKILL.md` (user-level). After editing here, copy it over:
  ```bash
  cp .claude/skills/hdm-timesheet/SKILL.md "C:/Users/j.hoell/.claude/skills/hdm-timesheet/SKILL.md"
  ```
- **Add a new skill**: create a new folder under `.claude/skills/<skill-name>/` with a `SKILL.md` inside, then copy to the user-level skills folder the same way.

---

## Key app references

| App | URL |
|---|---|
| HdM PPM Timesheets | `https://ppm.herzogdemeuron.com/ts22/timesheets/` |

---

## Notes

- The browser automation tools (Claude in Chrome) can interact directly with the PPM app — useful for filling in timesheets, testing UI behaviour, etc.
- Public holidays (e.g. May 1st) trigger a warning in the timesheet app when logging attendance — this is expected behaviour.
