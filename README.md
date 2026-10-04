# Numpad Window Controller

Windows 11 + AutoHotkey v2で、一般的なテンキーを **Window切替 / Keyboard Shortcut / Media操作 / Layer / Macro** 用の左手デバイスとして使うControllerです。

**最新安定Release: GitHub Releasesを参照**  
**License: MIT**

現在の `main` 系開発では Phase K「Action / Layer Architecture」を採用し、Runtime Configurationは **ConfigVersion 3のみ**をサポートします。ConfigVersion 1 / 2は過去Release・Git履歴・Phase文書から参照できますが、現行Runtimeでは読み込みません。

---

## 主な機能

- Physical Key → Active Layer → Action のAction Model
- Window Action
  - Manual Bind
  - Auto Bind
  - Toggle（MinimizedならRestore + Activate、非最小化でActiveならMinimize、InactiveならActivate）
  - Activate（Activeでも最小化しない）
  - ActivateThenToggle（新しいBindingでは最初のActivation成功までActivate、その後Toggle）
- Run Action
- KeySend
  - Ctrl+C / Ctrl+V / Ctrl+X / Ctrl+Z / Ctrl+S
  - Volume / Media / Browser / PrintScreen系
- Layer
  - Set
  - Next
- MultiAction + Delay
- Application Launch fallback
  - 対象Application Windowが0件の場合のみLaunch
  - Group単位LaunchPendingで多重起動防止
- Virtual00 / Virtual000
- Windows Task Schedulerによるログオン時自動起動
- NumLock ON固定 + 正常終了時復元

---

## 必要環境

- Windows 11
- AutoHotkey v2
- 一般的なテンキー

Public DefaultはChrome、VS Code、ChatGPT Desktopなど特定Applicationを必要としません。

---

## インストール

### 1. AutoHotkey v2をインストール

AutoHotkey v1ではなくv2を使用します。

### 2. Repositoryを取得

```powershell
git clone https://github.com/tabenishi02/NumpadWindowController.git
cd NumpadWindowController
```

ZIP展開でも利用できます。

### 3. 起動

`NumpadWindowController.ahk` を実行します。

初回起動時に `KeyBindings.ini` がなければ:

```text
KeyBindings.default.ini
        ↓ copy
KeyBindings.ini
```

としてUser Configを生成します。`KeyBindings.ini` はGit管理対象外です。

> v0.3.0以前の `KeyBindings.ini` はConfigVersion 3へ手動移行してください。ConfigVersion 1 / 2互換読込・自動Migrationはありません。

---

## Public Default

既定Configには3 Layerがあります。

### Base

通常のWindow切替Layerです。

- `NumpadDiv / Mult / Sub`
- `0～9`（`+`を除く）
- `.`
- `Enter`

を汎用Window Actionとして利用できます。

WindowをActiveにして:

```text
Ctrl + Key
```

でManual Bindします。

### Edit

代表的な編集Shortcutを割り当てています。

| Key | Action |
|---|---|
| 7 | Undo |
| 8 | Copy |
| 9 | Paste |
| 4 | Cut |
| 5 | Select All |
| 6 | Save |
| 1 | Find |
| 2 | Win+Shift+S |
| 3 | Redo |

### Media

Media / Browser操作用Layerです。

| Key | Action |
|---|---|
| 7 / 8 / 9 | Previous / Play-Pause / Next |
| 4 / 5 / 6 | Volume Down / Mute / Up |
| 1 / 2 / 3 | Browser Back / Refresh / Forward |
| 0 | Win+Shift+S |

### Layer切替

Public Defaultでは:

```text
NumpadAdd (+) → Next Layer
```

です。

Global MappingはActive Layerより優先されるため、どのLayerからでも切り替えられます。

Backspaceは既定では未Mappingで、Windows本来の入力を通します。

---

## Window Action

### 通常操作

Window Actionを解決するKeyでは:

| 操作 | 動作 |
|---|---|
| Key | Window Action実行 |
| Ctrl + Key | Active WindowをManual Bind |
| Ctrl + Shift + Key | Binding Clear |
| Ctrl + Alt + Key | Auto Bind Strategyがある場合に明示Auto Bind |

### Toggle

`Behavior=Toggle` の場合:

```text
対象WindowがMinimized
→ Restore
→ Activate

対象Windowが非最小化かつInactive
→ Activate

対象Windowが非最小化かつActive
→ Minimize
```

Minimized状態をActive判定より優先します。Windowsの状態遷移中にActive判定が一時的に残っていても、Minimizedなら再度MinimizeせずRestore + Activateします。

時間ベースのDouble Tapではありません。押下時点のWindow状態を見ます。

### Activate

`Behavior=Activate` は対象WindowがActiveでもMinimizeしません。MultiAction内のWindow移動などに向きます。

### ActivateThenToggle

`Behavior=ActivateThenToggle` は、新しいBindingに対する最初の操作を `Activate` として扱い、そのActivationが成功した後は同じBindingを `Toggle` として扱います。

```text
New Binding
→ Activate phase
→ first successful activation
→ Toggle phase
```

Binding Clear、新しいManual Bind、新しいAuto Bind、Controller再起動ではActivate phaseへ戻ります。同じ有効Bindingを維持したAuto Bind AllではToggle phaseを保持します。

`Behavior` 自体はApplicationの起動先を定義しません。対象Windowが0件の状態から起動したい場合は、参照する `WindowGroup` に `LaunchTarget` を設定する必要があります。

Windows TerminalでPowerShell 7を1 Windowとして起動する場合は、`pwsh.exe` 直起動ではなく次のようにWindows Terminalを明示的に起動できます。

```ini
LaunchTarget=wt.exe
LaunchArguments=-w new new-tab --title "PowerShell 7" pwsh.exe -NoExit
```

`-w new` により新規Windows Terminal Windowを明示し、`--title` をWindowGroupのTitle条件と一致させます。`ActivateThenToggle` でLaunch fallbackが発生した場合は、Window生成をLaunchPendingで検出し、自動Bind → Activateを続行し、Activation成功後にToggle phaseへ移行します。

### Global Command

Layerに関係なく予約されています。

| 操作 | 動作 |
|---|---|
| Ctrl + NumpadEnter | Auto Bind All |
| Ctrl + Shift + NumpadEnter | Clear All Window Bindings |

Standard Enter（SC01C）には影響しません。

---

## ConfigVersion 3

基本構造:

```ini
[General]
ConfigVersion=3
DefaultLayer=Base
LayerOrder=Base,Edit,Media
EnableVirtual00=Off
EnableVirtual000=Off

[GlobalKeys]
NumpadAdd=LayerNext

[Layer-Base]
Numpad7=Window7

[Action-Window7]
Type=Window
Label=Window 7
Behavior=Toggle
WindowGroup=
AllowedProcess=
AllowedClass=
AllowedTitleContains=
AutoBindStrategy=None
AutoBindOrder=1
```

Configの中心概念はKey Modeではなく **Action** です。

### Action Type

- `Window`
- `Run`
- `KeySend`
- `LayerSwitch`
- `Delay`
- `MultiAction`
- `Disabled`

---

## KeySend

AutoHotkey固有の `^c` ではなく、人間可読形式を使用します。

```ini
[Action-Copy]
Type=KeySend
Label=Copy
Keys=Ctrl+C
```

例:

```text
Ctrl+C
Ctrl+V
Ctrl+X
Ctrl+Shift+S
Win+Shift+S
Alt+F4
Volume_Up
Volume_Down
Volume_Mute
Media_Play_Pause
Media_Next
Media_Prev
Browser_Back
Browser_Forward
Browser_Refresh
PrintScreen
```

未知Keyや不正Combinationは起動時Configuration Errorになります。

---

## Layer

```ini
[Action-LayerNext]
Type=LayerSwitch
Label=Next Layer
Mode=Next
Layer=
```

初期対応:

- `Mode=Set`
- `Mode=Next`

常にActive Layerは1つです。

Phase KではLayer Stack、Momentary Layer、One-shot Layerは実装しません。

複数Layerを使うConfigでは、安全に戻れるようGlobal MappingにLayerSwitch Actionが少なくとも1つ必要です。

---

## MultiAction / Delay

```ini
[Action-Delay100]
Type=Delay
Label=100 ms
Milliseconds=100

[Action-CopyToApp]
Type=MultiAction
Label=Copy to App
Step1=Copy
Step2=Delay100
Step3=TargetActivate
Step4=Paste
```

制約:

- Step番号は1から連続
- 存在しないAction参照はError
- Nested MultiActionは禁止
- 同一MultiAction実行中の再入を抑止
- Delay中にController全体をCriticalで固定しない

---

## Window Group / Launch fallback

Application単位の存在判定とLaunch設定はWindowGroupへ分離します。

```ini
[WindowGroup-Notepad]
MatchProcess=notepad.exe
MatchClass=
MatchTitleContains=
LaunchTarget=C:\Windows\System32\notepad.exe
LaunchArguments=
LaunchWorkingDirectory=
LaunchPendingTimeoutMs=5000
```

Window Action:

```ini
[Action-Notepad]
Type=Window
Label=Notepad
Behavior=Activate
WindowGroup=Notepad
AllowedProcess=notepad.exe
AllowedClass=
AllowedTitleContains=
AutoBindStrategy=FirstMatch
AutoBindOrder=1
```

Launch条件:

```text
Bindingなし
↓
Auto Bindでも候補なし
↓
WindowGroup一致Window = 0
→ Launch

WindowGroup一致Window >= 1
→ 新規Launchしない
```

Launch直後はGroup単位のLaunchPendingを保持し、キー連打による多重Runを防止します。長時間の同期WinWaitは行いません。

---

## Auto Bind Strategy

ConfigVersion 3のWindow Actionで利用できます。

- `None`
- `FirstMatch`
- `ReverseList`
- `PrimaryThreePane`

旧個人Workflow相当は:

```text
examples/KeyBindings.developer-workflow.ini
```

へConfigVersion 3形式で保存しています。

```powershell
Copy-Item .\examples\KeyBindings.developer-workflow.ini .\KeyBindings.ini -Force
```

このExampleにはChrome 3-pane、VS Code逆順、Explorer / ChatGPT / PowerShell条件を含みます。

---

## Virtual00 / Virtual000

```ini
EnableVirtual00=On
EnableVirtual000=On
```

とするとNumpad0の高速入力列を論理キー化します。

```text
D-U             → Numpad0
D-U-D-U         → Virtual00
D-U-D-U-D-U     → Virtual000
```

判定窓は約80msです。

- 00 / 000ともOff: Numpad0を直接Hotkey処理
- Virtual00のみOn: 2回目のUpでVirtual00確定
- Virtual000 On: 000の途中か判定するため最大約80ms待機

物理00キーと人間による極端に高速な0二連打が同じEvent列なら完全識別できません。

---

## Pass-through / Backspace

未Mapping KeyはController Hotkey条件が成立しないため、Windows本来の入力を通します。

Backspaceは通常Keyboardと外付けテンキーをDevice単位で区別できないためPublic Defaultでは未Mappingです。Controller ActionへMappingすると起動時Warningを表示します。

---

## Encoding

Configuration INIはUTF-8のみ対応します。

- UTF-8 BOMなし: 対応
- UTF-8 BOMあり: 対応
- UTF-16 LE / BE: 非対応

Hot Reloadはありません。Config変更後はControllerを再起動してください。

---

## NumLock

対象実機の物理NumLockはテンキー内部の入力切替として動作し、WindowsへNumLock Keyboard Eventを送らない場合があります。

Controller実行中はWindows側NumLockをON固定し、正常終了時に起動前状態へ復元します。Process強制終了などOnExitが実行されない場合は復元を保証しません。

---

## ログオン時自動起動

登録:

```powershell
.\scripts\install-startup-task.ps1
```

AutoHotkey Path指定:

```powershell
.\scripts\install-startup-task.ps1 -AutoHotkeyPath 'C:\Program Files\AutoHotkey\v2\AutoHotkey64.exe'
```

Delay:

```powershell
.\scripts\install-startup-task.ps1 -DelaySeconds 30
```

解除:

```powershell
.\scripts\uninstall-startup-task.ps1
```

---

## テスト

Controller Regression:

```powershell
.\tests\Run-PhaseKTests.ps1
```

Startup Task:

```powershell
.\tests\StartupTask.Tests.ps1
.\tests\StartupTask.Tests.ps1 -Integration
```

GitHub ActionsのWindows runnerでもAutoHotkey v2 Regressionを実行します。

---

## Known Limitations

現行仕様の制限は [Known Limitations](docs/KNOWN_LIMITATIONS.md) を参照してください。

主な制限:

- Config Hot Reloadなし
- HWND Bindingは永続化しない
- Keyboard Device単位識別なし
- Virtual00の物理実機受入は未実施
- 管理者権限ApplicationへのKeySend / Window操作にはWindows権限分離の制限あり
- Tap / Hold / Double Tap、Mouse ActionはPhase K対象外

---

## 設計・検証資料

- [Phase K Design](docs/PHASE_K_DESIGN.md)
- [Phase K Result](docs/PHASE_K_RESULT.md)
- [Known Limitations](docs/KNOWN_LIMITATIONS.md)
- [Phase J Result](docs/PHASE_J_RESULT.md)
- [Public Release Audit](docs/PUBLIC_RELEASE_AUDIT.md)
- [Startup Task Test](docs/STARTUP_TASK_TEST.md)
- [Changelog](CHANGELOG.md)
- [Implementation Tasks](TASKS.md)
- [Project Handoff](PROJECT_HANDOFF.md)

Phase A～Jの文書は過去Release時点の設計・検証履歴として保持します。

---

## Version / Release Status

RepositoryはPublicです。

- `v0.1.0`: 初回MVP Release
- `v0.2.0`: ログオン時自動起動追加
- `v0.2.1`: Release後ドキュメント同期
- `v0.3.0`: Phase J Public Default / Configuration一般化
- Phase K: ConfigVersion 3 / Action / Layer Architecture（v0.4.0でRelease）

公開済みTagは後から移動しません。最新の安定ReleaseはGitHub Releasesを参照してください。

---

## Privacy / Security

本体およびStartup ScriptにはTelemetry、Analytics、HTTP送信処理はありません。

- [Security Policy](SECURITY.md)
- [Contributing](CONTRIBUTING.md)

個人Path、Credential、未加工Debug LogをPublic Repositoryへcommitしないでください。

---

## License

[MIT License](LICENSE)

Copyright (c) 2026 tabenishi02
