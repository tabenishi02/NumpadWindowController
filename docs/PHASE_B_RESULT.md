# Numpad Window Controller - Phase B Result

更新日: 2026-09-24  
対象: MVP / v0.1.0  
状態: Phase B Complete

## 1. 結論

Phase Bの実機PoC結果から、MVP実装に必要なWindow識別方式を確定できた。

判定:

- B-1 Window列挙: PASS
- B-2 Chrome識別: PASS
- B-3 Chrome Tolerance: PASS
- B-4 Monitor方針: PASS
- B-5 VS Code順序: PASS（方式変更あり）
- B-6 Explorer識別: PASS
- B-7 ChatGPT Desktop識別: PASS
- B-8 PowerShell系Terminal識別: PASS

追加PoCはMVPには不要と判断する。

---

## 2. 使用した実機結果

主な入力:

- B1_windows_20260924022040_669830953.tsv
- B2_B4_chrome_layout_20260924042115_677065890.tsv
- B2_B4_chrome_layout_20260924042133_677083703.tsv
- B2_B4_chrome_layout_20260924042148_677098859.tsv
- B2_B4_chrome_layout_20260924042231_677141593.tsv
- 対応するMonitor TSV ×4
- B5_vscode_order_20260924024131_671081828.tsv
- B5_vscode_order_20260924024658_671408562.tsv
- B5_vscode_order_20260924024811_671482015.tsv
- B6_B8_target_apps_20260924042517_677307500.tsv
- 手動記録.md

Chromeケース:

- Case A: 通常3Window配置
- Case B: 左下Chromeを最小化
- Case C: 左上Chromeを最大化
- Case D: Chrome再起動後、通常3Window配置

VS Codeの実際のOpen順:

1. CharacterPageCollector
2. CodexMobileDashboard
3. ComputerActivityArchive

---

# 3. B-1 Window列挙

## 3.1 結果

AutoHotkey v2から、MVPに必要なWindow metadataを取得できた。

確認済み:

- HWND
- Z-order
- Process Name
- PID
- Process Creation FILETIME
- Class
- Title
- Position / Size
- MinMax
- Style / ExStyle
- Visible
- Owner
- DWM Cloaked
- ToolWindow
- Monitor

暫定Candidate Filter:

- Visible
- DWM Cloakedではない
- Ownerなし
- ToolWindowではない
- Width / Height > 0
- Titleあり

は実機で有効だった。

タスクバー、Secondary Taskbar、Progman、PseudoConsoleWindow等は候補から除外された。

## 3.2 最小化Window

通常アプリの最小化WindowはCandidateとして残るが、WinGetPos値は例として:

- X = -32000
- Y = -32000
- Width = 160
- Height = 28
- MinMax = -1

となった。

したがって:

- Process / Class / Title / HWNDによる識別には利用可能
- 現在座標によるレイアウト識別には利用不可

とする。

---

# 4. B-2 / B-3 Chrome

## 4.1 通常配置

現行のMVP Thresholdで3Windowをすべて正しく分類できた。

### Chrome1 / 左上

実測:

- Center X = 0.2034
- Center Y = 0.2516
- Width Ratio = 0.4062
- Height Ratio = 0.5032
- match_chrome1 = 1

### Chrome2 / 左下

実測:

- Center X = 0.1905
- Center Y = 0.7500
- Width Ratio = 0.3799
- Height Ratio = 0.4944
- match_chrome2 = 1

### Chrome3 / 右大

実測:

- Center X = 0.7022
- Center Y = 0.5000
- Width Ratio = 0.5956
- Height Ratio = 1.0000
- match_chrome3 = 1

当初の「左30% / 右70%」は概念値であり、実配置は概ね左40% / 右60%だった。

ただし現在のThresholdには十分収まるため、MVPではThresholdを変更しない。

## 4.2 採用するThreshold

Chrome1:

- Center X < 0.40
- Center Y < 0.50
- Width Ratio 0.15 ～ 0.45
- Height Ratio 0.30 ～ 0.70

Chrome2:

- Center X < 0.40
- Center Y >= 0.50
- Width Ratio 0.15 ～ 0.45
- Height Ratio 0.30 ～ 0.70

Chrome3:

- Center X >= 0.40
- Width Ratio 0.50 ～ 0.90
- Height Ratio 0.70 ～ 1.05

複数候補時のみIdeal Rectangle ScoreをTie Breakerとして使用する。

## 4.3 Chrome再起動

再起動後はHWNDが変更されたが、3Windowとも同じ座標Ruleで正しく再分類できた。

したがって座標ベースAuto Bindは再起動後の再構築に利用可能。

## 4.4 最小化 / 最大化

左下Chromeを最小化したCase Bでは、そのWindowは現在座標から分類不能だった。

左上Chromeを最大化したCase Cでも、そのWindowは:

- X = -8
- Y = -8
- Width = 3856
- Height = 2176
- Width Ratio ≈ 1.004
- Height Ratio ≈ 1.007

となり、元の「左上Slot」を現在座標から識別できない。

MVP方針:

- すでにHWND Binding済みなら、最小化 / 最大化後もBindingを維持する。
- Auto Bindをゼロから行う時は、ChromeのNormal状態Windowだけを座標分類対象とする。
- Minimized / Maximized Chromeは座標による新規Auto Bind対象外。
- 必要ならWindowを通常状態へ戻してAuto Bind Allを再実行するか、Manual Bindする。

これはMVP Known Limitationとする。

---

# 5. B-4 Monitor

実機:

- Monitor 1: 3840×2160、左側、非Primary
- Monitor 2: 3840×2160、右側、Primary
- Primary Monitor Work Area = 0,0 ～ 3840,2160
- Chrome 3WindowはすべてPrimary Monitor上

したがってMVPでは:

- Chrome座標判定はPrimary Monitor Work Area固定
- Secondary Monitor上のChromeは専用7/8/9 Auto Bind対象外

とする。

Multi Monitor自動追従はMVP後の拡張対象。

---

# 6. B-5 VS Code Open Order

## 6.1 スクリプト起動前から3Windowがある場合

実際のOpen順:

1. CharacterPageCollector
2. CodexMobileDashboard
3. ComputerActivityArchive

初回観測順:

1. ComputerActivityArchive
2. CodexMobileDashboard
3. CharacterPageCollector

となり、真のOpen順と一致しなかった。

3Windowはすべて:

- 同一 PID
- 同一 Process Creation FILETIME

だった。

したがって:

- Z-order / WinGetList順
- PID
- Process Creation Time

から、スクリプト起動前の真のVS Code Window Open順を復元することはできないと判断する。

## 6.2 PoC実行中に順番に開いた場合

500ms観測を行えば実Open順を取得できること自体は確認できた。

ただし、ユーザー要件ではVS Codeの厳密なOpen順に大きなこだわりはなく、順序精度のために常時監視を追加する必要はない。

## 6.3 MVP方式

MVPではVS Code専用の定期監視を採用しない。

Auto Bind時だけ現在の `Code.exe` Windowを列挙し、次の単純な規則を使用する。

1. 有効な既存Bindingを維持する。
2. すでに他SlotへBinding済みのHWNDを候補から除外する。
3. 残った `Code.exe` Windowを `WinGetList` の列挙順から逆順にする。
4. 空いている `Numpad4 → Numpad5 → Numpad6` の順で割り当てる。
5. 4つ目以降はMVPでは自動割り当てしない。

実機PoCでは、起動前3Windowの `WinGetList` 順が実Open順の逆順になっていたため、この簡易規則で期待順と一致した。

ただし、これは真のOpen順を保証する規則ではない。Z-order等により順序が異なる場合は許容し、必要な場合だけ `Ctrl + Numpad4 / 5 / 6` でManual Bindして補正する。

この方式では:

- 500ms監視不要
- Observation Sequence不要
- PID / Process Creation Timeによる順序復元不要

となり、MVP実装を単純化できる。

---

# 7. B-6 Explorer

通常Explorer Windowの実測:

- Process = explorer.exe
- Class = CabinetWClass
- Candidate = 1

Shell系:

- Shell_TrayWnd
- Shell_SecondaryTrayWnd
- Progman

はCandidate Filterから除外できた。

MVP識別条件:

- Process = explorer.exe
- Class = CabinetWClass

複数候補時:

- MinimizedではないWindowを優先
- その中で最もZ-orderが前のWindowを採用

---

# 8. B-7 ChatGPT Desktop

実測:

- Process = ChatGPT.exe
- Class = Chrome_WidgetWin_1
- Title = ChatGPT
- Candidate = 1

MVP識別条件:

- Process = ChatGPT.exe を必須条件とする。

Chrome_WidgetWin_1はChrome / VS Code等でも使用されるため、Class単独では識別に使用しない。

Classは補助条件・診断情報として保持する。

複数候補時:

- MinimizedではないWindowを優先
- その中で最もZ-orderが前のWindowを採用

---

# 9. B-8 PowerShell / Windows Terminal

実測したトップレベルWindow:

- Process = WindowsTerminal.exe
- Class = CASCADIA_HOSTING_WINDOW_CLASS

Title例:

- PowerShell 7
- Windows PowerShell
- C:\WINDOWS\system32\cmd.exe

一方、pwsh.exe自体は:

- Class = PseudoConsoleWindow
- Ownerあり
- ToolWindow
- Zero Size
- Candidate = 0

だった。

したがって、この環境ではpwsh.exeを直接トップレベルWindowとしてBindingしない。

MVPのNumpad3識別条件:

- Process = WindowsTerminal.exe
- Class = CASCADIA_HOSTING_WINDOW_CLASS
- Titleに "PowerShell 7" を含む

このTitle条件は、Windows PowerShellやcmd.exeのWindows Terminal Windowを除外するために必要。

Configuration設計では Title条件を表現できるフィールドを追加する。

候補:

- AllowedTitleContains=PowerShell 7

Standalone pwsh.exeトップレベルWindowへの対応は、この環境のMVPでは必須としない。

---

# 10. Phase BからPhase C / Dへの引き継ぎ

## 10.1 共通Window Candidate

基本Filter:

- Visible
- not Cloaked
- Owner = 0
- not ToolWindow
- Width / Height > 0
- Title != empty

ただし最小化Windowは識別候補として保持する。

## 10.2 Minimized優先順位

Process / Class等で識別できる固定用途Slotでは:

1. 非Minimized候補
2. Minimized候補

の順に優先する。

Chrome座標分類ではMinimized / Maximizedを新規分類対象外とする。

## 10.3 VS Code

- VS Code専用の常時監視は採用しない。
- Auto Bind時に `Code.exe` を列挙し、未使用候補を逆順にして空き4→5→6へ割り当てる。
- 有効な既存Bindingは維持する。
- 真のOpen順は保証しない。
- Manual Bind補正を正式Fallbackとする。

## 10.4 Configuration追加要件

Phase DでTitle条件を追加する。

最低限:

- AllowedTitleContains

が必要。

主用途はNumpad3のPowerShell 7識別。

---

# 11. Phase B完了

Phase Bの技術検証によって、MVPのWindow識別に必要な情報取得方式とKnown Limitationを確定できた。

次工程:

Phase C - Auto Bindアルゴリズム確定
