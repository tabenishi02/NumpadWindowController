; Phase B shared helpers for AutoHotkey v2 PoCs.

PB_Target(hwnd) {
    return "ahk_id " hwnd
}

PB_Now() {
    return FormatTime(A_Now, "yyyy-MM-dd HH:mm:ss")
}

PB_LogDir() {
    dir := A_ScriptDir "\logs"
    DirCreate(dir)
    return dir
}

PB_WriteLog(fileName, text) {
    path := PB_LogDir() "\" fileName
    try FileDelete(path)
    FileAppend(text, path, "UTF-8")
    return path
}

PB_AppendLog(fileName, text) {
    path := PB_LogDir() "\" fileName
    FileAppend(text, path, "UTF-8")
    return path
}

PB_SafeTitle(hwnd) {
    try return WinGetTitle(PB_Target(hwnd))
    catch return "<error>"
}

PB_SafeClass(hwnd) {
    try return WinGetClass(PB_Target(hwnd))
    catch return "<error>"
}

PB_SafeProcess(hwnd) {
    try return WinGetProcessName(PB_Target(hwnd))
    catch return "<error>"
}

PB_SafePID(hwnd) {
    try return WinGetPID(PB_Target(hwnd))
    catch return 0
}

PB_SafeMinMax(hwnd) {
    try return WinGetMinMax(PB_Target(hwnd))
    catch return 99
}

PB_SafeStyle(hwnd) {
    try return WinGetStyle(PB_Target(hwnd))
    catch return 0
}

PB_SafeExStyle(hwnd) {
    try return WinGetExStyle(PB_Target(hwnd))
    catch return 0
}

PB_IsVisible(hwnd) {
    try return DllCall("IsWindowVisible", "Ptr", hwnd, "Int") != 0
    catch return false
}

PB_IsWindow(hwnd) {
    try return DllCall("IsWindow", "Ptr", hwnd, "Int") != 0
    catch return false
}

PB_GetPos(hwnd) {
    x := 0, y := 0, w := 0, h := 0
    try WinGetPos(&x, &y, &w, &h, PB_Target(hwnd))
    return {x:x, y:y, w:w, h:h}
}

PB_MinMaxName(value) {
    if value = -1
        return "minimized"
    if value = 1
        return "maximized"
    if value = 0
        return "normal"
    return "unknown"
}

PB_WindowTSV(hwnd, zOrder := "") {
    p := PB_GetPos(hwnd)
    return (
        zOrder "`t"
        hwnd "`t"
        PB_SafePID(hwnd) "`t"
        PB_SafeProcess(hwnd) "`t"
        PB_SafeClass(hwnd) "`t"
        PB_MinMaxName(PB_SafeMinMax(hwnd)) "`t"
        (PB_IsVisible(hwnd) ? "1" : "0") "`t"
        Format("0x{:08X}", PB_SafeStyle(hwnd)) "`t"
        Format("0x{:08X}", PB_SafeExStyle(hwnd)) "`t"
        p.x "`t" p.y "`t" p.w "`t" p.h "`t"
        StrReplace(PB_SafeTitle(hwnd), "`t", " ")
    )
}

PB_WindowHeader() {
    return "Z`tHWND`tPID`tProcess`tClass`tState`tVisible`tStyle`tExStyle`tX`tY`tW`tH`tTitle`n"
}

PB_GetPrimaryWorkArea() {
    primary := MonitorGetPrimary()
    left := 0, top := 0, right := 0, bottom := 0
    MonitorGetWorkArea(primary, &left, &top, &right, &bottom)
    return {
        index: primary,
        left: left,
        top: top,
        right: right,
        bottom: bottom,
        width: right - left,
        height: bottom - top
    }
}

PB_GetMonitorByPoint(x, y) {
    count := MonitorGetCount()
    Loop count {
        left := 0, top := 0, right := 0, bottom := 0
        MonitorGet(A_Index, &left, &top, &right, &bottom)
        if (x >= left && x < right && y >= top && y < bottom)
            return A_Index
    }
    return MonitorGetPrimary()
}

PB_GetWindowMonitor(hwnd) {
    p := PB_GetPos(hwnd)
    return PB_GetMonitorByPoint(p.x + p.w / 2, p.y + p.h / 2)
}

PB_NormalizeToWorkArea(hwnd, workArea) {
    p := PB_GetPos(hwnd)
    nx := (p.x - workArea.left) / workArea.width
    ny := (p.y - workArea.top) / workArea.height
    nw := p.w / workArea.width
    nh := p.h / workArea.height
    return {x:nx, y:ny, w:nw, h:nh, cx:nx + nw/2, cy:ny + nh/2}
}

PB_Abs(v) {
    return v < 0 ? -v : v
}
