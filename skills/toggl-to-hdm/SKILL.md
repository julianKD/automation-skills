---
name: toggl-to-hdm
description: >-
  Transfer a week's or month's Toggl time entries into the HdM PPM timesheet at
  ppm.herzogdemeuron.com. Use when the user wants to sync, transfer, export,
  or push Toggl hours to PPM, or says "fill my PPM from Toggl", "sync
  timesheets", or "transfer this week to PPM".
---

# Toggl → HdM PPM Transfer

Pull Toggl entries for a period, aggregate by project and day, compute
attendance slots from entry gaps, then fill everything via JS batch injection.
Be brief and action-oriented.

## MCP dependencies

- `toggl-track` MCP — `list_time_entries`, `list_projects`
- `Claude in Chrome` MCP — JS injection + UI for adding missing rows

---

## PPM API (use this for all reads/deletes)

PPM exposes a REST API at `/ts_22_api/`:

| Action | Endpoint | Method |
|---|---|---|
| Fetch full timesheet data | `/ts_22_api/timesheets/{id}` | GET |
| Delete a project hour entry | `/ts_22_api/timesheet_lines/{lineId}` | DELETE |
| Delete an attendance entry | `/ts_22_api/attendance_lines/{lineId}` | DELETE |

The GET response contains `timesheet_days[]` — each day has:
- `timesheet_lines[]` → `{id, float_amount, time_amount, ...}` (project hours)
- `attendance_lines[]` → `{id, arrival_time, departure_time, ...}`

Use these IDs to DELETE entries directly. **Sequential deletes with ~500ms
delay** avoid `500 concurrent update` errors from the server.

```js
// Fetch all line IDs
const data = await fetch('/ts_22_api/timesheets/{id}').then(r => r.json());

// Clear all project hours sequentially
for (const day of data.timesheet_days) {
  for (const line of day.timesheet_lines) {
    if (line.float_amount > 0) {
      await fetch(`/ts_22_api/timesheet_lines/${line.id}`, {method: 'DELETE'});
      await new Promise(r => setTimeout(r, 400));
    }
  }
}

// Clear all attendance lines sequentially
for (const day of data.timesheet_days) {
  for (const att of day.attendance_lines) {
    if (att.arrival_time !== '00:00' || att.departure_time !== '00:00') {
      await fetch(`/ts_22_api/attendance_lines/${att.id}`, {method: 'DELETE'});
      await new Promise(r => setTimeout(r, 400));
    }
  }
}
```

**Note:** `javascript_tool` does not support top-level `await`. Wrap in an
async IIFE or use `.then()` chains + `window._results` to collect output.

---

## PPM cells (for writing/injection)

Every editable cell has a unique HTML ID:

```
ts22-data-cell-{lineIndex}-{dayIndex}
```

- **lineIndex** — row number (attendance rows first, then project rows)
- **dayIndex** — day-of-month minus 1 (May 1 → 0, May 5 → 4, May 31 → 30)

Access any cell directly: `document.getElementById('ts22-data-cell-11-4')`

**Never use DOM column indices or X-position** — they are offset-prone due to
header/data row structural differences. Cell IDs are the only reliable method.

**Setting values** works via DOM injection (textContent + events).
**Clearing values** requires the DELETE API above — DOM clearing does not persist.

---

## Step 1 — User provides the PPM URL

Ask for the timesheet URL:
```
https://ppm.herzogdemeuron.com/ts22/timesheets/timesheet/{id}
```
Navigate there.

---

## Step 2 — Discover existing rows via JS

Run once after navigating:

```js
// Project rows
const lineMap = {};
document.querySelectorAll('tr').forEach(row => {
  const label = row.querySelector('td:not([contenteditable])')?.textContent?.trim() || '';
  if (!label || label.length < 3) return;
  const firstCell = row.querySelector('td[id^="ts22-data-cell-"]');
  if (!firstCell) return;
  lineMap[label] = parseInt(firstCell.id.split('-')[3]);
});

// Attendance rows (ts22-time-row class, no label)
const attendanceLineIdxs = [];
document.querySelectorAll('tr.ts22-time-row').forEach(row => {
  const firstCell = row.querySelector('td[id^="ts22-data-cell-"]');
  if (firstCell) attendanceLineIdxs.push(parseInt(firstCell.id.split('-')[3]));
});
// attendanceLineIdxs sorted ascending: [0,1,2,3...] → pairs: [0,1]=slot1, [2,3]=slot2
// Within each pair: lower lineIdx = arrival row, higher = departure row

JSON.stringify({lineMap, attendanceLineIdxs});
```

---

## Step 3 — Fetch Toggl data

- `list_projects` once to cache project IDs → names
- `list_time_entries` for the full month of the timesheet

All entries are entered manually in Toggl — **start/stop times are reliable**.

---

## Step 4 — Compute attendance slots per day

Group each day's entries into attendance slots by detecting gaps ≥ 15 min:

```
Sort entries by start time.
New slot starts when: gap between consecutive entries ≥ 15 min.
Slot = { start: first_entry.start, end: last_entry.stop } within the group.
```

Example for May 27:
```
09:00–10:00, 10:00–11:00, 11:00–12:00, 12:00–13:00  → slot 1: 09:00–13:00
── gap 2h ──
15:00–16:00, 16:00–18:45                             → slot 2: 15:00–18:45
```

Result per day: list of `{start, end}` pairs.
Find **max slots needed on any single day** → that's how many attendance rows to add.

---

## Step 5 — Aggregate project hours

Per project per day: sum durations, round to nearest 15 min.
Discard if raw total < 7 min 30 s (rounds to 0). Minimum kept: 0:15.

---

## Step 6 — Map Toggl projects → PPM rows

Match Toggl project names against the lineMap from Step 2.

| Toggl name (contains) | PPM label keyword | PPM project | PPM task |
|---|---|---|---|
| `608_B12` | `608 Roche` | `608` | `B12` |
| `422_RT` | `422` | `422` | `RT` |
| `425.*Center` | `425.*Center` | `425` | `Center` |
| `425.*preMove` | `425.*preMove` | `425` | `preMove` |
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
| `DP_DTC.*DT\b` | `/ DT` | `DP_DTC` | `DT` |
| `905.*Event` | `905` | `905` | `Event` |
| `924.*Academy` | `924` | `924` | `Academy` |
| `934.*BIM` | `934.*BIM` | `934` | `BIM` |
| `934.*General` | `934.*General` | `934` | `General` |
| `934.*Tools` | `934.*Tools` | `934` | `Tools` |

**For any unmapped Toggl project:** flag it and ask the user:
> "Project `XYZ` has no PPM mapping. What should I search for in PPM — project name and task/phase?"

Toggl projects have no phase/task info — the user must supply this for any
project not already in the mapping table above.

---

## Step 7 — Present summary table

Show before touching PPM:

```
Month: May 2026 — Timesheet #51310

ATTENDANCE (computed from entry gaps, ≥15 min gap = new slot):
┌─────────┬──────────────────────────────────┐
│ Day     │ Slots                            │
├─────────┼──────────────────────────────────┤
│ Tue 05  │ 06:30–13:00 │ 14:00–16:45       │
│ Wed 06  │ 06:30–15:00                      │
│ Thu 07  │ 06:30–15:00                      │
│ ...     │ ...                              │
└─────────┴──────────────────────────────────┘
→ Max slots on any day: 2 → will add 2 attendance rows

PROJECT HOURS:
│ Date      │ Project            │ Hours │
│ 05.05.26  │ DP_DTC / Admin     │ 3:45  │
│ 05.05.26  │ 608 Roche B12      │ 0:30  │
│ ...       │ ...                │ ...   │

Missing PPM rows (need to add): DP_DTC / Training, DP_DTC / Support
Unmapped Toggl projects: none

Proceed? (y / adjust)
```

Wait for confirmation.

---

## Step 8 — Add missing project rows via UI

For each project row not yet in lineMap:

1. Click "Add project"
2. Type PPM project search term → select match
3. Type task search term → click to add tag
4. Multiple tasks from same project: add all as tags before saving
5. Click Save

Re-run the row discovery JS to get updated lineMap.

---

## Step 9 — Add attendance slot rows via UI

Click "Add attendance time slot" exactly **max_slots** times
(= max number of slots needed on any single day).

Then re-run the discovery JS to get `attendanceLineIdxs`.

Pair them: `[idx[0], idx[1]]` = slot 1, `[idx[2], idx[3]]` = slot 2, etc.
Lower lineIdx of each pair = arrival row, higher = departure row.

---

## Step 10 — Inject everything via JS

One call fills all attendance + all project hours:

```js
function setCell(lineIdx, dayIdx, value) {
  const cell = document.getElementById(`ts22-data-cell-${lineIdx}-${dayIdx}`);
  if (!cell) return `MISSING line=${lineIdx} day=${dayIdx}`;
  const existing = cell.textContent.trim();
  if (existing && existing !== '00:00') return `SKIP line=${lineIdx} day=${dayIdx} (${existing})`;
  cell.focus();
  cell.textContent = value;
  cell.dispatchEvent(new Event('input', {bubbles: true}));
  cell.dispatchEvent(new Event('change', {bubbles: true}));
  cell.blur();
  return `SET line=${lineIdx} day=${dayIdx} = ${value}`;
}

// Attendance: dayIdx = day_of_month - 1
// attendanceSlots: { dayIdx: [{start, end}, ...] }
for (const [dayIdx, slots] of Object.entries(attendanceSlots)) {
  slots.forEach((slot, i) => {
    const arrivalLine  = attendanceLineIdxs[i * 2];
    const departureLine = attendanceLineIdxs[i * 2 + 1];
    setCell(arrivalLine,   dayIdx, slot.start);  // e.g. "6:30"
    setCell(departureLine, dayIdx, slot.end);    // e.g. "13:00"
  });
}

// Project hours: dayIdx = day_of_month - 1
for (const [lineIdx, dayHours] of Object.entries(projectPayload)) {
  for (const [dayIdx, value] of Object.entries(dayHours)) {
    setCell(lineIdx, dayIdx, value);
  }
}
```

Report: `✅ SET N cells, ⏭ SKIPPED M (already filled)`

### Holiday/weekend dialogs

Entries on public holidays or Sundays trigger a confirmation dialog.
Check the checkbox, click OK. Continue — these are expected when the user
has Toggl entries on those days.

---

## Step 11 — Verify

Reload the page and check:
- Attendance rows show correct arrival/departure per day per slot
- Project rows show correct hours in the right date columns
- "Not allocated Hours (DIV)" is close to zero on filled days

One summary line. Done.

---

## Clearing the timesheet (optional pre-step)

If the user asks to clear the timesheet before filling, use the API:

```js
(async () => {
  const data = await fetch('/ts_22_api/timesheets/51310').then(r => r.json());
  const results = [];
  for (const day of data.timesheet_days) {
    for (const line of (day.timesheet_lines || [])) {
      if (line.float_amount > 0) {
        const r = await fetch(`/ts_22_api/timesheet_lines/${line.id}`, {method:'DELETE'});
        results.push(`line ${line.id}: ${r.status}`);
        await new Promise(res => setTimeout(res, 400));
      }
    }
    for (const att of (day.attendance_lines || [])) {
      if (att.arrival_time !== '00:00' || att.departure_time !== '00:00') {
        const r = await fetch(`/ts_22_api/attendance_lines/${att.id}`, {method:'DELETE'});
        results.push(`att ${att.id}: ${r.status}`);
        await new Promise(res => setTimeout(res, 400));
      }
    }
  }
  window._clearResults = results;
})();
```

After running, check `window._clearResults` for any 500s and retry those IDs.
Reload the page to confirm the sheet is empty.

---

## Error handling

| Situation | Action |
|---|---|
| Cell already filled (non-zero) | Skip and report |
| Project row missing | Add via UI (Step 8), re-discover |
| Toggl project unmapped | Ask user for PPM project + task search terms |
| 500 on DELETE | Server concurrent update — retry that ID sequentially after 500ms |
| Holiday/weekend dialog | Check box, click OK |
| Attendance lineIdx pair unclear | Check `tr.ts22-time-row` count matches expected slots |
| DOM clear doesn't persist on reload | Use DELETE API instead — DOM clearing never saves |

---

## Conversation style

- Show summary table (Step 7) first — always wait for confirmation.
- One brief progress line while filling.
- After completion: one summary line. Done.
- Never narrate what you're about to do — just do it and report.
