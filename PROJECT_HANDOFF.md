# PROJECT_HANDOFF

更新日: 2026-09-29  
対象: NumpadWindowController  
状態: **Phase K Implementation Complete / Automated Regression PASS / Physical Acceptance Pending**

## 現在地点

Phase A～Jは完了済み。v0.3.0は2026-09-29にGitHub Release済み。

Phase K - Action / Layer Architectureは、設計・実装・ConfigVersion 3移行・Automated Regression・利用者向け文書更新まで完了した。

K-PA-1～11の初回Physical AcceptanceはPASS済み。ActivateThenToggle RuntimeとATT-01～12 Automated Regressionも実装・PASS済み。現在の残作業は **Window系再試験（K-PA-4 / 5 / 6 / 9）とK-PA-12**、その結果を反映したRelease Ready判定。Phase Kの次Release予定は **v0.4.0** と確定した。

現在のVersion / Release関係:

- Repository: **Public**
- 最新安定Release: GitHub Releasesを参照
- `v0.1.0`: 初回MVP
- `v0.2.0`: ログオン時自動起動追加
- `v0.2.1`: Release後ドキュメント同期
- `v0.3.0`: Phase J Public Default / Configuration一般化
- `v0.4.0`: **Phase K Action / Layer Architecture（予定、Physical Acceptance待ち）**
- Phase K: 次Release向けUnreleased

License: MIT

---

## Phase K Architecture

現行Runtimeの正本:

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

Config中心概念は旧 `Mode=Window / Shortcut / Disabled` ではなく **Action**。

RuntimeはConfigVersion 3のみ対応する。

ConfigVersion 1 / 2:

- 互換読込なし
- 自動Migrationなし
- Compatibility Layerなし
- 専用Regression削除済み

過去仕様はRelease Tag / Git履歴 / Phase A～J文書で参照する。

---

## ConfigVersion 3

### General

```ini
[General]
ConfigVersion=3
DefaultLayer=Base
LayerOrder=Base,Edit,Media
EnableVirtual00=Off
EnableVirtual000=Off
```

### Global Mapping

```ini
[GlobalKeys]
NumpadAdd=LayerNext
```

Global MappingはActive Layer Mappingより優先。

複数Layer ConfigではGlobal LayerSwitch Actionを最低1つ要求する。

### Layer

```ini
[Layer-Base]
Numpad7=Window7

[Layer-Edit]
Numpad7=Undo
```

Active Layerは常に1つ。

Phase K初期対応:

- Set
- Next

対象外:

- Layer Stack
- Momentary
- One-shot
- Tap / Hold

---

## Action Type

現行Action Type:

- `Window`
- `Run`
- `KeySend`
- `LayerSwitch`
- `Delay`
- `MultiAction`
- `Disabled`

---

## Window Action

Window Binding Runtime StateはPhysical Keyではなく **Window Action ID** を正本とする。

Window Actionを解決するKey:

| 操作 | 動作 |
|---|---|
| Key | Window Action実行 |
| Ctrl + Key | Manual Bind |
| Ctrl + Shift + Key | Binding Clear |
| Ctrl + Alt + Key | Auto Bind |

Reserved Global Command:

- `Ctrl + NumpadEnter` = Auto Bind All
- `Ctrl + Shift + NumpadEnter` = Clear All Window Bindings

### Behavior

`Toggle`:

- Active → Minimize
- Inactive → Activate
- Minimized → Restore + Activate

`Activate`:

- ActiveでもMinimizeしない
- MultiAction内Window移動向け

### Auto Bind Strategy

- None
- FirstMatch
- ReverseList
- PrimaryThreePane

---

## Launch fallback

WindowGroup単位でApplication存在判定を行う。

Launch条件:

```text
Bindingなし
↓
Auto Bind候補なし
↓
Group一致Window = 0
→ Launch
```

Group一致Windowが1件以上存在する場合は追加Launchしない。

起動直後はGroup単位 `LaunchPending` を保持し、多重Runを防止する。

長時間の同期WinWaitは行わない。

---

## Virtual00 / Virtual000

Hardware capability:

```ini
EnableVirtual00=On
EnableVirtual000=On
```

論理化:

```text
D-U             → Numpad0
D-U-D-U         → Virtual00
D-U-D-U-D-U     → Virtual000
```

判定窓は約80ms。

- Virtual00 / Virtual000ともOff: Numpad0 direct hotkey
- Virtual00のみOn: 2回目UpでVirtual00確定
- Virtual000 On: 判定窓終了まで00/000判定

Virtual00実機は未所有のためPhysical AcceptanceはN/A。Logic RegressionはPASS済み。

---

## KeySend / Media

Config例:

```ini
[Action-Copy]
Type=KeySend
Label=Copy
Keys=Ctrl+C
```

対応:

- Ctrl / Shift / Alt / Win
- A-Z / 0-9
- F1-F24
- Navigation
- Volume
- Media
- Browser
- PrintScreen

不正Combinationは起動時Validation Error。

管理者権限ApplicationへのSendはWindows Integrity Level制限を受ける場合がある。

---

## MultiAction / Delay

例:

```ini
[Action-CopyToApp]
Type=MultiAction
Label=Copy to App
Step1=Copy
Step2=Delay100
Step3=TargetActivate
Step4=Paste
```

仕様:

- Step1から連続
- 不存在Action参照拒否
- Nested MultiAction拒否
- 同一MultiAction実行中再入抑止
- Delay中はController全体をCritical固定しない

---

## Public Default

`KeyBindings.default.ini` はConfigVersion 3。

Layer:

- Base: 汎用Window
- Edit: Undo / Copy / Paste / Cut / Select All / Save / Find / Screenshot / Redo
- Media: Media / Volume / Browser / Screenshot

Global:

- `NumpadAdd` = Layer Next

安全設定:

- Backspace未Mapping
- Virtual00 Off
- Virtual000 Off

---

## Developer Workflow

`examples/KeyBindings.developer-workflow.ini` はConfigVersion 3へ移行済み。

```text
7 / 8 / 9 = Chrome PrimaryThreePane
4 / 5 / 6 = VS Code ReverseList
1 = Explorer
2 = ChatGPT Desktop
3 = PowerShell 7
```

Virtual000 = On。

これはLegacy ConfigVersion 1互換Profileではなく、現行Action Model上のExample。

---

## 自動起動

Windows Task Scheduler方式はPhase Kでも変更なし。

```powershell
.\scripts\install-startup-task.ps1
```

Current user / InteractiveToken / LeastPrivilege。

---

## Automated Regression

GitHub Actions Windows + AutoHotkey v2.0.28。

PASS済み:

- Phase K Controller Regression: **168 assertions**
- Startup Preview Regression: **24 assertions**
- Startup Task Scheduler Integration Regression: **37 assertions**

対象commit:

`9572c374c9de9090e77053054334674d60178a8b`

主な確認対象:

- ConfigVersion 3
- ConfigVersion 1 / 2拒否
- Layer
- Action reference
- KeySend
- Media key syntax
- MultiAction
- Delay
- Virtual00 / Virtual000
- Auto Bind
- Window Toggle decision
- Launch fallback
- LaunchPending
- Live Window Probe
- Startup Task

---

## Physical Acceptance

未実施。

手順:

`docs/PHASE_K_MANUAL_TEST.md`

対象:

- Layer
- KeySend
- Media/System
- Window Toggle
- Manual Bind / Clear / Global Command
- Launch fallback / LaunchPending
- MultiAction
- Virtual000
- Developer Workflow Auto Bind
- Native pass-through / Backspace
- NumLock lifecycle

Virtual00のみN/A。

---

## 次の作業

1. `docs/PHASE_K_MANUAL_TEST.md` に従い、`examples/KeyBindings.phase-k-test.ini` を使って実機受入を実施
2. 結果を `docs/PHASE_K_RESULT.md` へ反映
3. `TASKS.md` のPhysical Acceptance完了条件を更新
4. v0.4.0 Release Ready監査
5. Tag / GitHub Release

---

## 次に読む資料

1. `README.md`
2. `docs/PHASE_K_DESIGN.md`
3. `docs/PHASE_K_RESULT.md`
4. `docs/PHASE_K_MANUAL_TEST.md`
5. `docs/KNOWN_LIMITATIONS.md`
6. `CHANGELOG.md`
7. `TASKS.md`

公開済みTagを後から移動して内容を書き換える運用は採用しない。


---

## ActivateThenToggle追加仕様

追加Test Spec:

`tests/PHASE_K_ACTIVATE_THEN_TOGGLE_TEST_SPEC.md`

物理試験ConfigではWindow Layerの次を新Behavior対象とする。

- Numpad1 / Explorer
- Numpad2 / ChatGPT Desktop
- Numpad3 / PowerShell 7

Behavior:

`ActivateThenToggle`

K-PA-1～11初回試験はPASS済み。ActivateThenToggle RuntimeとATT-01～12は実装・Automated Regression PASS済み。次はK-PA-4 / 5 / 6 / 9再試験とK-PA-12を実施する。
