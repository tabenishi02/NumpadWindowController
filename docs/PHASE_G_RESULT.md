# Phase G 機能テスト結果

更新日: 2026-09-28  
対象: NumpadWindowController / MVP v0.1.0  
状態: **PASS - Phase G完了**  
試験結果反映Commit: `f8efac46a6b9bc40309888ff9000c113eb2a079e`

## 1. 結論

Phase Gの機能テストは完了した。

`TASKS.md` のG-1～G-8は **65 / 65項目すべて完了**しており、リポジトリ上にFAIL / BLOCKEDとして残っている項目はない。

Phase G中に本体実装コードの変更は行っていない。Phase Gで追加・修正されたのは試験手順・Configuration試験項目・試験結果記録であり、Phase Fで確定した実装を広い実利用条件で検証した。

次工程は **Phase H - 実機受入試験**。

---

## 2. 試験結果概要

| 区分 | 項目数 | 結果 |
|---|---:|---|
| G-1 Configuration | 11 | PASS |
| G-2 Manual Bind | 8 | PASS |
| G-3 Chrome Auto Bind | 9 | PASS |
| G-4 VS Code Auto Bind | 8 | PASS |
| G-5 Explorer / ChatGPT / PowerShell | 6 | PASS |
| G-6 Shortcut | 8 | PASS |
| G-7 Clear / Lazy Bind | 9 | PASS |
| G-8 長時間常駐 | 6 | PASS |
| **合計** | **65** | **PASS** |

---

## 3. 確認済みの主要事項

### Configuration

- UTF-16 LE BOM / ConfigVersion=1の正常読込。
- 不正Mode、未知・不足・重複Section / FieldのFatal拒否。
- 専用SlotのMode / Allowed条件整合。
- Shortcut Target不存在、ps1直接Targetの拒否。
- Numpad0 / Virtual000整合。
- Backspace Warning。
- Window / Shortcut / Disabled全ModeでLabel必須。
- Mode別に許可されないField混在の拒否。

### Manual Bind

- Chrome 7/8/9、VS Code 4/5/6の正常Manual Bind。
- Allowed違反時に既存Bindingを破壊しない。
- 1/2/3専用条件。
- 1 HWND : 1 Slot。
- Shortcut / Disabled ModeでManual Bindを生成しない。

### Chrome Auto Bind

- 1 / 2 / 3 / 4Window以上。
- 左上=7、左下=8、右大=9。
- Threshold内の位置ずれ。
- Primary Monitor制約。
- Minimized / Maximizedの新規分類除外。
- 既存Binding済みChromeのMinimize / Maximize / 位置変更後の維持。
- Chrome再起動後の新HWND再割り当て。

### VS Code Auto Bind

- 1 / 2 / 3 / 4Window以上。
- 未使用候補の `WinGetList` 逆順による4→5→6割り当て。
- 真のOpen順を要件にしないこと。
- 有効BindingをAuto Bind Allで再ソートしないこと。
- 再起動 / Window Close後の補充。

### 1 / 2 / 3

- Explorer = `explorer.exe + CabinetWClass`。
- ChatGPT Desktop = `ChatGPT.exe`。
- PowerShell 7 = `WindowsTerminal.exe + CASCADIA_HOSTING_WINDOW_CLASS + Title contains PowerShell 7`。
- 条件外Terminalの除外。
- 候補不存在。
- 複数候補時の非Minimized / Z-order優先。

### Shortcut

- exe / bat / cmd / lnk。
- Arguments。
- Working Directory。
- 押下ごとのRun。
- Runtime Target消失時の失敗通知とScript継続。
- Window Binding / Auto Bind対象外。

### Clear / Lazy Bind

- Slot Clear / Clear All直後に即時Auto Bindしない。
- 明示Auto Bind Allで専用Slot再構築。
- 通常押下によるLazy Auto Bind。
- HWND無効化 / Allowed違反からの復旧。
- Chrome / VS CodeはGroup単位。
- 1 / 2 / 3はSlot単位。
- 任意Slot / Shortcut / DisabledはLazy対象外。
- Manual Binding優先。

### 長時間常駐

- 数時間常駐。
- Chromeタブ変更。
- Window増減。
- Sleep / Resume。
- Explorer再起動。
- Script再起動とRuntime Binding再構築。

---

## 4. Regression / 未解決事項

Phase G手順書ではPhase F RegressionをPhase G開始前・完了後に確認する方針としている。Phase G全手順の実施完了報告があり、リポジトリ上に新規Regression FAILは記録されていない。

また、Phase G期間中に `NumpadWindowController.ahk` の実装変更はないため、Phase G試験結果を無効化する実装差分は存在しない。

### FAIL

なし。

### BLOCKED

なし。

### Phase Gで新たに追加された未解決Known Limitation

なし。

既存Known LimitationはPhase A～Fの設計・結果文書を引き継ぐ。

---

## 5. Phase G最終判定

**PASS - Phase G完了**

完了条件:

- [x] G-1～G-8をすべて実施
- [x] 全65項目を完了記録
- [x] FAIL / BLOCKEDなし
- [x] 新規Regression FAIL記録なし
- [x] Phase G由来の未解決機能不具合なし
- [x] 結果文書作成

次工程: **Phase H - 実機受入試験**
