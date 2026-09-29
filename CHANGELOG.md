# Changelog

このプロジェクトはSemantic Versioning形式でバージョンを管理する。

## [Unreleased]

Phase K「Action / Layer Architecture」を実装。

### Added

- ConfigVersion 3
  - Physical Key → Global Mapping → Active Layer → Action Dispatcher
  - RuntimeはConfigVersion 3のみをサポート
- Action Type
  - Window
  - Run
  - KeySend
  - LayerSwitch
  - Delay
  - MultiAction
  - Disabled
- Layer
  - DefaultLayer / LayerOrder
  - Global Key Mapping
  - Set / Next
- Window Toggle
  - Active Window再押下でMinimize
  - Inactive / Minimized WindowはActivate / Restore + Activate
- WindowGroup / Application Launch fallback
  - Group一致Window 0件の場合のみLaunch
  - Group単位LaunchPending / Timeout
- Virtual00
  - Virtual00 / Virtual000を同一Zero Detectorで処理
- KeySend
  - Ctrl / Shift / Alt / Win
  - Function / Navigation / Volume / Media / Browser / PrintScreen系
- MultiAction / Delay
  - 連続Step Validation
  - Nested MultiAction拒否
  - 実行中再入抑止
- `tests/PhaseK.Tests.ahk`
- `tests/Run-PhaseKTests.ps1`

### Changed

- Window Runtime Bindingの正本をPhysical Key / SlotからWindow Action IDへ変更
- Public DefaultをBase / Edit / Mediaの3 Layer構成へ更新
- Developer Workflow ExampleをConfigVersion 3へ移行
- Auto Bindを `None / FirstMatch / ReverseList / PrimaryThreePane` Strategyとして再定義
- 未Mapping KeyはNative Inputを通す方式へ変更
- README / Known LimitationsをConfigVersion 3中心へ更新
- Controller CIをPhase K Regressionへ更新

### Removed

- ConfigVersion 1 / 2 Runtime互換読込
- ConfigVersion 1 / 2専用Validation / Regression
- 旧 `tests/PhaseF.Tests.ahk` / `Run-PhaseFTests.ps1`

### Compatibility

- v0.3.0以前のUser Configは手動でConfigVersion 3へ移行が必要
- Startup Task方式は変更なし
- Phase A～J文書・Release Tagは過去仕様の履歴として保持

### Verification

- GitHub Actions Windows + AutoHotkey v2.0.28: **135 assertions PASS**
- Startup Preview Regression: **24 assertions PASS**
- Startup Task Scheduler Integration Regression: **37 assertions PASS**
- Phase K変更13ファイルのCredential / Secret / 個人User Path監査: **検出なし**
- Physical Acceptance: **未実施**

## v0.3.0 - 2026-09-29

Phase J「General-purpose Configuration / Public Default」を反映した一般公開向けConfiguration刷新Release。

### Added

- ConfigVersion 2
  - 1～9を含む各Slotを特定アプリ非依存でWindow / Shortcut / Disabledへ設定可能
  - Public Defaultではbuilt-in Auto Bindを無効化
- `KeyBindings.default.ini`
  - fresh clone / Release ZIP向け一般Default
  - 初回起動時にローカル `KeyBindings.ini` を自動生成
- `examples/KeyBindings.developer-workflow.ini`
  - v0.2.xまでのChrome / VS Code / Explorer / ChatGPT / PowerShell構成をLegacy Presetとして保存
- UTF-8 Configuration
  - UTF-8 BOMあり / なし
  - 配布INIをUTF-8 BOMなしへ統一
- ConfigVersion 2 Migration Guide
- GitHub Actions Windows Regression Test

### Changed

- Configuration INIをConfigVersionに関係なくUTF-8前提へ統一
- UTF-16 LE / BE Configurationの読込サポートを廃止
- Built-in key metadataから個人用Dedicated用途を分離
- ConfigVersion 2では旧Dedicated Slot 1～9のWindow Mode強制を廃止
- ConfigVersion 2ではChrome / VS Code Group整合Validationを適用しない
- `KeyBindings.ini` をユーザー専用・Git管理対象外へ変更
- Public DefaultでBackspace / Virtual000をDisabled
- Virtual000無効時はZero Detectorを起動せず、Numpad0を通常Hotkeyとして即時処理
- Public README / Known Limitationsを一般用途中心へ再構成

### Migration Notes

- v0.2.xの既存Git cloneでは `KeyBindings.ini` がtracked fileだったため、現在の設定を残す場合は **git pull前にバックアップ**する
- v0.2.x以前のUTF-16 LE `KeyBindings.ini` は、v0.3.0で使用する前にUTF-8へ変換する
- 旧Chrome / VS Code / Explorer / ChatGPT / PowerShell構成を継続する場合は `examples/KeyBindings.developer-workflow.ini` を `KeyBindings.ini` へコピーする
- 詳細は `docs/CONFIG_MIGRATION_V2.md` を参照

### Compatibility

- ConfigVersion 1をLegacy Developer Workflowとして引き続きサポート
- ConfigVersion 1では従来のDedicated Slot / Auto Bind / Zero Detector仕様を維持
- Startup Taskの起動方式は変更なし

### Verified

- GitHub Actions Windows runner
- AutoHotkey v2.0.28
- Controller Regression: **167 assertions PASS**
- Startup Preview Regression: **24 assertions PASS**
- Startup Task Scheduler Integration Regression: **37 assertions PASS**
- Public ConfigVersion 2 / Legacy ConfigVersion 1 / Virtual000 ON-OFF Regression: PASS
- Phase J差分のSecret / 個人Path監査: 公開阻害要因なし

### Manual Acceptance

- J-PA-1～6: PASS
- J-PA-7 NumLock lifecycle: Not Executed / N/A
  - 対象テンキーNumLockは内部入力切替として機能し、WindowsへNumLock Eventを送らない既知ハードウェア仕様
  - Windows側NumLock lifecycleはPhase F R-14で実機PASS済み
- Phase J Physical Acceptance: PASS

## v0.2.0 - 2026-09-28

Windowsログオン時自動起動を追加した正式Release。

### Added

- Windows Task Schedulerによる現在ユーザーのログオン時自動起動
- `scripts/install-startup-task.ps1`
  - AutoHotkey v2自動検出
  - 明示Path指定
  - 任意Delay
  - 同名Taskの安全な更新
  - Preview / PassThru
- `scripts/uninstall-startup-task.ps1`
  - 対象Taskだけを安全に削除
  - 未登録状態でも正常終了
- `tests/StartupTask.Tests.ps1`
  - Preview / Path / Arguments検証
  - Task Scheduler一時登録・検査・解除
  - Delay / 対象外Task保護 / 二度解除
- `docs/STARTUP_TASK_TEST.md`
  - 自動テスト・統合テスト・実ログオン試験結果

### Verified

- Startup Preview: 24 assertions PASS
- Task Scheduler Integration: 37 assertions PASS
- Phase F Regression after startup addition: 134 assertions PASS
- 実ログオンによる自動起動: PASS
- 自動起動後の既存Window操作 / Virtual000 / NumLock lifecycle: PASS
- 自動起動状態からの手動再起動・1インスタンス維持: PASS
- Task無効化 / 削除後の次回ログオン非起動: PASS

### Notes

公開済み `v0.1.0` Tagは自動起動機能追加前のCommitを指す。現在の `main` はその後の機能追加を含むため、同じ内容ではない。

## v0.1.0 - 2026-09-28

初回MVP Release。

- Window / Shortcut / Disabled Mode
- Chrome / VS Code / Explorer / ChatGPT Desktop / PowerShell 7 Auto Bind
- Manual Bind / Lazy Auto Bind / Clear
- Virtual000
- NumLock lifecycle
- UTF-16 LE BOM Configuration
- MIT License
