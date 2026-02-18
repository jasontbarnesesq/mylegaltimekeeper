VERSION 5.00
Begin {C62A69F0-16DC-11CE-9E98-00AA00574A4F} frmCalendar
   Caption         =   "Select Date"
   ClientHeight    =   3492
   ClientLeft      =   108
   ClientTop       =   456
   ClientWidth     =   2952
   OleObjectBlob   =   "frmCalendar.frx":0000
   StartUpPosition =   1  'CenterOwner
End
Attribute VB_Name = "frmCalendar"
Attribute VB_GlobalNameSpace = False
Attribute VB_Creatable = False
Attribute VB_PredeclaredId = True
Attribute VB_Exposed = False
' frmCalendar  (FIXED)
' Fixes applied:
'   5. [MEDIUM] DaySelected: removed redundant TimeEntryTools.UpdateMonthlyGroups call.
'      Setting ws.Range(mTargetAddress).Value already fires Worksheet_Change, which calls
'      UpdateMonthlyGroups via the sheet event. Calling it explicitly a second time caused
'      a double recalculation (visible flicker, wasted writes, potential event feedback).
'   6. [LOW]    btn.Tag: dates are now stored as CLng (locale-independent serial numbers)
'      instead of implicit CStr (locale-dependent date strings). This prevents CDate()
'      misparse if the workbook is opened on a machine with a different regional format.
Option Explicit

Private mCurrentDate As Date
Private mTargetAddress As String           ' Stores target cell address like "A5"
Private mButtons As Collection             ' Holds clsDayButton handlers so clicks work

'========================================================
' Initialize calendar for a specific target cell
'========================================================
Public Sub InitCalendar(ByVal Target As Range)

    ' Store address (safer than holding Range object references)
    mTargetAddress = Target.Address(False, False)

    If IsDate(Target.Value) Then
        mCurrentDate = CDate(Target.Value)
    Else
        mCurrentDate = Date
    End If

    BuildCalendar

End Sub

'========================================================
' Render the calendar grid inside fraDays
'========================================================
Private Sub BuildCalendar()

    If Len(mTargetAddress) = 0 Then
        MsgBox "Calendar isn't linked to a target cell. Close and double-click the date cell again.", vbExclamation
        Exit Sub
    End If

    ' Clear existing day buttons
    Dim ctrl As Control
    For Each ctrl In fraDays.Controls
        fraDays.Controls.Remove ctrl.Name
    Next ctrl

    Set mButtons = New Collection

    lblMonth.Caption = Format(mCurrentDate, "mmmm yyyy")

    Dim firstDay As Date
    firstDay = DateSerial(Year(mCurrentDate), Month(mCurrentDate), 1)

    Dim startDay As Integer
    startDay = Weekday(firstDay, vbSunday) ' 1=Sun, 7=Sat

    Dim daysInMonth As Integer
    daysInMonth = Day(DateSerial(Year(mCurrentDate), Month(mCurrentDate) + 1, 0))

    Dim i As Integer
    Dim row As Integer, col As Integer
    Dim btn As MSForms.CommandButton
    Dim handler As clsDayButton

    ' Create a button for each day
    For i = 1 To daysInMonth

        row = Int((i + startDay - 2) / 7)
        col = (i + startDay - 2) Mod 7

        Set btn = fraDays.Controls.Add("Forms.CommandButton.1")
        With btn
            .Caption = CStr(i)
            .Width = 28
            .Height = 22
            .Left = col * 30
            .Top = row * 24
            ' FIX 6 (LOW): Store date as a locale-independent Long serial number.
            ' Original stored as Date (implicit CStr), which uses the system locale
            ' date format and could misparse on machines with different regional settings.
            .Tag = CLng(DateSerial(Year(mCurrentDate), Month(mCurrentDate), i))
        End With

        Set handler = New clsDayButton
        handler.Init btn, Me
        mButtons.Add handler

    Next i

End Sub

'========================================================
' Called by clsDayButton when a day is clicked
'========================================================
Public Sub DaySelected(ByVal selectedDate As Date)

    If Len(mTargetAddress) = 0 Then
        MsgBox "Calendar isn't linked to a target cell. Close and double-click again.", vbExclamation
        Unload Me
        Exit Sub
    End If

    Dim ws As Worksheet
    Set ws = ThisWorkbook.Worksheets("Time Entry Form")

    ws.Range(mTargetAddress).Value = selectedDate
    ws.Range(mTargetAddress).NumberFormat = "mm/dd/yyyy"

    ' FIX 5 (MEDIUM): Removed redundant UpdateMonthlyGroups call.
    ' Setting the cell value above fires Worksheet_Change on Sheet1, which already
    ' calls TimeEntryTools.UpdateMonthlyGroups with EnableEvents protection.
    ' The explicit call here caused UpdateMonthlyGroups to run a second time,
    ' producing double writes, visible flicker, and unnecessary processing.

    Unload Me

End Sub

'========================================================
' Navigation buttons
'========================================================
Private Sub cmdPrev_Click()
    mCurrentDate = DateAdd("m", -1, mCurrentDate)
    BuildCalendar
End Sub

Private Sub cmdNext_Click()
    mCurrentDate = DateAdd("m", 1, mCurrentDate)
    BuildCalendar
End Sub

Private Sub cmdToday_Click()
    DaySelected Date
End Sub

Private Sub cmdCancel_Click()
    Unload Me
End Sub

Private Sub lblMonth_Click()

End Sub
