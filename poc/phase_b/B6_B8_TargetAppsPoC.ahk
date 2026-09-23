#Requires AutoHotkey v2.0
#SingleInstance Force
#Include %A_ScriptDir%\lib\WindowProbe.ahk

resultDir := EnsureResultDir()
resultFile := resultDir "\B6_B8_target_apps_" MakeResultTag() ".tsv"

WriteTargetSnapshot(resultFile)

Run(resultFile)
MsgBox(
    "B-6 to B-8 Target Apps PoC completed."
    . Chr(10) . Chr(10)
    . "Result:"
    . Chr(10) . resultFile
    . Chr(10) . Chr(10)
    . "Keep Explorer, ChatGPT Desktop and PowerShell/Windows Terminal open while running."
)

WriteTargetSnapshot(path) {
    header := "hint"
        . Chr(9) . "z_order"
        . Chr(9) . "hwnd"
        . Chr(9) . "candidate"
        . Chr(9) . "process"
        . Chr(9) . "pid"
        . Chr(9) . "process_creation_filetime"
        . Chr(9) . "class"
        . Chr(9) . "title"
        . Chr(9) . "x"
        . Chr(9) . "y"
        . Chr(9) . "width"
        . Chr(9) . "height"
        . Chr(9) . "minmax"
        . Chr(9) . "monitor"

    ResetResultFile(path, header)

    for p in ProbeAllWindows() {
        if !p.candidate
            continue

        hint := GetTargetHint(p)

        AppendTsvRow(
            path,
            hint,
            p.zOrder,
            Format("0x{:X}", p.hwnd),
            p.candidate,
            p.processName,
            p.pid,
            p.processCreationFileTime,
            p.className,
            p.title,
            p.x,
            p.y,
            p.width,
            p.height,
            p.minMax,
            p.monitor
        )
    }
}

GetTargetHint(p) {
    process := StrLower(p.processName)
    title := StrLower(p.title)

    hints := []

    if process = "explorer.exe"
        hints.Push("EXPLORER")

    if InStr(process, "chatgpt")
        || InStr(process, "openai")
        || InStr(title, "chatgpt")
        || InStr(title, "openai")
        hints.Push("CHATGPT")

    if process = "windowsterminal.exe"
        || process = "pwsh.exe"
        || InStr(title, "powershell")
        || InStr(title, "pwsh")
        hints.Push("POWERSHELL_TERMINAL")

    if hints.Length = 0
        return "OTHER"

    result := ""
    for index, item in hints {
        if index > 1
            result .= "+"
        result .= item
    }

    return result
}
