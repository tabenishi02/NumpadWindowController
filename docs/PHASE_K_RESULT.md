# Phase K - Action / Layer Architecture Result

更新日: 2026-09-29  
状態: **Implementation Complete / Automated Regression PASS / Physical Acceptance Pending**

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

### Window Toggle

- Active → Minimize
- Inactive → Activate
- Minimized → Restore + Activate
- Behavior=ActivateではActiveでもMinimizeしない

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

`076b5cdf05b4777df7800ce9f6f38cae27968126`

結果:

- Phase K Controller Regression: **127 assertions PASS**
- Startup Preview Regression: **24 assertions PASS**
- Startup Task Scheduler Integration Regression: **37 assertions PASS**
- Local Windows re-verification (AutoHotkey v2.0.26): **127 assertions PASS** / Startup Preview **24 assertions PASS**

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

Automated RegressionはPASSしたが、物理テンキーを使うPhase K受入は未実施。

手順:

[Phase K Physical Acceptance Test](PHASE_K_MANUAL_TEST.md)

Virtual00は00キー搭載実機を所有していないためPhysical AcceptanceはNot Executed / N/Aとする。

---

## 9. Public Repository Audit

Phase K変更ファイル13件を対象に以下を確認した。

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

Phase K完了判定は物理受入後にTASKS / PROJECT_HANDOFFへ最終反映する。

---

## 11. 現在判定

**Implementation Complete / Automated Regression PASS / Physical Acceptance Pending**

実装上のPhase K残作業は物理受入結果の反映とRelease Ready判定のみ。次Release予定は **v0.4.0**。
