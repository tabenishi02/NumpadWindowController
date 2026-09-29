# Phase K - Action / Layer Architecture Design

更新日: 2026-09-29  
状態: **Design Complete / Implementation Not Started**  
対象: NumpadWindowController 次期機能拡張

## 1. 目的

Phase Kでは、NumpadWindowControllerを「Window / Shortcut / Disabledをキーごとに固定するController」から、**Physical Key → Layer → Action** で動作を解決する汎用的な左手デバイス向けControllerへ拡張する。

今回の主対象は以下とする。

- Virtual00
- KeySend（Ctrl+C / Ctrl+V / Ctrl+X等）
- Media / System操作
- Layer
- Multi Action
- Window Toggle（同じWindowキーを再押下した場合の最小化）
- 対象Windowが1つも存在しない場合のApplication Launch fallback
- ConfigVersion 3への全面移行

Tap / Hold / Double Tap、マウス操作、Keyboard Device単位識別は今回実装しない。将来検討項目としてのみ残す。

---

## 2. Configuration方針

### 2.1 ConfigVersion 3のみをサポートする

Phase K実装後のRuntimeは **ConfigVersion 3のみ**を読み込む。

ConfigVersion 1 / 2については:

- 互換読込を実装しない
- 自動Migrationを実装しない
- Compatibility Layerを持たない
- ConfigVersion 1 / 2専用Validationを削除する
- 旧Config用Regression Testを削除する
- 過去仕様はGit履歴、Release Tag、Phase A～J文書で参照可能な状態を維持する

v1.0前であり、現時点では旧Config互換の維持コストより新設計の単純性を優先する。

既存User ConfigはPhase K導入時に新Configへ手動移行する。

### 2.2 ファイル運用

引き続き以下を使用する。

- User Config: `KeyBindings.ini`
- Distribution Default: `KeyBindings.default.ini`
- Example: `examples/*.ini`
- Encoding: UTF-8

Phase K実装時に配布Config / ExampleをConfigVersion 3形式へ全面更新する。

---

## 3. Runtime Architecture

入力処理の基本経路を以下へ変更する。

```text
Physical Input
    ↓
Logical Key Resolution
    ├─ Numpad0
    ├─ Virtual00
    └─ Virtual000
    ↓
Reserved Global Command判定
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

Configの中心概念を「Key Mode」から「Action」へ変更する。

Window BindingのRuntime Stateも、物理キーではなく **Window Action ID** を正本として保持する。これにより同じWindow Actionを複数Layerから参照できる。

---

## 4. ConfigVersion 3の基本構造

### 4.1 General

概念例:

```ini
[General]
ConfigVersion=3
DefaultLayer=Base
LayerOrder=Base,Edit,Media
EnableVirtual00=Off
EnableVirtual000=Off
```

- `DefaultLayer`: 起動時Layer
- `LayerOrder`: LayerNextで使用する順序
- `EnableVirtual00`: Numpad0高速2回入力をVirtual00として識別する
- `EnableVirtual000`: Numpad0高速3回入力をVirtual000として識別する

### 4.2 Global Key Mapping

Layerに関係なく同じActionを実行するキーを定義できる。

```ini
[GlobalKeys]
NumpadAdd=LayerNext
```

Global MappingはActive Layer Mappingより優先する。

Layer切替ActionをGlobal Mappingに置くことで、Layer変更後にBaseへ戻れなくなる構成を防ぎやすくする。

### 4.3 Layer Mapping

```ini
[Layer-Base]
Numpad7=Chrome1
Numpad8=Chrome2
Numpad9=Chrome3

[Layer-Edit]
Numpad7=Undo
Numpad8=Copy
Numpad9=Paste

[Layer-Media]
Numpad7=MediaPrev
Numpad8=MediaPlayPause
Numpad9=MediaNext
```

Layerは初期実装では**常に1つだけActive**とする。

Layer Stack、Momentary Layer、One-shot Layerは実装しない。

---

## 5. Action Model

初期Action Typeは以下とする。

| Type | 用途 |
|---|---|
| `Window` | Window Activate / Toggle / Binding |
| `Run` | exe / bat / cmd / lnk等の起動 |
| `KeySend` | Ctrl+C等のKeyboard Shortcut、Media/System Key |
| `LayerSwitch` | Layer切替 |
| `Delay` | Multi Action内の待機 |
| `MultiAction` | 複数Actionの順次実行 |
| `Disabled` | Controller Actionを行わない |

旧Configの `Mode=Window / Shortcut / Disabled` との互換変換は行わない。

---

## 6. Window Action

### 6.1 Behavior

Window Actionは以下のBehaviorを持つ。

- `Toggle`
- `Activate`

通常のテンキーWindow切替には `Toggle` を使用する。

Multi ActionからWindowへ移動する用途では `Activate` を使用する。

### 6.2 Toggle

```text
Window Action
    ↓
有効なBindingあり？
    ├─ Yes
    │    ↓
    │  対象HWNDがActive？
    │    ├─ Yes → Minimize → End
    │    └─ No
    │         ↓
    │       MinimizedならRestore
    │         ↓
    │       Activate
    │
    └─ No → Auto Bind / Launch fallbackへ
```

これにより、

```text
Numpad2
→ ChatGPTをActivate

Numpad2
→ ChatGPTをMinimize

Numpad2
→ ChatGPTをRestore + Activate
```

という動作になる。

これはDouble Tap判定ではない。時間間隔に関係なく、押下時点で対象WindowがActiveかどうかだけを判定する。

### 6.3 Activate

`Behavior=Activate` は対象WindowがActiveでも最小化しない。

Multi Action内で、

```text
KeySend Ctrl+C
Delay
Window Activate
KeySend Ctrl+V
```

のような処理を行うために使用する。

---

## 7. Window Group / Launch Fallback

### 7.1 目的

Window Actionに既定Applicationが設定されており、対象ApplicationのWindowが**1つも存在しない場合だけ**Applicationを起動できるようにする。

複数Windowを同一Applicationへ割り当てる場合は、Application Windowが1つでも存在すれば追加起動しない。

例:

```text
Chrome Window = 0
Numpad7
→ Chrome Launch

Chrome Window = 1
Numpad8
→ NotFound
→ 新しいChromeはLaunchしない
```

### 7.2 Group単位のApplication Identity

Application起動判定はSlot / Binding単位ではなくWindow Group単位で行う。

概念例:

```ini
[WindowGroup-Chrome]
MatchProcess=chrome.exe
MatchClass=
MatchTitleContains=
LaunchTarget=chrome.exe
LaunchArguments=
LaunchWorkingDirectory=
```

Window ActionはGroupを参照する。

```ini
[Action-Chrome1]
Type=Window
Label=Chrome 1
Behavior=Toggle
WindowGroup=Chrome
AllowedProcess=chrome.exe
AllowedClass=
AllowedTitleContains=
AutoBindStrategy=PrimaryThreePane
AutoBindOrder=1
```

Groupの `Match*` は「Applicationがすでに起動しているか」の判定に使用する。

Actionの `Allowed*` は「このWindow ActionへBinding可能か」の判定に使用する。

両者は目的が異なるため分離する。

### 7.3 Launch判定順

BindingもAuto Bind候補も見つからなかった場合:

```text
Launch設定あり？
    ├─ No → NotFound
    └─ Yes
         ↓
       Groupに一致するWindowが1つ以上存在？
         ├─ Yes → NotFound
         └─ No
              ↓
            LaunchPending？
              ├─ Yes → 追加Runしない
              └─ No → Run + LaunchPending
```

### 7.4 LaunchPending

Application起動直後はWindow生成前の時間が存在する。

その間に同Groupのキーを連打して複数回 `Run()` しないよう、RuntimeにGroup単位のLaunchPendingを保持する。

```text
App.LaunchPending["Chrome"]
```

PendingはWindow出現確認またはTimeoutで解除する。

初期実装ではApplication起動後に同期的な長時間 `WinWait` を行わない。

1回目のキーで起動し、Window生成後の次回キー入力でAuto Bind / Activateする方式を基本とする。

---

## 8. Auto Bind Strategy

ConfigVersion 3では旧Configとの互換ではなく、現在必要な挙動を新Action Modelへ再定義する。

初期Strategy候補:

- `None`: Manual Bindのみ
- `FirstMatch`: 条件に一致する候補から選択
- `ReverseList`: `WinGetList`逆順を使用
- `PrimaryThreePane`: Primary Monitor上の3分割レイアウトをOrder 1～3で判定

現行Developer Workflow相当は新ConfigVersion 3形式のExampleとして再構成する。

旧ConfigVersion 1 Presetを互換Profileとして読み込むことはしない。

---

## 9. Manual Bind / Clear / Global Command

既存操作の有用な部分は新Action Model上で維持する。

### Window Actionを解決したキー

- `Key`: Action実行
- `Ctrl + Key`: Active WindowをそのWindow ActionへManual Bind
- `Ctrl + Shift + Key`: Window ActionのRuntime BindingをClear
- `Ctrl + Alt + Key`: Auto Bind有効Actionの場合のみ明示Auto Bind

### Reserved Global Command

- `Ctrl + NumpadEnter`: Auto Bind All
- `Ctrl + Shift + NumpadEnter`: Clear All Window Bindings

Global CommandはLayerに依存しない。

非Window ActionでCtrl系管理操作が定義されていない場合、Controller Actionとして誤実行しない。

---

## 10. Virtual00 / Virtual000

### 10.1 Virtual00

Virtual00は、物理00キーがNumpad0を高速2回送信するタイプを対象とする。

```text
D-U
→ Numpad0

D-U-D-U
→ Virtual00

D-U-D-U-D-U
→ Virtual000
```

### 10.2 判定規則

- Virtual00 / Virtual000とも無効:
  - Numpad0を通常Hotkeyとして即時処理
- Virtual00のみ有効:
  - 2回目のUpでVirtual00を確定可能
- Virtual000有効:
  - 2回目のUp時点では000の途中か判別できないため判定窓終了まで待機する
- 3回目まで規定時間内に成立:
  - Virtual000として1回処理

現行Virtual000の約80ms判定窓を基礎としてDetectorを一般化する。

### 10.3 制限

物理00と人間による極端に高速なNumpad0二連打が同一イベント列を送る場合、ソフトウェアから完全には区別できない。

USB HID上の独立したKeypad 00 / Keypad 000 Usageを直接送信する製品は今回の保証対象外とする。

Virtual00対応実機を所有していないため:

- 自動Logic Test: 実施する
- 物理00受入試験: Not Executed / N/A
- 将来実機入手時に追加確認可能

---

## 11. KeySend

### 11.1 目的

テンキー単押しでKeyboard Shortcutを送信する。

例:

- Ctrl+C
- Ctrl+V
- Ctrl+X
- Ctrl+Z
- Ctrl+Y
- Ctrl+A
- Ctrl+S
- Ctrl+F
- Ctrl+Shift+S
- Win+Shift+S
- Alt+F4

### 11.2 Config表現

AutoHotkey固有の `^c` 等を直接Configへ書かせず、人間可読な表現を採用する。

```ini
[Action-Copy]
Type=KeySend
Label=Copy
Keys=Ctrl+C
```

Parserが内部的にAutoHotkeyのSend表現へ変換する。

初期Modifier:

- Ctrl
- Shift
- Alt
- Win

初期Key:

- A-Z
- 0-9
- F1-F24
- Tab / Enter / Escape / Space / Backspace / Delete
- Home / End / PageUp / PageDown
- Arrow keys
- Media / Browser / Volume / PrintScreen系の対応キー

未知Key名・不正Combinationは起動時Validation Errorとする。

---

## 12. Media / System操作

Media/System専用Action Typeは作らず、原則 `KeySend` を再利用する。

例:

```ini
[Action-MediaPlayPause]
Type=KeySend
Label=Play Pause
Keys=Media_Play_Pause
```

初期対象例:

- Volume_Up
- Volume_Down
- Volume_Mute
- Media_Play_Pause
- Media_Next
- Media_Prev
- Media_Stop
- Browser_Back
- Browser_Forward
- Browser_Refresh
- PrintScreen
- Win+Shift+S等のSystem Shortcut

Power Off / Shutdown等の破壊的System Actionは初期標準Actionには含めない。

---

## 13. Layer

### 13.1 基本仕様

- 起動時は `DefaultLayer`
- 常にActive Layerは1つ
- Layer Stackなし
- Holdによる一時Layerなし
- One-shot Layerなし

### 13.2 LayerSwitch

初期Mode:

- `Set`: 指定Layerへ切替
- `Next`: `LayerOrder`順に循環

例:

```ini
[Action-LayerNext]
Type=LayerSwitch
Label=Next Layer
Mode=Next
```

切替時は短時間ToolTipでLayer名を表示する。

Layer切替ActionはGlobal Key Mappingへ置くことを推奨する。

---

## 14. Multi Action

### 14.1 基本仕様

複数ActionをConfig記載順に実行する。

```ini
[Action-CopyToChatGPT]
Type=MultiAction
Label=Copy to ChatGPT
Step1=Copy
Step2=Delay100
Step3=ChatGPTActivate
Step4=Paste
```

DelayもActionとして定義する。

```ini
[Action-Delay100]
Type=Delay
Label=100 ms
Milliseconds=100
```

### 14.2 初期制約

- Step番号は1から連続
- 存在しないAction参照は起動時Error
- MultiActionからMultiActionを呼ぶNested Macroは初期実装では禁止
- Action参照CycleはValidationで拒否
- 同一MultiActionの実行中再入は抑止する
- Delay中にController全体をCritical状態でブロックしない

Window切替をMulti Actionへ組み込む場合は通常 `Behavior=Activate` のWindow Actionを使用する。

---

## 15. Disabled / Pass-through

`Type=Disabled` は「そのMappingでController Actionを実行しない」用途とする。

実装時にはNative Inputを不要に遮断しないことを必須とする。

各Layerで未定義Keyを許可するか、全Key明示を必須にするかは、Native Pass-throughを安全に実装できる方式に合わせてValidator側で統一する。

少なくともBackspaceについては、通常Keyboardとの区別がない現行制限を維持し、DefaultではController対象にしない。

---

## 16. 今回実装しない機能

以下はPhase K Scope外。

- Tap
- Hold
- Double Tap
- Tap Dance
- マウスClick / Wheel / Cursor操作
- Keyboard Device単位識別
- AutoHotInterception等のDriver依存Backend

設計上の拡張余地は残すが、Phase KのConfig / Runtimeへ未使用の複雑性を持ち込まない。

---

## 17. Test方針

最低限以下を自動Regressionへ追加する。

### Config

- ConfigVersion 3正常読込
- ConfigVersion 1 / 2拒否
- Layer / Action参照Validation
- MultiAction Step Validation
- WindowGroup Validation
- KeySend Combination Validation

### Virtual00

- Numpad0
- Virtual00
- Virtual000
- Virtual00のみON
- Virtual000のみON
- 両方ON
- Timeout境界
- Modifier付き入力
- Interrupt
- Long press / Repeat

### Action

- KeySend
- Media Key
- Layer Set / Next
- MultiAction
- Delay
- MultiAction再入抑止

### Window

- Inactive → Activate
- Active → Minimize
- Minimized → Restore + Activate
- Behavior=ActivateではActive WindowをMinimizeしない
- Binding消滅 → Auto Bind
- Group Window 0 → Launch
- Group Window 1以上 → Launchしない / NotFound
- LaunchPending中 → 重複Runしない
- Pending Timeout後 → 再試行可能

### Physical Acceptance

Virtual00は実機なしのためN/A。

既存テンキーで以下を実機確認する。

- Layer切替
- KeySend
- Media/System
- MultiAction
- Window Toggle
- Launch fallback
- Virtual000 Regression

---

## 18. Documentation方針

Phase K実装時に以下を新仕様へ同期する。

- README
- TASKS
- PROJECT_HANDOFF
- KNOWN_LIMITATIONS
- CHANGELOG
- KeyBindings.default.ini
- examples/*.ini
- Controller Regression Test文書

Phase A～J文書は過去時点の履歴として原則書き換えない。

ConfigVersion 1 / 2のMigration Guideも過去Release資料として残し、現行Runtimeが互換対応しているような説明は新しいREADMEから削除する。

---

## 19. Phase K完了条件

- ConfigVersion 3のみで起動できる
- ConfigVersion 1 / 2互換コードをRuntimeから除去
- Physical Key → Layer → Action Dispatcherが正本になる
- Virtual00 Logic TestがPASS
- KeySend / Media/Systemが動作
- Layer切替が安定動作
- Multi Actionが定義順に実行される
- Window Toggleが動作
- Launch fallbackがGroup単位要件を満たす
- LaunchPendingで多重起動を防止
- 現行Window Binding / Auto Bind機能を新Action Model上で再構成
- Controller Regression / Startup RegressionがPASS
- 物理受入でVirtual00以外のPhase K機能を確認
- README / TASKS / PROJECT_HANDOFF / Known Limitations / CHANGELOGが整合する

---

## 20. 実装順

推奨順:

```text
K-1 ConfigVersion 3 / Action Model
    ↓
K-2 Layer Resolver / Action Dispatcher
    ↓
K-3 Window Action移植
    ↓
K-4 Virtual00
    ↓
K-5 KeySend / Media-System
    ↓
K-6 Window Toggle
    ↓
K-7 Launch Fallback / LaunchPending
    ↓
K-8 Multi Action / Delay
    ↓
K-9 Config / Example全面移行
    ↓
K-10 Regression / Physical Acceptance / Documentation
```
