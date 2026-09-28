# Numpad Window Controller - MVP Design

更新日: 2026-09-28  
対象バージョン: **v0.1.0**  
状態: **Final**  
実装状態: **実装・機能テスト・実機受入試験完了**

> 本書はNumpadWindowController v0.1.0のMVP全体設計をまとめる。
> Configuration、Auto Bind、実装構造などの詳細はPhase A～E仕様書を参照し、検証結果はPhase F～H結果文書を参照する。

---

## 1. 目的

一般的なUSBテンキーを、Windows上で頻繁に利用するウィンドウへ直接移動するための専用コントローラーとして使用する。

MVPでは次の機能を提供する。

1. テンキーの物理キーとWindowを1対1でBindingし、1キーで対象Windowへ移動する。
2. Chrome / VS Code / Explorer / ChatGPT Desktop / PowerShell 7を専用Slotへ自動割り当てする。
3. 一部キーをShortcutとして設定し、exe / bat / cmd / lnkを実行する。
4. Manual Bind、Slot Clear、Clear All、Lazy Auto Bindにより日常利用中のWindow増減へ対応する。
5. 000キーを独立した論理キー `Virtual000` として利用する。

同一アプリケーションを複数Windowで使用する場合でも、個々のWindowへ直接移動できることを重視する。

---

## 2. 対象環境

- Windows 11
- AutoHotkey v2
- 一般的なUSBテンキー
- Runtime Window識別: HWND
- Configuration: INI
- Configファイル: `KeyBindings.ini`
- Config Version: 1
- Config Encoding: UTF-16 LE with BOM

専用USBドライバ、AutoHotInterception、常設GUIはMVP要件に含めない。

---

## 3. ファイル構成

v0.1.0の主要構成:

```text
NumpadWindowController/
├─ .gitattributes
├─ .gitignore
├─ LICENSE
├─ SECURITY.md
├─ CONTRIBUTING.md
├─ NumpadWindowController.ahk
├─ KeyBindings.ini
├─ README.md
├─ TASKS.md
├─ PROJECT_HANDOFF.md
├─ examples/
│  └─ KeyBindings.example.ini
├─ docs/
│  ├─ MVP_DESIGN.md
│  ├─ DESIGN_DRAFT.md
│  ├─ KNOWN_LIMITATIONS.md
│  ├─ PUBLIC_RELEASE_AUDIT.md
│  ├─ PHASE_A_SPEC.md
│  ├─ PHASE_B_POC.md
│  ├─ PHASE_B_RESULT.md
│  ├─ PHASE_C_SPEC.md
│  ├─ PHASE_D_SPEC.md
│  ├─ PHASE_E_SPEC.md
│  ├─ PHASE_F_RESULT.md
│  ├─ PHASE_G_TEST.md
│  ├─ PHASE_G_RESULT.md
│  ├─ PHASE_H_RESULT.md
│  └─ PHASE_I_RESULT.md
├─ poc/
└─ tests/
```

本体は単一AHKファイルとし、v0.1.0では `lib/` 分割しない。

---

## 4. キーMode

Configurationで設定できるModeは3種類。

| Mode | 意味 |
|---|---|
| Window | Window Binding / Activate |
| Shortcut | Targetを実行 |
| Disabled | Controllerで管理せずネイティブ入力を通す |

`Function` Modeは採用しない。

NumLockはConfiguration対象外。

---

## 5. 既定キー配置

| キー | 既定用途 | Auto Bind |
|---|---|---|
| 7 | Chrome 1 | ON |
| 8 | Chrome 2 | ON |
| 9 | Chrome 3 | ON |
| 4 | VS Code 1 | ON |
| 5 | VS Code 2 | ON |
| 6 | VS Code 3 | ON |
| 1 | Explorer | ON |
| 2 | ChatGPT Desktop | ON |
| 3 | PowerShell 7 | ON |
| / | 任意 | OFF |
| * | 任意 | OFF |
| - | 任意 | OFF |
| + | 任意 | OFF |
| Backspace | Disabled | OFF |
| 0 | 任意 | OFF |
| 000 | Virtual000 / 任意 | OFF |
| . | 任意 | OFF |
| Enter | 任意 | OFF |
| NumLock | Controller未使用 | - |

Enterは物理的に縦2行へまたがるが、論理上は1つの `NumpadEnter` とする。

---

## 6. 操作体系

Window Mode:

| 操作 | 動作 |
|---|---|
| Key | Binding済みWindowをActivate。必要ならLazy Auto Bind |
| Ctrl + Key | Active WindowをManual Bind |
| Ctrl + Shift + Key | Slot Clear |
| Ctrl + Alt + Key | 個別Slot / Group Auto Bind |

Global Action:

| 操作 | 動作 |
|---|---|
| Ctrl + NumpadEnter | Auto Bind All |
| Ctrl + Shift + NumpadEnter | Clear All |

NumpadEnterのGlobal ActionはWindow ModeのGeneric Manual Bind / Slot Clearより優先する。

Standard Enter=`SC01C`、NumpadEnter=`SC11C` として分離する。

Shortcut Modeでは通常押下だけをController Hotkeyとして登録する。

Disabled ModeではController Hotkeyを登録しない。

---

## 7. Runtime State

Runtime Stateの入口は1つのApp Stateへ集約する。

概念:

```text
App
├─ Config
├─ Keys
├─ Slots
├─ OriginalNumLock
├─ ZeroDetector
└─ Debug
```

Runtime Bindingの正本は `App.Slots`。

Slot State:

```text
Hwnd
BindingSource = Manual / Auto / None
```

HWNDは永続Configurationへ保存しない。

Script再起動時は新しいRuntime Bindingを作る。

Window metadataは必要時に都度取得し、長期キャッシュしない。

---

## 8. Window識別

共通の新規候補Filterでは、概ね次の条件を使う。

- Visible
- Cloakedではない
- Ownerなし
- ToolWindowではない
- Width / Height > 0
- Titleあり

既存BindingのValidity判定と、新規Candidate Eligibilityは分けて扱う。

既存BindingはHWNDが存在し、SlotのAllowed条件を満たす限り維持する。

---

## 9. 専用Slot

### 9.1 Chrome 7 / 8 / 9

標準Allowed条件:

```ini
AllowedProcess=chrome.exe
```

新規Auto Bind:

- Primary Monitor上だけ対象
- Normal Windowだけ対象
- 座標とサイズで左上 / 左下 / 右大へ分類
- 7=左上
- 8=左下
- 9=右大
- 同一分類に複数候補がある場合はIdeal Rectangle Scoreで選択

既存Binding済みChromeは移動・Minimize・Maximize後も、HWNDとAllowed条件が有効なら維持する。

### 9.2 VS Code 4 / 5 / 6

標準Allowed条件:

```ini
AllowedProcess=Code.exe
```

新規Auto Bind:

- 未使用 `Code.exe` Windowを取得
- `WinGetList` の逆順を使用
- 空きSlot 4→5→6へ補充

真のOpen順は保証しない。

### 9.3 Explorer 1

```ini
AllowedProcess=explorer.exe
AllowedClass=CabinetWClass
```

### 9.4 ChatGPT Desktop 2

```ini
AllowedProcess=ChatGPT.exe
```

### 9.5 PowerShell 7 3

```ini
AllowedProcess=WindowsTerminal.exe
AllowedClass=CASCADIA_HOSTING_WINDOW_CLASS
AllowedTitleContains=PowerShell 7
```

複数候補がある場合は非Minimizedを優先し、同条件ならZ-orderが前のWindowを使用する。

---

## 10. Manual Bind

`Ctrl + Key` でActive WindowをWindow Mode Slotへ登録する。

必須条件:

- Window Mode
- Allowed条件を満たす
- `1 HWND : 1 Slot`

同一HWNDが別Slotに存在する場合、Manual Bind先を正とし旧SlotをNoneへする。

Allowed違反時は既存Bindingを変更しない。

Manual BindingはAuto Bindingより優先する。

---

## 11. Auto Bind

Auto Bindは全Windowを空きキーへ自動配分する機能ではない。

対象は専用Slot 1～9だけ。

Auto Bind Allの処理:

1. Runtime StateをWorking Stateへコピー
2. 既存BindingのValidityを検証
3. 無効BindingをNoneへ変更
4. 有効BindingのHWNDをUsed HWND Setへ登録
5. Chrome Groupを補充
6. VS Code Groupを補充
7. Explorerを補充
8. ChatGPTを補充
9. PowerShellを補充
10. `1 HWND : 1 Slot` を最終検証
11. Runtime StateへCommit

有効なManual / Auto Bindingは再ソートしない。

候補不足はNoneを維持する。

候補過多は余剰候補を無視する。

4つ目以降のChrome / VS Codeを任意Slotへ自動転送しない。

一般Window Auto Bindは実装しない。

---

## 12. Lazy Auto Bind

専用Slotの通常押下時に次の状態ならLazy Auto Bindを試行する。

- Binding=None
- HWND消滅
- Allowed条件違反

Chrome / VS CodeはGroup単位で空Slotを補充する。

1 / 2 / 3は対象Slotだけ補充する。

任意Slot、Shortcut、DisabledではLazy Auto Bindしない。

失敗時はNoneのまま通知し、Background Retryはしない。

---

## 13. Clear

Slot Clear:

```text
Ctrl + Shift + Key
```

対象SlotのRuntime Bindingのみ解除する。

Clear All:

```text
Ctrl + Shift + NumpadEnter
```

全Runtime BindingをNoneへする。

Configurationは変更しない。

Clear直後は即時Auto Bindしない。

完全な再構築は:

```text
Ctrl + Shift + NumpadEnter
Ctrl + NumpadEnter
```

の順で行う。

---

## 14. Shortcut

Shortcut Modeで許可するTarget:

- `.exe`
- `.bat`
- `.cmd`
- `.lnk`

Field:

- `Mode`
- `Label`
- `Target`
- `Arguments`
- `WorkingDirectory`

Targetは起動時に解決・存在確認する。

Shortcutは押下ごとにTargetをRunし、既存Window Activateへ置き換えない。

Runtime実行失敗時は通知してController本体を継続する。

`.ps1` をTargetへ直接指定しない。

PowerShell Scriptは:

```ini
Target=pwsh.exe
Arguments=-File "C:\Scripts\Example.ps1"
```

を使用する。

---

## 15. Configuration

`KeyBindings.ini` は本体と同じDirectoryに配置する。

正規Encoding:

```text
UTF-16 LE with BOM
```

必須:

```ini
[General]
ConfigVersion=1
```

Canonicalな18 Key Sectionをすべて1回ずつ記述する。

Config変更はScript再起動で反映する。

Hot Reloadは実装しない。

AutoBind / AutoBindGroup / AutoBindOrderはConfigurationへ保存せず、コード側Built-in Metadataとする。

起動時に次をValidationする。

- Encoding
- ConfigVersion
- Section不足 / 未知 / 重複
- Field不足 / 未知 / 重複
- Mode
- Mode別Field
- 専用Slot Allowed条件
- Shortcut Target / WorkingDirectory
- Numpad0 / Virtual000整合

Fatal Configuration Error時は常駐開始しない。

---

## 16. Backspace

外付けテンキーBackspaceは:

```text
VK 08
SC 00E
AHK Backspace
```

であり、通常Keyboard Backspaceと区別できない。

そのため標準Configは:

```ini
[Key-Backspace]
Mode=Disabled
Label=Backspace
```

とする。

BackspaceをWindow / Shortcutへ変更した場合、通常Keyboard側Backspaceも同じController Actionを発火するため、起動時Warningを表示する。

---

## 17. Numpad0 / Virtual000

物理000キーは独立VK/SCではなく、Numpad0 `SC052` のDown/Upを3回高速送信する。

Detectorは最初のDownから80ms以内の:

```text
D-U-D-U-D-U
```

を `Virtual000` とする。

同一Modifier状態の再DownはInterrupt対象外。

その他の新規Interruptは通常Numpad0へフォールバックする。

通常Numpad0もDetectorを通るため最大約80msの確定待ちがある。

`Numpad0=Disabled` の場合は `Virtual000=Disabled` も必須。

両方Disabledの場合はZero Detectorを登録しない。

---

## 18. NumLock

外付けテンキーの物理NumLockは実機PoCでAutoHotkey InputHook / Windows Raw Inputの双方にEventを送らなかった。

そのためController Actionには使用しない。

Windows側NumLock状態は:

1. Config Validation後に起動前状態を保存
2. 実行中はON固定
3. 正常終了時に起動前状態へ復元

する。

強制Process Kill等でOnExitが実行されない場合の復元は保証しない。

---

## 19. Startup

起動順:

1. Directives / Constants
2. Built-in Metadata
3. Config Raw Read
4. Config Validation
5. Config Object生成
6. 起動前NumLock保存
7. OnExit登録
8. NumLock ON
9. Runtime State初期化
10. Zero Detector初期化
11. Hotkey登録
12. Auto Bind All
13. 常駐

Config Validation完了前にNumLockやHotkeyなどの外部状態を変更しない。

---

## 20. Shutdown

正常終了:

1. Timer停止
2. InputHook停止
3. ToolTip消去
4. NumLock復元
5. 終了

---

## 21. Logging / Diagnostics

通常利用では永続Logを生成しない。

Debugをコード内定数で明示有効化した場合のみ:

```text
logs/NumpadWindowController_<timestamp>.log
```

へ記録する。

全Key Down/Upを通常時に常時保存しない。

Auto Bind後のSlot Snapshotを診断出力できる。

Debug File I/O失敗はController本体へ波及させない。

---

## 22. 検証

### Phase F

本体実装、自動試験、実機Smoke Test、入力系Regressionを完了。

Phase F固有の未解決事項なし。

### Phase G

G-1～G-8:

```text
65 / 65 PASS
```

FAIL / BLOCKEDなし。

### Phase H

H-1 / H-2:

```text
16 / 16 PASS
```

通常利用で追加操作なしに主要Windowへ安定して移動できる受入条件を満たした。

---

## 23. Known Limitations

現行制限は [KNOWN_LIMITATIONS.md](KNOWN_LIMITATIONS.md) を正とする。

主な制限:

- Chrome新規Auto BindはPrimary Monitor固定
- Minimized / Maximized Chromeは新規座標分類しない
- VS Code真のOpen順は保証しない
- 4つ目以降のChrome / VS Codeは自動割り当てしない
- 任意SlotはManual専用
- HWNDは永続化しない
- Config Hot Reloadなし
- Backspaceは通常Keyboardと区別不可
- デバイス単位入力識別なし

---

## 24. MVPで実装しないもの

- 常設GUI
- Config編集GUI
- Config Hot Reload
- 一般Window Auto Bind
- Background Retry
- HWND永続化
- VS Code真のOpen順監視
- Secondary Monitor Chrome Auto Bind
- デバイス単位入力識別
- 汎用Plugin / Rule Engine
- `lib/` 分割

---

## 25. 詳細仕様

- [Phase A仕様](PHASE_A_SPEC.md)
- [Phase B PoC手順](PHASE_B_POC.md)
- [Phase B結果](PHASE_B_RESULT.md)
- [Phase C仕様](PHASE_C_SPEC.md)
- [Phase D Configuration仕様](PHASE_D_SPEC.md)
- [Phase E実装設計](PHASE_E_SPEC.md)
- [Phase F実装・検証結果](PHASE_F_RESULT.md)
- [Phase Gテスト手順](PHASE_G_TEST.md)
- [Phase Gテスト結果](PHASE_G_RESULT.md)
- [Phase H実機受入試験結果](PHASE_H_RESULT.md)
- [Known Limitations](KNOWN_LIMITATIONS.md)

旧暫定設計は [DESIGN_DRAFT.md](DESIGN_DRAFT.md) に最終結果を反映したうえで、設計確定までの経緯記録として保持する。
