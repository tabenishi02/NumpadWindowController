#Requires AutoHotkey v2.0
#SingleInstance Force
#Include %A_ScriptDir%\lib\WindowProbe.ahk

resultDir := EnsureResultDir()
tag := MakeResultTag()
chromeFile := resultDir "\B2_B4_chrome_layout_" tag ".tsv"
monitorFile := resultDir "\B2_B4_monitors_" tag ".tsv"

WriteMonitorSnapshot(monitorFile)
WriteChromeSnapshot(chromeFile)

Run(chromeFile)
MsgBox(
    "B-2 to B-4 Chrome / Monitor PoC completed."
    . Chr(10) . Chr(10)
    . "Chrome:"
    . Chr(10) . chromeFile
    . Chr(10) . Chr(10)
    . "Monitors:"
    . Chr(10) . monitorFile
)

WriteChromeSnapshot(path) {
    primary := GetPrimaryMonitorInfo()
    workWidth := primary.workRight - primary.workLeft
    workHeight := primary.workBottom - primary.workTop

    header := "z_order"
        . Chr(9) . "hwnd"
        . Chr(9) . "title"
        . Chr(9) . "minmax"
        . Chr(9) . "actual_monitor"
        . Chr(9) . "x"
        . Chr(9) . "y"
        . Chr(9) . "width"
        . Chr(9) . "height"
        . Chr(9) . "x_norm_primary"
        . Chr(9) . "y_norm_primary"
        . Chr(9) . "center_x_norm_primary"
        . Chr(9) . "center_y_norm_primary"
        . Chr(9) . "width_ratio_primary"
        . Chr(9) . "height_ratio_primary"
        . Chr(9) . "match_chrome1"
        . Chr(9) . "match_chrome2"
        . Chr(9) . "match_chrome3"
        . Chr(9) . "score_chrome1"
        . Chr(9) . "score_chrome2"
        . Chr(9) . "score_chrome3"

    ResetResultFile(path, header)

    for p in ProbeAllWindows() {
        if !IsCandidateProcess(p, "chrome.exe")
            continue

        xNorm := (p.x - primary.workLeft) / workWidth
        yNorm := (p.y - primary.workTop) / workHeight
        wRatio := p.width / workWidth
        hRatio := p.height / workHeight
        cxNorm := (p.x + p.width / 2 - primary.workLeft) / workWidth
        cyNorm := (p.y + p.height / 2 - primary.workTop) / workHeight

        match1 := (
            cxNorm < 0.40
            && cyNorm < 0.50
            && wRatio >= 0.15 && wRatio <= 0.45
            && hRatio >= 0.30 && hRatio <= 0.70
        ) ? 1 : 0

        match2 := (
            cxNorm < 0.40
            && cyNorm >= 0.50
            && wRatio >= 0.15 && wRatio <= 0.45
            && hRatio >= 0.30 && hRatio <= 0.70
        ) ? 1 : 0

        match3 := (
            cxNorm >= 0.40
            && wRatio >= 0.50 && wRatio <= 0.90
            && hRatio >= 0.70 && hRatio <= 1.05
        ) ? 1 : 0

        score1 := RectScore(xNorm, yNorm, wRatio, hRatio, 0.00, 0.00, 0.30, 0.50)
        score2 := RectScore(xNorm, yNorm, wRatio, hRatio, 0.00, 0.50, 0.30, 0.50)
        score3 := RectScore(xNorm, yNorm, wRatio, hRatio, 0.30, 0.00, 0.70, 1.00)

        AppendTsvRow(
            path,
            p.zOrder,
            Format("0x{:X}", p.hwnd),
            p.title,
            p.minMax,
            p.monitor,
            p.x,
            p.y,
            p.width,
            p.height,
            Format("{:.4f}", xNorm),
            Format("{:.4f}", yNorm),
            Format("{:.4f}", cxNorm),
            Format("{:.4f}", cyNorm),
            Format("{:.4f}", wRatio),
            Format("{:.4f}", hRatio),
            match1,
            match2,
            match3,
            Format("{:.4f}", score1),
            Format("{:.4f}", score2),
            Format("{:.4f}", score3)
        )
    }
}

RectScore(x, y, w, h, idealX, idealY, idealW, idealH) {
    return Abs(x - idealX)
        + Abs(y - idealY)
        + Abs(w - idealW)
        + Abs(h - idealH)
}
