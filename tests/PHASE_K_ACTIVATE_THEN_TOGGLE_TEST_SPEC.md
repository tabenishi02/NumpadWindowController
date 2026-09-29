# Phase K - ActivateThenToggle Test Specification

更新日: 2026-09-30  
対象: ConfigVersion 3 / Window Action  
状態: **Implemented / Automated Regression PASS**

## 1. 目的

新しいWindow Behavior `ActivateThenToggle` の受入条件と実装済みRegressionを記録する。

`ActivateThenToggle` は次の状態遷移を持つ。

```text
New Binding
    ↓
Activate phase
    ↓
first successful activation
    ↓
Toggle phase
    ↓
binding clear / rebind / controller restart
    ↓
Activate phase
```

Config自体を書き換えず、Runtime stateのみでphaseを管理する。

---

## 2. 自動Regression要件

実装時に `tests/PhaseK.Tests.ahk` へ統合する。

### ATT-01 Config Validator

入力:

```ini
Behavior=ActivateThenToggle
```

期待:

- ConfigVersion 3で受理する。
- 大文字小文字の正規化方針は既存 `Toggle / Activate` と同一にする。
- 未知Behaviorは引き続きConfiguration Error。

### ATT-02 初回Active Window

前提:

- 新規Binding
- 対象Windowは既にActive
- Activate phase

期待:

- Minimizeしない。
- Activate相当として扱う。
- Activation成功後にToggle phaseへ遷移する。

### ATT-03 初回Inactive Window

前提:

- 新規Binding
- 対象WindowはInactive
- Activate phase

期待:

- Activateする。
- Activation成功後にToggle phaseへ遷移する。

### ATT-04 初回Minimized Window

前提:

- 新規Binding
- 対象WindowはMinimized
- Activate phase

期待:

- Restoreする。
- Activateする。
- Activation成功後にToggle phaseへ遷移する。

### ATT-05 Activation成功後のActive Window

前提:

- Toggle phase
- 対象WindowはActive

期待:

- Toggleと同じくMinimizeする。

### ATT-06 Toggle phaseのInactive / Minimized Window

前提:

- Toggle phase

期待:

- Inactive → Activate
- Minimized → Restore + Activate
- Toggle phaseを維持する。

### ATT-07 Binding Clear

前提:

- Toggle phase

操作:

- 個別ClearまたはClear All

期待:

- Bindingが消える。
- 次回Binding時はActivate phaseから開始する。

### ATT-08 Manual Rebind

前提:

- Toggle phaseだったWindow Actionへ別WindowをManual Bindする。

期待:

- 新しいHWNDへBinding。
- Activate phaseへリセットする。
- 旧Windowのphaseを継承しない。

### ATT-09 Auto Bind / Lazy Auto Bind

前提:

- Bindingなし、または旧Bindingが無効。
- Auto Bindで新しいHWNDを割り当てる。

期待:

- Activate phaseから開始する。
- 同じ有効Bindingを保持したAuto Bind Allでは不要にphaseをリセットしない。

### ATT-10 Launch / LaunchPending continuation

前提:

- Bindingなし。
- WindowGroup一致Window 0件。
- Launch fallback実行。

期待:

- WindowGroupに有効なLaunchTargetが存在する。
- 1回目のKey入力でApplicationをLaunchする。
- Launch成功だけではToggle phaseへ遷移しない。
- LaunchPending中はActivate phaseを維持する。
- Window生成検出後、元のActivateThenToggle Actionを自動BindしてActivateまで続行する。
- Activation成功後にToggle phaseへ遷移する。

### ATT-11 Launch後最初のActivation

前提:

- ATT-10でApplication起動済み。
- Window生成後にBinding可能。

期待:

- 最初のWindow Action実行はActivate相当。
- `WinWaitActive` 成功後にToggle phaseへ遷移する。
- Activation失敗時はActivate phaseを維持する。

### ATT-12 Controller restart

前提:

- Toggle phaseのActionが存在する。

操作:

- Controller終了。
- 同じConfigで再起動。

期待:

- Runtime stateは永続化しない。
- Activate phaseから開始する。

---

## 3. 既存Behavior Regression

`ActivateThenToggle` 実装後も以下を再確認する。

- `Behavior=Toggle`: Active → Minimize
- `Behavior=Toggle`: Inactive → Activate
- `Behavior=Toggle`: Minimized → Restore + Activate
- `Behavior=Activate`: ActiveでもMinimizeしない
- `Behavior=Activate`: Minimized → Restore + Activate
- Launch fallback / LaunchPending
- Manual Bind / Clear
- Auto Bind Strategy
- MultiAction内 `Behavior=Activate`

---

## 4. Physical Acceptance

物理受入は `docs/PHASE_K_MANUAL_TEST.md` の **K-PA-12 ActivateThenToggle** で実施する。

対象:

- Explorer / Numpad1 / LaunchTarget=explorer.exe
- ChatGPT Desktop / Numpad2 / AppsFolder経由
- PowerShell 7 / Numpad3 / LaunchTarget=pwsh.exe

Test Config:

`examples/KeyBindings.phase-k-test.ini`

これら3 Actionは物理試験用Configで `Behavior=ActivateThenToggle` とする。

---

## 5. Automated Regression

Runtime実装完了後、暫定的な `ActivateThenToggle → Toggle` 正規化を削除した。

現在は `examples/KeyBindings.phase-k-test.ini` をそのままConfigVersion 3として読み込み、ATT-01～12を通常の `tests/PhaseK.Tests.ahk` で検証する。

結果:

- Local Windows / AutoHotkey v2.0.26: **183 assertions PASS**
- GitHub Actions / AutoHotkey v2.0.28: **183 assertions PASS**
- Startup Preview: **24 assertions PASS**
- Startup Task Scheduler Integration: **37 assertions PASS**

残作業はK-PA-4 / 5 / 6 / 9のWindow系再試験と、K-PA-12の物理受入。
