#Requires AutoHotkey v2.0

; Shared probe helpers for Phase B PoCs.

ProbeAllWindows() {
    results := []
    z := 0

    for hwnd in WinGetList() {
        z += 1
        results.Push(ProbeWindow(hwnd, z))
    }

    return results
}

ProbeWindow(hwnd, zOrder := 0) {
    spec := "ahk_id " hwnd

    title := ""
    processName := ""
    pid := 0
    className := ""
    x := 0
    y := 0
    width := 0
    height := 0
    minMax := 0
    style := 0
    exStyle := 0

    try title := WinGetTitle(spec)
    try processName := WinGetProcessName(spec)
    try pid := WinGetPID(spec)
    try className := WinGetClass(spec)
    try WinGetPos(&x, &y, &width, &height, spec)
    try minMax := WinGetMinMax(spec)
    try style := WinGetStyle(spec)
    try exStyle := WinGetExStyle(spec)

    visible := 0
    owner := 0
    cloaked := 0

    try visible := DllCall("IsWindowVisible", "ptr", hwnd, "int")
    try owner := DllCall("GetWindow", "ptr", hwnd, "uint", 4, "ptr")
    cloaked := GetCloaked(hwnd)

    toolWindow := (exStyle & 0x80) ? 1 : 0
    candidate := (
        visible
        && !cloaked
        && owner = 0
        && !toolWindow
        && width > 0
        && height > 0
        && title != ""
    )

    rejectReason := ""
    if !visible
        rejectReason .= "hidden;"
    if cloaked
        rejectReason .= "cloaked;"
    if owner != 0
        rejectReason .= "owned;"
    if toolWindow
        rejectReason .= "toolwindow;"
    if width <= 0 || height <= 0
        rejectReason .= "zero-size;"
    if title = ""
        rejectReason .= "empty-title;"

    mon := GetMonitorForRect(x, y, width, height)

    return {
        hwnd: hwnd,
        zOrder: zOrder,
        title: title,
        processName: processName,
        pid: pid,
        className: className,
        x: x,
        y: y,
        width: width,
        height: height,
        minMax: minMax,
        style: style,
        exStyle: exStyle,
        visible: visible,
        owner: owner,
        cloaked: cloaked,
        toolWindow: toolWindow,
        candidate: candidate ? 1 : 0,
        rejectReason: rejectReason,
        monitor: mon.index,
        monitorPrimary: mon.primary,
        monitorLeft: mon.left,
        monitorTop: mon.top,
        monitorRight: mon.right,
        monitorBottom: mon.bottom,
        workLeft: mon.workLeft,
        workTop: mon.workTop,
        workRight: mon.workRight,
        workBottom: mon.workBottom,
        processCreationFileTime: GetProcessCreationFileTime(pid)
    }
}

GetCloaked(hwnd) {
    data := Buffer(4, 0)

    try {
        hr := DllCall(
            "dwmapi\DwmGetWindowAttribute",
            "ptr", hwnd,
            "uint", 14,
            "ptr", data.Ptr,
            "uint", 4,
            "int"
        )
        if hr = 0
            return NumGet(data, 0, "UInt")
    }

    return 0
}

GetMonitorForRect(x, y, width, height) {
    count := MonitorGetCount()
    primary := MonitorGetPrimary()

    cx := x + width / 2
    cy := y + height / 2
    chosen := primary

    Loop count {
        i := A_Index
        MonitorGet(i, &left, &top, &right, &bottom)

        if cx >= left && cx < right && cy >= top && cy < bottom {
            chosen := i
            break
        }
    }

    MonitorGet(chosen, &left, &top, &right, &bottom)
    MonitorGetWorkArea(chosen, &workLeft, &workTop, &workRight, &workBottom)

    return {
        index: chosen,
        primary: chosen = primary ? 1 : 0,
        left: left,
        top: top,
        right: right,
        bottom: bottom,
        workLeft: workLeft,
        workTop: workTop,
        workRight: workRight,
        workBottom: workBottom
    }
}

GetPrimaryMonitorInfo() {
    i := MonitorGetPrimary()
    MonitorGet(i, &left, &top, &right, &bottom)
    MonitorGetWorkArea(i, &workLeft, &workTop, &workRight, &workBottom)

    return {
        index: i,
        left: left,
        top: top,
        right: right,
        bottom: bottom,
        workLeft: workLeft,
        workTop: workTop,
        workRight: workRight,
        workBottom: workBottom
    }
}

GetProcessCreationFileTime(pid) {
    if !pid
        return 0

    ; PROCESS_QUERY_LIMITED_INFORMATION
    hProcess := 0
    try hProcess := DllCall(
        "OpenProcess",
        "uint", 0x1000,
        "int", false,
        "uint", pid,
        "ptr"
    )

    if !hProcess
        return 0

    creation := Buffer(8, 0)
    exitTime := Buffer(8, 0)
    kernel := Buffer(8, 0)
    user := Buffer(8, 0)

    ok := 0
    try ok := DllCall(
        "GetProcessTimes",
        "ptr", hProcess,
        "ptr", creation.Ptr,
        "ptr", exitTime.Ptr,
        "ptr", kernel.Ptr,
        "ptr", user.Ptr,
        "int"
    )

    DllCall("CloseHandle", "ptr", hProcess)

    if !ok
        return 0

    return NumGet(creation, 0, "UInt64")
}

EnsureResultDir() {
    dir := A_ScriptDir "\results"
    DirCreate(dir)
    return dir
}

ResetResultFile(path, header) {
    if FileExist(path)
        FileDelete(path)

    FileAppend(header . Chr(10), path, "UTF-8")
}

AppendTsvRow(path, values*) {
    row := ""
    for index, value in values {
        if index > 1
            row .= Chr(9)
        row .= TsvClean(value)
    }

    FileAppend(row . Chr(10), path, "UTF-8")
}

TsvClean(value) {
    s := value ""
    s := StrReplace(s, Chr(9), " ")
    s := StrReplace(s, Chr(13), " ")
    s := StrReplace(s, Chr(10), " ")
    return s
}

WriteWindowSnapshot(path, windows) {
    header := "z_order"
        . Chr(9) . "hwnd"
        . Chr(9) . "candidate"
        . Chr(9) . "reject_reason"
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
        . Chr(9) . "visible"
        . Chr(9) . "owner"
        . Chr(9) . "cloaked"
        . Chr(9) . "toolwindow"
        . Chr(9) . "style"
        . Chr(9) . "exstyle"
        . Chr(9) . "monitor"
        . Chr(9) . "monitor_primary"
        . Chr(9) . "work_left"
        . Chr(9) . "work_top"
        . Chr(9) . "work_right"
        . Chr(9) . "work_bottom"

    ResetResultFile(path, header)

    for p in windows {
        AppendTsvRow(
            path,
            p.zOrder,
            Format("0x{:X}", p.hwnd),
            p.candidate,
            p.rejectReason,
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
            p.visible,
            p.owner,
            p.cloaked,
            p.toolWindow,
            Format("0x{:X}", p.style),
            Format("0x{:X}", p.exStyle),
            p.monitor,
            p.monitorPrimary,
            p.workLeft,
            p.workTop,
            p.workRight,
            p.workBottom
        )
    }
}

WriteMonitorSnapshot(path) {
    header := "monitor"
        . Chr(9) . "primary"
        . Chr(9) . "left"
        . Chr(9) . "top"
        . Chr(9) . "right"
        . Chr(9) . "bottom"
        . Chr(9) . "width"
        . Chr(9) . "height"
        . Chr(9) . "work_left"
        . Chr(9) . "work_top"
        . Chr(9) . "work_right"
        . Chr(9) . "work_bottom"
        . Chr(9) . "work_width"
        . Chr(9) . "work_height"

    ResetResultFile(path, header)

    count := MonitorGetCount()
    primary := MonitorGetPrimary()

    Loop count {
        i := A_Index
        MonitorGet(i, &left, &top, &right, &bottom)
        MonitorGetWorkArea(i, &workLeft, &workTop, &workRight, &workBottom)

        AppendTsvRow(
            path,
            i,
            i = primary ? 1 : 0,
            left,
            top,
            right,
            bottom,
            right - left,
            bottom - top,
            workLeft,
            workTop,
            workRight,
            workBottom,
            workRight - workLeft,
            workBottom - workTop
        )
    }
}

IsProcess(p, name) {
    return StrLower(p.processName) = StrLower(name)
}

IsCandidateProcess(p, name) {
    return p.candidate && IsProcess(p, name)
}
