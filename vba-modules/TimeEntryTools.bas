Attribute VB_Name = "TimeEntryTools"
'========================
' TimeEntryTools  (FIXED)
'========================
' Fixes applied:
'   1. [CRITICAL] Sort: replaced broken Collection-swap with array-based bubble sort.
'      Original used rows.Add tmp,,j-1 (3rd "before" param) which is off by one position
'      and never actually moved elements. Fixed using a Long array with proper index swap.
'   2. [CRITICAL] Month header: replaced fragile ws.Cells(outR,1).Value="" check with a
'      boolean flag (headerWritten). The cell-empty check was always True because outR
'      always pointed to the next unwritten row, causing a header to print before every entry.
'   3. [MEDIUM]   Billable check: changed case-sensitive = "Yes" to UCase$() = "YES" so
'      that "yes", "YES", "Yes", etc. are all counted correctly.
'   4. [LOW]      ClearContents range increased from 400 to 850 rows to cover worst-case
'      output (200 entries, one per month = up to 800 output rows with headers/subtotals).
'========================
Option Explicit

Public Const TE_FIRSTROW As Long = 5
Public Const TE_LASTROW  As Long = 204   ' 200 rows (5..204)
Public Const TE_OUTROW   As Long = 215   ' grouped output header row
Public Const TE_DATECOL  As Long = 1     ' A
Public Const TE_MONTHCOL As Long = 9     ' I (hidden helper)

'--- Quick "calendar" picker: uses a date input box with validation
Public Function PickDate(Optional ByVal defaultDate As Variant) As Variant
    Dim s As String
    Dim d As Date
    Dim prompt As String

    prompt = "Enter date (mm/dd/yyyy)." & vbCrLf & _
             "Tip: type 't' for today."

    s = InputBox(prompt, "Pick a Date", _
        IIf(IsDate(defaultDate), Format(CDate(defaultDate), "mm/dd/yyyy"), ""))

    If Len(Trim$(s)) = 0 Then
        PickDate = Empty
        Exit Function
    End If

    If LCase$(Trim$(s)) = "t" Then
        PickDate = Date
        Exit Function
    End If

    If Not IsDate(s) Then
        MsgBox "Not a valid date. Please try again.", vbExclamation
        PickDate = Empty
        Exit Function
    End If

    d = CDate(s)
    PickDate = d
End Function

'--- Builds the "Grouped by Month" section from the input table
Public Sub UpdateMonthlyGroups()
    On Error GoTo CleanFail

    Dim ws As Worksheet
    Set ws = ThisWorkbook.Worksheets("Time Entry Form")

    Dim r As Long, outR As Long
    Dim data As Variant

    Dim last As Long
    last = TE_LASTROW

    ' Read input rows into memory (A:H)
    Dim rng As Range
    Set rng = ws.Range(ws.Cells(TE_FIRSTROW, 1), ws.Cells(last, 8))
    data = rng.Value

    ' FIX 1 (CRITICAL): Collect row indices into a Long array instead of a Collection.
    ' The original Collection-based sort was broken: rows.Add tmp,,j-1 used the 3rd
    ' "before" parameter with wrong index arithmetic, so elements never actually moved.
    Dim rowArr() As Long
    Dim rowCount As Long
    rowCount = 0
    ReDim rowArr(1 To (last - TE_FIRSTROW + 1))

    Dim ri As Long
    For ri = 1 To UBound(data, 1)
        If IsDate(data(ri, 1)) Then
            rowCount = rowCount + 1
            rowArr(rowCount) = ri
        End If
    Next ri

    ' FIX 4 (LOW): Increased clear range from 400 to 850 rows.
    ' Worst case: 200 entries each in a different month = 200*(1 header+1 data+2 gap) = 800 rows.
    ws.Range(ws.Cells(TE_OUTROW + 1, 1), ws.Cells(TE_OUTROW + 850, 8)).ClearContents

    If rowCount = 0 Then
        ws.Cells(TE_OUTROW + 1, 1).Value = "(No dated entries yet.)"
        Exit Sub
    End If

    ' FIX 1 (CRITICAL): Array-based bubble sort — correctly swaps adjacent Long elements.
    Dim i As Long, j As Long, tmp As Long
    Dim swapped As Boolean
    Do
        swapped = False
        For i = 1 To rowCount - 1
            If CDate(data(rowArr(i + 1), 1)) < CDate(data(rowArr(i), 1)) Then
                tmp = rowArr(i)
                rowArr(i) = rowArr(i + 1)
                rowArr(i + 1) = tmp
                swapped = True
            End If
        Next i
    Loop While swapped

    ' Write grouped output with month headers and subtotals
    outR = TE_OUTROW + 1

    Dim curMonth As Date, m As Date
    Dim monthTotal As Double, monthBill As Double

    ' FIX 2 (CRITICAL): Use an explicit boolean flag instead of reading ws.Cells(outR,1).
    ' The old cell-empty check was always True because outR always pointed to the next
    ' unwritten row, causing a month header to be inserted before every single entry.
    Dim headerWritten As Boolean
    curMonth = 0
    monthTotal = 0
    monthBill = 0
    headerWritten = False

    For i = 1 To rowCount
        r = rowArr(i)
        m = DateSerial(Year(CDate(data(r, 1))), Month(CDate(data(r, 1))), 1)

        If curMonth = 0 Then curMonth = m

        If m <> curMonth Then
            ' subtotal row for prior month
            WriteSubtotal ws, outR, curMonth, monthTotal, monthBill
            outR = outR + 2

            curMonth = m
            monthTotal = 0
            monthBill = 0
            headerWritten = False   ' reset flag so new month gets its header
        End If

        ' month header — written exactly once per month group
        If Not headerWritten Then
            WriteMonthHeader ws, outR, curMonth
            outR = outR + 1
            headerWritten = True
        End If

        ' write entry row
        ws.Range(ws.Cells(outR, 1), ws.Cells(outR, 8)).Value = Array( _
            data(r, 1), data(r, 2), data(r, 3), data(r, 4), _
            data(r, 5), data(r, 6), data(r, 7), data(r, 8))

        monthTotal = monthTotal + Val(data(r, 7))

        ' FIX 3 (MEDIUM): Case-insensitive billable check.
        ' Original = "Yes" missed "yes", "YES", etc. silently.
        If UCase$(Trim$(CStr(data(r, 8)))) = "YES" Then
            monthBill = monthBill + Val(data(r, 7))
        End If

        outR = outR + 1
    Next i

    ' final subtotal
    WriteSubtotal ws, outR, curMonth, monthTotal, monthBill

    Exit Sub

CleanFail:
    MsgBox "UpdateMonthlyGroups failed: " & Err.Description, vbExclamation
End Sub

Private Sub WriteMonthHeader(ByVal ws As Worksheet, ByVal rowNum As Long, ByVal monthStart As Date)
    ws.Cells(rowNum, 1).Value = Format(monthStart, "mmmm yyyy")
    ws.Range(ws.Cells(rowNum, 1), ws.Cells(rowNum, 8)).Merge

    With ws.Cells(rowNum, 1)
        .Font.Bold = True
        .Font.Color = RGB(31, 78, 121)
    End With
End Sub

Private Sub WriteSubtotal(ByVal ws As Worksheet, ByVal rowNum As Long, ByVal monthStart As Date, _
                          ByVal totalHrs As Double, ByVal billHrs As Double)

    ws.Cells(rowNum, 6).Value = "Subtotal (" & Format(monthStart, "mmm yyyy") & "):"
    ws.Cells(rowNum, 7).Value = totalHrs
    ws.Cells(rowNum, 8).Value = "Billable: " & Format(billHrs, "0.00")

    ws.Cells(rowNum, 7).NumberFormat = "0.00"
    ws.Cells(rowNum, 6).Font.Bold = True
    ws.Cells(rowNum, 7).Font.Bold = True
    ws.Cells(rowNum, 8).Font.Bold = True
End Sub
