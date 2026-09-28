# Numpad Window Controller - Phase G Test Guide

更新日: 2026-09-25  
対象: MVP / v0.1.0  
状態: **Completed - Phase G実施済み / 結果はPHASE_G_RESULT.md**  
目的: `TASKS.md` のPhase Gについて、実Window / 実Config / 物理テンキーを使った具体的な試験方法、期待結果、記録方法を定義する。

> 本書の期待結果はPhase A～Fで確定した現行仕様を基準とする。
> Phase GではPhase Fの内部ロジック中心の自動試験より広い実利用条件を確認する。

---

# 1. Phase Gの進め方

推奨順序:

```text
事前Regression
  ↓
G-1 Configuration
  ↓
G-2 Manual Bind
  ↓
G-3 Chrome Auto Bind
  ↓
G-4 VS Code Auto Bind
  ↓
G-5 Explorer / ChatGPT / PowerShell
  ↓
G-6 Shortcut
  ↓
G-7 Clear / Lazy Bind
  ↓
G-8 長時間常駐
  ↓
最終Regression
```

各試験は原則として独立して実施する。

試験途中でConfigを変更した場合は、次の試験へ進む前に標準Configへ戻す。
Window配置やBindingが前試験の影響を受けそうな場合は、`Ctrl + Shift + NumpadEnter` でClear Allしてから必要な状態を作る。

---

# 2. 事前準備

## 2.1 必要環境

- Windows 11
- AutoHotkey v2
- 物理テンキー
- Chrome
- VS Code
- Explorer
- ChatGPT Desktop
- Windows Terminal + PowerShell 7
- PowerShell 7またはWindows PowerShell（試験準備用）

PoCを同時起動して本体Hotkeyと競合させない。
Phase B PoCを観測目的で使う場合だけ、本体とHotkeyが衝突しないことを確認して使用する。

## 2.2 Configバックアップ

Phase Gでは `KeyBindings.ini` を複数回変更する。

リポジトリRootで最初に実行:

```powershell
Copy-Item .\KeyBindings.ini .\KeyBindings.ini.phaseg.bak -Force
```

復元:

```powershell
Copy-Item .\KeyBindings.ini.phaseg.bak .\KeyBindings.ini -Force
```

Phase G完了後:

```powershell
Remove-Item .\KeyBindings.ini.phaseg.bak
```

`KeyBindings.ini.phaseg.bak` は試験用一時ファイルでありGitへCommitしない。

## 2.3 Debug Log

通常のPhase Gは `DEBUG_ENABLED := false` のままでよい。

次の確認で画面上だけでは判定しにくい場合のみ、一時的に:

```ahk
global DEBUG_ENABLED := true
```

へ変更する。

出力先:

```text
logs/NumpadWindowController_<timestamp>.log
```

特に有効:

- 1 HWND : 1 Slot確認
- Clear直後にAuto Bindが起きていないことの確認
- Manual BindingがAuto Bind Allで維持されたことの確認
- Runtime Shortcut失敗
- VS Code / ChromeのBinding Snapshot

試験後は必ず `false` へ戻す。

## 2.4 Phase F Regression

Phase G開始前に次を実行する。

```powershell
.\tests\Run-PhaseFTests.ps1
.\tests\Run-PhaseFTests.ps1 -Desktop
```

既知のPENDING以外に新規FAILがないことを確認する。

Phase G完了後にも同じ2コマンドを再実行する。

---

# 3. 共通記録形式

各試験は次の形式で記録する。

```text
Test ID:
日時:
実施Commit:
Config:
事前状態:
操作:
期待結果:
実際の結果:
結果: PASS / FAIL / BLOCKED
ログ:
備考:
```

FAILの場合は、可能ならDebug Log、対象Windowのタイトル、再現手順を残す。

---

# 4. G-1 設定読込テスト

Config試験では、毎回本体を完全終了してから `KeyBindings.ini` を変更し、再起動する。

## 4.0 Mode別の最小有効Schema

`Label` はWindow専用Fieldではなく、**Window / Shortcut / Disabledすべてで必須**。

最小例:

```ini
; Window
[Key-NumpadDiv]
Mode=Window
Label=Window Test
AllowedProcess=
AllowedClass=
AllowedTitleContains=

; Shortcut
[Key-NumpadDiv]
Mode=Shortcut
Label=Shortcut Test
Target=notepad.exe

; Disabled
[Key-NumpadDiv]
Mode=Disabled
Label=Disabled Test
```

Shortcutでは `Arguments` / `WorkingDirectory` は任意なので省略可能。
Disabledでは `Mode` / `Label` 以外のFieldを置かない。

したがって、次の設定は無効:

```ini
[Key-NumpadDiv]
Mode=Shortcut
Target=C:\path\to\example.bat
```

理由: 共通必須Field `Label` がない。

また、Target Pathが存在しない場合は、Labelを追加した後にTarget ValidationでFatalになる。

Fatalが期待される試験では:

- `NumpadWindowController startup error` が表示される
- 常駐開始しない
- Hotkeyを登録しない
- Config Validation前の副作用を残さない

ことも観察する。

## G-1-1 正常設定

手順:

1. バックアップから標準 `KeyBindings.ini` を復元する。
2. 本体を起動する。
3. Startup Errorが出ないことを確認する。
4. Numpad1～9等の通常操作が使用可能なことを確認する。
5. 正常終了する。

期待:

- UTF-16 LE BOM / ConfigVersion=1の標準Configで正常起動。
- 実行中はNumLock ON。
- 正常終了時に元のNumLock状態へ復元。

## G-1-2 不正Mode

例として `Key-NumpadDiv` を変更する。

```ini
Mode=Invalid
```

手順:

1. 本体停止。
2. 上記へ変更。
3. 本体起動。

期待:

- 起動時Fatal。
- Scriptは常駐しない。

終了後、Configを復元する。

## G-1-3 未知Section / Section不足 / 未知Field

3ケースに分ける。

### A. 未知Section

末尾に追加:

```ini
[Key-Unknown]
Mode=Disabled
Label=Unknown
```

期待: 起動時Fatal。

### B. 必須Section不足

例: `[Key-NumpadDot]` Section全体を一時削除。

期待: 起動時Fatal。

### C. 未知Field

例:

```ini
[Key-NumpadDiv]
Mode=Window
Label=Slash
AllowedProcess=
AllowedClass=
AllowedTitleContains=
UnknownField=1
```

期待: 起動時Fatal。

各ケース終了後にConfigを復元する。

## G-1-4 重複Section / Field

### A. Section重複

既存 `[Key-NumpadDiv]` と同名Sectionを末尾へ追加。

期待: Duplicate sectionとして起動時Fatal。

### B. Field重複

同一Section内へ同じFieldを2回書く。

```ini
Mode=Window
Mode=Disabled
```

期待: Duplicate fieldとして起動時Fatal。

## G-1-5 専用Slotの不整合

代表ケースを実施する。

### A. 専用SlotをWindow以外にする

`Key-Numpad7` を `Mode=Disabled` に変更し、Window用Fieldを削除する。

期待: 専用Slot 1～9はWindow固定のため起動時Fatal。

### B. Chrome GroupのAllowed不一致

例としてNumpad7のみ:

```ini
AllowedProcess=notepad.exe
```

へ変更する。

期待: 7/8/9のAllowed条件不一致として起動時Fatal。

VS Code 4/5/6についても同じRuleが自動テストで確認済みなので、Phase Gでは少なくともChrome代表ケースを実機確認する。

## G-1-6 Shortcut Target不存在

`Key-NumpadDiv` を次へ置換する。

```ini
[Key-NumpadDiv]
Mode=Shortcut
Label=Missing Target
Target=C:\__NWC_PHASE_G__\missing.exe
Arguments=
WorkingDirectory=
```

期待:

- Targetを解決できず起動時Fatal。

## G-1-7 .ps1直接Target拒否

実在する任意の `.ps1` を用意し、`Key-NumpadDiv` のTargetへ直接指定する。

```ini
Mode=Shortcut
Label=Direct PS1
Target=C:\path\to\test.ps1
Arguments=
WorkingDirectory=
```

期待:

- `.ps1` は直接Target非対応として起動時Fatal。

## G-1-8 Numpad0 / Virtual000整合

`Key-Numpad0`:

```ini
Mode=Disabled
Label=Zero
```

`Key-Virtual000` はWindowのまま残す。

期待:

- `Numpad0=Disabled` かつ `Virtual000!=Disabled` のため起動時Fatal。

## G-1-9 Backspace Warning

`Key-Backspace` を一時的にWindow Modeへ変更する。

```ini
[Key-Backspace]
Mode=Window
Label=Backspace Test
AllowedProcess=
AllowedClass=
AllowedTitleContains=
```

期待:

- Config自体は有効。
- 起動時に、テンキーBackspaceと通常Keyboard Backspaceを区別できない旨のWarningが表示される。
- OK後は起動継続。

試験後は必ず標準Disabledへ戻す。

## G-1-10 全ModeでLabel必須

Window / Shortcut / Disabledの代表ケースとしてNumpadDivを使う。

### A. ShortcutでLabel欠落

```ini
[Key-NumpadDiv]
Mode=Shortcut
Target=notepad.exe
```

期待:

- 起動時Fatal。
- ErrorのFieldが `Label`。
- Reasonが必須Field不足を示す。

### B. DisabledでLabel空欄

```ini
[Key-NumpadDiv]
Mode=Disabled
Label=
```

期待:

- 起動時Fatal。
- `Label` 空欄を拒否。

Window ModeのLabel必須はPhase F自動テストでも確認済みだが、必要なら同様に実機確認する。

## G-1-11 Mode別Field混在の拒否

### A. ShortcutにWindow用Fieldを残す

```ini
[Key-NumpadDiv]
Mode=Shortcut
Label=Shortcut Test
Target=notepad.exe
AllowedProcess=chrome.exe
```

期待:

- `AllowedProcess` はShortcut Modeで許可されないため起動時Fatal。

### B. Disabledに追加Fieldを残す

```ini
[Key-NumpadDiv]
Mode=Disabled
Label=Disabled Test
Target=notepad.exe
```

期待:

- `Target` はDisabled Modeで許可されないため起動時Fatal。

この試験により、Mode変更後の旧Mode用Fieldが残ったstale設定も検出できる。


---

# 5. G-2 Manual Bindテスト

共通準備:

1. 標準Configへ復元。
2. Chrome 1Window以上、VS Code 1Window以上を起動。
3. 本体起動。
4. `Ctrl + Shift + NumpadEnter` でClear All。
5. 必要ならDebugをONにする。

## G-2-1 Chrome -> 7/8/9 成功

1. Chrome Window AをActiveにする。
2. `Ctrl + Numpad7`。
3. 別WindowをActiveにする。
4. `Numpad7`。

期待:

- Manual Bind成功通知。
- Numpad7でChrome Aへ移動。

Numpad8 / 9も同様に確認する。

## G-2-2 VS Code -> 7/8/9 拒否

状態保存も確認するため次の順で行う。

1. Chrome Aを `Ctrl + Numpad7` でManual Bind。
2. VS Code AをActiveにする。
3. `Ctrl + Numpad7`。
4. 別Windowへ移動。
5. `Numpad7`。

期待:

- VS CodeはAllowed違反として拒否。
- 既存Chrome A Bindingは変更されない。
- Numpad7は引き続きChrome Aへ移動。

8 / 9も同Ruleであるため、代表として7を必須確認する。

## G-2-3 VS Code -> 4/5/6 成功

G-2-1と同じ方法でVS Codeを4 / 5 / 6へManual Bindし、各キーで戻れることを確認する。

## G-2-4 Chrome -> 4/5/6 拒否

VS Code AをNumpad4へManual Bindした状態を作る。

その後:

1. Chrome AをActive。
2. `Ctrl + Numpad4`。
3. 別Windowへ移動。
4. `Numpad4`。

期待:

- Chromeは拒否。
- Numpad4の既存VS Code Bindingは維持。

## G-2-5 1 / 2 / 3専用条件

専用対象ではないWindow、例としてVS CodeをActiveにし:

- `Ctrl + Numpad1`
- `Ctrl + Numpad2`
- `Ctrl + Numpad3`

を個別に試す。

期待:

- すべてAllowed違反として拒否。
- Slot Stateを変更しない。

その後、それぞれExplorer / ChatGPT Desktop / PowerShell 7 Windows TerminalではManual Bind可能なことも確認する。

## G-2-6 1 HWND : 1 Slot

AutoBind=OFFの任意Slotを使う。

1. Notepad等の一般Window AをActive。
2. `Ctrl + NumpadDiv` でSlashへManual Bind。
3. 同じWindow Aのまま `Ctrl + NumpadMult`。
4. 別Windowへ移動。
5. `NumpadMult`。
6. `NumpadDiv`。

期待:

- NumpadMultはWindow Aへ移動。
- 旧Slash SlotはNone。
- SlashはAutoBind=OFFなので別Windowへ自動補充されない。
- Debug Log使用時は同一HWNDが複数Slotへ存在しない。

## G-2-7 Shortcut ModeではManual Bindしない

NumpadDivを、まず最小有効Shortcut Configへ変更する。

```ini
[Key-NumpadDiv]
Mode=Shortcut
Label=Shortcut Manual Bind Test
Target=notepad.exe
```

`Arguments` / `WorkingDirectory` はこの試験では不要なので省略可能。

1. 本体を再起動し、Config Validationを通過することを確認する。
2. 一般Window AをActive。
3. `Ctrl + NumpadDiv`。
4. 通常 `NumpadDiv`。

期待:

- Ctrl+NumpadDivはController Manual Bindとして処理されない。
- Runtime Bindingを作らない。
- 通常NumpadDivではShortcutが実行される。

## G-2-8 Disabled Mode

NumpadDivを次へ変更:

```ini
[Key-NumpadDiv]
Mode=Disabled
Label=Slash Disabled Test
```

1. 本体再起動。
2. テキスト入力可能なアプリをActive。
3. 物理 `/` を押す。
4. `Ctrl + /` も必要に応じて確認する。

期待:

- Controller Hotkeyとして登録されない。
- ネイティブ入力がActive Appへ渡る。
- Runtime Bindingを作らない。

---

# 6. G-3 Chrome Auto Bindテスト

必要に応じて `poc/phase_b/B2_B4_ChromeLayoutPoC.ahk` を使い、現在位置がどのChrome分類条件を満たすか確認する。

基本配置:

- 左上 = Numpad7
- 左下 = Numpad8
- 右大 = Numpad9
- Primary Monitor上

各ケース開始前:

```text
Ctrl + Shift + NumpadEnter
→ Clear All

Ctrl + NumpadEnter
→ Auto Bind All
```

## G-3-1 1Window

Chromeを1Windowだけ対象状態にする。

例: 左上へ配置。

期待:

- 7だけBinding。
- 8 / 9はNone。

同様に左下だけなら8、右大だけなら9へ入ることも可能なら確認する。

## G-3-2 2Window

例:

- 左上
- 右大

の2Windowを用意。

期待:

- 7と9だけBinding。
- 8はNone。
- 「7から順に詰める」のではなく、位置に対応するSlotへ入る。

## G-3-3 3Window

左上 / 左下 / 右大を揃える。

期待:

- 7 = 左上
- 8 = 左下
- 9 = 右大

各キーを押して実Windowへ移動することで確認する。

## G-3-4 4Window以上

通常3Window配置に追加Chrome Windowを1つ以上用意する。

期待:

- 専用Slotは7 / 8 / 9の最大3つ。
- 余剰Chromeを `/ * - + 0 000 . Enter` 等へ自動転送しない。

## G-3-5 座標Tolerance

1. 3Window正常配置でAuto Bind。
2. Clear All。
3. 各Windowを数px～十数px程度移動する。
4. Phase B Threshold内であることをPoCで確認できる場合は確認。
5. Auto Bind All。

期待:

- Threshold内なら同じ7 / 8 / 9分類になる。

## G-3-6 Primary Monitor外

1. Chrome 1WindowをSecondary Monitorへ移動。
2. Clear All。
3. Auto Bind All。

期待:

- Secondary Monitor上のChromeは新規Chrome Auto Bind候補にならない。

## G-3-7 Minimized / Maximizedを新規候補にしない

### Minimized

1. 対象ChromeをMinimize。
2. Clear All。
3. Auto Bind All。

期待: Minimized Chromeは新規座標分類されない。

### Maximized

1. Clear All。
2. Chrome 1WindowをMaximize。
3. Auto Bind All。

期待: Maximized Chromeは新規座標分類されない。

## G-3-8 既存Bindingの維持

1. 通常配置3Windowで7 / 8 / 9をAuto Bind。
2. 7のChromeをMinimize。
3. Auto Bind All。
4. Numpad7を押す。

期待:

- 既存Bindingは維持。
- 押下時にRestoreしてActivateできる。

追加確認:

1. 7のChromeを通常状態へ戻す。
2. 元の左上位置から別位置へ移動。
3. Auto Bind All。

期待:

- HWND + Allowed条件が有効なら、座標変更だけを理由に既存7 Bindingを解除 / 再ソートしない。

## G-3-9 Chrome再起動

1. 3Window正常配置でAuto Bind。
2. 対象Chrome Windowを閉じる。
3. 同じ用途の新しいChrome Windowを開き、対応位置へ配置。
4. Auto Bind All、または該当キー通常押下でLazy Auto Bind。

期待:

- 旧HWNDは無効化。
- 新HWNDを現在座標から分類し直す。
- 対応Slotが復旧する。

---

# 7. G-4 VS Code Auto Bindテスト

VS Codeの「真のOpen順」は期待値にしない。
現行仕様はAuto Bind時点の未使用 `Code.exe` Windowを `WinGetList` の逆順にし、空き4→5→6へ割り当てる。

順序を厳密に観測したい場合:

```text
poc/phase_b/B5_VSCodeOrderPoC.ahk
```

を使用し、F5 Snapshotの列挙順を参考にする。

## G-4-1 1Window

1. VS Code 1Windowだけを対象状態にする。
2. Clear All。
3. Auto Bind All。

期待:

- Numpad4へBinding。
- 5 / 6はNone。

## G-4-2 2Window

1. VS Code 2Windowを用意。
2. 必要ならB5 PoCでSnapshot。
3. Clear All。
4. Auto Bind All。
5. 4 / 5を押して割り当てを確認。

期待:

- 未使用候補のWinGetList逆順を空き4→5へ割り当て。
- 6はNone。

## G-4-3 3Window

2Windowと同じ手順で3Windowを用意。

期待:

- WinGetList逆順で4→5→6。

## G-4-4 4Window以上

4Window以上用意しClear All → Auto Bind All。

期待:

- 最大3Windowだけ4 / 5 / 6へBinding。
- 余剰VS Codeを任意Slotへ自動転送しない。

## G-4-5 真のOpen順を期待しない

B5 PoCでOpen順とSnapshot列挙順が異なる状態でも、合否はOpen順ではなくAuto Bind時点の逆列挙Ruleで判定する。

この試験の目的は旧仕様「真のOpen順」を誤って期待しないことの確認。

## G-4-6 有効Bindingを再ソートしない

1. 3Windowを4 / 5 / 6へAuto Bind。
2. VS Code Windowを順番にActivateしてZ-orderを変える。
3. Auto Bind All。
4. 4 / 5 / 6を押す。

期待:

- 既存HWNDが有効な限り割り当ては維持。
- 新しいWinGetList順に再ソートしない。

## G-4-7 VS Code再起動

1. 4 / 5 / 6をAuto Bind。
2. 1つのVS Code Windowを閉じる。
3. 新しいVS Code Windowを開く。
4. Auto Bind All。

期待:

- 閉じた旧HWNDをNoneへ落とす。
- 新しい未使用候補で空Slotを補充。
- 他の有効Bindingは維持。

## G-4-8 Window Close後のLazy補充

1. 4 / 5 / 6をAuto Bind。
2. 例としてNumpad5のWindowを閉じる。
3. 新しいVS Code候補を用意。
4. `Numpad5` を通常押下。

期待:

- 無効5 Bindingを検出。
- VS Code Group単位で空Slotを補充。
- Numpad5の新BindingをActivate。

---

# 8. G-5 Numpad1 / 2 / 3テスト

必要に応じて:

```text
poc/phase_b/B6_B8_TargetAppsPoC.ahk
```

でProcess / Class / Titleを確認する。

## G-5-1 Explorer

1. Explorer Windowを開く。
2. Clear All。
3. Auto Bind All。
4. 別Windowへ移動。
5. Numpad1。

期待:

- `explorer.exe`
- `CabinetWClass`

を満たすExplorerへ移動。

Taskbar / Desktop等は対象にしない。

## G-5-2 ChatGPT Desktop

同様にChatGPT Desktopを起動。

期待:

- `ChatGPT.exe` WindowをNumpad2へBinding。
- Numpad2でActivate。

## G-5-3 PowerShell 7 Windows Terminal

PowerShell 7を開いたWindows Terminal Windowを用意。

期待条件:

```text
Process = WindowsTerminal.exe
Class = CASCADIA_HOSTING_WINDOW_CLASS
Title contains "PowerShell 7"
```

Clear All → Auto Bind All → Numpad3で確認。

## G-5-4 Numpad3対象外Terminal

PowerShell 7 Windowとは別に、Windows TerminalでcmdまたはWindows PowerShell等を開く。

期待:

- `PowerShell 7` Title条件を満たさないWindowはNumpad3候補にしない。
- PowerShell 7 Windowが存在すればそちらを選ぶ。

## G-5-5 対象アプリ不存在

対象の1つを完全に閉じた状態でClear All → Auto Bind All。

例: ChatGPT Desktopを終了。

期待:

- 対応SlotはNoneのまま。
- ErrorでScript全体を終了しない。

## G-5-6 複数候補

最低限Explorerで確認する。

### 非Minimized優先

1. Explorerを2Window用意。
2. AをMinimize。
3. Bを通常状態。
4. Clear All → Auto Bind All。
5. Numpad1。

期待: Bを選択。

### Z-order優先

1. Explorer A / Bを両方Normal。
2. Aを最後にActivateしZ-orderを前へ。
3. Clear All → Auto Bind All。
4. Numpad1。

期待: 同条件ならZ-orderが前のAを選択。

ChatGPT / PowerShellで複数Windowを作れる環境では同Ruleも追加確認する。

---

# 9. G-6 Shortcutテスト

任意キーNumpadDivを試験用Shortcut Slotにする。
専用Slot 1～9はShortcutへ変更しない。

## 9.1 Fixture準備

PowerShellで一時Directoryを作る。

```powershell
$PhaseG = Join-Path $env:TEMP "NumpadWindowController-PhaseG"
New-Item -ItemType Directory -Force $PhaseG | Out-Null
```

BAT:

```powershell
@'
@echo off
echo BAT %DATE% %TIME% %*>> "%TEMP%\nwc_phaseg_runs.txt"
'@ | Set-Content (Join-Path $PhaseG "phaseg.bat") -Encoding ascii
```

CMD:

```powershell
@'
@echo off
echo CMD %DATE% %TIME% %*>> "%TEMP%\nwc_phaseg_runs.txt"
echo CWD=%CD%>> "%TEMP%\nwc_phaseg_runs.txt"
'@ | Set-Content (Join-Path $PhaseG "phaseg.cmd") -Encoding ascii
```

LNKはPowerShellから作成できる。

```powershell
$ws = New-Object -ComObject WScript.Shell
$lnk = $ws.CreateShortcut((Join-Path $PhaseG "phaseg.lnk"))
$lnk.TargetPath = "$env:WINDIR\System32\notepad.exe"
$lnk.Save()
```

試験後:

```powershell
Remove-Item $PhaseG -Recurse -Force
Remove-Item (Join-Path $env:TEMP "nwc_phaseg_runs.txt") -ErrorAction SilentlyContinue
```

## G-6-1 exe

NumpadDiv:

```ini
[Key-NumpadDiv]
Mode=Shortcut
Label=EXE Test
Target=notepad.exe
Arguments=
WorkingDirectory=
```

本体再起動後、NumpadDiv。

期待: Notepad起動。

## G-6-2 bat

`Target=<PhaseG Directory>\phaseg.bat` とする。

期待:

- BATが実行される。
- `%TEMP%\nwc_phaseg_runs.txt` にBAT行が追加される。

## G-6-3 cmd

同様に `phaseg.cmd` をTargetへ指定。

期待: CMD行が追加される。

## G-6-4 lnk

`phaseg.lnk` をTargetへ指定。

期待: Shortcut経由でNotepad起動。

## G-6-5 Arguments

CMD Targetで:

```ini
Arguments=alpha "beta gamma"
```

期待:

- 出力ファイルに渡したArgumentsが反映される。
- 空白を含むquoted argumentが壊れない。

## G-6-6 Working Directory

CMD Targetで `WorkingDirectory=<PhaseG Directory>` を指定。

期待:

- 出力された `CWD=` が指定Directoryになる。

## G-6-7 押下ごとにRun

BATまたはCMDをShortcutとして設定。

1. NumpadDivを3回押す。
2. `nwc_phaseg_runs.txt` を確認。

期待:

- 3回分の実行記録が増える。
- 既存Window検索 / Activateへ置き換えない。

## G-6-8 Runtime Target消失

1. 有効なCMD Targetで本体起動。
2. 起動後にTargetファイルをRenameまたは削除。
3. NumpadDiv。

期待:

- Shortcut実行失敗を通知。
- Scriptは継続。
- 他のWindowキーは引き続き使用可能。

## G-6-9 Window Binding対象外

Shortcut ModeのNumpadDivで:

- Ctrl+NumpadDivによるManual Bindを作らない。
- Auto Bind AllでもSlot Bindingを作らない。
- 通常押下はShortcut実行。

を確認する。

---

# 10. G-7 Clear / Lazy Bindテスト

## G-7-1 Slot Clear直後

1. Explorer等ではなく、AutoBind=OFFの任意Slotへ一般WindowをManual Bind。
2. `Ctrl + Shift + <そのKey>`。
3. 何も押さず数秒待つ。
4. Debug Logまたは次の通常押下で確認。

期待:

- SlotはNone。
- Clear直後の即時Auto Bindなし。

## G-7-2 Clear All直後

1. 専用Slot 1～9をできる範囲でBinding済みにする。
2. `Ctrl + Shift + NumpadEnter`。
3. 数秒待つ。

期待:

- 全Runtime BindingがNone。
- Clear All自体はAuto Bindを起動しない。

Debug ONの場合、Clear後から次操作まで `Auto Bind start:` が無いことを確認できる。

## G-7-3 Clear All後の明示再構築

G-7-2直後:

1. `Ctrl + NumpadEnter`。
2. 専用キーを押して確認。

期待:

- 専用Slot 1～9のみ、存在する候補に応じて再構築。
- 任意Slotは自動補充しない。

## G-7-4 通常押下によるLazy Auto Bind

1. Clear All。
2. Explorerを開いた状態でNumpad1。

期待:

- Numpad1だけLazy探索。
- ExplorerをBindingしてそのままActivate。

## G-7-5 HWND消滅後

1. ExplorerをNumpad1へBinding。
2. そのExplorer Windowを閉じる。
3. 別Explorer Windowを用意。
4. Numpad1。

期待:

- 旧HWNDを無効と判定。
- SlotをNoneへ落とす。
- 新候補をLazy Bind。
- 新WindowをActivate。

## G-7-6 Chrome / VS Code Group Lazy Bind

### Chrome

1. Chrome 3Windowを通常配置。
2. Clear All。
3. Numpad7だけ押す。
4. 続けて8 / 9を押す。

期待:

- Numpad7押下時のLazy Auto BindでChrome Group全体の空Slotを補充。
- 8 / 9も追加Auto Bindなしで利用可能。

### VS Code

同様に3WindowでClear All → Numpad4 → 5 / 6。

期待: VS Code Group全体を補充。

## G-7-7 1 / 2 / 3はSlot単位

1. Explorer / ChatGPT / PowerShell 7をすべて起動。
2. Clear All。
3. Numpad1だけ押す。
4. Debug Snapshotを確認、または2 / 3の挙動を観察。

期待:

- Lazy処理の対象はNumpad1のみ。
- Numpad2 / 3はこの操作だけでは一緒に補充しない。

## G-7-8 AutoBind=OFF / Shortcut / Disabled

### AutoBind=OFF

一般WindowをNumpadDivへManual Bind → Windowを閉じる → NumpadDiv。

期待: 別Windowを勝手に補充しない。

### Shortcut

通常押下はShortcutのみで、Lazy Window探索しない。

### Disabled

Controller処理自体を行わない。

## G-7-9 Manual Binding優先

1. Chrome AをNumpad7へManual Bind。
2. AをChrome1想定位置とは別の位置へ移動してもよい。
3. 他Chrome候補を通常配置。
4. `Ctrl + NumpadEnter`。
5. Numpad7。

期待:

- 有効Manual Bindingを維持。
- Auto Bind Allで上書きしない。

---

# 11. G-8 長時間常駐テスト

標準Config / `DEBUG_ENABLED=false` を基本とする。
普段の作業に近い状態で数時間常駐させる。

開始時に:

- 開始日時
- Commit
- 起動中アプリ
- 初期Binding状態

を記録する。

## G-8-1 数時間常駐

目安として2～4時間程度、通常操作を継続する。

観察:

- Script crashなし
- AutoHotkey Error Dialogなし
- キー入力遅延の増大なし
- ToolTipが残留しない
- Bindingが理由なく消えない

## G-8-2 Chromeタブ変更

Binding済みChromeで:

- 複数回タブ変更
- タイトル変化
- ページ遷移

を行う。

期待:

- Process等のAllowed条件が有効な限りBinding維持。
- タブTitle変更だけで解除されない。

## G-8-3 Window増減

常駐中にChrome / VS Code / Explorer等を開閉する。

期待:

- 常時監視による勝手な再配置はしない。
- 必要なLazy / 明示Auto Bind時に欠損だけ補修。
- 同一HWNDを複数Slotへ残さない。

## G-8-4 Sleep / Resume

1. Script常駐状態でWindowsをSleep。
2. Resume。
3. Numpad1～9等を操作。
4. Auto Bind Allも実行。

期待:

- Resume後もHotkey / Window Activateが利用可能。
- Script crashなし。

## G-8-5 Explorer再起動

Task Managerの「Windows Explorer → 再起動」等、安全な通常手段でExplorerを再起動する。

その後Numpad1。

期待:

- 古いExplorer HWNDを無効化。
- 新しいExplorer Windowが存在すればLazy / Auto Bindで復旧。
- Controller全体は継続。

## G-8-6 Script再起動

1. 現在のBinding状態をメモ。
2. 本体を正常終了。
3. 再起動。
4. 1～9を確認。

期待:

- HWNDをConfig等から永続復元しない。
- Startup Auto Bindで現在存在するWindowから新しいRuntime Bindingを構築。
- 正常終了 / 再起動前後でNumLock lifecycleも正常。

---

# 12. Phase G中の共通異常確認

全試験を通じて次を確認する。

- Scriptが予期せず終了しない
- AutoHotkey Error Dialogが予期せず表示されない
- 同一HWNDが複数Slotへ残らない
- Allowed違反時に既存Bindingを壊さない
- 任意Slotへ一般Windowを勝手にAuto Bindしない
- 余剰Chrome / VS Codeを任意Slotへ自動転送しない
- Clear直後に意図しないAuto Bindをしない
- ToolTipが残留しない
- NumLockが異常状態に残らない
- Disabled KeyがControllerに奪われない
- Shortcut Runtime FailureでController全体が終了しない

---

# 13. Phase G完了条件

Phase G完了には次を満たす。

1. `TASKS.md` のG-1～G-8をすべて実施。
2. 各項目をPASS / FAIL / BLOCKEDで記録。
3. FAILがある場合、修正後に該当試験を再実施。
4. Phase F Regressionで新規FAILなし。
5. Phase Gによる未解決の機能不具合が残っていない。
6. Known Limitationとして受け入れる事項は、設計と結果文書へ明記。

Phase G完了後はPhase H - 実機受入試験へ進む。

---

# 14. 結果文書

Phase G実施結果は別途:

```text
docs/PHASE_G_RESULT.md
```

へ集約する。

最低限記録する内容:

- 実施環境
- 実施Commit
- 各Test IDの結果
- 使用したConfig差分
- FAILと修正内容
- Debug Log / PoC結果への参照
- Phase F Regression結果
- Phase G最終判定

