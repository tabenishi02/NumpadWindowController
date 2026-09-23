#Requires AutoHotkey v2.0
#SingleInstance Force
#Include Common.ahk

DetectHiddenWindows(false)

work := PB_GetPrimaryWorkArea()
out := "Phase B-2 Chrome Geometry PoC`n"
out .= "Timestamp: " PB_Now() "`n"
out .= "Primary monitor: " work.index "`n"
out .= "WorkArea: L=" work.left " T=" work.top " R=" work.right " B=" work.bottom
out .= " W=" work.width " H=" work.height "`n`n"
out .= "Z`tHWND`tMonitor`tState`tX`tY`tW`tH`tNX`tNY`tNW`tNH`tCenterX`tCenterY`tClass`tTitle`n"

list := WinGetList("ahk_exe chrome.exe")
for index, hwnd in list {
    if !PB_IsWindow(hwnd) || !PB_IsVisible(hwnd)
        continue
    p := PB_GetPos(hwnd)
    n := PB_NormalizeToWorkArea(hwnd, work)
    out .= (
        index "`t" hwnd "`t" PB_GetWindowMonitor(hwnd) "`t"
        PB_MinMaxName(PB_SafeMinMax(hwnd)) "`t"
        p.x "`t" p.y "`t" p.w "`t" p.h "`t"
        Format("{:.4f}", n.x) "`t" Format("{:.4f}", n.y) "`t"
        Format("{:.4f}", n.w) "`t" Format("{:.4f}", n.h) "`t"
        Format("{:.4f}", n.cx) "`t" Format("{:.4f}", n.cy) "`t"
        PB_SafeClass(hwnd) "`t" StrReplace(PB_SafeTitle(hwnd), "`t", " ") "`n"
    )
}

path := PB_WriteLog("B2_chrome_geometry.tsv", out)
MsgBox("B-2 complete.`n`nChrome windows: " list.Length "`nLog: " path)
