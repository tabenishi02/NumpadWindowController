# Numpad Window Controller - Phase D Configuration Specification

更新日: 2026-09-24  
対象: MVP / v0.1.0  
状態: Implemented / Verified  
目的: Phase D「Configuration仕様確定」を完了し、実装時の `KeyBindings.ini` の形式・スキーマ・検証・Shortcut実行仕様を固定する。

> 本書はConfigurationに関して `docs/MVP_DESIGN.md` より具体的な仕様として扱う。
> 本仕様はv0.1.0実装・Phase G機能テスト・Phase H実機受入試験に反映済み。

---

# 1. D-1 設定ファイル形式

## 1.1 INIを正式採用

MVPではJSONではなくINIを採用する。

理由:

- 設定構造が浅く、配列や深いネストを必要としない。
- AutoHotkey v2の標準INI機能を利用できる。
- 人間が手作業で編集しやすい。
- JSON parser等の追加依存を導入しない。
- MVPでは1キーにつき1Sectionで十分表現できる。

ファイル名:

~~~text
KeyBindings.ini
~~~

配置:

~~~text
NumpadWindowController.ahk
KeyBindings.ini
~~~

とし、スクリプトと同じディレクトリに固定する。

MVPではCLI引数等による別Config Path指定は実装しない。

## 1.2 Encoding

`IniRead / IniWrite` を使う標準INIはUTF-8を前提にできないため、MVPの `KeyBindings.ini` は:

~~~text
UTF-16 LE with BOM
~~~

を正規Encodingとする。

これによりLabelやWindows Pathに日本語を使用できる。

起動時にEncodingを確認し、MVPではUTF-16 LE BOMでないConfigをFatal Errorとしてよい。

## 1.3 Config Version

必須Section:

~~~ini
[General]
ConfigVersion=1
~~~

MVPで受け付けるVersionは `1` のみ。

未知のConfigVersionはFatal Errorとする。

将来スキーマを変更する場合にMigration判定へ利用する。

## 1.4 Reload

Configは起動時に1回だけ読み込む。

編集後はスクリプトを再起動する。

MVPでは:

- Hot Reload
- File Watcher
- 自動再読込

を実装しない。

---

# 2. Section設計

## 2.1 Key identity

Key名はFieldとして重複保持せず、Section名そのものをKey IDとする。

例:

~~~ini
[Key-Numpad7]
[Key-Numpad0]
[Key-Virtual000]
~~~

`Key=Numpad7` のようなFieldは持たない。

理由:

- Section名とKey Fieldの不一致を防ぐ。
- 検証項目を減らす。

## 2.2 Canonical Key Sections

MVPで認識するSectionは次だけとする。

~~~text
Key-NumpadDiv
Key-NumpadMult
Key-NumpadSub
Key-Numpad7
Key-Numpad8
Key-Numpad9
Key-NumpadAdd
Key-Numpad4
Key-Numpad5
Key-Numpad6
Key-Backspace
Key-Numpad1
Key-Numpad2
Key-Numpad3
Key-Numpad0
Key-Virtual000
Key-NumpadDot
Key-NumpadEnter
~~~

Enterは物理的に縦2キー分だが、論理Sectionは1つだけ。

実機では通常Keyboard Enter=`SC01C`、テンキーEnter=`SC11C` と区別できる。
`[Key-NumpadEnter]` は通常押下のWindow / Shortcut / Disabled用途を設定する。
ただし `Ctrl + NumpadEnter` と `Ctrl + Shift + NumpadEnter` はModeに関係なくGlobal Actionとして予約する。

NumLockはController入力として利用しないためConfig Sectionを持たない。
`[Key-NumLock]` が存在した場合はFatal Errorとする。

## 2.3 全Section必須

上記18Sectionはすべて1回ずつ存在することを要求する。

Section省略によるDefault補完はMVPでは行わない。

理由:

- 実際に各キーが何ModeなのかConfig単体で確認できる。
- typoや欠落を起動時に検出できる。
- 暗黙Defaultを減らす。

---

# 3. Mode

設定可能Mode:

~~~text
Window
Shortcut
Disabled
~~~

大文字小文字は区別しないが、サンプルでは上記表記を使用する。

NumpadEnterの予約Global Modifier CombinationはModeではなく、Configで変更不可とする。

## 3.1 Window

Window Binding / Activate用。

専用Slot 1～9は必ずWindow Modeとする。

任意SlotはWindowまたはShortcutまたはDisabledを選択可能。

## 3.2 Shortcut

設定Targetを毎回起動する。

Window Binding対象外。

## 3.3 Disabled

NumpadWindowControllerとしてそのキーを管理しない。

MVPではDisabled KeyのAction Hotkeyを登録せず、元のWindows入力をそのまま通す。

「PassThrough」という別Modeは設けず、無効化時のネイティブ動作をDisabledの意味とする。

---

# 4. Backspaceの安全方針

実機の外付けテンキーBackspaceは:

~~~text
VK 08
SC 00E
AHK Backspace
~~~

であり、一般キーボードのBackspaceと区別できない。

そのためMVP標準Configでは:

~~~ini
[Key-Backspace]
Mode=Disabled
Label=Backspace
~~~

とする。

これにより通常キーボードのBackspaceを奪わない。

ユーザーが明示的に `Window` または `Shortcut` へ変更することは許可するが、その場合:

- 外付けテンキーBackspace
- 通常キーボードBackspace

の両方が同じController Actionを発火する。

この制約を起動時Fatalにはしないが、BackspaceがDisabled以外なら起動時にWarningを1回表示する。

将来デバイス単位識別を導入した場合、この制限を解消できる。

---

# 5. D-2 Key設定スキーマ

## 5.1 共通Field

すべてのKey Section:

- `Mode`
- `Label`

を必須とする。

### Mode

必須。

値:

- Window
- Shortcut
- Disabled

### Label

必須、空文字禁止。

通知・診断表示用の人間向け名称。

LabelはBinding判定には使わない。

---

# 6. Window Mode Schema

Window Modeで使用可能なField:

- Mode
- Label
- AllowedProcess
- AllowedClass
- AllowedTitleContains

## 6.1 AllowedProcess

Process Nameの完全一致。

例:

~~~ini
AllowedProcess=chrome.exe
~~~

比較はcase-insensitive。

Path全体ではなくProcess Nameのみ。

Wildcard / Regex / 複数値はMVPでは対応しない。

空欄ならProcess制約なし。

## 6.2 AllowedClass

Window Classの完全一致。

比較はcase-insensitive。

Wildcard / Regexなし。

空欄ならClass制約なし。

## 6.3 AllowedTitleContains

Window Titleの部分一致。

比較はcase-insensitive。

Regex / Wildcardなし。

例:

~~~ini
AllowedTitleContains=PowerShell 7
~~~

空欄ならTitle制約なし。

## 6.4 Allowed条件の組み合わせ

複数Fieldが設定されている場合はAND条件。

例:

~~~ini
AllowedProcess=WindowsTerminal.exe
AllowedClass=CASCADIA_HOSTING_WINDOW_CLASS
AllowedTitleContains=PowerShell 7
~~~

は3条件すべて一致したWindowだけを許可する。

## 6.5 任意Window Slot

任意SlotをWindow Modeにした場合、Allowed条件はすべて空欄でもよい。

その場合Manual Bind対象にProcess / Class / Title制約を設けない。

Allowed条件を設定すれば、任意SlotにもManual Bind制約を付けられる。

---

# 7. Auto Bind属性はConfigから除外

Phase CでAuto Bind対象とGroup構造は固定したため、MVPでは次のFieldをユーザーConfigへ持たせない。

- AutoBind
- AutoBindGroup
- AutoBindOrder

これらはKey IDからコード側で決定するBuilt-in Metadataとする。

固定値:

| Key | AutoBind | Group |
|---|---|---|
| 7 / 8 / 9 | ON | Chrome |
| 4 / 5 / 6 | ON | VSCode |
| 1 | ON | Explorer |
| 2 | ON | ChatGPT |
| 3 | ON | PowerShell |
| 任意Slot | OFF | None |

理由:

- Phase A/Cの不変条件をConfig typoで壊さない。
- 汎用Auto Bind EngineをMVPで作らない。
- Configurationを用途調整に限定する。

---

# 8. 専用Slot Validation

## 8.1 7 / 8 / 9

必須:

~~~text
Mode=Window
AllowedProcess=<non-empty>
~~~

3Slotの `AllowedProcess` は同一でなければならない。

標準値:

~~~ini
AllowedProcess=chrome.exe
~~~

AllowedClass / AllowedTitleContainsは空欄可だが、3Slotで設定する場合は同じ値とする。

## 8.2 4 / 5 / 6

必須:

~~~text
Mode=Window
AllowedProcess=<non-empty>
~~~

3SlotのAllowed条件は同一でなければならない。

標準:

~~~ini
AllowedProcess=Code.exe
~~~

## 8.3 Numpad1

必須標準条件:

~~~ini
Mode=Window
AllowedProcess=explorer.exe
AllowedClass=CabinetWClass
~~~

AllowedTitleContainsは空欄可。

値自体は将来のアプリ変更に備えて編集可能だが、Process / Classを空欄にはできない。

## 8.4 Numpad2

必須:

~~~ini
Mode=Window
AllowedProcess=ChatGPT.exe
~~~

AllowedClass / Titleは空欄可。

## 8.5 Numpad3

必須:

~~~ini
Mode=Window
AllowedProcess=WindowsTerminal.exe
AllowedClass=CASCADIA_HOSTING_WINDOW_CLASS
AllowedTitleContains=PowerShell 7
~~~

3Fieldとも空欄不可。

---

# 9. Numpad0 / Virtual000 Config制約

`Virtual000` は物理Numpad0の高速D-U×3から生成されるため、独立物理入力ではない。

MVPルール:

- Numpad0がWindow / ShortcutならVirtual000はWindow / Shortcut / Disabledのいずれでもよい。
- Numpad0がDisabledの場合、Virtual000もDisabledでなければならない。

つまり:

~~~text
Numpad0 = Disabled
Virtual000 = Window/Shortcut
~~~

は禁止する。

理由:

Virtual000だけをController Actionとして有効化しつつ、通常Numpad0をネイティブ入力として正確に再送する処理をMVPへ追加しないため。

両方Disabledの場合はNumpad0 / Virtual000判定Hook自体を登録しない。

---

# 10. D-3 Shortcut Schema

Shortcut Modeで使用可能なField:

- Mode
- Label
- Target
- Arguments
- WorkingDirectory

## 10.1 Target

必須、空欄不可。

MVPで許可するTarget:

- `.exe`
- `.bat`
- `.cmd`
- `.lnk`

URLや任意Document Association起動はMVP対象外。

## 10.2 Target Path Resolution

Targetは次の順で解決する。

1. 絶対PathならそのPath。
2. 相対Pathなら `A_ScriptDir` 基準。
3. Path区切りを含まない実行ファイル名はWindowsの実行ファイル検索で解決。

例:

~~~ini
Target=pwsh.exe
~~~

はWindows側で解決可能なら許可する。

解決後にファイルが存在しない場合はFatal Error。

MVPでは:

- `%USERPROFILE%`
- `%LOCALAPPDATA%`
- `~`

等の環境変数 / Home省略記法をConfig独自には展開しない。

必要なら絶対Pathを記述する。

## 10.3 Arguments

任意。

値はShortcut実行時にTargetへ渡す引数文字列として扱う。

引用符を含める場合はConfigにそのまま記述する。

MVPではArgumentsを独自tokenizeしない。

例:

~~~ini
Arguments=-File "C:\Scripts\Example.ps1"
~~~

## 10.4 WorkingDirectory

任意。

空欄ならMVPではWorking Directoryを明示指定せず、AutoHotkey / Windowsの通常動作に任せる。

設定する場合:

- 絶対Path
- またはA_ScriptDir基準の相対Path

を許可する。

存在しないDirectoryはFatal Error。

環境変数独自展開は行わない。

## 10.5 PowerShell Script

`.ps1` をTargetとして直接指定する方式はMVPでは禁止する。

次の方式を使用する。

~~~ini
Target=pwsh.exe
Arguments=-File "C:\Scripts\Example.ps1"
~~~

理由:

- 実行Policy / File Association依存を減らす。
- PowerShell 7を明示できる。
- Shortcut起動方式を統一できる。

Arguments内のScript Path存在確認まではMVPのConfig Validatorでは行わない。

## 10.6 既存起動済みアプリ

Shortcut Modeは毎回Targetを実行する。

既存Window検索やActivateはしない。

既存Windowへ移動したい場合はWindow Modeを使用する。

## 10.7 Runtime実行失敗

起動時Validationを通過したTargetでも、実行時に失敗する可能性はある。

例:

- ファイルが起動後に削除された
- 権限不足
- removable / network path切断

この場合:

- Script全体は終了しない。
- ToolTipまたはMsgBoxでShortcut実行失敗を通知する。
- 他Keyは利用継続可能。

---

# 11. Mode別Field制約

## 11.1 Window

許可:

- Mode
- Label
- AllowedProcess
- AllowedClass
- AllowedTitleContains

禁止:

- Target
- Arguments
- WorkingDirectory

## 11.2 Shortcut

許可:

- Mode
- Label
- Target
- Arguments
- WorkingDirectory

禁止:

- AllowedProcess
- AllowedClass
- AllowedTitleContains

## 11.3 Disabled

許可:

- Mode
- Label

その他Fieldは設定しない。

Modeを変更した後に旧Mode用Fieldが残っている場合はFatal Errorとし、stale設定を明示的に削除させる。

---

# 12. INI Syntax規約

## 12.1 コメント

コメントは行頭の `;` を使用する。

MVPサンプルではinline commentを使用しない。

## 12.2 Quotes

通常のValue全体を引用符で囲まない。

Pathに空白があっても:

~~~ini
Target=C:\Program Files\Example\Example.exe
~~~

と記述する。

Arguments内で必要な引用符だけはそのまま保持する。

## 12.3 Boolean

Phase DでAutoBind等をConfigから除外したため、MVP SchemaにはBoolean Fieldを持たない。

## 12.4 Case

Section名 / Field名 / Modeはcase-insensitiveとして読み込んでよい。

ただし標準ConfigではCanonical表記を使用する。

---

# 13. D-4 Configuration Validation

起動時に、Hotkey登録やRuntime State初期化より前に全Validationを完了する。

## 13.1 Structural Validation

Fatal:

- Configファイル不存在
- UTF-16 LE BOMでない
- `[General]` 不在
- ConfigVersion不在 / 不正
- 未知Section
- 必須Key Section不足
- 同一Key Sectionの重複
- 同一Section内のField重複
- 未知Field

Duplicate検出は `IniRead` の結果だけに依存せず、必要ならRaw Fileを先に走査して検出する。

## 13.2 Mode Validation

Fatal:

- Mode不在
- 不正Mode
- Label不在
- Label空
- 専用Slot 1～9がWindow以外
- ModeとFieldの組み合わせ違反

## 13.3 Allowed Validation

Fatal:

- 7/8/9のAllowedProcessが空
- 7/8/9のAllowed条件が相互不一致
- 4/5/6のAllowedProcessが空
- 4/5/6のAllowed条件が相互不一致
- 1のAllowedProcess / AllowedClassが空
- 2のAllowedProcessが空
- 3のAllowedProcess / AllowedClass / AllowedTitleContainsが空

AllowedProcessが現在実行中かどうかは検証しない。

アプリ未起動は正常状態。

## 13.4 Numpad0 / Virtual000 Validation

Fatal:

~~~text
Numpad0 = Disabled
AND
Virtual000 != Disabled
~~~

## 13.5 Shortcut Validation

Fatal:

- Target不在 / 空
- Target解決失敗
- Targetファイル不存在
- 非対応拡張子
- WorkingDirectory指定時にDirectory不存在
- Window用Fieldが混在

## 13.6 Backspace Warning

BackspaceがDisabled以外の場合はFatalではなくWarning。

起動時に1回:

~~~text
Backspace is enabled.
The keypad Backspace and the standard keyboard Backspace cannot be distinguished.
Both will trigger this controller action.
~~~

相当のMsgBoxを表示する。

---

# 14. Error Reporting

Fatal Configuration Errorではスクリプトを常駐開始しない。

MsgBoxに最低限:

- Config path
- Section
- Field
- Value
- Reason

を表示する。

例:

~~~text
Configuration error

File: C:\...\KeyBindings.ini
Section: Key-Numpad3
Field: AllowedTitleContains
Value: <empty>
Reason: Required for the PowerShell slot.
~~~

複数Errorを一括列挙するより、MVPでは最初のFatal Errorで停止してよい。

実装修正を簡単にするため、Error Messageは具体的なFieldまで示す。

---

# 15. 標準Config例

~~~ini
[General]
ConfigVersion=1

[Key-NumpadDiv]
Mode=Window
Label=Slash
AllowedProcess=
AllowedClass=
AllowedTitleContains=

[Key-NumpadMult]
Mode=Window
Label=Asterisk
AllowedProcess=
AllowedClass=
AllowedTitleContains=

[Key-NumpadSub]
Mode=Window
Label=Minus
AllowedProcess=
AllowedClass=
AllowedTitleContains=

[Key-Numpad7]
Mode=Window
Label=Chrome 1
AllowedProcess=chrome.exe
AllowedClass=
AllowedTitleContains=

[Key-Numpad8]
Mode=Window
Label=Chrome 2
AllowedProcess=chrome.exe
AllowedClass=
AllowedTitleContains=

[Key-Numpad9]
Mode=Window
Label=Chrome 3
AllowedProcess=chrome.exe
AllowedClass=
AllowedTitleContains=

[Key-NumpadAdd]
Mode=Window
Label=Plus
AllowedProcess=
AllowedClass=
AllowedTitleContains=

[Key-Numpad4]
Mode=Window
Label=VS Code 1
AllowedProcess=Code.exe
AllowedClass=
AllowedTitleContains=

[Key-Numpad5]
Mode=Window
Label=VS Code 2
AllowedProcess=Code.exe
AllowedClass=
AllowedTitleContains=

[Key-Numpad6]
Mode=Window
Label=VS Code 3
AllowedProcess=Code.exe
AllowedClass=
AllowedTitleContains=

[Key-Backspace]
Mode=Disabled
Label=Backspace

[Key-Numpad1]
Mode=Window
Label=Explorer
AllowedProcess=explorer.exe
AllowedClass=CabinetWClass
AllowedTitleContains=

[Key-Numpad2]
Mode=Window
Label=ChatGPT Desktop
AllowedProcess=ChatGPT.exe
AllowedClass=
AllowedTitleContains=

[Key-Numpad3]
Mode=Window
Label=PowerShell 7
AllowedProcess=WindowsTerminal.exe
AllowedClass=CASCADIA_HOSTING_WINDOW_CLASS
AllowedTitleContains=PowerShell 7

[Key-Numpad0]
Mode=Window
Label=Zero
AllowedProcess=
AllowedClass=
AllowedTitleContains=

[Key-Virtual000]
Mode=Window
Label=Virtual 000
AllowedProcess=
AllowedClass=
AllowedTitleContains=

[Key-NumpadDot]
Mode=Window
Label=Dot
AllowedProcess=
AllowedClass=
AllowedTitleContains=

[Key-NumpadEnter]
Mode=Window
Label=Enter
AllowedProcess=
AllowedClass=
AllowedTitleContains=
~~~

標準ConfigではShortcutを事前設定しない。

Shortcut例:

~~~ini
[Key-Virtual000]
Mode=Shortcut
Label=Run Example Script
Target=pwsh.exe
Arguments=-File "C:\Scripts\Example.ps1"
WorkingDirectory=
~~~

---

# 16. Phase D確定事項まとめ

- Config形式はINI。
- `KeyBindings.ini` をScriptと同じDirectoryに固定。
- ConfigVersion=1必須。
- UTF-16 LE BOMを正規Encodingとする。
- Key identityはSection名。
- 18 Key Sectionをすべて必須とする。
- NumLockはConfig対象外。
- ModeはWindow / Shortcut / Disabled。
- AutoBind / AutoBindGroup / AutoBindOrderはConfigから除外し、コード側固定。
- Window ModeはAllowedProcess / AllowedClass / AllowedTitleContainsを使用可能。
- Allowed条件はcase-insensitive AND一致。
- Shortcut Targetはexe / bat / cmd / lnk。
- ps1直接Targetは禁止し、pwsh.exe + -Fileを使用。
- Shortcutは毎回新規Runし、既存Window Activateはしない。
- Config変更は再起動で反映。
- 起動時に全構造・Mode・Allowed・Shortcutを検証。
- Fatal Error時は常駐開始しない。
- Backspaceは標準Disabled。明示有効化時は通常Keyboard Backspaceも巻き込むWarningを表示。
- Numpad0 Disabled時はVirtual000もDisabled必須。

---

# 17. 次工程への引き継ぎ

Phase Eでは、このConfiguration仕様を読み込むRuntime構造とファイル構成を決定する。

実装側で必要な主な責務:

- UTF-16 INI読込
- Raw構造Validation
- Mode別Schema Validation
- Shortcut Path Resolution
- Built-in Auto Bind Metadata付与
- Configuration Object → Runtime State変換
- Fatal / Warning表示

MVPではConfigurationの書き換え機能は実装しない。
