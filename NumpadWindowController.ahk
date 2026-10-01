#Requires AutoHotkey v2.0
#SingleInstance Force

; NumpadWindowController - Phase K runtime
; ConfigVersion 3 only: Physical Key -> Layer -> Action.

global DEBUG_ENABLED := false
global App := App_Create()

if A_LineFile = A_ScriptFullPath
    App_Start()

; === App / Startup / Shutdown ===

App_Create() {
    return {
        Config: 0,
        Metadata: Config_Map(),
        WindowState: Map(),
        ActiveLayer: "",
        OriginalNumLock: 0,
        NumLockSaved: false,
        ZeroDetector: Zero_New(false, false),
        Hook: 0,
        InputQueue: [],
        LaunchPending: Map(),
        MultiRunning: Map(),
        Debug: {Enabled: false, Path: ""}
    }
}

App_Start() {
    global App, DEBUG_ENABLED
    try {
        userConfig := A_ScriptDir "\KeyBindings.ini"
        Config_EnsureUserConfig(userConfig, A_ScriptDir "\KeyBindings.default.ini")
        App.Metadata := Config_Metadata()
        App.Config := Config_Load(userConfig, App.Metadata, A_ScriptDir)
        App.ActiveLayer := App.Config.DefaultLayer
        App.WindowState := Runtime_Init(App.Config)
        App.ZeroDetector := Zero_New(App.Config.EnableVirtual00, App.Config.EnableVirtual000)

        if Config_KeyIsControllerMapped(App.Config, "Backspace")
            MsgBox("Backspace is enabled.`nThe keypad Backspace and the standard keyboard Backspace cannot be distinguished.`nBoth will trigger this controller action.", "NumpadWindowController", "Icon!")

        App.OriginalNumLock := GetKeyState("NumLock", "T")
        App.NumLockSaved := true
        OnExit(App_OnExit)
        NumLock_ForceOn()

        App.Debug := {
            Enabled: DEBUG_ENABLED,
            Path: A_ScriptDir "\logs\NumpadWindowController_" A_Now ".log"
        }

        Debug_Log("Startup / ConfigVersion 3 validated / Layer=" App.ActiveLayer)
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
    SetTimer(Launch_CheckPending, 0)
    SetTimer(Notify_Clear, 0)
    if IsObject(App.Hook)
        App.Hook.Stop()
    ToolTip()
    if App.NumLockSaved {
        SetNumLockState()
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

; === Metadata ===

Config_Metadata() {
    result := Config_Map()
    ids := [
        ["NumpadDiv", "SC135", false],
        ["NumpadMult", "SC037", false],
        ["NumpadSub", "SC04A", false],
        ["Numpad7", "SC047", false],
        ["Numpad8", "SC048", false],
        ["Numpad9", "SC049", false],
        ["NumpadAdd", "SC04E", false],
        ["Numpad4", "SC04B", false],
        ["Numpad5", "SC04C", false],
        ["Numpad6", "SC04D", false],
        ["Backspace", "SC00E", false],
        ["Numpad1", "SC04F", false],
        ["Numpad2", "SC050", false],
        ["Numpad3", "SC051", false],
        ["Numpad0", "SC052", false],
        ["Virtual00", "SC052", true],
        ["Virtual000", "SC052", true],
        ["NumpadDot", "SC053", false],
        ["NumpadEnter", "SC11C", false]
    ]
    for row in ids
        result[row[1]] := {Id: row[1], AhkKey: row[2], Virtual: row[3]}
    return result
}

; === Configuration primitives ===

Config_Map() {
    result := Map()
    result.CaseSense := false
    return result
}

Config_Error(path, section, field, value, reason) {
    throw Error("Configuration error`nFile: " path "`nSection: " section
        "`nField: " field "`nValue: " (value = "" ? "<empty>" : value)
        "`nReason: " reason)
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

    if raw.Size >= 2 {
        bom16 := NumGet(raw, 0, "UShort")
        if bom16 = 0xFEFF || bom16 = 0xFFFE
            Config_Error(path, "<file>", "Encoding", "", "UTF-8 is required. UTF-16 configuration files are not supported.")
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

Config_RejectUnknown(fields, allowedFields, path, section) {
    allowed := Config_Map()
    for field in allowedFields
        allowed[field] := true
    for field, value in fields
        if !allowed.Has(field)
            Config_Error(path, section, field, value, "Unknown field.")
}

Config_Name(value, path, section, field) {
    if !RegExMatch(value, "^[A-Za-z0-9][A-Za-z0-9_-]*$")
        Config_Error(path, section, field, value, "Use letters, numbers, underscore or hyphen; the first character must be alphanumeric.")
    return value
}

Config_Bool(value, path, section, field) {
    if StrLower(value) = "on"
        return true
    if StrLower(value) = "off"
        return false
    Config_Error(path, section, field, value, "Expected On or Off.")
}

Config_Int(value, path, section, field, minValue := 0, maxValue := 2147483647) {
    if !RegExMatch(value, "^\d+$")
        Config_Error(path, section, field, value, "Expected an integer.")
    number := Integer(value)
    if number < minValue || number > maxValue
        Config_Error(path, section, field, value, "Integer is outside the allowed range.")
    return number
}

Config_Csv(value, path, section, field) {
    result := []
    seen := Config_Map()
    for raw in StrSplit(value, ",") {
        item := Trim(raw)
        if item = ""
            Config_Error(path, section, field, value, "Empty list item.")
        Config_Name(item, path, section, field)
        if seen.Has(item)
            Config_Error(path, section, field, value, "Duplicate list item: " item)
        seen[item] := true
        result.Push(item)
    }
    if !result.Length
        Config_Error(path, section, field, value, "At least one item is required.")
    return result
}

Config_Absolute(path, baseDir) {
    return RegExMatch(path, "i)^(?:[a-z]:[\\/]|\\\\)") ? path : baseDir "\" path
}

Config_ResolveTarget(target, baseDir, path, section, field := "Target") {
    SplitPath(target, , , &ext)
    if !RegExMatch(ext, "i)^(exe|bat|cmd|lnk)$")
        Config_Error(path, section, field, target, "Supported extensions: exe, bat, cmd, lnk. Use pwsh.exe -File for ps1.")
    if InStr(target, "\") || InStr(target, "/") || InStr(target, ":") {
        resolved := Config_Absolute(target, baseDir)
    } else {
        pathBuffer := Buffer(65536, 0)
        length := DllCall("SearchPathW", "ptr", 0, "str", target, "ptr", 0,
            "uint", 32768, "ptr", pathBuffer, "ptr", 0, "uint")
        resolved := length && length < 32768 ? StrGet(pathBuffer) : ""
    }
    if resolved = "" || !FileExist(resolved) || DirExist(resolved)
        Config_Error(path, section, field, target, "Target could not be resolved to an existing file.")
    return resolved
}

Config_Validate(sections, path, metadata, baseDir) {
    if !sections.Has("General")
        Config_Error(path, "General", "<section>", "", "Missing section.")
    general := sections["General"]
    Config_RejectUnknown(general,
        ["ConfigVersion", "DefaultLayer", "LayerOrder", "EnableVirtual00", "EnableVirtual000"],
        path, "General")

    versionText := Config_Required(general, "ConfigVersion", path, "General")
    if versionText != "3"
        Config_Error(path, "General", "ConfigVersion", versionText, "Phase K runtime supports ConfigVersion 3 only.")

    defaultLayer := Config_Name(Config_Required(general, "DefaultLayer", path, "General"),
        path, "General", "DefaultLayer")
    layerOrder := Config_Csv(Config_Required(general, "LayerOrder", path, "General"),
        path, "General", "LayerOrder")
    enable00 := Config_Bool(Config_Required(general, "EnableVirtual00", path, "General"),
        path, "General", "EnableVirtual00")
    enable000 := Config_Bool(Config_Required(general, "EnableVirtual000", path, "General"),
        path, "General", "EnableVirtual000")

    layerNames := Config_Map()
    for layer in layerOrder
        layerNames[layer] := true
    if !layerNames.Has(defaultLayer)
        Config_Error(path, "General", "DefaultLayer", defaultLayer, "DefaultLayer must be included in LayerOrder.")

    ; Classify sections first.
    actionSections := Config_Map()
    groupSections := Config_Map()
    layerSections := Config_Map()
    for section, fields in sections {
        if section = "General" || section = "GlobalKeys"
            continue
        if RegExMatch(section, "i)^Action-(.+)$", &match) {
            id := Config_Name(match[1], path, section, "<section>")
            if actionSections.Has(id)
                Config_Error(path, section, "<section>", id, "Duplicate Action ID.")
            actionSections[id] := fields
            continue
        }
        if RegExMatch(section, "i)^WindowGroup-(.+)$", &match) {
            id := Config_Name(match[1], path, section, "<section>")
            if groupSections.Has(id)
                Config_Error(path, section, "<section>", id, "Duplicate WindowGroup ID.")
            groupSections[id] := fields
            continue
        }
        if RegExMatch(section, "i)^Layer-(.+)$", &match) {
            id := Config_Name(match[1], path, section, "<section>")
            if layerSections.Has(id)
                Config_Error(path, section, "<section>", id, "Duplicate Layer ID.")
            layerSections[id] := fields
            continue
        }
        Config_Error(path, section, "<section>", section, "Unknown or reserved section.")
    }

    for layer in layerOrder
        if !layerSections.Has(layer)
            Config_Error(path, "Layer-" layer, "<section>", "", "LayerOrder entry is missing its Layer section.")
    for layer in layerSections
        if !layerNames.Has(layer)
            Config_Error(path, "Layer-" layer, "<section>", layer, "Layer section is not listed in LayerOrder.")

    groups := Config_Map()
    for id, fields in groupSections
        groups[id] := Config_ValidateWindowGroup(id, fields, path, baseDir)

    actions := Config_Map()
    for id, fields in actionSections
        actions[id] := Config_ValidateAction(id, fields, path, baseDir, groups, layerNames)

    if actions.Count = 0
        Config_Error(path, "<actions>", "<section>", "", "At least one Action section is required.")

    globalKeys := Config_Map()
    if sections.Has("GlobalKeys")
        globalKeys := Config_ValidateMapping(sections["GlobalKeys"], "GlobalKeys", path, metadata, actions)

    layers := Config_Map()
    for layer in layerOrder
        layers[layer] := {
            Name: layer,
            Keys: Config_ValidateMapping(layerSections[layer], "Layer-" layer, path, metadata, actions)
        }

    if layerOrder.Length > 1 {
        hasGlobalLayerSwitch := false
        for id, actionId in globalKeys {
            if actions[actionId].Type = "LayerSwitch" {
                hasGlobalLayerSwitch := true
                break
            }
        }
        if !hasGlobalLayerSwitch
            Config_Error(path, "GlobalKeys", "<mapping>", "", "Multiple layers require at least one global LayerSwitch mapping so every layer can be exited safely.")
    }

    ; Validate MultiAction references after all actions exist.
    for id, action in actions {
        if action.Type != "MultiAction"
            continue
        for step in action.Steps {
            if !actions.Has(step)
                Config_Error(path, "Action-" id, "<step>", step, "Referenced Action does not exist.")
            if actions[step].Type = "MultiAction"
                Config_Error(path, "Action-" id, "<step>", step, "Nested MultiAction is not supported in Phase K.")
            if StrLower(step) = StrLower(id)
                Config_Error(path, "Action-" id, "<step>", step, "Action reference cycle is not allowed.")
        }
    }

    return {
        Version: 3,
        DefaultLayer: defaultLayer,
        LayerOrder: layerOrder,
        EnableVirtual00: enable00,
        EnableVirtual000: enable000,
        GlobalKeys: globalKeys,
        Layers: layers,
        Actions: actions,
        WindowGroups: groups
    }
}

Config_ValidateWindowGroup(id, fields, path, baseDir) {
    section := "WindowGroup-" id
    Config_RejectUnknown(fields,
        ["MatchProcess", "MatchClass", "MatchTitleContains", "LaunchTarget",
         "LaunchArguments", "LaunchWorkingDirectory", "LaunchPendingTimeoutMs"],
        path, section)

    group := {
        Id: id,
        MatchProcess: fields.Get("MatchProcess", ""),
        MatchClass: fields.Get("MatchClass", ""),
        MatchTitleContains: fields.Get("MatchTitleContains", ""),
        LaunchTarget: "",
        LaunchArguments: fields.Get("LaunchArguments", ""),
        LaunchWorkingDirectory: "",
        LaunchPendingTimeoutMs: fields.Get("LaunchPendingTimeoutMs", "") = ""
            ? 5000
            : Config_Int(fields["LaunchPendingTimeoutMs"], path, section, "LaunchPendingTimeoutMs", 250, 60000)
    }

    if group.MatchProcess = "" && group.MatchClass = "" && group.MatchTitleContains = ""
        Config_Error(path, section, "<match>", "", "WindowGroup requires at least one Match condition.")

    launchTarget := fields.Get("LaunchTarget", "")
    if launchTarget != "" {
        group.LaunchTarget := Config_ResolveTarget(launchTarget, baseDir, path, section, "LaunchTarget")
        wd := fields.Get("LaunchWorkingDirectory", "")
        if wd != "" {
            wd := Config_Absolute(wd, baseDir)
            if !DirExist(wd)
                Config_Error(path, section, "LaunchWorkingDirectory", fields["LaunchWorkingDirectory"], "Directory does not exist.")
            group.LaunchWorkingDirectory := wd
        }
    } else if group.LaunchArguments != "" || fields.Get("LaunchWorkingDirectory", "") != "" {
        Config_Error(path, section, "LaunchTarget", "", "LaunchArguments/LaunchWorkingDirectory require LaunchTarget.")
    }
    return group
}

Config_ValidateAction(id, fields, path, baseDir, groups, layerNames) {
    section := "Action-" id
    type := Config_Required(fields, "Type", path, section)
    label := Config_Required(fields, "Label", path, section)

    types := Config_Map()
    for value in ["Window", "Run", "KeySend", "LayerSwitch", "Delay", "MultiAction", "Disabled"]
        types[value] := value
    if !types.Has(type)
        Config_Error(path, section, "Type", type, "Expected Window, Run, KeySend, LayerSwitch, Delay, MultiAction or Disabled.")
    type := types[type]

    if type = "Window" {
        Config_RejectUnknown(fields,
            ["Type", "Label", "Behavior", "WindowGroup", "AllowedProcess", "AllowedClass",
             "AllowedTitleContains", "AutoBindStrategy", "AutoBindOrder"],
            path, section)
        behavior := Config_Required(fields, "Behavior", path, section)
        if StrLower(behavior) = "toggle"
            behavior := "Toggle"
        else if StrLower(behavior) = "activate"
            behavior := "Activate"
        else if StrLower(behavior) = "activatethentoggle"
            behavior := "ActivateThenToggle"
        else
            Config_Error(path, section, "Behavior", behavior,
                "Expected Toggle, Activate or ActivateThenToggle.")

        strategy := fields.Get("AutoBindStrategy", "None")
        strategies := Config_Map()
        for value in ["None", "FirstMatch", "ReverseList", "PrimaryThreePane"]
            strategies[value] := value
        if !strategies.Has(strategy)
            Config_Error(path, section, "AutoBindStrategy", strategy, "Expected None, FirstMatch, ReverseList or PrimaryThreePane.")
        strategy := strategies[strategy]

        order := fields.Get("AutoBindOrder", "") = "" ? 1
            : Config_Int(fields["AutoBindOrder"], path, section, "AutoBindOrder", 1, 999)
        if strategy = "PrimaryThreePane" && (order < 1 || order > 3)
            Config_Error(path, section, "AutoBindOrder", order, "PrimaryThreePane requires order 1, 2 or 3.")

        group := fields.Get("WindowGroup", "")
        if group != "" && !groups.Has(group)
            Config_Error(path, section, "WindowGroup", group, "Referenced WindowGroup does not exist.")

        return {
            Id: id, Type: type, Label: label, Behavior: behavior,
            WindowGroup: group,
            AllowedProcess: fields.Get("AllowedProcess", ""),
            AllowedClass: fields.Get("AllowedClass", ""),
            AllowedTitleContains: fields.Get("AllowedTitleContains", ""),
            AutoBindStrategy: strategy,
            AutoBindOrder: order
        }
    }

    if type = "Run" {
        Config_RejectUnknown(fields, ["Type", "Label", "Target", "Arguments", "WorkingDirectory"], path, section)
        target := Config_ResolveTarget(Config_Required(fields, "Target", path, section), baseDir, path, section)
        wd := fields.Get("WorkingDirectory", "")
        if wd != "" {
            wd := Config_Absolute(wd, baseDir)
            if !DirExist(wd)
                Config_Error(path, section, "WorkingDirectory", fields["WorkingDirectory"], "Directory does not exist.")
        }
        return {
            Id: id, Type: type, Label: label,
            Target: target,
            Arguments: fields.Get("Arguments", ""),
            WorkingDirectory: wd
        }
    }

    if type = "KeySend" {
        Config_RejectUnknown(fields, ["Type", "Label", "Keys"], path, section)
        keys := Config_Required(fields, "Keys", path, section)
        return {Id: id, Type: type, Label: label, Keys: keys, SendSpec: KeySend_Compile(keys, path, section)}
    }

    if type = "LayerSwitch" {
        Config_RejectUnknown(fields, ["Type", "Label", "Mode", "Layer"], path, section)
        mode := Config_Required(fields, "Mode", path, section)
        if StrLower(mode) = "set"
            mode := "Set"
        else if StrLower(mode) = "next"
            mode := "Next"
        else
            Config_Error(path, section, "Mode", mode, "Expected Set or Next.")
        layer := fields.Get("Layer", "")
        if mode = "Set" {
            layer := Config_Required(fields, "Layer", path, section)
            if !layerNames.Has(layer)
                Config_Error(path, section, "Layer", layer, "Referenced Layer is not listed in LayerOrder.")
        } else if layer != ""
            Config_Error(path, section, "Layer", layer, "Layer is only valid with Mode=Set.")
        return {Id: id, Type: type, Label: label, Mode: mode, Layer: layer}
    }

    if type = "Delay" {
        Config_RejectUnknown(fields, ["Type", "Label", "Milliseconds"], path, section)
        ms := Config_Int(Config_Required(fields, "Milliseconds", path, section),
            path, section, "Milliseconds", 0, 60000)
        return {Id: id, Type: type, Label: label, Milliseconds: ms}
    }

    if type = "MultiAction" {
        steps := []
        maxStep := 0
        for field, value in fields {
            if field = "Type" || field = "Label"
                continue
            if !RegExMatch(field, "i)^Step(\d+)$", &match)
                Config_Error(path, section, field, value, "Unknown field.")
            n := Integer(match[1])
            if n < 1
                Config_Error(path, section, field, value, "Step numbers start at 1.")
            if n > maxStep
                maxStep := n
        }
        if maxStep = 0
            Config_Error(path, section, "Step1", "", "MultiAction requires at least one step.")
        Loop maxStep {
            field := "Step" A_Index
            if !fields.Has(field)
                Config_Error(path, section, field, "", "Step numbers must be continuous from 1.")
            steps.Push(Config_Name(Config_Required(fields, field, path, section), path, section, field))
        }
        return {Id: id, Type: type, Label: label, Steps: steps}
    }

    Config_RejectUnknown(fields, ["Type", "Label"], path, section)
    return {Id: id, Type: type, Label: label}
}

Config_ValidateMapping(fields, section, path, metadata, actions) {
    mapping := Config_Map()
    for keyId, actionId in fields {
        if !metadata.Has(keyId)
            Config_Error(path, section, keyId, actionId, "Unknown logical key.")
        actionId := Config_Name(actionId, path, section, keyId)
        if !actions.Has(actionId)
            Config_Error(path, section, keyId, actionId, "Referenced Action does not exist.")
        mapping[keyId] := actionId
    }
    return mapping
}

Config_KeyIsControllerMapped(config, id) {
    if config.GlobalKeys.Has(id) && config.Actions[config.GlobalKeys[id]].Type != "Disabled"
        return true
    for layerName in config.LayerOrder {
        layer := config.Layers[layerName]
        if layer.Keys.Has(id) && config.Actions[layer.Keys[id]].Type != "Disabled"
            return true
    }
    return false
}

; === KeySend parser ===

KeySend_Compile(text, path := "<memory>", section := "<KeySend>") {
    modifierSymbols := Config_Map()
    modifierSymbols["Ctrl"] := "^"
    modifierSymbols["Shift"] := "+"
    modifierSymbols["Alt"] := "!"
    modifierSymbols["Win"] := "#"

    named := Config_Map()
    for key in ["Tab", "Enter", "Escape", "Space", "Backspace", "Delete", "Insert",
                "Home", "End", "PageUp", "PageDown", "Up", "Down", "Left", "Right",
                "PrintScreen", "Volume_Up", "Volume_Down", "Volume_Mute",
                "Media_Play_Pause", "Media_Next", "Media_Prev", "Media_Stop",
                "Browser_Back", "Browser_Forward", "Browser_Refresh"]
        named[key] := key

    aliases := Config_Map()
    aliases["Esc"] := "Escape"
    aliases["PgUp"] := "PageUp"
    aliases["PgDn"] := "PageDown"

    modifiers := Config_Map()
    keyToken := ""
    for raw in StrSplit(text, "+") {
        token := Trim(raw)
        if token = ""
            Config_Error(path, section, "Keys", text, "Empty KeySend token.")
        if modifierSymbols.Has(token) {
            if modifiers.Has(token)
                Config_Error(path, section, "Keys", text, "Duplicate modifier: " token)
            modifiers[token] := true
            continue
        }
        if keyToken != ""
            Config_Error(path, section, "Keys", text, "Exactly one non-modifier key is required.")
        keyToken := token
    }

    if keyToken = ""
        Config_Error(path, section, "Keys", text, "A non-modifier key is required.")

    keySpec := ""
    if RegExMatch(keyToken, "i)^[A-Z]$")
        keySpec := StrLower(keyToken)
    else if RegExMatch(keyToken, "^[0-9]$")
        keySpec := keyToken
    else if RegExMatch(keyToken, "i)^F([1-9]|1[0-9]|2[0-4])$")
        keySpec := "{" StrUpper(keyToken) "}"
    else {
        if aliases.Has(keyToken)
            keyToken := aliases[keyToken]
        if !named.Has(keyToken)
            Config_Error(path, section, "Keys", text, "Unknown KeySend key: " keyToken)
        keySpec := "{" named[keyToken] "}"
    }

    prefix := ""
    for modifier in ["Ctrl", "Shift", "Alt", "Win"]
        if modifiers.Has(modifier)
            prefix .= modifierSymbols[modifier]
    return prefix keySpec
}

; === Layer / Action resolution ===

Action_IdForKey(id) {
    global App
    if App.Config.GlobalKeys.Has(id)
        return App.Config.GlobalKeys[id]
    layer := App.Config.Layers[App.ActiveLayer]
    return layer.Keys.Get(id, "")
}

Action_GetForKey(id) {
    global App
    actionId := Action_IdForKey(id)
    return actionId != "" && App.Config.Actions.Has(actionId) ? App.Config.Actions[actionId] : 0
}

Layer_Set(name, notify := true) {
    global App
    if !App.Config.Layers.Has(name)
        throw Error("Unknown layer: " name)
    App.ActiveLayer := App.Config.Layers[name].Name
    Debug_Log("Layer Set: " App.ActiveLayer)
    if notify
        Notify_Info("Layer: " App.ActiveLayer)
}

Layer_Next(notify := true) {
    global App
    index := 0
    for i, name in App.Config.LayerOrder {
        if StrLower(name) = StrLower(App.ActiveLayer) {
            index := i
            break
        }
    }
    if !index
        throw Error("Active layer is not in LayerOrder.")
    nextIndex := index = App.Config.LayerOrder.Length ? 1 : index + 1
    Layer_Set(App.Config.LayerOrder[nextIndex], notify)
    return App.ActiveLayer
}

; === Runtime Window State ===

Runtime_Init(config) {
    state := Map()
    for id, action in config.Actions
        if action.Type = "Window"
            state[id] := Runtime_Empty()
    return state
}

Runtime_Empty() {
    return {Hwnd: 0, BindingSource: "None", ToggleArmed: false}
}

Runtime_Copy(state) {
    working := Map()
    for id, slot in state
        working[id] := slot.Clone()
    return working
}

Runtime_Validate(state, config) {
    used := Map()
    for id, action in config.Actions {
        if (action.Type = "Window") != state.Has(id)
            throw Error("Window runtime/action mismatch: " id)
    }
    for id, slot in state {
        if !config.Actions.Has(id) || config.Actions[id].Type != "Window"
            throw Error("Unexpected Window runtime state: " id)
        if !slot.HasProp("ToggleArmed")
            || (slot.ToggleArmed != true && slot.ToggleArmed != false)
            || (slot.BindingSource = "None" && slot.Hwnd != 0)
            || (slot.BindingSource != "None" && slot.BindingSource != "Auto" && slot.BindingSource != "Manual")
            || (slot.Hwnd = 0 && slot.BindingSource != "None")
            throw Error("Invalid binding state: " id)
        if slot.Hwnd {
            if used.Has(slot.Hwnd)
                throw Error("Duplicate HWND in Window runtime state.")
            used[slot.Hwnd] := true
        }
    }
    return used
}

Runtime_Commit(working) {
    global App
    Runtime_Validate(working, App.Config)
    App.WindowState := working
}

; === Input / Hotkeys ===

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

Input_ShouldCapture(id, modifier) {
    global App
    if modifier = "Normal" {
        action := Action_GetForKey(id)
        return IsObject(action) && action.Type != "Disabled"
    }
    action := Action_GetForKey(id)
    return IsObject(action) && action.Type = "Window"
}

Input_Context(id, modifier, *) {
    return Input_Modifier() = modifier && Input_ShouldCapture(id, modifier)
}

Input_ZeroDetectorEnabled() {
    global App
    return App.Config.EnableVirtual00 || App.Config.EnableVirtual000
}

Input_HotkeyPlan(metadata, zeroDetectorEnabled) {
    plan := []
    for id, meta in metadata {
        if meta.Virtual || (id = "Numpad0" && zeroDetectorEnabled)
            continue
        for modifier in ["Normal", "Ctrl", "CtrlShift", "CtrlAlt"] {
            if id = "NumpadEnter" && (modifier = "Ctrl" || modifier = "CtrlShift")
                continue
            plan.Push({Id: id, Key: meta.AhkKey, Modifier: modifier})
        }
    }
    return plan
}

Input_GlobalHotkeyPlan() {
    return [
        {Action: "AutoBindAll", Key: "SC11C", Modifier: "Ctrl"},
        {Action: "ClearAll", Key: "SC11C", Modifier: "CtrlShift"}
    ]
}

Input_GlobalContext(modifier, *) {
    return Input_Modifier() = modifier
}

Input_RegisterHotkeys() {
    global App
    plan := Input_HotkeyPlan(App.Metadata, Input_ZeroDetectorEnabled())
    for entry in plan {
        HotIf(Input_Context.Bind(entry.Id, entry.Modifier))
        Hotkey("*" entry.Key, Input_Dispatch.Bind(entry.Id, entry.Modifier))
    }
    for entry in Input_GlobalHotkeyPlan() {
        HotIf(Input_GlobalContext.Bind(entry.Modifier))
        Hotkey("*" entry.Key, Input_GlobalDispatch.Bind(entry.Action))
    }
    HotIf()
    Debug_Log("Hotkey registration plan: " (plan.Length + Input_GlobalHotkeyPlan().Length))
}

Input_GlobalDispatch(action, *) {
    Debug_Log("Global dispatch: " action)
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
    Input_DispatchCore(id, modifier, false)
}

Input_DispatchCore(id, modifier, fromZeroDetector := false) {
    global App
    Debug_Log("Input dispatch: " id " / " modifier " / Layer=" App.ActiveLayer)
    try {
        actionId := Action_IdForKey(id)
        if actionId = "" {
            if fromZeroDetector
                Input_ZeroPassThrough(id, modifier)
            return
        }

        action := App.Config.Actions[actionId]
        if action.Type = "Disabled" {
            if fromZeroDetector
                Input_ZeroPassThrough(id, modifier)
            return
        }

        if fromZeroDetector && modifier = "Unsupported" {
            Input_ZeroPassThrough(id, modifier)
            return
        }

        ; Non-Window actions only own the unmodified key. Modifier combinations
        ; remain native input, matching direct-hotkey behavior.
        if fromZeroDetector && modifier != "Normal" && action.Type != "Window" {
            Input_ZeroPassThrough(id, modifier)
            return
        }

        switch modifier {
            case "Normal":
                Action_Execute(actionId)
            case "Ctrl":
                if action.Type = "Window"
                    Binding_ManualBind(actionId)
            case "CtrlShift":
                if action.Type = "Window"
                    Binding_Clear(actionId)
            case "CtrlAlt":
                if action.Type = "Window" {
                    if action.AutoBindStrategy = "None"
                        Notify_Info("Auto Bind disabled: " action.Label)
                    else {
                        AutoBind_Action(actionId)
                        Notify_Info(App.WindowState[actionId].Hwnd
                            ? "Auto Bind completed: " action.Label
                            : "No window found: " action.Label)
                    }
                }
        }
    } catch as err {
        Debug_Log("Action failed: " id " / " err.Message)
        Notify_Info("Action failed: " id)
    }
}

Input_ZeroPassThroughSpec(id, modifier) {
    count := id = "Virtual000" ? 3 : id = "Virtual00" ? 2 : 1
    prefix := modifier = "Ctrl" ? "^"
        : modifier = "CtrlShift" ? "^+"
        : modifier = "CtrlAlt" ? "^!"
        : ""
    return prefix "{Numpad0 " count "}"
}

Input_ZeroPassThrough(id, modifier) {
    ; SendInput is ignored by InputHook, so replaying suppressed physical zero
    ; input cannot feed the Virtual00/000 detector recursively.
    SendInput(Input_ZeroPassThroughSpec(id, modifier))
    Debug_Log("Zero pass-through replay: " id " / " modifier)
}

Input_Drain() {
    global App
    while App.InputQueue.Length {
        event := App.InputQueue.RemoveAt(1)
        Input_DispatchCore(event.Id, event.Modifier, true)
    }
}

; === Numpad0 / Virtual00 / Virtual000 detector ===

Zero_New(enable00 := false, enable000 := false) {
    return {
        Active: false,
        Start: 0,
        Pattern: "",
        Downs: 0,
        Down: false,
        IgnoreUntilUp: false,
        Modifier: "Normal",
        Enable00: enable00,
        Enable000: enable000
    }
}

Zero_WindowMs(*) {
    return 80
}

Zero_IsModifierVk(vk) {
    return vk = 0x10 || vk = 0x11 || vk = 0x12
        || vk = 0xA0 || vk = 0xA1 || vk = 0xA2 || vk = 0xA3
        || vk = 0xA4 || vk = 0xA5 || vk = 0x5B || vk = 0x5C
}

Zero_ShouldIgnoreInterrupt(state, vk, modifier) {
    return state.Active && Zero_IsModifierVk(vk) && modifier = state.Modifier
}

Zero_Finish(state, virtual000 := false) {
    events := []
    if !state.Active
        return events

    if virtual000 {
        events.Push({Id: "Virtual000", Modifier: state.Modifier})
    } else if state.Downs = 2 && state.Enable00 && !state.Down && state.Pattern = "DUDU" {
        events.Push({Id: "Virtual00", Modifier: state.Modifier})
    } else {
        Loop state.Downs
            events.Push({Id: "Numpad0", Modifier: state.Modifier})
    }

    state.IgnoreUntilUp := state.Down
    state.Active := false
    state.Pattern := ""
    state.Downs := 0
    return events
}

Zero_FeedInput(state, kind, tick, modifier := "Normal", vk := 0) {
    if kind = "Interrupt" && Zero_ShouldIgnoreInterrupt(state, vk, modifier)
        return []
    return Zero_Feed(state, kind, tick, modifier)
}

Zero_Feed(state, kind, tick, modifier := "Normal") {
    events := []

    if state.Active && tick - state.Start > Zero_WindowMs(state.Modifier)
        for event in Zero_Finish(state)
            events.Push(event)

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
        return events
    }

    if kind = "U" {
        state.Down := false
        if state.IgnoreUntilUp {
            state.IgnoreUntilUp := false
            return events
        }
        if !state.Active
            return events
        state.Pattern .= "U"

        if state.Enable000 && state.Pattern = "DUDUDU" {
            for event in Zero_Finish(state, true)
                events.Push(event)
        } else if !state.Enable000 && state.Enable00 && state.Pattern = "DUDU" {
            for event in Zero_Finish(state)
                events.Push(event)
        }
    }
    return events
}

Input_StartZeroDetector() {
    global App
    if !Input_ZeroDetectorEnabled()
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
        ignored := kind = "Interrupt"
            && Zero_ShouldIgnoreInterrupt(App.ZeroDetector, vk, modifier)

        if kind = "Interrupt" && App.ZeroDetector.Active {
            Debug_Log("Zero interrupt: vk=" Format("{:02X}", vk)
                " sc=" Format("{:03X}", sc)
                " modifier=" modifier
                " ignored=" ignored
                " pattern=" App.ZeroDetector.Pattern)
        }

        for event in Zero_FeedInput(App.ZeroDetector, kind, tick, modifier, vk)
            App.InputQueue.Push(event)

        timeout := App.ZeroDetector.Active ? Zero_WindowMs(App.ZeroDetector.Modifier) : 0
        SetTimer(Zero_OnTimer, App.ZeroDetector.Active
            ? -Max(1, timeout + 1 - (A_TickCount - App.ZeroDetector.Start))
            : 0)
        if App.InputQueue.Length
            SetTimer(Input_Drain, -1)
    } catch as err {
        App.ZeroDetector := Zero_New(App.Config.EnableVirtual00, App.Config.EnableVirtual000)
        Debug_Log("Zero detector error: " err.Message)
        Notify_Info("Zero detector reset after an error")
    } finally {
        Critical("Off")
    }
}

; === Window probe / matching ===

Window_GetIdentity(hwnd) {
    if !hwnd || !DllCall("IsWindow", "ptr", hwnd, "int")
        return 0
    previous := A_DetectHiddenWindows
    try {
        DetectHiddenWindows(true)
        spec := "ahk_id " hwnd
        return {
            Hwnd: hwnd,
            Process: WinGetProcessName(spec),
            Class: WinGetClass(spec),
            Title: WinGetTitle(spec)
        }
    } catch {
        return 0
    } finally {
        DetectHiddenWindows(previous)
    }
}

Window_MatchesAllowed(candidate, action) {
    return IsObject(candidate)
        && (action.AllowedProcess = "" || StrLower(candidate.Process) = StrLower(action.AllowedProcess))
        && (action.AllowedClass = "" || StrLower(candidate.Class) = StrLower(action.AllowedClass))
        && (action.AllowedTitleContains = "" || InStr(candidate.Title, action.AllowedTitleContains, false))
}

Window_MatchesGroup(candidate, group) {
    return IsObject(candidate)
        && (group.MatchProcess = "" || StrLower(candidate.Process) = StrLower(group.MatchProcess))
        && (group.MatchClass = "" || StrLower(candidate.Class) = StrLower(group.MatchClass))
        && (group.MatchTitleContains = "" || InStr(candidate.Title, group.MatchTitleContains, false))
}

Window_IsExistingBindingValid(hwnd, action) {
    return Window_MatchesAllowed(Window_GetIdentity(hwnd), action)
}

Window_GetPrimaryWorkArea() {
    primary := MonitorGetPrimary()
    MonitorGetWorkArea(primary, &left, &top, &right, &bottom)
    MonitorGet(primary, &ml, &mt, &mr, &mb)
    return {
        X: left, Y: top, W: right - left, H: bottom - top,
        Left: ml, Top: mt, Right: mr, Bottom: mb
    }
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
        return 0
    }
}

Window_IsCandidateEligible(p) {
    return p.Visible && !p.Cloaked && !p.Owner && !p.ToolWindow
        && p.W > 0 && p.H > 0 && p.Title != ""
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

Window_GroupHasMatch(group, candidates) {
    for candidate in candidates
        if Window_MatchesGroup(candidate, group)
            return true
    return false
}

; === Binding / Clear ===

Binding_Assign(state, config, actionId, candidate) {
    action := config.Actions[actionId]
    if action.Type != "Window" || !Window_MatchesAllowed(candidate, action)
        throw Error("Manual Bind rejected: " action.Label)

    working := Runtime_Copy(state)
    for oldId, slot in working
        if slot.Hwnd = candidate.Hwnd
            working[oldId] := Runtime_Empty()
    working[actionId] := {Hwnd: candidate.Hwnd, BindingSource: "Manual", ToggleArmed: false}
    Runtime_Validate(working, config)
    return working
}

Binding_ManualBind(actionId) {
    global App
    Critical("On")
    try {
        candidate := Window_GetIdentity(WinExist("A"))
        Runtime_Commit(Binding_Assign(App.WindowState, App.Config, actionId, candidate))
        Debug_Log("Manual Bind: " actionId)
        Debug_DumpWindows()
        Notify_Info("Manual Bind: " App.Config.Actions[actionId].Label)
    } finally {
        Critical("Off")
    }
}

Binding_Clear(actionId := "", notify := true) {
    global App
    Critical("On")
    try {
        working := Runtime_Copy(App.WindowState)
        if actionId = ""
            working := Runtime_Init(App.Config)
        else if working.Has(actionId)
            working[actionId] := Runtime_Empty()
        Runtime_Commit(working)
        Debug_Log("Clear: " (actionId = "" ? "All" : actionId))
        Debug_DumpWindows()
        if notify
            Notify_Info(actionId = ""
                ? "All window bindings cleared"
                : "Binding cleared: " App.Config.Actions[actionId].Label)
    } finally {
        Critical("Off")
    }
}

; === Auto Bind ===

AutoBind_Action(actionId) {
    global App
    action := App.Config.Actions[actionId]
    if action.Type != "Window" || action.AutoBindStrategy = "None"
        return
    filterGroup := action.WindowGroup
    filterAction := filterGroup = "" ? actionId : ""
    working := AutoBind_Calculate(App.Config, App.WindowState,
        Window_EnumerateCandidates(), Window_GetPrimaryWorkArea(),
        filterGroup, filterAction)
    Runtime_Commit(working)
    Debug_DumpWindows()
}

AutoBind_Run() {
    global App
    Critical("On")
    try {
        working := AutoBind_Calculate(App.Config, App.WindowState,
            Window_EnumerateCandidates(), Window_GetPrimaryWorkArea())
        Runtime_Commit(working)
        Debug_Log("Auto Bind completed")
        Debug_DumpWindows()
    } finally {
        Critical("Off")
    }
}

AutoBind_Calculate(config, state, candidates, area, filterGroup := "", filterAction := "",
        valid := Window_IsExistingBindingValid) {
    working := Runtime_Copy(state)

    ; Invalidate only relevant bindings.
    for id, slot in working {
        action := config.Actions[id]
        selected := (filterAction = "" && filterGroup = "")
            || (filterAction != "" && StrLower(id) = StrLower(filterAction))
            || (filterGroup != "" && StrLower(action.WindowGroup) = StrLower(filterGroup))
        if selected && slot.Hwnd && !valid.Call(slot.Hwnd, action)
            working[id] := Runtime_Empty()
    }

    used := Runtime_Validate(working, config)

    for id, action in config.Actions {
        if action.Type != "Window" || action.AutoBindStrategy = "None"
            continue
        if filterAction != "" && StrLower(id) != StrLower(filterAction)
            continue
        if filterGroup != "" && StrLower(action.WindowGroup) != StrLower(filterGroup)
            continue
        if working[id].Hwnd
            continue

        best := AutoBind_SelectCandidate(action, candidates, used, area)
        if IsObject(best) {
            working[id] := {Hwnd: best.Hwnd, BindingSource: "Auto", ToggleArmed: false}
            used[best.Hwnd] := true
        }
    }

    Runtime_Validate(working, config)
    return working
}

AutoBind_SelectCandidate(action, candidates, used, area) {
    best := 0
    bestScore := 1.0e20

    Loop candidates.Length {
        index := action.AutoBindStrategy = "ReverseList"
            ? candidates.Length - A_Index + 1
            : A_Index
        candidate := candidates[index]
        if used.Has(candidate.Hwnd)
            continue
        if !Window_MatchesAllowed(candidate, action) || !Window_IsCandidateEligible(candidate)
            continue

        if action.AutoBindStrategy = "PrimaryThreePane" {
            score := AutoBind_PrimaryThreePaneScore(candidate, area, action.AutoBindOrder)
            if score < 0 || score >= bestScore
                continue
            best := candidate
            bestScore := score
        } else {
            best := candidate
            break
        }
    }
    return best
}

AutoBind_PrimaryThreePaneScore(p, area, order) {
    cx := p.X + p.W / 2, cy := p.Y + p.H / 2
    if p.MinMax != 0 || cx < area.Left || cx >= area.Right || cy < area.Top || cy >= area.Bottom
        return -1
    x := (p.X - area.X) / area.W, y := (p.Y - area.Y) / area.H
    w := p.W / area.W, h := p.H / area.H
    nx := (cx - area.X) / area.W, ny := (cy - area.Y) / area.H

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

; === Window action / Behavior ===

Window_EffectiveBehavior(behavior, toggleArmed) {
    if behavior = "ActivateThenToggle"
        return toggleArmed ? "Toggle" : "Activate"
    return behavior
}

Window_ToggleArmedAfterActivation(behavior, current, activationSucceeded) {
    if behavior = "ActivateThenToggle" && activationSucceeded
        return true
    return current
}

Window_BehaviorDecision(behavior, isActive, minMax) {
    if minMax = -1
        return "RestoreActivate"
    if behavior = "Toggle" && isActive
        return "Minimize"
    return "Activate"
}

Action_Window(actionId) {
    global App
    action := App.Config.Actions[actionId]
    slot := App.WindowState[actionId]

    if slot.Hwnd && !Window_IsExistingBindingValid(slot.Hwnd, action) {
        Binding_Clear(actionId, false)
        slot := App.WindowState[actionId]
    }

    if !slot.Hwnd && action.AutoBindStrategy != "None" {
        AutoBind_Action(actionId)
        slot := App.WindowState[actionId]
        Debug_Log("Lazy Auto Bind: " actionId)
    }

    if !slot.Hwnd {
        status := Launch_Try(actionId)
        if status = "Launched" || status = "Pending"
            Notify_Info("Launching: " action.Label)
        else
            Notify_Info("No window found: " action.Label)
        return
    }

    hwnd := slot.Hwnd
    try {
        spec := "ahk_id " hwnd
        effectiveBehavior := Window_EffectiveBehavior(action.Behavior, slot.ToggleArmed)
        decision := Window_BehaviorDecision(effectiveBehavior, !!WinActive(spec), WinGetMinMax(spec))
        if decision = "Minimize" {
            WinMinimize(spec)
            return
        }
        if decision = "RestoreActivate"
            WinRestore(spec)
        WinActivate(spec)
        activationSucceeded := !!WinWaitActive(spec, , 0.5)
        if !activationSucceeded
            throw Error("Foreground activation failed.")

        armed := Window_ToggleArmedAfterActivation(
            action.Behavior, slot.ToggleArmed, activationSucceeded)
        if armed != slot.ToggleArmed {
            working := Runtime_Copy(App.WindowState)
            if working.Has(actionId) && working[actionId].Hwnd = hwnd {
                working[actionId].ToggleArmed := armed
                Runtime_Commit(working)
                Debug_Log("ActivateThenToggle armed: " actionId)
            }
        }
    } catch as err {
        if !Window_IsExistingBindingValid(hwnd, action) && App.WindowState[actionId].Hwnd = hwnd
            Binding_Clear(actionId, false)
        Debug_Log("Window action failed: " actionId " / " err.Message)
        Notify_Info("Window action failed: " action.Label)
    }
}

; === Launch fallback ===

Launch_Decide(actionId, candidates, nowTick := -1) {
    global App
    action := App.Config.Actions[actionId]
    if action.Type != "Window" || action.WindowGroup = ""
        return "Unavailable"
    group := App.Config.WindowGroups[action.WindowGroup]
    if group.LaunchTarget = ""
        return "Unavailable"

    if Window_GroupHasMatch(group, candidates)
        return "Existing"

    if nowTick < 0
        nowTick := A_TickCount
    if App.LaunchPending.Has(group.Id) {
        pending := App.LaunchPending[group.Id]
        if nowTick < pending.Expires
            return "Pending"
        App.LaunchPending.Delete(group.Id)
    }
    return "Ready"
}

Launch_Try(actionId) {
    global App
    candidates := Window_EnumerateCandidates()
    decision := Launch_Decide(actionId, candidates)

    action := App.Config.Actions[actionId]
    if action.WindowGroup = ""
        return decision
    group := App.Config.WindowGroups[action.WindowGroup]

    if decision = "Existing" {
        if App.LaunchPending.Has(group.Id)
            App.LaunchPending.Delete(group.Id)
        Launch_SchedulePendingTimer()
        return "Existing"
    }
    if decision != "Ready"
        return decision

    try {
        Run('"' group.LaunchTarget '"' (group.LaunchArguments = "" ? "" : " " group.LaunchArguments),
            group.LaunchWorkingDirectory, , &pid)
        App.LaunchPending[group.Id] := {
            Expires: A_TickCount + group.LaunchPendingTimeoutMs,
            Pid: pid,
            ActionId: actionId
        }
        Launch_SchedulePendingTimer()
        Debug_Log("Launch fallback: " group.Id " pid=" pid)
        return "Launched"
    } catch as err {
        Debug_Log("Launch fallback failed: " group.Id " / " err.Message)
        return "Failed"
    }
}

Launch_SchedulePendingTimer() {
    global App
    SetTimer(Launch_CheckPending, App.LaunchPending.Count ? 250 : 0)
}

Launch_PendingContinuationAction(pending, config) {
    if !pending.HasProp("ActionId") || pending.ActionId = ""
        return ""
    if !config.Actions.Has(pending.ActionId)
        return ""
    action := config.Actions[pending.ActionId]
    return action.Type = "Window" && action.Behavior = "ActivateThenToggle"
        ? action.Id
        : ""
}

Launch_CheckPending() {
    global App
    if !App.LaunchPending.Count {
        SetTimer(Launch_CheckPending, 0)
        return
    }

    candidates := Window_EnumerateCandidates()
    remove := []
    continuations := []
    nowTick := A_TickCount

    for groupId, pending in App.LaunchPending {
        if !App.Config.WindowGroups.Has(groupId) {
            remove.Push(groupId)
            continue
        }

        matched := Window_GroupHasMatch(App.Config.WindowGroups[groupId], candidates)
        if matched {
            actionId := Launch_PendingContinuationAction(pending, App.Config)
            if actionId != ""
                continuations.Push(actionId)
            remove.Push(groupId)
            continue
        }

        if nowTick >= pending.Expires
            remove.Push(groupId)
    }

    for groupId in remove
        App.LaunchPending.Delete(groupId)
    if !App.LaunchPending.Count
        SetTimer(Launch_CheckPending, 0)

    ; ActivateThenToggle should complete the original key action after the
    ; asynchronously launched window appears. This keeps launch non-blocking:
    ; first key launches + activates, then later presses use Toggle behavior.
    for actionId in continuations {
        try {
            AutoBind_Action(actionId)
            if App.WindowState.Has(actionId) && App.WindowState[actionId].Hwnd {
                Debug_Log("Launch continuation: " actionId)
                Action_Window(actionId)
            } else {
                Debug_Log("Launch continuation could not bind: " actionId)
            }
        } catch as err {
            Debug_Log("Launch continuation failed: " actionId " / " err.Message)
            Notify_Info("Launch continuation failed: " App.Config.Actions[actionId].Label)
        }
    }
}

; === Actions ===

Action_Execute(actionId, fromMulti := false) {
    global App
    if !App.Config.Actions.Has(actionId)
        throw Error("Unknown Action: " actionId)
    action := App.Config.Actions[actionId]

    switch action.Type {
        case "Window":
            Action_Window(actionId)
        case "Run":
            Action_Run(action)
        case "KeySend":
            Action_KeySend(action)
        case "LayerSwitch":
            if action.Mode = "Set"
                Layer_Set(action.Layer)
            else
                Layer_Next()
        case "Delay":
            Sleep(action.Milliseconds)
        case "MultiAction":
            MultiAction_Run(actionId)
        case "Disabled":
            return
    }
}

Action_Run(action) {
    try {
        Run('"' action.Target '"' (action.Arguments = "" ? "" : " " action.Arguments),
            action.WorkingDirectory, , &pid)
        Debug_Log("Run action: " action.Id " pid=" pid)
        return pid
    } catch as err {
        Debug_Log("Run action failed: " action.Id " / " err.Message)
        Notify_Info("Run failed: " action.Label)
        return 0
    }
}

Action_KeySend(action) {
    try {
        Send(action.SendSpec)
        Debug_Log("KeySend: " action.Id " / " action.Keys)
    } catch as err {
        Debug_Log("KeySend failed: " action.Id " / " err.Message)
        Notify_Info("KeySend failed: " action.Label)
    }
}

MultiAction_Run(actionId, executor := Action_Execute) {
    global App
    action := App.Config.Actions[actionId]
    if action.Type != "MultiAction"
        throw Error("Not a MultiAction: " actionId)
    if App.MultiRunning.Has(actionId)
        return false

    App.MultiRunning[actionId] := true
    try {
        for step in action.Steps
            executor.Call(step, true)
        return true
    } finally {
        App.MultiRunning.Delete(actionId)
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

; === Debug ===

Debug_Log(text) {
    global App
    if !App.Debug.Enabled
        return
    try {
        SplitPath(App.Debug.Path, , &dir)
        DirCreate(dir)
        FileAppend(A_Now " " text "`n", App.Debug.Path, "UTF-8")
    } catch {
    }
}

Debug_DumpWindows() {
    global App
    if !App.Debug.Enabled
        return
    snapshot := "WindowState:"
    for id, slot in App.WindowState
        snapshot .= "`n" id " " slot.BindingSource " " Format("0x{:X}", slot.Hwnd)
    Debug_Log(snapshot)
}
