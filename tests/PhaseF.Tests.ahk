#Requires AutoHotkey v2.0
#Include ..\NumpadWindowController.ahk

global TestCount := 0
global TestExitCode := 0
global TestRoot := A_ScriptDir "\.."
global TestTemp := A_Temp "\NumpadWindowController-test-" DllCall("GetCurrentProcessId")
DirCreate(TestTemp)
try {
    Test_Config()
    Test_Binding()
    Test_AutoBind()
    Test_Zero()
    Test_Input()
    Test_Lazy()
    Test_Probe()
    if A_Args.Length && A_Args[1] = "--desktop"
        Test_Desktop()
    FileAppend("PASS " TestCount " assertions (AHK " A_AhkVersion ")`n", "*")
} catch as err {
    FileAppend("FAIL: " err.Message "`n" err.Stack "`n", "*")
    TestExitCode := 1
} finally {
    ; Delete only files created in this process-specific test directory.
    DirDelete(TestTemp, true)
}
ExitApp(TestExitCode)

Test_Assert(condition, name) {
    global TestCount
    if !condition
        throw Error(name)
    TestCount += 1
}

Test_Throws(callback, name) {
    caught := false
    try callback.Call()
    catch
        caught := true
    Test_Assert(caught, name)
}

Test_LoadPublic() {
    global TestRoot
    return Config_Load(TestRoot "\KeyBindings.default.ini", Config_Metadata(), TestRoot)
}

Test_LoadLegacy() {
    global TestRoot
    return Config_Load(TestRoot "\examples\KeyBindings.developer-workflow.ini", Config_Metadata(), TestRoot)
}

Test_Load() {
    return Test_LoadPublic()
}

Test_ValidateText(text) {
    global TestRoot
    return Config_Validate(Config_Parse(text, "test.ini"), "test.ini", Config_Metadata(), TestRoot)
}

Test_Config() {
    global TestRoot, TestTemp

    public := Test_LoadPublic()
    Test_Assert(public.Version = 2, "Public config uses ConfigVersion 2")
    Test_Assert(public.Keys.Count = 18, "Public config has all 18 key definitions")
    Test_Assert(public.Keys["Backspace"].Mode = "Disabled", "Backspace public default Disabled")
    Test_Assert(public.Keys["Virtual000"].Mode = "Disabled", "Virtual000 public default Disabled")
    Test_Assert(public.Keys["Numpad0"].InputStrategy = "Hotkey", "Public Numpad0 uses direct hotkey")
    Test_Assert(public.Keys["Numpad7"].AllowedProcess = "", "Public numeric slots are app agnostic")
    Test_Assert(Runtime_Init(public.Keys).Count = 16, "Public default has 16 Window slots")
    for id, key in public.Keys
        Test_Assert(!key.AutoBind, "Public default has no built-in Auto Bind " id)

    legacy := Test_LoadLegacy()
    Test_Assert(legacy.Version = 1, "Legacy developer preset uses ConfigVersion 1")
    Test_Assert(legacy.Keys["Numpad7"].AutoBind && legacy.Keys["Numpad7"].AutoBindGroup = "Chrome",
        "Legacy Chrome Auto Bind metadata preserved")
    Test_Assert(legacy.Keys["Numpad4"].AutoBindGroup = "VSCode", "Legacy VS Code metadata preserved")
    Test_Assert(legacy.Keys["Numpad0"].InputStrategy = "ZeroDetector", "Legacy zero detector preserved")
    Test_Assert(Runtime_Init(legacy.Keys).Count = 17, "Legacy Window slot count preserved")

    text := FileRead(TestRoot "\KeyBindings.default.ini", "UTF-8")
    invalid := [
        StrReplace(text, "ConfigVersion=2", "ConfigVersion=3"),
        StrReplace(text, "[General]", "[Other]"),
        text "`n[Key-NumLock]`nMode=Window`nLabel=Invalid",
        text "`n[key-numpad7]`nMode=Window",
        StrReplace(text, "ConfigVersion=2", "ConfigVersion=2`nconfigversion=2"),
        StrReplace(text, "Label=Window /", "Label=Window /`nAutoBind=true"),
        StrReplace(text, "Mode=Window", "Mode=Invalid", , , 1),
        StrReplace(text, "Label=Window /", "Label="),
        StrReplace(text, "[Key-Numpad7]", "[Key-NumpadTypo]"),
        StrReplace(text, "Mode=Disabled", "Mode=Disabled`nTarget=unused.exe", , , 1),
        text "`nMalformed line",
        RegExReplace(text, "s)\[Key-NumpadEnter\].*$", "")
    ]
    for i, input in invalid
        Test_Throws(Test_ValidateText.Bind(input), "Reject invalid public configuration " i)

    mixed := StrReplace(text, "Mode=Window", "mode=wInDoW")
    Test_Assert(Test_ValidateText(mixed).Keys["Numpad7"].Mode = "Window",
        "Case insensitive fields and modes")

    sections := Config_Parse(text, "test.ini")
    seven := sections["Key-Numpad7"]
    for field in ["AllowedProcess", "AllowedClass", "AllowedTitleContains"]
        seven.Delete(field)
    seven["Mode"] := "Shortcut"
    seven["Target"] := "cmd.exe"
    seven["Arguments"] := "/c echo public-v2"
    seven["WorkingDirectory"] := ""
    result := Config_Validate(sections, "test.ini", Config_Metadata(), TestRoot)
    Test_Assert(result.Keys["Numpad7"].Mode = "Shortcut",
        "ConfigVersion 2 allows former dedicated slot as Shortcut")

    optIn := Config_Parse(text, "test.ini")
    optIn["Key-Virtual000"]["Mode"] := "Window"
    optInResult := Config_Validate(optIn, "test.ini", Config_Metadata(), TestRoot)
    Test_Assert(optInResult.Keys["Numpad0"].InputStrategy = "ZeroDetector"
        && optInResult.Keys["Virtual000"].InputStrategy = "ZeroDetector",
        "ConfigVersion 2 Virtual000 opt-in enables Zero Detector")

    optIn["Key-Numpad0"]["Mode"] := "Disabled"
    optIn["Key-Numpad0"].Delete("AllowedProcess")
    optIn["Key-Numpad0"].Delete("AllowedClass")
    optIn["Key-Numpad0"].Delete("AllowedTitleContains")
    Test_Throws(() => Config_Validate(optIn, "test.ini", Config_Metadata(), TestRoot),
        "Virtual000 cannot remain enabled when Numpad0 is Disabled")

    legacyText := FileRead(TestRoot "\examples\KeyBindings.developer-workflow.ini", "UTF-8")
    Test_Throws(Test_ValidateText.Bind(StrReplace(StrReplace(legacyText, "`r"),
        "[Key-Numpad7]`nMode=Window", "[Key-Numpad7]`nMode=Disabled")),
        "ConfigVersion 1 still rejects disabled dedicated slot")
    Test_Throws(Test_ValidateText.Bind(StrReplace(legacyText,
        "AllowedProcess=chrome.exe", "AllowedProcess=", , , 1)),
        "ConfigVersion 1 still requires dedicated process")
    Test_Throws(Test_ValidateText.Bind(StrReplace(legacyText,
        "AllowedProcess=chrome.exe", "AllowedProcess=other.exe", , , 1)),
        "ConfigVersion 1 still requires matching Chrome group")

    sections := Config_Parse(text, "test.ini")
    shortcut := sections["Key-NumpadDiv"]
    for field in ["AllowedProcess", "AllowedClass", "AllowedTitleContains"]
        shortcut.Delete(field)
    shortcut["Mode"] := "Shortcut"
    shortcut["Target"] := "cmd.exe"
    shortcut["Arguments"] := '/c echo "test value"'
    config := Config_Validate(sections, "test.ini", Config_Metadata(), TestRoot)
    Test_Assert(FileExist(config.Keys["NumpadDiv"].ShortcutTarget), "Resolve executable via Windows search")
    Test_Assert(config.Keys["NumpadDiv"].ShortcutArguments = '/c echo "test value"', "Preserve argument quotes")
    for target in ["missing-command-example.exe", "script.ps1", "https://example.invalid", "missing.cmd"] {
        shortcut["Target"] := target
        Test_Throws(() => Config_Validate(sections, "test.ini", Config_Metadata(), TestRoot), "Reject target " target)
    }
    for ext in ["exe", "bat", "cmd", "lnk"] {
        target := TestTemp "\target with spaces." ext
        FileAppend("test", target)
        shortcut["Target"] := target
        shortcut["WorkingDirectory"] := TestTemp
        result := Config_Validate(sections, "test.ini", Config_Metadata(), TestRoot)
        Test_Assert(result.Keys["NumpadDiv"].ShortcutTarget = target, "Accept target extension " ext)
    }
    shortcut["WorkingDirectory"] := TestTemp "\missing-directory"
    Test_Throws(() => Config_Validate(sections, "test.ini", Config_Metadata(), TestRoot), "Reject missing working directory")

    generated := TestTemp "\generated-KeyBindings.ini"
    Config_EnsureUserConfig(generated, TestRoot "\KeyBindings.default.ini")
    Test_Assert(FileExist(generated), "Create user config from public default")
    generatedConfig := Config_Load(generated, Config_Metadata(), TestRoot)
    Test_Assert(generatedConfig.Version = 2, "Generated user config loads as version 2")

    utf16 := TestTemp "\legacy-utf16.ini"
    FileAppend(legacyText, utf16, "UTF-16")
    Test_Assert(Config_Load(utf16, Config_Metadata(), TestRoot).Version = 1,
        "UTF-16 legacy configuration remains supported")
    Test_Throws(() => Config_Load(TestTemp "\missing.ini", Config_Metadata(), TestRoot), "Reject missing file")
    Test_Assert(Config_Absolute("scripts\test.cmd", TestRoot) = TestRoot "\scripts\test.cmd",
        "Relative paths use script directory")
}

Test_Candidate(hwnd, process, className := "WindowClass", title := "Test Window", x := 0, y := 0, w := 300, h := 500, minmax := 0) {
    return {Hwnd: hwnd, Process: process, Class: className, Title: title,
        X: x, Y: y, W: w, H: h, MinMax: minmax,
        Visible: true, Cloaked: false, Owner: 0, ToolWindow: false}
}

Test_Binding() {
    global App
    App.Keys := Test_Load().Keys
    App.Slots := Runtime_Init(App.Keys)
    p := Test_Candidate(101, "chrome.exe")
    first := Binding_Assign(App.Slots, App.Keys, "Numpad7", p)
    Test_Assert(first["Numpad7"].BindingSource = "Manual", "Manual source")
    Test_Assert(!App.Slots["Numpad7"].Hwnd, "Manual uses isolated working state")
    moved := Binding_Assign(first, App.Keys, "Numpad0", p)
    Test_Assert(!moved["Numpad7"].Hwnd && moved["Numpad0"].Hwnd = 101, "Manual transfer clears old slot")
    App.Keys["Numpad4"].AllowedProcess := "Code.exe"
    Test_Throws(() => Binding_Assign(moved, App.Keys, "Numpad4", p), "Reject explicit AllowedProcess mismatch")
    Test_Assert(moved["Numpad0"].Hwnd = 101, "Rejection preserves old state")
    Test_Throws(() => Binding_Assign(moved, App.Keys, "Backspace", p), "Disabled cannot bind")
    invalid := Runtime_Copy(moved)
    invalid["Numpad7"] := {Hwnd: 101, BindingSource: "Auto"}
    Test_Throws(() => Runtime_Commit(invalid), "Duplicate HWND blocks commit")
    Test_Assert(!App.Slots["Numpad0"].Hwnd, "Rejected commit retains App.Slots")
    invalid["Numpad7"] := {Hwnd: 0, BindingSource: "Manual"}
    Test_Throws(() => Runtime_Validate(invalid, App.Keys), "Zero HWND needs None source")
    Runtime_Commit(moved)
    Binding_Clear("Numpad0", false)
    Test_Assert(!App.Slots["Numpad0"].Hwnd, "Slot clear does not refill")
    Runtime_Commit(first)
    Binding_Clear("", false)
    Test_Assert(Runtime_Validate(App.Slots, App.Keys).Count = 0, "Clear all")
    Test_Assert(App.Keys["Numpad7"].AllowedProcess = "", "Clear preserves public configuration")
}

Test_AutoBind() {
    keys := Test_LoadLegacy().Keys
    slots := Runtime_Init(keys)
    area := {X: 0, Y: 0, W: 1000, H: 1000, Left: 0, Top: 0, Right: 1000, Bottom: 1000}
    candidates := [Test_Candidate(11, "chrome.exe"),
        Test_Candidate(12, "chrome.exe", , , 0, 500),
        Test_Candidate(13, "chrome.exe", , , 300, 0, 700, 1000),
        Test_Candidate(14, "chrome.exe", , , 20, 0),
        Test_Candidate(24, "Code.exe"), Test_Candidate(23, "Code.exe"),
        Test_Candidate(22, "Code.exe"), Test_Candidate(21, "Code.exe"),
        Test_Candidate(31, "explorer.exe", "CabinetWClass", , , , , , -1),
        Test_Candidate(32, "explorer.exe", "CabinetWClass"),
        Test_Candidate(33, "explorer.exe", "CabinetWClass"),
        Test_Candidate(40, "ChatGPT.exe"),
        Test_Candidate(50, "WindowsTerminal.exe", "CASCADIA_HOSTING_WINDOW_CLASS", "Windows PowerShell"),
        Test_Candidate(51, "WindowsTerminal.exe", "CASCADIA_HOSTING_WINDOW_CLASS", "PowerShell 7"),
        Test_Candidate(99, "Other.exe")]
    working := AutoBind_Calculate(keys, slots, candidates, area)
    for pair in [["Numpad7", 11], ["Numpad8", 12], ["Numpad9", 13], ["Numpad4", 21], ["Numpad5", 22], ["Numpad6", 23], ["Numpad1", 32], ["Numpad2", 40], ["Numpad3", 51]]
        Test_Assert(working[pair[1]].Hwnd = pair[2], "Auto Bind result " pair[1])
    Test_Assert(Runtime_Validate(slots, keys).Count = 0, "Calculate leaves original state untouched")
    Test_Assert(Runtime_Validate(working, keys).Count = 9, "Nine unique bindings, excess candidates ignored")
    Test_Assert(!working["Numpad0"].Hwnd && !working["Virtual000"].Hwnd, "No general window autobinding")
    Test_Throws(() => AutoBind_Calculate(keys, working, candidates, area, "", (hwnd, key) => Test_ProbeFailure()), "Probe exception aborts transaction")
    Test_Assert(working["Numpad7"].Hwnd = 11, "Exception preserves original binding")
    working["Numpad7"].BindingSource := "Manual"
    working["Numpad5"] := Runtime_Empty()
    repaired := AutoBind_Calculate(keys, working, candidates, area, "", (hwnd, key) => true)
    Test_Assert(repaired["Numpad7"].BindingSource = "Manual" && repaired["Numpad7"].Hwnd = 11, "Preserve Manual")
    Test_Assert(repaired["Numpad4"].Hwnd = 21 && repaired["Numpad6"].Hwnd = 23, "Preserve Auto")
    Test_Assert(repaired["Numpad5"].Hwnd = 22, "Fill only missing VS Code slot")
    repaired := AutoBind_Calculate(keys, working, [], area, "Chrome", (hwnd, key) => false)
    Test_Assert(!repaired["Numpad7"].Hwnd && repaired["Numpad4"].Hwnd = 21, "Group invalidation leaves unrelated slots alone")
    repaired := AutoBind_Calculate(keys, working, [], area, "", (hwnd, key) => false)
    Test_Assert(Runtime_Validate(repaired, keys).Count = 0, "Invalid HWNDs become None")
    moved := Binding_Assign(working, keys, "Numpad0", candidates[1])
    repaired := AutoBind_Calculate(keys, moved, candidates, area, "", (hwnd, key) => true)
    Test_Assert(repaired["Numpad0"].Hwnd = 11 && repaired["Numpad7"].Hwnd = 14, "Used manual HWND excluded from candidates")
    for minmax in [-1, 1] {
        p := candidates[1].Clone()
        p.MinMax := minmax
        Test_Assert(AutoBind_ChromeScore(p, area, 1) = -1, "No new Chrome classification minmax " minmax)
    }
    p := candidates[1].Clone()
    p.X := -500
    Test_Assert(AutoBind_ChromeScore(p, area, 1) = -1, "Secondary monitor excluded")
    p := candidates[1].Clone()
    p.W := 450
    Test_Assert(AutoBind_ChromeScore(p, area, 1) >= 0, "Chrome inclusive width threshold")
    p.W := 451
    Test_Assert(AutoBind_ChromeScore(p, area, 1) = -1, "Chrome outside width threshold")
    for field in ["Cloaked", "ToolWindow", "Owner"] {
        p := candidates[1].Clone()
        p.%field% := 1
        Test_Assert(!Window_IsCandidateEligible(p), "Filter " field)
    }
    p := candidates[1].Clone()
    p.Visible := false
    Test_Assert(!Window_IsCandidateEligible(p), "Filter invisible")

    publicKeys := Test_LoadPublic().Keys
    publicSlots := Runtime_Init(publicKeys)
    publicResult := AutoBind_Calculate(publicKeys, publicSlots, candidates, area)
    Test_Assert(Runtime_Validate(publicResult, publicKeys).Count = 0,
        "Public ConfigVersion 2 performs no built-in Auto Bind")
}

Test_ProbeFailure() {
    throw Error("Injected probe failure")
}

Test_Zero() {
    for modifier in ["Normal", "Ctrl", "CtrlShift", "CtrlAlt", "Unsupported"] {
        state := Zero_New()
        events := []
        for i, kind in StrSplit("DUDUDU")
            for event in Zero_Feed(state, kind, 100 + (i - 1) * 10, i = 1 ? modifier : "Normal")
                events.Push(event)
        Test_Assert(events.Length = 1 && events[1].Id = "Virtual000", "Triple zero " modifier)
        Test_Assert(events[1].Modifier = modifier, "First-down modifier snapshot " modifier)
    }
    state := Zero_New()
    Zero_Feed(state, "D", 0)
    Zero_Feed(state, "U", 10)
    events := Zero_Feed(state, "Timer", 81)
    Test_Assert(events.Length = 1 && events[1].Id = "Numpad0", "Single zero timeout")
    state := Zero_New()
    Zero_Feed(state, "D", 0)
    Zero_Feed(state, "D", 30)
    events := Zero_Feed(state, "Timer", 81)
    Test_Assert(events.Length = 1 && state.IgnoreUntilUp, "Held zero generates one action")
    Test_Assert(Zero_Feed(state, "D", 100).Length = 0, "Repeat ignored")
    Zero_Feed(state, "U", 110)
    Test_Assert(!state.IgnoreUntilUp, "Release ends repeat suppression")
    state := Zero_New()
    for i, kind in StrSplit("DUDU")
        Zero_Feed(state, kind, i * 10)
    events := Zero_Feed(state, "Interrupt", 50)
    Test_Assert(events.Length = 2 && events[1].Id = "Numpad0", "Interrupted double becomes two normal presses")
    state := Zero_New()
    for i, kind in StrSplit("DUDUD")
        Zero_Feed(state, kind, (i - 1) * 10)
    events := Zero_Feed(state, "U", 80)
    Test_Assert(events.Length = 1 && events[1].Id = "Virtual000", "80ms boundary accepted")
    state := Zero_New()
    for i, kind in StrSplit("DUDUD")
        Zero_Feed(state, kind, (i - 1) * 10)
    events := Zero_Feed(state, "U", 81)
    Test_Assert(events.Length = 3 && events[1].Id = "Numpad0", "Late Up cannot become triple")
    Test_Assert(Zero_WindowMs("Normal") = 80 && Zero_WindowMs("Ctrl") = 80,
        "Zero detector keeps one 80ms window")
    Test_Assert(Zero_IsModifierVk(0x11) && Zero_IsModifierVk(0xA2)
        && Zero_IsModifierVk(0xA1) && Zero_IsModifierVk(0xA5)
        && Zero_IsModifierVk(0x5B), "Modifier VK classification")
    Test_Assert(!Zero_IsModifierVk(0x41), "Non-modifier VK classification")

    state := Zero_New()
    Zero_FeedInput(state, "D", 0, "Ctrl")
    Zero_FeedInput(state, "U", 10, "Ctrl")
    events := Zero_FeedInput(state, "Interrupt", 15, "Ctrl", 0xA2)
    Test_Assert(events.Length = 0 && state.Active && state.Pattern = "DU",
        "Repeated held Ctrl does not interrupt 000 candidate")
    Zero_FeedInput(state, "D", 20, "Ctrl")
    Zero_FeedInput(state, "U", 30, "Ctrl")
    Zero_FeedInput(state, "D", 40, "Ctrl")
    events := Zero_FeedInput(state, "U", 50, "Ctrl")
    Test_Assert(events.Length = 1 && events[1].Id = "Virtual000"
        && events[1].Modifier = "Ctrl",
        "Ctrl+000 survives held-Ctrl repeat interrupt")

    state := Zero_New()
    Zero_FeedInput(state, "D", 0, "Ctrl")
    Zero_FeedInput(state, "U", 10, "Ctrl")
    events := Zero_FeedInput(state, "Interrupt", 15, "Ctrl", 0x41)
    Test_Assert(events.Length = 1 && events[1].Id = "Numpad0" && !state.Active,
        "Non-modifier key still interrupts 000 candidate")

    state := Zero_New()
    Zero_FeedInput(state, "D", 0, "Ctrl")
    Zero_FeedInput(state, "U", 10, "Ctrl")
    events := Zero_FeedInput(state, "Interrupt", 15, "CtrlShift", 0xA0)
    Test_Assert(events.Length = 1 && !state.Active,
        "New modifier state still interrupts 000 candidate")

    state := Zero_New()
    for i, kind in StrSplit("DUDUD")
        Zero_FeedInput(state, kind, (i - 1) * 10, "Ctrl")
    events := Zero_FeedInput(state, "U", 80, "Ctrl")
    Test_Assert(events.Length = 1 && events[1].Id = "Virtual000",
        "Ctrl triple accepted at 80ms boundary")
    state := Zero_New()
    for i, kind in StrSplit("DUDUD")
        Zero_FeedInput(state, kind, (i - 1) * 10, "Ctrl")
    events := Zero_FeedInput(state, "U", 81, "Ctrl")
    Test_Assert(events.Length = 3 && events[1].Id = "Numpad0",
        "Ctrl triple rejected outside 80ms window")
    state := Zero_New()
    Zero_Feed(state, "D", 0)
    Zero_Feed(state, "U", 10)
    events := Zero_Feed(state, "D", 90)
    Test_Assert(events.Length = 1 && state.Active && state.Start = 90, "Delayed timer flushes before next sequence")
}

Test_Input() {
    global App, TestTemp
    keys := Test_LoadPublic().Keys
    keys["NumpadDiv"].Mode := "Shortcut"
    plan := Input_HotkeyPlan(keys)
    counts := Map()
    for entry in plan
        counts[entry.Id] := counts.Get(entry.Id, 0) + 1
    Test_Assert(counts["Numpad7"] = 4, "Public Window registers four actions")
    Test_Assert(counts["NumpadDiv"] = 1, "Shortcut registers Normal only")
    Test_Assert(!counts.Has("Backspace"), "Disabled Backspace registers no hotkeys")
    Test_Assert(counts["Numpad0"] = 4, "Public Numpad0 uses direct hotkeys")
    Test_Assert(!counts.Has("Virtual000"), "Public Virtual000 is disabled")
    Test_Assert(counts["NumpadEnter"] = 2,
        "NumpadEnter generic plan keeps Normal and CtrlAlt only")

    legacyKeys := Test_LoadLegacy().Keys
    legacyPlan := Input_HotkeyPlan(legacyKeys)
    legacyCounts := Map()
    for entry in legacyPlan
        legacyCounts[entry.Id] := legacyCounts.Get(entry.Id, 0) + 1
    Test_Assert(!legacyCounts.Has("Numpad0") && !legacyCounts.Has("Virtual000"),
        "Legacy zero input remains detector-only")

    globalPlan := Input_GlobalHotkeyPlan()
    Test_Assert(globalPlan.Length = 2, "NumpadEnter has two reserved global actions")
    Test_Assert(globalPlan[1].Action = "AutoBindAll"
        && globalPlan[1].Key = "SC11C" && globalPlan[1].Modifier = "Ctrl",
        "Ctrl NumpadEnter routes to Auto Bind All")
    Test_Assert(globalPlan[2].Action = "ClearAll"
        && globalPlan[2].Key = "SC11C" && globalPlan[2].Modifier = "CtrlShift",
        "Ctrl Shift NumpadEnter routes to Clear All")
    Test_Assert(globalPlan[1].Key != "SC01C" && globalPlan[2].Key != "SC01C",
        "Standard Enter SC01C is not a Global Action key")

    keys["NumpadEnter"].Mode := "Disabled"
    disabledEnterPlan := Input_HotkeyPlan(keys)
    hasGenericEnter := false
    for entry in disabledEnterPlan
        if entry.Id = "NumpadEnter"
            hasGenericEnter := true
    Test_Assert(!hasGenericEnter, "Disabled NumpadEnter has no generic hotkeys")
    Test_Assert(Input_GlobalHotkeyPlan().Length = 2,
        "NumpadEnter Global Actions remain reserved regardless of Config Mode")

    App := App_Create()
    App.Keys := Test_LoadPublic().Keys
    App.Slots := Runtime_Init(App.Keys)
    Input_StartZeroDetector()
    Test_Assert(!IsObject(App.Hook), "Public default does not start Zero Detector")

    Test_Assert(Input_ModifierKind(1, 1, 1) = "Unsupported", "Reject Ctrl Shift Alt")
    Test_Assert(Input_ModifierKind(0, 1, 0) = "Unsupported", "Shift alone passes through")
    Test_Assert(Input_ModifierKind(1, 1, 0) = "CtrlShift", "Ctrl Shift mapping")
    App.Debug := {Enabled: true, Path: TestTemp "\invalid<>\log.txt"}
    Debug_Log("Expected IO failure")
    Test_Assert(true, "Debug IO failure contained")
    App.Debug.Enabled := false
    App.Debug.Path := TestTemp "\should-not-exist.log"
    Debug_Log("Disabled")
    Test_Assert(!FileExist(App.Debug.Path), "Default logging writes nothing")
}

Test_Probe() {
    window := Gui(, "NWC probe fixture")
    try {
        p := Window_GetIdentity(window.Hwnd)
        Test_Assert(IsObject(p) && p.Title = "NWC probe fixture", "Live HWND identity/title")
        Test_Assert(p.Process != "" && p.Class = "AutoHotkeyGUI", "Live process/class")
        Test_Assert(!IsObject(Window_GetIdentity(0)), "Invalid HWND")
        Test_Assert(!IsObject(Window_GetCandidate(window.Hwnd)), "Hidden fixture excluded")
        candidates := Window_EnumerateCandidates()
        Test_Assert(candidates is Array, "Live candidate enumeration")
        area := Window_GetPrimaryWorkArea()
        Test_Assert(area.W > 0 && area.H > 0, "Live primary work area")
    } finally {
        window.Destroy()
    }
}

Test_Lazy() {
    global App
    App := App_Create()
    App.Keys := Test_LoadLegacy().Keys
    App.Slots := Runtime_Init(App.Keys)
    App.Keys["Numpad1"].AllowedProcess := "NWC-nonexistent-fixture.exe"
    App.Slots["Numpad1"] := {Hwnd: -1, BindingSource: "Manual"}
    App.Slots["Numpad4"] := {Hwnd: -2, BindingSource: "Auto"}
    Action_ActivateWindow("Numpad1")
    Test_Assert(App.Slots["Numpad1"].BindingSource = "None", "Lazy miss clears invalid binding")
    Test_Assert(App.Slots["Numpad4"].Hwnd = -2, "Lazy single slot leaves unrelated slots intact")
    App.Slots["Numpad0"] := {Hwnd: -1, BindingSource: "Manual"}
    Action_ActivateWindow("Numpad0")
    Test_Assert(!App.Slots["Numpad0"].Hwnd, "Manual-only slot becomes empty without Auto Bind")
    before := App.Slots
    Input_Dispatch("Backspace", "Normal")
    Test_Assert(App.Slots = before, "Disabled dispatcher does nothing")
    App.Keys["Numpad0"].Mode := "Disabled"
    App.Keys["Virtual000"].Mode := "Disabled"
    Input_StartZeroDetector()
    Test_Assert(!IsObject(App.Hook), "Both zero keys disabled means no InputHook")
    ; Recreate consistent configuration before checking Global Actions.
    App.Keys := Test_LoadLegacy().Keys
    App.Slots := Runtime_Init(App.Keys)
    Input_GlobalDispatch("AutoBindAll")
    Test_Assert(Runtime_Validate(App.Slots, App.Keys) is Map,
        "Ctrl NumpadEnter Global Action routes to Auto Bind All")
    App.Slots["Numpad0"] := {Hwnd: 0x12345, BindingSource: "Manual"}
    Input_GlobalDispatch("ClearAll")
    Test_Assert(Runtime_Validate(App.Slots, App.Keys).Count = 0
        && !App.Slots["Numpad0"].Hwnd,
        "Ctrl Shift NumpadEnter Global Action routes to Clear All")
    SetTimer(Notify_Clear, 0)
    Notify_Clear()
}

Test_Desktop() {
    global App
    original := GetKeyState("NumLock", "T")
    foreground := WinExist("A")
    window := Gui(, "NWC activation fixture")
    try {
        App := App_Create()
        App.Keys := Test_LoadLegacy().Keys
        App.Slots := Runtime_Init(App.Keys)
        App.OriginalNumLock := original
        App.NumLockSaved := true
        OnExit(App_OnExit)
        NumLock_ForceOn()
        Test_Assert(GetKeyState("NumLock", "T"), "NumLock forced on and verified")
        Input_RegisterHotkeys()
        Input_StartZeroDetector()
        Test_Assert(App.Hook.InProgress, "InputHook starts")
        AutoBind_Run()
        Test_Assert(Runtime_Validate(App.Slots, App.Keys) is Map, "Live Auto Bind transaction")
        window.Show("w240 h80 NoActivate")
        hwnd := window.Hwnd
        App.Slots["Numpad0"] := {Hwnd: hwnd, BindingSource: "Manual"}
        WinMinimize("ahk_id " hwnd)
        Action_ActivateWindow("Numpad0")
        Test_Assert(WinGetMinMax("ahk_id " hwnd) != -1, "Restore own fixture")
        if WinActive("ahk_id " hwnd) {
            Test_Assert(true, "Activate own fixture")
            Binding_ManualBind("NumpadDot")
            Test_Assert(App.Slots["NumpadDot"].Hwnd = hwnd && !App.Slots["Numpad0"].Hwnd, "Live active-window manual transfer")
        } else {
            FileAppend("PENDING: foreground activation / active-window manual binding (desktop did not grant foreground).`n", "*")
            Test_Assert(App.Slots["Numpad0"].Hwnd = hwnd, "Activation failure retains valid binding and continues")
        }
        App_OnExit()
        Test_Assert(!App.Hook.InProgress, "InputHook stops")
        Test_Assert(GetKeyState("NumLock", "T") = original, "NumLock restored")
        for saved in [false, true] {
            App.OriginalNumLock := saved
            SetNumLockState(saved ? "On" : "Off")
            Sleep(30)
            if GetKeyState("NumLock", "T") != saved {
                FileAppend("PENDING: NumLock " saved " restoration (environment does not allow setting initial toggle).`n", "*")
                continue
            }
            NumLock_ForceOn()
            App_OnExit()
            Sleep(30)
            Test_Assert(GetKeyState("NumLock", "T") = saved, "Restore saved NumLock " saved)
        }
        App.OriginalNumLock := original
        Test_Shortcuts()
    } finally {
        App_OnExit()
        window.Destroy()
        if foreground && WinExist("ahk_id " foreground)
            try WinActivate("ahk_id " foreground)
        SetNumLockState(original ? "On" : "Off")
    }
}

Test_Shortcuts() {
    global App, TestTemp
    key := App.Keys["NumpadDiv"].Clone()
    key.Mode := "Shortcut"
    key.ShortcutWorkingDirectory := TestTemp
    App.Keys["NumpadDiv"] := key
    App.Slots := Runtime_Init(App.Keys)
    marker := TestTemp "\shortcut-result.txt"
    helper := TestTemp "\shortcut helper.ahk"
    FileAppend('#Requires AutoHotkey v2.0`nFileAppend(A_WorkingDir "|" A_Args[1], A_ScriptDir "\shortcut-result.txt")`nExitApp()', helper, "UTF-8")
    for extension in ["exe", "bat", "cmd", "lnk"] {
        if FileExist(marker)
            FileDelete(marker)
        if extension = "exe" {
            key.ShortcutTarget := A_AhkPath
            key.ShortcutArguments := '"' helper '" "argument with spaces"'
        } else if extension = "lnk" {
            link := TestTemp "\shortcut test.lnk"
            FileCreateShortcut(A_AhkPath, link, TestTemp, '"' helper '" "argument with spaces"')
            key.ShortcutTarget := link
            key.ShortcutArguments := ""
        } else {
            batch := TestTemp "\shortcut test." extension
            FileAppend('@echo off`r`necho %CD%^|%~1>"' marker '"`r`n', batch)
            key.ShortcutTarget := batch
            key.ShortcutArguments := '"argument with spaces"'
        }
        Action_RunShortcut("NumpadDiv")
        deadline := A_TickCount + 3000
        while !FileExist(marker) && A_TickCount < deadline
            Sleep(20)
        Test_Assert(FileExist(marker), "Shortcut launched " extension)
        Test_Assert(Trim(FileRead(marker), "`r`n") = TestTemp "|argument with spaces", "Shortcut args and working directory " extension)
    }
    key.ShortcutTarget := TestTemp "\does-not-exist.exe"
    Test_Assert(Action_RunShortcut("NumpadDiv") = 0, "Runtime shortcut failure is recoverable")
}
