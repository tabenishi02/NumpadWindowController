#Requires AutoHotkey v2.0
#SingleInstance Force
Persistent()
#Include Common.ahk

DetectHiddenWindows(false)
global LOG_NAME := "B7_chatgpt_identification.log"

PB_WriteLog(LOG_NAME,
    "Phase B-7 ChatGPT Desktop Identification PoC`n"
    "Started: " PB_Now() "`n"
    "Activate ChatGPT Desktop, then press F5.`n"
    "F5=Capture  F9=Open log  Ctrl+Esc=Exit`n`n"
)

ToolTip("Activate ChatGPT Desktop, then press F5")
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

    text .= "`nMATCHING CANDIDATES (process/title contains ChatGPT/OpenAI)`n"
    text .= PB_WindowHeader()

    list := WinGetList()
    found := 0
    for index, hwnd in list {
        if !PB_IsWindow(hwnd) || !PB_IsVisible(hwnd)
            continue
        proc := PB_SafeProcess(hwnd)
        title := PB_SafeTitle(hwnd)
        hay := StrLower(proc " " title)
        if InStr(hay, "chatgpt") || InStr(hay, "openai") {
            text .= PB_WindowTSV(hwnd, index) "`n"
            found += 1
        }
    }

    text .= "CandidateCount=" found "`n"
    PB_AppendLog(LOG_NAME, text)
    ToolTip("B-7 captured active window + " found " candidates")
    SetTimer(() => ToolTip(), -1200)
}

OpenLog() {
    global LOG_NAME
    Run(PB_LogDir() "\" LOG_NAME)
}
