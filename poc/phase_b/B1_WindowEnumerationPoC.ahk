#Requires AutoHotkey v2.0
#SingleInstance Force
#Include %A_ScriptDir%\lib\WindowProbe.ahk

resultDir := EnsureResultDir()
resultFile := resultDir "\B1_windows_" MakeResultTag() ".tsv"

windows := ProbeAllWindows()
WriteWindowSnapshot(resultFile, windows)

Run(resultFile)
MsgBox(
    "B-1 Window Enumeration PoC completed."
    . Chr(10) . Chr(10)
    . "Result:"
    . Chr(10) . resultFile
    . Chr(10) . Chr(10)
    . "candidate=1 is the initial proposed Auto Bind candidate set."
)
