# ConfigVersion 2 Migration Guide

更新日: 2026-09-29  
対象: v0.2.x以前のConfigVersion 1から、Phase J / 次期v0.3.0系のConfigVersion 2へ移行する利用者

## 概要

ConfigVersion 2では、NumpadWindowControllerの公開Defaultから特定アプリ専用割り当てを削除した。

ConfigVersion 1は廃止しない。既存のConfigVersion 1はLegacy Developer Workflowとして引き続き読み込める。

## ConfigVersion 1で固定されていた用途

- 7 / 8 / 9 = Chrome
- 4 / 5 / 6 = VS Code
- 1 = Explorer
- 2 = ChatGPT Desktop
- 3 = PowerShell 7用Windows Terminal

この構成を継続したい場合は、次のPresetを使用する。

```text
examples/KeyBindings.developer-workflow.ini
```

Repository Rootで:

```powershell
Copy-Item .\examples\KeyBindings.developer-workflow.ini .\KeyBindings.ini -Force
```

## ConfigVersion 2のPublic Default

新しい配布Default:

```text
KeyBindings.default.ini
```

初回起動時に `KeyBindings.ini` が存在しなければ、本体がこのDefaultをローカル `KeyBindings.ini` としてコピーする。

`KeyBindings.ini` はGit管理対象外であり、更新時に配布側から上書きしない。

Public Defaultでは:

- 1～9を含む通常Slotは特定アプリに固定しない
- Window SlotはCtrl+Keyで任意WindowをManual Bindできる
- BackspaceはDisabled
- Virtual000はDisabled
- built-in Auto Bindは行わない

## ConfigVersion 2の主な変更

### Dedicated Slot廃止

ConfigVersion 2では、旧1～9も通常Slotと同様に次を選択できる。

- Window
- Shortcut
- Disabled

Window Modeの `AllowedProcess / AllowedClass / AllowedTitleContains` は任意。

### Auto Bind

ConfigVersion 2 Public Defaultにはbuilt-in Auto Bind Groupを設定しない。

旧Chrome / VS Code / Explorer / ChatGPT / PowerShell Auto BindはConfigVersion 1の互換Profileとして維持する。

### Virtual000

Public DefaultではVirtual000をDisabledにする。

この状態ではNumpad0を通常Hotkeyとして直接処理するため、000判定用の最大約80ms待機は発生しない。

物理000キーを使用したい場合は `Key-Virtual000` をWindowまたはShortcutへ変更する。この場合Numpad0 / Virtual000はZero Detector経路へ切り替わる。

`Numpad0=Disabled` の場合は引き続き `Virtual000=Disabled` が必要。

### Encoding

ConfigVersion 2の配布TemplateはUTF-8を使用する。

本体は互換性のため次を読み込める。

- UTF-8（BOMあり / なし）
- UTF-16 LE BOM

既存ConfigVersion 1をUTF-16 LE BOMのまま利用してもよい。

## v0.2.xの既存Git cloneを更新する前の注意

v0.2.xでは `KeyBindings.ini` がtracked fileだった。

Phase JではUser ConfigをGit管理対象外へ変更したため、**既存cloneで `git pull` すると、ローカル変更がない旧 `KeyBindings.ini` はGitの更新によって削除される**。

現在の設定を残したい場合は、pull前に必ず別名へバックアップする。

```powershell
Copy-Item .\KeyBindings.ini .\KeyBindings.pre-v0.3.backup.ini
git pull
Copy-Item .\KeyBindings.pre-v0.3.backup.ini .\KeyBindings.ini -Force
```

旧標準Developer Workflowをそのまま使うだけでよい場合は、pull後に次でも復元できる。

```powershell
Copy-Item .\examples\KeyBindings.developer-workflow.ini .\KeyBindings.ini -Force
```

Release ZIPを新規展開する利用者にはこの注意は不要。

## 既存KeyBindings.iniがある場合

本体は既存 `KeyBindings.ini` を自動上書きしない。

したがって、ローカルにConfigVersion 1の `KeyBindings.ini` が残っている場合は、そのままLegacy Workflowとして継続利用できる。

Public Defaultへ切り替える場合:

```powershell
Copy-Item .\KeyBindings.ini .\KeyBindings.backup.ini
Copy-Item .\KeyBindings.default.ini .\KeyBindings.ini -Force
```

その後、必要なSlotだけ再設定する。

## 推奨移行方法

旧Developer Workflowを使い続ける場合はLegacy Presetをコピーする。一般的なテンキー用途へ移行する場合はPublic Defaultから開始し、Ctrl+KeyによるManual BindまたはShortcut設定を必要なSlotへ追加する。
