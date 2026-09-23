# Numpad Window Controller - MVP Design

更新日: 2026-09-23  
対象バージョン: MVP / v0.1 設計案  
状態: Review Required  
実装状態: 未実装

> この文書は、まず最低限動作する初期版を実装するために、これまで未確定だった仕様を具体化した設計書である。
> 実装は本書のレビュー完了後に開始する。

---

## 1. 目的

一般的なUSBテンキーを、Windows上で頻繁に使用するウィンドウへ直接移動するための専用コントローラーとして利用する。

MVPでは次の2機能を提供する。

1. テンキーの物理キーとWindowを1対1でBindingし、1キーで対象Windowへ移動する。
2. 一部キーをWindow BindingではなくShortcutとして設定し、アプリケーションやバッチファイルを起動する。

同一アプリケーションの複数Windowを個別に扱えることを重視する。

---

## 2. MVPの設計方針

MVPでは機能を増やしすぎず、日常利用できる最小構成を優先する。

採用するもの:

- AutoHotkey v2
- HWNDによるRuntime Window Binding
- 手動Binding
- Chrome 3WindowのAuto Bind
- VS Code 3WindowのAuto Bind
- Explorer / ChatGPTデスクトップ / pwsh系TerminalのAuto Bind
- Window単位のClear
- 全Window BindingのClear
- Shortcut実行
- INI設定ファイル
- ToolTipによる簡易通知

MVPでは採用しないもの:

- GUI設定画面
- Hot Reload
- 常時Window監視
- Window Bindingの永続保存
- 外付けテンキーとメインキーボードの厳密なデバイス識別
- 高度なマルチモニター自動判定
- 4つ目以降のChrome / VS Codeの自動一般Slot割り当て
- 複雑なWindowスコアリング
- プラグイン機構
- 自動アップデート

---

## 3. 対象環境

- OS: Windows 11
- AutoHotkey: v2系
- 入力デバイス: 現在使用しているUSBテンキー
- NumLock: スクリプト実行中はON固定
- Chrome: Google Chrome
- VS Code: Visual Studio Code
- Terminal: PowerShell 7を主用途とするWindows Terminalまたは直接起動されたpwsh Window

### 3.1 外付けテンキー識別の制約

MVPでは、AutoHotkeyから外付けテンキーと通常キーボード側の同一テンキーキーを区別しない。

したがって、例えば外付けテンキーの `Numpad7` とメインキーボード側の `Numpad7` は同じHotkeyとして扱われる。

これはMVPのKnown Limitationとする。

---

## 4. 実機キー情報

実機Key Historyで確認済みの値を基準とする。

| 物理キー | VK | SC | AutoHotkey Key |
|---|---:|---:|---|
| NumLock | 90 | 145 | NumLock |
| `/` | 6F | 135 | NumpadDiv |
| `*` | 6A | 037 | NumpadMult |
| `-` | 6D | 04A | NumpadSub |
| `7` | 67 | 047 | Numpad7 |
| `8` | 68 | 048 | Numpad8 |
| `9` | 69 | 049 | Numpad9 |
| `+` | 6B | 04E | NumpadAdd |
| `4` | 64 | 04B | Numpad4 |
| `5` | 65 | 04C | Numpad5 |
| `6` | 66 | 04D | Numpad6 |
| DEL | 08 | 00E | Backspace |
| `1` | 61 | 04F | Numpad1 |
| `2` | 62 | 050 | Numpad2 |
| `3` | 63 | 051 | Numpad3 |
| `0` | 60 | 052 | Numpad0 |
| `.` | 6E | 053 | NumpadDot |
| Enter | 0D | 11C | NumpadEnter |

### 4.1 000キーとVirtual000

物理 `000` キーは独立したVK/SCを持たず、`Numpad0` のDown/Upを3回高速に発生させる。

PoCでは通常の `0` と `000` を誤認識なく区別できたため、MVPではこの入力列をソフトウェアで検出し、独立した論理キー **`Virtual000`** として扱う。

初期判定条件:

- 最初の `Numpad0 Down` から80ms以内。
- `Down-Up-Down-Up-Down-Up` が連続して成立。
- 判定中に別キーのDownが割り込まない。

判定結果:

```text
通常の0
  → Numpad0

高速 D-U × 3
  → Virtual000
```

物理 `000` から生成された3回の `Numpad0` は個別の `Numpad0` 操作として実行せず、1回の `Virtual000` 操作へ集約する。

通常の `Numpad0` は `000` 判定のため最大約80msの確定待ち時間を持つ。Window切り替え用途では許容する。

PoCの高頻度ログ書き込みではファイル競合エラーが発生したが、入力識別自体は通常使用の各入力パターンで誤認識なく動作したため、ログ競合はPoC固有事項としてMVP本体の判定仕様には持ち込まない。

---

## 5. キーMode

設定可能なModeは3種類とする。

| Mode | 説明 |
|---|---|
| Window | Window Binding用 |
| Shortcut | アプリ・ファイル実行用 |
| Disabled | 何もしない |

従来案にあった汎用 `Function` ModeはMVPでは採用しない。

NumLockだけは設定ファイル外の予約Function Keyとして扱う。

### 5.1 Virtual000の扱い

`Virtual000` は物理キー名ではなく、本ツール内部で生成する論理キー名である。

設定・Runtime State・Hotkeyディスパッチでは他のキーと同等に扱い、`Window / Shortcut / Disabled` のいずれも設定可能とする。

INIのSection名は `[Key-Virtual000]` を使用する。

修飾キーも判定時に保持し、例えば `Ctrl + 000` は `Ctrl + Virtual000` として扱う。

### 5.2 排他

1キーは1つのModeだけを持つ。

ShortcutまたはDisabledのキーは:

- Manual Bind不可
- Auto Bind対象外
- Window Activate対象外

とする。

---

## 6. 既定キー配置

| キー | MVP既定用途 | Mode | Auto Bind |
|---|---|---|---|
| NumLock | Auto Bind All | 予約Function | - |
| `/` | 任意 | Window | OFF |
| `*` | 任意 | Window | OFF |
| `-` | 任意 | Window | OFF |
| `7` | Chrome1 | Window | ON |
| `8` | Chrome2 | Window | ON |
| `9` | Chrome3 | Window | ON |
| `+` | 任意 | Window | OFF |
| `4` | VSCode1 | Window | ON |
| `5` | VSCode2 | Window | ON |
| `6` | VSCode3 | Window | ON |
| DEL / Backspace | 任意 | Window | OFF |
| `1` | Explorer | Window | ON |
| `2` | ChatGPT Desktop | Window | ON |
| `3` | pwsh / Windows Terminal | Window | ON |
| `0` | 任意 | Window | OFF |
| `000` / `Virtual000` | 任意 | Window | OFF |
| `.` | 任意 | Window | OFF |
| Enter | 任意 | Window | OFF |

任意キー（`Virtual000` を含む）はMVPでは自動的にWindowを埋めない。

必要なWindowをユーザーが `Ctrl + Key` で手動Bindingする。

これにより、予期しないWindowが空きキーへ勝手に割り当てられることを防ぐ。

---

## 7. 操作仕様

### 7.1 入力正規化

物理入力を直接Window処理へ渡さず、まず論理キーへ正規化する。

```text
物理Numpad0
  ↓ 80ms判定
通常単打      → Numpad0
高速D-U×3     → Virtual000
```

以降のWindow / Shortcut / Clear等の処理は、正規化済みの論理キーを対象にする。

### 7.2 通常押下

Window Mode:

```text
Key
→ Binding済みWindowをActivate
```

Shortcut Mode:

```text
Key
→ 設定されたShortcutを実行
```

Disabled:

```text
Key
→ 何もしない
```

### 7.3 Manual Bind

```text
Ctrl + Key
```

現在アクティブなWindowを、そのキーへManual Bindする。

条件:

- KeyがWindow Modeであること。
- 固定用途SlotではAllowed条件を満たすこと。
- Shortcut / Disabledは拒否する。

### 7.4 Slot Clear

```text
Ctrl + Shift + Key
```

対象Window SlotのRuntime Bindingを解除する。

設定ファイルは変更しない。

### 7.5 Auto Bind All

```text
NumLock
```

全Auto Bind対象Slotを再評価する。

NumLock本来のON/OFF切り替えは実行しない。

### 7.6 Clear All

```text
Ctrl + NumLock
```

全Window SlotのRuntime Bindingだけを解除する。

Shortcut設定やINI設定は変更しない。

### 7.7 NumLock状態

スクリプト起動時にNumLockをONにし、実行中はON状態を維持する。

理由:

- `Numpad7` 等のAutoHotkey Key Nameを安定させる。
- NumLockを本ツールのGlobal Function Keyとして利用する。

Known Limitation:

- メインキーボード側のNumLock利用にも影響する。

---

## 8. Binding State

各Window SlotはRuntimeに次の状態を持つ。

- Key
- Label
- HWND
- BindingSource
- AllowedProcess
- AllowedClass
- AutoBind
- AutoBindGroup

BindingSource:

| 値 | 意味 |
|---|---|
| None | 未Binding |
| Auto | Auto Bindで設定 |
| Manual | Ctrl+Keyで設定 |

HWNDとBindingSourceは永続化しない。

---

## 9. Manual Bind優先ルール

MVPではManual BindをAuto Bindより優先する。

### 9.1 Auto Bind All

有効なManual Bindは上書きしない。

```text
Manual Bindが存在
  ↓
対象HWNDがまだ存在
  ↓
そのSlotを固定
```

### 9.2 Manual Binding先Windowが閉じた場合

Manual Bind先HWNDが無効になった時点で、そのManual Bindは失効する。

AutoBind=ONのSlotなら、次回のLazy Auto BindまたはAuto Bind Allで自動割り当てへ戻す。

AutoBind=OFFの任意Slotなら空Slotへ戻す。

### 9.3 重複Binding

同一HWNDを複数SlotへBindingすることは禁止する。

Manual Bind時に、そのHWNDが別Slotに存在する場合:

1. 旧SlotからBinding解除。
2. 新SlotへManual Bind。
3. 旧Slotは空になる。

Auto Bind時も、確定済みHWNDは後続候補から除外する。

---

## 10. Window Activate

Window Modeの通常押下時:

1. HWNDが存在するか確認。
2. Windowが最小化されていればRestore。
3. WindowをActivate。
4. 前面へ移動できなければ失敗通知。

Bindingが無効な場合:

- AutoBind=ON → Lazy Auto Bindを実行。
- AutoBind=OFF → `Slot is empty` を通知。

---

## 11. Auto Bind共通ルール

Auto Bind対象は `AutoBind=ON` のWindow Slotのみ。

処理順:

1. 有効なManual Bindを確保。
2. Chrome Groupを処理。
3. VS Code Groupを処理。
4. Explorerを処理。
5. ChatGPT Desktopを処理。
6. pwsh / Windows Terminalを処理。
7. 結果をRuntime Stateへ反映。

MVPでは任意Slotへの一般Window自動割り当ては行わない。

4つ目以降のChrome / VS Codeも自動割り当てしない。

必要な場合は任意SlotへManual Bindする。

---

## 12. Chrome Auto Bind

対象Process:

```text
chrome.exe
```

専用Slot:

- Numpad7 = Chrome1
- Numpad8 = Chrome2
- Numpad9 = Chrome3

MVPではPrimary MonitorのWork Areaを基準とする。

### 12.1 Chrome1

想定位置:

- 左上
- 幅: 約30%
- 高さ: 約50%

### 12.2 Chrome2

想定位置:

- 左下
- 幅: 約30%
- 高さ: 約50%

### 12.3 Chrome3

想定位置:

- 右側
- 幅: 約70%
- 高さ: 約100%

### 12.4 判定方式

MVPでは複雑な最適化計算を使わず、Window中心座標とサイズ比率で分類する。

Primary Monitor Work Areaを:

- X: 0.0 ～ 1.0
- Y: 0.0 ～ 1.0

へ正規化する。

分類:

Chrome1候補:

- Window中心X < 0.40
- Window中心Y < 0.50
- Window幅がWork Areaの15%～45%
- Window高さがWork Areaの30%～70%

Chrome2候補:

- Window中心X < 0.40
- Window中心Y >= 0.50
- Window幅がWork Areaの15%～45%
- Window高さがWork Areaの30%～70%

Chrome3候補:

- Window中心X >= 0.40
- Window幅がWork Areaの50%～90%
- Window高さがWork Areaの70%～105%

複数候補が同じ分類に入った場合は、想定矩形との位置・サイズ差が最も小さいWindowを採用する。

候補が見つからなければ対象Slotは空のままにする。

### 12.5 Chrome 4Window以上

4つ目以降はMVPではAuto Bindしない。

Manual Bindで任意Slotへ設定可能。

---

## 13. VS Code Auto Bind

対象Process:

```text
Code.exe
```

専用Slot:

- Numpad4 = VSCode1
- Numpad5 = VSCode2
- Numpad6 = VSCode3

要求としては「開いた順」を優先する。

しかし、スクリプト起動前にすでに存在する複数VS Code Windowについて、Windowsから真のWindow生成順を常に復元できることはMVPでは前提にしない。

### 13.1 MVPの順序定義

MVPでは `First Observed Order` を使用する。

スクリプトが初めてVS Code Windowを観測したとき、各HWNDに連番を付ける。

```text
Observed #1 → Numpad4
Observed #2 → Numpad5
Observed #3 → Numpad6
```

### 13.2 起動時にすでに複数Windowが存在する場合

最初の観測時にAutoHotkeyから取得できるWindow列挙順を初期順として採用する。

この順は本来の「開いた順」と一致しない可能性がある。

その場合は:

```text
Ctrl + Numpad4
Ctrl + Numpad5
Ctrl + Numpad6
```

でManual Bindして補正する。

Manual BindはAuto Bind Allでも保持される。

### 13.3 新規Window

スクリプト実行中に新しいVS Code Windowが観測された場合、未観測HWNDへ次のObservation Sequenceを付与する。

常時ポーリングは行わないため、新Windowの観測タイミングは:

- Auto Bind All
- Lazy Auto Bind
- VS Code Slot操作

のいずれかとする。

### 13.4 4Window以上

Observation Sequenceが4番目以降のVS Code WindowはMVPではAuto Bindしない。

任意SlotへManual Bind可能。

---

## 14. Explorer Auto Bind

Numpad1はExplorer専用Slotとする。

基本対象:

- Process: `explorer.exe`
- 可視トップレベルWindow
- デスクトップShellやタスクバー等は除外

複数Explorer Windowがある場合、Auto Bind時に最も前面側にある通常Explorer Windowを採用する。

Manual Bindで別Explorer Windowへ変更可能。

Allowed条件:

- Explorer Window以外はNumpad1へManual Bind不可。

---

## 15. ChatGPT Desktop Auto Bind

Numpad2はChatGPTデスクトップ専用Slotとする。

Process Name / Window Classは実装前に実機で確認し、INIの既定値として記録する。

設計上はProcess Nameによる判定を第一条件とする。

複数候補がある場合は最も前面側のWindowを採用。

Manual BindはChatGPT Desktopと判定されたWindowだけ許可する。

Process Nameが将来変更された場合はINI編集で対応する。

---

## 16. pwsh / Windows Terminal Auto Bind

Numpad3は「PowerShell 7作業用Terminal Window」を対象とする。

Windows 11ではpwshがWindows Terminal内で動作する場合があるため、MVPでは次の順に候補を探す。

1. Windows TerminalのトップレベルWindowで、Titleに `PowerShell` または `pwsh` を含むもの。
2. 直接トップレベルWindowとして取得できる `pwsh.exe`。
3. 条件一致なしなら未Binding。

複数候補がある場合は最も前面側を採用。

Known Limitation:

- Windows Terminalのタブ内部プロセスを完全には追跡しない。
- Titleがカスタマイズされている場合、自動検出できない可能性がある。

その場合はManual Bindで補正可能とする。

---

## 17. Lazy Auto Bind

AutoBind=ONのSlotで、通常押下時に:

- HWNDが未設定
- HWNDが消滅
- HWNDがAllowed条件に一致しなくなった

場合、そのSlotが所属するGroupだけ再評価する。

例:

```text
Numpad7押下
  ↓
Chrome1 HWND無効
  ↓
Chrome Group再評価
  ↓
7/8/9を必要に応じて再構築
  ↓
Numpad7をActivate
```

Manual Bindが有効な他Slotは維持する。

---

## 18. Clear仕様

### 18.1 Slot Clear

`Ctrl + Shift + Key`

対象Slot:

- HWND = empty
- BindingSource = None

へ変更する。

AutoBind=ONでも、その場では再Auto Bindしない。

次回通常押下するとLazy Auto Bindされる。

### 18.2 Clear All

`Ctrl + NumLock`

全Window Slot:

- HWND = empty
- BindingSource = None

へ変更する。

Auto Bindは自動実行しない。

再構築したい場合はNumLockを押す。

これにより:

```text
Ctrl + NumLock
→ 全解除

NumLock
→ Auto対象だけ再構築
```

という明確な操作にする。

---

## 19. Shortcut Mode

ShortcutはINIで設定する。

MVPで対応するTarget:

- `.exe`
- `.bat`
- `.cmd`
- Windowsが通常実行可能なファイルまたはショートカット

PowerShell Scriptを実行したい場合は、Targetを `pwsh.exe` とし、Argumentsに `-File ...` を設定する。

### 19.1 Shortcut項目

- Target
- Arguments
- WorkingDirectory

Arguments / WorkingDirectoryは空欄可。

### 19.2 実行済みアプリ

Shortcutは「既存Windowを探す」のではなく、設定されたTargetを毎回実行する。

既に起動済みアプリをActivateする用途はWindow Modeを使用する。

この2機能を明確に分離する。

---

## 20. 設定ファイル

MVPはINIを採用する。

理由:

- AutoHotkey v2から読みやすい。
- ユーザーが手動編集しやすい。
- MVPで必要な設定は階層が浅い。
- JSON parser等の追加依存を避けられる。

ファイル名:

```text
KeyBindings.ini
```

### 20.1 Window Keyの設定項目

- Mode
- Label
- AllowedProcess
- AllowedClass
- AutoBind
- AutoBindGroup

必要のない項目は空欄可。

### 20.2 Shortcut Keyの設定項目

- Mode
- Label
- Target
- Arguments
- WorkingDirectory

### 20.3 Virtual000設定例

```ini
[Key-Virtual000]
Mode=Window
Label=Virtual 000
AutoBind=false
```

Shortcutとして利用する場合も、通常キーと同様に `Mode=Shortcut` と `Target` 等を設定する。

### 20.4 Reserved Key

NumLockはINIから変更不可とする。

MVPではGlobal Function Keyとして固定する。

### 20.5 設定変更

INIを編集した後はスクリプトを再起動する。

Hot Reloadは行わない。

---

## 21. 設定検証

起動時にINIを検証する。

Fatal Errorとしてスクリプトを終了する条件:

- 未知のKey Section
- 不正なMode
- 必須設定不足
- Chrome専用Slotの制約が破壊されている
- VS Code専用Slotの制約が破壊されている
- 同じ物理Keyの重複定義

Shortcut Targetが存在しない場合もMVPではFatal Errorとする。

理由:

部分的に壊れた設定で常駐するより、起動時に明確に修正させる方が初期版では安全である。

エラーはMsgBox等で:

- Section
- Field
- Error reason

を表示する。

---

## 22. 起動処理

スクリプト起動時:

1. Single Instanceを保証。
2. NumLockをON固定。
3. INIを読み込む。
4. 設定検証。
5. Runtime Stateを初期化。
6. Numpad0 / Virtual000入力判定器を初期化。
7. Hotkeyを登録。
8. VS Code Observation Stateを初期化。
9. Auto Bind Allを1回実行。
10. 常駐開始。

Chrome / VS Code等がまだ起動していなくてもエラーにはしない。

後からWindowが起動した場合はLazy Auto BindまたはNumLockで取得する。

---

## 23. Window列挙対象

MVPでAuto Bind対象にするWindowは:

- 可視トップレベルWindow
- 対象Process / Class条件に一致
- Tool Window等の補助Windowではない
- HWNDが有効

とする。

次は候補から除外する。

- 本スクリプト自身のWindow
- 非表示Window
- デスクトップShell
- タスクバー
- 明らかな補助・ポップアップWindow

具体的なClass除外値は実装時に実機確認して確定する。

---

## 24. 通知

常設GUIは作らない。

短時間ToolTipを使用する。

通知対象:

- Manual Bind成功
- Manual Bind拒否
- Slot Clear
- Clear All
- Auto Bind All完了
- Slot未登録
- Auto Bind失敗
- Shortcut実行失敗

通常のWindow Activate成功時は通知しない。

日常操作で毎回通知が出ないようにする。

---

## 25. ファイル構成

MVPは過剰に分割しない。

```text
NumpadWindowController/
├─ NumpadWindowController.ahk
├─ KeyBindings.ini
├─ README.md
├─ TASKS.md
├─ PROJECT_HANDOFF.md
└─ docs/
   ├─ DESIGN_DRAFT.md
   └─ MVP_DESIGN.md
```

初期実装は `NumpadWindowController.ahk` 1ファイルにまとめる。

理由:

- MVP規模では追跡しやすい。
- AHK include構成を早期に複雑化しない。
- 実装が安定してから責務分割できる。

目安として、コード量または責務が増えた段階で `lib/` 分割を検討する。

---

## 26. Runtime State

スクリプト内部では少なくとも次を保持する。

### 26.1 Key Definition

- Key Name
- Mode
- Label
- Allowed Process
- Allowed Class
- AutoBind
- AutoBindGroup
- Shortcut settings

### 26.2 Window Binding

- HWND
- BindingSource

### 26.3 VS Code Observation

- HWND
- Observation Sequence

### 26.4 Used HWND Set

Auto Bind時の重複を防ぐため、現在Binding済みHWND集合を保持する。

### 26.5 Numpad0 / Virtual000 Detector

- 判定開始Tick
- D/Uイベント列
- 判定中Modifier State
- 80ms判定Timer
- 判定中断状態

を保持し、物理 `Numpad0` 入力を `Numpad0` または `Virtual000` へ正規化する。

---

## 27. エラー処理

Windowが閉じること自体は正常系として扱う。

Window消滅:

- エラー表示しない。
- Runtime Bindingを無効扱い。
- 必要時にLazy Auto Bind。

設定不正:

- 起動失敗。

Shortcut起動失敗:

- ToolTipまたはMsgBoxで通知。
- スクリプト自体は継続。

Window Activate失敗:

- ToolTip。
- Slotを即削除せず、HWND有効性を再確認。
- HWND無効ならBinding解除。

---

## 28. MVP受入条件

以下がすべて満たされた時点で「最低限動作する」と判定する。

### Chrome

- Numpad7 → 左上Chrome
- Numpad8 → 左下Chrome
- Numpad9 → 右大Chrome
- Chrome再起動後、NumLockまたはLazy Auto Bindで復旧可能

### VS Code

- Numpad4 / 5 / 6で3Windowを個別切替可能
- 初期自動順が意図と違う場合、Ctrl+4/5/6で補正可能
- Manual BindがAuto Bind Allで維持される

### その他固定Slot

- Numpad1 → Explorer
- Numpad2 → ChatGPT Desktop
- Numpad3 → PowerShell系Terminal

### 任意Slot

- `/ * - + DEL 0 000 . Enter` に任意WindowをManual Bind可能
- INIでShortcutへ変更可能

### Global操作

- NumLock → Auto Bind All
- Ctrl+NumLock → Clear All
- Ctrl+Key → Manual Bind
- Ctrl+Shift+Key → Slot Clear

### Virtual000

- 通常の `0` と物理 `000` を誤認識なく区別できる
- `000` 1回が `Virtual000` 1回として処理される
- `000` によって `Numpad0` のWindow処理が3回実行されない
- `Virtual000` をWindowまたはShortcutとして設定できる

### Shortcut

- EXEまたはBAT/CMDを実行可能
- Shortcut ModeのKeyへWindow Bindingされない

---

## 29. MVP Known Limitations

1. 外付けテンキーと通常キーボードの同一テンキーキーを区別しない。
2. NumLockはスクリプト実行中ON固定。
3. 通常の `Numpad0` は `Virtual000` 判定のため最大約80msの入力確定待ち時間を持つ。
4. Chrome座標判定はPrimary Monitor Work Areaを基準とする。
5. 複雑なマルチモニター配置は対象外。
6. VS Codeの真のWindow生成順をスクリプト再起動後に保証しない。
7. スクリプト起動前のVS Code複数Windowは初回列挙順を使用する。
8. 4つ目以降のChrome / VS Codeは自動割り当てしない。
9. Windows Terminal内部のpwshタブを完全には識別しない。
10. 設定変更にはスクリプト再起動が必要。
11. GUI設定画面はない。
12. Runtime Bindingはスクリプト終了時に失われる。

---

## 30. MVP後に検討する機能

MVPの実機運用後、必要性が確認できたものだけ追加する。

候補:

- Virtual000判定閾値のユーザー設定化
- 外付けテンキーのデバイス単位識別
- Multi Monitor対応
- VS Code順序復元の高度化
- 4つ目以降のChrome / VS Code一般Auto Bind
- Runtime Binding永続化
- GUI設定画面
- Hot Reload
- Tray Menu
- Debug Log
- Window一覧表示
- Key Label表示
- AutoHotInterception採用

---

## 31. 実装開始前のレビュー項目

本書レビューでは特に以下を確認する。

1. NumLockをAuto Bind Allにしてよいか。
2. NumLockをON固定してよいか。
3. Ctrl+NumLockをClear Allにしてよいか。
4. 任意キーをAuto BindせずManual専用にしてよいか。
5. Manual BindをAutoより優先してよいか。
6. Chrome判定をPrimary Monitor座標方式にしてよいか。
7. VS CodeをFirst Observed Order + Manual補正としてよいか。
8. 4つ目以降のChrome / VS CodeをMVPでは手動割り当てにしてよいか。
9. 1/2/3を専用Slotとして制限してよいか。
10. INI設定＋スクリプト再起動方式でよいか。
11. 初期実装を単一AHKファイルにしてよいか。
12. **採用済み:** 000は `Virtual000` として正式採用し、Numpad0には最大約80msの判定遅延を許容する。

この12点に問題がなければ、MVP実装へ進める。
