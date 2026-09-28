# Numpad Window Controller

Windows上で、一般的なテンキーを「ウィンドウ直接切り替え＋ショートカット実行用コントローラー」として利用するためのツールです。

AutoHotkey v2を利用し、設定可能なテンキーキーに `Window / Shortcut / Disabled` の動作種別を割り当てます。Global操作はNumpadEnterのCtrl系Modifier Combinationへ予約します。

## 現在の段階

現在は **Phase H完了 / ログオン時自動起動対応済み** です。本体実装と機能・実機受入試験は完了しています。通常運用ではWindowsタスクスケジューラによる自動起動を使用でき、開発・テスト時は従来どおり手動起動できます。次は設計・README・サンプル設定・Known Limitations・バージョン・初期リリース可否を整理してMVP初期版を完成させます。

- [Phase F実装・検証結果](docs/PHASE_F_RESULT.md)
- [Phase Gテスト手順](docs/PHASE_G_TEST.md)
- [Phase Gテスト結果](docs/PHASE_G_RESULT.md)

- [MVP設計書](docs/MVP_DESIGN.md)
- [Phase A仕様](docs/PHASE_A_SPEC.md)
- [Phase B PoC手順](docs/PHASE_B_POC.md)
- [Phase B結果](docs/PHASE_B_RESULT.md)
- [Phase C仕様](docs/PHASE_C_SPEC.md)
- [Phase D仕様](docs/PHASE_D_SPEC.md)
- [Phase E仕様](docs/PHASE_E_SPEC.md)
- [暫定設計](docs/DESIGN_DRAFT.md)
- [設計引き継ぎ](PROJECT_HANDOFF.md)
- [実装タスク一覧](TASKS.md)
- [000キー識別PoC](poc/README.md)

## 自動起動（通常運用）

正式な自動起動方式はWindowsタスクスケジューラです。現在のユーザーがWindowsへログオンした時に、対話型デスクトップセッションでAutoHotkey v2を直接起動します。ターミナルWindowは表示せず、通常権限で実行します。

リポジトリRootで次を実行します。管理者権限は通常不要です。

```powershell
.\scripts\install-startup-task.ps1
```

既定タスク名は `NumpadWindowController-Logon` です。同名タスクがあれば現行リポジトリ・AutoHotkeyの設定で更新します。AutoHotkey v2を自動検出できない場合は明示できます。

```powershell
.\scripts\install-startup-task.ps1 -AutoHotkeyPath 'C:\Program Files\AutoHotkey\v2\AutoHotkey64.exe'
```

既定は遅延なしです。ログオン直後の負荷を避けたい場合は、同じコマンドでタスクを更新します。

```powershell
.\scripts\install-startup-task.ps1 -DelaySeconds 30
```

登録内容と直近の実行情報は次で確認できます。

```powershell
Get-ScheduledTask -TaskName 'NumpadWindowController-Logon' |
    Select-Object TaskName, State, Principal, Actions, Triggers
Get-ScheduledTaskInfo -TaskName 'NumpadWindowController-Logon'
```

長時間常駐中はタスクの `State` が `Running` になります。タスクを実行したまま一時的に次回ログオンの自動起動だけ止める場合は、無効化・再有効化します。

`LastTaskResult=267009`（`0x41301`）は「現在実行中」を表し、常駐中は正常です。

```powershell
Disable-ScheduledTask -TaskName 'NumpadWindowController-Logon'
Enable-ScheduledTask -TaskName 'NumpadWindowController-Logon'
```

登録を完全に解除する場合は次を実行します。未登録でも正常に終了し、同名のNumpadWindowController用タスク以外は変更しません。

```powershell
.\scripts\uninstall-startup-task.ps1
```

無効化または登録解除は次回以降の自動起動を止めます。現在実行中のControllerは、必要に応じてトレイのAutoHotkeyアイコンから終了してください。

## 手動起動（開発・テスト・代替運用）

AutoHotkey v2をインストールしたWindowsで、`NumpadWindowController.ahk`と`KeyBindings.ini`を同じDirectoryに置き、本体を起動してください。終了はトレイのAutoHotkeyアイコンからExitを選びます。PoCと同時には起動しないでください。

自動起動タスクを登録済みでも手動起動できます。本体の `#SingleInstance Force` により、既存インスタンスを正常終了させて新しいインスタンスへ置き換えるため、複数常駐しません。置き換え時も既存のOnExit処理と新しい起動処理によりNumLock状態を引き継ぎます。

`KeyBindings.ini`はUTF-16 LE BOMを維持して編集し、反映には本体を再起動します。標準設定ではShortcutは未登録、BackspaceはDisabledです。詳細な設定形式とShortcut例は[Phase D仕様](docs/PHASE_D_SPEC.md)を参照してください。個人用Path等を含む実設定はコミットしないでください。

| 操作 | 動作 |
|---|---|
| Key | Window切替 / Shortcut起動 |
| Ctrl + Key | Active WindowをManual Bind |
| Ctrl + Shift + Key | Slot Clear |
| Ctrl + Alt + Key | 専用Slot / Groupの欠損補修 |
| Ctrl + NumpadEnter | 有効Bindingを維持してAuto Bind All |
| Ctrl + Shift + NumpadEnter | 全Binding解除 |

通常Keyboard Enterは `SC01C`、NumpadEnterは `SC11C` と実機確認済みで、Global操作はNumpadEnterだけを対象にします。

実行中はNumLockをON固定し、正常終了時に元の状態へ戻します。0/000判定中はSC052を消費し、未定義Modifier付き0も再送しません。通常の0入力を維持したい場合はNumpad0とVirtual000を両方Disabledにしてください。

検証は`.\tests\Run-PhaseFTests.ps1`で実行できます。デスクトップ操作を伴う確認と既知の制限は[Phase F検証結果](docs/PHASE_F_RESULT.md)に記載しています。

自動起動スクリプトの非変更テストは次で実行できます。Task Schedulerへの一時登録を伴う統合テストは `-Integration` を追加します。

```powershell
.\tests\StartupTask.Tests.ps1
.\tests\StartupTask.Tests.ps1 -Integration
```

## 自動起動のトラブルシューティング

### ログオンしても起動しない

`Get-ScheduledTask` でタスクが `Disabled` になっていないか確認し、`Get-ScheduledTaskInfo` の `LastRunTime` と `LastTaskResult` を確認してください。タスクを選択してTask Schedulerから手動実行し、トレイのAutoHotkeyアイコンとテンキー操作も確認します。実行ファイルやリポジトリを移動した場合は、installスクリプトを再実行してタスクの絶対パスを更新します。

### AutoHotkey v2が見つからない

AutoHotkey v2をインストールするか、installスクリプトへ `-AutoHotkeyPath` を指定してください。v1実行ファイルは登録時に拒否します。

### タスクは存在するが実行に失敗する

タスクのActionがAutoHotkey v2、Argumentsが現在の `NumpadWindowController.ahk`、Working Directoryが現在のリポジトリRootになっているか確認してください。必要ならinstallスクリプトを再実行します。詳細はイベントビューアーの「Applications and Services Logs → Microsoft → Windows → TaskScheduler → Operational」でも確認できます。

### 管理者権限で起動しているアプリを操作できない

本タスクは安全な既定値として通常権限で実行します。Windowsの権限分離により、管理者権限のアプリへHotkey送信やWindow操作が届かない場合があります。対象アプリも通常権限で起動する運用を推奨します。

### 手動起動しても複数起動しない

`NumpadWindowController.ahk` の `#SingleInstance Force` が既存インスタンスを置き換えます。Task Scheduler側も `IgnoreNew` を設定しているため、同じタスクの重複開始を抑止します。

## 現時点の主要方針

- Windows 11
- AutoHotkey v2
- 一般的なUSBテンキーを利用
- 実機で確認したKey Name / VK / SCを設計資料に記録
- 設定可能キーは `Window / Shortcut / Disabled`。Ctrl+NumpadEnter / Ctrl+Shift+NumpadEnterは予約Global Combination
- Shortcut設定キーはWindow Binding対象外
- `000` キーは高速な `Numpad0` D-U×3を検出し、仮想キー `Virtual000` として利用
- `7 / 8 / 9` はChrome専用
- Chrome優先3ウィンドウは画面上の座標で自動割り当て
- `4 / 5 / 6` はVS Code専用
- VS Code優先3ウィンドウは未使用候補を逆列挙順で4→5→6へ簡易自動割り当て
- `1 / 2 / 3` の既定用途はExplorer / ChatGPTデスクトップ / pwsh
- 4つ目以降のChrome / VS Codeは自動割り当てせず、必要な場合だけ任意SlotへManual Bind
- HWNDはRuntime Bindingとして使用し、永続化しない
- Auto Bindは専用Slot 1～9の欠損補修のみ。任意SlotはManual専用
- ConfigはKeyBindings.ini（INI / ConfigVersion=1）。Auto Bind Groupはコード側固定
- MVP本体は単一AHKファイル。内部を責務Section / Prefix関数で分離
- 外付けテンキーのBackspaceは通常キーボードのBackspaceと区別できないため標準Disabled
- 通常利用では永続ログなし。必要時のみDebug Log
- 全Window Bindingを解除する機能を持つ
- Shortcutからアプリ起動やバッチファイル実行を行えるようにする

## 既定キー配置

```text
NumLock  /       *       -
未使用   任意    任意    任意

7        8       9       +
Chrome1  Chrome2 Chrome3 任意

4        5       6       Backspace
VSCode1  VSCode2 VSCode3 Disabled

1        2       3       Enter
Explorer ChatGPT pwsh    任意

0        000     .       Enter
任意     仮想キー 任意   任意
```

同じアプリを複数ウィンドウで使用する環境でも、個々のウィンドウへ直接ジャンプできることを主目的とします。
