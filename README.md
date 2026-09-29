# Numpad Window Controller

Windows 11上で一般的なテンキーを、**任意Windowへの直接切り替え + Shortcut実行用コントローラー**として利用するAutoHotkey v2ツールです。

同じアプリを複数Windowで使用している場合も、Runtimeでは個々のWindowをHWNDで区別して1キーで呼び出せます。

**最新Release: GitHub Releasesを参照**  
**License: MIT**

現在の `main` には完了済みPhase J「General-purpose Configuration / Public Default」の一般化変更が含まれています。v0.3.0のRelease Ready状態です。v0.2.x以前のConfigVersion 1も互換Profileとして引き続き読み込めます。

---

## 主な機能

- テンキー各Slotへ任意WindowをManual Bind
- Window / Shortcut / Disabledの3 Mode
- Process / Class / Title条件によるWindow制約
- HWNDによるWindow単位のBinding
- Slot Clear / Clear All
- ConfigVersion 2の一般公開Default
- ConfigVersion 1 Legacy Developer Workflow互換
- Virtual000を任意で有効化可能
- Virtual000無効時はNumpad0を通常Hotkeyとして即時処理
- 実行中NumLock ON固定、正常終了時に元状態へ復元
- Windows Task Schedulerによるログオン時自動起動
- Debug時のみ任意ログ出力

---

## 必要環境

- Windows 11
- AutoHotkey v2
- 一般的なテンキー

Public DefaultはGoogle Chrome、Visual Studio Code、ChatGPT Desktop、PowerShell 7などの特定アプリを必要としません。

---

## インストール

> **既存v0.2.x cloneから更新する場合:** 旧版では `KeyBindings.ini` がtracked fileでした。現在の個人設定を維持する場合は、**git pull前にバックアップ**してください。手順は [ConfigVersion 2 Migration Guide](docs/CONFIG_MIGRATION_V2.md) を参照してください。

### 1. AutoHotkey v2をインストール

AutoHotkey v1ではなく**v2**を使用します。

### 2. Repositoryを取得

```powershell
git clone https://github.com/tabenishi02/NumpadWindowController.git
cd NumpadWindowController
```

ZIP展開でも利用できます。

### 3. 起動

`NumpadWindowController.ahk` を実行します。

初回起動時に `KeyBindings.ini` が存在しない場合:

```text
KeyBindings.default.ini
    ↓ copy
KeyBindings.ini
```

としてユーザーConfigを自動生成します。

`KeyBindings.ini` はGit管理対象外です。Repository更新時にユーザー設定を配布側から上書きしません。

---

## Public Default

ConfigVersion 2のPublic Defaultでは、1～9を含む通常Slotを特定アプリへ固定しません。

```text
NumLock  /        *        -
未使用   Window   Window   Window

7        8        9        +
Window   Window   Window   Window

4        5        6        Backspace
Window   Window   Window   Disabled

1        2        3        Enter
Window   Window   Window   Window

0        000      .
Window   Disabled Window
```

`Window` は「任意WindowをManual Bind可能」という意味です。起動直後に特定Windowへ自動割り当ては行いません。

---

## 基本操作

### Window Mode

| 操作 | 動作 |
|---|---|
| Key | Binding済みWindowへ移動 |
| Ctrl + Key | Active WindowをManual Bind |
| Ctrl + Shift + Key | Slot Clear |
| Ctrl + Alt + Key | Auto Bind対応Profileの場合のみ個別/Group Auto Bind |

例:

1. ChromeをActiveにする
2. `Ctrl + Numpad7`
3. 別Windowへ移動
4. `Numpad7`
5. 登録したChromeへ戻る

Public Defaultではbuilt-in Auto Bindはありません。

### Global Action

| 操作 | 動作 |
|---|---|
| Ctrl + NumpadEnter | Auto Bind All（Auto Bind Profile使用時） |
| Ctrl + Shift + NumpadEnter | Clear All |

通常Keyboard Enterは `SC01C`、NumpadEnterは `SC11C` で区別します。

---

## Configuration

ユーザーConfig:

```text
KeyBindings.ini
```

配布Default:

```text
KeyBindings.default.ini
```

一般例:

```text
examples/KeyBindings.example.ini
```

旧Developer Workflow:

```text
examples/KeyBindings.developer-workflow.ini
```

### ConfigVersion 2

ConfigVersion 2では、旧Dedicated Slot 1～9を含む各設定可能キーで:

```text
Window
Shortcut
Disabled
```

を選択できます。

18 Key Sectionは引き続き明示します。

### Window Mode

```ini
[Key-Numpad7]
Mode=Window
Label=Window 7
AllowedProcess=
AllowedClass=
AllowedTitleContains=
```

Allowed条件がすべて空なら任意WindowをManual Bindできます。

特定アプリだけ許可する例:

```ini
[Key-Numpad1]
Mode=Window
Label=Explorer
AllowedProcess=explorer.exe
AllowedClass=CabinetWClass
AllowedTitleContains=
```

複数条件を指定した場合はAND条件です。

### Shortcut Mode

```ini
[Key-NumpadDiv]
Mode=Shortcut
Label=Notepad
Target=C:\Windows\System32\notepad.exe
Arguments=
WorkingDirectory=
```

引数付き:

```ini
[Key-NumpadDiv]
Mode=Shortcut
Label=Example
Target=C:\Program Files\Example\Example.exe
Arguments=alpha "beta gamma"
WorkingDirectory=C:\Program Files\Example
```

PowerShell Scriptは `.ps1` をTargetへ直接指定せず:

```ini
Target=pwsh.exe
Arguments=-File "C:\Scripts\Example.ps1"
WorkingDirectory=C:\Scripts
```

とします。

### Disabled Mode

```ini
[Key-NumpadSub]
Mode=Disabled
Label=Minus
```

Disabled KeyにはController Hotkeyを登録せず、元のWindows入力を通します。

---

## ConfigVersion 1互換 / Developer Workflow

v0.2.xまでの個人用Workflowは削除せず、Legacy Presetとして維持しています。

```text
7 / 8 / 9 → Chrome
4 / 5 / 6 → VS Code
1         → Explorer
2         → ChatGPT Desktop
3         → PowerShell 7 Windows Terminal
```

利用する場合:

```powershell
Copy-Item .\examples\KeyBindings.developer-workflow.ini .\KeyBindings.ini -Force
```

このPresetでは従来どおりChrome座標Auto Bind、VS Code逆順Auto Bind、Explorer / ChatGPT / PowerShell Auto Bindを使用します。

移行方法は [ConfigVersion 2 Migration Guide](docs/CONFIG_MIGRATION_V2.md) を参照してください。

---

## 0 / 000

一般的なテンキーでは000キーを持たない場合が多いため、Public Defaultでは:

```ini
[Key-Virtual000]
Mode=Disabled
Label=Virtual 000
```

です。

この状態ではZero Detectorを起動せず、Numpad0を通常Hotkeyとして直接処理します。従来の約80ms判定待ちは発生しません。

物理000キーを利用する場合はVirtual000をWindowまたはShortcutへ変更します。するとNumpad0の `D-U-D-U-D-U` を80ms以内に検出し、論理キー `Virtual000` として扱います。

Virtual000有効時は通常Numpad0も判定のため最大約80ms待機します。

`Numpad0=Disabled` の場合は `Virtual000=Disabled` が必要です。

---

## Encoding

Configuration INIは **UTF-8** を前提とします。

- `KeyBindings.ini`
- `KeyBindings.default.ini`
- `examples/*.ini`

はすべてUTF-8で扱います。UTF-8 BOMの有無はどちらでも読み込めますが、Repository上の配布INIはUTF-8（BOMなし）へ統一しています。

UTF-16 LE / BEはサポートしません。v0.2.x以前のUTF-16 LE `KeyBindings.ini` を継続利用する場合は、先にUTF-8へ変換してください。変換手順は [ConfigVersion 2 Migration Guide](docs/CONFIG_MIGRATION_V2.md) を参照してください。

---

## Backspace

外付けテンキーBackspaceと通常Keyboard Backspaceをデバイス単位で区別できない環境があります。

Public DefaultではBackspaceをDisabledにしています。有効化した場合は起動時Warningを表示します。

---

## NumLock

対象実機では物理NumLockイベントをController Actionとして取得できないため、NumLock自体にはActionを割り当てません。

外付けテンキーのNumLockキーは、対象実機ではテンキー内部の入力切替として機能し、WindowsへNumLock Keyboard Eventを送信しません。したがって、この物理キーの表示・入力モードとWindows側NumLock状態は別物として扱います。

本体実行中はWindows側NumLockをON固定し、正常終了時に起動前状態へ復元します。Windows側lifecycleは過去のR-14実機試験で確認済みです。Process強制終了等では復元を保証しません。

---

## ログオン時自動起動

Windows Task Schedulerを使用します。

登録:

```powershell
.\scripts\install-startup-task.ps1
```

AutoHotkey v2 Pathを明示:

```powershell
.\scripts\install-startup-task.ps1 -AutoHotkeyPath 'C:\Program Files\AutoHotkey\v2\AutoHotkey64.exe'
```

起動Delay:

```powershell
.\scripts\install-startup-task.ps1 -DelaySeconds 30
```

解除:

```powershell
.\scripts\uninstall-startup-task.ps1
```

Taskは現在ユーザーのInteractive Desktop Session・通常権限で実行します。本体は `#SingleInstance Force`、Task側は `IgnoreNew` です。

RepositoryまたはAutoHotkey v2の配置場所を変更した場合はinstall scriptを再実行してください。

---

## テスト

Controller Regression:

```powershell
.\tests\Run-PhaseFTests.ps1
```

Desktop操作を含む試験:

```powershell
.\tests\Run-PhaseFTests.ps1 -Desktop
```

Startup Task:

```powershell
.\tests\StartupTask.Tests.ps1
.\tests\StartupTask.Tests.ps1 -Integration
```

GitHub ActionsのWindows runnerでもRegressionを実行しています。

- Controller Regression: **167 assertions PASS**（AutoHotkey v2.0.28）
- Startup Preview Regression: **24 assertions PASS**
- Startup Task Scheduler Integration Regression: **37 assertions PASS**
- Public ConfigVersion 2 / Legacy ConfigVersion 1 / Virtual000 ON-OFF: **PASS**

---

## Privacy

本体および自動起動用PowerShell ScriptにはTelemetry、Analytics、HTTP送信処理はありません。

通常利用では永続Debug Logを生成しません。Debugを明示的に有効化した場合、Window title、Process name、HWNDなどがLogへ含まれる可能性があります。

---

## Security / Contributing

- [Security Policy](SECURITY.md)
- [Contributing](CONTRIBUTING.md)

個人用Shortcut Path、Credential、未加工Debug Log等をPublic Repositoryへcommitしないでください。

---

## Known Limitations

現在仕様の制限は [Known Limitations](docs/KNOWN_LIMITATIONS.md) を参照してください。

Legacy Developer Workflow固有のChrome / VS Code Auto Bind制限も同文書内で区別して記載します。

---

## 設計・検証資料

- [MVP Design](docs/MVP_DESIGN.md)
- [Known Limitations](docs/KNOWN_LIMITATIONS.md)
- [Phase J Plan](docs/PHASE_J_PLAN.md)
- [Phase J Result](docs/PHASE_J_RESULT.md)
- [Phase J Physical Acceptance Test](docs/PHASE_J_MANUAL_TEST.md)
- [ConfigVersion 2 Migration Guide](docs/CONFIG_MIGRATION_V2.md)
- [Public Release Audit](docs/PUBLIC_RELEASE_AUDIT.md)
- [ログオン時自動起動テスト](docs/STARTUP_TASK_TEST.md)
- [Changelog](CHANGELOG.md)
- [実装タスク一覧](TASKS.md)
- [Project Handoff](PROJECT_HANDOFF.md)

Phase A～Iの文書はv0.1/v0.2系の設計・検証履歴としてRepository内に保持します。

---

## Version / Release Status

RepositoryはPublicです。

- `v0.1.0`: 初回MVP Release
- `v0.2.0`: ログオン時自動起動追加
- `v0.2.1`: Release後ドキュメント同期
- `v0.3.0`: **Release Ready**（Phase J一般化。公開前）

公開済みTagは後から移動しません。最新の安定ReleaseはGitHub Releasesを参照してください。

---

## License

[MIT License](LICENSE)

Copyright (c) 2026 tabenishi02
