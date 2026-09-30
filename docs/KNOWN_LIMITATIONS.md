# Numpad Window Controller - Known Limitations

更新日: 2026-09-29  
対象: Phase K / ConfigVersion 3  
状態: **Current**

この文書はPhase K以降の現行Runtime制限を記録する。Phase A～J固有の過去仕様・制限は各Phase文書とRelease Tagを参照する。

---

## 1. ConfigVersion 3のみ対応

Phase K RuntimeはConfigVersion 3のみを読み込む。

- ConfigVersion 1 / 2互換読込なし
- 自動Migrationなし
- Compatibility Layerなし

v0.3.0以前のUser Configは手動でConfigVersion 3へ移行する必要がある。

---

## 2. Config Hot Reloadなし

`KeyBindings.ini` は起動時に1回読み込む。

設定変更後はNumpadWindowControllerを再起動する必要がある。

---

## 3. HWND Bindingは永続化しない

Window ActionのBindingはRuntime Stateだけに保持する。

Script再起動、Application再起動、Windows再起動をまたいでManual Bindingを保存・復元しない。

AutoBind Strategyを設定したWindow Actionは再探索できるが、`AutoBindStrategy=None` は再度Manual Bindが必要。

---

## 4. Window ActionはHWNDを使用する

WindowをProcess単位ではなくHWND単位で識別する。

対象Windowが破棄・再生成された場合、旧HWND Bindingは無効になる。AutoBind対象なら次回操作時に再探索する。

---

## 5. PrimaryThreePaneはPrimary Monitor基準

`AutoBindStrategy=PrimaryThreePane` はPrimary Monitor Work Areaを基準にする。

Secondary Monitor上のWindowを3-pane位置判定へ自動分類しない。

Minimized / Maximized Windowも新規3-pane分類対象外。

---

## 6. ReverseListは真のWindow生成順を保証しない

`AutoBindStrategy=ReverseList` はAutoBind時点の `WinGetList` 逆順を利用する。

Application Windowの真の生成順・起動順を復元する機能ではない。

---

## 7. Application Launch fallbackは同期WinWaitしない

Launch fallbackは対象Windowが0件の場合だけApplicationを起動する。

起動後に長時間の同期 `WinWait` は行わない。

基本動作:

1. 最初のKey入力でApplicationをLaunch
2. Group単位LaunchPendingで重複Runを抑止
3. Window生成後の次回入力でAutoBind / Activate

Application起動が極端に遅い場合はLaunchPending Timeout後に再試行可能になる。

---

## 8. Group一致Windowが1件以上ある場合は追加Launchしない

Window ActionのBindingがなくても、対応WindowGroupに一致するWindowが1件以上存在する場合、新しいApplication Instance / WindowはLaunchしない。

複数Windowを自動生成するLauncherとしては使用しない。

---

## 9. Virtual00 / Virtual000はEvent列推定

Virtual00 / Virtual000はNumpad0の高速D/U列から論理Keyを推定する。

標準判定窓は約80ms。

物理00キーと人間による極端に高速なNumpad0二連打が同じEvent列を送る場合、Softwareから完全には区別できない。

USB HID上の独立したKeypad 00 / Keypad 000 Usageを直接送る製品はPhase K保証対象外。

---

## 10. Virtual00物理実機受入は未実施

現時点で00キー搭載テンキーを所有していないため:

- Logic Regression: 実施
- 物理00受入: Not Executed / N/A

Virtual000はPhase KのK-PA-8で物理実機Regression PASS済み。

---

## 11. Virtual000有効時はNumpad0確定に最大約80ms必要

`EnableVirtual000=On` の場合、2回目入力時点ではVirtual00なのかVirtual000途中なのか確定できない。

そのためNumpad0 / Virtual00の確定が最大約80ms遅延する。

Virtual00 / Virtual000ともOffの場合はZero Detectorを起動せずNumpad0を直接Hotkey処理する。

---

## 12. BackspaceはKeyboard Device単位で区別しない

対象実機では外付けテンキーBackspaceと通常Keyboard Backspaceが同じKey Eventとして届く。

Public DefaultではBackspaceを未Mappingにし、Native Inputを通す。

BackspaceへController ActionをMappingすると通常Keyboard側BackspaceもController Action対象になるため、起動時Warningを表示する。

---

## 13. Keyboard Device単位識別なし

通常のAutoHotkey Keyboard Hook / InputHookを使用し、同じVK / SCを送る複数Keyboard Deviceを区別しない。

AutoHotInterception等のDriver依存BackendはPhase K対象外。

---

## 14. KeySendは定義済みKey集合のみ

Phase K初期実装ではKeySend Parserが許可するKey名を限定する。

主な対応:

- A-Z / 0-9
- F1-F24
- Tab / Enter / Escape / Space / Backspace / Delete / Insert
- Home / End / PageUp / PageDown / Arrow
- Volume
- Media
- Browser
- PrintScreen
- Ctrl / Shift / Alt / Win Modifier

未知Keyや複数の非Modifier Keyを含むCombinationは起動時Error。

---

## 15. 管理者権限Applicationへの操作制限

Controllerが通常権限で動作している場合、WindowsのUIPI / Integrity Level制限により、管理者権限ApplicationへKeySendやWindow操作が届かない場合がある。

Startup Taskも既定ではLeastPrivilege / InteractiveToken。

---

## 16. Run / Launch Target種別は限定

直接Targetとして許可するのは:

- exe
- bat
- cmd
- lnk

`.ps1` は直接Targetにせず `pwsh.exe -File ...` を使用する。

URL、任意URI Scheme、Document AssociationはPhase K初期対象外。

---

## 17. Config独自の環境変数展開なし

Target / WorkingDirectoryで:

- `%USERPROFILE%`
- `%LOCALAPPDATA%`
- `~`

等を独自展開しない。

絶対Path、Script Directory基準の相対Path、またはWindows SearchPathで解決できる実行ファイル名を使用する。

---

## 18. MultiActionのNested Macroなし

Phase K初期実装ではMultiActionからMultiActionを呼び出せない。

- Step番号は1から連続
- 不存在Action参照は起動時Error
- Nested MultiActionは起動時Error
- 同一MultiAction実行中の再入は抑止

複雑なMacro Graphは将来候補。

---

## 19. DelayはThreadをSleepする

Delay ActionはAutoHotkey `Sleep` を使用する。

Controller全体を `Critical` で固定しないため他Hotkey Threadは動作可能だが、厳密なReal-time Schedulerではない。

---

## 20. Layerは常に1つ

Phase K初期実装では:

- Active Layer = 1つ
- Set / Nextのみ
- Layer Stackなし
- Momentary Layerなし
- One-shot Layerなし
- Tap / HoldによるLayer切替なし

複数Layer Configでは安全に戻れるようGlobal MappingにLayerSwitch Actionを最低1つ要求する。

---

## 21. Tap / Hold / Double Tap / Mouse操作なし

Phase K Scope外:

- Tap / Hold
- Double Tap
- Tap Dance
- Mouse Click
- Wheel
- Cursor移動

Window ToggleはDouble Tapではなく、押下時点で対象WindowがActiveかどうかだけを見る。

---

## 22. 物理NumLockをController Actionとして利用しない

対象実機の物理NumLockはテンキー内部の入力切替として機能し、WindowsへNumLock Keyboard Eventを送らない。

NumLock自体へController Actionを割り当てない。

Controller実行中のWindows側NumLockはON固定し、正常終了時に起動前状態へ戻す。

---

## 23. 強制終了時のNumLock復元は保証しない

Process Kill、OS障害等でOnExitが実行されない場合は起動前NumLock状態への復元を保証しない。

---

## 24. 常設GUIなし

現行版には以下を用意しない。

- Config GUI
- Binding一覧GUI
- Layer常設表示
- Tray MenuからのConfig編集

Layer切替時は短時間ToolTipのみ表示する。

---

## 25. Configuration INIはUTF-8のみ

- UTF-8 BOMなし: 対応
- UTF-8 BOMあり: 対応
- UTF-16 LE / BE: 非対応

過去ReleaseのUTF-16 Configをそのまま読み込まない。

---

## 26. Startup Taskは絶対Pathを保持する

Task Scheduler Actionには登録時点のAutoHotkey executable、Controller Script、Repository Rootを保存する。

配置場所を変更した場合は:

```powershell
.\scripts\install-startup-task.ps1
```

を再実行する。
