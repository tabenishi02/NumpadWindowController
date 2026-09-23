#Requires AutoHotkey v2.0
#SingleInstance Force
#Include Common.ahk

DetectHiddenWindows(false)

excluded := Map(
    "Progman", true,
    "WorkerW", true,
    "Shell_TrayWnd", true,
    "Shell_SecondaryTrayWnd", true
)

out := "Phase B-6 Explorer Identification PoC`n"
out .= "Timestamp: " PB_Now() "`n`n"
out .= "Z`tCandidate`tHWND`tClass`tState`tVisible`tX`tY`tW`tH`tTitle`n"

list := WinGetList("ahk_exe explorer.exe")
for index, hwnd in list {
    if !PB_IsWindow(hwnd)
        continue

    cls := PB_SafeClass(hwnd)
    title := PB_SafeTitle(hwnd)
    visible := PB_IsVisible(hwnd)
    candidate := visible && title != "" && !excluded.Has(cls)

    p := PB_GetPos(hwnd)
    out .= (
        index "`t" (candidate ? "YES" : "NO") "`t" hwnd "`t" cls "`t"
        PB_MinMaxName(PB_SafeMinMax(hwnd)) "`t" (visible ? "1" : "0") "`t"
        p.x "`t" p.y "`t" p.w "`t" p.h "`t"
        StrReplace(title, "`t", " ") "`n"
    )
}

path := PB_WriteLog("B6_explorer_identification.tsv", out)
MsgBox("B-6 complete.`n`nExplorer-process windows: " list.Length "`nLog: " path)
