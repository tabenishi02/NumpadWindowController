# Numpad Window Controller - Phase B PoC Guide

更新日: 2026-09-23  
対象: MVP / v0.1  
状態: PoC implementation complete / execution pending

## 1. 目的

Phase Bでは、設計上必要なWindow識別情報をWindows / AutoHotkey v2から安定して取得できるかを実機で確認する。

この段階では本体のWindow Controller機能は実装しない。

確認対象:

- B-1 Window列挙
- B-2 Chrome識別
- B-3 Chrome座標Tolerance
- B-4 Monitor / Work Area
- B-5 VS Codeの順序
- B-6 Explorer識別
- B-7 ChatGPT Desktop識別
- B-8 PowerShell系Terminal識別

## 2. PoC構成

~~~text
poc/phase_b/
├─ B1_WindowEnumerationPoC.ahk
├─ B2_B4_ChromeLayoutPoC.ahk
├─ B5_VSCodeOrderPoC.ahk
├─ B6_B8_TargetAppsPoC.ahk
├─ README.md
├─ lib/
│  └─ WindowProbe.ahk
└─ results/
   └─ *.tsv
~~~

`results/` は実行時に自動作成され、Git管理対象外。

## 3. 共通取得項目

`lib/WindowProbe.ahk` はWindowごとに次を取得する。

- HWND
- Z-order上の列挙順位
- Process Name
- PID
- Process Creation FILETIME
- Window Class
- Window Title
- X / Y / Width / Height
- Minimized / Maximized状態
- Style / Extended Style
- Visible
- Owner Window
- DWM Cloaked
- Tool Window判定
- Monitor番号
- Primary Monitorか
- Monitor Work Area

初期Auto Bind候補は次をすべて満たすWindowとする。

- Visible
- DWM Cloakedではない
- Owner Windowなし
- Tool Windowではない
- Width / Height > 0
- Titleが空ではない

PoCではこの条件を `candidate=1` として出力する。Phase Bの結果を見て条件を修正する可能性がある。

---

# 4. B-1 Window Enumeration PoC

実行:

~~~text
poc/phase_b/B1_WindowEnumerationPoC.ahk
~~~

出力:

~~~text
poc/phase_b/results/B1_windows_<timestamp>.tsv
~~~

目的:

- AutoHotkeyからトップレベルWindow群を取得できるか確認。
- Targetアプリ以外も含め、候補除外条件を検証。
- hidden / cloaked / owned / toolwindow等の情報を比較。

推奨状態:

- Chrome 3Window
- VS Code 3Window程度
- Explorer
- ChatGPT Desktop
- Windows Terminal / pwsh
- その他普段使用するアプリ

を開いた通常作業状態で1回実行する。

報告時はTSV全体を共有する。

---

# 5. B-2 / B-3 / B-4 Chrome Layout PoC

実行:

~~~text
poc/phase_b/B2_B4_ChromeLayoutPoC.ahk
~~~

出力:

~~~text
B2_B4_chrome_layout_<timestamp>.tsv
B2_B4_monitors_<timestamp>.tsv
~~~

Chrome TSVにはPrimary Monitor Work Area基準の正規化値を出力する。

- x_norm_primary
- y_norm_primary
- center_x_norm_primary
- center_y_norm_primary
- width_ratio_primary
- height_ratio_primary

現在のMVP仮判定条件も同時評価する。

Chrome1:

- center X < 0.40
- center Y < 0.50
- width 15%～45%
- height 30%～70%

Chrome2:

- center X < 0.40
- center Y >= 0.50
- width 15%～45%
- height 30%～70%

Chrome3:

- center X >= 0.40
- width 50%～90%
- height 70%～105%

さらに想定矩形との差を `score_chrome1 / 2 / 3` として出力する。小さいほど想定配置に近い。

## 5.1 実行してほしい4ケース

### Case A: 通常配置

- 左上Chrome
- 左下Chrome
- 右大Chrome

の3Windowを通常配置した状態。

### Case B: 最小化

3Windowのうち1つを最小化した状態。

どのWindowを最小化したか報告時に記載する。

### Case C: 最大化

Chromeの1Windowを最大化した状態。

どのWindowを最大化したか記載する。

### Case D: Chrome再起動後

Chromeを終了・再起動し、通常の3Window配置へ戻した後に実行。

これによりHWNDが変化しても座標ルールで再識別できるか確認する。

各実行は時刻付き別ファイルになるため、上書きされない。

---

# 6. B-5 VS Code Order PoC

実行:

~~~text
poc/phase_b/B5_VSCodeOrderPoC.ahk
~~~

このPoCだけは常駐する。

操作:

| 操作 | 動作 |
|---|---|
| F5 | 現在のVS Code WindowをSnapshotとして記録 |
| F8 | First Observed Orderをリセット |
| F9 | ログを開く |
| Ctrl + Esc | PoC終了 |

出力:

~~~text
poc/phase_b/results/B5_vscode_order.tsv
~~~

取得項目:

- row_type
- observation_sequence
- Z-order
- HWND
- PID
- Process Creation FILETIME
- Class
- Title

## 6.1 Test A: 起動前から複数Windowがある場合

1. PoCを停止。
2. VS Code Windowを3つ用意する。
3. どのWindowを1番目・2番目・3番目に開いたか記録する。
4. PoCを起動。
5. F5でSnapshot。

`INITIAL_OBSERVED` の順と実際のOpen順が一致するか確認する。

## 6.2 Test B: PoC実行中にWindowを開く

1. 可能ならVS Code Windowをすべて閉じる。
2. PoCを起動。
3. F8でOrder Reset。
4. VS Code Windowを1つずつ、明確な順番で3つ開く。
5. F5。

`NEW_OBSERVED` のObservation SequenceがOpen順と一致するか確認する。

## 6.3 Test C: Close / Reopen

1. 3Windowのうち1つを閉じる。
2. F5。
3. 新しいVS Code Windowを開く。
4. F5。

新しいHWNDに新しいObservation Sequenceが付与されることを確認する。

## 6.4 Process Creation FILETIME

Process Creation FILETIMEも記録する。

目的は、VS Code WindowごとにPIDやProcess Start Timeが分かれているか、それとも複数Windowが同一Processに属するかを比較するため。

---

# 7. B-6 / B-7 / B-8 Target Apps PoC

実行:

~~~text
poc/phase_b/B6_B8_TargetAppsPoC.ahk
~~~

出力:

~~~text
B6_B8_target_apps_<timestamp>.tsv
~~~

実行時に必ず以下を開いておく。

- Explorer Windowを2つ程度
- ChatGPT Desktop
- PowerShell 7を開いているWindows Terminal
- 可能ならPowerShell以外のWindows Terminal Window / Tabも比較用に用意

PoCはすべての初期Candidate Windowを出力し、簡易Hintも付ける。

- EXPLORER
- CHATGPT
- POWERSHELL_TERMINAL
- OTHER

Hintは最終判定ではない。Process / Class / Titleの実測値を確認するための補助。

## 7.1 B-6 Explorer

確認項目:

- 通常Explorer WindowのProcess
- Window Class
- Desktop / Taskbar等がcandidateから除外されているか
- 複数ExplorerのZ-order

## 7.2 B-7 ChatGPT Desktop

確認項目:

- 実際のProcess Name
- Window Class
- Title
- candidate=1で取得できるか

## 7.3 B-8 PowerShell系Terminal

確認項目:

- Windows TerminalのProcess Name
- Window Class
- PowerShell利用時のTitle
- `pwsh.exe` 自体がトップレベルWindowとして見えるか
- 複数Terminal候補をTitleで区別できるか

---

# 8. 結果報告時に必要なもの

すべてのPoCを実行後、`poc/phase_b/results/` のファイルをまとめて共有する。

最低限必要:

- B1 TSV ×1
- B2_B4 Chrome TSV ×4ケース
- 各Chromeケースに対応するMonitor TSV
- B5 TSV ×1
- B6_B8 TSV ×1

加えて次のメモを添える。

~~~text
Chrome Case B:
- 最小化したWindow: 左下

Chrome Case C:
- 最大化したWindow: 右大

VS Code Test A:
- 実際に開いた順: <タイトルA> → <タイトルB> → <タイトルC>

VS Code Test B:
- 実行中に開いた順: <タイトルA> → <タイトルB> → <タイトルC>
~~~

結果受領後、B-1～B-8をまとめて評価し、`docs/PHASE_B_RESULT.md` と最終識別仕様へ反映する。

---

# 9. PoC設計上の判断

## 9.1 TSV採用

ログはTSVとする。

理由:

- Window Titleにカンマが入ってもCSVより扱いやすい。
- Excel / VS Code等で確認可能。
- タブ・改行は出力時に空白へ正規化する。

## 9.2 Process Creation FILETIME

人間向け日時変換はPoC内で行わず、Windows FILETIMEの64bit整数をそのまま記録する。

順序比較には生値で十分であり、日時変換ロジックによる追加不具合を避ける。

## 9.3 常時監視はB-5のみ

MVP本体は常時ポーリングしない方針だが、B-5 PoCではOpen順の技術検証が目的なので500ms間隔でVS Code Windowを観測する。

これはPoC専用動作であり、本体設計への常時ポーリング採用を意味しない。

## 9.4 PoCから本体ロジックを分離

Phase B PoCは観測用であり、実際のWindow Activate / Bindは行わない。

実機結果を確認する前に識別方式を固定しない。
