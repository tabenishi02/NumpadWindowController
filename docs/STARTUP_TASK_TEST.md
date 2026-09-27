# ログオン時自動起動テスト

更新日: 2026-09-28
対象: `NumpadWindowController-Logon`

## 1. 自動テスト結果

実行Commitは自動起動対応の作業中Commit。Windows PowerShell 5.1とAutoHotkey v2.0.26を使用した。

```powershell
.\tests\StartupTask.Tests.ps1
.\tests\StartupTask.Tests.ps1 -Integration
.\tests\Run-PhaseFTests.ps1
```

結果:

- Preview / Path /引数テスト: PASS（24 assertions）
- Task Scheduler一時登録・検査・解除: PASS（合計37 assertions）
- Phase F Regression: PASS（134 assertions）
- 本番Task登録・同名更新・設定照合: PASS
- 本番TaskのTask Scheduler起動: PASS（`State=Running`, `LastTaskResult=267009 / 0x41301`）

統合テストは `NumpadWindowController-Test-<PID>` と隣接する専用テストTaskを一時登録する。登録内容をExportして検査後、対象だけを削除して隣接Taskが残ること、および未登録状態で再度uninstallしても安全なことを確認した。最後に隣接Taskも削除し、テスト用タスクは残していない。

確認済み:

- タスク名とTaskPathが意図した値。
- 現在ユーザーのログオンTrigger。
- `InteractiveToken`、通常権限（Highest privilegesなし）。
- AutoHotkey v2実行ファイル、メインAHK、Working Directoryが正しい。
- AHKファイル引数が引用され、空白を含む配置先でも壊れない。
- 既定Delayは0秒、任意のDelay秒をISO 8601へ変換可能。
- Task Scheduler側の多重起動Policyは `IgnoreNew`。
- 長時間常駐を途中終了させないExecution Time Limit。
- 解除は完全一致するNumpadWindowController用タスクだけを対象とする。
- 未登録状態で解除しても異常終了しない。
- AutoHotkey本体の既存Regressionに新規FAILなし。

本番Task `NumpadWindowController-Logon` は現在ユーザーへ登録済み。登録後に同じinstallコマンドを再実行し、既存タスクを安全に更新できることを確認した。Task Schedulerから起動して常駐状態が`Running`になることも確認済み。`267009`は常駐Taskが現在実行中であることを示す正常値。

## 2. 実機ログオン試験

実際のサインアウト／ログオンが必要な項目は、次の形式で記録する。

```text
Test ID:
日時:
実施Commit:
タスク状態:
起動前NumLock:
操作:
実際の結果:
結果: PASS / FAIL / BLOCKED
備考:
```

### S-1 ログオン起動

1. `install-startup-task.ps1`を実行する。
2. `Get-ScheduledTask`でTaskがReadyか確認する。
3. Windowsからサインアウトし、同じユーザーでログオンする。
4. AutoHotkeyのトレイアイコンとテンキー操作を確認する。

期待:

- ログオン後にControllerが起動する。
- PowerShellやcmd等の不要なWindowを表示しない。
- Taskは現在ユーザーの対話型Session、通常権限で実行される。

### S-2 既存機能とNumLock

1. 起動前のWindows側NumLockをOFFにしてS-1を実施する。
2. 起動後にON固定を確認する。
3. Chrome / VS Code / Explorer / ChatGPT / PowerShell 7の切替、Manual Bind、Clear / Auto Bind、Virtual000を確認する。
4. トレイからControllerを正常終了する。

期待:

- Phase F～Hで確認済みのWindow操作を維持する。
- 実行中はNumLock ON、正常終了後は起動前のOFFへ復元する。

起動前ONでも再実施し、終了後ONを維持することを確認する。

### S-3 自動起動後の手動起動

1. S-1で自動起動済みの状態にする。
2. `NumpadWindowController.ahk`を手動起動する。
3. AutoHotkeyプロセスとトレイアイコンを確認する。
4. テンキー操作とNumLockを確認する。

期待:

- `#SingleInstance Force`により1インスタンスだけ常駐する。
- 既存インスタンスのOnExitと新インスタンスのStartupを経てもNumLock lifecycleが壊れない。
- 手動起動後も既存機能を利用できる。

### S-4 無効化・解除

1. `Disable-ScheduledTask -TaskName NumpadWindowController-Logon`を実行する。
2. サインアウト／ログオンし、自動起動しないことを確認する。
3. TaskをEnableし、必要なら再確認する。
4. `uninstall-startup-task.ps1`を実行する。
5. タスクが存在しないことを確認する。
6. 未登録状態でuninstallを再実行する。

期待:

- Disabledまたは削除後はログオン時に自動起動しない。
- 手動起動は引き続き可能。
- 二度目のuninstallも正常終了する。
- 他のScheduled Taskは変更されない。

### S-5 遅延起動

必要な環境だけで実施する。

```powershell
.\scripts\install-startup-task.ps1 -DelaySeconds 30
```

ログオン後すぐには起動せず、約30秒後に起動することを確認する。確認後はDelay 0で再登録する。

## 3. 制約

- サインアウト／ログオンそのものは自動テストに含めない。
- 通常権限のControllerは、管理者権限で起動したアプリをWindowsの権限分離により操作できない場合がある。
- リポジトリまたはAutoHotkeyを移動した場合はタスクの再登録が必要。
- 強制終了やProcess Killでは既存仕様どおりNumLock復元を保証しない。
