# PROJECT_HANDOFF

更新日: 2026-10-04  
対象: NumpadWindowController  
状態: **Phase K Complete / v0.4.1 Maintenance Released / 未完了タスクなし**

## 現在地点

Phase A～Kは完了済み。v0.4.0は2026-09-30にGitHub Release済み。Window Toggle復元不具合を修正したv0.4.1を2026-10-04にMaintenance Releaseした。

Phase K - Action / Layer Architectureは、設計・実装・ConfigVersion 3移行・Automated Regression・利用者向け文書更新まで完了した。

K-PA-1～11、ActivateThenToggle追加後のK-PA-4 / 5 / 6 / 9再試験、K-PA-12 3回目までPhysical AcceptanceはすべてPASS。Virtual00のみ実機なしN/A。Phase Kは実装・Regression・Physical Acceptance・文書整合・Releaseまで完了した。

現在のVersion / Release関係:

- Repository: **Public**
- 最新安定Release: GitHub Releasesを参照
- `v0.1.0`: 初回MVP
- `v0.2.0`: ログオン時自動起動追加
- `v0.2.1`: Release後ドキュメント同期
- `v0.3.0`: Phase J Public Default / Configuration一般化
- `v0.4.0`: **Phase K Action / Layer Architecture（2026-09-30 Release）**
- `v0.4.1`: **Window Toggle minimized restore fix（2026-10-04 Maintenance Release）**

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

- Minimized → Restore + Activate
- 非最小化かつActive → Minimize
- 非最小化かつInactive → Activate
- Minimized判定をActive判定より優先し、状態遷移中にActive判定が残っていても再Minimizeしない

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

- Phase K Controller Regression: **187 assertions**
- Startup Preview Regression: **24 assertions**
- Startup Task Scheduler Integration Regression: **37 assertions**

対象commit:

`61f45ca3af5dbd05565a07b74ec5a18b64131231`

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

**PASS - 完了。**

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

Phase K / v0.4.0のRelease作業は完了。

Phase K自体の残タスクはない。v0.4.0で見つかったWindow Toggle復元不具合もv0.4.1で修正・Release済み。

2026-10-04残タスク監査:

- Repository: Public
- Latest Release: v0.4.1
- Open Issue: 0件
- Open Pull Request: 0件
- 最新main GitHub Actions `AutoHotkey Tests`: PASS
- Secret Protection / Push Protection: Enabled
- Open Secret scanning alert: 0件
- Private vulnerability reporting: Disabled（設定状態確認済み、`SECURITY.md`で報告経路を案内）
- 実装・試験・Release・文書に未完了タスクなし

Release Ready再監査: PASS
- Phase K現行差分16ファイルを再走査
- 実Credential / 実ユーザーPath検出なし
- 最新GitHub Actions: Controller 187 / Startup Preview 24 / Startup Integration 37 PASS

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

K-PA-1～11、K-PA-4 / 5 / 6 / 9追加後再試験、K-PA-12 3回目までPASS。ActivateThenToggle Physical Acceptanceは完了。


### K-PA-12 1回目 FAIL / 修正済み

症状: Explorer / ChatGPT Desktop / PowerShell 7が未起動のとき `No window found`。

原因: Physical Acceptance ConfigにLaunchTargetがなく、ActivateThenToggleのLaunchPending後continuationも未実装だった。

修正済み:

- Explorer: explorer.exe
- ChatGPT Desktop: AppsFolder
- PowerShell 7: pwsh.exe
- Window生成後の自動Bind → Activate → Toggle phase移行

### K-PA-12 2回目 FAIL / 修正済み

- Explorer: PASS
- ChatGPT Desktop: PASS
- PowerShell 7: FAIL（複数Window生成）

原因: `pwsh.exe` 直起動ではWindows Terminal Window数を保証できなかった。

修正:

- PowerShell 7: `wt.exe -w new new-tab --title "PowerShell 7" pwsh.exe -NoExit`
- 同等コマンドの実機Probeで新規Top-level Window 1個を確認
- Regressionへ起動Command条件を追加

3回目: **PASS**。PowerShell 7は単一Windows Terminal Windowの起動・Activate・Toggleを確認。
