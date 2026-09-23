#Requires AutoHotkey v2.0
#SingleInstance Force
Persistent()
#Include Common.ahk

DetectHiddenWindows(false)
global LOG_NAME := "B8_powershell_terminal_identification.log"

PB_WriteLog(LOG_NAME,
    "Phase B-8 PowerShell / Windows Terminal Identification PoC`n"
    "Started: " PB_Now() "`n"
    "Activate the PowerShell 7 terminal you want Numpad3 to target, then press F5.`n"
    "F5=Capture  F9=Open log  Ctrl+Esc=Exit`n`n"
)

ToolTip("Activate PowerShell 7 terminal, then press F5")
SetTimer(() => ToolTip(), -2500)

F5::Capture()
F9::OpenLog()
^Esc::ExitApp()

Capture() {
    global LOG_NAME

    active := WinExist("A")
    text := "`n=== CAPTURE " PB_Now() " ===`n"
    text .= "ACTIVE WINDOW`n"
    text .= PB_WindowHeader()
    if active
        text .= PB_WindowTSV(active, "A") "`n"

    text .= "`nMATCHING CANDIDATES`n"
    text .= PB_WindowHeader()

    list := WinGetList()
    found := 0
    for index, hwnd in list {
        if !PB_IsWindow(hwnd) || !PB_IsVisible(hwnd)
            continue

        proc := StrLower(PB_SafeProcess(hwnd))
        title := StrLower(PB_SafeTitle(hwnd))
        cls := StrLower(PB_SafeClass(hwnd))

        match := (
            InStr(proc, "windowsterminal")
            || InStr(proc, "pwsh")
            || InStr(title, "powershell")
            || InStr(title, "pwsh")
            || InStr(cls, "cascadia")
        )

        if match {
            text .= PB_WindowTSV(hwnd, index) "`n"
            found += 1
        }
    }

    text .= "CandidateCount=" found "`n"
    PB_AppendLog(LOG_NAME, text)
    ToolTip("B-8 captured active window + " found " candidates")
    SetTimer(() => ToolTip(), -1200)
}

OpenLog() {
    global LOG_NAME
    Run(PB_LogDir() "\" LOG_NAME)
}
