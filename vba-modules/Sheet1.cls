VERSION 1.0 CLASS
BEGIN
  MultiUse = -1  'True
END
Attribute VB_Name = "Sheet1"
Attribute VB_GlobalNameSpace = False
Attribute VB_Creatable = False
Attribute VB_PredeclaredId = False
Attribute VB_Exposed = False
' Sheet1 (Time Entry Form) — no bugs found; no changes from original.
Option Explicit

'===========================================
' Auto refresh grouped output when data changes
'===========================================
Private Sub Worksheet_Change(ByVal Target As Range)

    On Error GoTo SafeExit

    If Not Intersect(Target, Me.Range("A5:H204")) Is Nothing Then
        Application.EnableEvents = False
        TimeEntryTools.UpdateMonthlyGroups
    End If

SafeExit:
    Application.EnableEvents = True

End Sub

Private Sub Worksheet_BeforeDoubleClick(ByVal Target As Range, Cancel As Boolean)

    If Not Intersect(Target, Me.Range("A5:A204")) Is Nothing Then
        Cancel = True

        Dim f As frmCalendar
        Set f = New frmCalendar

        f.InitCalendar Target
        f.Show

    End If

End Sub
