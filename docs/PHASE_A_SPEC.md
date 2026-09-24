# Numpad Window Controller - Phase A Specification

更新日: 2026-09-23  
対象: MVP / v0.1  
状態: Adopted for Review  
目的: `TASKS.md` の「Phase A - 残仕様の確定」を完了し、実装前の操作・Binding仕様を固定する。

> 本書の内容はPhase Aに関して `docs/MVP_DESIGN.md` より具体的な仕様として扱う。
> ユーザーレビューで変更指摘があった場合は、その指摘を優先して改訂する。

---

## 1. Phase Aで確定する事項

Phase Aでは以下を確定する。

- A-1. NumLock機能
- A-2. Manual BindとAuto Bindの優先関係
- A-3. 重複Bindingルール
- A-4. Numpad1 / 2 / 3の制約
- A-5. 任意キーの初期定義
- A-6. Auto Bind / Clearを含む操作体系

---

# 2. A-1 NumLock機能

## 2.1 決定

MVPでは物理 `NumLock` を Numpad Window Controller のGlobal Function Keyとして予約する。

通常押下:

~~~text
NumLock
→ Auto Bind All
~~~

修飾操作:

~~~text
Ctrl + NumLock
→ Clear All
~~~

NumLock本来のON/OFFトグルは、スクリプト実行中は行わせない。

## 2.2 NumLock状態

スクリプト起動時に:

1. 現在のNumLock状態を保存する。
2. NumLockをONにする。
3. スクリプト実行中はONを維持する。
4. 正常終了時は起動前のNumLock状態へ戻す。

目的:

- `Numpad0` ～ `Numpad9` 等の認識を安定させる。
- MVPの入力処理を単純化する。
- NumLockをGlobal Function Keyとして利用する。

## 2.3 異常終了時

プロセス強制終了等ではNumLock状態を復元できない場合がある。

これはMVPのKnown Limitationとする。

次回起動時には再びNumLockをONへ設定する。

## 2.4 NumLockをINI設定対象にしない

NumLockは予約Global Keyとし、`KeyBindings.ini` から用途変更不可とする。

理由:

- Auto Bind All / Clear Allへの入口を常に確保する。
- 設定ミスで復旧操作自体を失うことを防ぐ。

---

# 3. A-2 Manual BindとAuto Bindの優先関係

## 3.1 基本原則

~~~text
Manual > Auto > None
~~~

Manual Bindは、ユーザーが明示的に選択した結果であるため、Auto Bindより常に優先する。

## 3.2 Auto Bind All

Auto Bind All実行時:

- 有効なManual Bindは保持する。
- Manual BindされたSlotはAuto Bind対象から除外する。
- Manual BindされたHWNDも他SlotのAuto Bind候補から除外する。
- Auto BindがManual Bindを上書きする例外はMVPでは設けない。

## 3.3 Lazy Auto Bind

Manual BindのHWNDが存在する限りLazy Auto Bindは実行しない。

Manual Bind先Windowが閉じるなどしてHWNDが無効になった場合:

~~~text
Manual
  ↓ HWND無効
None
  ↓ AutoBind=ONなら、次回Slot使用時
Auto
~~~

AutoBind=OFFなら `None` のままとする。

## 3.4 Slot Clear

`Ctrl + Shift + Key` でManual / Autoを問わず対象Slotを `None` にする。

AutoBind=ONのSlotでもClear直後にはAuto Bindしない。

次のいずれかまで空のままにする。

- そのSlotの通常押下によるLazy Auto Bind
- `Ctrl + Alt + Key` による個別Auto Bind
- NumLockによるAuto Bind All

これにより「Clearした瞬間に元へ戻る」挙動を避ける。

## 3.5 Manual Bindの状態遷移

~~~text
None
  └─ Ctrl+Key ───────────→ Manual

Auto
  └─ Ctrl+Key ───────────→ Manual

Manual
  ├─ Ctrl+Key ───────────→ Manual（新しいHWNDへ差し替え）
  ├─ Slot Clear ─────────→ None
  └─ HWND無効 ──────────→ None
                             └─ AutoBind=ONなら後でAutoへ復帰可能
~~~

---

# 4. A-3 重複Bindingルール

## 4.1 基本原則

MVPでは:

~~~text
1 HWND : 1 Window Slot
~~~

を厳守する。

例外は設けない。

## 4.2 Manual Bind時の重複

新しいSlotへManual BindしようとしたHWNDが、すでに別SlotへBindingされている場合:

1. 旧SlotからそのHWNDを解除する。
2. 旧Slotを `None` にする。
3. 新Slotへ `Manual` としてBindingする。

例:

~~~text
Numpad7 = Chrome A (Auto)
Ctrl + Numpad0 while Chrome A active
        ↓
Numpad7 = None
Numpad0 = Chrome A (Manual)
~~~

旧SlotがAutoBind=ONでも、その場では自動補充しない。

必要なら次のAuto Bind / Lazy Auto Bindで再構築する。

## 4.3 Auto Bind時の重複

Auto Bind処理では、すでにBinding済みのHWND集合を `Used HWND Set` として管理する。

候補選択時にUsed HWNDを除外する。

Auto Bind中に同じHWNDを2Slotへ割り当てることは禁止する。

## 4.4 Manual Bind先が固定Slot条件に違反する場合

重複解除より前にAllowed条件を検証する。

Allowed違反なら:

- 新SlotへのBindingを拒否。
- 既存Bindingは一切変更しない。

失敗操作によって既存状態を壊さない。

---

# 5. A-4 Numpad1 / 2 / 3 の制約

## 5.1 決定

MVPでは `1 / 2 / 3` を専用Slotとする。

| Key | 専用用途 | Manual Bind | Auto Bind |
|---|---|---|---|
| Numpad1 | Explorer | Explorer系Windowのみ | ON |
| Numpad2 | ChatGPT Desktop | ChatGPT Desktopのみ | ON |
| Numpad3 | PowerShell系Terminal | PowerShell系Terminalのみ | ON |

## 5.2 理由

これらはユーザーが物理位置と用途を対応付けて指定した主要Slotである。

MVPでは自由度よりも:

- 毎回同じキーに同じ種類のWindowが存在する
- Auto Bind後の結果が予測できる
- 誤って別アプリを固定Slotへ登録しない

ことを優先する。

## 5.3 Allowed条件

意味上の用途は固定するが、Windows上の具体的なProcess / Class / Title条件は実機差・バージョン差に対応できるよう設定値として保持する。

つまり `Numpad1 = Explorer専用` という役割自体はMVP固定。

一方で:

~~~ini
AllowedProcess=explorer.exe
AllowedClass=...
~~~

等の実装上の識別値はPhase BのPoC結果に基づいて確定する。

## 5.4 Numpad3の意味

Numpad3の意味は `pwsh.exe` プロセスそのものではなく:

~~~text
PowerShell 7を操作しているトップレベルTerminal Window
~~~

とする。

Windows Terminal内のpwshも対象候補に含める。

具体的識別方法はPhase Bで確定する。

---

# 6. A-5 任意キーの初期定義

## 6.1 対象

MVPの任意キーは以下とする。

- `NumpadDiv` (`/`)
- `NumpadMult` (`*`)
- `NumpadSub` (`-`)
- `NumpadAdd` (`+`)
- `Backspace`
- `Numpad0` (`0`)
- `Virtual000` (`000`)
- `NumpadDot` (`.`)
- `NumpadEnter` (Enter)

## 6.2 初期Mode

原則として任意キーは次で開始する。

~~~text
Mode = Window
AutoBind = false
HWND = None
BindingSource = None
~~~

外付けテンキーのBackspaceは通常キーボードのBackspaceと入力上区別できないため、MVP標準Configでは `Backspace` だけ `Mode=Disabled` とする。

それ以外の任意キーは空のManual Window Slotとして扱う。

## 6.3 Shortcutの初期割り当て

MVP標準設定ではShortcutを1つも事前割り当てしない。

理由:

- 実行ファイル・BAT等のPathはユーザー環境固有。
- 誤って不要なプログラムを起動しない。
- まずWindow Controllerとしての基本動作を評価する。

ユーザーがINIを編集したキーだけ `Mode=Shortcut` へ変更する。

## 6.4 未設定状態

サポート対象キーについて、INI Sectionそのものが存在しない「未設定」は許容しない。

各キーは必ず:

- Window
- Shortcut
- Disabled

のいずれかを明示する。

理由:

- 押下時の挙動を決定的にする。
- typoやSection欠落を設定ミスとして検出できる。

## 6.5 Disabled

任意キーを使いたくない場合は:

~~~ini
Mode=Disabled
~~~

とする。

DisabledキーはNumpadWindowControllerとして管理しない。

MVPではDisabled KeyのAction Hotkeyを登録せず、元のWindows入力をそのまま通す。

独立したPassThrough Modeは設けず、「Controller管理外」というDisabledの意味にネイティブ動作を含める。

この定義により、通常キーボードBackspaceを維持したまま外付けテンキー側Backspaceを既定Disabledにできる。

---

# 7. A-6 操作体系

## 7.1 Window / Shortcut共通ディスパッチ

論理キー `Key` に対し、Modifierによって操作を分ける。

### Modifierなし

~~~text
Key
~~~

Window Mode:
- Binding済みWindowをActivate。
- 空でAutoBind=ONならLazy Auto Bind。
- 空でAutoBind=OFFなら空Slot通知。

Shortcut Mode:
- Shortcutを実行。

Disabled:
- 何もしない。

### Ctrl

~~~text
Ctrl + Key
~~~

Window Mode:
- 現在のActive WindowをManual Bind。

Shortcut:
- Controller用のCtrl Hotkeyを登録せず、通常の入力としてActive Appへ渡す。

Disabled:
- Controller Hotkeyを登録せず、通常の入力としてActive Appへ渡す。

### Ctrl + Shift

~~~text
Ctrl + Shift + Key
~~~

Window Mode:
- Slot Clear。

Shortcut / Disabled:
- Controller用のCtrl+Shift Hotkeyを登録せず、通常の入力としてActive Appへ渡す。

### Ctrl + Alt

~~~text
Ctrl + Alt + Key
~~~

Window ModeかつAutoBind=ON:
- 対象Slot / Groupの個別Auto Bindを実行。

Window ModeかつAutoBind=OFF:
- Auto Bind規則が存在しないため何も割り当てず、通知する。

Shortcut / Disabled:
- Controller用のCtrl+Alt Hotkeyを登録せず、通常の入力としてActive Appへ渡す。

## 7.2 Global操作

~~~text
NumLock
→ Auto Bind All

Ctrl + NumLock
→ Clear All
~~~

MVPではこれ以外のNumLock修飾操作を定義しない。

## 7.3 Virtual000

`Virtual000` も通常の論理キーと同じ操作体系を使用する。

例:

~~~text
000
→ Virtual000の通常動作

Ctrl + 000
→ Virtual000へのManual Bind

Ctrl + Shift + 000
→ Virtual000 Slot Clear

Ctrl + Alt + 000
→ Virtual000個別Auto Bind
~~~

ただし標準設定のVirtual000は `AutoBind=OFF` なので、最後の操作は「Auto Bind ruleなし」の通知になる。

## 7.4 Hotkey衝突方針

NumpadWindowControllerが実際に登録したController Hotkeyだけを消費する。

- Window ModeはNormal / Ctrl / Ctrl+Shift / Ctrl+AltをController操作として登録する。
- Shortcut ModeはNormalだけを登録する。
- Disabledは登録しない。
- 未定義Modifier CombinationはActive Appへ通常入力として渡す。

例外として、Numpad0 / Virtual000 Detectorが有効な場合はSC052を判定のためSuppressするため、Detectorが対応していないModifier CombinationをネイティブNumpad0として再送しない。

## 7.5 Auto Bind Allと個別Auto Bindの違い

Auto Bind All:

- 全AutoBind=ON Slot / Groupを再評価。
- 有効Manual Bindを保持。

個別Auto Bind:

- 指定Slotが属するAutoBind Groupだけを再評価。
- 同Group内の有効Manual Bindを保持。
- Groupを持たないSlotは個別Auto Bind不可。

例:

~~~text
Ctrl + Alt + Numpad7
→ Chrome Group再評価

Ctrl + Alt + Numpad4
→ VS Code Group再評価

Ctrl + Alt + Numpad1
→ Explorer Slot再評価
~~~

---

# 8. Phase A確定後の標準キー表

| 物理キー | 論理キー | 標準用途 | Mode | AutoBind |
|---|---|---|---|---|
| NumLock | NumLock | Auto Bind All | Reserved | - |
| / | NumpadDiv | 任意Window | Window | OFF |
| * | NumpadMult | 任意Window | Window | OFF |
| - | NumpadSub | 任意Window | Window | OFF |
| 7 | Numpad7 | Chrome1 | Window | ON |
| 8 | Numpad8 | Chrome2 | Window | ON |
| 9 | Numpad9 | Chrome3 | Window | ON |
| + | NumpadAdd | 任意Window | Window | OFF |
| 4 | Numpad4 | VSCode1 | Window | ON |
| 5 | Numpad5 | VSCode2 | Window | ON |
| 6 | Numpad6 | VSCode3 | Window | ON |
| Backspace | Backspace | 任意Window | Window | OFF |
| 1 | Numpad1 | Explorer専用 | Window | ON |
| 2 | Numpad2 | ChatGPT Desktop専用 | Window | ON |
| 3 | Numpad3 | PowerShell系Terminal専用 | Window | ON |
| 0 | Numpad0 | 任意Window | Window | OFF |
| 000 | Virtual000 | 任意Window | Window | OFF |
| . | NumpadDot | 任意Window | Window | OFF |
| Enter | NumpadEnter | 任意Window | Window | OFF |

---

# 9. Phase A完了時のBinding規則まとめ

~~~text
Manual > Auto > None

1 HWND : 1 Slot

固定Slot:
  7/8/9 = Chrome
  4/5/6 = VS Code
  1 = Explorer
  2 = ChatGPT Desktop
  3 = PowerShell系Terminal

任意Slot:
  / * - + Backspace 0 000 . Enter
  初期状態はWindow / AutoBind OFF

Global:
  NumLock = Auto Bind All
  Ctrl+NumLock = Clear All
~~~

---

# 10. Phase A後に残る技術課題

Phase Aでは「どう動くべきか」を確定した。

次のPhase Bでは「Windows / AutoHotkeyからその判定材料を安定して取得できるか」を検証する。

特に:

- Chrome座標・サイズ取得
- Primary Monitor Work Area判定
- VS Code簡易逆列挙順割り当て
- Explorerの通常Window識別
- ChatGPT DesktopのProcess / Class
- PowerShell系Terminalの識別
- 非表示 / Tool Window除外

をPoCで確認する。

Phase Bの結果によってAllowedProcess / AllowedClass等の具体値は変更できるが、Phase Aで決めた操作体系・優先関係・Slotの意味は原則変更しない。
