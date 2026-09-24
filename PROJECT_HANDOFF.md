# PROJECT_HANDOFF

更新日: 2026-09-25
対象: NumpadWindowController
状態: Phase F完了 / 次工程 Phase G - テスト

## 現在の成果物

- `NumpadWindowController.ahk`: 単一ファイルのAutoHotkey v2本体。
- `KeyBindings.ini`: Phase D標準設定、UTF-16 LE BOM、ConfigVersion=1。
- `tests/PhaseF.Tests.ahk`: 本体を直接includeする設定・状態・入力判定・Windows API検証。
- `tests/Run-PhaseFTests.ps1`: AHKの終了コードを確認する実行入口。
- [Phase F検証結果](docs/PHASE_F_RESULT.md): 確認済み範囲、未確認事項、次の実機手順。

Phase A～Eは2026-09-25のGlobal Action変更を反映済み。PoCの入力判定方式、候補Filter、Chrome Threshold / Scoreを本実装へ移した。`lib/` 分割はしていない。

## 実装済みの操作

| 操作 | 動作 |
|---|---|
| Key | Window Activate / Shortcut起動 |
| Ctrl + Key | Manual Bind |
| Ctrl + Shift + Key | Slot Clear |
| Ctrl + Alt + Key | Group / Slot Auto Bind |
| Ctrl + NumpadEnter | Auto Bind All |
| Ctrl + Shift + NumpadEnter | Clear All |

専用Slotは7/8/9=Chrome、4/5/6=VS Code、1=Explorer、2=ChatGPT Desktop、3=PowerShell 7用Windows Terminal。任意SlotはManual専用で、自動補充しない。Backspaceは標準Disabled。

Auto Bindは有効なManual / Auto Bindingを維持し、欠損だけ補修する。完全再構築はCtrl+Shift+NumpadEnter → Ctrl+NumpadEnter。VS Codeは未使用候補の逆列挙順で空き4→5→6へ補充する。

## 実装上の重要点

- Config Validation後にNumLock状態保存、OnExit登録、ON固定、Runtime / Hook / Hotkey初期化、Auto Bind Allを行う。Global Actionは物理NumpadEnter(SC11C)のCtrl / Ctrl+Shiftへ登録し、Standard Enter(SC01C)は対象外。
- Runtime Binding正本は`App.Slots`のみ。Working Stateの整合性を確認してからCommitする。
- Window metadataは都度取得。既存BindingのValidityと新規候補のEligibilityを分離する。
- Hotkeyは物理Scan Codeと正確なModifier条件を組み合わせる。Shortcutは通常押下だけ、Disabledは未登録。
- 0/000はInputHookでSC052を消費する。全Modifierで80ms以内のD-U×3をVirtual000へ変換し、同一Modifier状態の再DownだけをInterrupt対象外とする。Action実行はQueue経由で入力記録から分離する。
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

初回テスト以降の入力系調査・修正結果:

- Ctrl+000失敗のInterrupt元はLeft Ctrl (vk=A2/sc=01D) と確定。
- 同一Modifier状態の再Downを無視する修正後、R-9は5/5 PASS。
- NumLock Input PoCでは通常NumLock / Ctrl+NumLockともAHK / Raw InputにNumLock Eventなし。
- 比較用Pauseは両経路で観測され、PoCは正常。
- 物理NumLockをGlobal Actionに使う設計を廃止。
- Ctrl+NumpadEnter=Auto Bind All、Ctrl+Shift+NumpadEnter=Clear Allへ変更。
- Standard Enter=SC01C / NumpadEnter=SC11Cを実機確認済み。
- `poc/NumLockInputPoC.ahk` は設計変更の根拠PoCとして保持。

初回テスト時の「物理キーはDEL」という記録はユーザーの誤認として撤回した。
実機のキー表記はBackspaceであり、`Key-Backspace` の現行設計を維持する。

R-10新Global Action自動テストはPASS、R-12 NumpadEnter / Standard Enter分離もPASS。
R-13ではClear All直後に即時Auto Bindがないことと、専用Slot押下時だけLazy Auto Bindすることをログで確認した。
これによりR-11で観測した再BindingはClear Allの不具合ではなく、仕様どおりのLazy Auto Bindと確定した。
R-14ではWindows側NumLockについて、OFF→起動ON→終了OFF、ON→起動ON→終了ON、実行中ON固定をすべてPASSした。

Phase Fは正式完了。Phase F固有の未解決事項はない。
次工程はPhase G - テスト。Phase Hの実機受入試験はPhase G完了後に実施する。

## 次回読む資料

1. 本書
2. `docs/PHASE_F_RESULT.md`
3. `TASKS.md`のPhase G/H
4. 変更対象に関係する`docs/PHASE_E_SPEC.md` / `PHASE_D_SPEC.md` / `PHASE_C_SPEC.md`

既存設計の根拠はPhase A～E仕様書、実機識別の根拠は`docs/PHASE_B_RESULT.md`。PoCは`poc/`に保持している。
