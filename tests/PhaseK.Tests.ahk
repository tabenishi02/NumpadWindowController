#Requires AutoHotkey v2.0
#Include ..\NumpadWindowController.ahk

global TestCount := 0
global TestExitCode := 0
global TestRoot := A_ScriptDir "\.."
global TestTemp := A_Temp "\NumpadWindowController-phase-k-test-" DllCall("GetCurrentProcessId")
DirCreate(TestTemp)

try {
    Test_Config()
    Test_KeySend()
    Test_Layer()
    Test_Binding()
    Test_AutoBind()
    Test_Zero()
    Test_Input()
    Test_MultiAction()
    Test_Launch()
    Test_WindowBehavior()
    Test_ActivateThenToggle()
    Test_Probe()
    FileAppend("PASS " TestCount " assertions (AHK " A_AhkVersion ")`n", "*")
} catch as err {
    FileAppend("FAIL: " err.Message "`n" err.Stack "`n", "*")
    TestExitCode := 1
} finally {
    SetTimer(Notify_Clear, 0)
    SetTimer(Launch_CheckPending, 0)
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

Test_LoadDeveloper() {
    global TestRoot
    return Config_Load(TestRoot "\examples\KeyBindings.developer-workflow.ini", Config_Metadata(), TestRoot)
}

Test_LoadExample() {
    global TestRoot
    return Config_Load(TestRoot "\examples\KeyBindings.example.ini", Config_Metadata(), TestRoot)
}

Test_LoadPhysicalAcceptance() {
    global TestRoot
    return Config_Load(TestRoot "\examples\KeyBindings.phase-k-test.ini", Config_Metadata(), TestRoot)
}

Test_ValidateText(text) {
    global TestRoot
    return Config_Validate(Config_Parse(text, "test.ini"), "test.ini", Config_Metadata(), TestRoot)
}

Test_Config() {
    global TestRoot, TestTemp

    config := Test_LoadPublic()
    Test_Assert(config.Version = 3, "Public config uses ConfigVersion 3")
    Test_Assert(config.LayerOrder.Length = 3, "Public config has Base/Edit/Media layers")
    Test_Assert(config.DefaultLayer = "Base", "Public default layer is Base")
    Test_Assert(!config.EnableVirtual00 && !config.EnableVirtual000, "Virtual00/000 are opt-in")
    Test_Assert(Config_Metadata().Count = 19, "Metadata includes Virtual00")
    Test_Assert(config.GlobalKeys["NumpadAdd"] = "LayerNext", "Global layer switch mapping")
    Test_Assert(config.Actions["Window7"].Type = "Window", "Window Action parsed")
    Test_Assert(config.Actions["Copy"].Type = "KeySend", "KeySend Action parsed")
    Test_Assert(config.Actions["LayerNext"].Type = "LayerSwitch", "LayerSwitch Action parsed")
    Test_Assert(!Config_KeyIsControllerMapped(config, "Backspace"), "Backspace passes through by default")
    Test_Assert(Runtime_Init(config).Count = 15, "Public Window Action runtime state count")

    developer := Test_LoadDeveloper()
    Test_Assert(developer.Version = 3, "Developer workflow migrated to ConfigVersion 3")
    Test_Assert(developer.EnableVirtual000 && !developer.EnableVirtual00, "Developer workflow keeps Virtual000")
    Test_Assert(developer.Actions["Chrome1"].AutoBindStrategy = "PrimaryThreePane", "Chrome strategy migrated")
    Test_Assert(developer.Actions["VSCode1"].AutoBindStrategy = "ReverseList", "VS Code strategy migrated")

    example := Test_LoadExample()
    Test_Assert(example.EnableVirtual00 && example.EnableVirtual000, "Example enables 00 and 000")
    Test_Assert(example.Actions["CopyToNotepad"].Type = "MultiAction", "MultiAction example loads")
    Test_Assert(example.WindowGroups["Notepad"].LaunchTarget != "", "Launch fallback target resolves")

    physicalText := StrReplace(
        FileRead(TestRoot "\examples\KeyBindings.phase-k-test.ini", "UTF-8"), "`r", "")
    Test_Assert(InStr(physicalText,
        "[Action-Explorer]`nType=Window`nLabel=Explorer`nBehavior=ActivateThenToggle"),
        "Physical acceptance Explorer uses ActivateThenToggle")
    Test_Assert(InStr(physicalText,
        "[Action-ChatGPT]`nType=Window`nLabel=ChatGPT Desktop`nBehavior=ActivateThenToggle"),
        "Physical acceptance ChatGPT uses ActivateThenToggle")
    Test_Assert(InStr(physicalText,
        "[Action-PowerShell7]`nType=Window`nLabel=PowerShell 7`nBehavior=ActivateThenToggle"),
        "Physical acceptance PowerShell 7 uses ActivateThenToggle")

    physical := Test_LoadPhysicalAcceptance()
    Test_Assert(physical.Version = 3, "Physical acceptance config uses ConfigVersion 3")
    Test_Assert(physical.Actions["Explorer"].Behavior = "ActivateThenToggle",
        "ATT-01 Explorer ActivateThenToggle accepted")
    Test_Assert(physical.Actions["ChatGPT"].Behavior = "ActivateThenToggle",
        "ATT-01 ChatGPT ActivateThenToggle accepted")
    Test_Assert(physical.Actions["PowerShell7"].Behavior = "ActivateThenToggle",
        "ATT-01 PowerShell 7 ActivateThenToggle accepted")
    Test_Assert(physical.LayerOrder.Length = 4, "Physical acceptance config has four test layers")
    Test_Assert(physical.DefaultLayer = "Window", "Physical acceptance default layer is Window")
    Test_Assert(!physical.EnableVirtual00 && physical.EnableVirtual000,
        "Physical acceptance config matches available 000 hardware")
    Test_Assert(physical.Actions["Chrome1"].AutoBindStrategy = "PrimaryThreePane",
        "Physical acceptance config covers Chrome auto bind")
    Test_Assert(physical.Actions["CopyToNotepad"].Type = "MultiAction",
        "Physical acceptance config covers MultiAction")
    Test_Assert(physical.WindowGroups["Notepad"].LaunchTarget != "",
        "Physical acceptance config covers launch fallback")
    Test_Assert(physical.WindowGroups["Explorer"].LaunchTarget != "",
        "ActivateThenToggle Explorer has launch fallback")
    Test_Assert(physical.WindowGroups["ChatGPT"].LaunchTarget != "",
        "ActivateThenToggle ChatGPT has launch fallback")
    Test_Assert(InStr(physical.WindowGroups["ChatGPT"].LaunchArguments, "shell:AppsFolder\"),
        "ActivateThenToggle ChatGPT uses AppsFolder launch")
    Test_Assert(physical.WindowGroups["PowerShell"].LaunchTarget != "",
        "ActivateThenToggle PowerShell 7 has launch fallback")
    Test_Assert(InStr(StrLower(physical.WindowGroups["PowerShell"].LaunchTarget), "wt.exe"),
        "ActivateThenToggle PowerShell 7 launches via Windows Terminal")
    Test_Assert(InStr(physical.WindowGroups["PowerShell"].LaunchArguments, "-w new"),
        "PowerShell launch forces a new Windows Terminal window")
    Test_Assert(InStr(physical.WindowGroups["PowerShell"].LaunchArguments, "--title ""PowerShell 7"""),
        "PowerShell launch sets the matching Window title")
    Test_Assert(InStr(physical.WindowGroups["PowerShell"].LaunchArguments, "pwsh.exe"),
        "PowerShell launch starts pwsh.exe inside Windows Terminal")
    Test_Assert(!Config_KeyIsControllerMapped(physical, "Backspace"),
        "Physical acceptance config keeps Backspace native")

    lowerBehaviorText := StrReplace(physicalText,
        "Behavior=ActivateThenToggle", "Behavior=activatethentoggle", , , 1)
    lowerBehaviorConfig := Test_ValidateText(lowerBehaviorText)
    Test_Assert(lowerBehaviorConfig.Actions["Explorer"].Behavior = "ActivateThenToggle",
        "ATT-01 ActivateThenToggle is case-normalized")
    Test_Throws(Test_ValidateText.Bind(StrReplace(physicalText,
        "Behavior=ActivateThenToggle", "Behavior=UnknownBehavior", , , 1)),
        "ATT-01 unknown Window behavior rejected")

    text := FileRead(TestRoot "\KeyBindings.default.ini", "UTF-8")
    Test_Throws(Test_ValidateText.Bind(StrReplace(text, "ConfigVersion=3", "ConfigVersion=2")),
        "ConfigVersion 2 rejected")
    Test_Throws(Test_ValidateText.Bind(StrReplace(text, "ConfigVersion=3", "ConfigVersion=1")),
        "ConfigVersion 1 rejected")
    Test_Throws(Test_ValidateText.Bind(StrReplace(text, "Numpad7=Window7", "Numpad7=MissingAction", , , 1)),
        "Unknown Action reference rejected")
    Test_Throws(Test_ValidateText.Bind(StrReplace(text, "NumpadAdd=LayerNext", "", , , 1)),
        "Multiple layers require global LayerSwitch")
    Test_Throws(Test_ValidateText.Bind(StrReplace(text, "Keys=Ctrl+C", "Keys=Ctrl+NoSuchKey", , , 1)),
        "Invalid KeySend rejected")
    Test_Throws(Test_ValidateText.Bind(text "`n[Unknown]`nA=B`n"),
        "Unknown section rejected")

    exampleText := FileRead(TestRoot "\examples\KeyBindings.example.ini", "UTF-8")
    Test_Throws(Test_ValidateText.Bind(StrReplace(exampleText,
        "Step2=Delay100", "Step2=CopyToNotepad", , , 1)),
        "Nested/self MultiAction rejected")
    Test_Throws(Test_ValidateText.Bind(StrReplace(exampleText,
        "Step2=Delay100", "Step5=Delay100", , , 1)),
        "MultiAction step gap rejected")
    Test_Throws(Test_ValidateText.Bind(StrReplace(exampleText,
        "MatchProcess=notepad.exe", "MatchProcess=", , , 1)),
        "WindowGroup requires identity")

    generated := TestTemp "\generated-KeyBindings.ini"
    Config_EnsureUserConfig(generated, TestRoot "\KeyBindings.default.ini")
    Test_Assert(FileExist(generated), "User config generated")
    Test_Assert(Config_Load(generated, Config_Metadata(), TestRoot).Version = 3,
        "Generated config loads as version 3")
    existing := FileRead(generated, "UTF-8")
    Config_EnsureUserConfig(generated, TestRoot "\examples\KeyBindings.example.ini")
    Test_Assert(FileRead(generated, "UTF-8") = existing, "Existing user config is not overwritten")

    utf16 := TestTemp "\utf16.ini"
    FileAppend(text, utf16, "UTF-16")
    Test_Throws(() => Config_Load(utf16, Config_Metadata(), TestRoot),
        "UTF-16 configuration rejected")
}

Test_KeySend() {
    Test_Assert(KeySend_Compile("Ctrl+C") = "^c", "Compile Ctrl+C")
    Test_Assert(KeySend_Compile("Win+Shift+S") = "+#s", "Compile Win+Shift+S")
    Test_Assert(KeySend_Compile("Alt+F4") = "!{F4}", "Compile Alt+F4")
    Test_Assert(KeySend_Compile("Volume_Up") = "{Volume_Up}", "Compile Volume Up")
    Test_Assert(KeySend_Compile("Media_Play_Pause") = "{Media_Play_Pause}", "Compile media key")
    Test_Assert(KeySend_Compile("Ctrl+PageDown") = "^{PageDown}", "Compile navigation key")
    Test_Throws(() => KeySend_Compile("Ctrl"), "Reject modifier-only KeySend")
    Test_Throws(() => KeySend_Compile("A+B"), "Reject two non-modifier keys")
    Test_Throws(() => KeySend_Compile("Ctrl+UnknownKey"), "Reject unknown KeySend key")
    Test_Throws(() => KeySend_Compile("Ctrl+Ctrl+C"), "Reject duplicate modifier")
}

Test_Layer() {
    global App
    App := App_Create()
    App.Config := Test_LoadPublic()
    App.Metadata := Config_Metadata()
    App.ActiveLayer := App.Config.DefaultLayer
    App.WindowState := Runtime_Init(App.Config)

    Test_Assert(Action_IdForKey("Numpad7") = "Window7", "Base mapping resolves")
    Test_Assert(Action_IdForKey("NumpadAdd") = "LayerNext", "Global mapping resolves before layer")
    Test_Assert(Layer_Next(false) = "Edit", "Layer Next Base -> Edit")
    Test_Assert(Action_IdForKey("Numpad7") = "Undo", "Edit mapping resolves")
    Test_Assert(Layer_Next(false) = "Media", "Layer Next Edit -> Media")
    Test_Assert(Action_IdForKey("Numpad8") = "MediaPlayPause", "Media mapping resolves")
    Test_Assert(Layer_Next(false) = "Base", "Layer Next wraps")
    Layer_Set("Edit", false)
    Test_Assert(App.ActiveLayer = "Edit", "Layer Set")
    Test_Throws(() => Layer_Set("Missing", false), "Unknown layer rejected")
}

Test_Candidate(hwnd, process, className := "WindowClass", title := "Test Window",
        x := 0, y := 0, w := 300, h := 500, minmax := 0) {
    return {
        Hwnd: hwnd, Process: process, Class: className, Title: title,
        X: x, Y: y, W: w, H: h, MinMax: minmax,
        Visible: true, Cloaked: false, Owner: 0, ToolWindow: false
    }
}

Test_Binding() {
    global App
    App := App_Create()
    App.Config := Test_LoadPublic()
    App.Metadata := Config_Metadata()
    App.ActiveLayer := "Base"
    App.WindowState := Runtime_Init(App.Config)

    p := Test_Candidate(101, "test.exe")
    first := Binding_Assign(App.WindowState, App.Config, "Window7", p)
    Test_Assert(first["Window7"].BindingSource = "Manual", "Manual binding source")
    Test_Assert(!App.WindowState["Window7"].Hwnd, "Binding uses isolated working state")

    moved := Binding_Assign(first, App.Config, "Window0", p)
    Test_Assert(!moved["Window7"].Hwnd && moved["Window0"].Hwnd = 101,
        "One HWND moves between Window Actions")

    invalid := Runtime_Copy(moved)
    invalid["Window7"] := {Hwnd: 101, BindingSource: "Auto", ToggleArmed: false}
    Test_Throws(() => Runtime_Validate(invalid, App.Config), "Duplicate HWND rejected")

    Runtime_Commit(moved)
    Binding_Clear("Window0", false)
    Test_Assert(!App.WindowState["Window0"].Hwnd, "Binding clear")
    Binding_Clear("", false)
    Test_Assert(Runtime_Validate(App.WindowState, App.Config).Count = 0, "Clear all bindings")
}

Test_AutoBind() {
    config := Test_LoadDeveloper()
    state := Runtime_Init(config)
    area := {X: 0, Y: 0, W: 1000, H: 1000, Left: 0, Top: 0, Right: 1000, Bottom: 1000}
    candidates := [
        Test_Candidate(11, "chrome.exe", , , 0, 0, 300, 500),
        Test_Candidate(12, "chrome.exe", , , 0, 500, 300, 500),
        Test_Candidate(13, "chrome.exe", , , 300, 0, 700, 1000),
        Test_Candidate(14, "chrome.exe", , , 20, 0, 300, 500),
        Test_Candidate(24, "Code.exe"),
        Test_Candidate(23, "Code.exe"),
        Test_Candidate(22, "Code.exe"),
        Test_Candidate(21, "Code.exe"),
        Test_Candidate(32, "explorer.exe", "CabinetWClass"),
        Test_Candidate(31, "explorer.exe", "CabinetWClass", , , , , , -1),
        Test_Candidate(40, "ChatGPT.exe"),
        Test_Candidate(50, "WindowsTerminal.exe", "CASCADIA_HOSTING_WINDOW_CLASS", "Windows PowerShell"),
        Test_Candidate(51, "WindowsTerminal.exe", "CASCADIA_HOSTING_WINDOW_CLASS", "PowerShell 7"),
        Test_Candidate(99, "Other.exe")
    ]

    working := AutoBind_Calculate(config, state, candidates, area)
    expected := Map(
        "Chrome1", 11, "Chrome2", 12, "Chrome3", 13,
        "VSCode1", 21, "VSCode2", 22, "VSCode3", 23,
        "Explorer", 32, "ChatGPT", 40, "PowerShell7", 51)
    for id, hwnd in expected
        Test_Assert(working[id].Hwnd = hwnd, "Auto Bind " id)

    Test_Assert(Runtime_Validate(state, config).Count = 0, "Auto Bind leaves source state untouched")
    Test_Assert(Runtime_Validate(working, config).Count = 9, "Nine unique auto bindings")
    Test_Assert(!working["Window0"].Hwnd, "Manual-only Action not auto bound")

    chromeOnly := AutoBind_Calculate(config, state, candidates, area, "Chrome")
    Test_Assert(chromeOnly["Chrome1"].Hwnd = 11 && !chromeOnly["VSCode1"].Hwnd,
        "Group-scoped Auto Bind")

    Test_Assert(Window_GroupHasMatch(config.WindowGroups["Chrome"], candidates),
        "WindowGroup MatchProcess")
    Test_Assert(!Window_GroupHasMatch(config.WindowGroups["Chrome"],
        [Test_Candidate(200, "other.exe")]), "WindowGroup mismatch")

    p := candidates[1].Clone()
    p.MinMax := -1
    Test_Assert(AutoBind_PrimaryThreePaneScore(p, area, 1) = -1,
        "PrimaryThreePane excludes minimized")
}

Test_Collect(state, sequence, times, modifier := "Normal") {
    events := []
    for i, kind in StrSplit(sequence)
        for event in Zero_Feed(state, kind, times[i], modifier)
            events.Push(event)
    return events
}

Test_Zero() {
    state := Zero_New(true, false)
    events := Test_Collect(state, "DUDU", [0, 10, 20, 30])
    Test_Assert(events.Length = 1 && events[1].Id = "Virtual00",
        "Virtual00-only resolves on second Up")

    state := Zero_New(true, true)
    events := Test_Collect(state, "DUDU", [0, 10, 20, 30])
    Test_Assert(events.Length = 0 && state.Active, "Virtual000 keeps double pending")
    events := Zero_Feed(state, "Timer", 81)
    Test_Assert(events.Length = 1 && events[1].Id = "Virtual00",
        "Double resolves to Virtual00 at timeout")

    state := Zero_New(false, true)
    Test_Collect(state, "DUDU", [0, 10, 20, 30])
    events := Zero_Feed(state, "Timer", 81)
    Test_Assert(events.Length = 2 && events[1].Id = "Numpad0",
        "Virtual000-only double becomes two normal zeros")

    state := Zero_New(true, true)
    events := Test_Collect(state, "DUDUDU", [0, 10, 20, 30, 40, 50], "Ctrl")
    Test_Assert(events.Length = 1 && events[1].Id = "Virtual000",
        "Triple resolves to Virtual000")
    Test_Assert(events[1].Modifier = "Ctrl", "Zero detector snapshots modifier")

    state := Zero_New(true, true)
    Test_Collect(state, "DUDU", [0, 10, 20, 30])
    events := Zero_Feed(state, "Interrupt", 40)
    Test_Assert(events.Length = 1 && events[1].Id = "Virtual00",
        "Interrupt flushes pending double")

    state := Zero_New(true, true)
    Zero_Feed(state, "D", 0)
    Zero_Feed(state, "D", 30)
    events := Zero_Feed(state, "Timer", 81)
    Test_Assert(events.Length = 1 && events[1].Id = "Numpad0" && state.IgnoreUntilUp,
        "Repeat/long press emits one normal zero")
    Zero_Feed(state, "U", 90)
    Test_Assert(!state.IgnoreUntilUp, "Release clears repeat suppression")

    state := Zero_New(false, true)
    events := Test_Collect(state, "DUDUDU", [0, 10, 20, 30, 40, 80])
    Test_Assert(events.Length = 1 && events[1].Id = "Virtual000", "80ms boundary accepted")

    state := Zero_New(false, true)
    events := Test_Collect(state, "DUDUDU", [0, 10, 20, 30, 40, 81])
    Test_Assert(events.Length = 3 && events[1].Id = "Numpad0", "Late triple rejected")

    state := Zero_New(false, true)
    Zero_FeedInput(state, "D", 0, "Ctrl")
    Zero_FeedInput(state, "U", 10, "Ctrl")
    events := Zero_FeedInput(state, "Interrupt", 15, "Ctrl", 0xA2)
    Test_Assert(events.Length = 0 && state.Active, "Held Ctrl repeat does not interrupt")
    events := Zero_FeedInput(state, "Interrupt", 16, "Ctrl", 0x41)
    Test_Assert(events.Length = 1 && !state.Active, "Non-modifier interrupt flushes")
}

Test_Input() {
    global App
    App := App_Create()
    App.Config := Test_LoadPublic()
    App.Metadata := Config_Metadata()
    App.ActiveLayer := "Base"
    App.WindowState := Runtime_Init(App.Config)

    plan := Input_HotkeyPlan(App.Metadata, false)
    counts := Map()
    for entry in plan
        counts[entry.Id] := counts.Get(entry.Id, 0) + 1
    Test_Assert(counts["Numpad0"] = 4, "Numpad0 direct hotkeys when virtual detector off")
    Test_Assert(!counts.Has("Virtual00") && !counts.Has("Virtual000"),
        "Virtual logical keys have no physical hotkeys")
    Test_Assert(counts["NumpadEnter"] = 2, "Reserved Enter modifier combinations excluded")

    Test_Assert(Input_ShouldCapture("Numpad7", "Normal"), "Base Window normal captured")
    Test_Assert(Input_ShouldCapture("Numpad7", "Ctrl"), "Base Window management captured")
    Test_Assert(!Input_ShouldCapture("Backspace", "Normal"), "Unmapped Backspace passes through")

    Layer_Set("Edit", false)
    Test_Assert(Input_ShouldCapture("Numpad7", "Normal"), "Edit KeySend captured")
    Test_Assert(!Input_ShouldCapture("Numpad7", "Ctrl"), "Ctrl+KeySend passes through")
    Test_Assert(Input_ShouldCapture("NumpadAdd", "Normal"), "Global LayerSwitch captured")
    Test_Assert(!Input_ShouldCapture("NumpadAdd", "Ctrl"), "Ctrl+LayerSwitch passes through")

    App.Config := Test_LoadExample()
    App.ActiveLayer := App.Config.DefaultLayer
    plan := Input_HotkeyPlan(App.Metadata, true)
    counts := Map()
    for entry in plan
        counts[entry.Id] := counts.Get(entry.Id, 0) + 1
    Test_Assert(!counts.Has("Numpad0"), "Numpad0 direct hotkey removed when zero detector enabled")

    globalPlan := Input_GlobalHotkeyPlan()
    Test_Assert(globalPlan.Length = 2, "Two reserved global commands")
    Test_Assert(globalPlan[1].Action = "AutoBindAll" && globalPlan[1].Key = "SC11C",
        "Ctrl+NumpadEnter AutoBindAll")
    Test_Assert(globalPlan[2].Action = "ClearAll" && globalPlan[2].Key = "SC11C",
        "Ctrl+Shift+NumpadEnter ClearAll")

    Test_Assert(Input_ModifierKind(1, 1, 0) = "CtrlShift", "Ctrl Shift modifier")
    Test_Assert(Input_ModifierKind(1, 0, 1) = "CtrlAlt", "Ctrl Alt modifier")
    Test_Assert(Input_ModifierKind(0, 1, 0) = "Unsupported", "Shift-only controller modifier unsupported")

    Test_Assert(Input_ZeroPassThroughSpec("Numpad0", "Normal") = "{Numpad0 1}",
        "Zero pass-through replays one zero")
    Test_Assert(Input_ZeroPassThroughSpec("Virtual00", "Ctrl") = "^{Numpad0 2}",
        "Virtual00 pass-through replays two Ctrl+zeros")
    Test_Assert(Input_ZeroPassThroughSpec("Virtual000", "CtrlShift") = "^+{Numpad0 3}",
        "Virtual000 pass-through replays three Ctrl+Shift+zeros")
    Test_Assert(Input_ZeroPassThroughSpec("Virtual000", "Unsupported") = "{Numpad0 3}",
        "Unsupported modifier fallback still replays suppressed zeros")
}

Test_RecordStep(log, actionId, fromMulti := false) {
    log.Push(actionId)
}

Test_MultiAction() {
    global App
    App := App_Create()
    App.Config := Test_LoadExample()
    App.Metadata := Config_Metadata()
    App.ActiveLayer := App.Config.DefaultLayer
    App.WindowState := Runtime_Init(App.Config)

    log := []
    Test_Assert(MultiAction_Run("CopyToNotepad", Test_RecordStep.Bind(log)),
        "MultiAction executes")
    Test_Assert(log.Length = 4, "MultiAction executes all steps")
    Test_Assert(log[1] = "Copy" && log[2] = "Delay100"
        && log[3] = "NotepadActivate" && log[4] = "Paste",
        "MultiAction preserves configured order")

    App.MultiRunning["CopyToNotepad"] := true
    Test_Assert(!MultiAction_Run("CopyToNotepad", Test_RecordStep.Bind(log)),
        "MultiAction re-entry suppressed")
    App.MultiRunning.Delete("CopyToNotepad")
}

Test_Launch() {
    global App
    App := App_Create()
    App.Config := Test_LoadExample()
    App.ActiveLayer := App.Config.DefaultLayer
    App.WindowState := Runtime_Init(App.Config)

    none := []
    Test_Assert(Launch_Decide("NotepadActivate", none, 1000) = "Ready",
        "Launch ready when group window count is zero")

    exists := [Test_Candidate(500, "notepad.exe")]
    Test_Assert(Launch_Decide("NotepadActivate", exists, 1000) = "Existing",
        "Existing application window blocks launch")

    App.LaunchPending["Notepad"] := {Expires: 2000, Pid: 123}
    Test_Assert(Launch_Decide("NotepadActivate", none, 1500) = "Pending",
        "LaunchPending blocks duplicate run")
    Test_Assert(Launch_Decide("NotepadActivate", none, 2001) = "Ready",
        "LaunchPending timeout permits retry")
    Test_Assert(!App.LaunchPending.Has("Notepad"), "Expired LaunchPending cleared")
    Test_Assert(Launch_Decide("ManualWindow", none, 1000) = "Unavailable",
        "Window Action without launch group does not launch")
}

Test_WindowBehavior() {
    Test_Assert(Window_BehaviorDecision("Toggle", true, 0) = "Minimize",
        "Toggle active window minimizes")
    Test_Assert(Window_BehaviorDecision("Toggle", false, -1) = "RestoreActivate",
        "Toggle minimized window restores and activates")
    Test_Assert(Window_BehaviorDecision("Toggle", false, 0) = "Activate",
        "Toggle inactive normal window activates")
    Test_Assert(Window_BehaviorDecision("Activate", true, 0) = "Activate",
        "Activate behavior never minimizes active window")
    Test_Assert(Window_BehaviorDecision("Activate", false, -1) = "RestoreActivate",
        "Activate behavior restores minimized window")
}

Test_AlwaysValid(hwnd, action) {
    return true
}

Test_NeverValid(hwnd, action) {
    return false
}

Test_ActivateThenToggle() {
    global App, TestRoot

    App := App_Create()
    App.Config := Test_LoadPhysicalAcceptance()
    App.Metadata := Config_Metadata()
    App.ActiveLayer := "Window"
    App.WindowState := Runtime_Init(App.Config)

    action := App.Config.Actions["Explorer"]
    Test_Assert(action.Behavior = "ActivateThenToggle", "ATT-01 behavior loaded")
    for id in ["Explorer", "ChatGPT", "PowerShell"] {
        group := App.Config.WindowGroups[id]
        Test_Assert(group.LaunchTarget != "",
            "ATT-10 " id " launch fallback configured")
        Test_Assert(Launch_Decide(
            id = "PowerShell" ? "PowerShell7" : id, [], 1000) = "Ready",
            "ATT-10 " id " launch is ready with zero windows")
    }
    Test_Assert(!App.WindowState["Explorer"].ToggleArmed,
        "ATT-12 controller startup begins in Activate phase")

    Test_Assert(Launch_PendingContinuationAction(
        {Expires: 2000, Pid: 123, ActionId: "Explorer"}, App.Config) = "Explorer",
        "ATT-10 ActivateThenToggle launch continues with original Action")
    Test_Assert(Launch_PendingContinuationAction(
        {Expires: 2000, Pid: 123, ActionId: "ChatGPT"}, App.Config) = "ChatGPT",
        "ATT-10 ChatGPT launch continuation selected")
    Test_Assert(Launch_PendingContinuationAction(
        {Expires: 2000, Pid: 123, ActionId: "PowerShell7"}, App.Config) = "PowerShell7",
        "ATT-10 PowerShell launch continuation selected")
    Test_Assert(Launch_PendingContinuationAction(
        {Expires: 2000, Pid: 123, ActionId: "Chrome1"}, App.Config) = "",
        "ATT-10 ordinary Toggle launch does not auto-continue")
    Test_Assert(Launch_PendingContinuationAction(
        {Expires: 2000, Pid: 123}, App.Config) = "",
        "ATT-10 legacy pending state without ActionId has no continuation")

    Test_Assert(Window_EffectiveBehavior(action.Behavior, false) = "Activate",
        "ATT-02 initial phase uses Activate behavior")
    Test_Assert(Window_BehaviorDecision(
        Window_EffectiveBehavior(action.Behavior, false), true, 0) = "Activate",
        "ATT-02 initially active window does not minimize")
    Test_Assert(Window_BehaviorDecision(
        Window_EffectiveBehavior(action.Behavior, false), false, 0) = "Activate",
        "ATT-03 initially inactive window activates")
    Test_Assert(Window_BehaviorDecision(
        Window_EffectiveBehavior(action.Behavior, false), false, -1) = "RestoreActivate",
        "ATT-04 initially minimized window restores and activates")

    armed := Window_ToggleArmedAfterActivation(action.Behavior, false, true)
    Test_Assert(armed, "ATT-02/03/04 successful activation arms Toggle phase")
    Test_Assert(Window_EffectiveBehavior(action.Behavior, armed) = "Toggle",
        "ATT-05 armed phase uses Toggle behavior")
    Test_Assert(Window_BehaviorDecision(
        Window_EffectiveBehavior(action.Behavior, armed), true, 0) = "Minimize",
        "ATT-05 armed active window minimizes")
    Test_Assert(Window_BehaviorDecision(
        Window_EffectiveBehavior(action.Behavior, armed), false, 0) = "Activate",
        "ATT-06 armed inactive window activates")
    Test_Assert(Window_BehaviorDecision(
        Window_EffectiveBehavior(action.Behavior, armed), false, -1) = "RestoreActivate",
        "ATT-06 armed minimized window restores and activates")
    Test_Assert(!Window_ToggleArmedAfterActivation(action.Behavior, false, false),
        "ATT-11 failed activation does not arm Toggle phase")
    Test_Assert(Window_ToggleArmedAfterActivation(action.Behavior, true, false),
        "ATT-06 armed phase remains armed without a new activation")

    firstCandidate := Test_Candidate(301, "explorer.exe", "CabinetWClass")
    bound := Binding_Assign(App.WindowState, App.Config, "Explorer", firstCandidate)
    Test_Assert(bound["Explorer"].Hwnd = 301 && !bound["Explorer"].ToggleArmed,
        "ATT-08 manual binding starts in Activate phase")
    bound["Explorer"].ToggleArmed := true

    secondCandidate := Test_Candidate(302, "explorer.exe", "CabinetWClass")
    rebound := Binding_Assign(bound, App.Config, "Explorer", secondCandidate)
    Test_Assert(rebound["Explorer"].Hwnd = 302 && !rebound["Explorer"].ToggleArmed,
        "ATT-08 manual rebind resets Activate phase")

    App.WindowState := rebound
    App.WindowState["Explorer"].ToggleArmed := true
    Binding_Clear("Explorer", false)
    Test_Assert(!App.WindowState["Explorer"].Hwnd && !App.WindowState["Explorer"].ToggleArmed,
        "ATT-07 binding clear resets Activate phase")

    area := {X: 0, Y: 0, W: 1000, H: 1000, Left: 0, Top: 0, Right: 1000, Bottom: 1000}
    candidates := [Test_Candidate(401, "explorer.exe", "CabinetWClass")]
    autoState := AutoBind_Calculate(App.Config, Runtime_Init(App.Config), candidates, area)
    Test_Assert(autoState["Explorer"].Hwnd = 401 && !autoState["Explorer"].ToggleArmed,
        "ATT-09 new Auto Bind starts in Activate phase")

    autoState["Explorer"].ToggleArmed := true
    preserved := AutoBind_Calculate(App.Config, autoState, candidates, area, , ,
        Test_AlwaysValid)
    Test_Assert(preserved["Explorer"].Hwnd = 401 && preserved["Explorer"].ToggleArmed,
        "ATT-09 valid existing Auto Bind preserves Toggle phase")

    replacementCandidates := [Test_Candidate(402, "explorer.exe", "CabinetWClass")]
    replaced := AutoBind_Calculate(App.Config, autoState, replacementCandidates, area, , ,
        Test_NeverValid)
    Test_Assert(replaced["Explorer"].Hwnd = 402 && !replaced["Explorer"].ToggleArmed,
        "ATT-09 invalid binding replaced in Activate phase")

    exampleText := FileRead(TestRoot "\examples\KeyBindings.example.ini", "UTF-8")
    launchText := StrReplace(exampleText, "Behavior=Activate",
        "Behavior=ActivateThenToggle", , , 1)
    App.Config := Test_ValidateText(launchText)
    App.WindowState := Runtime_Init(App.Config)
    Test_Assert(App.Config.Actions["NotepadActivate"].Behavior = "ActivateThenToggle",
        "ATT-10 launch fixture uses ActivateThenToggle")
    Test_Assert(Launch_Decide("NotepadActivate", [], 1000) = "Ready",
        "ATT-10 launch is ready with no matching window")
    Test_Assert(!App.WindowState["NotepadActivate"].ToggleArmed,
        "ATT-10 launch decision alone does not arm Toggle phase")

    App.LaunchPending["Notepad"] := {Expires: 2000, Pid: 123}
    Test_Assert(Launch_Decide("NotepadActivate", [], 1500) = "Pending"
        && !App.WindowState["NotepadActivate"].ToggleArmed,
        "ATT-10 LaunchPending keeps Activate phase")
    App.LaunchPending.Delete("Notepad")

    App.WindowState["NotepadActivate"].ToggleArmed :=
        Window_ToggleArmedAfterActivation("ActivateThenToggle", false, true)
    Test_Assert(App.WindowState["NotepadActivate"].ToggleArmed,
        "ATT-11 first successful post-launch activation arms Toggle phase")

    restarted := Runtime_Init(App.Config)
    Test_Assert(!restarted["NotepadActivate"].ToggleArmed,
        "ATT-12 controller restart does not persist Toggle phase")
}

Test_Probe() {
    window := Gui(, "NWC Phase K probe fixture")
    try {
        p := Window_GetIdentity(window.Hwnd)
        Test_Assert(IsObject(p) && p.Title = "NWC Phase K probe fixture", "Live HWND identity")
        Test_Assert(p.Process != "" && p.Class = "AutoHotkeyGUI", "Live process/class")
        Test_Assert(!IsObject(Window_GetIdentity(0)), "Invalid HWND")
        Test_Assert(!IsObject(Window_GetCandidate(window.Hwnd)), "Hidden GUI excluded")
        candidates := Window_EnumerateCandidates()
        Test_Assert(candidates is Array, "Live candidate enumeration")
        area := Window_GetPrimaryWorkArea()
        Test_Assert(area.W > 0 && area.H > 0, "Live primary work area")
    } finally {
        window.Destroy()
    }
}
