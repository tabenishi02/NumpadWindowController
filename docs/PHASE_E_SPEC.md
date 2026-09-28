# Numpad Window Controller - Phase E Implementation Design

更新日: 2026-09-24  
対象: MVP / v0.1.0  
状態: Implemented / Verified  
目的: Phase E「実装設計」を完了し、Phase FでAutoHotkey v2コードへ直接落とし込める構造・Runtime State・診断方針を固定する。

> 本書は実装構造に関して `docs/MVP_DESIGN.md` より具体的な仕様として扱う。
> 本仕様はv0.1.0実装・Phase G機能テスト・Phase H実機受入試験に反映済み。

---

# 1. 設計原則

MVPでは次を優先する。

1. 単純さ
2. 状態の一元管理
3. 既存Bindingを不用意に壊さない
4. 設定エラーを起動時に止める
5. 通常利用ではログやGUIを増やさない
6. 将来分割できる責務境界だけコード内で明確にする

MVPではClass階層、Plugin構造、汎用Rule Engineは作らない。

---

# 2. E-1 ファイル構成

## 2.1 正式構成

MVP本体は単一AHKファイル構成を正式採用する。

~~~text
NumpadWindowController/
├─ NumpadWindowController.ahk
├─ KeyBindings.ini
├─ README.md
├─ TASKS.md
├─ PROJECT_HANDOFF.md
├─ docs/
└─ poc/
~~~

Phase F開始時点では `lib/` を作らない。

理由:

- MVP規模では単一ファイルの方が処理の流れを追いやすい。
- AHKのinclude依存を早期に増やさない。
- Phase A～Dで機能範囲がかなり限定された。
- 実装後に責務境界を見て分割する方が安全。

## 2.2 単一ファイル内の責務区分

物理ファイルは1つだが、以下の順番でSectionを明確に分ける。

~~~text
1. Directives / Constants
2. Startup / Shutdown
3. Built-in Key Metadata
4. Configuration
5. Runtime State
6. Input / Hotkey Registration
7. Numpad0 / Virtual000 Detector
8. Window Probe / Matching
9. Auto Bind
10. Window Actions
11. Shortcut Actions
12. Notifications
13. Debug Logging
~~~

各Sectionはコメント見出しで分離する。

将来 `lib/` へ分割する場合も、この責務単位をそのまま候補とする。

## 2.3 分割判断

MVP完成後、次のいずれかが起きた場合にのみ `lib/` 分割を検討する。

- 本体が追跡しにくい規模になった
- Config Parser / Auto Bind等を独立テストしたい
- 新しいAuto Bind Groupが増えた
- デバイス単位入力処理を追加する
- GUI設定画面を追加する

Phase F途中で「ファイルが長い」という理由だけでは分割しない。

---

# 3. Startup / Shutdown設計

## 3.1 Startup順序

推奨順序:

~~~text
1. #Requires / #SingleInstance
2. Global Constants初期化
3. Built-in Metadata生成
4. KeyBindings.iniをRaw Read
5. Config Validation
6. Config Object生成
7. 起動時NumLock状態を保存
8. OnExit Handler登録
9. NumLockをONへ設定
10. Runtime State初期化
11. Numpad0 / Virtual000 Detector初期化
12. Hotkey登録
13. Auto Bind All
14. 常駐開始
~~~

重要:

Config Validation完了前にはNumLockやHotkey等の外部状態を変更しない。

これによりConfig Fatal Error時に副作用を残さない。

## 3.2 Shutdown

正常終了時:

1. Timer停止
2. InputHookが動作中なら停止
3. ToolTip消去
4. 起動時NumLock状態へ復元
5. 終了

NumLock復元は `OnExit` で行う。

強制Process Kill等でOnExitが実行されない場合は復元を保証しない。

---

# 4. Built-in Key Metadata

Phase DでConfigから除外した不変条件はコード側で保持する。

KeyごとのBuilt-in Metadata例:

~~~text
Key ID
AHK physical key / input source
Dedicated flag
AutoBind flag
AutoBindGroup
Slot order
Input strategy
~~~

例:

~~~text
Numpad7:
  Dedicated = true
  AutoBind = true
  Group = Chrome
  SlotOrder = 1

Numpad4:
  Dedicated = true
  AutoBind = true
  Group = VSCode
  SlotOrder = 1

Numpad0:
  Dedicated = false
  AutoBind = false
  InputStrategy = ZeroDetector

Virtual000:
  Dedicated = false
  AutoBind = false
  InputStrategy = ZeroDetector
~~~

Config値とBuilt-in Metadataを混在させず、起動時に統合したKey Definitionを生成する。

---

# 5. E-2 Runtime Stateモデル

## 5.1 基本方針

AHK v2の `Map` と単純Object Literalを使用する。

MVPでは独自Classを作らない。

理由:

- Data構造が小さい。
- Mutation箇所を追いやすい。
- Class継承やConstructorを導入する必要がない。

## 5.2 App State

Global Runtimeの入口は1つのApp Stateへまとめる。

概念:

~~~text
AppState
├─ Config
├─ Keys
├─ Slots
├─ OriginalNumLock
├─ ZeroDetector
└─ Debug
~~~

Global変数を機能ごとに大量作成しない。

AHK実装上は `global App := {...}` のようなObjectを1つ用意する方針とする。

---

# 6. Key Definition

各Logical Keyは起動後不変のKey Definitionを持つ。

概念Schema:

~~~text
KeyDefinition
  Id
  AhkKey
  Mode
  Label
  Dedicated
  AutoBind
  AutoBindGroup
  SlotOrder
  AllowedProcess
  AllowedClass
  AllowedTitleContains
  ShortcutTarget
  ShortcutArguments
  ShortcutWorkingDirectory
  InputStrategy
~~~

Config + Built-in MetadataからStartup時に1回生成する。

以降、Key Definition自体はRuntime中に変更しない。

Config Hot Reloadがないため、Immutable扱いで問題ない。

---

# 7. Window Slot State

Window Mode KeyだけRuntime Slot Stateを持つ。

Schema:

~~~text
SlotState
  Hwnd
  BindingSource
~~~

値:

~~~text
Hwnd = 0
BindingSource = "None"
~~~

または:

~~~text
Hwnd = <valid HWND>
BindingSource = "Auto" | "Manual"
~~~

## 7.1 保存しない値

Slot Stateへ次を恒久保存しない。

- Title
- Process
- Class
- X / Y
- Width / Height
- MinMax
- Z-order

理由:

Window metadataは変化する。

必要な時にHWNDから再取得する。

これにより「キャッシュされたTitleと実Windowがずれる」問題を避ける。

## 7.2 Runtime Bindingの唯一の正本

現在のBindingについては `App.Slots` だけを正本とする。

Key Definition側へHWNDを書き込まない。

ConfigへもHWNDを書き込まない。

---

# 8. Used HWND Set

Used HWND SetはGlobalな永続Stateにしない。

Auto Bind / Manual Bind処理を行う時だけ一時 `Map` として生成する。

~~~text
used := Map()
used[hwnd] := true
~~~

理由:

- Binding変更後にGlobal Setを同期し忘れるリスクを避ける。
- Slot Stateから毎回容易に再構築できる。
- 1 HWND : 1 Slotの検証用途に限定できる。

---

# 9. Window Candidate

Window列挙結果は処理中だけCandidate Objectとして保持する。

Schema例:

~~~text
WindowCandidate
  Hwnd
  Process
  Class
  Title
  X
  Y
  W
  H
  MinMax
  ZOrder
  Monitor
  Visible
  Cloaked
  Owner
  ToolWindow
~~~

Auto Bind完了後は保持しない。

Chrome Score等もCandidate計算中だけの一時値とする。

---

# 10. Auto Bind Working State

Phase CのAtomic Update方針を実装構造へ落とす。

Auto Bind開始時:

~~~text
App.Slots
  ↓ shallow copy of SlotState values
WorkingSlots
  ↓ validate / clear invalid / fill
Final Validation
  ↓
App.Slots = WorkingSlots
~~~

Key Definition / Configはコピーしない。

## 10.1 Commit条件

Commit前に最低限:

- 同じHWNDが2Slotに存在しない
- BindingSourceがNoneならHwnd=0
- Hwnd!=0ならBindingSourceがAutoまたはManual

を確認する。

内部Validation失敗時はWorking Stateを破棄し、元の `App.Slots` を保持する。

---

# 11. Input / Hotkey設計

## 11.1 Mode別Hotkey登録

HotkeyはConfig Validation後、Modeに応じて登録する。

### Window Mode

登録:

- `Key` → Activate / Lazy Auto Bind
- `Ctrl + Key` → Manual Bind
- `Ctrl + Shift + Key` → Slot Clear
- `Ctrl + Alt + Key` → Individual / Group Auto Bind

### Shortcut Mode

登録:

- `Key` → Shortcut Run

Modifier付きController操作は登録しない。

したがって `Ctrl + ShortcutKey` 等はController機能ではなく、Windows / Active App側へ通常入力として渡る。

### Disabled

Controller Hotkeyを一切登録しない。

ネイティブ入力をそのまま通す。

これはPhase DのBackspace安全方針に必要。

## 11.2 NumpadEnter Global Function

Global ActionはConfig Modeと独立して、物理 `NumpadEnter = SC11C` のModifier Combinationへ登録する。

- `Ctrl + NumpadEnter` → Auto Bind All
- `Ctrl + Shift + NumpadEnter` → Clear All

通常KeyboardのEnterは `SC01C` なので対象外。

`NumpadEnter` のNormal押下は従来どおりConfig Modeに従う。
Window ModeであってもCtrl / Ctrl+ShiftはGeneric Manual Bind / Slot Clearへ登録せず、Global Actionが優先する。

物理NumLockはPhase F PoCでAHK / Raw Inputの双方にEventが届かないことを確認したため、Global Hotkeyとして登録しない。
NumLock状態の保存 / ON固定 / OnExit復元は別責務として維持する。

## 11.3 Unsupported Modifier

Window Modeでも、定義していないModifier CombinationはController Hotkeyとして登録しない。

例:

- Alt + Key
- Shift + Key
- Win + Key

はMVPのController操作対象外。

---

# 12. Numpad0 / Virtual000 Input設計

## 12.1 InputHookを使用

`Numpad0` と `Virtual000` は同一物理入力 `SC052` を共有するため、通常Hotkey登録ではなく専用Detectorを使用する。

PoCで確認済みのInputHook方式を採用する。

Detectorが有効な場合:

- SC052をSuppress
- Down / Up列を記録
- 80ms以内のD-U×3をVirtual000へ正規化
- それ以外をNumpad0へ正規化

## 12.2 Modifier Snapshot

最初のNumpad0 Down時点でController Modifier状態をSnapshotする。

対象:

- Ctrl
- Shift
- Alt

判定完了後、そのSnapshotとLogical Keyを共通Dispatcherへ渡す。

例:

~~~text
Ctrl held
physical 000
↓
Virtual000 + Ctrl
↓
Manual Bind
~~~

## 12.3 Detector有効条件

- Numpad0とVirtual000が両方Disabled → Detectorを起動しない
- それ以外 → Detectorを起動

Phase Dにより:

~~~text
Numpad0=Disabled
Virtual000!=Disabled
~~~

は禁止されている。

## 12.4 Detector使用時の入力消費

Detector有効時、SC052は判定のためControllerが消費する。

定義外Modifierとの組み合わせはネイティブNumpad0として再送しない。

これはMVP Known Limitationとする。

通常Numpad0入力を完全に維持したい場合はNumpad0 / Virtual000を両方Disabledにする。

---

# 13. Common Dispatcher

Logical Key操作は可能な限り1つのDispatcherへ集約する。

概念:

~~~text
DispatchKey(keyId, modifierKind)
~~~

modifierKind:

- Normal
- Ctrl
- CtrlShift
- CtrlAlt

処理:

~~~text
Key Definition取得
↓
Mode確認
↓
Mode + modifierKindに応じたActionへRouting
~~~

Virtual000もここから先は通常Logical Keyと同じ扱いにする。

入力元がHotkeyかZeroDetectorかをAction側で意識させない。

---

# 14. Window Probe / Match責務

Window情報取得をAuto Bindロジックへ直接散らさない。

関数責務を分離する。

概念:

~~~text
Window_GetCandidate(hwnd)
Window_EnumerateCandidates()
Window_MatchesAllowed(candidate, keyDef)
Window_IsExistingBindingValid(hwnd, keyDef)
Window_GetPrimaryWorkArea()
~~~

Existing Binding ValidityとNew Candidate EligibilityはPhase Cどおり別関数にする。

---

# 15. Auto Bind責務

主要関数の概念:

~~~text
AutoBind_All()
AutoBind_Group(groupName)
AutoBind_Single(keyId)

AutoBind_FillChrome(workingSlots, candidates, used)
AutoBind_FillVSCode(...)
AutoBind_FillExplorer(...)
AutoBind_FillChatGPT(...)
AutoBind_FillPowerShell(...)
~~~

`AutoBind_All` はWindow Activateを行わない。

Binding Stateの更新だけを行う。

Lazy Auto Bind呼出側が、成功後に対象WindowをActivateする。

これにより「Binding計算」と「ユーザー操作」を分離する。

---

# 16. Manual Bind責務

概念:

~~~text
Binding_ManualBind(keyId)
~~~

処理:

1. Active HWND取得
2. KeyがWindow Modeか確認
3. Active WindowがAllowed条件を満たすか確認
4. 既存の同HWND Binding検索
5. 必要なら旧SlotをNoneへ変更
6. 対象SlotをManualへ設定
7. State整合性確認
8. 成功通知

Allowed違反時はStateを一切変更しない。

---

# 17. Window Activate責務

概念:

~~~text
Action_ActivateWindow(keyId)
~~~

処理:

1. Slot State取得
2. Validity確認
3. 無効ならLazy Auto Bind
4. 再度Slot確認
5. Hwndがなければ失敗通知
6. MinimizedならRestore
7. Activate
8. Foreground失敗なら通知

通常成功時は通知しない。

---

# 18. Shortcut責務

概念:

~~~text
Action_RunShortcut(keyId)
~~~

Config Validationで解決済みTargetを使用する。

Runtimeでは:

1. Key Definition取得
2. Target / Arguments / WorkingDirectory組立
3. Run
4. 例外時だけ通知 + Debug Log

既存Window検索は行わない。

---

# 19. Notification設計

常設GUIは作らない。

## 19.1 ToolTip

短時間通知:

- Manual Bind成功
- Manual Bind拒否
- Slot Clear
- Auto Bind失敗
- Empty Slot
- Shortcut実行失敗
- Auto Bind disabled

ToolTipは共通関数へ集約する。

概念:

~~~text
Notify_Info(text)
Notify_Error(text)
Notify_Clear()
~~~

MVPでは色分けや複数Toast Queueは作らない。

## 19.2 MsgBox

起動時:

- Fatal Config Error
- Backspace有効化Warning

など、ユーザー確認が必要なものだけMsgBoxを使う。

---

# 20. E-3 Logging / Diagnostics

## 20.1 通常利用

標準動作では永続ログを書かない。

理由:

- 日常操作ツールでログファイルを増やさない。
- 高速入力時のPoCでFileAppend競合が起きた実績がある。
- MVPのRuntime処理は状態が小さく、通常はToolTipで十分。

## 20.2 Debug Mode

開発・問題調査用にコード先頭の定数として:

~~~text
DEBUG_ENABLED = false
~~~

相当を持つ。

MVPではConfig Fieldにはしない。

Debug Modeを有効にした場合だけ:

~~~text
logs/NumpadWindowController_<timestamp>.log
~~~

へ逐次記録する。

Debug LogのFile I/Oは必ず例外を内部でCatchし、ログ書き込み失敗によってController本体の入力処理やBinding処理を失敗させない。

`logs/` はGit管理対象外とする。

## 20.3 Debug記録対象

必要最小限:

- Startup / Shutdown
- Config load result
- Hotkey registration summary
- Manual Bind result
- Clear result
- Auto Bind開始 / 終了
- Slot state change
- Lazy Auto Bind result
- Shortcut実行結果
- Unexpected exception

キーDown / Upイベントを全件記録しない。

特にNumpad0 Detectorの全物理イベントLogは通常Debugでも既定OFFとする。

## 20.4 Auto Bind診断

Debug ModeではAuto Bind後にSlot一覧を1つのSnapshotとして出力可能にする。

概念:

~~~text
7  Auto    0x123456 chrome.exe ...
8  None
9  Manual  0x987654 chrome.exe ...
...
~~~

Candidate全件Dumpは通常行わず、必要な時だけ追加できる内部関数にする。

---

# 21. Error Handling

## 21.1 Startup Fatal

Config / Initialization Error:

- MsgBox
- 常駐開始しない
- NumLock変更前ならそのまま終了
- NumLock変更後ならOnExitで復元

## 21.2 Runtime Recoverable

次はScript継続:

- Windowが閉じた
- Activate失敗
- Lazy Auto Bind候補なし
- Shortcut Run失敗
- Manual Bind拒否

ToolTip + Debug Logで処理する。

## 21.3 Unexpected Internal Error

Hotkey Callback等の境界で必要に応じて例外をCatchする。

原則:

- Runtime Stateを途中Commitしない
- Debug Logへ記録
- 短いError通知
- Script全体は可能なら継続

ただしRuntime State整合性が保証できない場合は、安全側としてFatal終了を許容する。

---

# 22. Naming Convention

AHK v2関数名は責務Prefixを使用する。

例:

~~~text
App_Start
App_OnExit

Config_Load
Config_Validate

Runtime_Init

Input_RegisterHotkeys
Input_StartZeroDetector

Window_EnumerateCandidates
Window_MatchesAllowed

Binding_ManualBind
Binding_ClearSlot

AutoBind_All
AutoBind_Group

Action_ActivateWindow
Action_RunShortcut

Notify_Info
Notify_Error

Debug_Log
Debug_DumpSlots
~~~

Globalの一文字名や汎用名を避ける。

---

# 23. Phase F実装単位

Phase Fでは次の順に実装する。

1. Skeleton / App State
2. Config Load / Validation
3. Built-in Metadata / Runtime Init
4. Window Probe
5. Manual Bind / Clear
6. Auto Bind Groups
7. Window Activate / Lazy Auto Bind
8. Shortcut
9. Hotkey Registration
10. Numpad0 / Virtual000 Detector
11. NumpadEnter Global Function
12. Notification / Debug
13. Integration Test

Input処理より先にState / Binding処理を作り、関数単位で確認しやすくする。

---

# 24. Phase E確定事項まとめ

- MVP本体は単一 `NumpadWindowController.ahk`。
- `lib/` 分割はMVP後に必要性を見て判断。
- 内部は責務SectionとPrefix関数で分離。
- Global Runtime入口は1つのApp State。
- Config / Key Definitionは起動後Immutable扱い。
- Runtime Bindingの正本は `App.Slots` のみ。
- Slot StateはHwnd + BindingSourceだけを基本とする。
- Window metadataは都度取得し永続キャッシュしない。
- Used HWND SetはAuto Bind時の一時Map。
- Auto BindはWorking Stateで計算して最終Validation後にCommit。
- Modeに応じて必要なHotkeyだけ登録。
- DisabledはHotkeyを登録せずネイティブ入力を通す。
- Numpad0 / Virtual000だけInputHook Detectorを使用。
- Logical Key化後は共通Dispatcherへ統合。
- 通常利用では永続Logなし。
- Debug Logはコード内定数で明示有効化した時だけ出力。
- Debugでも全Keyイベントを常時記録しない。

---

# 25. 次工程

Phase E完了後はPhase F - AutoHotkey v2実装へ進む。

Phase Fでは本書の責務境界を維持しつつ、まず単一ファイルでMVPを完成させる。
