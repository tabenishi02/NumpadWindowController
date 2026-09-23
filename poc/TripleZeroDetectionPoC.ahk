#Requires AutoHotkey v2.0
#SingleInstance Force
Persistent

; NumpadWindowController - 000 key detection PoC
; Goal:
;   Distinguish a normal Numpad0 press from the physical 000 key,
;   which emits Numpad0 Down/Up three times in rapid succession.
;
; Initial rule:
;   D-U-D-U-D-U completed within 80 ms => TRIPLE_ZERO
;
; While this PoC is running, physical Numpad0 (SC052) is suppressed so
; the test does not type 0 into the active application.

global DETECTION_WINDOW_MS := 80
global ZERO_VK := 0x60
global ZERO_SC := 0x052

global LOG_DIR := A_ScriptDir "\logs"
global LOG_FILE := LOG_DIR "\triple_zero_poc.log"

global gActive := false
global gStartTick := 0
global gEvents := []
global gZeroPhysicallyDown := false
global gIgnoreUntilUp := false
global gInterruptedBy := ""
global gFinalizeTimer := FinalizeByTimer

DirCreate LOG_DIR

FileAppend(
    "=== TripleZeroDetectionPoC session " A_Now
    " | window=" DETECTION_WINDOW_MS "ms ===`n",
    LOG_FILE,
    "UTF-8"
)

; The measured key is Numpad0 only while NumLock is on.
SetNumLockState "On"

; Observe every keyboard event, but suppress only the physical key with SC052.
; Other keys remain visible to the active application.
global gInput := InputHook("V")
gInput.KeyOpt("{All}", "N")
gInput.KeyOpt("{sc052}", "NS")
gInput.OnKeyDown := OnKeyDown
gInput.OnKeyUp := OnKeyUp
gInput.Start()

ShowStatus(
    "000 detection PoC running"
    "`nWindow: " DETECTION_WINDOW_MS " ms"
    "`nF9: open log / F8: reset / Ctrl+Esc: exit",
    2500
)

F8::ResetSession()
F9::Run(LOG_FILE)
^Esc::ExitApp

OnKeyDown(ih, vk, sc) {
    global gActive, gInterruptedBy

    now := A_TickCount

    if IsNumpad0(vk, sc) {
        HandleZeroDown(now)
        return
    }

    ; Any different key pressed during the candidate window invalidates
    ; the 000 pattern for this PoC.
    if gActive {
        gInterruptedBy := KeyId(vk, sc)
        LogLine(
            "INTERRUPT +" (now - GetStartTick()) "ms"
            " key=" gInterruptedBy
        )
        FinalizeSequence("INTERRUPTED")
    }
}

OnKeyUp(ih, vk, sc) {
    if IsNumpad0(vk, sc)
        HandleZeroUp(A_TickCount)
}

HandleZeroDown(now) {
    global DETECTION_WINDOW_MS
    global gActive, gStartTick, gEvents
    global gZeroPhysicallyDown, gIgnoreUntilUp
    global gFinalizeTimer

    ; After a normal single press has already been classified while the
    ; key is still held, ignore keyboard-repeat Downs until the real Up.
    if gIgnoreUntilUp {
        LogLine("EVENT ignored-repeat D Numpad0")
        return
    }

    ; Protect against a delayed timer: if a new Down arrives outside the
    ; 80 ms window, finalize the previous sequence first.
    if gActive && (now - gStartTick > DETECTION_WINDOW_MS) {
        FinalizeSequence()
        if gIgnoreUntilUp
            return
    }

    if !gActive {
        gActive := true
        gStartTick := now
        gEvents := []
        SetTimer gFinalizeTimer, -DETECTION_WINDOW_MS
    }

    gEvents.Push({kind: "D", tick: now})
    gZeroPhysicallyDown := true

    LogZeroEvent("D", now)
    CheckImmediateTriple()
}

HandleZeroUp(now) {
    global gActive, gEvents
    global gZeroPhysicallyDown, gIgnoreUntilUp

    gZeroPhysicallyDown := false

    if gIgnoreUntilUp {
        gIgnoreUntilUp := false
        LogLine("EVENT release-after-single U Numpad0")
        return
    }

    if !gActive {
        LogLine("EVENT stray U Numpad0")
        return
    }

    gEvents.Push({kind: "U", tick: now})
    LogZeroEvent("U", now)

    CheckImmediateTriple()
}

CheckImmediateTriple() {
    global DETECTION_WINDOW_MS
    global gActive, gStartTick, gEvents

    if !gActive
        return

    pattern := EventPattern()

    if pattern = "DUDUDU" {
        elapsed := gEvents[gEvents.Length].tick - gStartTick

        if elapsed <= DETECTION_WINDOW_MS
            FinalizeSequence("TRIPLE_ZERO")
        else
            FinalizeSequence("AMBIGUOUS")
    }
}

FinalizeByTimer() {
    FinalizeSequence()
}

FinalizeSequence(forcedResult := "") {
    global DETECTION_WINDOW_MS
    global gActive, gStartTick, gEvents
    global gZeroPhysicallyDown, gIgnoreUntilUp
    global gInterruptedBy, gFinalizeTimer

    if !gActive
        return

    SetTimer gFinalizeTimer, 0

    pattern := EventPattern()
    downCount := CountEvent("D")
    lastEventElapsed := 0

    if gEvents.Length > 0
        lastEventElapsed := gEvents[gEvents.Length].tick - gStartTick

    result := forcedResult

    if result = "" {
        if pattern = "DUDUDU" && lastEventElapsed <= DETECTION_WINDOW_MS
            result := "TRIPLE_ZERO"
        else if downCount = 1
            result := "SINGLE_ZERO"
        else if downCount = 2
            result := "FAST_DOUBLE_ZERO"
        else
            result := "AMBIGUOUS"
    }

    detail := (
        "RESULT " result
        " pattern=" pattern
        " downs=" downCount
        " lastEvent=" lastEventElapsed "ms"
    )

    if gInterruptedBy != ""
        detail .= " interruptedBy=" gInterruptedBy

    LogLine(detail)

    ShowStatus(
        result
        "`npattern=" pattern
        "`nlastEvent=" lastEventElapsed " ms",
        1100
    )

    ; If classification occurred before the physical key was released
    ; (typical normal 0 press), ignore auto-repeat until the real Up.
    if gZeroPhysicallyDown
        gIgnoreUntilUp := true

    gActive := false
    gStartTick := 0
    gEvents := []
    gInterruptedBy := ""
}

ResetSession() {
    global gActive, gStartTick, gEvents
    global gZeroPhysicallyDown, gIgnoreUntilUp
    global gInterruptedBy, gFinalizeTimer

    SetTimer gFinalizeTimer, 0

    gActive := false
    gStartTick := 0
    gEvents := []
    gZeroPhysicallyDown := false
    gIgnoreUntilUp := false
    gInterruptedBy := ""

    LogLine("=== MANUAL RESET ===")
    ShowStatus("PoC state reset", 900)
}

IsNumpad0(vk, sc) {
    global ZERO_VK, ZERO_SC
    return vk = ZERO_VK && sc = ZERO_SC
}

EventPattern() {
    global gEvents

    pattern := ""
    for event in gEvents
        pattern .= event.kind

    return pattern
}

CountEvent(kind) {
    global gEvents

    count := 0
    for event in gEvents {
        if event.kind = kind
            count += 1
    }

    return count
}

LogZeroEvent(kind, tick) {
    global gStartTick
    LogLine(
        "EVENT +" (tick - gStartTick) "ms"
        " " kind
        " Numpad0 vk=60 sc=052"
    )
}

LogLine(text) {
    global LOG_FILE
    FileAppend(A_Now " " text "`n", LOG_FILE, "UTF-8")
}

KeyId(vk, sc) {
    return Format("vk{:02X}/sc{:03X}", vk, sc)
}

GetStartTick() {
    global gStartTick
    return gStartTick
}

ShowStatus(text, durationMs := 1000) {
    ToolTip text
    SetTimer ClearStatus, -durationMs
}

ClearStatus() {
    ToolTip
}
