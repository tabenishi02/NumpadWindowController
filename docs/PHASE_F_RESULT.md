# Phase F 実装・検証結果

更新日: 2026-09-25
状態: 実装済み / 自動検証済み / 実機検証済み / Phase F完了

## 2026-09-25 初回Manual Testと修正版

初回Manual Test（commit `cab10c9188cafd8cea3c3158f1175b0f3f8902ad`）では、
Window制御の主要経路はPASSした一方、特殊入力経路に修正事項が見つかった。

PASS:

- Active Window Manual Bind。
- Minimized Window Restore / Activate。
- Lazy Auto Bind + Activate。
- 通常の物理0 / 000。
- Ctrl Manual Bind、Ctrl+Alt Auto Bind、未定義Modifier。
- Backspace DisabledおよびBackspace有効化Warning。

修正対象:

- Ctrl+000のVirtual000判定が80msでは不安定。
- Numpad0 Clear後の再押下で期待外の `Auto Bind completed` 表示を1回観測。
- 通常NumLock / Ctrl+NumLockの実機Hotkey経路。
- NumLock AlwaysOnと終了時復元。

修正版では次を採用した。

- 通常NumLockは物理Scan Code `SC145` で捕捉する。
- Windows / AutoHotkey仕様に合わせ、Ctrl+NumLockは `^Pause` で捕捉する。
- NumLock Global Action後にAlwaysOnを再適用し、ON状態を検証する。
- 通常0/000の判定窓80msは維持する。
- 初回修正ではModifier付き000を120msへ拡張したが、ログ解析で時間超過が原因ではないと判明したため80msへ戻した。
- Debug時にLogical DispatchとZero Detectorのtick / elapsedを記録する。
- 自動テストへ専用NumLock Hotkey定義とModifier別000境界を追加する。

### Backspace記録の訂正

初回Manual Testには「物理キーはDELでありBackspaceではない」とする記録があったが、
これはユーザーの誤認だったため撤回した。

実機の物理キー表記もBackspaceであり、DELであるという事実はない。
したがって `Key-Backspace` / `Backspace` の現行設定・命名を維持し、
KeypadDel等への名称変更は行わない。

再テストは `docs/PHASE_F_MANUAL_TEST.md` のR-1～R-7を使用する。

## 2026-09-25 Ctrl+000ログ解析とNumLock追加PoC

Driveへ保存された `NumpadWindowController_20260925022556.log` を解析した。

Ctrl+000:

- 成功時は `D-U-D-U-D-U` が31～47ms程度で完成し、`Virtual000 / Ctrl` へ確定した。
- 失敗時は15～78ms程度の途中で `Interrupt` が入り、Numpad0へフォールバックした。
- したがって120msへの判定窓拡大は原因対策ではなかった。
- 判定窓は通常 / Modifier付きとも80msへ戻す。
- 同一Modifier状態のCtrl/Shift/Alt/Win再DownだけはZero候補を中断しない。
- 新しいModifier追加や通常キーDownは従来どおりInterruptとする。
- InterruptログへVK / SC / ignoredフラグを追加した。

NumLock:

- 実機試験では外付けテンキーNumLockがAutoHotkey Key Historyに現れなかった。
- 本体側のHotkey指定だけでは原因を判定できない。
- `poc/NumLockInputPoC.ahk` を追加し、AHK InputHookとWindows Raw Inputを同時記録する。
- PoC結果が得られるまで、NumLockのGlobal Function仕様を確定済みとして扱わない。

次の実機試験は `docs/PHASE_F_MANUAL_TEST.md` のR-8 / R-9を優先する。

## 2026-09-25 NumLock PoC確定 / Global Action移行

`numlock_input_poc_20260925025920.log` を確認した。

- 通常NumLock操作はAHK InputHook / Windows Raw Inputの双方でEventなし。
- Ctrl+NumLock操作はLeft Ctrl Eventのみで、NumLock Eventなし。
- 比較用PauseはAHK / Raw Input双方で正常に観測された。
- したがってPoCは正常であり、外付けテンキー物理NumLockはWindowsへKeyboard Eventを送らないと判断する。

Global Action仕様を次へ変更した。

```text
Ctrl + NumpadEnter
→ Auto Bind All

Ctrl + Shift + NumpadEnter
→ Clear All
```

実機Key Historyで通常Enter=`VK0D/SC01C`、NumpadEnter=`VK0D/SC11C` を確認済み。
通常Keyboard EnterはGlobal Action対象外。

NumpadEnter単押しはConfigどおりの通常Actionを維持する。
Window ModeでもCtrl / Ctrl+ShiftはManual Bind / Slot ClearではなくGlobal Actionとして予約する。

NumLockの状態保存 / ON固定 / 正常終了時復元要件は今回変更しない。

Ctrl+000はR-9で5/5 PASSし、割込み元がLeft Ctrl (`vk=A2/sc=01D`) であることと、修正版で `ignored=1` として正しく無視されることを確認した。

R-10 / R-12はPASS。R-13でR-11の再Bindingが仕様どおりのLazy Auto Bindと確定し、R-14でNumLock lifecycleもPASSした。

## 実装範囲

F-1～F-12の本体コードを`NumpadWindowController.ahk`へ実装した。Configurationは`KeyBindings.ini`だけを使用する。Global Action変更はPhase A～E仕様へ反映済み。`lib/`への分割、常時Window監視は行っていない。

- Config構造・Mode・Allowed条件・Shortcut・0/000制約の起動時Validation。
- App State、Built-in Metadata、Window Probe、Manual Bind、Clear。
- Chrome / VS Code / Explorer / ChatGPT / PowerShellのAuto BindとLazy Auto Bind。
- Working State、Used HWND、Commit前Validationによる重複防止。
- Shortcut実行、Mode別Hotkey、InputHookによる0/000、NumpadEnter Modifier CombinationによるGlobal操作。
- ToolTip、Backspace起動Warning、任意DebugログとSlot Snapshot。

## 自動検証

実行環境: Windows / AutoHotkey v2.0.26 x64。

```powershell
# Config・状態計算・入力判定・読み取り中心の確認
.\tests\Run-PhaseFTests.ps1

# Hook登録、NumLock、テストWindow、Shortcut実行を追加
.\tests\Run-PhaseFTests.ps1 -Desktop

# AutoHotkeyの配置が異なる場合
.\tests\Run-PhaseFTests.ps1 -AutoHotkeyPath '<AutoHotkey v2 executable>' -Desktop
```

本体を直接includeして検証するため、本体全体がAHK v2で構文解析される。通常起動処理はinclude時には呼び出さない。テストは一時DirectoryにFixtureを作成し、終了時に削除する。`-Desktop`は短時間Hookを登録し、NumLockとテストWindowを操作するため、実行中のキー操作を避ける。終了時は元のNumLock状態とForeground Windowへの復元を試みる。

最終実行結果:

```text
PENDING: foreground activation / active-window manual binding (desktop did not grant foreground).
PENDING: NumLock 0 restoration (environment does not allow setting initial toggle).
PASS 136 assertions (AHK 2.0.26)
```

PASSは確認できたassertionの件数であり、PENDINGを含めた受入合格ではない。

| 領域 | 確認済み |
|---|---|
| Config | 18Section、BOM、不存在、不正Version/Mode、未知・不足・重複Section/Field、Mode別Field、Allowed整合、Backspace既定Disabled、0/000制約 |
| Shortcut Validation | Windows実行ファイル検索、対応拡張子、Target不存在、ps1拒否、作業Directory不存在、引数引用符保持 |
| Binding | Manual登録・移動、Allowed拒否時の保持、Disabled拒否、1 HWND : 1 Slot、Commit失敗時の保持、Clear / Clear All |
| Auto Bind | 合成候補によるChrome Threshold/Score・Primary判定・最大化/最小化の新規除外、VS Code逆列挙、1/2/3条件、非最小化優先、余剰候補除外、既存Manual/Auto維持、例外時のState保持 |
| Lazy | 無効HWND解除、候補なし時None、対象外Groupの保持、Manual専用Slotの非補充 |
| Input | Mode別登録Plan、実Hotkey登録API、Hook開始/停止、両0キーDisabledでHookなし、NumpadEnter Global Action経路、Standard Enter非対象 |
| Zero Detector | D-U×3、80ms境界、通常0、二連打、割込み、遅延Timer、長押しRepeat抑止、Modifier Snapshot |
| Windows API | HWND/Process/Class/Title、候補列挙、Primary Work Area、実候補Auto Bind、テストWindowのRestore |
| 実行 | EXE/BAT/CMD/LNK、空白入りPath/Arguments、WorkingDirectory、Target消失時の継続 |
| 終了・診断 | Hook停止、起動前ONへのNumLock復元、通常ログなし、Debug I/O失敗の隔離 |

## 最終再テスト結果

R-8 NumLock PoCで、外付けテンキー物理NumLockがAHK / Raw Inputの双方へEventを送らないことを確定した。
R-9 Ctrl+000 Regressionは5/5 PASS。
R-10 新Global Action自動テストはPASS。
R-12 NumpadEnter / Standard Enter分離はPASS。

R-13ではDriveログを確認し、Clear All直後は全SlotがNoneのままで即時Auto Bindが発生しないことを確認した。
その後Numpad1 / Numpad2を押した時点でだけExplorer / ChatGPTのLazy Auto Bindが発生している。
したがってR-11で観測した再BindingはClear Allの不具合ではなく、仕様どおりのLazy Auto Bindだった。

確認ログ:

- `NumpadWindowController_20260925065317.log`: Clear All後、Shutdownまで `Auto Bind start:` なし。
- `NumpadWindowController_20260925065458.log`: Clear All後、Numpad1 / Numpad2押下時にだけLazy Auto Bind。

R-14ではNumLock lifecycleを再確認し、以下をPASSした。

- 起動前OFF → 実行中ON → 正常終了後OFF。
- 起動前ON → 実行中ON → 正常終了後ON。
- 実行中に通常Keyboard側NumLockを操作してもON固定を維持。

以上によりPhase F完了条件を満たした。Phase F固有の未解決事項はない。

## Phase F最終判定

**PASS - Phase F完了**

確認済み:

1. Window Manual Bind / Restore / Activate。
2. Lazy Auto Bind。
3. 物理0 / Virtual000とModifier付き000。
4. NumpadEnter Global Action。
5. Standard Enterとの分離。
6. Clear AllとLazy Auto Bindの分離。
7. NumLock ON固定と正常終了時復元。
8. Backspace安全方針。
9. 1 HWND : 1 Slot整合性。

旧NumLock Global ActionのFAILは廃止仕様の履歴であり、現行仕様の未解決事項ではない。
次工程はPhase Gの網羅的機能テスト。

Phase G/HはPhase Fより広い条件の機能テスト・受入試験として別工程で実施する。
