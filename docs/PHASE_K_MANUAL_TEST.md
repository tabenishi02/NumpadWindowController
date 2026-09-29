# Phase K - Physical Acceptance Test

更新日: 2026-09-29  
対象: Phase K / ConfigVersion 3  
状態: **Ready for Manual Test**

## 1. 目的

Automated Regressionで検証済みのPhase K機能を、実際のテンキー・Desktop Sessionで確認する。

Virtual00は00キー搭載実機がないためPhysical Acceptance対象外とし、Logic RegressionのみでN/Aとする。

---

## 2. 事前準備

1. 最新のPhase K実装を取得する。
2. 実行中のNumpadWindowControllerを終了する。
3. 現在のUser Configをバックアップする。

```powershell
Copy-Item .\KeyBindings.ini .\KeyBindings.before-phase-k-test.ini -ErrorAction SilentlyContinue
```

4. AutoHotkey v2で `NumpadWindowController.ahk` を起動する。

Configを切り替えた場合はControllerを再起動する。

---

## K-PA-1 Public Default / Layer

`KeyBindings.default.ini` をUser Configへコピーする。

```powershell
Copy-Item .\KeyBindings.default.ini .\KeyBindings.ini -Force
```

Controllerを再起動。

確認:

1. 起動時にConfiguration Errorが出ない。
2. 起動時LayerはBase。
3. `NumpadAdd` を押す。
4. ToolTipが `Layer: Edit` になる。
5. 再度押すとMedia。
6. 再度押すとBase。

期待:

- Base → Edit → Media → Baseで循環する。
- Layer切替後もNumpadAddで必ず次Layerへ移動できる。

結果:

- [ ] PASS
- [ ] FAIL

---

## K-PA-2 KeySend

Edit Layerへ移動する。

任意のText EditorをActiveにして確認する。

1. Textを入力する。
2. `Numpad8` → Copy
3. Cursorを移動する。
4. `Numpad9` → Paste
5. `Numpad7` → Undo
6. `Numpad3` → Redo

期待:

- Ctrl+C / Ctrl+V / Ctrl+Z / Ctrl+Y相当が動作する。
- Controller Key自体の文字入力は発生しない。

結果:

- [ ] PASS
- [ ] FAIL

---

## K-PA-3 Media / System

Media Layerへ移動する。

確認:

- `Numpad4`: Volume Down
- `Numpad5`: Mute
- `Numpad6`: Volume Up
- `Numpad7`: Previous
- `Numpad8`: Play/Pause
- `Numpad9`: Next
- `Numpad1`: Browser Back
- `Numpad2`: Browser Refresh
- `Numpad3`: Browser Forward
- `Numpad0`: Win+Shift+S

期待:

- 対応するMedia / Browser / System Shortcutが発火する。
- Application側が未対応のMedia KeyはController不具合扱いにしない。

結果:

- [ ] PASS
- [ ] FAIL

---

## K-PA-4 Window Toggle

Base Layerへ戻る。

1. 任意WindowをActiveにする。
2. `Ctrl + Numpad2` でManual Bind。
3. 別WindowをActiveにする。
4. `Numpad2`。

期待: Binding WindowがActivate。

5. Binding WindowがActiveの状態でもう一度 `Numpad2`。

期待: Binding WindowがMinimize。

6. もう一度 `Numpad2`。

期待: Restore + Activate。

結果:

- [ ] PASS
- [ ] FAIL

---

## K-PA-5 Manual Bind / Clear / Global Command

Base Layerで確認する。

1. `Ctrl + Numpad7` でWindow AをBind。
2. `Ctrl + Shift + Numpad7`。
3. `Numpad7`。

期待: BindingがClearされておりWindow Aへ移動しない。

4. 複数Window ActionへBind。
5. `Ctrl + Shift + NumpadEnter`。
6. 各Window Keyを押す。

期待: 全Window BindingがClear。

結果:

- [ ] PASS
- [ ] FAIL

---

## K-PA-6 Launch fallback / LaunchPending

Example Configへ切り替える。

```powershell
Copy-Item .\examples\KeyBindings.example.ini .\KeyBindings.ini -Force
```

Controllerを再起動。

すべてのNotepad Windowを閉じる。

1. `NumpadMult` を1回押す。

期待:

- NotepadがLaunchする。
- Controllerは長時間固まらない。

2. Window生成直前にNumpadMultを数回押す。

期待:

- LaunchPendingによりNotepadの多重Runが発生しない。

3. Notepad Windowが存在する状態でBindingをClearし、再度NumpadMult。

期待:

- Group一致Windowが存在するため追加NotepadをLaunchしない。
- 次回AutoBindで既存Notepadを利用できる。

結果:

- [ ] PASS
- [ ] FAIL

---

## K-PA-7 MultiAction / Delay

Example Configのまま確認する。

Text Editorで任意Textを選択し、ClipboardへCopy可能な状態にする。

`Numpad9` = `CopyToNotepad` を実行。

期待順:

1. Copy
2. 100ms Delay
3. Notepad Activate
4. Paste

期待:

- Step順に実行される。
- 同じKeyを短時間連打しても同一MultiActionが重複実行されにくい。
- Delay中にController全体が永久に固まらない。

結果:

- [ ] PASS
- [ ] FAIL

---

## K-PA-8 Virtual000 Regression

Developer Workflowへ切り替える。

```powershell
Copy-Item .\examples\KeyBindings.developer-workflow.ini .\KeyBindings.ini -Force
```

Controllerを再起動。

所有している000キーで確認する。

期待:

- 000キー1回でVirtual000 Actionが1回発火。
- Numpad0単押しはNumpad0 Actionとして動作。
- Ctrlを保持した000入力でも誤Interruptしない。
- 通常の他Key入力でZero Detectorが異常状態に残らない。

結果:

- [ ] PASS
- [ ] FAIL

---

## K-PA-9 Developer Workflow / Auto Bind

Developer Workflowのまま確認する。

- Chrome 7 / 8 / 9
- VS Code 4 / 5 / 6
- Explorer 1
- ChatGPT 2
- PowerShell 7 Terminal 3

期待:

- Chrome PrimaryThreePaneが従来配置で割り当てられる。
- VS CodeはReverseListで最大3Windowを割り当てる。
- Explorer / ChatGPT / PowerShell条件が動作する。
- `Ctrl + NumpadEnter` でAuto Bind All。
- Manual Bindingは有効な限り維持される。

結果:

- [ ] PASS
- [ ] FAIL

---

## K-PA-10 Native Pass-through / Backspace

Public Defaultへ戻す。

Backspaceが未Mappingであることを確認する。

1. Text Editorで通常Keyboard Backspaceを押す。
2. テンキーBackspaceを押す。

期待:

- Controller Actionではなく通常Backspaceとして動作。
- 起動時Backspace Warningが出ない。

結果:

- [ ] PASS
- [ ] FAIL

---

## K-PA-11 NumLock lifecycle

既知仕様の範囲で確認する。

- Controller実行中Windows側NumLockがON。
- Controller正常終了後に起動前状態へ復元。
- テンキー物理NumLockはテンキー内部入力切替として利用可能。

結果:

- [ ] PASS
- [ ] FAIL

---

## Virtual00

00キー実機なし。

- Logic Regression: PASS
- Physical Acceptance: **Not Executed / N/A**

---

## 最終記録

- [ ] K-PA-1 PASS
- [ ] K-PA-2 PASS
- [ ] K-PA-3 PASS
- [ ] K-PA-4 PASS
- [ ] K-PA-5 PASS
- [ ] K-PA-6 PASS
- [ ] K-PA-7 PASS
- [ ] K-PA-8 PASS
- [ ] K-PA-9 PASS
- [ ] K-PA-10 PASS
- [ ] K-PA-11 PASS
- [x] Virtual00 Physical Acceptance = N/A

全項目完了後、`docs/PHASE_K_RESULT.md` と `TASKS.md` をPhysical Acceptance PASSへ更新する。
