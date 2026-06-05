---
name: hdm-timesheet
description: >
  Guide for filling in the HdM PPM timesheet app at ppm.herzogdemeuron.com.
  Use this skill whenever the user wants to log hours, add attendance slots,
  add projects, navigate or understand the timesheet table structure, or
  interact with the HdM timesheet system in any way. Also trigger when the
  user mentions "timesheet", "PPM", "SLaT", "DP_DTC", "attendance slot",
  "submit to manager", or asks how to track time at HdM.
---

# HdM PPM Timesheet — How-To Guide

URL: `https://ppm.herzogdemeuron.com/ts22/timesheets/timesheet/<id>`

---

## Table Structure

The timesheet is a scrollable horizontal grid. Each column is one calendar day (`DD.MM.YY` + weekday name). The last column on the right shows **Totals**.

### Top area
| Element | Description |
|---|---|
| Header | "YYYY / Month / Person Name" |
| Status buttons (top-right) | **New → Open → Submitted to manager → Approved → Cancelled** |
| Pensum % | The person's employment percentage |
| Approver | Dropdown — the manager who approves the sheet |
| Unlocked button | Appears when submitted; click to reopen for editing |
| Submit to manager | Sends the sheet for approval |

### Day color coding
- **Yellow/gold** = weekends and public holidays
- **Highlighted border** = today's date

---

## Row-by-row breakdown

### Attendance section
| Row | Type | Notes |
|---|---|---|
| Attendance time slot rows (icon rows) | **Editable** | Added manually; one row per time slot; enter start + end time per day |
| *Add attendance time slot* link | Action | Clicking adds a new icon row |
| Attendance Hours | Calculated | Sum of all slot durations per day |
| Mandatory Break deducted | Calculated | Auto-deducted based on duration |

### Project section
| Row | Type | Notes |
|---|---|---|
| Project rows (e.g. "DP_DTC Design Technology / SLaT") | **Editable** | Added manually; enter hours logged per day in each cell |
| *Add project* link | Action | Opens the "Adding task…" modal |
| Not allocated Hours (DIV) | Calculated | Attendance hours not assigned to any project |
| Worked Hours | Calculated | Total hours logged across all projects |
| Target time | Calculated | 06:48 on working days (= 80% of 8:30 for 80% Pensum, etc.) |
| Holidays time | Reference | Public holiday hours |
| Overtime | Calculated | Positive = surplus, **negative = under target** |

### Bottom panels
| Panel | Location | Content |
|---|---|---|
| Overview by Approved Timesheets | Bottom-left | Holiday rollover, allowance, budget, taken, planned holidays, holiday balance, compensation taken, planned compensation, overtime balance |
| History | Bottom-right | Message box + "Send Comment" button for notes to approver |

---

## How to add an attendance time slot

1. Click the **"Add attendance time slot"** link — a new icon row appears in the grid.
2. Click on a **cell for the desired day** — the cell activates as an input.
3. Type the **start time** (e.g. `8:00`) and press **Tab** to move to the end time field.
4. Enter the **end time** (e.g. `17:00`).

> ⚠️ **Public holidays** (e.g. May 1st) trigger a warning dialog: *"Work on Public Holidays prohibited"*. You must check the confirmation box and click OK to proceed, or choose a different day.

---

## How to add a project

1. Click the **"Add project"** link — the **"Adding task…"** modal dialog opens.
2. The **"From"** dropdown defaults to `Project` — leave it as is.
3. In **"Project / Business Department"**: type a **short code or abbreviation** (e.g. `DP_DTC`) rather than the full name. Autocomplete filters results.
4. Click the matching option in the dropdown.
5. In **"Phase / Task"**: type a **short keyword** (e.g. `SLaT`) to filter options.
6. Click the matching option — it appears as a **tag** (with an × to remove it).
7. **You can select multiple tasks** before saving — just repeat steps 5–6 for each task. All selected tasks appear as tags.
8. Click **Save** — each selected task gets its own project row in the grid.

> 💡 **Search tip:** Always use short codes or abbreviations in both dropdowns. Typing the full project name is slower and may not match. For example: `DP_DTC` finds "DP_DTC Design Technology", `SLaT` finds the SLaT task immediately.

---

## Logging hours against a project

Once a project row exists in the grid:
- Click on the **cell for the desired day** in that project's row.
- Type the number of hours (e.g. `2:00` for 2 hours).
- Press **Tab** or click away to confirm.

---

## Workflow summary

```
1. Open timesheet for the correct month
2. Add attendance time slot(s) → enter start/end times per day
3. Add project(s) via "Add project" link → search by short code, pick task(s), Save
4. Log hours per day in each project row
5. Review Overtime row — ensure it's not unexpectedly negative
6. Add a comment in History if needed
7. Click "Submit to manager" when complete
```
