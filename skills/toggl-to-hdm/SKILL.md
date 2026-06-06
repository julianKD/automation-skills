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
attendance slots from entry gaps, then fill everything via direct API calls.
Be brief and action-oriented.

## MCP dependencies

- `toggl-track` MCP — `list_time_entries`, `list_projects`
- `Claude in Chrome` MCP — XHR API calls + UI for adding missing project rows

---

## PPM API reference (complete)

The app is Odoo with a custom REST/JSON-RPC hybrid. **It uses XHR internally,
not fetch** — intercept with `XMLHttpRequest.prototype.send` not `window.fetch`.

All write endpoints use this envelope:
```json
{"params": {"data": { ...fields... }}}
```

### Project hours

| Action | Endpoint | Method |
|---|---|---|
| Create line | `/ts_22_api/timesheet_lines` | POST |
| Delete line | `/ts_22_api/timesheet_lines/{id}` | DELETE |

**Create body:**
```json
{
  "params": {
    "data": {
      "date": "2026-05-05",
      "task_id": 11557,
      "is_public_holiday": false,
      "is_sunday": false,
      "float_amount": 3.75,
      "timesheet_id": "51310"
    }
  }
}
```

- `timesheet_id` must be a **string** (`"51310"`, not `51310`)
- `float_amount` = hours as decimal (3h45m = 3.75, 8h30m = 8.5)
- `is_public_holiday: true` for Ascension, Labour Day, etc. — PPM accepts
  entries on holidays but needs the flag set
- Response: `{"jsonrpc":"2.0","id":null,"result":"ok"}`
- Duplicate entry: server returns `"There are other timesheets for this date
  for the given task!"` — safe to skip

### Attendance

| Action | Endpoint | Method |
|---|---|---|
| Create arrival | `/ts_22_api/attendance_lines` | POST |
| Set departure | `/ts_22_api/attendance_lines/{id}` | PUT |
| Delete slot | `/ts_22_api/attendance_lines/{id}` | DELETE |

**Create arrival body:**
```json
{
  "params": {
    "data": {
      "date": "2026-05-05",
      "time": "8:30",
      "timesheet_id": "51310",
      "attendance_type": "arrival",
      "entry_type": "by_hand"
    }
  }
}
```

Each POST arrival **creates a new slot** — there is no slot limit. Slots for
the same day are ordered by creation time (ascending ID).

**Set departure body:**
```json
{
  "params": {
    "data": {
      "date": "2026-05-05",
      "time": "12:30",
      "timesheet_id": "51310",
      "attendance_type": "departure",
      "id": 800159,
      "entry_type": "by_hand"
    }
  }
}
```

The `id` is the attendance_line record ID, obtained by GETting the timesheet
after the POST arrival. You **cannot** POST departure standalone — departure
requires an existing arrival record (PUT updates it).

### Read

| Action | Endpoint |
|---|---|
| Full timesheet | GET `/ts_22_api/timesheets/{id}` |
| Task list | GET `/ts_22_api/timesheets/get_projects/{id}` |

GET response structure:
- `tasks[]` → `{id, name_for_timesheet, float_amount, ...}` — task_ids needed for POSTing
- `timesheet_days[]` → per-day data:
  - `timesheet_lines[]` → `{id, float_amount, time_amount, ...}`
  - `attendance_lines[]` → `{id, arrival_time, departure_time, ...}`
- `num_attendance_slots` — current slot count

### XHR helper (use for all create/update)

```js
function xhrPost(url, data) {
  return new Promise((resolve) => {
    const xhr = new XMLHttpRequest();
    xhr.open(url.includes('/') && url.split('/').length > 4 ? 'PUT' : 'POST', url);
    xhr.setRequestHeader('Content-Type', 'application/json');
    xhr.onload = () => resolve(JSON.parse(xhr.responseText));
    xhr.send(JSON.stringify({params:{data}}));
  });
}
// Simpler named helpers:
function postLine(date, taskId, floatAmount, isPubHol, tsId) {
  return new Promise(res => {
    const xhr = new XMLHttpRequest();
    xhr.open('POST', '/ts_22_api/timesheet_lines');
    xhr.setRequestHeader('Content-Type', 'application/json');
    xhr.onload = () => res(JSON.parse(xhr.responseText));
    xhr.send(JSON.stringify({params:{data:{
      date, task_id: taskId, is_public_holiday: isPubHol||false,
      is_sunday: false, float_amount: floatAmount, timesheet_id: tsId
    }}}));
  });
}
function postArrival(date, time, tsId) {
  return new Promise(res => {
    const xhr = new XMLHttpRequest();
    xhr.open('POST', '/ts_22_api/attendance_lines');
    xhr.setRequestHeader('Content-Type', 'application/json');
    xhr.onload = () => res(JSON.parse(xhr.responseText));
    xhr.send(JSON.stringify({params:{data:{
      date, time, timesheet_id: tsId, attendance_type: "arrival", entry_type: "by_hand"
    }}}));
  });
}
function putDeparture(id, date, time, tsId) {
  return new Promise(res => {
    const xhr = new XMLHttpRequest();
    xhr.open('PUT', `/ts_22_api/attendance_lines/${id}`);
    xhr.setRequestHeader('Content-Type', 'application/json');
    xhr.onload = () => res(JSON.parse(xhr.responseText));
    xhr.send(JSON.stringify({params:{data:{
      date, time, timesheet_id: tsId, attendance_type: "departure", id, entry_type: "by_hand"
    }}}));
  });
}
function getTs(tsId) { return fetch(`/ts_22_api/timesheets/${tsId}`).then(r=>r.json()); }
function delay(ms) { return new Promise(res => setTimeout(res, ms)); }
```

**Use sequential calls with 300ms delay** to avoid `500 concurrent update` errors.

---

## DOM cell IDs (for reference / update-only use)

Every editable cell has a unique HTML ID:
```
ts22-data-cell-{lineIndex}-{dayIndex}
```
- `dayIndex` = day-of-month − 1 (May 5 → 4, May 31 → 30)
- `lineIndex` = row number assigned by server at creation time

**Important:** DOM injection (setting `textContent` + dispatching events) only
**updates** existing server records — it does **not create** new ones. On a fresh
or cleared timesheet, DOM injection silently fails. Always use the API above
for creating entries. DOM injection is useful only for correcting values that
already exist on the server.

---

## Step 1 — User provides the PPM URL

```
https://ppm.herzogdemeuron.com/ts22/timesheets/timesheet/{id}
```
Navigate there. Extract the timesheet ID (e.g. `51310`).

---

## Step 2 — Fetch timesheet state and task IDs

```js
// Run in javascript_tool after navigating
fetch('/ts_22_api/timesheets/51310').then(r=>r.json()).then(d => {
  window._tasks = {};
  (d.tasks||[]).forEach(t => { window._tasks[t.name_for_timesheet] = t.id; });
  window._numSlots = d.num_attendance_slots;
  window._tsData = d;
});
```

This gives you the task_id for every PPM project row — needed for the POST payload.

---

## Step 3 — Fetch Toggl data

- `list_projects` once to cache Toggl project IDs → names
- `list_time_entries` for the full month

Toggl `start` field: parsed as local DateTime by PowerShell's `ConvertFrom-Json`
— use it directly, do NOT add UTC offset again.

---

## Step 4 — Compute attendance slots per day

Sort each day's entries by start time. A gap ≥ 15 min between consecutive
entries = new slot boundary.

```
Slot = { start: first_entry.start, end: last_entry.stop } per group.
```

Find **max slots on any single day** — that's how many POSTs per day at maximum.

---

## Step 5 — Aggregate project hours

Per project per day: sum durations → round to nearest 15 min.
Convert to float: 3h45m = 3.75, 8h30m = 8.5, 0h30m = 0.5.
Discard if raw total < 7m30s.

---

## Step 6 — Map Toggl projects → PPM task IDs

Use the task map from Step 2 (`window._tasks`) and this lookup:

| Toggl name (contains) | PPM row label contains |
|---|---|
| `608_B12` | `608 Roche` |
| `494_UZH` | `494 FORUM` |
| `509.1.*Currie` | `509.1` |
| `347.6_Toggenburg` | `374.6` |
| `632.*Mered` | `632 Mered` |
| `DP_DTC.*Admin` | `/ Admin` |
| `DP_DTC.*SLaT` | `/ SLaT` |
| `DP_DTC.*Strategy` | `/ Strategy` |
| `DP_DTC.*Tools` | `/ Tools` |
| `DP_DTC.*Training` | `/ Training` |
| `DP_DTC.*Outreach` | `/ Outreach` |
| `DP_DTC.*Support` | `/ Support` |
| `422_RT` | `422` | ... etc (see full mapping table below)

**Full mapping table:**

| Toggl | PPM project | PPM task |
|---|---|---|
| `608_B12` | `608` | `B12` |
| `422_RT` | `422` | `RT` |
| `425.*Center` | `425` | `Center` |
| `425.*preMove` | `425` | `preMove` |
| `497_USB` | `497` | `USB` |
| `537_SLE` | `537` | `SLE` |
| `641_Bau124` | `641` | `Bau124` |
| `650_UC` | `650` | `UC` |
| `655_UM6P` | `655` | `UM6P` |
| `647_Monte` | `647` | `Monte` |
| `469_NG20` | `469` | `NG20` |
| `623_JBC` | `623` | `JBC` |
| `680_Breakthrough` | `680` | `Breakthrough` |
| `540_Hölzli` | `540` | `Hölzli` |
| `630_Dreispitz` | `630` | `Dreispitz` |
| `617_CST` | `617` | `CST` |
| `482_Titlis` | `482` | `Titlis` |
| `494_UZH` | `494` | `UZH` |
| `366_Lusail` | `366` | `Lusail` |
| `180.4_Elsässer` | `180` | `Elsässer` |
| `347.6_Toggenburg` | `374` | `Toggenburg` |
| `509.1.*Currie` | `509` | `Currie` |
| `632.*Mered` | `632` | `Mered` |
| `DP_DTC.*Admin` | `DP_DTC` | `Admin` |
| `DP_DTC.*SLaT` | `DP_DTC` | `SLaT` |
| `DP_DTC.*Strategy` | `DP_DTC` | `Strategy` |
| `DP_DTC.*Tools` | `DP_DTC` | `Tools` |
| `DP_DTC.*Training` | `DP_DTC` | `Training` |
| `DP_DTC.*Outreach` | `DP_DTC` | `Outreach` |
| `DP_DTC.*Support` | `DP_DTC` | `Support` |
| `DP_DTC.*DT\b` | `DP_DTC` | `DT` |
| `905.*Event` | `905` | `Event` |
| `924.*Academy` | `924` | `Academy` |
| `934.*BIM` | `934` | `BIM` |
| `934.*General` | `934` | `General` |
| `934.*Tools` | `934` | `Tools` |

For any unmapped project, ask the user for the PPM project + task search terms,
add the row via UI, then re-fetch task IDs.

---

## Step 7 — Present summary table

Show before touching PPM and wait for confirmation.

---

## Step 8 — Add missing project rows via UI

For each project not yet in `window._tasks`:

1. Click "Add project" link
2. Type PPM project search term → select match
3. Type task search term → select, repeat for multiple tasks
4. Click Save

Re-fetch task IDs (Step 2) to get the new `task_id` values.

---

## Step 9 — Batch create project hours via XHR

```js
(async () => {
  const tsId = "51310"; // string
  const entries = [
    // [date, taskId, floatAmount, isPublicHoliday?]
    ["2026-05-05", 11557, 3.75],
    ["2026-05-14", 11552, 8.5, true],  // public holiday
    // ... all entries
  ];
  const results = [];
  for (const [date, taskId, amt, isPubHol] of entries) {
    const r = await postLine(date, taskId, amt, isPubHol||false, tsId);
    results.push({date, taskId, amt, result: r.result, error: r.error?.data?.message});
    await delay(300);
  }
  window._lineResults = results;
})();
```

Check results: `r.result === 'ok'` = success.
`"There are other timesheets for this date for the given task!"` = already exists (skip).

---

## Step 10 — Batch create attendance via XHR

**Important sequence:** POST arrival → GET timesheet to find record ID → PUT departure.
Departure cannot be POSTed standalone — it requires an existing arrival record.

```js
(async () => {
  const tsId = "51310";
  const plan = [
    // [date, slot1_arr, slot1_dep, slot2_arr, slot2_dep, slot3_arr, slot3_dep]
    ["2026-05-05", "8:30", "12:30", "13:30", "18:45", null, null],
    ["2026-05-06", "8:30", "12:30", "13:30", "17:00", null, null],
    // days with 1 slot:
    ["2026-05-18", "10:00", "11:30", null, null, null, null],
    // days with 3 slots:
    ["2026-05-21", "8:30", "12:00", "13:00", "15:00", "18:00", "21:00"],
  ];

  // Step A: POST all slot 1 arrivals
  for (const [date, s1arr] of plan) {
    if (!s1arr) continue;
    await postArrival(date, s1arr, tsId);
    await delay(300);
  }

  // Step B: GET to find slot 1 IDs
  const data1 = await getTs(tsId);
  const slot1Ids = {};
  data1.timesheet_days.forEach(day => {
    const atts = day.attendance_lines || [];
    if (atts.length >= 1) slot1Ids[day.date] = atts[0].id;
  });

  // Step C: PUT slot 1 departures
  for (const [date, s1arr, s1dep] of plan) {
    if (!s1dep || !slot1Ids[date]) continue;
    await putDeparture(slot1Ids[date], date, s1dep, tsId);
    await delay(300);
  }

  // Step D: POST slot 2 arrivals
  for (const [date,,, s2arr] of plan) {
    if (!s2arr) continue;
    await postArrival(date, s2arr, tsId);
    await delay(300);
  }

  // Step E: GET to find slot 2 IDs (atts[1] per day)
  const data2 = await getTs(tsId);
  const slot2Ids = {};
  data2.timesheet_days.forEach(day => {
    const atts = day.attendance_lines || [];
    if (atts.length >= 2) slot2Ids[day.date] = atts[1].id;
  });

  // Step F: PUT slot 2 departures
  for (const [date,,, s2arr, s2dep] of plan) {
    if (!s2dep || !slot2Ids[date]) continue;
    await putDeparture(slot2Ids[date], date, s2dep, tsId);
    await delay(300);
  }

  // Repeat for slot 3 (atts[2] per day) if needed...

  window._attDone = true;
})();
```

---

## Step 11 — Verify

Reload the page and check:
- All attendance rows show correct arrival/departure per day per slot
- All project rows show correct hours in the right date columns
- "Not allocated Hours (DIV)" is near zero on filled days
- No validation error banner at top

One summary line. Done.

---

## Clearing the timesheet (optional pre-step)

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

After clearing, retry any 500s individually. Reload to confirm empty sheet.

---

## Error handling

| Situation | Action |
|---|---|
| `"There are other timesheets for this date for the given task!"` | Entry already exists — skip, don't treat as error |
| 500 on POST/PUT/DELETE | Concurrent update — retry after 500ms |
| `'NoneType' object has no attribute '__getitem__'` | Wrong payload format — ensure body is `{"params":{"data":{...}}}` |
| Departure POST returns mandatory field error | You cannot POST departure — use PUT with an existing arrival's ID |
| Project row not in task map | Add via UI, re-fetch task IDs |
| Toggl project unmapped | Ask user for PPM project + task search terms |
| DOM injection doesn't persist on reload | Use the XHR API — DOM writes never create server records |

---

## Conversation style

- Show summary table first — always wait for confirmation.
- One brief progress line while filling.
- After completion: one summary line. Done.
- Never narrate — just do it and report.
