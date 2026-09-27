# Public Release Audit

更新日: 2026-09-28  
対象: NumpadWindowController v0.1.0  
状態: **Public release preparation complete**

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

## 5. GitHubで公開時に確認する設定

RepositoryをPublicへ切り替えた後、GitHub Settingsで次を確認する。

- Secret scanning
  - Public repositoryではGitHubのSecret scanningが自動的に利用される
- Private vulnerability reporting
  - Security reporting用に有効化を推奨
- Dependabot alerts
  - 将来Dependencyを導入する場合に有効化を推奨
- Default branch
  - `main`
- Tag / Release
  - 初回公開Releaseを作る場合は `v0.1.0`

## 6. 注意

静的パターン確認は、あらゆる種類の秘密情報を数学的に保証して検出するものではない。

公開直前にはGitHub側のSecret scanning結果も確認し、今後も個人情報や秘密情報をcommitしない運用を継続する。
