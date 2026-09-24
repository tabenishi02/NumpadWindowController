#Requires AutoHotkey v2.0
#SingleInstance Force
Persistent()

; NumpadWindowController - NumLock input observation PoC
; This PoC deliberately does NOT call SetNumLockState().
; It observes the external keypad NumLock through both AutoHotkey InputHook
; and Windows Raw Input so we can distinguish "AHK did not see it" from
; "Windows did not receive a keyboard event".

global LOG_DIR := A_ScriptDir "\logs"
global LOG_FILE := LOG_DIR "\numlock_input_poc_" A_Now ".log"

global WM_INPUT := 0x00FF
global RID_INPUT := 0x10000003
global RIM_TYPEKEYBOARD := 1
global RIDEV_INPUTSINK := 0x00000100
global RI_KEY_BREAK := 0x0001

DirCreate(LOG_DIR)
InstallKeybdHook()

FileAppend(
    "=== NumLockInputPoC session " A_Now
    " | AHK=" A_AhkVersion
    " | ptr=" A_PtrSize
    " | initialNumLock=" GetKeyState("NumLock", "T")
    " ===`n",
    LOG_FILE,
    "UTF-8"
)

OnMessage(WM_INPUT, Raw_OnInput)
RegisterRawKeyboard()

global gInput := InputHook("V")
gInput.KeyOpt("{All}", "N")
gInput.OnKeyDown := Input_OnDown
gInput.OnKeyUp := Input_OnUp
gInput.Start()

ToolTip(
    "NumLock input PoC running"
    "`nF6: mark normal NumLock"
    "`nF7: mark Ctrl+NumLock"
    "`nF8: mark Pause control"
    "`nF9: open log / Ctrl+Esc: exit"
)
SetTimer(() => ToolTip(), -3500)

F6::MarkTest("NORMAL_NUMLOCK")
F7::MarkTest("CTRL_NUMLOCK")
F8::MarkTest("PAUSE_CONTROL")
F9::Run(LOG_FILE)
^Esc::ExitApp()

MarkTest(name) {
    LogLine("=== MARK " name " | numToggle=" GetKeyState("NumLock", "T")
        " numPhysical=" GetKeyState("NumLock", "P") " ===")
    ToolTip(name)
    SetTimer(() => ToolTip(), -700)
}

Input_OnDown(ih, vk, sc) {
    LogAhk("D", vk, sc)
}

Input_OnUp(ih, vk, sc) {
    LogAhk("U", vk, sc)
}

LogAhk(kind, vk, sc) {
    name := KeyNameSafe(vk, sc)
    LogLine(
        "AHK " kind
        " vk=" Format("{:02X}", vk)
        " sc=" Format("{:03X}", sc)
        " key=" name
        " numToggle=" GetKeyState("NumLock", "T")
        " numPhysical=" GetKeyState("NumLock", "P")
    )
}

RegisterRawKeyboard() {
    global RIDEV_INPUTSINK
    rid := Buffer(8 + A_PtrSize, 0)
    NumPut("UShort", 0x01, rid, 0) ; Generic Desktop Controls
    NumPut("UShort", 0x06, rid, 2) ; Keyboard
    NumPut("UInt", RIDEV_INPUTSINK, rid, 4)
    NumPut("Ptr", A_ScriptHwnd, rid, 8)

    if !DllCall(
        "RegisterRawInputDevices",
        "Ptr", rid,
        "UInt", 1,
        "UInt", rid.Size,
        "Int"
    )
        throw OSError(A_LastError, "RegisterRawInputDevices")
}

Raw_OnInput(wParam, lParam, msg, hwnd) {
    global RID_INPUT, RIM_TYPEKEYBOARD, RI_KEY_BREAK

    headerSize := 8 + 2 * A_PtrSize
    size := 0

    result := DllCall(
        "GetRawInputData",
        "Ptr", lParam,
        "UInt", RID_INPUT,
        "Ptr", 0,
        "UInt*", &size,
        "UInt", headerSize,
        "UInt"
    )
    if result = 0xFFFFFFFF || size < headerSize
        return

    data := Buffer(size, 0)
    result := DllCall(
        "GetRawInputData",
        "Ptr", lParam,
        "UInt", RID_INPUT,
        "Ptr", data,
        "UInt*", &size,
        "UInt", headerSize,
        "UInt"
    )
    if result = 0xFFFFFFFF
        return

    type := NumGet(data, 0, "UInt")
    if type != RIM_TYPEKEYBOARD
        return

    device := NumGet(data, 8, "Ptr")
    offset := headerSize
    makeCode := NumGet(data, offset + 0, "UShort")
    flags := NumGet(data, offset + 2, "UShort")
    vkey := NumGet(data, offset + 6, "UShort")
    message := NumGet(data, offset + 8, "UInt")
    kind := (flags & RI_KEY_BREAK) ? "U" : "D"

    LogLine(
        "RAW " kind
        " device=0x" Format("{:X}", device)
        " vkey=" Format("{:02X}", vkey)
        " makeCode=" Format("{:03X}", makeCode)
        " flags=" Format("{:04X}", flags)
        " message=" Format("{:04X}", message)
        " numToggle=" GetKeyState("NumLock", "T")
    )
}

KeyNameSafe(vk, sc) {
    try
        return GetKeyName(Format("vk{:02X}sc{:03X}", vk, sc))
    catch
        return "?"
}

LogLine(text) {
    global LOG_FILE
    FileAppend(A_Now " " text "`n", LOG_FILE, "UTF-8")
}
