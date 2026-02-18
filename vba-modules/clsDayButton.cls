VERSION 1.0 CLASS
BEGIN
  MultiUse = -1  'True
END
Attribute VB_Name = "clsDayButton"
Attribute VB_GlobalNameSpace = False
Attribute VB_Creatable = False
Attribute VB_PredeclaredId = False
Attribute VB_Exposed = False
' clsDayButton  (FIXED)
' Fix 6 (LOW): btn.Tag is now read back as CLng() then CDate() to match the locale-independent
' Long serial number written by frmCalendar.BuildCalendar. The original CDate(btn.Tag) parsed
' whatever locale-dependent string VBA had implicitly written, which could misparse on machines
' with different regional date format settings.
Option Explicit

Public WithEvents btn As MSForms.CommandButton
Attribute btn.VB_VarHelpID = -1
Private mParent As frmCalendar

Public Sub Init(ByVal button As MSForms.CommandButton, ByVal parentForm As frmCalendar)
    Set btn = button
    Set mParent = parentForm
End Sub

Private Sub btn_Click()
    ' FIX 6 (LOW): Read Tag as Long serial number then convert to Date.
    ' This is locale-independent and matches the CLng() write in frmCalendar.BuildCalendar.
    mParent.DaySelected CDate(CLng(btn.Tag))
End Sub
