#Requires AutoHotkey v2.0
#SingleInstance Force
#Include Common.ahk

DetectHiddenWindows(false)

work := PB_GetPrimaryWorkArea()
ideal := Map(
    "Chrome1", {x:0.00, y:0.00, w:0.30, h:0.50},
    "Chrome2", {x:0.00, y:0.50, w:0.30, h:0.50},
    "Chrome3", {x:0.30, y:0.00, w:0.70, h:1.00}
)

out := "Phase B-3 Chrome Tolerance / Classification PoC`n"
out .= "Timestamp: " PB_Now() "`n`n"
out .= "HWND`tMonitor`tNX`tNY`tNW`tNH`tCX`tCY`tRuleCandidate`tBestIdeal`tScore1`tScore2`tScore3`tTitle`n"

list := WinGetList("ahk_exe chrome.exe")
for hwnd in list {
    if !PB_IsWindow(hwnd) || !PB_IsVisible(hwnd)
        continue

    n := PB_NormalizeToWorkArea(hwnd, work)
    candidate := "None"

    if (n.cx < 0.40 && n.cy < 0.50 && n.w >= 0.15 && n.w <= 0.45 && n.h >= 0.30 && n.h <= 0.70)
        candidate := "Chrome1"
    else if (n.cx < 0.40 && n.cy >= 0.50 && n.w >= 0.15 && n.w <= 0.45 && n.h >= 0.30 && n.h <= 0.70)
        candidate := "Chrome2"
    else if (n.cx >= 0.40 && n.w >= 0.50 && n.w <= 0.90 && n.h >= 0.70 && n.h <= 1.05)
        candidate := "Chrome3"

    scores := Map()
    bestName := ""
    bestScore := 999.0
    for name, target in ideal {
        score := PB_Abs(n.x-target.x) + PB_Abs(n.y-target.y) + PB_Abs(n.w-target.w) + PB_Abs(n.h-target.h)
        scores[name] := score
        if score < bestScore {
            bestScore := score
            bestName := name
        }
    }

    out .= (
        hwnd "`t" PB_GetWindowMonitor(hwnd) "`t"
        Format("{:.4f}", n.x) "`t" Format("{:.4f}", n.y) "`t"
        Format("{:.4f}", n.w) "`t" Format("{:.4f}", n.h) "`t"
        Format("{:.4f}", n.cx) "`t" Format("{:.4f}", n.cy) "`t"
        candidate "`t" bestName "`t"
        Format("{:.4f}", scores["Chrome1"]) "`t"
        Format("{:.4f}", scores["Chrome2"]) "`t"
        Format("{:.4f}", scores["Chrome3"]) "`t"
        StrReplace(PB_SafeTitle(hwnd), "`t", " ") "`n"
    )
}

path := PB_WriteLog("B3_chrome_tolerance.tsv", out)
MsgBox("B-3 complete.`n`nLog: " path)
