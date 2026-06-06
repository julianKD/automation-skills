---
name: toggl-to-hdm
description: >-
  Transfer a week's or month's Toggl time entries into the HdM PPM timesheet at
  ppm.herzogdemeuron.com. Use when the user wants to sync, transfer, export,
  or push Toggl hours to PPM, or says "fill my PPM from Toggl", "sync
  timesheets", or "transfer this week to PPM".
---

# Toggl → HdM PPM Transfer

Pull Toggl entries for a period, aggregate by project and day, then fill the
HdM PPM timesheet via JS batch injection. Be brief and action-oriented.

## MCP dependencies

- `toggl-track` MCP — reads time entries (`list_time_entries`, `list_projects`)
- `Claude in Chrome` MCP — drives the PPM browser UI and runs JS

---

## How PPM cells work (critical for injection)

Each data cell has a unique HTML ID:

```
ts22-data-cell-{lineIndex}-{dayIndex}
```

- **lineIndex** = the row number for that project/task (varies per timesheet)
- **dayIndex** = day-of-month minus 1 (May 1 → 0, May 5 → 4, May 31 → 30)

This means you can access any cell directly:

```js
document.getElementById('ts22-data-cell-11-4')  // line 11, May 5
```

Never use DOM column indices or X-position matching — they are offset-prone.
Always use cell IDs.

---

## 1. User provides the PPM URL

Ask the user to paste the URL of the timesheet they want to fill:
```
https://ppm.herzogdemeuron.com/ts22/timesheets/timesheet/{id}
```

Navigate to that URL.

---

## 2. Discover existing project rows via JS

Run this to find all project rows and their lineIndices:

```js
const lineMap = {};
document.querySelectorAll('tr').forEach(row => {
  const label = row.querySelector('td:not([contenteditable])')?.textContent?.trim() || '';
  if (!label || label.length < 3) return;
  const firstCell = row.querySelector('td[id^="ts22-data-cell-"]');
  if (!firstCell) return;
  const lineIdx = firstCell.id.split('-')[3];
  lineMap[label] = lineIdx;
});
JSON.stringify(lineMap, null, 2);
```

This returns the full label → lineIndex map for the current timesheet.

---

## 3. Fetch Toggl data

Call `list_projects` once to cache project IDs → names.
Call `list_time_entries` for the full month (or week) of the timesheet.

Aggregate by **project × calendar day**:
- Sum all durations per project per day
- Round each daily total to nearest 15 min
- Discard entries < 7:30 s raw duration (rounds to 0)
- Minimum kept: 0:15

---

## 4. Project mapping — Toggl → PPM row

Match Toggl project names to PPM row labels using this table.
The PPM label keyword is used for fuzzy matching against the lineMap from step 2.

| Toggl project name (contains) | PPM label keyword | PPM project search | PPM task search |
|---|---|---|---|
| `608_B12` | `608 Roche` | `608` | `B12` |
| `422_RT` | `422` | `422` | `RT` |
| `425 Roche pRED.*Center` | `425.*Center` | `425` | `Center` |
| `425 Roche pRED.*preMove` | `425.*preMove` | `425` | `preMove` |
| `497_USB` | `497` | `497` | `USB` |
| `537_SLE` | `537` | `537` | `SLE` |
| `641_Bau124` | `641` | `641` | `Bau124` |
| `650_UC` | `650` | `650` | `UC` |
| `655_UM6P` | `655` | `655` | `UM6P` |
| `647_Monte` | `647` | `647` | `Monte` |
| `469_NG20` | `469` | `469` | `NG20` |
| `623_JBC` | `623` | `623` | `JBC` |
| `680_Breakthrough` | `680` | `680` | `Breakthrough` |
| `540_Hölzli` | `540` | `540` | `Hölzli` |
| `630_Dreispitz` | `630` | `630` | `Dreispitz` |
| `617_CST` | `617` | `617` | `CST` |
| `482_Titlis` | `482` | `482` | `Titlis` |
| `494_UZH` | `494 FORUM` | `494` | `UZH` |
| `366_Lusail` | `366` | `366` | `Lusail` |
| `180.4_Elsässer` | `180` | `180` | `Elsässer` |
| `347.6_Toggenburg` | `374.6` | `374` | `Toggenburg` |
| `509.1.*Currie` | `509.1` | `509` | `Currie` |
| `632.*Mered` | `632 Mered` | `632` | `Mered` |
| `DP_DTC.*Admin` | `/ Admin` | `DP_DTC` | `Admin` |
| `DP_DTC.*SLaT` | `/ SLaT` | `DP_DTC` | `SLaT` |
| `DP_DTC.*Strategy` | `/ Strategy` | `DP_DTC` | `Strategy` |
| `DP_DTC.*Tools` | `/ Tools` | `DP_DTC` | `Tools` |
| `DP_DTC.*Training` | `/ Training` | `DP_DTC` | `Training` |
| `DP_DTC.*Outreach` | `/ Outreach` | `DP_DTC` | `Outreach` |
| `DP_DTC.*Support` | `/ Support` | `DP_DTC` | `Support` |
| `DP_DTC.*DT` | `/ DT` | `DP_DTC` | `DT` |
| `905.*Event` | `905` | `905` | `Event` |
| `924.*Academy` | `924` | `924` | `Academy` |
| `934.*BIM` | `934.*BIM` | `934` | `BIM` |
| `934.*General` | `934.*General` | `934` | `General` |
| `934.*Tools` | `934.*Tools` | `934` | `Tools` |

If a Toggl project has no match, **flag it and ask the user** for:
1. The PPM project search term
2. The PPM task/phase search term

---

## 5. Add missing project rows via UI

For each PPM project needed that does NOT appear in the lineMap from step 2:

1. Click "Add project" link
2. In the modal: type the PPM project search term, select the match
3. Type the task search term, click to add it as a tag
4. Repeat for additional tasks from the same project (they can be added in one modal)
5. Click Save

After saving, re-run the lineMap discovery script to get updated lineIndices.

---

## 6. Attendance — manual only

⚠️ **The user must fill attendance slots manually.**

Toggl does not reliably encode start-of-day and end-of-day:
- Many entries use `duronly: true` (only duration stored, times unreliable)
- Even reliable entries don't capture lunch breaks or gaps between tasks
- Deriving attendance windows from first/last entry timestamps would be wrong

Tell the user: *"Attendance slots need to be entered manually — I'll fill all
the project hours now, please add your arrival/departure times yourself."*

---

## 7. Present summary table

Show this before injecting anything:

```
Month: May 2026 — Timesheet #51310

⚠️ Attendance: manual (please fill arrival/departure yourself)

| Date       | Day | Project              | Hours |
|------------|-----|----------------------|-------|
| 05.05.26   | Tue | DP_DTC / Admin       | 3:45  |
| 05.05.26   | Tue | 608 Roche B12        | 0:30  |
| ...        | ... | ...                  | ...   |

Unmapped Toggl projects: none
Missing PPM rows (to add): none

Proceed? (y / adjust)
```

Wait for confirmation before injecting.

---

## 8. Fill via JS batch injection

Once confirmed, run the injection in one `javascript_tool` call:

```js
// lineMap: built from step 2 + 5 (lineIndex per keyword)
// payload: {lineIndex: {dayIndex: "H:MM"}}
// dayIndex = day_of_month - 1

function setCell(lineIdx, dayIdx, value) {
  const cell = document.getElementById(`ts22-data-cell-${lineIdx}-${dayIdx}`);
  if (!cell) return `MISSING: line=${lineIdx} day=${dayIdx}`;
  const existing = cell.textContent.trim();
  if (existing && existing !== '00:00') return `SKIP: line=${lineIdx} day=${dayIdx} (has: ${existing})`;
  cell.focus();
  cell.textContent = value;
  cell.dispatchEvent(new Event('input', {bubbles: true}));
  cell.dispatchEvent(new Event('change', {bubbles: true}));
  cell.blur();
  return `SET: line=${lineIdx} day=${dayIdx} = ${value}`;
}
```

Build the payload as `{lineIndex: {dayIndex: "H:MM"}}` using:
- `lineIdx` from the lineMap (step 2)
- `dayIdx` = `date.getDate() - 1` (May 5 → 4, May 31 → 30)

Report: `✅ SET N cells, ⏭ SKIPPED M (already filled)`

### Holiday/weekend dialogs

Entries on public holidays or Sundays trigger a warning dialog.
For each: check the confirmation checkbox, then click OK. Continue.

These dialogs appear one at a time — handle each before the next injection
if they queue up.

---

## 9. Verify

After injection, reload the page and check:
- Values appear in the correct date columns
- "Not allocated Hours (DIV)" row shows expected values
  (will be negative until attendance is added — that is normal)
- No unexpected values on weekend/holiday columns

Report one summary line. Done.

---

## 10. Error handling

| Situation | Action |
|---|---|
| Cell already filled (non-zero) | Skip and report |
| Project row missing from PPM | Add via UI (step 5), then re-discover |
| Toggl project unmapped | Flag, ask user for PPM search terms |
| Concurrent update warning | Reload page, check what persisted, re-run for missing cells |
| Holiday/weekend dialog | Check box, click OK |

---

## Conversation style

- Show summary table first, always wait for confirmation.
- While filling: brief progress only.
- After completion: one summary line + note about manual attendance. Done.
- Never explain what you are about to do step by step — just do it and report.
