# Changelog

このプロジェクトはSemantic Versioning形式でバージョンを管理する。

## [Unreleased]

次期Release候補: **v0.3.0**

### Added

- ConfigVersion 2
  - 1～9を含む各Slotを特定アプリ非依存でWindow / Shortcut / Disabledへ設定可能
  - Public Defaultではbuilt-in Auto Bindを無効化
- `KeyBindings.default.ini`
  - fresh clone / Release ZIP向け一般Default
  - 初回起動時にローカル `KeyBindings.ini` を自動生成
- `examples/KeyBindings.developer-workflow.ini`
  - v0.2.xまでのChrome / VS Code / Explorer / ChatGPT / PowerShell構成をLegacy Presetとして保存
- UTF-8 Configuration読込
  - UTF-8 BOMあり / なし
  - 既存UTF-16 LE BOMも継続対応
- ConfigVersion 2 Migration Guide
- GitHub Actions Windows Regression Test

### Changed

- Built-in key metadataから個人用Dedicated用途を分離
- ConfigVersion 2では旧Dedicated Slot 1～9のWindow Mode強制を廃止
- ConfigVersion 2ではChrome / VS Code Group整合Validationを適用しない
- `KeyBindings.ini` をユーザー専用・Git管理対象外へ変更
- Public DefaultでBackspace / Virtual000をDisabled
- Virtual000無効時はZero Detectorを起動せず、Numpad0を通常Hotkeyとして即時処理
- Public README / Known Limitationsを一般用途中心へ再構成

### Compatibility

- ConfigVersion 1をLegacy Developer Workflowとして引き続きサポート
- ConfigVersion 1では従来のDedicated Slot / Auto Bind / Zero Detector仕様を維持
- Startup Taskの起動方式は変更なし

### Verified

- GitHub Actions Windows runner
- AutoHotkey v2.0.28
- Controller Regression: **166 assertions PASS**
- Public ConfigVersion 2 / Legacy ConfigVersion 1 / Virtual000 ON-OFF Regression: PASS
- Phase J差分のSecret / 個人Path監査: 公開阻害要因なし

### Pending Manual Acceptance

- 一般的な物理テンキーによるPublic Default実機受入
- Virtual000無効時の物理Numpad0即時操作感確認

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
