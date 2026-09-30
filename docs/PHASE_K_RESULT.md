# Phase K - Action / Layer Architecture Result

更新日: 2026-09-29  
状態: **Phase K Complete / Automated Regression PASS / Physical Acceptance PASS / v0.4.0 Released**

## 1. 概要

Phase KではNumpadWindowControllerのRuntime Architectureを、従来のKey Mode中心構造から次へ移行した。

```text
Physical Input
    ↓
Logical Key Resolution
    ↓
Reserved Global Command
    ↓
Global Key Mapping
    ↓
Active Layer Mapping
    ↓
Action Resolution
    ↓
Action Dispatcher
    ↓
Action Executor
```

Runtime ConfigurationはConfigVersion 3のみをサポートする。ConfigVersion 1 / 2互換読込・自動Migrationは実装していない。

---

## 2. 実装済み機能

### ConfigVersion 3 / Action Model

- ConfigVersion 3 Parser / Validator
- ConfigVersion 1 / 2拒否
- Physical Key / Logical Key / Global Mapping / Layer Mapping分離
- Window / Run / KeySend / LayerSwitch / Delay / MultiAction / Disabled
- Action参照Validation
- WindowGroup Validation
- MultiAction Step Validation
- KeySend Combination Validation

### Layer

- Active Layerは常に1つ
- DefaultLayer
- LayerOrder
- Global Mapping優先
- LayerSwitch Set / Next
- Layer切替ToolTip
- 複数Layer時にGlobal LayerSwitch必須Validation

### Window Action

- Runtime BindingをWindow Action ID基準へ移行
- Manual Bind / Clear
- Auto Bind
- Lazy Auto Bind
- AutoBind Strategy:
  - None
  - FirstMatch
  - ReverseList
  - PrimaryThreePane
- Window Behavior:
  - Toggle
  - Activate
  - ActivateThenToggle

### Window Behavior

- Toggle:
  - Active → Minimize
  - Inactive → Activate
  - Minimized → Restore + Activate
- Activate:
  - ActiveでもMinimizeしない
- ActivateThenToggle:
  - 新規BindingではActivate phase
  - 最初のActivation成功後にToggle phase
  - Clear / Manual Rebind / 新規Auto Bind / Controller再起動でActivate phaseへ戻る
  - 同じ有効Bindingを維持するAuto Bindではphaseを保持
  - Launch成功だけではToggle phaseへ移行しない

### Launch fallback

- WindowGroup
- MatchProcess / MatchClass / MatchTitleContains
- LaunchTarget / Arguments / WorkingDirectory
- Group一致Window 0件の場合のみLaunch
- Group一致Window 1件以上では追加Launchしない
- Group単位LaunchPending
- Timeout後再試行
- 同期的な長時間WinWaitなし

### Virtual00 / Virtual000

- Logical Key MetadataへVirtual00追加
- Numpad0 / Virtual00 / Virtual000を同一Detectorで処理
- EnableVirtual00 / EnableVirtual000
- Virtual00-only時は2回目Upで確定
- Virtual000有効時は約80ms判定窓
- Modifier / Interrupt / Timeout / Repeat Regression

### KeySend / Media / System

- 人間可読Combination Parser
- Ctrl / Shift / Alt / Win
- A-Z / 0-9 / F1-F24
- Navigation Key
- Volume
- Media
- Browser
- PrintScreen
- 不正Combinationは起動時Error

### MultiAction / Delay

- Step1..N順次実行
- Delay Action
- Step連続性Validation
- 不存在Action参照拒否
- Nested MultiAction拒否
- 同一MultiAction実行中再入抑止
- Delay中にController全体をCritical固定しない

---

## 3. Public Default

`KeyBindings.default.ini` をConfigVersion 3へ全面更新した。

- Base Layer: 汎用Window Action
- Edit Layer: Copy / Paste / Cut / Undo / Redo / Save等
- Media Layer: Media / Volume / Browser
- NumpadAdd: Global Layer Next
- Backspace: 未Mapping
- Virtual00: Off
- Virtual000: Off

未Mapping KeyはController Hotkey条件が成立せずNative Inputを通す。

---

## 4. Developer Workflow

`examples/KeyBindings.developer-workflow.ini` をConfigVersion 3へ移行した。

- 7 / 8 / 9: Chrome PrimaryThreePane
- 4 / 5 / 6: VS Code ReverseList
- 1: Explorer
- 2: ChatGPT Desktop
- 3: PowerShell 7
- Virtual000: On
- その他: Manual Window Action

旧ConfigVersion 1互換Profileとしては読み込まず、ConfigVersion 3 Exampleとして再構成した。

---

## 5. Example

`examples/KeyBindings.example.ini` で以下を例示する。

- Layer
- Run
- Window Activate
- Notepad Launch fallback
- Virtual00 / Virtual000
- KeySend
- Media / Browser
- Delay
- MultiAction

---

## 6. Automated Regression

GitHub Actions Windows runner + AutoHotkey v2.0.28で実施。

対象commit:

`61f45ca3af5dbd05565a07b74ec5a18b64131231`

結果:

- Phase K Controller Regression: **187 assertions PASS**
- Startup Preview Regression: **24 assertions PASS**
- Startup Task Scheduler Integration Regression: **37 assertions PASS**
- Local Windows re-verification (AutoHotkey v2.0.26): **187 assertions PASS** / Startup Preview **24 assertions PASS**

確認内容には以下を含む。

- ConfigVersion 3正常読込
- ConfigVersion 1 / 2拒否
- Layer / Action参照Validation
- WindowGroup Validation
- KeySend Validation
- MultiAction Validation
- Virtual00 / Virtual000 Logic
- Modifier / Interrupt / Timeout / Repeat
- Window Action Runtime State
- Auto Bind Strategy
- Window Toggle decision
- Launch fallback decision
- LaunchPending / Timeout
- MultiAction順序
- MultiAction再入抑止
- Live Window Probe
- Startup Task既存Regression

---

## 7. 削除した互換コード / Test

Phase K Runtimeから以下を削除した。

- ConfigVersion 1 / 2互換読込
- ConfigVersion 1 / 2専用Validation
- Legacy Key Mode Runtime
- ConfigVersion 1 / 2専用Regression
- `tests/PhaseF.Tests.ahk`
- `tests/Run-PhaseFTests.ps1`

過去仕様はGit履歴・Release Tag・Phase A～J文書で参照可能。

---

## 8. Physical Acceptance

Automated RegressionはPASS済み。K-PA-1～11の初回物理受入もすべてPASSした。

その後、追加仕様として `Behavior=ActivateThenToggle` をPhase Kへ加えた。既存K-PA-1～11のPASS記録は保持し、K-PA-4 / 5 / 6 / 9の追加後再試験もPASS済み。K-PA-12は1回目FAIL（Launch設定不足）、2回目FAIL（PowerShell 7で複数Window生成）を経て修正し、3回目試験でPASS。Phase K Physical Acceptanceは完了した。

手順:

[Phase K Physical Acceptance Test](PHASE_K_MANUAL_TEST.md)

専用Config: `../examples/KeyBindings.phase-k-test.ini`

専用Config自体もPhase K Controller RegressionでConfigVersion 3として読み込み検証する。

Virtual00は00キー搭載実機を所有していないためPhysical AcceptanceはNot Executed / N/Aとする。

### 8.1 ActivateThenToggle

追加Test Spec:

`../tests/PHASE_K_ACTIVATE_THEN_TOGGLE_TEST_SPEC.md`

Physical Acceptance Config:

- Explorer / Numpad1 = `ActivateThenToggle`
- ChatGPT Desktop / Numpad2 = `ActivateThenToggle`
- PowerShell 7 / Numpad3 = `ActivateThenToggle`

Runtime実装済み。物理試験Fixtureは `ActivateThenToggle` をそのままConfigVersion 3として読み込み、ATT-01～12を通常Regressionへ統合済み。


K-PA-12 1回目はFAIL。

症状:

- Explorer / ChatGPT Desktop / PowerShell 7を未起動状態でKey入力すると `No window found`。

原因:

- Physical Acceptance Configの3 WindowGroupにLaunchTargetがなかった。
- Launch後のWindow生成を検出してActivateThenToggleを続行する処理も不足していた。

修正:

- Explorer = `explorer.exe`
- ChatGPT Desktop = AppsFolder経由
- PowerShell 7 = `wt.exe -w new new-tab --title "PowerShell 7" pwsh.exe -NoExit`
- LaunchPendingへ元Action IDを保持し、Window生成後に自動Bind → Activate → Toggle phase移行を実装
- ATT Regressionへ3対象のLaunch fallback / continuation確認を追加

2回目K-PA-12ではExplorer / ChatGPT DesktopはPASS、PowerShell 7のみFAIL。PowerShell 7で複数Windowが生成された。

原因:

- `LaunchTarget=pwsh.exe` はPowerShellプロセスの起動であり、PowerShell 7用Windows Terminal Windowを1つだけ生成する保証がなかった。

追加修正:

- `LaunchTarget=wt.exe`
- `LaunchArguments=-w new new-tab --title "PowerShell 7" pwsh.exe -NoExit`
- ユーザー環境で同等起動をProbeし、新規Top-level Windowが1個のみ生成されることを確認
- RegressionへWindows Terminal単一Window起動Config条件を追加

K-PA-12 3回目はPASS。Explorer / ChatGPT Desktop / PowerShell 7の未起動状態からのLaunch、Activate、以降Toggleまで実機確認完了。

### 8.2 Physical Acceptance最終結果

- K-PA-1～11: PASS
- K-PA-4 / 5 / 6 / 9 ActivateThenToggle追加後再試験: PASS
- K-PA-12:
  - 1回目: FAIL / LaunchTarget不足
  - 2回目: FAIL / PowerShell 7複数Window生成
  - 3回目: **PASS**
- Virtual00: Logic Regression PASS / Physical Acceptance N/A

**Phase K Physical Acceptance: PASS**

---

## 9. Public Repository Audit

### Release Ready再監査

2026-09-30にPhase K現行差分の16ファイルを再走査した。

確認:

- 実Credential / API Key / GitHub Token: 検出なし
- 実ユーザーPath: 検出なし
- `token` 検出: KeySend parserのローカル変数でありSecretではない
- `C:\Users\<name>`: 文書中のプレースホルダーであり実Pathではない
- Public Default / Example / Test Config: 公開阻害要因なし

**Release Ready Audit: PASS**


Phase K主要変更ファイル13件を対象に初回監査を実施し、以下を確認した。

- Private key pattern
- GitHub token pattern
- password / secret / API key / access token形式
- 個人 `C:\Users\<name>\...` Path
- Email address

結果: **検出なし**

Exampleに含まれる絶対PathはWindows標準 `C:\Windows\System32\notepad.exe` のみ。

---

## 10. Documentation

更新済み:

- README
- CHANGELOG
- KNOWN_LIMITATIONS
- KeyBindings.default.ini
- examples
- Controller Regression

Physical Acceptance完了後、TASKS / PROJECT_HANDOFFへの最終反映まで完了した。

---

## 11. 現在判定

**PASS - Phase K Complete / v0.4.0 Released**

Phase Kの実装・自動Regression・Physical Acceptance・文書整合・Releaseはすべて完了。**v0.4.0** を2026-09-30にReleaseした。


---

## 11. Release

- Version: **v0.4.0**
- Release date: **2026-09-30**
- Phase K: **Complete**
- Automated Regression: **PASS**
- Physical Acceptance: **PASS**
- Release Ready Audit: **PASS**
