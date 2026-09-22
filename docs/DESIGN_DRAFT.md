# Numpad Window Controller - 暫定設計

更新日: 2026-09-23  
状態: Draft / 設計継続中

## 1. 目的

一般的な安価なUSBテンキーを、Windows上のウィンドウを直接呼び出すための専用コントローラーとして利用する。

単純な「アプリ切り替え」ではなく、同じアプリを複数ウィンドウで使用している場合でも、特定のウィンドウとテンキーの物理キーを1対1で対応させられることを重視する。

主な想定例:

- Chromeを常時3ウィンドウで使用し、それぞれを `7 / 8 / 9` から直接呼び出す
- VS Codeを複数プロジェクトで開き、それぞれを `4 / 5 / 6` から直接呼び出す
- その他のテンキーキーにも任意のウィンドウを割り当てる
- 毎回の手動登録を減らすため、条件と優先順位による自動割り当てを行う

---

## 2. 対象環境

- OS: Windows 11
- 実装候補: AutoHotkey v2
- 入力デバイス: 一般的なUSBテンキー
- 初期版では NumLock ON を前提とする

専用マクロデバイスや専用ドライバを必須としない。

---

## 3. 基本概念

### 3.1 Window Slot

テンキーの各物理キーを `Window Slot` として扱う。

各Slotは、単なるHWNDの保存先ではなく、以下の情報を持つ。

- Key
- Label
- 登録可能なウィンドウ条件
- Auto Bindの可否
- Auto Bind時の優先条件
- 現在BindingされているHWND
- BindingSource
  - Manual
  - Auto
  - None

概念例:

```text
Slot 7
  Key: Numpad7
  Label: Chrome 1
  AllowedProcess: chrome.exe
  AutoBind: true
  PriorityRules: ...
  HWND: ...
  BindingSource: Auto / Manual / None
```

---

## 4. 初期Slot方針

数値キーだけでなく、一般的なテンキーに存在する演算キー等も利用可能な構造とする。

| 物理キー | Slot | 初期限界 |
|---|---|---|
| Numpad7 | 7 | Chromeのみ |
| Numpad8 | 8 | Chromeのみ |
| Numpad9 | 9 | Chromeのみ |
| Numpad4 | 4 | VS Codeのみ |
| Numpad5 | 5 | VS Codeのみ |
| Numpad6 | 6 | VS Codeのみ |
| Numpad1 | 1 | 任意 |
| Numpad2 | 2 | 任意 |
| Numpad3 | 3 | 任意 |
| Numpad0 | 0 | 任意 |
| NumpadDot | Dot | 任意 |
| NumpadDiv | Divide | 任意 |
| NumpadMult | Multiply | 任意 |
| NumpadSub | Subtract | 任意 |
| NumpadAdd | Add | 任意 |
| NumpadEnter | Enter | 任意 |

この表は初期案であり、今後変更可能とする。

---

## 5. 固定アプリ制約

### 5.1 Chrome

`Numpad7 / 8 / 9` は必ず Google Chrome のウィンドウのみを受け付ける。

想定条件:

```text
AllowedProcess = chrome.exe
```

Chrome以外のウィンドウを手動登録しようとした場合は拒否する。

### 5.2 VS Code

`Numpad4 / 5 / 6` は必ず Visual Studio Code のウィンドウのみを受け付ける。

想定条件:

```text
AllowedProcess = Code.exe
```

VS Code以外のウィンドウを手動登録しようとした場合は拒否する。

### 5.3 その他

`0 / 1 / 2 / 3 / Dot / Divide / Multiply / Subtract / Add / Enter` は、初期案では任意のウィンドウを登録可能とする。

将来的にはSlotごとに個別制約を設定できる構造とする。

---

## 6. 手動Binding

全Slotで同じ基本操作体系を採用する。

### 6.1 通常押下

```text
NumpadX
```

Slot X にBindingされているウィンドウを前面へ移動する。

処理:

```text
キー押下
  ↓
SlotのHWNDを取得
  ↓
HWNDが現在も有効か確認
  ↓
Slot制約に適合するウィンドウか再確認
  ↓
最小化されていれば復元
  ↓
前面へActivate
```

### 6.2 手動登録

```text
Ctrl + NumpadX
```

現在アクティブなウィンドウをSlot Xへ登録する。

登録前に必ずSlot制約を検証する。

例:

- `Ctrl + Numpad7` でChrome → 登録可能
- `Ctrl + Numpad7` でVS Code → 登録拒否
- `Ctrl + Numpad4` でVS Code → 登録可能
- `Ctrl + Numpad4` でChrome → 登録拒否

### 6.3 BindingSource

手動登録された場合:

```text
BindingSource = Manual
```

自動登録された場合:

```text
BindingSource = Auto
```

未登録:

```text
BindingSource = None
```

---

## 7. HWNDによるRuntime Binding

実行中のウィンドウ識別には HWND を利用する。

利点:

- Chromeの現在のタブタイトルが変化しても、同じChromeウィンドウを追跡できる
- VS Codeのタイトルが多少変化しても、一度Bindingした後は同じウィンドウを直接Activateできる

ただしHWNDはプロセス・ウィンドウの再生成で変化するため、永続的な識別子としては利用しない。

---

## 8. 設定とRuntime Stateの分離

### 8.1 永続化するConfiguration

例:

```text
Slot 7
  AllowedProcess = chrome.exe
  PriorityRules = ...
  Label = Chrome 1
```

### 8.2 永続化しないRuntime State

例:

```text
Slot 7
  HWND = 123456
  BindingSource = Auto
```

PC再起動や対象アプリ再起動後は、保存済みConfigurationを利用して新しいHWNDを再探索する。

---

## 9. 重複Binding

原則として、同一ウィンドウを複数Slotへ同時Bindingしない。

例:

```text
Slot 7 -> Chrome A
```

の状態でChrome AをSlot 8へ手動登録した場合、初期案では:

```text
Slot 7 -> Empty
Slot 8 -> Chrome A
```

とする。

自動Bindingでも、1つのウィンドウが複数Slotの候補として選ばれないよう、確定済みウィンドウを候補から除外する。

この挙動は今後再検討可能。

---

## 10. Auto Bind

手作業で毎回ウィンドウを登録する負担を減らすため、自動Binding機能を持たせる。

### 10.1 基本処理

```text
Windows上の対象ウィンドウ一覧を取得
  ↓
SlotのAllowed条件に適合するウィンドウを抽出
  ↓
Priority Ruleで候補を評価
  ↓
最上位候補を選択
  ↓
重複を避けてSlotへBinding
```

### 10.2 Manual Bindの優先

初期案では、有効なManual BindはAuto Bindより優先する。

例:

```text
Slot 7 = Auto
Slot 8 = Manual
Slot 9 = Auto
```

Auto Bind Allを実行しても、Slot 8のManual Bindが有効な限り上書きしない。

---

## 11. Priority Rule

Auto Bindでは、複数候補から対象を選ぶため優先条件を設定できるようにする。

利用候補:

- Process
- Window Class
- Window Title
- Monitor
- Window Position
- Window Size
- Z-order

優先条件は複数段階設定可能とする。

例:

```text
Slot 7
  AllowedProcess = chrome.exe

  Priority:
    1. Title contains "ChatGPT"
    2. Monitor = 1
    3. Position = Left
    4. Window order
```

基本思想:

```text
具体的な条件
  ↓
一致しなければ次の条件
  ↓
Fallback条件
```

---

## 12. Chromeの自動割り当て

Chromeは通常、現在表示しているタブによってウィンドウタイトルが変化する。

そのためChromeの永続的なウィンドウ識別を、タイトルだけに依存させない。

Auto Bind候補として以下を組み合わせる。

- `chrome.exe`
- Monitor
- Window Position
- Title
- Window Size
- その他Windowsから得られる安定情報

一度Bindingされた後はHWNDを使用するため、タブタイトルが変化してもBindingは維持できる。

### 制約

複数Chromeウィンドウが以下のすべてで区別不能な場合:

- 同一プロセス種別
- 同一モニター
- 同一または近い位置
- タイトルが可変
- その他の安定した識別情報がない

再起動後に「以前のChrome 1」を完全自動で復元することは保証できない。

その場合はPriority Ruleの設計を調整する。

---

## 13. VS Codeの自動割り当て

VS Codeはウィンドウタイトルにプロジェクト名・フォルダ名が含まれることが多いため、ChromeよりタイトルベースのPriority Ruleを利用しやすい。

例:

```text
Slot 4
  AllowedProcess = Code.exe
  Priority 1 = Title contains "ImagePromptComposer"

Slot 5
  AllowedProcess = Code.exe
  Priority 1 = Title contains "DanbooruArtistCollector"

Slot 6
  AllowedProcess = Code.exe
  Priority 1 = Title contains "RunLog"
```

ただし、プロジェクト名による固定割り当てを最終仕様とするかは未確定。

---

## 14. Lazy Auto Bind

登録済みHWNDが無効になった場合、単に失敗するのではなく、そのSlotだけAuto Bindを再実行できる設計とする。

例:

```text
Numpad7
  ↓
Slot 7のHWNDが無効
  ↓
Slot 7 Auto Bind
  ↓
Priority RuleによりChrome候補を探索
  ↓
新HWNDを登録
  ↓
Activate
```

これによりChromeやVS Codeを再起動した後でも、ユーザーが再登録操作を意識する必要を減らす。

---

## 15. Auto Bind All

全Auto Bind対象Slotを一括で再評価する機能を持たせる。

初期ショートカット案:

```text
Ctrl + Alt + NumpadEnter
```

想定処理:

1. 全ウィンドウ取得
2. 有効なManual Bindを固定
3. Auto Bind対象Slotを順に評価
4. Slot制約で候補抽出
5. Priority Ruleで候補を決定
6. 重複を避けて割り当て
7. 結果を一時表示

このショートカット自体は未確定。

---

## 16. Slot Clear / Clear All

### 16.1 単一Slot Clear

初期ショートカット案:

```text
Ctrl + Shift + NumpadX
```

対象SlotのRuntime Bindingだけを削除する。

### 16.2 Clear All

全SlotのRuntime Bindingを解除する機能を持たせる。

初期ショートカット案:

```text
Ctrl + Alt + Shift + Numpad0
```

実行後:

```text
HWND = Empty
BindingSource = None
```

とする。

以下は削除しない:

- AllowedProcess
- PriorityRules
- Label
- AutoBind設定

したがって:

```text
Clear All
  ↓
全Slot未登録
  ↓
Auto Bind All
  ↓
Configurationから再構築
```

が可能。

このショートカット自体は未確定。

---

## 17. 個別Auto Bind

各Slotのみを自動再割り当てする操作も持たせる案。

初期ショートカット案:

```text
Ctrl + Alt + NumpadX
```

この操作体系は未確定。

---

## 18. 状態通知

常設GUIは初期版では必須としない。

登録・失敗・解除等はAutoHotkeyの一時的なToolTip等で通知する案。

例:

```text
Chrome Slot 7 registered
```

```text
Slot 7 accepts only Google Chrome
```

```text
Slot 8 is empty
```

Auto Bind Allでは結果一覧を一時表示する案もある。

---

## 19. 設定ファイル

スクリプト本体にSlot設定を書き散らさず、Configurationを外部ファイルへ分離する方針。

初期構成案:

```text
NumpadWindowController/
├─ NumpadWindowController.ahk
├─ WindowSlots.ini
└─ docs/
```

設定例:

```ini
[Slot7]
Key=Numpad7
Label=Chrome 1
AllowedProcess=chrome.exe
AutoBind=true

[Slot8]
Key=Numpad8
Label=Chrome 2
AllowedProcess=chrome.exe
AutoBind=true

[Slot9]
Key=Numpad9
Label=Chrome 3
AllowedProcess=chrome.exe
AutoBind=true

[Slot4]
Key=Numpad4
Label=VSCode 1
AllowedProcess=Code.exe
AutoBind=true
```

Priority Ruleの実際の表現形式は未確定。

---

## 20. 起動時Auto Bind

将来的にはWindowsログイン時等にAutoHotkeyスクリプトを起動し、Auto Bindを行えるようにする。

ただしスクリプト起動時点ではChromeやVS Codeがまだ起動していない可能性がある。

そのため初期案では:

```text
起動時Auto Bind
+
空Slot・無効Slot使用時のLazy Auto Bind
```

を併用する。

常時ポーリングは必須としない。

---

## 21. 外付けテンキー固有の制約

一般的なUSBテンキーは、AutoHotkeyから通常キーボードのテンキーと区別できない場合がある。

例えば:

```text
外付けテンキー Numpad7
```

と

```text
メインキーボード Numpad7
```

が同じ入力として扱われる可能性がある。

初期版ではテンキー入力をウィンドウ操作へ使う前提とする。

将来的に外付けテンキーだけを識別する必要が生じた場合は、AutoHotInterception等の追加手段を検討する。ただし専用ドライバ等の依存が増えるため、初期採用はしない。

---

## 22. 現時点の操作案

| 操作 | 動作 | 状態 |
|---|---|---|
| `NumpadX` | Slot XをActivate | 方針採用 |
| `Ctrl + NumpadX` | 現Windowを手動Bind | 方針採用 |
| `Ctrl + Alt + NumpadX` | Slot XをAuto Bind | 暫定案 |
| `Ctrl + Shift + NumpadX` | Slot XをClear | 暫定案 |
| `Ctrl + Alt + NumpadEnter` | Auto Bind All | 暫定案 |
| `Ctrl + Alt + Shift + Numpad0` | Clear All | 暫定案 |

ショートカット体系は今後の設計議論で変更可能。

---

## 23. 現時点で比較的強く決まっている事項

- テンキー全体を汎用Window Slotとして設計する
- 同一アプリの複数ウィンドウを個別Slotへ割り当て可能にする
- `Ctrl + Numpadキー` による手動登録を基本操作とする
- `7 / 8 / 9` はChrome以外を拒否する
- `4 / 5 / 6` はVS Code以外を拒否する
- 手動登録でもSlot制約を必ず検証する
- HWNDはRuntime Bindingとして使う
- HWND自体は永続化しない
- ConfigurationとRuntime Stateを分離する
- 自動Binding機能を持たせる
- Priority RuleによってAuto Bind候補を選べるようにする
- 全Bindingを空にする機能を持たせる

---

## 24. 未確定・再検討予定

ユーザーから「変更してほしい設計がある」と明示されているため、この資料を最終仕様とは扱わない。

特に以下は次回以降の論点候補:

1. 各テンキーキーの最終役割
2. `Ctrl / Alt / Shift` を使った操作体系
3. Manual BindをAuto Bindより必ず優先するか
4. 重複Bindingを全面禁止するか
5. Auto BindのSlot評価順序
6. Priority Ruleの具体的な評価方式
7. Chrome 3ウィンドウを安定して自動識別する方法
8. VS Codeをプロジェクト名で固定するか、汎用的な手動・自動Slotとして扱うか
9. Clear All時の挙動
10. 設定ファイル形式
11. GUIを作るか、設定ファイル＋Hotkeyだけにするか
12. NumLock OFF時の扱い
13. 外付けテンキーと通常キーボードのテンキーを区別する必要があるか

---

## 25. 実装前提

この段階では実装を開始しない。

未確定項目を設計議論で整理した後に、以下の順で進める想定:

```text
Slotモデル確定
  ↓
Hotkey体系確定
  ↓
Window条件モデル確定
  ↓
Priority Rule確定
  ↓
Auto Bindアルゴリズム確定
  ↓
設定形式確定
  ↓
AutoHotkey v2実装
  ↓
実機テンキーで検証
```
