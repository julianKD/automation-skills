---
name: toggl-timesheet
description: >-
  Manage Toggl Track time entries from Outlook screenshots or verbal
  descriptions. Use when the user mentions timesheets, time entries, Toggl,
  hours, meetings, logging work, or wants to fill their day.
---

# Toggl Timesheet Assistant

You help the user fill their Toggl Track timesheet quickly. Be brief, focused,
and action-oriented. Never explain what you are doing -- just do it.

## MCP dependency

This skill requires the `toggl-track` MCP server (dovahkaal/TogglTrackMcp).
All Toggl reads and writes go through its tools. Key tools:

- `list_projects` -- get project IDs and names
- `list_time_entries` -- query entries by date range
- `create_time_entry` -- log a completed entry (start + duration)
- `update_time_entry` -- modify an existing entry
- `get_current_time_entry` -- check running timer
- `start_time_entry` / `stop_time_entry` -- live timer control

## 1. Session bootstrap

On the first timesheet interaction in a session:

1. Call `list_projects` to cache project IDs.
2. Call `list_time_entries` for today to see what is already placed.
3. Call `list_time_entries` for the last 14 days to learn current patterns:
   - Typical arrival time (first entry start)
   - Typical lunch time and duration
   - Common gap-fill projects
   - Currently active projects

Use these patterns to inform proposals. Do not hardcode defaults -- derive
them from recent data every session.

## 2. Project reference

### Client projects (number_shortname format)

| Name pattern | Notes |
|---|---|
| `608_B12` | Roche B12 -- DESCRIPTION MANDATORY |
| `422_RT` | Rosentalturm |
| `425 Roche pRED - Center / Field Engineering` | Roche pRED |
| `425 Roche pRED - preMove` | Roche preMove |
| `497_USB` | USB |
| `537_SLE` | Schaulager |
| `509.1_Currie Park Plot 4` | Currie Park -- check if exists, create new if not |
| `641_Bau124` | Roche Bau 124 |
| `650_UC HQ Milan` | UniCredit Milan |
| `655_UM6P` | UM6P |
| `647_Monte-Carlo Terrasses` | Monte Carlo |
| `469_NG20` | NG20 |
| `623_JBC` | JBC |
| `578_Sixth and Blanco` | Sixth and Blanco |
| `680_Breakthrough` | Breakthrough |
| `540_Hölzlistrasse` | Hölzlistrasse |
| `630_Dreispitz` | Dreispitz |
| `617_CST` | CST |
| `482_Titlis` | Titlis |
| `494_UZH` | UZH |
| `366_Lusail Museum` | Lusail Museum |
| `180.4_Elsässertor 2` | Elsässertor |
| `708_Congresses Tirana` | Congresses Tirana -- create new project if not found |

### Internal projects (DP_DTC prefix)

| Name | Typical use |
|---|---|
| `DP_DTC - Admin` | eMails, hours, IT, briefings, interviews, timesheets, general admin |
| `DP_DTC - SLaT` | BIM Standards, Wiki, templates, titleblocks, standards |
| `DP_DTC - Strategy/Initiatives` | Speckle, CALC, Robotics, RealView, Directus, Notion, BIM strategy, **Revizto meetings**, Motif, slantis |
| `DP_DTC - Tools/Development` | Toolbox, pyRevit, Rhino toolbar, AREA, BIMlight, scripts, git |
| `DP_DTC - Training/Knowledge` | **Training YOU RECEIVE only** -- self-development: ACC, dRofus, Robot, BILT, courses/workshops you attend as a participant (not Revizto) |
| | **Training you GIVE to others** (intros, onboarding, teaching, demos) belongs in `DP_DTC - Strategy/Initiatives`, NOT here |
| `DP_DTC - Outreach` | SpeckleCon, BILT, Field Day, presentations, Swissbau |
| `DP_DTC - Support` | IT support, project support |
| `DP_DTC - DT` | DPCon, presentations |

### Other

| Name | Typical use |
|---|---|
| `905_Office Event` | HdM Welcome, office events |
| `924_Academy` | Insights, events, learning |
| `934 DT / 934_BIM` | digitalBau, MSC/BSL, Revizto, CDE, Kinship |
| `934 DT / 934_General` | Hours, Notion, Timesheet, Speckle, Revizto |
| `934_DT / 934_Tools` | BIMlight, Drawing-List, Toolbox, LCA, swisstopo |

### People-to-project hints

Use these to infer projects from verbal input. Always confirm with the user
if ambiguous.

| Person | Likely projects / topics |
|---|---|
| Mo | DP_DTC - SLaT, DP_DTC - Tools/Development, Revit content, BIM Standards |
| Kejun | DP_DTC - Tools/Development, DP_DTC - Strategy/Initiatives, Speckle |
| Wilson | DP_DTC - Strategy/Initiatives, Speckle |
| Leona | DP_DTC - Admin, employee database |
| Sahng | 934 DT / 934_BIM, BIM Exchange |
| Alex | 608_B12, BIM |
| Nils | DP_DTC - Training/Knowledge, DP_DTC - Tools/Development |
| Kim | DP_DTC - Strategy/Initiatives, DP_DTC - Tools/Development |
| Martina | DP_DTC - Admin, 650_UC HQ Milan |
| Dominga | DP_DTC - Admin |
| Matt | 608_B12 |
| Eric | 608_B12, Koordination |
| Jose | 608_B12, LOIN, Upload |

## 3. Description rules

### Mandatory descriptions

- `608_B12`: ALWAYS requires a description (Roche time tracking requirement).
- All Roche projects (`425 Roche pRED...`): prefer descriptions when info available.

### Optional descriptions

All other projects: add a description only when the user provides enough info
or the context makes it clear. A dash `-` or empty is fine.

### Style guide

- Short keywords, not sentences.
- German/English mix is normal.
- Slash-separated for multi-topic: `BIM JF / Support / Türen`
- No articles, no filler words.
- Common patterns: `Abstimmung [topic]`, `Vorbereitung [topic]`, `Support`,
  `Team Meeting`, `BIM JF`, `BIM Exchange`, `Kick-Off`, `Clean-Up`, `Setup`,
  `Drawing-List`, `Nullpunkt`, `dRofus`, `eMails`, `Intro`, `Update`.

For detailed per-project vocabulary, see [reference.md](reference.md).

## 4. Entry rules

### 15-minute grid

All entries snap to 15-minute boundaries. Round start/end times to the
nearest quarter hour. Minimum entry: 0:15.

### One entry per meeting — never merge distinct meetings

Each distinct calendar meeting gets its own Toggl entry, even if
consecutive and on the same project. **Never combine two named meetings
into one entry.**

- "US Exchange" and "Goodbye Joe" → two entries, even if both Admin.
- "DP-Update Wim" and "Revizto Recap" → two entries, even back-to-back.
- An unnamed gap-fill **may** be absorbed into an adjacent named meeting
  on the same project (extend its duration) when the gap has no distinct
  identity. This is the only merge that is ever permitted.

**Example — gap-fill absorbed (ok):**
```
| 09:00 - 10:00 | 608_B12 | Projekt-Znüni | NEW      |
| 10:00 - 10:30 | 608_B12 | -             | gap-fill |  ← absorbed
| 10:30 - 11:30 | 608_B12 | BIM Exchange  | NEW      |  ← stays separate
```
Result: Projekt-Znüni 09:00–10:30 (gap absorbed), BIM Exchange 10:30–11:30.

**Never do this:**
```
| 09:00 - 11:30 | 608_B12 | Projekt-Znüni / BIM Exchange | NEW |  ← WRONG
```

### Overlap protection

Before creating any entry, always check existing entries for that day.
Existing entries have priority -- never overwrite or shrink them.
If a proposed entry overlaps, adjust or flag it transparently.

### Lunch

- A lunch break is always present on workdays.
- **Lunch ALWAYS falls inside the 12:30-14:00 window.** It may never start
  before 12:30 nor end after 14:00. Never place lunch at 12:00.
- Default duration is **30 minutes**. Never default to 1 hour. Propose 30 min unless the user says otherwise.
- If a meeting occupies the 12:30-14:00 window, fit lunch into whatever part
  of the window is free (e.g. 12:30-13:00 when a meeting starts at 13:00).
  A 1 h lunch is only possible when a full hour inside the window is free -
  never displace a meeting to make room.
- NEVER auto-fill lunch. Always ask the user for time and duration.
- Propose a default based on recent patterns but mark it `CONFIRM`.

### Gap filling

When the user provides arrival or departure time:
1. Query the day's entries.
2. Identify gaps between entries (excluding lunch).
3. Propose gap-fill entries by **rotating** across `DP_DTC - Admin`,
   `DP_DTC - Strategy/Initiatives`, and `DP_DTC - Tools/Development`
   — do not repeat the same project for every gap-fill.
   **Keep Admin low: roughly one Admin gap-fill per day (the morning
   eMails block), everything else Strategy/Initiatives or
   Tools/Development.** If the day already has several named Admin
   meetings, use no Admin gap-fill at all. Admin should not dominate
   a day's total.
4. Mark gap-fills as `gap-fill` status in the table.
5. After computing all entries, keep each gap-fill as its own entry.

### Monday is normally OOO

**The work week is Tuesday-Friday. Monday is out of office by default** -
never gap-fill a Monday and never propose one on your own.

The one exception: the user may **explicitly** ask for occasional Monday
work (typically a short afternoon or evening session, e.g. to top up the
monthly attendance target). Only then create Monday entries, only for the
hours they name, and never extend beyond them. Such sessions sit outside
the normal 08:45-18:45 span and need no lunch break.

### OOO blocks — "JHO ooo"

A block titled **"JHO ooo"** (any casing) means the user was **out of office for exactly that time range** — not the whole day.

- **Exclude that time range entirely**: no meeting entries, no gap-fills inside it.
- Other parts of the same day are tracked normally.
- **A `JHO ooo` block is usually just a BREAK, not a departure.** The working day continues after it. Never assume it ends the day.
- Only treat it as a departure if it clearly runs to the end of the working day AND nothing is scheduled after it — and even then, **ask** rather than assume.
- If a named meeting overlaps a `JHO ooo` range, **ask** — do not silently include or drop it.

### Wednesday early departure

Standard end-of-day on **Wednesdays is 17:30** (fixed obligation — kita pickup). Never propose gap-fills or entries past 17:30 on Wednesdays, regardless of what the calendar shows after that time.

### Meeting room bookings and duplicate blocks

Skip any calendar entry that exists to reserve a space or is a duplicate shell of a real meeting:

- Title contains **"Meeting Room"**, "Room for [X]", "Room Booking" → **skip**.
- A **generic title** like `DP_DTC - Meeting` sitting in the same slot as a specifically-named meeting → the generic one is the room/organizer shell. **Track the named meeting, skip the generic one.**
- The **same title appearing twice** in adjacent sub-columns of one day (two organizers, one meeting) → **count once**.

### Arrival and departure

- **Standard arrival: 08:45**, sometimes 09:00.
- **Standard departure: 18:30-18:45.**
- **Wednesday departure: 17:30** (fixed - kita pickup, see above).
- These are the defaults. Only deviate when the calendar or the user says so,
  and never invent a later departure than 18:45.

### New project numbers

When a meeting title contains a number prefix not matching any known
project (e.g. `509.1`, `632`), ask the user before creating a new
Toggl project. Never silently invent projects.

## 5. Conversation flow

### Mode A: Screenshot

User pastes an Outlook calendar screenshot.

1. Read the image carefully using the **Outlook time-reading rules**
   below. Extract meeting titles, exact start/end times.
2. Classify each meeting by Outlook status (see below). Skip free,
   ask about tentative, include busy/accepted.
3. Map each meeting to a project using Section 2 + recent entries.
4. Call `list_time_entries` for that day -- identify overlaps.
5. Merge consecutive same-project entries (Section 4).
6. Present the table (see Section 6).
7. Ask briefly: "Lunch? Arrival? Left at?"
8. On confirmation, create all entries and show links.

#### Outlook time-reading rules

- The calendar has hour marks on the left (9, 10, 11 …). Use them as
  a ruler. **Compute the px-per-hour spacing first**, then convert every
  block's top and bottom edge to a time with that constant.
- Measure each block's top and bottom edge against the hour grid.
  Do not guess or round down -- match the pixel position.
- Text length does not indicate duration. A one-line title can be a
  1-hour block; a three-line title can be 30 min.

#### Side-by-side blocks are usually SEQUENTIAL, not parallel

Outlook splits a day column into sub-columns, so blocks that look
side-by-side are often **back-to-back in time**. **Never infer overlap
from horizontal position.**

- Compare **vertical top edges**. Only if two blocks share
  substantially the same top *and* bottom edge are they truly concurrent.
- If block A's bottom edge equals block B's top edge, they are
  sequential — track both, one after the other.
- Only flag a genuine conflict when the vertical ranges actually
  overlap. Then ask which one the user attended.

#### Outlook meeting status

Outlook shows meeting status via background color AND left-edge border:

| Visual indicator | Status | Action |
|---|---|---|
| Solid blue background, solid left border | **Busy / Accepted** | Include normally |
| Light blue background + diagonal stripe / hatched pattern | **Tentative** | **Ask user: "Attended [title]?"** — never assume attended |
| **White / no background color** (transparent or very faint) | **Free** | **SKIP ENTIRELY — never track, no exceptions** |
| Cancelled / strikethrough text | **Cancelled** | Skip |

- **Free = white = invisible to Toggl.** If a block has no colored background, it is Free and must be ignored completely, regardless of what the text says.
- **Tentative = light blue with a diagonal stripe pattern.** Always ask the user whether they attended before including it.
- **`B012 Projekt-Znüni` is NEVER attended** - always skip it, never ask.
- Always check both the background color and left-edge border before including a meeting.
- When unsure whether an item is tentative or free, ask the user.

#### All-day banner row — ignore entirely

The narrow rows above the time grid (holding items like `Sommerferien`,
`XYZ_OoO`, `nil ooo Nils Lindhorst`, and **`+2` / `+3` collapse badges**)
are **all-day banners — almost always colleagues' out-of-office notices**.
They are not the user's meetings. **Never track them and never ask about
the `+N` badges** — just state what they are and move on.

### Mode B: Verbal input

User says something like "I talked with Wilson about Speckle for 45min".

1. Parse: person=Wilson, topic=Speckle, duration=45min.
2. Map: Wilson + Speckle = `DP_DTC - Strategy/Initiatives`, description `Speckle`.
3. Ask only what is missing (time? project correct?).
4. If ambiguous, present 2-3 project options briefly.
5. On confirmation, create and show link.

### Mode C: Day-fill

User says "I left Wednesday at 18:30" or "Tuesday I arrived at 8:15".

1. Query all entries for that day.
2. Identify arrival/departure boundaries.
3. Identify gaps.
4. Propose fills using recent project patterns.
5. Ask about lunch if not yet placed.
6. Present full day table.
7. On confirmation, create gap-fill entries.

### Combined

These modes mix freely. A user might paste a screenshot, then say
"I also had a quick call with Mo about BIM Standards, 15 min after the
last meeting" and then "I left at 18:00".

## 6. Output format

Always present entries in this table before creating them:

```
Day: Wednesday, 2026-05-27

| #  | Time          | Project              | Description          | Dur  | Status   |
|----|---------------|----------------------|----------------------|------|----------|
| 1  | 08:30 - 09:00 | DP_DTC - Admin       | -                    | 0:30 | gap-fill |
| 2  | 09:00 - 10:00 | 608_B12              | BIM JF               | 1:00 | existing |
| 3  | 10:00 - 11:30 | 608_B12              | dRofus / Support     | 1:30 | NEW      |
| 4  | 11:30 - 12:00 | DP_DTC - Admin       | -                    | 0:30 | gap-fill |
| 5  | 12:00 - 12:30 | ---                  | Lunch                | 0:30 | CONFIRM  |
| 6  | 12:30 - 14:00 | 608_B12              | Team Meeting         | 1:30 | NEW      |
```

**Status legend:**
- `existing` -- already in Toggl, untouched
- `NEW` -- proposed from user input
- `gap-fill` -- auto-proposed to fill time gaps
- `CONFIRM` -- needs explicit user confirmation (lunch, ambiguous mapping)

After creating entries, show each entry's Toggl link:
`https://track.toggl.com/timer/entry/{entry_id}`

## 7. Conversation style

- Very brief. No filler. No narration.
- Ask only what is missing, propose the rest.
- Group questions: "Lunch 12:00-12:30? Left at 18:00?"
- Always show the table before placing anything.
- After placement: one summary line + links. Done.
- If the user corrects something, update the table and re-confirm.
- Never repeat information the user already gave.
