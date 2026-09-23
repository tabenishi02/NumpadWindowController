#Requires AutoHotkey v2.0
#SingleInstance Force
#Include Common.ahk

DetectHiddenWindows(false)

out := "Phase B-1 Window Enumeration PoC`n"
out .= "Timestamp: " PB_Now() "`n`n"
out .= PB_WindowHeader()

list := WinGetList()
for index, hwnd in list {
    if !PB_IsWindow(hwnd)
        continue
    out .= PB_WindowTSV(hwnd, index) "`n"
}

path := PB_WriteLog("B1_window_enumeration.tsv", out)
MsgBox("B-1 complete.`n`nWindows: " list.Length "`nLog: " path)
