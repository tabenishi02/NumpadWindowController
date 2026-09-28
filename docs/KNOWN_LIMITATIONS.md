# Numpad Window Controller - Known Limitations

更新日: 2026-09-28  
対象バージョン: **v0.2.0**  
状態: **Current**

この文書は、Phase A～Hで確認・採用したWindow Controller Coreと、v0.2.0で追加したログオン時自動起動の既知の制限を一か所へ集約する。

「不具合」ではなく、MVPで意図的に受け入れている仕様上の制限も含む。

---

## 1. Chrome Auto BindはPrimary Monitor基準

Chrome 7 / 8 / 9の新規Auto BindはPrimary MonitorのWork Areaを基準に座標分類する。

Secondary Monitor上のChromeは新規Auto Bind候補にしない。

既存Binding済みのChromeを後から移動した場合は、HWNDとAllowed条件が有効ならBindingを維持する。

### 将来拡張候補

- MonitorごとのChrome Group
- Monitor指定Configuration
- Primary以外への座標分類

---

## 2. Minimized / Maximized Chromeは新規座標分類しない

Chromeの新規Auto BindではNormal Windowだけを座標分類する。

Minimized / Maximized状態のChromeは、ゼロからの新規割り当て対象にしない。

ただし、すでにBinding済みのChromeはMinimize / Maximize後もBindingを維持する。

---

## 3. VS Codeの真のOpen順は保証しない

Windows / AutoHotkeyから、起動前から存在する複数VS Code Windowの真の生成順を安定して復元できない。

v0.1.0ではAuto Bind時点の未使用 `Code.exe` 候補を `WinGetList` 逆順で4→5→6へ割り当てる。

必要な並びと異なる場合はManual Bindで補正する。

常時監視によるObservation Sequenceは実装しない。

---

## 4. Chrome / VS Codeの4つ目以降は自動割り当てしない

専用Auto Bind Slotは次に固定する。

- Chrome: 7 / 8 / 9
- VS Code: 4 / 5 / 6

4つ目以降のChrome / VS Codeは任意Slotへ自動転送しない。

必要な場合だけ任意SlotへManual Bindする。

---

## 5. 任意SlotはManual専用

次の任意Slotには一般Window Auto Bindを行わない。

- NumpadDiv
- NumpadMult
- NumpadSub
- NumpadAdd
- Backspace
- Numpad0
- Virtual000
- NumpadDot
- NumpadEnter

Window Modeとして使用する場合はManual Bindする。

ShortcutまたはDisabledへ変更することもできる。

---

## 6. HWNDは永続化しない

Window BindingにはHWNDを使用するが、HWNDはRuntime Stateのみで保持する。

Script再起動、アプリ再起動、Windows再起動をまたいでHWNDを保存・復元しない。

Script起動時にAuto Bindで専用Slotを再構築する。

---

## 7. Config Hot Reloadなし

`KeyBindings.ini` は起動時に1回だけ読み込む。

変更後はNumpadWindowControllerを再起動する必要がある。

File Watcherや自動再読込はv0.1.0では実装しない。

---

## 8. Backspaceは通常Keyboardと区別できない

実機の外付けテンキーBackspaceは通常Keyboard Backspaceと同じ:

```text
VK 08
SC 00E
```

として届く。

そのため標準設定ではBackspaceをDisabledにする。

BackspaceをWindow / Shortcutへ変更すると、通常Keyboard側Backspaceも同じController Actionを発火する。

起動時にWarningを表示するが、デバイス単位での区別はしない。

---

## 9. 外付けテンキーと通常Keyboardをデバイス単位で区別しない

v0.1.0は通常のAutoHotkey Keyboard Hook / InputHookを使用する。

同じVK / SCを送る複数Keyboard Deviceを識別しない。

専用デバイス単位制御が必要になった場合は、AutoHotInterception等の導入を別途検討する。

---

## 10. 物理NumLockをController Actionに使えない

対象実機の外付けテンキーNumLockは、AutoHotkey InputHook / Windows Raw Inputの双方でKeyboard Eventが観測されなかった。

そのためNumLock自体へController Actionを割り当てない。

Global ActionはNumpadEnterのCtrl系Combinationへ移行している。

Windows側NumLock状態は、実行中ON固定・正常終了時復元を行う。

---

## 11. 強制終了時のNumLock復元は保証しない

正常終了時はOnExitで起動前NumLock状態へ復元する。

ただし、Process Kill、OS障害、強制終了などでOnExitが実行されない場合は復元を保証しない。

---

## 12. 0 / 000判定には最大約80msの待ち時間がある

物理000キーは独立キーではなくNumpad0のDown/Upを3回高速送信する。

そのためNumpad0とVirtual000を識別するため、通常の0入力も最大約80ms待って確定する。

日常操作上の受入試験はPASSしているが、完全な即時入力ではない。

---

## 13. Numpad0とVirtual000にはConfig上の依存関係がある

`Numpad0=Disabled` の場合、`Virtual000` もDisabledでなければならない。

Virtual000だけControllerで処理しながら、通常Numpad0だけを完全なネイティブ入力として再送する構成はv0.1.0では実装しない。

通常の0入力を完全にController対象外にしたい場合は両方Disabledにする。

---

## 14. Shortcutは既存Window Activateを行わない

Shortcut Modeは押下ごとにTargetをRunする。

既に同じアプリが起動していてもWindow検索・Activateへ切り替えない。

既存Windowへ移動したい場合はWindow Modeを使用する。

---

## 15. Shortcut Target種別は限定

v0.1.0で直接Targetとして許可するのは:

- exe
- bat
- cmd
- lnk

のみ。

`.ps1` の直接Target指定は行わず、`pwsh.exe -File ...` を使用する。

URL、Document Association、任意URI Scheme等はMVP対象外。

---

## 16. Config独自の環境変数展開なし

Shortcut Target / WorkingDirectoryで:

- `%USERPROFILE%`
- `%LOCALAPPDATA%`
- `~`

等をNumpadWindowController独自には展開しない。

絶対Path、A_ScriptDir基準相対Path、またはWindows側で解決できる実行ファイル名を使用する。

---

## 17. 専用Slotのアプリ識別は現在のProcess / Class / Titleに依存

v0.1.0の標準条件:

- Chrome: `chrome.exe`
- VS Code: `Code.exe`
- Explorer: `explorer.exe + CabinetWClass`
- ChatGPT Desktop: `ChatGPT.exe`
- PowerShell 7: `WindowsTerminal.exe + CASCADIA_HOSTING_WINDOW_CLASS + Title contains PowerShell 7`

対象アプリ側のProcess名、Window Class、Title仕様が将来変更された場合はConfigまたは実装調整が必要になる可能性がある。

---

## 18. 一般Windowの優先順位エンジンなし

任意Windowを自動分類する汎用Rule Engineは実装しない。

MVPは専用Groupだけを自動化し、それ以外はManual Bindに限定することで挙動を単純化している。

---

## 19. Background Retryなし

Lazy Auto Bindまたは明示Auto Bindで候補が見つからなかった場合、その時点ではNoneを維持する。

常時監視や一定間隔での自動Retryは行わない。

次回キー押下または明示Auto Bindで再評価する。

---

## 20. 常設GUIなし

v0.2.0には次を用意しない。

- 設定GUI
- Binding一覧GUI
- 常設Status Window
- Tray Menu拡張によるConfig編集

通常の状態通知はToolTip / Error表示を使用する。

---

## 21. Debug Logは通常OFF

通常利用では永続ログを作らない。

問題解析時にコード内Debug設定を有効化した場合だけログを生成する。

そのため通常運用後に過去の詳細操作履歴を遡ることはできない。

---

## 22. 自動起動Taskは通常権限

v0.2.0のTask Scheduler登録はLeastPrivilege / InteractiveTokenを使用する。

そのためWindowsの権限分離により、管理者権限で起動したApplicationへHotkey送信やWindow操作が届かない場合がある。

通常運用では対象Applicationも通常権限で起動する。

---

## 23. 自動起動Taskは絶対Pathを保持

Task Scheduler Actionには登録時点のAutoHotkey v2 executable、`NumpadWindowController.ahk`、Repository RootのPathを保存する。

Repository DirectoryまたはAutoHotkey v2の配置場所を変更した場合、既存Taskは自動追従しない。

次を再実行してTaskを更新する。

```powershell
.\scripts\install-startup-task.ps1
```

---

## 24. 自動起動は現在ユーザー単位

既定のStartup Taskは、install Scriptを実行した現在ユーザーのLogon Triggerだけを登録する。

全ユーザー共通Startup、Service化、Session 0実行はv0.2.0の対象外。

---

## 25. 現行版の受入状態

これらの制限を含む現在仕様で:

- Phase G: 65 / 65 PASS
- Phase H: 16 / 16 PASS
- Startup Preview: 24 assertions PASS
- Task Scheduler Integration: 37 assertions PASS
- Startup追加後 Phase F Regression: 134 assertions PASS
- 実ログオン / 自動起動後操作 / 手動再起動 / Task無効化・解除: PASS

を完了している。

現行v0.2.0で未解決のFAIL / BLOCKEDは記録されていない。
