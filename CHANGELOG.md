# Changelog

このプロジェクトはSemantic Versioning形式でバージョンを管理する。

## [Unreleased] v0.2.0

現在の `main` が対象とするバージョン。

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
