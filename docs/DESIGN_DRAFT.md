# Numpad Window Controller - 設計確定記録

> **履歴文書:** 本書はv0.2.0までの設計確定記録です。v0.3.0ではPhase JによりPublic Default / Configurationが一般化されています。現行仕様はREADMEとPhase J資料を参照してください。

更新日: 2026-09-28  
対象バージョン: **v0.2.0**  
状態: **Finalized - Phase I反映済み**  
実装状態: **実装・機能テスト・実機受入試験完了**

> このファイルは旧 `DESIGN_DRAFT.md` のファイル名を既存リンク互換のため維持している。
> 内容はDraftではなく、Phase A～Hで確定・検証されたWindow Controller Coreと、v0.2.0で追加したログオン時自動起動を反映した設計確定記録である。
> 現行MVP全体設計は [MVP_DESIGN.md](MVP_DESIGN.md)、詳細仕様は各Phase仕様書を参照する。

---

## 1. 目的

一般的なUSBテンキーを、Windows 11上で頻繁に利用するウィンドウへ直接移動し、必要に応じてShortcutも実行できる専用コントローラーとして利用する。

同じアプリケーションを複数Windowで使用する環境でも、個々のWindowをHWNDで区別して1キーで呼び出せることを主目的とする。

---

## 2. 初期案から確定仕様への変更点

Phase A～Hの設計・PoC・実装・実機検証により、初期Draftの未確定事項は次のように確定した。

| 初期Draftの案 | v0.1.0での確定仕様 |
|---|---|
| `Window / Shortcut / Function / Disabled` | `Window / Shortcut / Disabled` の3Mode |
| NumLockへGlobal Functionを割り当てる | 物理NumLockはController Actionに使わない |
| Global Hotkey未確定 | `Ctrl + NumpadEnter` = Auto Bind All、`Ctrl + Shift + NumpadEnter` = Clear All |
| VS Codeを真のOpen順で4→5→6へ割り当てる | 未使用候補の `WinGetList` 逆順を4→5→6へ割り当てる |
| 4つ目以降のChrome / VS Codeを一般候補へ回す | 自動割り当てしない。必要時のみ任意SlotへManual Bind |
| 一般Window Auto Bind | 実装しない。任意SlotはManual専用 |
| AutoBind属性をConfigへ記録 | Auto Bind対象・Groupはコード側Built-in Metadataへ固定 |
| 1 / 2 / 3の識別条件未確定 | Explorer / ChatGPT Desktop / PowerShell 7の条件を確定 |
| Shortcut仕様未確定 | exe / bat / cmd / lnk、Arguments、WorkingDirectoryを実装 |
| Config形式未確定 | `KeyBindings.ini` / UTF-16 LE BOM / ConfigVersion=1 |
| 000判定方式検討中 | SC052のD-U×3を80ms以内で検出し `Virtual000` へ変換 |
| NumLock状態の扱い未確定 | 起動後ON固定、正常終了時に起動前状態へ復元 |

---

## 3. 対象環境

- OS: Windows 11
- AutoHotkey: v2
- 入力デバイス: 一般的なUSBテンキー
- Runtime Window識別: HWND
- Configuration: `KeyBindings.ini`
- Config Encoding: UTF-16 LE with BOM
- Config Version: 1

専用ドライバやAutoHotInterception等はv0.1.0では使用しない。

---

## 4. キーMode

各設定可能キーは次のいずれかのModeを持つ。

| Mode | 動作 |
|---|---|
| Window | WindowをBindingし、通常押下でActivate |
| Shortcut | Targetを押下ごとにRun |
| Disabled | Controller Hotkeyを登録せず、Windowsの元入力を通す |

NumLockはConfiguration対象外。

NumpadEnterの以下のModifier CombinationはModeに関係なくGlobal Actionとして予約する。

| 操作 | Global Action |
|---|---|
| Ctrl + NumpadEnter | Auto Bind All |
| Ctrl + Shift + NumpadEnter | Clear All |

通常Keyboard Enter (`SC01C`) とNumpadEnter (`SC11C`) は区別する。

---

## 5. 既定キー配置

| キー | 既定用途 |
|---|---|
| 7 / 8 / 9 | Chrome 1 / 2 / 3 |
| 4 / 5 / 6 | VS Code 1 / 2 / 3 |
| 1 | Explorer |
| 2 | ChatGPT Desktop |
| 3 | PowerShell 7用Windows Terminal |
| / * - + 0 000 . Enter | 任意Window / Shortcut / Disabledを選択可能 |
| Backspace | Disabled |
| NumLock | Controller Actionなし |

Enterは物理的に縦2行へまたがるが、論理キーは1つの `NumpadEnter` として扱う。

---

## 6. 専用Slotの識別条件

### Chrome: 7 / 8 / 9

- `AllowedProcess=chrome.exe`
- 新規Auto BindはPrimary Monitor上のNormal Windowのみ
- 座標分類で左上=7、左下=8、右大=9
- 既存Binding済みHWNDは移動・Minimize・Maximize後も有効条件を満たす限り維持

### VS Code: 4 / 5 / 6

- `AllowedProcess=Code.exe`
- 未使用候補をAuto Bind時点の `WinGetList` 逆順で空き4→5→6へ割り当て
- 真のWindow生成順・Open順は保証しない

### Explorer: 1

- `AllowedProcess=explorer.exe`
- `AllowedClass=CabinetWClass`

### ChatGPT Desktop: 2

- `AllowedProcess=ChatGPT.exe`

### PowerShell 7: 3

- `AllowedProcess=WindowsTerminal.exe`
- `AllowedClass=CASCADIA_HOSTING_WINDOW_CLASS`
- `AllowedTitleContains=PowerShell 7`

---

## 7. Runtime Binding

Runtime Bindingの正本は `App.Slots`。

各Slotは基本的に次を保持する。

- HWND
- BindingSource
  - `Manual`
  - `Auto`
  - `None`

HWNDは永続化しない。Script再起動時は新しいRuntime Stateを構築する。

Window metadataは必要時に都度取得し、永続キャッシュしない。

---

## 8. Manual Bind

Window Modeのキーに対して:

```text
Ctrl + Key
```

でActive WindowをManual Bindする。

条件:

- 対象SlotがWindow Mode
- Active WindowがAllowed条件を満たす
- `1 HWND : 1 Slot` を維持する

同一HWNDを別SlotへManual Bindした場合、旧SlotをNoneへ移す。

Allowed違反時は既存Bindingを変更しない。

---

## 9. Auto Bind

Auto Bind対象は専用Slot 1～9のみ。

Auto Bind All:

```text
Ctrl + NumpadEnter
```

処理原則:

1. 有効なManual Bindingを維持
2. 有効なAuto Bindingを維持
3. 無効BindingだけNoneへ変更
4. 空いた専用Slotだけ補充
5. Chrome → VS Code → Explorer → ChatGPT → PowerShellの順に処理
6. Working State上で計算
7. `1 HWND : 1 Slot` を最終検証してからCommit

完全再構築は:

```text
Ctrl + Shift + NumpadEnter
→ Ctrl + NumpadEnter
```

で行う。

4つ目以降のChrome / VS Codeや一般Windowを任意Slotへ自動転送しない。

---

## 10. Lazy Auto Bind

専用Slot通常押下時にBindingがNone・HWND消滅・Allowed違反なら必要な範囲だけAuto Bindを試行する。

- Chrome / VS Code: Group単位で空Slot補充
- 1 / 2 / 3: 対象Slot単位
- 任意Slot: Lazy Auto Bindなし
- Shortcut / Disabled: Lazy Auto Bindなし
- 失敗時: Noneのまま通知
- Background Retry: なし

---

## 11. Clear

### Slot Clear

```text
Ctrl + Shift + Key
```

対象SlotのRuntime Bindingのみ解除する。

### Clear All

```text
Ctrl + Shift + NumpadEnter
```

全Runtime BindingをNoneへする。

Configurationは変更しない。Clear直後に自動再Bindingは行わない。

---

## 12. 個別Auto Bind

```text
Ctrl + Alt + Key
```

- 7 / 8 / 9: Chrome Group補充
- 4 / 5 / 6: VS Code Group補充
- 1 / 2 / 3: 対象Slot補充

任意SlotはAuto Bind対象外。

---

## 13. Shortcut

Shortcut Modeでは通常押下ごとにTargetを実行する。

対応Target:

- `.exe`
- `.bat`
- `.cmd`
- `.lnk`

対応:

- `Arguments`
- `WorkingDirectory`

`.ps1` の直接Target指定は禁止し、PowerShell Scriptは:

```ini
Target=pwsh.exe
Arguments=-File "C:\Scripts\Example.ps1"
```

の形式を使用する。

Shortcutは既存Windowを検索・Activateせず、毎回TargetをRunする。

---

## 14. Numpad0 / Virtual000

実機の000キーは独立したVK / SCを持たず、Numpad0 (`SC052`) のDown/Upを3回高速送信する。

v0.1.0では:

- 最初のDownから80ms以内
- `D-U-D-U-D-U`

を検出した場合に論理キー `Virtual000` とする。

通常Numpad0も同Detectorで扱うため、確定まで最大約80ms待つ。

`Numpad0=Disabled` の場合は `Virtual000=Disabled` も必須。

両方DisabledならZero Detector自体を登録しない。

---

## 15. NumLock

外付けテンキーの物理NumLockは実機PoCでAutoHotkey InputHook / Windows Raw Inputの双方にKeyboard Eventを送らないことを確認した。

したがってController Actionには使用しない。

一方、Windows側NumLock状態については:

1. Config Validation完了後に起動前状態を保存
2. 実行中はON固定
3. 正常終了時に起動前状態へ復元

する。

強制Process Kill等でOnExitが実行されない場合は復元を保証しない。

---

## 16. Configuration

Configファイル:

```text
KeyBindings.ini
```

本体 `NumpadWindowController.ahk` と同じDirectoryへ置く。

要件:

- UTF-16 LE BOM
- `[General] ConfigVersion=1`
- Canonical 18 Key Sectionをすべて記述
- Hot Reloadなし
- 編集後はScript再起動

起動時にSection / Field / Mode / Allowed / Shortcut / Encoding等を検証し、Fatal Error時は常駐開始しない。

詳細は [PHASE_D_SPEC.md](PHASE_D_SPEC.md) を参照。

---

## 17. Startup / Shutdown

Startup:

1. Directives / Constants
2. Built-in Metadata
3. Config Read
4. Config Validation
5. Config Object生成
6. NumLock状態保存
7. OnExit登録
8. NumLock ON
9. Runtime State初期化
10. Zero Detector
11. Hotkey登録
12. Auto Bind All

Config Validation前にNumLockやHotkey等の外部状態を変更しない。

正常終了時はHook / Timer / ToolTipを停止し、NumLockを復元する。

---

## 18. Logging / Diagnostics

通常利用では永続Logを生成しない。

コード先頭のDebug設定を明示有効化した場合のみ:

```text
logs/NumpadWindowController_<timestamp>.log
```

へ診断情報を出力する。

Debug File I/O失敗はController本体の動作へ波及させない。

---

## 19. 検証結果

- Phase F: 実装・自動試験・実機Regression完了
- Phase G: 65 / 65項目 PASS
- Phase H: 16 / 16項目 PASS
- Phase H由来のFAIL / BLOCKED / 修正要求なし

詳細:

- [PHASE_F_RESULT.md](PHASE_F_RESULT.md)
- [PHASE_G_RESULT.md](PHASE_G_RESULT.md)
- [PHASE_H_RESULT.md](PHASE_H_RESULT.md)

---

## 19.1 v0.2.0 ログオン時自動起動

v0.2.0ではWindow Controller Coreを変更せず、Windows Task Schedulerによるログオン時自動起動を追加した。

正式方式:

- 現在ユーザーのLogon Trigger
- InteractiveToken
- LeastPrivilege
- AutoHotkey v2を直接Execute
- Repository RootをWorking Directoryに指定
- Task Scheduler側は `IgnoreNew`
- 本体側は `#SingleInstance Force`
- 任意Delay対応
- install / uninstall Script提供
- Preview / Integration Test提供

関連:

- `scripts/install-startup-task.ps1`
- `scripts/uninstall-startup-task.ps1`
- `tests/StartupTask.Tests.ps1`
- [STARTUP_TASK_TEST.md](STARTUP_TASK_TEST.md)

自動起動追加後もPhase F Regressionに新規FAILはなく、実ログオン、自動起動後の既存操作、NumLock lifecycle、手動再起動、Task無効化・解除までPASSしている。

---

## 20. Known Limitations

現行の制限は [KNOWN_LIMITATIONS.md](KNOWN_LIMITATIONS.md) に集約する。

主なもの:

- Chrome新規Auto BindはPrimary Monitor基準
- VS Codeの真のOpen順は保証しない
- 4つ目以降のChrome / VS Codeは自動割り当てしない
- 任意SlotはManual専用
- HWNDは永続化しない
- Config Hot Reloadなし
- Backspaceは通常Keyboardと区別不可
- USBテンキーと通常Keyboardの同一Scan Code入力をデバイス単位で区別しない

---

## 21. v0.2.0で意図的に実装しないもの

- 常設GUI
- Config編集GUI
- Config Hot Reload
- 一般Window Auto Bind
- Background Retry
- HWND永続化
- VS Code真のOpen順追跡
- Secondary Monitor向けChrome Auto Bind
- デバイス単位入力識別
- Plugin / Rule Engine
- 本体の `lib/` 分割

---

## 22. 正式仕様の参照順

矛盾がある場合は、より後で確定した具体的仕様を優先する。

1. 実装コード `NumpadWindowController.ahk`
2. Phase H / G / F検証結果
3. Phase A～Eの各仕様書
4. [MVP_DESIGN.md](MVP_DESIGN.md)
5. 本書

本書は旧Draftからの移行記録も兼ねるため、詳細実装仕様の唯一の正本ではない。
