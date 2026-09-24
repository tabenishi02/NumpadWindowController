# NumpadWindowController - Phase F Manual Test Guide

更新日: 2026-09-25  
対象: Phase F - AutoHotkey v2実装  
目的: Phase Fで自動テストだけでは確認できない実機動作を確認し、Phase F完了可否を判断する。

---

# 1. このテストの位置づけ

Phase Fの本体実装および自動テストは完了している。

旧Global Action仕様ではAutoHotkey v2.0.26環境で自動テストPASSを確認済み。NumpadEnter Global Actionへの変更後はR-10で再実行する。

一方、以下は実Desktop環境・物理テンキー・Foreground制御等に依存するため、自動テストだけでは最終確認できない。

- Foreground Windowの取得
- Window Restore / Activate
- Lazy Auto Bind後のActivate
- 物理テンキー `0 / 000`
- Modifier付き物理入力
- Disabled / 未定義Modifier時の入力挙動
- Backspace有効化Warning
- NumLock状態の保存・ON固定・終了時復元

本書ではこれらをPhase FのManual Smoke Testとして確認する。

Chrome / VS Code等について多数のWindow数・再起動・長時間常駐・Sleep / Resumeまで網羅する試験はPhase G / Hで実施する。

---

# 2. Phase F完了条件

以下をすべて満たした場合、Phase F完了とする。

- Foreground WindowをManual Bindできる
- Binding済みWindowをRestore / Activateできる
- Lazy Auto Bind後に対象WindowをActivateできる
- 物理 `0` と物理 `000` が意図したLogical Keyとして動作する
- Ctrl / Ctrl+Shift / Ctrl+Altの各操作が物理入力でも正しく動作する
- Disabled Keyおよび未定義Modifierの挙動が設計どおりである
- Backspaceを有効化した際にWarningが表示される
- NumLockが実行中ON固定される
- 正常終了時に起動前のNumLock状態へ復元される
- テスト中に重大な例外、Script終了、Runtime State破損が発生しない

---

# 3. テスト前準備

## 3.1 使用環境を記録する

以下を記録する。

| 項目 | 記録 |
|---|---|
| Windows Version | |
| AutoHotkey Version | |
| NumpadWindowController Commit | |
| テスト実施日 | |
| テンキー機種 | |
| 備考 | |

Commitは可能であれば以下で確認する。

```powershell
git rev-parse HEAD
```

AutoHotkey Versionは使用しているAutoHotkey v2実行ファイルのバージョンを記録する。

---

## 3.2 競合するHookを停止する

以下を停止する。

- Phase B等で使用したPoC
- KeyCheckTest.ahk
- 他のAutoHotkey Script
- テンキー入力を変更する常駐Software

NumpadWindowController以外が同じキーをHookしていない状態で試験する。

---

## 3.3 標準Configurationを確認する

`KeyBindings.ini` が通常の標準状態であることを確認する。

特に次を確認する。

```ini
[Key-Backspace]
Mode=Disabled
Label=Backspace
```

専用Slotは以下である。

| Key | 用途 |
|---|---|
| 1 | Explorer |
| 2 | ChatGPT Desktop |
| 3 | PowerShell 7 |
| 4 | VS Code 1 |
| 5 | VS Code 2 |
| 6 | VS Code 3 |
| 7 | Chrome 1 |
| 8 | Chrome 2 |
| 9 | Chrome 3 |

`0` および `000` は任意WindowのManual Bindに使用する。

---

# 4. 自動テスト再確認

Manual Testを行う前に、現在のBaselineが正常であることを確認する。

## Test A-1: 通常自動テスト

### 実行

```powershell
.\tests\Run-PhaseFTests.ps1
```

### 期待結果

- Exit Codeが0
- FAILが存在しない

### 結果

- [x] PASS
- [ ] FAIL

記録:

```text
PASS 119 assertions (AHK 2.0.26)
```

---

## Test A-2: Desktop自動テスト

### 実行

```powershell
.\tests\Run-PhaseFTests.ps1 -Desktop
```

### 期待結果

基本的には以下と同等以上であること。

```text
PASS 138 assertions (AHK 2.0.26)
```

環境によって以下のPENDINGは許容する。

```text
PENDING: foreground activation / active-window manual binding
PENDING: NumLock 0 restoration
```

これらは本書のManual Testで確認する。

### 結果

- [x] PASS
- [ ] FAIL

Assertion数:

```text
138
```

PENDING:

```text
0
```

---

# 5. Foreground / Manual Bind / Activate

## Test F-1: Active Window Manual Bind

### 目的

実際にForegroundとなっているWindowを `WinExist("A")` から取得し、Manual Bindできることを確認する。

### 前提

- NumpadWindowControllerを起動する
- 任意の通常Windowを1つ開く
- テスト対象WindowをForegroundにする

専用Allowed条件の影響を避けるため、`Numpad0` を使用する。

### 手順

1. テスト対象WindowをForegroundにする。
2. `Ctrl + 0` を押す。
3. Manual Bind成功のToolTipを確認する。
4. 他のWindowをForegroundにする。
5. `0` を押す。

### 期待結果

- `Ctrl + 0` 時点でForegroundだったWindowがNumpad0へBindingされる
- `0` 押下でそのWindowがForegroundへ移動する
- Scriptが停止しない
- エラーToolTipが表示されない

### 結果

- [x] PASS
- [ ] FAIL

記録:

```text
対象Window:Chrome
結果:OK
備考:
```

---

## Test F-2: Minimized Window Restore + Activate

### 目的

Binding済みWindowが最小化されている場合にRestoreしてForegroundへ移動できることを確認する。

### 手順

1. Test F-1でNumpad0へBindingしたWindowを最小化する。
2. 別WindowをForegroundにする。
3. `0` を押す。

### 期待結果

- 対象Windowが最小化状態から復元される
- 対象WindowがForegroundになる
- Bindingは維持される

### 結果

- [x] PASS
- [ ] FAIL

記録:

```text

```

---

# 6. Lazy Auto Bind

## Test F-3: 無効HWNDからのLazy Auto Bind + Activate

### 目的

Binding先Window消滅後、通常押下だけで以下の一連処理が動作することを確認する。

```text
無効Binding検出
    ↓
Slot Clear
    ↓
Lazy Auto Bind
    ↓
新しいHWNDをBinding
    ↓
Activate
```

### 推奨対象

Explorer / Numpad1を使用する。

ChromeやVS Codeの詳細な再割り当て試験はPhase Gで行うため、Phase Fでは単一Slotで経路を確認する。

### 手順

1. Explorer Windowを1つ開く。
2. `Ctrl + NumpadEnter` を押してAuto Bind Allする。
3. `1` を押し、そのExplorerへ移動できることを確認する。
4. BindingされているExplorer Windowを閉じる。
5. 新しいExplorer Windowを開く。
6. 別WindowをForegroundにする。
7. `1` を押す。

### 期待結果

- 古いHWNDが無効と判定される
- Numpad1が一旦Noneになる
- 新しいExplorerが検索される
- 新しいExplorerへAuto Bindされる
- 同じ `1` 押下処理内で新しいExplorerがForegroundになる

### 結果

- [x] PASS
- [ ] FAIL

記録:

```text

```

---

# 7. 物理0 / 000

## Test F-4: 物理0

### 目的

物理テンキー `0` が通常のNumpad0として扱われることを確認する。

### 前提

Numpad0へ任意WindowをManual Bindしておく。

### 手順

1. `Ctrl + 0` で任意WindowをNumpad0へBindingする。
2. 別Windowへ移動する。
3. 物理テンキーの `0` を1回押す。

### 期待結果

- 約80ms程度の判定待ち後、Numpad0のActionが1回だけ実行される
- BindingしたWindowがForegroundになる
- 二重実行されない

### 結果

- [x] PASS
- [ ] FAIL

記録:

```text

```

---

## Test F-5: 物理000

### 目的

テンキーの `000` キーが `Numpad0` 3回ではなくLogical Key `Virtual000` の1操作として扱われることを確認する。

### 前提

Numpad0とVirtual000に異なるWindowを登録する。

### 手順

1. Window AをForegroundにする。
2. `Ctrl + 0` でWindow AをNumpad0へ登録する。
3. Window BをForegroundにする。
4. `Ctrl + 000` でWindow BをVirtual000へ登録する。
5. 別Windowへ移動する。
6. 物理 `000` キーを押す。

### 期待結果

- Window Bへ移動する
- Window AのActionが3回実行されない
- Virtual000として1回だけ処理される

### 結果

- [ ] PASS
- [x] FAIL

記録:

```text
Virtual000の登録自体は可能
しかし判定が人間に知覚が難しいほどにシビア
多くの場合0に登録されてしまう
判定の改善が必要
ただし、登録時以外の000は正常に機能する。Ctrl + Virtual000 が特別に判定が難しい可能性がある。
```

---

## Test F-6: 0の連続入力

### 目的

通常の0入力と000判定が明らかに破綻していないことを確認する。

### 手順

以下をそれぞれ試す。

1. `0` を1回
2. `0` を2回、普通の速度で押す
3. `000` 専用キーを押す
4. `0` を長押しする

### 期待結果

- 単押しはNumpad0 1回
- 通常速度の2回押しはNumpad0として処理される
- 000専用キーはVirtual000 1回
- 長押しRepeatによってActionが大量発火しない

### 注意

物理000と、人間による極端に高速な `0` 三連打は完全には区別できない。これは既知の制限であり、不具合とはしない。

### 結果

- [x] PASS
- [ ] FAIL

記録:

```text

```

---

# 8. Modifier入力

## Test F-7: Ctrl + Key Manual Bind

### 手順

1. 任意WindowをForegroundにする。
2. `Ctrl + 0` を押す。

### 期待結果

- Manual Bindされる
- 通常Activateは実行されない

### 結果

- [x] PASS
- [ ] FAIL

---

## Test F-8: Ctrl + Shift + Key Slot Clear

### 手順

1. Numpad0へWindowをBindingする。
2. `Ctrl + Shift + 0` を押す。
3. `0` を押す。

### 期待結果

- Numpad0 SlotがClearされる
- Numpad0はManual専用なので自動補充されない
- `0` 押下時にWindowが存在しない旨が通知される

### 結果

- [ ] PASS
- [x] FAIL

記録:

```text
- Numpad0 SlotがClearされる ok
- Numpad0はManual専用なので自動補充されない ok
- `0` 押下時にWindowが存在しない旨が通知される ng
0押下時に、Auto Bind completed と表示される。
```

---

## Test F-9: Ctrl + Alt + Key Auto Bind

### 推奨対象

Numpad1 / Explorer。

### 手順

1. Explorerを開く。
2. `Ctrl + Shift + 1` でNumpad1をClearする。
3. `Ctrl + Alt + 1` を押す。
4. `1` を押す。

### 期待結果

- ExplorerがNumpad1へAuto Bindされる
- `1` でExplorerへ移動できる

### 結果

- [x] PASS
- [ ] FAIL

---

## Test F-10: 未定義Modifier

### 対象

以下などを確認する。

```text
Shift + 1
Alt + 1
Ctrl + Shift + Alt + 1
Win + 1
```

### 期待結果

ControllerのActionとして誤実行されない。

通常Hotkey方式のキーについては、Controllerが定義していない組合せをController側で処理しない。

### 結果

- [x] PASS
- [ ] FAIL

記録:

```text
Shift:ok
Alt:ok
Ctrl+Shift+Alt:ok
Win:ok
```

---

# 9. Disabled Key

## Test F-11: Backspace Disabled時の通常入力

### 前提

標準設定を使用する。

```ini
[Key-Backspace]
Mode=Disabled
```

### 手順

1. メモ帳やVS Code等のText入力欄を開く。
2. 適当な文字列を入力する。
3. 通常KeyboardのBackspaceを押す。

### 期待結果

- 通常のBackspaceとして動作する
- NumpadWindowControllerのActionは実行されない

### 結果

- [x] PASS
- [ ] FAIL

---

# 10. Backspace Warning

## Test F-12: Backspace有効化Warning

### 目的

外付けテンキーのBackspaceと通常Keyboard Backspaceを入力上区別できないことについて、起動時Warningが表示されることを確認する。

### 注意

この試験では一時的にConfigurationを変更する。

試験終了後、必ず元の設定へ戻す。

### 一時設定

```ini
[Key-Backspace]
Mode=Window
Label=Backspace
AllowedProcess=
AllowedClass=
AllowedTitleContains=
```

### 手順

1. NumpadWindowControllerを終了する。
2. `KeyBindings.ini` を上記設定へ変更する。
3. NumpadWindowControllerを起動する。

### 期待結果

起動時に以下の内容を示すWarningが表示される。

- Backspaceが有効である
- 外付けテンキーBackspaceと通常Keyboard Backspaceを区別できない
- 両方がController Actionの対象になる

### 追加確認

Warningを閉じて起動後、通常KeyboardのBackspaceもController側の対象となることを確認してよい。

これは現在の設計上の既知制限である。

### 結果

- [x] PASS
- [ ] FAIL

記録:

```text
訂正（2026-09-25）:
初回テスト時に「物理キー表記はDEL」と記録したが、ユーザーの誤認だったため撤回する。
実機の物理キー表記もBackspaceであり、DELであるという事実はない。
したがって Key-Backspace / Backspace という現行設定・命名を維持し、KeypadDel等への名称変更は行わない。
```

### 復旧

試験後、必ず以下へ戻す。

```ini
[Key-Backspace]
Mode=Disabled
Label=Backspace
```

再起動して通常Backspaceが復旧したことも確認する。

- [x] 標準設定へ復旧済み

---

# 11. NumLock

## Test F-13: 起動前OFF → 実行中ON

### 手順

1. NumpadWindowControllerを終了する。
2. NumLockをOFFにする。
3. OFFであることを確認する。
4. NumpadWindowControllerを起動する。

### 期待結果

- 起動後NumLockがONになる
- Controller実行中はNumLock ONとして利用できる

### 結果

- [ ] PASS
- [x] FAIL

---

## Test F-14: 起動前OFF → 終了後OFF復元

### 前提

Test F-13から続ける。

### 手順

1. 起動前NumLock OFFでControllerを起動する。
2. Controller実行中にONであることを確認する。
3. AutoHotkeyのTray Iconから正常終了する。
4. NumLock状態を確認する。

### 期待結果

```text
起動前: OFF
実行中: ON
終了後: OFF
```

### 結果

- [ ] PASS
- [x] FAIL

記録:

```text
スクリプトの起動時のNumLock状態はそのまま維持される。
スクリプト起動中でもNumLock状態は切り替え可能。
スクリプトの終了時のNumLock状態はそのまま維持される。
```

---

## Test F-15: 起動前ON → 終了後ON復元

### 手順

1. NumLockをONにする。
2. Controllerを起動する。
3. Controllerを正常終了する。

### 期待結果

```text
起動前: ON
実行中: ON
終了後: ON
```

### 結果

- [ ] PASS
- [x] FAIL

---

## NumLock試験上の注意

強制Process Kill時のNumLock復元は保証対象外である。

以下による終了は本テストの対象外とする。

```text
taskkill /F
Process強制終了
OS crash
```

Phase Fでは正常終了時の復元を確認する。

---

# 12. 旧NumLock Global Action（廃止仕様・履歴）

## Test F-16: NumLock = Auto Bind All（旧仕様・廃止）

### 手順

1. `Ctrl + NumLock` でClear Allする。
2. `NumLock` を押す。
3. 1～9の専用Slotを確認する。

### 期待結果

- Clear直後はBindingが空になる
- NumLock押下後、存在する対象アプリだけ専用Slotへ再Bindingされる
- Numpad0 / Virtual000等のManual専用Slotは自動補充されない

### 結果

- [ ] PASS
- [x] FAIL

---

## Test F-17: Ctrl + NumLock = Clear All（旧仕様・廃止）

### 手順

1. Auto BindおよびManual Bindをいくつか作る。
2. `Ctrl + NumLock` を押す。

### 期待結果

- 全Window BindingがClearされる
- Configuration自体は変更されない
- 自動的な即時再Bindingは発生しない

### 結果

- [ ] PASS
- [x] FAIL

```text
Ctrl + NumLock を押しても Clearされない。
```

---

# 12.1 Phase F 修正後再テスト

F-16 / F-17およびR-2 / R-3のNumLock Global Action部分は旧仕様の履歴として残す。現行Global ActionはR-10～R-12で確認する。

初回Manual Testで確認されたF-5 / F-8 / F-13～F-17の問題に対する修正後テスト。
初回結果は履歴として上記に残し、この節へ2回目の結果を記録する。

## Test R-1: 修正後自動テスト

### 実行

```powershell
.\tests\Run-PhaseFTests.ps1
.\tests\Run-PhaseFTests.ps1 -Desktop
```

### 期待結果

- 両方ともExit Code 0
- FAILなし
- DesktopテストでPENDINGなし
- Assertion数は追加テストにより初回138件より増えていてよい

### 結果

- [x] PASS
- [ ] FAIL

記録:

```text

```

---

## Test R-2: NumLock物理入力 + ON固定（旧Global Action仕様の履歴）

### 手順

1. Controllerを終了し、NumLockをOFFにする。
2. Controllerを起動し、NumLockがONになることを確認する。
3. 物理NumLockを5回、1回ずつ押す。
4. 各押下で `Auto Bind completed` が表示されることを確認する。
5. 各押下後にNumLockがONのままであることを確認する。

### 期待結果

- 通常NumLockは物理SC145としてControllerへ届く
- NumLock本来のON/OFF Toggleは発生しない
- 5回すべてAuto Bind Allとして動作する
- NumLockは常にON

### 結果

- [ ] PASS
- [x] FAIL

記録:

```text
症状としては前回と同じ。
Auto Bind completedは表示されない。
Key history and script info に NumLock を押した際にキー入力が記録されない。
キーボード側にあるPauseキーは認識される。(Pause=VK:13,SC:045,Elapsed key:Pause)
```

---

## Test R-3: Ctrl + NumLock Clear All（旧Global Action仕様の履歴）

AutoHotkey / WindowsではCtrlを押したNumLockは `Ctrl + Pause` として報告されるため、
修正版ではこの経路を専用Hotkeyとして扱う。

### 手順

1. Numpad0へ任意WindowをManual Bindする。
2. Explorer等を専用SlotへAuto Bindする。
3. `Ctrl + NumLock` を押す。
4. Numpad0および専用SlotのBindingを確認する。
5. NumLock状態を確認する。

### 期待結果

- 全BindingがClearされる
- 即時Auto Bindは行われない
- NumLockはONのまま
- ControllerがPause動作へ誤遷移しない

### 結果

- [ ] PASS
- [x] FAIL

記録:

```text

```

---

## Test R-4: Ctrl + 000 Manual Bindの安定性

### 目的

初回修正版で行った120ms拡張の結果を記録する。
その後のR-7ログ解析により、失敗原因は時間超過ではなく途中Interruptと判明したため、
現在の実装は通常 / Modifier付きとも80msへ戻し、同一Modifier状態の再DownだけをInterrupt対象外としている。
現行修正版の再確認はR-9で行う。

### 手順

1. Window Aを `Ctrl + 0` でNumpad0へ登録する。
2. Window BをForegroundにする。
3. `Ctrl + 000` でVirtual000へ登録する。
4. 別Windowへ移動し、`0` でA、`000` でBへ移動することを確認する。
5. 2～4を合計5回繰り返す。

### 期待結果

- 5回すべてCtrl+000がVirtual000として認識される
- Numpad0のBindingを誤って上書きしない
- 通常000は引き続きVirtual000として動作する

### 結果

- [ ] PASS
- [x] FAIL

初回修正版の結果（FAIL）:

```text
ctrl + Virtual000 について以下の挙動を確認。
・ctrlキーをdownさせ、000を押すと000に登録できる。
・000に登録後、ctrlキーをdownさせ続け、000を押すと0に登録されてしまう。それ以降、ctrlをdown中は何度000キーを押しても0に登録される。
・ctrlキーをdownさせ、ctrlキーをupさせたあと、もう一度ctrlキーをdownさせ、000を押すと、前回の登録が0でも、000で登録できる。これは000に正常登録した後でも、0に誤登録したあとでも同じ挙動。
```

---

## Test R-5: Numpad0 Clear後の通知Regression

### 手順

1. Numpad0へWindowをManual Bindする。
2. `Ctrl + Shift + 0` でClearする。
3. 前のToolTipが確実に消えるよう1.5秒以上待つ。
4. `0` を1回押す。

### 期待結果

- `No window found: Zero` が表示される
- `Auto Bind completed` は表示されない
- Numpad0はNoneのまま

### 結果

- [x] PASS
- [ ] FAIL

記録:

```text

```

---

## Test R-6: NumLock終了時復元

### Case A

```text
起動前: OFF
実行中: ON
終了後: OFF
```

### Case B

```text
起動前: ON
実行中: ON
終了後: ON
```

正常終了はTray IconからExitして行う。

### 結果

- [ ] PASS
- [x] FAIL

記録:

```text

```

---

## Test R-7: Debug診断（R-4またはR-5失敗時のみ）

R-4またはR-5がFAILした場合だけ実施する。

1. `NumpadWindowController.ahk` の `DEBUG_ENABLED := false` を一時的に `true` にする。
2. R-4 / R-5を再現する。
3. `logs/NumpadWindowController_<timestamp>.log` から以下を記録する。

確認対象:

- `Input dispatch: <Logical Id> / <Modifier>`
- `Zero input: kind=... tick=... modifier=...`
- `Zero queued: Numpad0|Virtual000 / <Modifier> elapsed=...`

試験後は `DEBUG_ENABLED := false` へ戻す。

記録:

```text
Drive log: NumpadWindowController_20260925022556.log

R-7確認結果:
- 成功するCtrl+000では D-U-D-U-D-U が最後まで成立し、Virtual000 / Ctrlへ確定する。
- 失敗するCtrl+000では途中に Interrupt が発生し、DUD / DUDU / DUDUD 等の途中状態でNumpad0へフォールバックする。
- 失敗は120msの時間超過ではなく、非SC052 KeyDownによるInterruptが直接原因。
- 修正版ではInterrupt発生時のvk/sc/ignoredをログへ追加済み。R-9で割込み元キーを確認する。
```

---

## Test R-8: NumLock Input PoC

### 目的

外付けテンキーNumLockが、AutoHotkey Keyboard HookまたはWindows Raw Inputへ実際に届いているかを確定する。

### 前提

本体NumpadWindowControllerと他のKeyboard Hookを終了する。

### 実行

```text
poc/NumLockInputPoC.ahk
```

### 手順

1. PoCを起動する。
2. F6を押し、外付けテンキーNumLockを5回押す。
3. F7を押し、Ctrlを押したまま外付けテンキーNumLockを5回押す。
4. F8を押し、通常KeyboardのPauseを2回押す。
5. F9でログを開く。
6. PoCを終了する。

### 確認観点

ログの `AHK ...` と `RAW ...` を比較する。

- AHK + RAW: 通常のKeyboard入力として捕捉可能。
- RAWのみ: 本体にRaw Input経路を追加する候補。
- AHK / RAWとも無し、Pauseは記録あり: 外付けテンキー内部処理の可能性が高く、NumLock Global Function設計を再検討する。

### 結果

- [ ] AHK + RAWでNumLockを観測
- [ ] RAWのみでNumLockを観測
- [x] NumLockはAHK / RAWとも観測されない
- [ ] 判定不能

ログ:

```text
Drive log: numlock_input_poc_20260925025920.log

通常NumLock:
- AHK / RAWともNumLock相当Eventなし。

Ctrl+NumLock:
- Left Ctrlのみ記録。
- NumLock相当Eventなし。

Pause比較:
- AHK / RAW双方で正常にPause Eventを記録。

結論:
- PoCは正常。
- 外付けテンキー物理NumLockはWindowsへKeyboard Eventを送らないと判断。
- NumLock Global Action仕様を廃止し、NumpadEnter Modifier Combinationへ移行する。
```

---

## Test R-9: Ctrl押下継続中の000 Regression

### 目的

同一Modifier状態のCtrl再DownをZero Detectorが誤Interruptとして扱わないことを確認する。

### 手順

1. 任意WindowをForegroundにする。
2. CtrlをDownしたまま維持する。
3. 物理000を5回、約0.5～1秒間隔で押す。
4. Ctrlを離す。
5. 各000がVirtual000へのManual Bindとして扱われたか確認する。
6. 可能ならDebugを有効にして同じ操作を再実施する。

### 期待結果

- 5回すべて `Virtual000 / Ctrl` として処理される。
- Numpad0への誤Manual Bindが発生しない。
- Modifier再Downが割込んだ場合は `Zero interrupt ... ignored=1` と記録される。
- Modifier以外の割込みは `ignored=0` となり、従来どおり000候補を中断する。

### 結果

- [x] PASS
- [ ] FAIL

成功回数:

```text
5/5
```

Debug記録:

```text

```

---

## Test R-10: 新Global Action自動テスト

### 実行

```powershell
.\tests\Run-PhaseFTests.ps1
.\tests\Run-PhaseFTests.ps1 -Desktop
```

### 期待結果

- 両方ともExit Code 0
- FAILなし
- `Input_GlobalHotkeyPlan()` が `SC11C` のCtrl / CtrlShiftだけをGlobal Actionとして登録する
- NumpadEnterのGeneric PlanからCtrl / CtrlShiftが除外される
- Standard Enter `SC01C` がGlobal Action Planへ含まれない

### 結果

- [x] PASS
- [ ] FAIL

記録:

```text

```

---

## Test R-11: NumpadEnter Global Action（初回確認・判定保留）

### 手順

1. Numpad0等へManual Bindを1つ作成する。
2. 専用Slot 1～9の一部をClearする。
3. `Ctrl + NumpadEnter` を押す。
4. 専用Slotが補充され、Manual Bindが維持されることを確認する。
5. Auto / Manual Bindingを複数作成する。
6. `Ctrl + Shift + NumpadEnter` を押す。
7. 全BindingがClearされることを確認する。

### 期待結果

- `Ctrl + NumpadEnter` = Auto Bind All
- `Ctrl + Shift + NumpadEnter` = Clear All
- Clear All直後に自動再Bindingしない
- Configurationは変更されない

### 結果

- [ ] PASS
- [x] FAIL

記録:

```text
Ctrl + Shift + Numpad で各スロットをClearした際、自動で再Bindされてしまう。
```

### 判定補足

このFAILだけでは、Clear All直後に自動再Bindingされたのか、
Clear後の確認として専用Slotキー（1～9）を押した結果、仕様どおりLazy Auto Bindが発動したのかを区別できない。

本体実装の `Binding_Clear()` 自体は `AutoBind_Run()` を呼ばない。
したがってR-11は「初回確認・判定保留」とし、R-13でClear All直後の状態とLazy Auto Bindをログで分離して再判定する。

---

## Test R-12: NumpadEnter / Standard Enter分離と誤操作防止

### 手順

1. NumpadEnter単押しの現在Config Actionを確認する。
2. NumpadEnterを単押しし、Auto Bind All / Clear Allが発火しないことを確認する。
3. 通常Keyboard EnterをText入力欄で5回押す。
4. 通常Keyboard側で `Ctrl + Enter` と `Ctrl + Shift + Enter` を試す。
5. テンキー側で `Ctrl + NumpadEnter` / `Ctrl + Shift + NumpadEnter` を再確認する。

### 期待結果

- NumpadEnter単押しはConfigどおりの通常Action
- 単押しでGlobal Actionは発火しない
- Standard Enterは通常Enterとして動作する
- Standard EnterのCtrl系CombinationでGlobal Actionは発火しない
- Global ActionはNumpadEnter `SC11C` でのみ発火する

### 結果

- [x] PASS
- [ ] FAIL

記録:

```text

```

---

## Test R-13: Clear All直後 / Lazy Auto Bind分離再試験

### 目的

R-11で観測した「Clear後に再Bindされた」現象が、

1. Clear All自身が即時Auto Bindしている不具合
2. Clear後に専用Slotキーを押したことで仕様どおりLazy Auto Bindした

のどちらかを確定する。

### 前提

1. `NumpadWindowController.ahk` の `DEBUG_ENABLED := true` にする。
2. Controllerを再起動する。
3. Auto / Manual Bindingを複数作成する。

### 手順A: Clear All直後を確認

1. `Ctrl + Shift + NumpadEnter` を1回だけ押す。
2. **その後、1～9、Ctrl+NumpadEnter、Ctrl+Alt+Keyを押さない。**
3. 1～2秒待つ。
4. Controllerを正常終了する。
5. 最新の `logs/NumpadWindowController_<timestamp>.log` を確認する。

### 期待ログ

Clear All操作に対して、概ね次の順序になる。

```text
Global input dispatch: ClearAll
Clear: All
Slots:
Numpad0 None ...
Numpad1 None ...
...
Numpad9 None ...
...
```

このClear Allと次の意図的操作の間に、次のログが**存在しない**こと。

```text
Auto Bind start:
```

### 手順B: Lazy Auto Bindを意図的に確認

1. Controllerを再起動する。
2. `Ctrl + Shift + NumpadEnter` でClear Allする。
3. Clear直後に専用Slotの `1` を1回押す。
4. ログを確認する。

### 期待結果

- Clear All直後は全BindingがNone。
- Clear All自身はAuto Bindを開始しない。
- その後 `1` を押した時点でExplorer用Lazy Auto Bindが発動する。
- このLazy Auto Bindは仕様どおりであり、Clear Allの失敗とは扱わない。

### 結果

- [ ] PASS
- [ ] FAIL

記録:

```text

```

### 復旧

試験後、`DEBUG_ENABLED := false` に戻す。

---

## Test R-14: NumLock lifecycle再試験

### 目的

旧F-13～F-15でFAILとなったNumLock lifecycleを、Global Action用途から切り離して再確認する。

確認対象:

- 起動前状態の保存
- 起動後ON固定
- 実行中のON維持
- 正常終了時の起動前状態復元

### 重要

外付けテンキーの物理NumLockはPoCでWindowsへKeyboard Eventを送らないことが確認済みである。
**初期状態の変更・確認には外付けテンキーのNumLockを使用しない。**

Windowsが認識する通常Keyboard側NumLock、またはWindowsスクリーンキーボード（`osk.exe`）を使用する。

### Case A: 起動前OFF → 実行中ON → 終了後OFF

1. Controllerを終了する。
2. Windows側NumLockをOFFにする。
3. `osk.exe` 等でOFFを確認する。
4. Controllerを起動する。
5. Windows側NumLockがONになったことを確認する。
6. 実行中に通常Keyboard側NumLockを1回押し、OFFへ切り替わらずONが維持されることを確認する。
7. AutoHotkey Tray IconからControllerを正常終了する。
8. Windows側NumLockがOFFへ復元されたことを確認する。

期待:

```text
起動前: OFF
実行中: ON
通常Keyboard NumLock操作後: ON
終了後: OFF
```

### Case B: 起動前ON → 実行中ON → 終了後ON

1. Controller終了状態でWindows側NumLockをONにする。
2. ONを確認する。
3. Controllerを起動する。
4. 実行中ONであることを確認する。
5. AutoHotkey Tray Iconから正常終了する。
6. Windows側NumLockがONのままであることを確認する。

期待:

```text
起動前: ON
実行中: ON
終了後: ON
```

### 結果

Case A:

- [ ] PASS
- [ ] FAIL

Case B:

- [ ] PASS
- [ ] FAIL

総合:

- [ ] PASS
- [ ] FAIL

記録:

```text
Case A:
Case B:
備考:
```

### 注意

`taskkill /F`、Process強制終了、OS crash等はOnExit復元保証の対象外。

---

# 13. 異常の確認

すべての試験を通じて以下を観察する。

- [x] Scriptが予期せず終了しない
- [x] AutoHotkey Error Dialogが表示されない
- [x] 同一HWNDが複数Slotへ残らない
- [x] 操作不能になるほどHotkeyが奪われない
- [x] ToolTipが消えずに残り続けない
- [x] NumLockが異常な状態に残らない
- [x] Standard Backspace設定復旧後にBackspaceが正常動作する

異常があった場合:

```text
発生Test:
操作:
期待結果:
実際の結果:
再現性:
表示されたError:
関連するWindow/Application:
備考:
```

---

# 14. Phase F結果まとめ

## テスト結果

| Test | 内容 | 結果 |
|---|---|---|
| A-1 | 通常自動テスト | |
| A-2 | Desktop自動テスト | |
| F-1 | Active Window Manual Bind | |
| F-2 | Restore + Activate | |
| F-3 | Lazy Auto Bind + Activate | |
| F-4 | 物理0 | |
| F-5 | 物理000 | |
| F-6 | 0連続入力 | |
| F-7 | Ctrl Manual Bind | |
| F-8 | Ctrl+Shift Clear | |
| F-9 | Ctrl+Alt Auto Bind | |
| F-10 | 未定義Modifier | |
| F-11 | Disabled Backspace | |
| F-12 | Backspace Warning | |
| F-13 | NumLock OFF → 起動ON | |
| F-14 | NumLock OFF復元 | |
| F-15 | NumLock ON復元 | |
| F-16 | NumLock Auto Bind All（旧仕様・廃止） | FAIL（履歴） |
| F-17 | Ctrl+NumLock Clear All（旧仕様・廃止） | FAIL（履歴） |
| R-8 | NumLock Input PoC | PASS（AHK/RAWともNumLock Eventなし） |
| R-9 | Ctrl押下継続000 | PASS（5/5） |
| R-10 | 新Global Action自動テスト | PASS |
| R-11 | NumpadEnter Global Action（初回確認） | 判定保留（R-13で再判定） |
| R-12 | NumpadEnter / Standard Enter分離 | PASS |
| R-13 | Clear All直後 / Lazy Auto Bind分離 | |
| R-14 | NumLock lifecycle再試験 | |

---

# 15. Phase F完了判定

## 判定

初回Manual Test判定:

- [ ] PASS - Phase F完了
- [ ] CONDITIONAL PASS - Known Limitationのみ
- [x] FAIL - 修正が必要

修正後再テスト判定:

- [ ] PASS - Phase F完了
- [ ] CONDITIONAL PASS - Known Limitationのみ
- [ ] FAIL - 追加修正が必要

## 未解決事項

```text

```

## 新たに確認されたKnown Limitation

```text

```

## 修正が必要な問題

```text

```

---

# 16. テスト後に更新する文書

Phase FがPASSした場合、以下を更新する。

## `TASKS.md`

現在未チェックの以下を完了へ変更する。

```text
F-2
- [x] Backspace Warning

F-3
- [x] Active Window取得
- [x] Activate

F-9
- [x] 成功時Activate

F-12
- [x] OnExit NumLock復元
```

Phase F見出しについても「完了」へ変更する。

---

## `docs/PHASE_F_RESULT.md`

以下を追記・更新する。

- Manual Test実施環境
- 実施Commit
- Foreground Activate結果
- Manual Bind結果
- Lazy Auto Bind + Activate結果
- 物理0 / 000結果
- Modifier結果
- Backspace Warning結果
- NumLock OFF / ON復元結果
- Phase F最終判定

状態を問題なければ以下へ変更する。

```text
状態: 実装済み / 自動検証済み / 実機検証済み / Phase F完了
```

---

# 17. Phase F後の次工程

Phase F完了後はPhase Gへ進む。

Phase GではPhase FのSmoke Testより広い条件を対象とする。

主な対象:

- Configuration異常系の網羅
- Chrome 1 / 2 / 3 / 4Window以上
- Chrome位置ずれ
- Chrome最小化 / 再起動
- VS Code 1 / 2 / 3 / 4Window以上
- VS Code再起動 / Window Close
- Explorer / ChatGPT / PowerShell複数候補
- Shortcut全形式
- Manual / Auto優先関係
- Clear / Lazy Bind
- 数時間常駐
- Sleep / Resume
- Explorer再起動
- Script再起動

Phase Hでは、その結果を踏まえて日常操作シナリオと操作感を受入試験する。
