# PROJECT_HANDOFF

更新日: 2026-09-24
対象: NumpadWindowController
状態: Phase F実装済み / 自動検証済み / 実機確認待ち

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

- Config Validation後にNumLock状態保存、OnExit登録、ON固定、Runtime / Hook / Hotkey初期化、Auto Bind Allを行う。
- Runtime Binding正本は`App.Slots`のみ。Working Stateの整合性を確認してからCommitする。
- Window metadataは都度取得。既存BindingのValidityと新規候補のEligibilityを分離する。
- Hotkeyは物理Scan Codeと正確なModifier条件を組み合わせる。Shortcutは通常押下だけ、Disabledは未登録。
- 0/000はInputHookでSC052を消費し、80ms以内のD-U×3をVirtual000へ変換。Action実行はQueue経由で入力記録から分離する。
- Debugは先頭の`DEBUG_ENABLED`で明示ONにした場合だけ。通常は永続ログなし。ログI/O失敗は内部で処理する。
- ConfigにAutoBind属性やNumLock設定、HWNDは保存しない。Configの変更は再起動で反映する。

## 検証結果と未完了項目

AutoHotkey v2.0.26で`tests/Run-PhaseFTests.ps1 -Desktop`を実行し、136 assertions PASS。

確認済み: Config正常・異常系、Manualの状態遷移、重複禁止、Auto Bind計算と例外時のState保持、Lazy候補なし、Mode別Hotkey登録、Detector状態遷移、実Window情報取得、Hook開始/停止、テストWindowのRestore、EXE/BAT/CMD/LNK起動、引数、作業ディレクトリ、実行失敗の継続、Debug I/O失敗の隔離。

次は実機確認が必要:

- テスト環境ではForeground化できず、Activate成功とActive WindowからのManual Bind成功は未確認。
- NumLockは単独のSetNumLockStateでもOFFにならなかった。起動前OFF → 実行中ON → 終了後OFFは未確認。ONからの終了処理は確認済み。
- 物理テンキーの0/000、修飾操作、Disabled入力、未定義Modifierの通過。
- 実際のChrome / VS Code / Explorer / ChatGPT / Terminal切替、再起動・Window増減・長時間常駐。

`TASKS.md`の未チェック項目を推測で完了にしない。Phase G/Hの受入確認は未実施。テスト後にControllerを常駐状態にはしていない。

## 次回読む資料

1. 本書
2. `docs/PHASE_F_RESULT.md`
3. `TASKS.md`のPhase F残項目とPhase G/H
4. 変更対象に関係する`docs/PHASE_E_SPEC.md` / `PHASE_D_SPEC.md` / `PHASE_C_SPEC.md`

既存設計の根拠はPhase A～E仕様書、実機識別の根拠は`docs/PHASE_B_RESULT.md`。PoCは`poc/`に保持している。
