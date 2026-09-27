# Numpad Window Controller

Windows 11上で一般的なテンキーを、**ウィンドウ直接切り替え + Shortcut実行用コントローラー**として利用するAutoHotkey v2ツールです。

同じアプリを複数Windowで使用する環境でも、個々のWindowをHWNDで区別して1キーで呼び出せます。

**現在の初期版: v0.1.0**  
**License: MIT**

Phase F実装・検証、Phase G機能テスト、Phase H実機受入試験、Phase I初期版完成処理まで完了しており、v0.1.0として初期リリース可能な状態です。

---

## 主な機能

- 7 / 8 / 9でChrome 3Windowへ直接移動
- 4 / 5 / 6でVS Code 3Windowへ直接移動
- 1 / 2 / 3でExplorer / ChatGPT Desktop / PowerShell 7へ移動
- 任意SlotへWindowをManual Bind
- 任意SlotをShortcutとして利用
- Chrome / VS Code / 1 / 2 / 3のAuto Bind
- Bindingが失効した場合のLazy Auto Bind
- Slot Clear / Clear All
- 物理000キーを論理キー `Virtual000` として利用
- 実行中NumLock ON固定、正常終了時に元状態へ復元
- Debug時のみ任意ログ出力

---

## 必要環境

- Windows 11
- AutoHotkey v2
- 一般的なUSBテンキー
- 標準設定をそのまま利用する場合:
  - Google Chrome
  - Visual Studio Code
  - Windows Explorer
  - ChatGPT Desktop
  - Windows Terminal + PowerShell 7

標準設定のProcess / Class / Title条件は `KeyBindings.ini` で確認できます。

---

## インストール

### 1. AutoHotkey v2をインストール

AutoHotkey v2をWindowsへインストールします。

v1系ではなく**v2**が必要です。

### 2. リポジトリを取得

Git cloneまたはZIPでリポジトリを取得します。

Gitを使用する場合:

```powershell
git clone https://github.com/tabenishi02/NumpadWindowController.git
cd NumpadWindowController
```

### 3. 必要ファイルを確認

少なくとも次の2ファイルを同じDirectoryに置きます。

```text
NumpadWindowController.ahk
KeyBindings.ini
```

`KeyBindings.ini` は **UTF-16 LE with BOM** を維持してください。

### 4. 起動

`NumpadWindowController.ahk` を実行します。

起動時に:

1. Config Validation
2. NumLock状態保存
3. NumLock ON
4. Hotkey登録
5. Auto Bind All

を行います。

### 5. 終了

タスクトレイのAutoHotkeyアイコンからExitします。

正常終了時は起動前のNumLock状態へ戻します。

---

## 既定キー配置

```text
NumLock  /        *        -
未使用   任意     任意     任意

7        8        9        +
Chrome1  Chrome2  Chrome3  任意

4        5        6        Backspace
VSCode1  VSCode2  VSCode3  Disabled

1        2        3        Enter
Explorer ChatGPT  pwsh     任意

0        000      .        Enter
任意     仮想キー  任意     任意
```

Enterキーは物理的に縦2行分の大きさですが、論理上は1つの `NumpadEnter` です。

---

## 操作一覧

### Window Mode

| 操作 | 動作 |
|---|---|
| Key | Binding済みWindowへ移動。必要ならLazy Auto Bind |
| Ctrl + Key | Active WindowをManual Bind |
| Ctrl + Shift + Key | Slot Clear |
| Ctrl + Alt + Key | 個別Slot / Group Auto Bind |

### Global Action

| 操作 | 動作 |
|---|---|
| Ctrl + NumpadEnter | Auto Bind All |
| Ctrl + Shift + NumpadEnter | Clear All |

通常Keyboard EnterとNumpadEnterは区別されます。

- Standard Enter = `SC01C`
- NumpadEnter = `SC11C`

Global ActionはNumpadEnterだけを対象にします。

---

## Auto Bind

Auto Bind対象は専用Slot 1～9です。

| Slot | 対象 |
|---|---|
| 7 / 8 / 9 | Chrome |
| 4 / 5 / 6 | VS Code |
| 1 | Explorer |
| 2 | ChatGPT Desktop |
| 3 | PowerShell 7 |

任意Slot:

```text
/ * - + Backspace 0 000 . Enter
```

には一般Window Auto Bindを行いません。

必要な場合だけManual Bindします。

### Chrome

新規Auto Bind時:

- Primary Monitor上のみ対象
- Normal Windowのみ対象
- 左上 → 7
- 左下 → 8
- 右大 → 9

既存Binding済みChromeは、移動・Minimize・Maximize後もHWNDとAllowed条件が有効なら維持します。

### VS Code

未使用 `Code.exe` Windowを、Auto Bind時点の `WinGetList` 逆順で空き4→5→6へ補充します。

真のOpen順は保証しません。

### 完全再構築

すべてのBindingを作り直したい場合:

```text
Ctrl + Shift + NumpadEnter
↓
Ctrl + NumpadEnter
```

の順で実行します。

---

## Configuration

設定ファイル:

```text
KeyBindings.ini
```

要件:

- 本体と同じDirectory
- UTF-16 LE with BOM
- `ConfigVersion=1`
- 18 Key Sectionをすべて記述
- Hot Reloadなし
- 変更後は本体を再起動

設定可能Mode:

```text
Window
Shortcut
Disabled
```

詳細仕様は [Phase D Configuration仕様](docs/PHASE_D_SPEC.md) を参照してください。

---

## Window Modeの設定例

任意WindowをManual Bindできる設定:

```ini
[Key-NumpadDiv]
Mode=Window
Label=Slash
AllowedProcess=
AllowedClass=
AllowedTitleContains=
```

Allowed条件を空欄にすると任意WindowをManual Bindできます。

特定Processだけ許可する場合:

```ini
[Key-NumpadDiv]
Mode=Window
Label=Example
AllowedProcess=example.exe
AllowedClass=
AllowedTitleContains=
```

複数Allowed条件を指定した場合はAND条件です。

---

## Shortcutの設定例

### exe

```ini
[Key-NumpadDiv]
Mode=Shortcut
Label=Notepad
Target=C:\Windows\System32\notepad.exe
Arguments=
WorkingDirectory=
```

### 引数付きexe

```ini
[Key-NumpadDiv]
Mode=Shortcut
Label=Example
Target=C:\Program Files\Example\Example.exe
Arguments=alpha "beta gamma"
WorkingDirectory=C:\Program Files\Example
```

### PowerShell Script

`.ps1` をTargetへ直接指定せず、`pwsh.exe` をTargetにします。

```ini
[Key-NumpadDiv]
Mode=Shortcut
Label=PowerShell Script
Target=pwsh.exe
Arguments=-File "C:\Scripts\Example.ps1"
WorkingDirectory=C:\Scripts
```

Shortcutは押下ごとにTargetを実行します。

既存Window検索やActivateは行いません。

---

## Disabledの設定例

```ini
[Key-NumpadSub]
Mode=Disabled
Label=Minus
```

Disabled KeyにはController Hotkeyを登録せず、元のWindows入力を通します。

---

## Backspace

外付けテンキーBackspaceは通常Keyboard Backspaceと区別できません。

そのため標準設定では:

```ini
[Key-Backspace]
Mode=Disabled
Label=Backspace
```

です。

BackspaceをWindow / Shortcutへ変更すると通常Keyboard側Backspaceも同じActionを発火するため、起動時Warningを表示します。

---

## 0 / 000

物理000キーは独立したVK / SCを持たず、Numpad0のDown/Upを3回高速送信します。

NumpadWindowControllerでは、最初のDownから80ms以内の:

```text
D-U-D-U-D-U
```

を論理キー `Virtual000` として扱います。

通常Numpad0も判定のため最大約80ms待って確定します。

`Numpad0=Disabled` の場合は `Virtual000=Disabled` も必要です。

通常の0入力をController対象外にしたい場合は、両方Disabledにしてください。

---

## NumLock

対象実機の物理NumLockは、AutoHotkey InputHook / Windows Raw Inputの双方でKeyboard Eventが観測されませんでした。

そのためNumLock自体にはController Actionを割り当てません。

代わりにGlobal ActionをNumpadEnterへ割り当てています。

実行中のWindows側NumLock状態はON固定し、正常終了時に起動前状態へ戻します。

---

## サンプル設定

配布用サンプル:

```text
examples/KeyBindings.example.ini
```

標準の `KeyBindings.ini` と同じくUTF-16 LE BOMです。

サンプルでは任意Slotの一部をWindow / Shortcut / Disabledに設定し、Mode別の記述例を確認できます。

---

## Privacy

NumpadWindowController v0.1.0本体には、Telemetry、Analytics、HTTP通信などのNetwork送信処理はありません。

通常利用では永続Debug Logも生成しません。

Debugを明示的に有効化した場合、LogにはWindow title、Process name、HWND等のローカルRuntime情報が含まれる可能性があります。LogをIssueやPull Requestへ添付する場合は、個人情報・機密情報が含まれていないか確認してから共有してください。

公開前の個人情報・秘密情報監査結果は [Public Release Audit](docs/PUBLIC_RELEASE_AUDIT.md) に記録しています。

---

## Security

Security vulnerabilityの報告方法は [SECURITY.md](SECURITY.md) を参照してください。

未公開の脆弱性詳細、Token、Password、個人Path、未加工のDebug LogをPublic Issueへ投稿しないでください。

---

## Contributing

開発・Pull Request時のルールは [CONTRIBUTING.md](CONTRIBUTING.md) を参照してください。

特に、個人用Shortcut PathやCredentialをtracked fileへcommitしないよう注意してください。

---

## Known Limitations

現在の制限は [Known Limitations](docs/KNOWN_LIMITATIONS.md) に集約しています。

代表例:

- Chrome新規Auto BindはPrimary Monitor基準
- Minimized / Maximized Chromeは新規座標分類しない
- VS Codeの真のOpen順は保証しない
- 4つ目以降のChrome / VS Codeは自動割り当てしない
- 任意SlotはManual専用
- HWNDは永続化しない
- Config Hot Reloadなし
- Backspaceは通常Keyboardと区別不可
- Keyboard Device単位の識別なし

---

## テスト

Phase F自動テスト:

```powershell
.\tests\Run-PhaseFTests.ps1
```

Desktop操作を含むテスト:

```powershell
.\tests\Run-PhaseFTests.ps1 -Desktop
```

検証結果:

- Phase F: 完了
- Phase G: **65 / 65 PASS**
- Phase H: **16 / 16 PASS**
- Phase H由来のFAIL / BLOCKED / 修正要求なし

---

## 設計資料

- [MVP Design](docs/MVP_DESIGN.md)
- [設計確定記録（旧DESIGN_DRAFT）](docs/DESIGN_DRAFT.md)
- [Known Limitations](docs/KNOWN_LIMITATIONS.md)
- [Public Release Audit](docs/PUBLIC_RELEASE_AUDIT.md)
- [Security Policy](SECURITY.md)
- [Contributing](CONTRIBUTING.md)
- [Phase A仕様](docs/PHASE_A_SPEC.md)
- [Phase B PoC手順](docs/PHASE_B_POC.md)
- [Phase B結果](docs/PHASE_B_RESULT.md)
- [Phase C仕様](docs/PHASE_C_SPEC.md)
- [Phase D Configuration仕様](docs/PHASE_D_SPEC.md)
- [Phase E実装設計](docs/PHASE_E_SPEC.md)
- [Phase F実装・検証結果](docs/PHASE_F_RESULT.md)
- [Phase Gテスト手順](docs/PHASE_G_TEST.md)
- [Phase Gテスト結果](docs/PHASE_G_RESULT.md)
- [Phase H実機受入試験結果](docs/PHASE_H_RESULT.md)
- [Phase I初期版完成処理結果](docs/PHASE_I_RESULT.md)
- [実装タスク一覧](TASKS.md)
- [Project Handoff](PROJECT_HANDOFF.md)

---

## バージョン

初期版の正式バージョンは:

```text
v0.1.0
```

とする。

Semantic Versioning形式を使用し、今後の互換性を伴う機能追加・修正に応じて更新する。

---

## Release Status

**v0.1.0: Release Ready / Public release preparation complete**

Phase F～Hの完了結果と公開前監査から、現在のKnown Limitationsを受け入れたMVP初期版として公開可能な状態です。

RepositoryのVisibility変更そのものは実施していません。Publicへ切り替えた後は、GitHubのSecret scanning結果を確認し、Private vulnerability reportingを有効化することを推奨します。

GitHub Tag / Releaseの作成は別操作です。初回公開Releaseを作成する場合は `v0.1.0` を使用します。

---

## License

このプロジェクトは [MIT License](LICENSE) のもとで公開します。

Copyright (c) 2026 tabenishi02
