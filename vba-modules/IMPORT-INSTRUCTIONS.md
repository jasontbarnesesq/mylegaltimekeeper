# VBA Module Import Instructions

These fixed `.bas`, `.cls`, and `.frm` files replace the buggy VBA modules inside
`JTBAdmin Client Intake and Tracking List Sheet 1 Form.xlsm`.

## Bugs Fixed

| # | Severity | Module | Description |
|---|----------|--------|-------------|
| 1 | **Critical** | `TimeEntryTools.bas` | **Sort never moved elements.** `rows.Add tmp,,j-1` used the 3rd "before" parameter with wrong index. Result: entries were output in original input order regardless of date. Fixed with array-based bubble sort. |
| 2 | **Critical** | `TimeEntryTools.bas` | **Month header printed before every row, not once per month.** The `ws.Cells(outR,1).Value=""` check was always `True` because `outR` always points to the next unwritten row. Fixed with a `headerWritten` boolean flag. |
| 3 | **Medium** | `TimeEntryTools.bas` | **Billable hours silently under-counted.** `= "Yes"` is case-sensitive; "yes" or "YES" were excluded. Fixed with `UCase$() = "YES"`. |
| 4 | **Medium** | `frmCalendar.frm` | **`UpdateMonthlyGroups` ran twice on every calendar pick** (once via `Worksheet_Change`, once explicitly). Caused double write, visible flicker. Removed the redundant explicit call. |
| 5 | **Low** | `TimeEntryTools.bas` | **`ClearContents` only covered 400 rows**; worst-case output needs up to 800 rows. Increased to 850. |
| 6 | **Low** | `frmCalendar.frm` + `clsDayButton.cls` | **`btn.Tag` stored dates as locale-dependent strings.** `CDate(btn.Tag)` could misparse on machines with different regional settings. Fixed by storing/reading as `CLng` serial number. |

---

## How to Apply the Fixes

### Step 1 — Open the VBA Editor
1. Open `JTBAdmin Client Intake and Tracking List Sheet 1 Form.xlsm` in Excel.
2. Press **Alt + F11** to open the Visual Basic Editor (VBE).

### Step 2 — Replace `TimeEntryTools` module
1. In the **Project Explorer** (left panel), expand your workbook.
2. Double-click **Modules → TimeEntryTools**.
3. Press **Ctrl + A** to select all code, then **Delete**.
4. Open `vba-modules/TimeEntryTools.bas` in a text editor, copy all content.
5. Paste into the now-empty `TimeEntryTools` module window.

> **Alternative:** Right-click **Modules** → **Remove TimeEntryTools** → **No** (don't export).
> Then right-click **Modules** → **Import File** → select `TimeEntryTools.bas`.

### Step 3 — Replace `frmCalendar` form
1. In the Project Explorer, right-click **Forms → frmCalendar** → **Remove frmCalendar** → **No**.
2. Right-click **Forms** → **Import File** → select `frmCalendar.frm`.

### Step 4 — Replace `clsDayButton` class
1. In the Project Explorer, right-click **Class Modules → clsDayButton** → **Remove clsDayButton** → **No**.
2. Right-click **Class Modules** → **Import File** → select `clsDayButton.cls`.

### Step 5 — `Sheet1` (no changes required)
`Sheet1.cls` is included for reference only. No changes were made to it.

### Step 6 — Save
1. Close the VBE (**Alt + Q** or the X button).
2. Save the workbook as `.xlsm` (**Ctrl + S**).

---

## Verification

After importing, test the following:

- **Sort:** Enter 3-4 time entries with dates out of order. The "Grouped by Month" section should display them in chronological order.
- **Month headers:** Each month group should have exactly **one** header row (e.g., "February 2026"), not one before every entry.
- **Billable hours:** Enter some rows with "yes" (lowercase) in the Billable column. The subtotal should include those hours in the "Billable:" field.
- **Calendar picker:** Double-click a date cell (A5–A204), pick a date from the calendar. The grouped output should refresh exactly once (no flicker/double update).
