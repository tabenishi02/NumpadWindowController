#Requires AutoHotkey v2.0
#SingleInstance Force
Persistent()
#Include %A_ScriptDir%\lib\WindowProbe.ahk

global gResultDir := EnsureResultDir()
global gResultFile := gResultDir "\B5_vscode_order_" MakeResultTag() ".tsv"
global gSeen := Map()
global gSequence := 0
global gInitialScan := true

InitializeLog()
ObserveVSCode()
gInitialScan := false

SetTimer(ObserveVSCode, 500)

ToolTip(
    "B-5 VS Code Order PoC"
    . Chr(10) . "Keep this script running while opening/closing VS Code windows."
    . Chr(10) . "F5: snapshot  F8: reset observation  F9: open log  Ctrl+Esc: exit"
)
SetTimer(() => ToolTip(), -5000)

F5::WriteSnapshot()
F8::ResetObservation()
F9::Run(gResultFile)
^Esc::ExitApp()

InitializeLog() {
    global gResultFile

    header := "row_type"
        . Chr(9) . "timestamp"
        . Chr(9) . "observation_sequence"
        . Chr(9) . "z_order"
        . Chr(9) . "hwnd"
        . Chr(9) . "pid"
        . Chr(9) . "process_creation_filetime"
        . Chr(9) . "class"
        . Chr(9) . "title"
        . Chr(9) . "candidate"

    ResetResultFile(gResultFile, header)
}

ObserveVSCode() {
    global gSeen, gSequence, gInitialScan, gResultFile

    for p in ProbeAllWindows() {
        if !IsCandidateProcess(p, "Code.exe")
            continue

        key := p.hwnd

        if !gSeen.Has(key) {
            gSequence += 1
            gSeen[key] := gSequence

            AppendTsvRow(
                gResultFile,
                gInitialScan ? "INITIAL_OBSERVED" : "NEW_OBSERVED",
                A_Now,
                gSequence,
                p.zOrder,
                Format("0x{:X}", p.hwnd),
                p.pid,
                p.processCreationFileTime,
                p.className,
                p.title,
                p.candidate
            )
        }
    }
}

WriteSnapshot() {
    global gSeen, gResultFile

    ObserveVSCode()

    for p in ProbeAllWindows() {
        if !IsCandidateProcess(p, "Code.exe")
            continue

        seq := gSeen.Has(p.hwnd) ? gSeen[p.hwnd] : 0

        AppendTsvRow(
            gResultFile,
            "SNAPSHOT",
            A_Now,
            seq,
            p.zOrder,
            Format("0x{:X}", p.hwnd),
            p.pid,
            p.processCreationFileTime,
            p.className,
            p.title,
            p.candidate
        )
    }

    ToolTip("VS Code snapshot written.")
    SetTimer(() => ToolTip(), -1000)
}

ResetObservation() {
    global gSeen, gSequence, gInitialScan, gResultFile

    gSeen := Map()
    gSequence := 0
    gInitialScan := true

    AppendTsvRow(
        gResultFile,
        "RESET",
        A_Now,
        "",
        "",
        "",
        "",
        "",
        "",
        "",
        ""
    )

    ObserveVSCode()
    gInitialScan := false

    ToolTip("Observation order reset.")
    SetTimer(() => ToolTip(), -1000)
}
