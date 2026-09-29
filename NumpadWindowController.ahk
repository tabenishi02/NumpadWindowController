#Requires AutoHotkey v2.0
#SingleInstance Force

; === App / Startup / Shutdown ===
; Set this constant to true only for local diagnostics.
global DEBUG_ENABLED := false
global App := App_Create()

if A_LineFile = A_ScriptFullPath
    App_Start()

App_Create() {
    return {Config: Map(), Keys: Map(), Slots: Map(), OriginalNumLock: 0,
        NumLockSaved: false, ZeroDetector: Zero_New(), Hook: 0, InputQueue: [],
        Debug: {Enabled: false, Path: ""}}
}

App_Start() {
    global App, DEBUG_ENABLED
    try {
        userConfig := A_ScriptDir "\KeyBindings.ini"
        Config_EnsureUserConfig(userConfig, A_ScriptDir "\KeyBindings.default.ini")
        metadata := Config_Metadata()
        App.Config := Config_Load(userConfig, metadata, A_ScriptDir)
        App.Keys := App.Config.Keys
        if App.Keys["Backspace"].Mode != "Disabled"
            MsgBox("Backspace is enabled.`nThe keypad Backspace and the standard keyboard Backspace cannot be distinguished.`nBoth will trigger this controller action.", "NumpadWindowController", "Icon!")
        App.OriginalNumLock := GetKeyState("NumLock", "T")
        App.NumLockSaved := true
        OnExit(App_OnExit)
        NumLock_ForceOn()
        App.Slots := Runtime_Init(App.Keys)
        App.Debug := {Enabled: DEBUG_ENABLED,
            Path: A_ScriptDir "\logs\NumpadWindowController_" A_Now ".log"}
        Debug_Log("Startup / Config validated")
        Input_StartZeroDetector()
        Input_RegisterHotkeys()
        AutoBind_Run()
        Persistent()
    } catch as err {
        MsgBox(err.Message, "NumpadWindowController startup error", "Iconx")
        ExitApp(1)
    }
}

App_OnExit(*) {
    global App
    SetTimer(Zero_OnTimer, 0)
    SetTimer(Input_Drain, 0)
    SetTimer(Notify_Clear, 0)
    if IsObject(App.Hook)
        App.Hook.Stop()
    ToolTip()
    if App.NumLockSaved {
        SetNumLockState() ; Release AlwaysOn before restoring the saved toggle.
        SetNumLockState(App.OriginalNumLock ? "On" : "Off")
    }
    Debug_Log("Shutdown")
}

NumLock_ForceOn() {
    SetNumLockState("AlwaysOn")
    Sleep(10)
    if !GetKeyState("NumLock", "T")
        throw Error("Failed to force NumLock ON.")
}

; === Built-in Key Metadata ===
Config_Metadata() {
    result := Map()
    ids := StrSplit("NumpadDiv,NumpadMult,NumpadSub,Numpad7,Numpad8,Numpad9,NumpadAdd,Numpad4,Numpad5,Numpad6,Backspace,Numpad1,Numpad2,Numpad3,Numpad0,Virtual000,NumpadDot,NumpadEnter", ",")
    scans := StrSplit("135,037,04A,047,048,049,04E,04B,04C,04D,00E,04F,050,051,052,052,053,11C", ",")
    for i, id in ids
        result[id] := {Id: id, AhkKey: "SC" scans[i], Dedicated: false,
            AutoBind: false, AutoBindGroup: "", SlotOrder: 1, InputStrategy: "Hotkey"}
    return result
}

Config_LegacyGroup(id) {
    groups := Map("Numpad7", "Chrome", "Numpad8", "Chrome", "Numpad9", "Chrome",
        "Numpad4", "VSCode", "Numpad5", "VSCode", "Numpad6", "VSCode",
        "Numpad1", "Explorer", "Numpad2", "ChatGPT", "Numpad3", "PowerShell")
    return groups.Get(id, "")
}

Config_LegacyOrder(id, group) {
    return group = "Chrome" ? SubStr(id, -1) - 6
        : group = "VSCode" ? SubStr(id, -1) - 3 : 1
}

; === Configuration ===
Config_Map() {
    result := Map()
    result.CaseSense := false
    return result
}

Config_Error(path, section, field, value, reason) {
    throw Error("Configuration error`nFile: " path "`nSection: " section
        "`nField: " field "`nValue: " (value = "" ? "<empty>" : value) "`nReason: " reason)
}

Config_EnsureUserConfig(path, defaultPath) {
    if FileExist(path)
        return
    if !FileExist(defaultPath)
        Config_Error(path, "<file>", "Default", defaultPath, "User configuration is missing and the default configuration was not found.")
    try FileCopy(defaultPath, path, false)
    catch as err
        Config_Error(path, "<file>", "Default", defaultPath, "Failed to create user configuration: " err.Message)
}

Config_ReadText(path) {
    try raw := FileRead(path, "RAW")
    catch
        Config_Error(path, "<file>", "Encoding", "", "Cannot read configuration file.")
    if raw.Size >= 2 && NumGet(raw, 0, "UShort") = 0xFEFF {
        if Mod(raw.Size, 2)
            Config_Error(path, "<file>", "Encoding", "", "Invalid UTF-16 LE byte length.")
        return raw.Size > 2 ? StrGet(raw.Ptr + 2, (raw.Size - 2) // 2, "UTF-16") : ""
    }
    offset := raw.Size >= 3
        && NumGet(raw, 0, "UChar") = 0xEF
        && NumGet(raw, 1, "UChar") = 0xBB
        && NumGet(raw, 2, "UChar") = 0xBF ? 3 : 0
    return raw.Size > offset ? StrGet(raw.Ptr + offset, raw.Size - offset, "UTF-8") : ""
}

Config_Load(path, metadata, baseDir) {
    text := Config_ReadText(path)
    sections := Config_Parse(text, path)
    return Config_Validate(sections, path, metadata, baseDir)
}

Config_Parse(text, path) {
    sections := Config_Map()
    section := ""
    for line in StrSplit(text, "`n", "`r") {
        line := Trim(line)
        if line = "" || SubStr(line, 1, 1) = ";"
            continue
        if RegExMatch(line, "^\[([^\[\]]+)\]$", &match) {
            section := match[1]
            if sections.Has(section)
                Config_Error(path, section, "<section>", section, "Duplicate section.")
            sections[section] := Config_Map()
        } else {
            pos := InStr(line, "=")
            if !pos || section = ""
                Config_Error(path, section, "<syntax>", line, "Expected section or Field=Value.")
            field := Trim(SubStr(line, 1, pos - 1))
            value := Trim(SubStr(line, pos + 1))
            if field = "" || sections[section].Has(field)
                Config_Error(path, section, field, value, "Empty or duplicate field.")
            sections[section][field] := value
        }
    }
    return sections
}

Config_Required(fields, field, path, section) {
    value := fields.Get(field, "")
    if value = ""
        Config_Error(path, section, field, value, "Required non-empty field.")
    return value
}

Config_Validate(sections, path, metadata, baseDir) {
    expected := Config_Map()
    expected["General"] := true
    for id in metadata
        expected["Key-" id] := true
    for section, fields in sections
        if !expected.Has(section)
            Config_Error(path, section, "<section>", section, "Unknown or reserved section.")
    for section in expected
        if !sections.Has(section)
            Config_Error(path, section, "<section>", "", "Missing section.")

    general := sections["General"]
    for field, value in general
        if field != "ConfigVersion"
            Config_Error(path, "General", field, value, "Unknown field.")
    versionText := general.Get("ConfigVersion", "")
    if versionText != "1" && versionText != "2"
        Config_Error(path, "General", "ConfigVersion", versionText, "Supported versions: 1, 2.")
    version := Integer(versionText)
    legacy := version = 1

    keys := Map()
    modes := Config_Map()
    for mode in ["Window", "Shortcut", "Disabled"]
        modes[mode] := mode

    for id, meta in metadata {
        section := "Key-" id
        fields := sections[section]
        mode := Config_Required(fields, "Mode", path, section)
        if !modes.Has(mode)
            Config_Error(path, section, "Mode", mode, "Expected Window, Shortcut or Disabled.")
        mode := modes[mode]

        legacyGroup := legacy ? Config_LegacyGroup(id) : ""
        dedicated := legacyGroup != ""
        if dedicated && mode != "Window"
            Config_Error(path, section, "Mode", mode, "ConfigVersion 1 dedicated slot requires Window mode.")

        allowed := Config_Map()
        for field in StrSplit("Mode,Label," (mode = "Window" ? "AllowedProcess,AllowedClass,AllowedTitleContains" : mode = "Shortcut" ? "Target,Arguments,WorkingDirectory" : ""), ",")
            allowed[field] := true
        for field, value in fields
            if !allowed.Has(field)
                Config_Error(path, section, field, value, "Unknown field or field not allowed for this mode.")

        key := meta.Clone()
        key.Mode := mode
        key.Label := Config_Required(fields, "Label", path, section)
        key.Dedicated := dedicated
        key.AutoBind := dedicated
        key.AutoBindGroup := legacyGroup
        key.SlotOrder := Config_LegacyOrder(id, legacyGroup)
        for field in ["AllowedProcess", "AllowedClass", "AllowedTitleContains"]
            key.%field% := fields.Get(field, "")
        key.ShortcutTarget := ""
        key.ShortcutArguments := fields.Get("Arguments", "")
        key.ShortcutWorkingDirectory := ""

        if dedicated {
            Config_Required(fields, "AllowedProcess", path, section)
            if id = "Numpad1" || id = "Numpad3"
                Config_Required(fields, "AllowedClass", path, section)
            if id = "Numpad3"
                Config_Required(fields, "AllowedTitleContains", path, section)
        }

        if mode = "Shortcut" {
            target := Config_Required(fields, "Target", path, section)
            key.ShortcutTarget := Config_ResolveTarget(target, baseDir, path, section)
            wd := fields.Get("WorkingDirectory", "")
            if wd != "" {
                wd := Config_Absolute(wd, baseDir)
                if !DirExist(wd)
                    Config_Error(path, section, "WorkingDirectory", fields["WorkingDirectory"], "Directory does not exist.")
                key.ShortcutWorkingDirectory := wd
            }
        }
        keys[id] := key
    }

    if legacy {
        for group in [["Numpad7", "Numpad8", "Numpad9"], ["Numpad4", "Numpad5", "Numpad6"]]
            for id in group
                for field in ["AllowedProcess", "AllowedClass", "AllowedTitleContains"]
                    if StrLower(keys[id].%field%) != StrLower(keys[group[1]].%field%)
                        Config_Error(path, "Key-" id, field, keys[id].%field%, "ConfigVersion 1 Allowed conditions must match within the group.")
    }

    if keys["Numpad0"].Mode = "Disabled" && keys["Virtual000"].Mode != "Disabled"
        Config_Error(path, "Key-Virtual000", "Mode", keys["Virtual000"].Mode, "Numpad0 Disabled requires Virtual000 Disabled.")

    zeroDetector := legacy || keys["Virtual000"].Mode != "Disabled"
    for id, key in keys
        key.InputStrategy := ((id = "Numpad0" || id = "Virtual000") && zeroDetector)
            ? "ZeroDetector" : "Hotkey"

    return {Version: version, Keys: keys}
}

Config_Absolute(path, baseDir) {
    return RegExMatch(path, "i)^(?:[a-z]:[\\/]|\\\\)") ? path : baseDir "\" path
}

Config_ResolveTarget(target, baseDir, path, section) {
    SplitPath(target, , , &ext)
    if !RegExMatch(ext, "i)^(exe|bat|cmd|lnk)$")
        Config_Error(path, section, "Target", target, "Supported extensions: exe, bat, cmd, lnk. Use pwsh.exe -File for ps1.")
    if InStr(target, "\") || InStr(target, "/") || InStr(target, ":") {
        resolved := Config_Absolute(target, baseDir)
    } else {
        pathBuffer := Buffer(65536, 0)
        length := DllCall("SearchPathW", "ptr", 0, "str", target, "ptr", 0,
            "uint", 32768, "ptr", pathBuffer, "ptr", 0, "uint")
        resolved := length && length < 32768 ? StrGet(pathBuffer) : ""
    }
    if resolved = "" || !FileExist(resolved) || DirExist(resolved)
        Config_Error(path, section, "Target", target, "Target could not be resolved to an existing file.")
    return resolved
}

; === Runtime State ===
Runtime_Init(keys) {
    slots := Map()
    for id, key in keys
        if key.Mode = "Window"
            slots[id] := Runtime_Empty()
    return slots
}

Runtime_Empty() {
    return {Hwnd: 0, BindingSource: "None"}
}

Runtime_Copy(slots) {
    working := Map()
    for id, slot in slots
        working[id] := slot.Clone()
    return working
}

Runtime_Validate(slots, keys) {
    used := Map()
    for id, key in keys
        if (key.Mode = "Window") != slots.Has(id)
            throw Error("Slot/mode mismatch: " id)
    for id, slot in slots {
        if !keys.Has(id) || keys[id].Mode != "Window"
            throw Error("Unexpected slot: " id)
        if (slot.BindingSource = "None" && slot.Hwnd != 0)
            || (slot.BindingSource != "None" && slot.BindingSource != "Auto" && slot.BindingSource != "Manual")
            || (slot.Hwnd = 0 && slot.BindingSource != "None")
            throw Error("Invalid binding state: " id)
        if slot.Hwnd {
            if used.Has(slot.Hwnd)
                throw Error("Duplicate HWND in working state.")
            used[slot.Hwnd] := true
        }
    }
    return used
}

Runtime_Commit(working) {
    global App
    Runtime_Validate(working, App.Keys)
    App.Slots := working
}

; === Input / Hotkey Registration ===
Input_Modifier() {
    if GetKeyState("LWin", "P") || GetKeyState("RWin", "P")
        return "Unsupported"
    ctrl := GetKeyState("Ctrl", "P")
    shift := GetKeyState("Shift", "P")
    alt := GetKeyState("Alt", "P")
    return Input_ModifierKind(ctrl, shift, alt)
}

Input_ModifierKind(ctrl, shift, alt) {
    if !ctrl
        return !shift && !alt ? "Normal" : "Unsupported"
    return shift && alt ? "Unsupported" : shift ? "CtrlShift" : alt ? "CtrlAlt" : "Ctrl"
}

Input_Context(modifier, *) {
    return Input_Modifier() = modifier
}

Input_HotkeyPlan(keys) {
    plan := []
    for id, key in keys {
        if key.Mode = "Disabled" || key.InputStrategy = "ZeroDetector"
            continue
        for modifier in (key.Mode = "Window" ? ["Normal", "Ctrl", "CtrlShift", "CtrlAlt"] : ["Normal"]) {
            ; Ctrl+NumpadEnter and Ctrl+Shift+NumpadEnter are reserved Global Actions.
            if id = "NumpadEnter" && (modifier = "Ctrl" || modifier = "CtrlShift")
                continue
            plan.Push({Id: id, Key: key.AhkKey, Modifier: modifier})
        }
    }
    return plan
}

Input_GlobalHotkeyPlan() {
    ; NumpadEnter is SC11C. Standard keyboard Enter is SC01C and is unaffected.
    return [
        {Action: "AutoBindAll", Key: "SC11C", Modifier: "Ctrl"},
        {Action: "ClearAll", Key: "SC11C", Modifier: "CtrlShift"}
    ]
}

Input_RegisterHotkeys() {
    global App
    plan := Input_HotkeyPlan(App.Keys)
    for modifier in ["Normal", "Ctrl", "CtrlShift", "CtrlAlt"] {
        HotIf(Input_Context.Bind(modifier))
        for entry in plan
            if entry.Modifier = modifier
                Hotkey("*" entry.Key, Input_Dispatch.Bind(entry.Id, modifier))
    }

    globalPlan := Input_GlobalHotkeyPlan()
    for entry in globalPlan {
        HotIf(Input_Context.Bind(entry.Modifier))
        Hotkey("*" entry.Key, Input_GlobalDispatch.Bind(entry.Action))
    }

    HotIf()
    Debug_Log("Hotkey registration: " (plan.Length + globalPlan.Length))
}

Input_GlobalDispatch(action, *) {
    Debug_Log("Global input dispatch: " action)
    try {
        switch action {
            case "AutoBindAll":
                AutoBind_Run()
                Notify_Info("Auto Bind completed")
            case "ClearAll":
                Binding_Clear()
        }
    } catch as err {
        Debug_Log("Global action failed: " action " / " err.Message)
        Notify_Info("Global action failed: " action)
    }
}

Input_Dispatch(id, modifier, *) {
    global App
    Debug_Log("Input dispatch: " id " / " modifier)
    try {
        key := App.Keys[id]
        if key.Mode = "Disabled"
            return
        if key.Mode = "Shortcut" {
            if modifier = "Normal"
                Action_RunShortcut(id)
            return
        }
        switch modifier {
            case "Normal": Action_ActivateWindow(id)
            case "Ctrl": Binding_ManualBind(id)
            case "CtrlShift": Binding_Clear(id)
            case "CtrlAlt":
                if key.AutoBind {
                    AutoBind_Run(key.AutoBindGroup)
                    Notify_Info(App.Slots[id].Hwnd ? "Auto Bind completed: " key.Label : "No window found: " key.Label)
                } else
                    Notify_Info("Auto Bind disabled for this slot: " key.Label)
        }
    } catch as err {
        Debug_Log("Action failed: " id " / " err.Message)
        Notify_Info("Action failed: " id)
    }
}

Input_Drain() {
    global App
    ; Remove before dispatch: a callback can enqueue more input during activation.
    while App.InputQueue.Length {
        event := App.InputQueue.RemoveAt(1)
        Input_Dispatch(event.Id, event.Modifier)
    }
}

; === Numpad0 / Virtual000 Detector ===
Zero_New() {
    return {Active: false, Start: 0, Pattern: "", Downs: 0, Down: false,
        IgnoreUntilUp: false, Modifier: "Normal"}
}

Zero_WindowMs(modifier) {
    ; The second manual-test log showed successful Ctrl+000 sequences at 31-47 ms.
    ; Failures were caused by an Interrupt, not by the elapsed-time threshold.
    ; Keep one 80 ms window for all modifier states.
    return 80
}

Zero_IsModifierVk(vk) {
    ; Generic and left/right-specific modifier VK values.
    return vk = 0x10 || vk = 0x11 || vk = 0x12
        || vk = 0xA0 || vk = 0xA1 || vk = 0xA2 || vk = 0xA3
        || vk = 0xA4 || vk = 0xA5 || vk = 0x5B || vk = 0x5C
}

Zero_ShouldIgnoreInterrupt(state, vk, modifier) {
    ; A held modifier can emit another KeyDown while the physical 000 key is
    ; producing SC052 D/U events. Ignore only that same modifier state.
    ; A newly pressed modifier changes Input_Modifier() and still interrupts.
    return state.Active && Zero_IsModifierVk(vk) && modifier = state.Modifier
}

Zero_FeedInput(state, kind, tick, modifier := "Normal", vk := 0) {
    if kind = "Interrupt" && Zero_ShouldIgnoreInterrupt(state, vk, modifier)
        return []
    return Zero_Feed(state, kind, tick, modifier)
}

Zero_Finish(state, triple := false) {
    events := []
    if !state.Active
        return events
    Loop (triple ? 1 : state.Downs)
        events.Push({Id: triple ? "Virtual000" : "Numpad0", Modifier: state.Modifier})
    state.IgnoreUntilUp := state.Down
    state.Active := false
    state.Pattern := ""
    state.Downs := 0
    return events
}

Zero_Feed(state, kind, tick, modifier := "Normal") {
    events := []
    if state.Active && tick - state.Start > Zero_WindowMs(state.Modifier)
        events := Zero_Finish(state)
    if kind = "Interrupt" || kind = "Timer" {
        if state.Active
            for event in Zero_Finish(state)
                events.Push(event)
        return events
    }
    if kind = "D" {
        if state.IgnoreUntilUp || state.Down
            return events
        if !state.Active {
            state.Active := true
            state.Start := tick
            state.Modifier := modifier
        }
        state.Down := true
        state.Pattern .= "D"
        state.Downs += 1
    } else if kind = "U" {
        state.Down := false
        if state.IgnoreUntilUp {
            state.IgnoreUntilUp := false
            return events
        }
        if !state.Active
            return events
        state.Pattern .= "U"
        if state.Pattern = "DUDUDU"
            for event in Zero_Finish(state, true)
                events.Push(event)
    }
    return events
}

Input_StartZeroDetector() {
    global App
    if App.Keys["Numpad0"].Mode = "Disabled"
        || App.Keys["Numpad0"].InputStrategy != "ZeroDetector"
        return
    App.Hook := InputHook("V")
    App.Hook.KeyOpt("{All}", "N")
    App.Hook.KeyOpt("{sc052}", "NS")
    App.Hook.OnKeyDown := Zero_OnDown
    App.Hook.OnKeyUp := Zero_OnUp
    App.Hook.Start()
}

Zero_OnDown(ih, vk, sc) {
    Zero_Process(sc = 0x052 ? "D" : "Interrupt", vk, sc)
}

Zero_OnUp(ih, vk, sc) {
    if sc = 0x052
        Zero_Process("U", vk, sc)
}

Zero_OnTimer() {
    Zero_Process("Timer")
}

Zero_Process(kind, vk := 0, sc := 0) {
    global App
    Critical("On")
    try {
        tick := A_TickCount
        modifier := Input_Modifier()
        ignoredModifierInterrupt := kind = "Interrupt"
            && Zero_ShouldIgnoreInterrupt(App.ZeroDetector, vk, modifier)

        if kind = "Interrupt" && App.ZeroDetector.Active {
            Debug_Log("Zero interrupt: vk=" Format("{:02X}", vk)
                " sc=" Format("{:03X}", sc)
                " modifier=" modifier
                " ignored=" ignoredModifierInterrupt
                " pattern=" App.ZeroDetector.Pattern)
        } else if kind != "Interrupt" || App.ZeroDetector.Active {
            Debug_Log("Zero input: kind=" kind " tick=" tick " modifier=" modifier
                " active=" App.ZeroDetector.Active " start=" App.ZeroDetector.Start
                " pattern=" App.ZeroDetector.Pattern)
        }

        for event in Zero_FeedInput(App.ZeroDetector, kind, tick, modifier, vk) {
            Debug_Log("Zero queued: " event.Id " / " event.Modifier
                " elapsed=" (tick - App.ZeroDetector.Start))
            App.InputQueue.Push(event)
        }

        timeout := App.ZeroDetector.Active ? Zero_WindowMs(App.ZeroDetector.Modifier) : 0
        SetTimer(Zero_OnTimer, App.ZeroDetector.Active
            ? -Max(1, timeout + 1 - (A_TickCount - App.ZeroDetector.Start)) : 0)
        if App.InputQueue.Length
            SetTimer(Input_Drain, -1)
    } catch as err {
        App.ZeroDetector := Zero_New()
        Debug_Log("Zero detector error: " err.Message)
        Notify_Info("Zero detector reset after an error")
    } finally {
        Critical("Off")
    }
}

; === Window Probe / Matching ===
Window_GetIdentity(hwnd) {
    if !hwnd || !DllCall("IsWindow", "ptr", hwnd, "int")
        return 0
    previous := A_DetectHiddenWindows
    try {
        DetectHiddenWindows(true)
        spec := "ahk_id " hwnd
        return {Hwnd: hwnd, Process: WinGetProcessName(spec), Class: WinGetClass(spec), Title: WinGetTitle(spec)}
    } catch {
        return 0
    } finally {
        DetectHiddenWindows(previous)
    }
}

Window_MatchesAllowed(candidate, key) {
    return IsObject(candidate)
        && (key.AllowedProcess = "" || StrLower(candidate.Process) = StrLower(key.AllowedProcess))
        && (key.AllowedClass = "" || StrLower(candidate.Class) = StrLower(key.AllowedClass))
        && (key.AllowedTitleContains = "" || InStr(candidate.Title, key.AllowedTitleContains, false))
}

Window_IsExistingBindingValid(hwnd, key) {
    return Window_MatchesAllowed(Window_GetIdentity(hwnd), key)
}

Window_GetPrimaryWorkArea() {
    primary := MonitorGetPrimary()
    MonitorGetWorkArea(primary, &left, &top, &right, &bottom)
    MonitorGet(primary, &ml, &mt, &mr, &mb)
    return {X: left, Y: top, W: right - left, H: bottom - top,
        Left: ml, Top: mt, Right: mr, Bottom: mb}
}

Window_GetCandidate(hwnd) {
    p := Window_GetIdentity(hwnd)
    if !IsObject(p) || hwnd = A_ScriptHwnd
        return 0
    try {
        spec := "ahk_id " hwnd
        WinGetPos(&x, &y, &w, &h, spec)
        p.X := x, p.Y := y, p.W := w, p.H := h
        p.MinMax := WinGetMinMax(spec)
        p.Visible := DllCall("IsWindowVisible", "ptr", hwnd, "int")
        p.Owner := DllCall("GetWindow", "ptr", hwnd, "uint", 4, "ptr")
        p.ToolWindow := (WinGetExStyle(spec) & 0x80) != 0
        cloaked := Buffer(4, 0)
        hr := DllCall("dwmapi\DwmGetWindowAttribute", "ptr", hwnd, "uint", 14,
            "ptr", cloaked, "uint", 4, "int")
        p.Cloaked := hr = 0 ? NumGet(cloaked, 0, "UInt") : 1
        return Window_IsCandidateEligible(p) ? p : 0
    } catch {
        return 0 ; A window may disappear while being probed.
    }
}

Window_IsCandidateEligible(p) {
    return p.Visible && !p.Cloaked && !p.Owner && !p.ToolWindow && p.W > 0 && p.H > 0 && p.Title != ""
}

Window_EnumerateCandidates() {
    candidates := []
    for hwnd in WinGetList() {
        p := Window_GetCandidate(hwnd)
        if IsObject(p)
            candidates.Push(p)
    }
    return candidates
}

; === Binding / Clear ===
Binding_Assign(slots, keys, id, candidate) {
    if keys[id].Mode != "Window" || !Window_MatchesAllowed(candidate, keys[id])
        throw Error("Manual Bind rejected: " keys[id].Label)
    working := Runtime_Copy(slots)
    for oldId, slot in working
        if slot.Hwnd = candidate.Hwnd
            working[oldId] := Runtime_Empty()
    working[id] := {Hwnd: candidate.Hwnd, BindingSource: "Manual"}
    Runtime_Validate(working, keys)
    return working
}

Binding_ManualBind(id) {
    global App
    Critical("On")
    try {
        candidate := Window_GetIdentity(WinExist("A"))
        Runtime_Commit(Binding_Assign(App.Slots, App.Keys, id, candidate))
        Debug_Log("Manual Bind: " id)
        Debug_DumpSlots()
        Notify_Info("Manual Bind: " App.Keys[id].Label)
    } finally {
        Critical("Off")
    }
}

Binding_Clear(id := "", notify := true) {
    global App
    Critical("On")
    try {
        working := Runtime_Copy(App.Slots)
        if id = ""
            working := Runtime_Init(App.Keys)
        else if working.Has(id)
            working[id] := Runtime_Empty()
        Runtime_Commit(working)
        Debug_Log("Clear: " (id = "" ? "All" : id))
        Debug_DumpSlots()
        if notify
            Notify_Info(id = "" ? "All bindings cleared" : "Slot cleared: " App.Keys[id].Label)
    } finally {
        Critical("Off")
    }
}

; === AutoBind / Working State ===
AutoBind_Run(group := "") {
    global App
    Critical("On")
    try {
        Debug_Log("Auto Bind start: " (group = "" ? "All" : group))
        working := AutoBind_Calculate(App.Keys, App.Slots, Window_EnumerateCandidates(), Window_GetPrimaryWorkArea(), group)
        Runtime_Commit(working)
        Debug_Log("Auto Bind complete")
        Debug_DumpSlots()
    } finally {
        Critical("Off")
    }
}

AutoBind_Calculate(keys, slots, candidates, area, group := "", valid := Window_IsExistingBindingValid) {
    working := Runtime_Copy(slots)
    ; A group operation does not clear unrelated slots. Their HWNDs remain reserved.
    for id, slot in working
        if (group = "" || keys[id].AutoBindGroup = group) && slot.Hwnd && !valid.Call(slot.Hwnd, keys[id])
            working[id] := Runtime_Empty()
    used := Runtime_Validate(working, keys)
    hasAutoBind := false
    for id, key in keys
        if key.AutoBind {
            hasAutoBind := true
            break
        }
    if !hasAutoBind
        return working
    for current in ["Chrome", "VSCode", "Explorer", "ChatGPT", "PowerShell"] {
        if group != "" && group != current
            continue
        ids := current = "Chrome" ? ["Numpad7", "Numpad8", "Numpad9"]
            : current = "VSCode" ? ["Numpad4", "Numpad5", "Numpad6"]
            : [current = "Explorer" ? "Numpad1" : current = "ChatGPT" ? "Numpad2" : "Numpad3"]
        for id in ids {
            if working[id].Hwnd
                continue
            best := 0
            bestScore := 1.0e20
            Loop candidates.Length {
                p := candidates[current = "VSCode" ? candidates.Length - A_Index + 1 : A_Index]
                if used.Has(p.Hwnd) || !Window_MatchesAllowed(p, keys[id]) || !Window_IsCandidateEligible(p)
                    continue
                if current = "Chrome" {
                    score := AutoBind_ChromeScore(p, area, keys[id].SlotOrder)
                    if score < 0 || score >= bestScore
                        continue
                    best := p
                    bestScore := score
                } else if current = "VSCode" {
                    best := p
                    break
                } else if !IsObject(best) || (best.MinMax = -1 && p.MinMax != -1) {
                    best := p
                }
            }
            if IsObject(best) {
                working[id] := {Hwnd: best.Hwnd, BindingSource: "Auto"}
                used[best.Hwnd] := true
            }
        }
    }
    Runtime_Validate(working, keys)
    return working
}

AutoBind_ChromeScore(p, area, order) {
    cx := p.X + p.W / 2, cy := p.Y + p.H / 2
    if p.MinMax != 0 || cx < area.Left || cx >= area.Right || cy < area.Top || cy >= area.Bottom
        return -1
    x := (p.X - area.X) / area.W, y := (p.Y - area.Y) / area.H
    w := p.W / area.W, h := p.H / area.H
    nx := (cx - area.X) / area.W, ny := (cy - area.Y) / area.H
    ; Same thresholds and ideal rectangle score as Phase B's Chrome PoC.
    if order < 3 {
        if !(nx < 0.40 && w >= 0.15 && w <= 0.45 && h >= 0.30 && h <= 0.70)
            || (order = 1 ? ny >= 0.50 : ny < 0.50)
            return -1
        return Abs(x) + Abs(y - (order = 1 ? 0 : 0.5)) + Abs(w - 0.3) + Abs(h - 0.5)
    }
    if !(nx >= 0.40 && w >= 0.50 && w <= 0.90 && h >= 0.70 && h <= 1.05)
        return -1
    return Abs(x - 0.3) + Abs(y) + Abs(w - 0.7) + Abs(h - 1)
}

; === Window Actions ===
Action_ActivateWindow(id) {
    global App
    key := App.Keys[id]
    if !Window_IsExistingBindingValid(App.Slots[id].Hwnd, key) {
        Binding_Clear(id, false)
        if key.AutoBind {
            AutoBind_Run(key.AutoBindGroup)
            Debug_Log("Lazy Auto Bind: " id)
        }
    }
    hwnd := App.Slots[id].Hwnd
    if !hwnd {
        Notify_Info("No window found: " key.Label)
        return
    }
    try {
        spec := "ahk_id " hwnd
        if WinGetMinMax(spec) = -1
            WinRestore(spec)
        WinActivate(spec)
        if !WinWaitActive(spec, , 0.5)
            throw Error("Foreground activation failed.")
    } catch as err {
        if !Window_IsExistingBindingValid(hwnd, key) && App.Slots[id].Hwnd = hwnd
            Binding_Clear(id, false)
        Debug_Log("Activate failed: " id " / " err.Message)
        Notify_Info("Activate failed: " key.Label)
    }
}

; === Shortcut Actions ===
Action_RunShortcut(id) {
    global App
    key := App.Keys[id]
    try {
        Run('"' key.ShortcutTarget '"' (key.ShortcutArguments = "" ? "" : " " key.ShortcutArguments), key.ShortcutWorkingDirectory, , &pid)
        Debug_Log("Shortcut launched: " id)
        return pid
    } catch as err {
        Debug_Log("Shortcut failed: " id " / " err.Message)
        Notify_Info("Shortcut failed: " key.Label)
        return 0
    }
}

; === Notification ===
Notify_Info(text) {
    ToolTip(text)
    SetTimer(Notify_Clear, -1200)
}

Notify_Clear() {
    ToolTip()
}

; === Debug Logging ===
Debug_Log(text) {
    global App
    if !App.Debug.Enabled
        return
    try {
        SplitPath(App.Debug.Path, , &dir)
        DirCreate(dir)
        FileAppend(A_Now " " text "`n", App.Debug.Path, "UTF-8")
    } catch {
        ; Diagnostics must never break input or binding operations.
    }
}

Debug_DumpSlots() {
    global App
    if !App.Debug.Enabled
        return
    snapshot := "Slots:"
    for id, slot in App.Slots
        snapshot .= "`n" id " " slot.BindingSource " " Format("0x{:X}", slot.Hwnd)
    Debug_Log(snapshot)
}
