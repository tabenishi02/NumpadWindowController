# Phase K - Physical Acceptance Test

更新日: 2026-09-30  
対象: Phase K / ConfigVersion 3  
状態: **Ready for Manual Test**

## 1. 目的

Phase Kで実装したAction / Layer Architectureを、実際のテンキーとDesktop Sessionで確認する。

この試験では専用Config:

`examples/KeyBindings.phase-k-test.ini`

を使用する。従来のようにPublic Default / Example / Developer Workflowを試験途中で切り替えず、原則として**1つのINIだけでK-PA-1～12を実施する**。

Virtual00は00キー実機を所有していないためPhysical Acceptance対象外とし、Logic Regression PASS / Physical Acceptance N/Aとする。

---

## 2. テストConfigのLayer

`NumpadAdd` は全Layer共通のLayer Next。

| Layer | 主用途 |
|---|---|
| Window | Developer Workflow相当、Window Toggle、Manual Bind |
| Edit | Copy / Paste / Cut / Undo / Redo等 |
| Media | Volume / Media / Browser / Screenshot |
| Tools | Run / Launch fallback / MultiAction / Virtual000 |

Layer順:

```text
Window → Edit → Media → Tools → Window
```

---

## 3. 事前準備

### 3.1 Phase Kブランチを取得

対象Branch:

```text
phase-k-action-layer-architecture
```

最新状態へ更新する。

```powershell
git switch phase-k-action-layer-architecture
git pull
```

### 3.2 Controllerを終了

実行中のNumpadWindowControllerを終了する。

### 3.3 現在のUser Configをバックアップ

```powershell
Copy-Item .\KeyBindings.ini .\KeyBindings.before-phase-k-test.ini -ErrorAction SilentlyContinue
```

### 3.4 Physical Acceptance Configを適用

```powershell
Copy-Item .\examples\KeyBindings.phase-k-test.ini .\KeyBindings.ini -Force
```

### 3.5 Controllerを起動

`NumpadWindowController.ahk` をAutoHotkey v2で起動する。

期待:

- Configuration Errorが出ない
- 起動時Layerは `Window`
- Windows側NumLockがONになる

---

# K-PA-1 Layer

1. 起動直後のLayerが `Window` であることを確認。
2. `NumpadAdd` を押す。
3. ToolTipが `Layer: Edit` になることを確認。
4. 再度押して `Media`。
5. 再度押して `Tools`。
6. 再度押して `Window`。

期待:

```text
Window → Edit → Media → Tools → Window
```

- どのLayerからでも `NumpadAdd` が機能する。
- Layer切替後に操作不能にならない。

結果:

- [x] PASS
- [ ] FAIL

備考:

---

# K-PA-2 KeySend

`Edit` Layerへ移動する。

Text EditorをActiveにし、適当な文章を入力する。

| Key | Action |
|---|---|
| Numpad7 | Undo |
| Numpad8 | Copy |
| Numpad9 | Paste |
| Numpad4 | Cut |
| Numpad5 | Select All |
| Numpad6 | Save |
| Numpad1 | Find |
| Numpad2 | Win+Shift+S |
| Numpad3 | Redo |

最低確認:

1. Textを選択。
2. `Numpad8` でCopy。
3. Cursorを移動。
4. `Numpad9` でPaste。
5. `Numpad7` でUndo。
6. `Numpad3` でRedo。
7. `Numpad4` / `Numpad5` / `Numpad6` / `Numpad1` も確認。

期待:

- 対応するKeyboard Shortcutとして動作する。
- テンキー本来の数字入力等は発生しない。
- Controllerが停止しない。

結果:

- [x] PASS
- [ ] FAIL

備考:

---

# K-PA-3 Media / System

`Media` Layerへ移動する。

| Key | Action |
|---|---|
| Numpad4 | Volume Down |
| Numpad5 | Volume Mute |
| Numpad6 | Volume Up |
| Numpad7 | Previous Track |
| Numpad8 | Play / Pause |
| Numpad9 | Next Track |
| Numpad1 | Browser Back |
| Numpad2 | Browser Refresh |
| Numpad3 | Browser Forward |
| Numpad0 | Win+Shift+S |

期待:

- Volume系はWindows側で反映される。
- Browser系は対応Browserで動作する。
- Win+Shift+SでScreenshot UIが起動する。
- Media Key非対応Applicationで反応しない場合、それ自体はController FAILとしない。

結果:

- [x] PASS
- [ ] FAIL

備考:

---

# K-PA-4 Window Toggle / 実Application

`Window` Layerへ戻る。

事前に可能な範囲で以下を起動する。

- Chrome: 3 Window
- VS Code: 1～3 Window
- Explorer
- ChatGPT Desktop
- Windows Terminal上のPowerShell 7

Window Layer割当:

| Key | Window |
|---|---|
| 7 / 8 / 9 | Chrome 1 / 2 / 3 |
| 4 / 5 / 6 | VS Code 1 / 2 / 3 |
| 1 | Explorer / ActivateThenToggle |
| 2 | ChatGPT Desktop / ActivateThenToggle |
| 3 | PowerShell 7 / ActivateThenToggle |

最初に:

```text
Ctrl + NumpadEnter
```

でAuto Bind Allを実行する。

各対象について次を確認する。

1. 別WindowをActiveにする。
2. 対象Keyを押す。
3. 対象WindowがActivateされる。
4. 対象WindowがActiveの状態でもう一度同じKeyを押す。
5. 対象WindowがMinimizeされる。
6. もう一度同じKeyを押す。
7. Restore + Activateされる。

期待:

```text
Inactive  → Activate
Active    → Minimize
Minimized → Restore + Activate
```

Chrome / VS Code / Explorer / ChatGPT / PowerShell 7について確認する。

結果（初回試験 / Toggle仕様）:

- [x] PASS
- [ ] FAIL

ActivateThenToggle追加後の再試験:

- [ ] PASS
- [ ] FAIL

備考:

---

# K-PA-5 Manual Bind / Clear / Global Command

`Window` Layerで実施する。

Manual用Key:

| Key | Action |
|---|---|
| NumpadDiv | Manual Window 1 |
| NumpadMult | Manual Window 2 |
| NumpadSub | Manual Window 3 |
| NumpadDot | Manual Window Dot |

## 個別Bind / Clear

1. Window AをActiveにする。
2. `Ctrl + NumpadDiv` でBind。
3. 別Windowへ移動。
4. `NumpadDiv` でWindow Aへ戻れることを確認。
5. `Ctrl + Shift + NumpadDiv` でClear。
6. 再度 `NumpadDiv` を押す。

期待:

- Clear後はWindow Aへ移動しない。

## Clear All

複数Manual Window ActionをBindする。

```text
Ctrl + Shift + NumpadEnter
```

を実行する。

期待:

- 全Window BindingがClearされる。
- Config自体は変更されない。

Developer Workflowを再構築する場合:

```text
Ctrl + NumpadEnter
```

結果:

- [x] PASS
- [ ] FAIL

ActivateThenToggle追加後の再試験:

- [ ] PASS
- [ ] FAIL

備考:

---

# K-PA-6 Launch fallback / LaunchPending

`Tools` Layerへ移動する。

Tools Layer:

| Key | Action |
|---|---|
| NumpadDiv | Run Notepad |
| NumpadMult | Notepad Window Action |
| Numpad9 | Copy to Notepad MultiAction |

すべてのNotepad Windowを閉じる。

## Launch fallback

1. `NumpadMult` を1回押す。

期待:

- Notepadが起動する。
- Controllerは長時間停止しない。
- 最初の入力で同期的にWindow生成待ちを続けない。

## LaunchPending

Notepadを再度すべて閉じる。

1. `NumpadMult` を短時間に複数回押す。

期待:

- Notepadが大量に多重起動しない。
- Group単位LaunchPendingが重複Runを抑止する。

## Existing Window

1. Notepadを1つ起動した状態にする。
2. `Ctrl + Shift + NumpadMult` でNotepad ActionのBindingをClear。
3. `NumpadMult` を押す。

期待:

- 既存Notepadを候補として利用する。
- Notepad Windowが存在する場合、新規Notepadを追加Launchしない。

結果:

- [x] PASS
- [ ] FAIL

ActivateThenToggle追加後の再試験:

- [ ] PASS
- [ ] FAIL

備考:

---

# K-PA-7 MultiAction / Delay

`Tools` Layerのまま実施する。

Notepadを1つ起動しておく。

別のText Editorで任意Textを選択する。

`Numpad9` を押す。

設定されている順序:

```text
Copy
 ↓
Delay 100 ms
 ↓
Notepad Activate
 ↓
Paste
```

期待:

- 選択TextがClipboardへCopyされる。
- 約100msのDelay後にNotepadへ移動する。
- NotepadへPasteされる。
- Step順序が崩れない。
- 同じKeyを短時間連打しても同一MultiActionの再入が抑止される。
- Delay後もControllerが操作可能。

結果:

- [x] PASS
- [ ] FAIL

備考:

---

# K-PA-8 Virtual000 / Numpad0分離

`Tools` Layerで実施する。

このTest Configでは:

```ini
EnableVirtual00=Off
EnableVirtual000=On
```

としている。

Mapping:

```text
Numpad0    → ZeroWindow
Virtual000 → TripleZeroWindow
```

## Single Zero

1. Window AをActive。
2. `Ctrl + Numpad0` でZeroWindowへBind。
3. 別Windowへ移動。
4. `Numpad0` を1回押す。

期待:

- Window Aへ移動する。

## Physical 000

1. Window BをActive。
2. `Ctrl` を保持しながら物理 `000` キーを1回押し、TripleZeroWindowへBind。
3. 別Windowへ移動。
4. 物理 `000` キーを1回押す。

期待:

- Window Bへ移動する。
- 000入力がNumpad0 ×3として3回Action実行されない。
- Ctrl保持中の000入力が誤Interruptされない。

追加確認:

- 通常Keyを押した後もZero Detectorが異常状態に残らない。
- Numpad0単押しは引き続きZeroWindowとして動作する。

結果:

- [x] PASS
- [ ] FAIL

備考:

---

# K-PA-9 Auto Bind Strategy

`Window` Layerへ戻る。

```text
Ctrl + Shift + NumpadEnter
Ctrl + NumpadEnter
```

の順で、全Binding Clear → Auto Bind Allを行う。

確認:

### Chrome

- Primary Monitor上で従来の3-pane配置にする。
- 7 / 8 / 9が対応位置へ割り当てられる。

期待:

- `PrimaryThreePane` Strategyが動作。

### VS Code

- 複数Windowを起動。
- 4 / 5 / 6を確認。

期待:

- `ReverseList` Strategyで最大3 Windowを割り当てる。
- 真の起動順ではなくAuto Bind時点のWinGetList逆順である。

### FirstMatch

- Explorer = 1
- ChatGPT = 2
- PowerShell 7 = 3

期待:

- 各Allowed条件に一致するWindowへBindされる。
- Manual Binding済みActionは有効な限りAuto Bind Allで上書きされない。

結果:

- [x] PASS
- [ ] FAIL

ActivateThenToggle追加後の再試験:

- [ ] PASS
- [ ] FAIL

備考:

---

# K-PA-10 Native Pass-through / Backspace

BackspaceはTest ConfigのどのLayerにもMappingしていない。

Text Editorで確認する。

1. 通常Keyboard Backspaceを押す。
2. テンキーBackspaceを押す。
3. Layerを変更して同じ確認を行う。

期待:

- いずれもController Actionではなく通常Backspaceとして動作する。
- 起動時にBackspace Warningが出ない。

結果:

- [x] PASS
- [ ] FAIL

備考:

---

# K-PA-11 NumLock lifecycle

Controller起動前のWindows側NumLock状態を記録する。

### 実行中

期待:

- Controller実行中はWindows側NumLockがON。

### 正常終了

Controllerを正常終了する。

期待:

- Windows側NumLockが起動前状態へ復元される。

### 物理NumLock

対象テンキーの物理NumLockを操作する。

期待:

- テンキー内部の入力切替として使用可能。
- WindowsへNumLock Eventを送らない対象実機の既知仕様と矛盾しない。

結果:

- [x] PASS
- [ ] FAIL

備考:

---


# K-PA-12 ActivateThenToggle

Runtime実装済み。以下の追加物理受入を実施する。

`Window` Layerで次の3 Actionを確認する。

| Key | Window | Behavior |
|---|---|---|
| Numpad1 | Explorer | ActivateThenToggle |
| Numpad2 | ChatGPT Desktop | ActivateThenToggle |
| Numpad3 | PowerShell 7 | ActivateThenToggle |

## A. 初回Activation

1. `Ctrl + Shift + NumpadEnter` で全BindingをClearする。
2. `Ctrl + NumpadEnter` でAuto Bind Allする。
3. 対象WindowをActiveにする。
4. 対象Keyを1回押す。

期待:

- 初回はActive WindowでもMinimizeしない。
- Activate相当として扱われる。
- 正常なActivation完了後にToggle phaseへ移行する。

## B. Toggle phase

Activation成功後に同じKeyを再度押す。

期待:

- Active → Minimize
- 再度押す → Restore + Activate
- 別Windowから押す → Activate

## C. Binding ClearによるReset

1. Toggle phaseまで進める。
2. `Ctrl + Shift + 対象Key` でBinding Clear。
3. 再度Auto BindまたはManual Bindする。
4. 対象WindowをActiveにした状態で対象Keyを押す。

期待:

- Activate phaseへ戻っている。
- 初回入力ではMinimizeしない。

## D. Manual RebindによるReset

1. Toggle phaseまで進める。
2. 別の許可対象WindowへManual Bindする。
3. 新しいBinding先をActiveにして対象Keyを押す。

期待:

- 新しいBindingではActivate phaseから開始する。
- 旧BindingのToggle phaseを引き継がない。

## E. Controller Restart

1. Toggle phaseまで進める。
2. Controllerを終了。
3. 再起動して同じActionを確認。

期待:

- Runtime phaseは永続化されない。
- 再起動後はActivate phaseから開始する。

結果:

- [ ] PASS
- [ ] FAIL

備考:

---

# Virtual00

00キー搭載テンキーを所有していないため:

- [x] Logic Regression = PASS
- [x] Physical Acceptance = Not Executed / N/A

Physical AcceptanceのPASS条件には含めない。

---

# 4. 最終記録

| Test | Result |
|---|---|
| K-PA-1 Layer | [x] PASS / [ ] FAIL |
| K-PA-2 KeySend | [x] PASS / [ ] FAIL |
| K-PA-3 Media / System | [x] PASS / [ ] FAIL |
| K-PA-4 Window Toggle | [x] PASS / [ ] FAIL |
| K-PA-5 Manual Bind / Clear | [x] PASS / [ ] FAIL |
| K-PA-6 Launch fallback | [x] PASS / [ ] FAIL |
| K-PA-7 MultiAction / Delay | [x] PASS / [ ] FAIL |
| K-PA-8 Virtual000 | [x] PASS / [ ] FAIL |
| K-PA-9 Auto Bind Strategy | [x] PASS / [ ] FAIL |
| K-PA-10 Native Pass-through | [x] PASS / [ ] FAIL |
| K-PA-11 NumLock lifecycle | [x] PASS / [ ] FAIL |
| K-PA-12 ActivateThenToggle | [ ] PASS / [ ] FAIL |
| Virtual00 physical test | N/A |

Phase K Physical Acceptance PASS条件:

- 既存K-PA-1～11の初回試験結果を保持
- ActivateThenToggle実装後、K-PA-4 / K-PA-5 / K-PA-6 / K-PA-9を再確認
- K-PA-12がPASS
- Virtual00はN/A
- 新しいFAIL / BLOCKEDがない、または既知制限として整理済み
- Phase K Result / TASKS / PROJECT_HANDOFFへ結果を反映済み

---

# 5. テスト後のUser Config復元

Controllerを終了してから実施する。

バックアップが存在する場合:

```powershell
Copy-Item .\KeyBindings.before-phase-k-test.ini .\KeyBindings.ini -Force
```

バックアップが存在しなかった場合は、Test Configを削除し、次回起動時にDefaultを再生成させてもよい。

```powershell
Remove-Item .\KeyBindings.ini -ErrorAction SilentlyContinue
```

その後Controllerを再起動する。

---

# 6. FAIL時に記録する情報

FAILが発生した場合は最低限次を記録する。

- Test ID
- 使用Layer
- 押したKey / Modifier
- 期待結果
- 実際の結果
- 対象Application
- 再現回数
- Controller再起動後も再現するか
- 必要ならDebug Log

Phase K完了前にFAIL原因を実装不具合 / Test手順不備 / Known Limitationへ分類する。
