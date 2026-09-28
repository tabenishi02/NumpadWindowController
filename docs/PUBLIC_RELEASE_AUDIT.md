# Public Release Audit

更新日: 2026-09-28  
対象: NumpadWindowController v0.1.0 initial audit + v0.2.0 delta audit  
状態: **Public repository / v0.2.0 delta audit complete**

## 1. 監査範囲

公開前に次を確認した。

- 現在のRepository Treeに存在するMarkdown / AutoHotkey / PowerShell / INI / gitignore
- ドキュメントに記載されたWindows絶対Path
- Git commit metadata
- 履歴上で確認できた削除済みPhase G Config backup
- 重複として削除されたPhase B PoCファイル
- RuntimeコードのNetwork / Telemetry処理

## 2. 秘密情報・個人情報チェック

次の代表的パターンを確認した。

- `C:\Users\<username>\...`
- Email address
- GitHub token
- OpenAI-style secret key
- AWS access key
- Private key header
- password / token / secret形式の代入
- Webhook URL
- ローカルIP / localhost URL
- 実環境由来のWindows絶対Path

### 結果

現在のRepository Treeでは、公開を妨げる個人情報・秘密情報を検出しなかった。

Windows絶対Pathとして確認されたものは、次のような一般的なSystem Pathまたは明示的なExample Pathだった。

- `C:\Windows\System32\notepad.exe`
- `C:\Program Files\Example\...`
- `C:\Scripts\Example.ps1`
- `C:\path\to\...`
- テスト用の明示的なmissing path

Git commit metadataは監査時点の全commitでGitHubのnoreply addressを使用しており、実Email addressは確認されなかった。

履歴上で誤ってcommitされた `KeyBindings.ini.phaseg.bak` は標準Configurationのcopyで、個人Pathや秘密情報を含んでいなかった。

重複削除されたPhase B PoCファイルにも、上記秘密情報パターンやユーザープロファイルPathを確認しなかった。

## 3. Privacy / Network

`NumpadWindowController.ahk` 本体にHTTP通信、Telemetry、Analytics処理は確認されなかった。

通常利用では永続Debug Logを生成しない。

Debug Logを有効化した場合はWindow title等のローカル情報を含む可能性があるため、公開共有前に内容を確認・redactする。

## 4. 公開準備として追加したもの

- MIT `LICENSE`
- `SECURITY.md`
- `CONTRIBUTING.md`
- 強化した `.gitignore`
- UTF-16 Configurationを保護する `.gitattributes`
- READMEのPrivacy / Security / License説明

## 5. 現在の公開状態

- Repository Visibility: **Public**
- Default branch: `main`
- 公開済みTag / Release: `v0.1.0`, `v0.2.0`
- Latest Release: **`v0.2.0`**
- `v0.2.0`公開日時: 2026-09-28 18:17:55 JST
- `v0.2.0` Release対象Commit: `7c244a87358295b223e9892ca5f6c51b13df9bea`

GitHub Settingsでは引き続き次を確認対象とする。

- Secret scanning alert
- Private vulnerability reporting
- 将来Dependencyを導入した場合のDependabot alerts

## 6. 注意

静的パターン確認は、あらゆる種類の秘密情報を数学的に保証して検出するものではない。

公開後もGitHub側のSecret scanning alertを確認し、今後も個人情報や秘密情報をcommitしない運用を継続する。


---

## 7. v0.2.0差分監査

v0.1.0公開後に追加されたログオン時自動起動関連を再監査した。

対象:

- `scripts/install-startup-task.ps1`
- `scripts/uninstall-startup-task.ps1`
- `tests/StartupTask.Tests.ps1`
- `docs/STARTUP_TASK_TEST.md`
- v0.2.0向けに更新したREADME / TASKS / PROJECT_HANDOFF / CHANGELOG

確認した代表的パターン:

- 実ユーザー固有の `C:\Users\...\` Path
- 実Email Address
- GitHub / OpenAI / AWS形式のCredential
- Private Key header
- Webhook URL

結果:

**検出なし**

Startup Scriptは実行時にWindows IdentityとEnvironmentから現在ユーザー・Program Files等を取得するが、Repositoryへ個人情報をhard-codeしていない。

AutoHotkey v2の例示Path `C:\Program Files\AutoHotkey\v2\AutoHotkey64.exe` は一般的なSystem/Application Pathであり、ユーザー固有情報ではない。

追加Commitのauthor / committer emailもGitHub noreply形式である。

Startup ScriptにHTTP通信、Telemetry、Analytics送信処理はない。


---

## 8. v0.2.0 Release確認

2026-09-28にGitHub Release `v0.2.0` を公開した。

確認結果:

- Tag: `v0.2.0`
- Release Name: `v0.2.0`
- Draft: false
- Pre-release: false
- Latest Release: `v0.2.0`
- Tag対象Commit: `7c244a87358295b223e9892ca5f6c51b13df9bea`
- Release作成時点のmainとTag対象Commitは一致
- GitHub自動生成Source archiveを利用可能

Release Notesにはログオン時自動起動機能、検証結果、通常権限・Path変更時再登録の注意事項を記載した。
