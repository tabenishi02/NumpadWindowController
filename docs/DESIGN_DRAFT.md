# Numpad Window Controller - 暫定設計

更新日: 2026-09-23  
状態: Draft / 設計継続中

## 1. 目的

一般的なUSBテンキーを、Windows上のウィンドウを直接呼び出すための専用コントローラーとして利用する。

同じアプリを複数ウィンドウで使用する場合でも、特定のウィンドウとテンキーの物理キーを1対1で対応させる。また、ウィンドウ切り替えだけでなく、設定ファイルからショートカット実行や特別機能をキーへ割り当てられる構造とする。

---

## 2. 対象環境

- OS: Windows 11
- 実装候補: AutoHotkey v2
- 入力デバイス: 現在使用しているUSBテンキー
- 実行中ウィンドウの識別: HWND
- 永続設定とRuntime Stateを分離する

専用マクロデバイスや専用ドライバは初期版では必須としない。

---

## 3. キー動作モデル

追加仕様により、テンキーの各物理キーをすべて単純な Window Slot とみなす方式は採用しない。

各キーは設定上、次のいずれかの動作種別を持つ。

| Mode | 意味 |
|---|---|
| Window | ウィンドウをBindingし、通常押下でActivateする |
| Shortcut | プログラム起動やバッチファイル呼び出しを行う |
| Function | Numpad Window Controller固有の特別機能を実行する |
| Disabled | 使用しない |

### 3.1 排他性

1つの物理キーは同時に複数Modeを持たない。

特に `Shortcut` が設定されたキーは Window Binding対象から除外する。

```text
Shortcut設定あり
  ↓
Window Binding対象外
  ↓
通常押下でShortcutを実行
```

Shortcutキーを再びWindowキーとして使う場合は、設定ファイルを編集してModeまたはShortcut設定を変更し、スクリプトを再起動する。

---

## 4. 実機テンキー配置

現在使用しているテンキーの物理配置と既定用途は次の通り。

| キー | 割り当て | キー | 割り当て | キー | 割り当て | キー | 割り当て |
|---|---|---|---|---|---|---|---|
| NumLock | 機能キー | `/` | 任意 | `*` | 任意 | `-` | 任意 |
| `7` | Chrome1 | `8` | Chrome2 | `9` | Chrome3 | `+` | 任意 |
| `4` | VSCode1 | `5` | VSCode2 | `6` | VSCode3 | DEL | 任意 |
| `1` | エクスプローラー | `2` | ChatGPTデスクトップ | `3` | pwsh | Enter | 任意 |
| `0` | 任意 | `000` | 使用不可 | `.` | 任意 | Enter | 任意 |

注記:

- Enterキーは物理的に縦2行分の大きさで、`1 / 2 / 3` の行と `0 / 000 / .` の行にまたがる。
- NumLockキーには特別な機能を持たせる予定。
- `000` キーはNumpad0を3回送信するだけなので、独立キーとして識別できず、本システムでは使用不可とする。
- 物理DELキーはAutoHotkey上では `Backspace` として検出される。

---

## 5. 実機で確認したAutoHotkeyキー情報

Key Historyで確認した値を実機情報として記録する。

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

### 5.1 000キー

`000` キーは独自のVK/SCを持たず、`Numpad0` のDown/Upを3回発生させる。

したがって、通常の `0` キーと確実に区別できる独立キーとしては扱わない。

### 5.2 通常キーボード側の四則計算キー参考値

実機調査時の参考情報として記録する。

| VK | SC | Key |
|---:|---:|---|
| BB | 027 | `;` |
| BD | 00C | `-` |
| BA | 028 | `:` |
| BF | 035 | `/` |

これらはテンキー側の `NumpadDiv / NumpadSub` 等とは別キーとして扱える。

---

## 6. Window Mode

Window ModeのキーにはWindow Slotを持たせる。

各Window Slotは以下を持つ。

- Key
- Label
- Allowed条件
- AutoBind設定
- Auto Bind優先条件
- 現在BindingされているHWND
- BindingSource
  - Manual
  - Auto
  - None

例:

```text
Key: Numpad7
Mode: Window
Label: Chrome 1
AllowedProcess: chrome.exe
AutoBind: true
HWND: ...
BindingSource: Auto / Manual / None
```

---

## 7. 既定Window割り当て制約

### 7.1 Chrome

`Numpad7 / Numpad8 / Numpad9` はChrome専用とする。

```text
AllowedProcess = chrome.exe
```

Chrome以外を手動Bindingしようとした場合は拒否する。

### 7.2 VS Code

`Numpad4 / Numpad5 / Numpad6` はVS Code専用とする。

```text
AllowedProcess = Code.exe
```

VS Code以外を手動Bindingしようとした場合は拒否する。

### 7.3 Numpad1

既定用途はWindows エクスプローラー。

実装時には対象ウィンドウの実際のProcess/Classを確認してAllowed条件を確定する。

### 7.4 Numpad2

既定用途はChatGPTデスクトップアプリ。

実装時に実際のProcess/Classを確認してAllowed条件を確定する。現時点ではプロセス名を推測して固定しない。

### 7.5 Numpad3

既定用途はPowerShell 7 (`pwsh`)。

実装時にTerminal Hostとの関係も含めて、Window判別条件を確定する。

### 7.6 任意キー

`NumpadDiv / NumpadMult / NumpadSub / NumpadAdd / Backspace / Numpad0 / NumpadDot / NumpadEnter` は、特別機能やShortcutが設定されていない場合、任意Window用として利用可能とする。

---

## 8. 手動Binding

Window Modeのキーでは、基本操作を以下とする。

### 8.1 通常押下

```text
NumpadX
```

対象SlotにBindingされているWindowを前面へ移動する。

処理:

```text
キー押下
  ↓
Modeを確認
  ↓
Window ModeならHWND取得
  ↓
HWNDが有効か確認
  ↓
Allowed条件を再確認
  ↓
最小化されていれば復元
  ↓
Activate
```

### 8.2 手動登録

```text
Ctrl + NumpadX
```

現在アクティブなWindowを対象Slotへ登録する。

- 対象キーがWindow Modeであること
- Allowed条件に適合すること

を必ず検証する。

Shortcut / Function / Disabledキーに対するWindow Bindingは拒否する。

### 8.3 BindingSource

```text
Manual
Auto
None
```

をRuntime Stateとして保持する。

---

## 9. HWNDとRuntime State

一度BindingされたWindowはHWNDで追跡する。

利点:

- Chromeのタブタイトルが変わっても同じWindowを維持できる
- VS Codeのタイトル変化の影響を受けにくい

ただしHWNDは再起動等で変化するため永続化しない。

### 永続Configuration

例:

```text
Key = Numpad7
Mode = Window
AllowedProcess = chrome.exe
AutoBind = true
Priority = ...
```

### Runtime State

例:

```text
HWND = 123456
BindingSource = Auto
```

---

## 10. 重複Binding

原則として、同一Windowを複数のWindow Slotへ同時Bindingしない。

手動Bindingで既存SlotのWindowを別Slotへ移した場合は、旧Slotを空にする案を維持する。

Auto Bindでは、一度確定したWindowを後続Slotの候補から除外する。

この細部は今後再検討可能。

---

## 11. Auto Bindの全体優先順位

Auto Bindではアプリ種別ごとに優先度を持たせる。

現時点の優先順位:

1. Chromeの優先3Window → `7 / 8 / 9`
2. VS Codeの優先3Window → `4 / 5 / 6`
3. その他のWindow候補
4. 4つ目以降のChrome / VS Codeは「その他」と同列

したがって、ChromeやVS Codeが4Window以上存在しても、4つ目以降に専用優先Slotは与えない。

---

## 12. Chrome Auto Bind

Chromeは他アプリより先にAuto Bindする。

ただし、専用優先対象は3Windowまでで、対象キーは `7 / 8 / 9` のみ。

Chrome各Windowは基本的に重ならない運用を前提とし、画面上の座標と占有領域で割り当てる。

### 12.1 Numpad7 / Chrome1

優先対象:

- 画面左側
- 左から右へ約30%
- 上から下へ約50%
- 左上の小Window

概念:

```text
┌───────────────┬──────────────────────────────┐
│ Chrome1       │                              │
│ 約30% x 50%   │                              │
├───────────────┤                              │
│               │                              │
└───────────────┴──────────────────────────────┘
```

### 12.2 Numpad8 / Chrome2

優先対象:

- 画面左側
- 左から右へ約30%
- 下から上へ約50%
- 左下の小Window

### 12.3 Numpad9 / Chrome3

優先対象:

- 画面右側
- 右から左へ約70%
- 上から下へ100%
- 右側の大Window

### 12.4 座標判定

厳密なピクセル一致ではなく、許容幅を持つ位置・サイズ判定とする。

具体的なToleranceは実装前に確定する。

### 12.5 Chromeが4Window以上ある場合

4つ目以降のChromeはChrome専用優先割り当てから外し、その他アプリと同列の一般候補として扱う。

---

## 13. VS Code Auto Bind

VS CodeはChromeの次に優先してAuto Bindする。

専用優先対象は3Windowまでで、対象キーは `4 / 5 / 6` のみ。

VS CodeはWindow同士が重なる運用を前提とし、座標ではなく「開いた順番」を優先順位として利用する。

```text
最初に開いたVS Code  -> Numpad4
次に開いたVS Code    -> Numpad5
3番目に開いたVS Code -> Numpad6
```

### 13.1 「開いた順番」の取得

Windows/AutoHotkeyから安定して取得可能な情報で、起動・生成順をどのように再現するかは実装前に検証する。

取得方法が複数ある場合でも、設計上の要求は「ユーザーが開いた順番を4→5→6へ反映すること」とする。

### 13.2 VS Codeが4Window以上ある場合

4つ目以降のVS CodeはVS Code専用優先割り当てから外し、その他アプリと同列の一般候補として扱う。

---

## 14. その他WindowのAuto Bind

Chrome優先3WindowとVS Code優先3Windowを確定した後、残りのWindow Modeキーに対して一般候補を割り当てる。

一般候補には以下も含まれる。

- Explorer
- ChatGPTデスクトップ
- pwsh
- その他アプリ
- 4つ目以降のChrome
- 4つ目以降のVS Code

Numpad1/2/3の既定固定用途との優先関係、および一般候補の並び順は今後詳細化する。

---

## 15. Lazy Auto Bind

Window Modeのキーを押した際、登録HWNDが無効なら、そのSlotだけAuto Bindを再評価できる構造とする。

```text
キー押下
  ↓
HWND無効
  ↓
対象SlotをAuto Bind
  ↓
新しいHWNDを取得
  ↓
Activate
```

---

## 16. Auto Bind All

全Window ModeキーのAuto Bindを一括再評価する機能を持たせる。

基本処理:

1. 実行中Windowを列挙
2. Shortcut / Function / Disabledキーを除外
3. 有効なManual Bindの扱いを確認
4. Chrome優先3Windowを7/8/9へ割り当て
5. VS Code優先3Windowを4/5/6へ割り当て
6. 残りのWindow候補を処理
7. 重複を避けて確定
8. 結果を通知

Auto Bind Allの最終Hotkeyは未確定。

---

## 17. Clear

### 17.1 Slot Clear

単一Window SlotのRuntime Bindingを解除する機能を持つ。

Shortcut / Function / DisabledキーにはWindow Bindingがないため対象外。

### 17.2 Clear All

すべてのWindow SlotのRuntime Bindingを解除する。

削除対象:

```text
HWND
BindingSource
```

削除しないもの:

- Mode
- Allowed条件
- Priority設定
- Shortcut設定
- Function設定
- Label
- AutoBind設定

したがって、Clear All後にAuto Bind Allを実行してConfigurationから再構築できる。

最終Hotkeyは未確定。

---

## 18. Shortcut Mode

各キーには設定ファイルからShortcutを割り当てられる。

用途:

- アプリケーションやウィンドウを起動する
- バッチファイルを実行する
- その他、設定された実行対象を呼び出す

### 18.1 Window Bindingとの排他

Shortcutが設定されたキーはWindowを開くキーの対象から除外する。

つまり:

```text
Mode = Shortcut
  ↓
Manual Bind不可
Auto Bind対象外
Window Activate対象外
  ↓
通常押下でShortcut実行
```

### 18.2 設定変更

ShortcutキーをWindowキーへ変更する場合:

1. 設定ファイルの該当キーを編集
2. Shortcut設定を削除またはModeをWindowへ変更
3. スクリプトを再起動

初期版では設定変更のHot Reloadを必須としない。

### 18.3 設定例

具体的な設定形式は未確定だが、概念例:

```ini
[Key-NumpadDiv]
Mode=Shortcut
Target=C:\path\to\example.bat
```

または:

```ini
[Key-NumpadDiv]
Mode=Shortcut
Target=C:\Program Files\Example\Example.exe
```

引数・Working Directory等を持たせるかは今後検討する。

---

## 19. Function Mode

NumLockにはNumpad Window Controller固有の特別機能を持たせる予定。

Numpad0は通常の任意キーとして扱い、WindowまたはShortcutの割り当て対象にできる。

NumLockの具体的な機能内容は未決定であるため、設定・実装では予約領域として扱う。

`000` はFunction Modeにも利用しない。

---

## 20. 状態通知

常設GUIは初期版では必須としない。

以下の操作結果をToolTip等で通知する案を維持する。

- Manual Bind成功
- Allowed条件違反
- Slot未登録
- Auto Bind結果
- Clear結果
- Shortcut実行失敗

---

## 21. 設定ファイル

スクリプト本体とキー設定を分離する。

構成案:

```text
NumpadWindowController/
├─ NumpadWindowController.ahk
├─ KeyBindings.ini
└─ docs/
```

従来案の `WindowSlots.ini` より、Shortcut / Function / Disabledも含められる `KeyBindings.ini` の方が現在の設計には適する。

概念例:

```ini
[Key-Numpad7]
Mode=Window
Label=Chrome 1
AllowedProcess=chrome.exe
AutoBind=true
AutoBindGroup=Chrome
AutoBindOrder=1

[Key-Numpad4]
Mode=Window
Label=VSCode 1
AllowedProcess=Code.exe
AutoBind=true
AutoBindGroup=VSCode
AutoBindOrder=1

[Key-Numpad1]
Mode=Window
Label=Explorer
AutoBind=true

[Key-NumpadDiv]
Mode=Shortcut
Target=C:\path\to\example.bat

[Key-NumLock]
Mode=Function
Function=TODO

[Key-000]
Mode=Disabled
```

実際のフィールド名・ファイル形式は未確定。

---

## 22. 外付けテンキー固有の制約

一般的なUSBテンキーは、AutoHotkeyから通常キーボードのテンキーと区別できない場合がある。

初期版ではこの制約を受け入れる。

必要になった場合のみAutoHotInterception等を検討する。

---

## 23. 現時点で比較的強く決まっている事項

- AutoHotkey v2を使用する
- 実機テンキーのKey Name / VK / SCは本書の測定値を基準とする
- キーは `Window / Shortcut / Function / Disabled` のModeを持つ
- ShortcutキーはWindow Binding対象外
- `000` はDisabled
- `7 / 8 / 9` はChrome専用
- Chrome優先3Windowは座標で7/8/9へ割り当てる
- ChromeはAuto Bindで最優先
- 4つ目以降のChromeは一般候補へ回す
- `4 / 5 / 6` はVS Code専用
- VS Code優先3Windowは開いた順に4/5/6へ割り当てる
- VS CodeはChromeの次にAuto Bindする
- 4つ目以降のVS Codeは一般候補へ回す
- `1 / 2 / 3` の既定用途はExplorer / ChatGPTデスクトップ / pwsh
- HWNDはRuntime Bindingとして利用し、永続化しない
- ConfigurationとRuntime Stateを分離する
- 全Window BindingをClearする機能を持つ

---

## 24. 未確定・再検討予定

1. NumLockの特別機能
2. Manual BindとAuto Bindの最終優先関係
3. 同一Windowの重複Binding時の細部
4. Chrome座標判定のTolerance
5. マルチモニター時のChrome座標基準
6. VS Codeの「開いた順番」を取得・保持する具体的方法
7. Numpad1/2/3のAuto Bindをどこまで固定するか
8. 4つ目以降のChrome/VS Codeを含む一般候補の優先順位
9. Auto Bind All / Clear / Slot Clear等のHotkey
10. Shortcutの引数・Working Directory・表示方法
11. 設定ファイルの最終形式
12. GUIの必要性
13. NumLock状態そのものをどう扱うか
14. 外付けテンキーと通常キーボードを区別する必要性

---

## 25. 実装前の進行順

```text
実機キー情報確認             完了
  ↓
キーModeモデル整理           今回反映
  ↓
既定キー配置                 今回反映
  ↓
Chrome Auto Bind方針         今回反映
  ↓
VS Code Auto Bind方針        今回反映
  ↓
Shortcut Mode方針            今回反映
  ↓
未確定の特別機能を検討
  ↓
Manual / Auto優先関係確定
  ↓
一般Window Auto Bind確定
  ↓
Hotkey体系確定
  ↓
設定形式確定
  ↓
AutoHotkey v2実装
  ↓
実機検証
```
