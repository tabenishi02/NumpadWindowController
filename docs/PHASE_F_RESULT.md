# Phase F 実装・検証結果

更新日: 2026-09-24
状態: 実装済み / 自動検証済み / 実機確認待ち

## 実装範囲

F-1～F-12の本体コードを`NumpadWindowController.ahk`へ実装した。Configurationは`KeyBindings.ini`だけを使用する。Phase A～Eの仕様変更、`lib/`への分割、常時Window監視は行っていない。

- Config構造・Mode・Allowed条件・Shortcut・0/000制約の起動時Validation。
- App State、Built-in Metadata、Window Probe、Manual Bind、Clear。
- Chrome / VS Code / Explorer / ChatGPT / PowerShellのAuto BindとLazy Auto Bind。
- Working State、Used HWND、Commit前Validationによる重複防止。
- Shortcut実行、Mode別Hotkey、InputHookによる0/000、NumLock Global操作。
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
| Input | Mode別登録Plan、実Hotkey登録API、Hook開始/停止、両0キーDisabledでHookなし、NumLock操作のDispatcher経路 |
| Zero Detector | D-U×3、80ms境界、通常0、二連打、割込み、遅延Timer、長押しRepeat抑止、Modifier Snapshot |
| Windows API | HWND/Process/Class/Title、候補列挙、Primary Work Area、実候補Auto Bind、テストWindowのRestore |
| 実行 | EXE/BAT/CMD/LNK、空白入りPath/Arguments、WorkingDirectory、Target消失時の継続 |
| 終了・診断 | Hook停止、起動前ONへのNumLock復元、通常ログなし、Debug I/O失敗の隔離 |

## 実機確認待ち

1. Foreground Activate成功と、実際にActiveなWindowのManual Bind。
2. 起動前NumLock OFFの状態保存、実行中ON固定、正常終了後OFF復元。
3. 物理0/000・Ctrl/Shift/Alt組合せ・未定義Modifier入力・Disabled入力の配信。
4. Backspaceを明示有効化した際のWarning表示と通常Keyboardへの影響。
5. 実アプリの配置、Window Close / 再起動、Chrome移動・最小化・最大化後のBinding保持。
6. 長時間常駐、Sleep/Resume、Explorer再起動などPhase G/Hの項目。

Foreground化失敗時もBindingを保持して処理継続できた。NumLock OFFはControllerを使わない単独スクリプトでも設定できなかったため、この環境ではOFF復元をPASSにできない。

## 実装詳細と制限

仕様との差分はない。次は仕様の範囲内で決めた実装詳細。

- Shiftによるテンキー名の変化を避け、Hotkeyには物理Scan Codeと`HotIf`のModifier条件を使う。定義した組合せでだけController Hotkeyが有効になる。
- 0/000の不成立列は実Down回数分のNumpad0へ変換する。長押しRepeatはPoC同様に実Upまで抑止する。
- InputHook Callbackは状態判定とQueue追加を行い、Actionは別Timerで処理する。Window監視やAuto BindのBackground Retryは行わない。
- INIはRaw読込と小さな構造Parserで重複検出とArguments保持を行う。
- Working Stateの変更中はCritical区間で入力Callbackとの書き換え競合を避ける。

既定の制限:

- 同一キーを出す入力デバイス同士は区別しない。Backspace有効化時は通常Keyboardも対象。
- Detector有効時はSC052を消費する。Virtual000がDisabledでもその3打鍵は再送しない。未定義Modifier付き0も再送しない。ネイティブ0が必要なら両方Disabledにする。
- 通常0の判定待ちは約80ms。物理的な高速三連打と000を完全には区別できない。
- Chrome新規分類はPrimary MonitorのNormal Windowのみ。VS Codeは真のOpen順を保証しない。
- PowerShellはTerminalのTitle条件に依存する。手動登録でもAllowed条件は適用される。
- HWNDは永続化しない。終了・再起動後にManual Bindingを引き継がない。
- 強制Process KillではNumLock復元を保証しない。

## 次の実機確認手順

1. PoCや他のテンキーHookを終了し、NumLockをOFFにする。本体を起動しONになることを確認する。標準Backspaceが通常入力できることを確認する。
2. ChromeをPrimary Monitorの左上・左下・右大へ通常配置し、VS Code、Explorer、ChatGPT、PowerShell 7用Terminalを開く。NumLockを押し、1～9で対応Windowへ移動することを確認する。
3. 任意WindowをActiveにし、Ctrl+0とCtrl+000で別Slotへ登録する。通常0と物理000で意図したWindowへ切り替わることを確認する。各Ctrl+Shift操作でClearする。
4. 同じWindowを別SlotへManual Bindして旧Slotが空になること、専用Slotへの異種アプリ登録が拒否されることを確認する。NumLockで有効Manual/Autoが維持されることを確認する。
5. Chromeを移動・最小化・最大化して既存Bindingから移動できることを確認する。対象を閉じて新しいWindowを開き、通常押下またはCtrl+Alt+Keyで補修する。Ctrl+NumLock直後は空、NumLock後は専用Slotだけ補充されることを確認する。
6. INIの任意SlotをShortcutへ変更して再起動する。通常押下だけ実行され、Ctrl付きは元アプリへ渡ることを確認する。Disabledと未定義Modifierも確認する。試験後は標準設定へ戻す。
7. トレイのAutoHotkeyアイコンからExitし、NumLockが起動前のOFFへ戻ることを確認する。起動前ONでも同様に試す。

結果を受けて`TASKS.md`の未チェック項目とPhase G/Hを更新する。本実装の自動検証だけで実機受入完了とはしない。
