# PROJECT_HANDOFF

更新日: 2026-09-25
対象: NumpadWindowController
状態: Phase F初回実機テスト済み / 入力系修正版実装済み / 再テスト待ち

## 現在の成果物

- `NumpadWindowController.ahk`: 単一ファイルのAutoHotkey v2本体。
- `KeyBindings.ini`: Phase D標準設定、UTF-16 LE BOM、ConfigVersion=1。
- `tests/PhaseF.Tests.ahk`: 本体を直接includeする設定・状態・入力判定・Windows API検証。
- `tests/Run-PhaseFTests.ps1`: AHKの終了コードを確認する実行入口。
- [Phase F検証結果](docs/PHASE_F_RESULT.md): 確認済み範囲、未確認事項、次の実機手順。

Phase A～Eの仕様変更は行っていない。PoCの入力判定方式、候補Filter、Chrome Threshold / Scoreを本実装へ移した。`lib/` 分割はしていない。

## 実装済みの操作

| 操作 | 動作 |
|---|---|
| Key | Window Activate / Shortcut起動 |
| Ctrl + Key | Manual Bind |
| Ctrl + Shift + Key | Slot Clear |
| Ctrl + Alt + Key | Group / Slot Auto Bind |
| NumLock | Auto Bind All |
| Ctrl + NumLock | Clear All |

専用Slotは7/8/9=Chrome、4/5/6=VS Code、1=Explorer、2=ChatGPT Desktop、3=PowerShell 7用Windows Terminal。任意SlotはManual専用で、自動補充しない。Backspaceは標準Disabled。

Auto Bindは有効なManual / Auto Bindingを維持し、欠損だけ補修する。完全再構築はCtrl+NumLock → NumLock。VS Codeは未使用候補の逆列挙順で空き4→5→6へ補充する。

## 実装上の重要点

- Config Validation後にNumLock状態保存、OnExit登録、ON固定、Runtime / Hook / Hotkey初期化、Auto Bind Allを行う。通常NumLockはSC145、Ctrl+NumLockはWindows/AutoHotkey仕様により^Pauseで捕捉する。
- Runtime Binding正本は`App.Slots`のみ。Working Stateの整合性を確認してからCommitする。
- Window metadataは都度取得。既存BindingのValidityと新規候補のEligibilityを分離する。
- Hotkeyは物理Scan Codeと正確なModifier条件を組み合わせる。Shortcutは通常押下だけ、Disabledは未登録。
- 0/000はInputHookでSC052を消費する。通常入力は80ms、Modifier付き入力は120ms以内のD-U×3をVirtual000へ変換し、Action実行はQueue経由で入力記録から分離する。
- Debugは先頭の`DEBUG_ENABLED`で明示ONにした場合だけ。通常は永続ログなし。ログI/O失敗は内部で処理する。
- ConfigにAutoBind属性やNumLock設定、HWNDは保存しない。Configの変更は再起動で反映する。

## 検証結果と未完了項目

初回Manual TestではWindow制御系の主要経路を確認できた。

PASS:

- Active Window Manual Bind
- Minimized Window Restore / Activate
- Lazy Auto Bind + Activate
- 通常の物理0 / 000
- Ctrl Manual Bind / Ctrl+Alt Auto Bind / 未定義Modifier
- Backspace Disabled / Backspace Warning

初回テストで見つかった入力系問題に対し、次を修正済み。

- 通常NumLockを物理SC145で登録。
- Ctrl+NumLockを^Pauseで登録。
- NumLock Global Action後にAlwaysOnを再適用しONを検証。
- R-7ログから000失敗は時間超過ではなく途中Interruptと判明。判定窓は全Modifierで80msへ戻し、同一Modifier状態の再Downだけを無視する修正を追加。
- Debug LogへLogical DispatchとZero Detector timingを追加。
- 自動テストへNumLock専用Hotkey定義とCtrl押下継続000のRegressionを追加。
- `poc/NumLockInputPoC.ahk` を追加し、AHK InputHookとWindows Raw Inputを同時観測可能にした。

初回テスト時の「物理キーはDEL」という記録はユーザーの誤認として撤回した。
実機のキー表記はBackspaceであり、`Key-Backspace` の現行設計を維持する。

次は `docs/PHASE_F_MANUAL_TEST.md` のR-8（NumLock Input PoC）とR-9（Ctrl押下継続000）を優先する。
Phase Fはこれらの結果を反映するまで閉じない。Phase G/Hの受入確認は未実施。

## 次回読む資料

1. 本書
2. `docs/PHASE_F_RESULT.md`
3. `TASKS.md`のPhase F残項目とPhase G/H
4. 変更対象に関係する`docs/PHASE_E_SPEC.md` / `PHASE_D_SPEC.md` / `PHASE_C_SPEC.md`

既存設計の根拠はPhase A～E仕様書、実機識別の根拠は`docs/PHASE_B_RESULT.md`。PoCは`poc/`に保持している。
