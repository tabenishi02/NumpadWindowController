#Requires AutoHotkey v2.0
#SingleInstance Force
Persistent()
#Include Common.ahk

DetectHiddenWindows(false)

global OBS := Map()
global NEXT_SEQ := 1
global LOG_NAME := "B5_vscode_order.log"

PB_WriteLog(LOG_NAME,
    "Phase B-5 VS Code First Observed Order PoC`n"
    "Started: " PB_Now() "`n"
    "F5=Scan  F8=Reset observation  F9=Open log  Ctrl+Esc=Exit`n`n"
)

ScanVSCode()
ToolTip("B-5 running`nF5 Scan / F8 Reset / F9 Log / Ctrl+Esc Exit")
SetTimer(() => ToolTip(), -2500)

F5::ScanVSCode()
F8::ResetObserved()
F9::OpenLog()
^Esc::ExitApp()

ScanVSCode() {
    global OBS, NEXT_SEQ, LOG_NAME

    list := WinGetList("ahk_exe Code.exe")
    text := "`n=== SCAN " PB_Now() " ===`n"
    text .= "WinGetList count=" list.Length "`n"
    text .= "ListOrder`tObservedSeq`tHWND`tPID`tState`tX`tY`tW`tH`tTitle`n"

    for listIndex, hwnd in list {
        if !PB_IsWindow(hwnd) || !PB_IsVisible(hwnd)
            continue

        if !OBS.Has(hwnd) {
            OBS[hwnd] := NEXT_SEQ
            NEXT_SEQ += 1
        }

        p := PB_GetPos(hwnd)
        text .= (
            listIndex "`t" OBS[hwnd] "`t" hwnd "`t" PB_SafePID(hwnd) "`t"
            PB_MinMaxName(PB_SafeMinMax(hwnd)) "`t"
            p.x "`t" p.y "`t" p.w "`t" p.h "`t"
            StrReplace(PB_SafeTitle(hwnd), "`t", " ") "`n"
        )
    }

    PB_AppendLog(LOG_NAME, text)
    ToolTip("B-5 scanned: " list.Length " Code.exe windows")
    SetTimer(() => ToolTip(), -1000)
}

ResetObserved() {
    global OBS, NEXT_SEQ, LOG_NAME
    OBS := Map()
    NEXT_SEQ := 1
    PB_AppendLog(LOG_NAME, "`n=== OBSERVATION RESET " PB_Now() " ===`n")
    ToolTip("B-5 observation reset")
    SetTimer(() => ToolTip(), -1000)
}

OpenLog() {
    global LOG_NAME
    Run(PB_LogDir() "\" LOG_NAME)
}
