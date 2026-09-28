# PROJECT_HANDOFF

更新日: 2026-09-28  
対象: NumpadWindowController  
状態: **v0.2.0 Released / ログオン時自動起動統合済み**

## 現在地点

Phase A～IのMVP工程は完了している。

現在のVersion / Release関係:

- Repository: **Public**
- 最新の公開Release: **v0.2.0**
- `v0.2.0` Tag / GitHub Release: **公開済み**
- `v0.1.0`: 初回MVP Release
- License: MIT

`v0.1.0` は自動起動機能追加前の初回MVP Release。`v0.2.0` はWindows Task Schedulerによるログオン時自動起動を追加した現行Release。

## 主要成果物

- `NumpadWindowController.ahk`: AutoHotkey v2本体
- `KeyBindings.ini`: 標準Config / UTF-16 LE BOM
- `examples/KeyBindings.example.ini`: 配布用Config例
- `scripts/install-startup-task.ps1`: ログオン時自動起動Taskの登録・更新
- `scripts/uninstall-startup-task.ps1`: 自動起動Taskの解除
- `tests/PhaseF.Tests.ahk`: Controller自動テスト
- `tests/Run-PhaseFTests.ps1`: Controllerテスト実行入口
- `tests/StartupTask.Tests.ps1`: Task Scheduler自動起動テスト
- `docs/STARTUP_TASK_TEST.md`: 自動起動試験結果
- `docs/MVP_DESIGN.md`: 現行v0.2.0設計
- `docs/KNOWN_LIMITATIONS.md`: 現行制限
- `CHANGELOG.md`: Version差分
- `README.md`: 利用者向け導入・操作・自動起動手順

## Controller Core

既定Slot:

- 7 / 8 / 9 = Chrome
- 4 / 5 / 6 = VS Code
- 1 = Explorer
- 2 = ChatGPT Desktop
- 3 = PowerShell 7用Windows Terminal

操作:

| 操作 | 動作 |
|---|---|
| Key | Window Activate / Shortcut |
| Ctrl + Key | Manual Bind |
| Ctrl + Shift + Key | Slot Clear |
| Ctrl + Alt + Key | Group / Slot Auto Bind |
| Ctrl + NumpadEnter | Auto Bind All |
| Ctrl + Shift + NumpadEnter | Clear All |

任意Slotは一般Window Auto Bindを行わずManual専用。Backspaceは標準Disabled。

Auto Bindは有効なManual / Auto Bindingを維持し、無効BindingだけNoneへ落として専用Slotの欠損を補修する。

## 0 / 000 / NumLock

物理000はNumpad0 `SC052` のD-U×3として届く。

最初のDownから80ms以内の `D-U-D-U-D-U` を `Virtual000` とする。

対象実機の物理NumLockはAHK InputHook / Raw Input双方でEventなし。Controller Actionには使用しない。

Windows側NumLockは:

1. Config Validation後に起動前状態保存
2. 実行中ON固定
3. 正常終了時に復元

強制終了時の復元は保証しない。

## ログオン時自動起動

正式方式はWindows Task Scheduler。

登録:

```powershell
.\scripts\install-startup-task.ps1
```

明示的なAutoHotkey v2 Path:

```powershell
.\scripts\install-startup-task.ps1 -AutoHotkeyPath 'C:\Program Files\AutoHotkey\v2\AutoHotkey64.exe'
```

任意Delay:

```powershell
.\scripts\install-startup-task.ps1 -DelaySeconds 30
```

解除:

```powershell
.\scripts\uninstall-startup-task.ps1
```

Task仕様:

- Task Name: `NumpadWindowController-Logon`
- Current user Logon Trigger
- InteractiveToken
- Least privilege / 通常権限
- Working Directory = Repository Root
- MultipleInstances = `IgnoreNew`
- ExecutionTimeLimit = unlimited
- 本体側は `#SingleInstance Force`

RepositoryまたはAutoHotkeyのPathを変更した場合は再登録する。

通常権限のControllerは、管理者権限ApplicationをWindowsの権限分離により操作できない場合がある。

## 検証状況

Controller:

- Phase F: 完了
- Phase G: 65 / 65 PASS
- Phase H: 16 / 16 PASS
- 未解決FAIL / BLOCKEDなし

自動起動:

- Preview / Path / Arguments: 24 assertions PASS
- Task Scheduler Integration: 37 assertions PASS
- Phase F Regression after startup addition: 134 assertions PASS
- Production Task登録 / 更新 / 定義照合: PASS
- Task Schedulerからの起動: PASS
- 実ログオン起動: PASS
- 自動起動後の既存機能 / Virtual000 / NumLock: PASS
- 手動再起動・1インスタンス維持: PASS
- Task無効化 / 削除後の非起動: PASS

## Known Limitations

正本: `docs/KNOWN_LIMITATIONS.md`

主な制限:

- Chrome新規Auto BindはPrimary Monitor基準
- Minimized / Maximized Chromeは新規座標分類しない
- VS Code真のOpen順非保証
- 4つ目以降のChrome / VS Code非Auto Bind
- 任意Slot Manual専用
- HWND非永続
- Config Hot Reloadなし
- Backspaceを通常Keyboardと区別できない
- Keyboard Device単位識別なし
- Task Schedulerは現在ユーザー・通常権限で起動
- Repository / AutoHotkey Path変更時はTask再登録が必要

## 次に読む資料

利用者向け:

1. `README.md`
2. `docs/STARTUP_TASK_TEST.md`
3. `docs/KNOWN_LIMITATIONS.md`

設計:

1. `docs/MVP_DESIGN.md`
2. `docs/DESIGN_DRAFT.md`
3. Phase A～E仕様書

検証履歴:

1. `docs/PHASE_F_RESULT.md`
2. `docs/PHASE_G_RESULT.md`
3. `docs/PHASE_H_RESULT.md`
4. `docs/PHASE_I_RESULT.md`
5. `docs/STARTUP_TASK_TEST.md`

## 次の作業

v0.2.0のRelease作業は完了済み。

今後の候補:

- v0.2.x bugfix
- v0.3.0以降の機能追加
- Private vulnerability reporting設定の確認
- GitHub Secret scanning alertの継続確認

公開済みTagを後から移動して内容を書き換える運用は採用しない。
