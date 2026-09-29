# Numpad Window Controller - Known Limitations

更新日: 2026-09-29  
対象: Phase J / 次期v0.3.0候補  
状態: **Current**

この文書はConfigVersion 2 Public Defaultの制限と、ConfigVersion 1 Legacy Developer Workflow固有の制限を分けて記録する。

---

## 1. Config Hot Reloadなし

`KeyBindings.ini` は起動時に1回読み込む。

設定変更後はNumpadWindowControllerを再起動する必要がある。

---

## 2. HWNDは永続化しない

Window BindingはRuntime Stateだけに保持する。

Script再起動、Application再起動、Windows再起動をまたいでManual Bindingを保存・復元しない。

ConfigVersion 2 Public Defaultにはbuilt-in Auto Bindがないため、再起動後は必要なWindowを再度Manual Bindする。

---

## 3. Public Defaultには汎用Auto Bind Rule Engineがない

ConfigVersion 2は特定アプリをCoreへ固定しない代わりに、一般Windowを自動分類するRule Engineも実装しない。

Public DefaultはManual Bindを基本とする。

`Ctrl + NumpadEnter` / `Ctrl + Alt + Key` のAuto Bind操作は互換性のため維持するが、Auto Bind Profileを持たないPublic Defaultでは新規割り当てを行わない。

---

## 4. Backspaceは通常Keyboardと区別できない

対象実機では外付けテンキーBackspaceと通常Keyboard Backspaceが同じKey Eventとして届く。

そのためPublic DefaultではBackspaceをDisabledにする。

BackspaceをWindow / Shortcutへ変更すると通常Keyboard側BackspaceもController Actionを発火するため、起動時Warningを表示する。

---

## 5. Keyboard Device単位の識別なし

通常のAutoHotkey Keyboard Hook / InputHookを使用し、同じVK / SCを送る複数Keyboard Deviceを区別しない。

専用デバイス単位制御が必要な場合はAutoHotInterception等を別途検討する。

---

## 6. 物理NumLockをController Actionとして利用しない

対象実機では物理NumLockをAutoHotkey InputHook / Windows Raw Inputで取得できなかった。

このNumLockキーはテンキー内部の入力切替として機能するが、WindowsへNumLock Keyboard Eventを送信しない。したがって、テンキー側の入力モードとWindows側NumLock状態は独立している。

NumLock自体へController Actionを割り当てない。

実行中のWindows側NumLock状態はON固定し、正常終了時に起動前状態へ戻す。Windows側lifecycleはPhase F R-14で確認済み。

---

## 7. 強制終了時のNumLock復元は保証しない

Process Kill、OS障害等でOnExitが実行されない場合は、起動前NumLock状態への復元を保証しない。

---

## 8. Virtual000有効時はNumpad0へ最大約80msの判定待ちがある

Public DefaultではVirtual000をDisabledにするため、この待機は発生しない。

Virtual000をWindow / Shortcutとして有効化した場合のみ、物理000の `D-U-D-U-D-U` を識別するためNumpad0も最大約80ms待って確定する。

---

## 9. Numpad0 / Virtual000には依存関係がある

`Numpad0=Disabled` の場合、`Virtual000` もDisabledでなければならない。

Virtual000だけControllerで処理しつつ、通常Numpad0だけを完全なNative Inputとして扱う構成は実装しない。

---

## 10. Shortcut Target種別は限定

直接Targetとして許可するのは:

- exe
- bat
- cmd
- lnk

`.ps1` は直接Targetにせず `pwsh.exe -File ...` を使用する。

URL、Document Association、任意URI Scheme等は現行対象外。

---

## 11. Config独自の環境変数展開なし

Shortcut Target / WorkingDirectoryで:

- `%USERPROFILE%`
- `%LOCALAPPDATA%`
- `~`

等を独自展開しない。

絶対Path、Script Directory基準の相対Path、またはWindows側で解決可能な実行ファイル名を使用する。

---

## 12. 常設GUIなし

現行版には次を用意しない。

- 設定GUI
- Binding一覧GUI
- 常設Status Window
- Tray MenuからのConfig編集

設定はINIを編集する。

---

# Legacy Developer Workflow固有

以下は `examples/KeyBindings.developer-workflow.ini`（ConfigVersion 1）を使用した場合だけ適用する。

## 13. Chrome Auto BindはPrimary Monitor基準

Chrome 7 / 8 / 9の新規Auto BindはPrimary Monitor Work Areaを基準にする。

Secondary Monitor上のChromeは新規候補にしない。

---

## 14. Minimized / Maximized Chromeは新規座標分類しない

Chromeの新規Auto BindではNormal Windowだけを座標分類する。

既存Binding済みWindowはHWNDとAllowed条件が有効ならMinimize / Maximize後も維持する。

---

## 15. Chromeは最大3Window

Legacy PresetではChrome Auto Bind Slotを7 / 8 / 9に固定する。

4つ目以降を他Slotへ自動転送しない。

---

## 16. VS Codeは最大3Window・真のOpen順非保証

Legacy Presetでは4 / 5 / 6へ最大3Windowを割り当てる。

起動前から存在する複数VS Code Windowの真の生成順は復元せず、Auto Bind時点の `WinGetList` 逆順を使用する。

---

## 17. Legacyアプリ識別はProcess / Class / Titleに依存

ConfigVersion 1 Presetの条件:

- Chrome: `chrome.exe`
- VS Code: `Code.exe`
- Explorer: `explorer.exe + CabinetWClass`
- ChatGPT Desktop: `ChatGPT.exe`
- PowerShell 7: `WindowsTerminal.exe + CASCADIA_HOSTING_WINDOW_CLASS + Title contains PowerShell 7`

対象Application側の仕様変更時にはPreset調整が必要になる可能性がある。

---

## 18. Legacy Auto BindにBackground Retryなし

候補が見つからなかった場合はNoneを維持する。

次回キー押下によるLazy Auto Bind、または明示Auto Bindで再評価する。常時監視は行わない。

---

# Startup Task固有

## 19. 自動起動Taskは通常権限

Task Scheduler登録はLeastPrivilege / InteractiveTokenを使用する。

管理者権限で起動したApplicationをWindowsの権限分離により操作できない場合がある。

---

## 20. 自動起動Taskは絶対Pathを保持

Task Scheduler Actionには登録時点のAutoHotkey executable、Controller Script、Repository Rootを保存する。

配置場所を変更した場合は:

```powershell
.\scripts\install-startup-task.ps1
```

を再実行する。

---

## 21. 自動起動は現在ユーザー単位

既定Taskはinstall scriptを実行した現在ユーザーのLogon Triggerだけを登録する。

全ユーザー共通StartupやService化は対象外。


---

## 22. Configuration INIはUTF-8のみ

現行版は `KeyBindings.ini` および配布INIをUTF-8前提で扱う。

- UTF-8 BOMなし: 対応
- UTF-8 BOMあり: 対応
- UTF-16 LE / BE: 非対応

v0.2.x以前のUTF-16 LE Configを継続利用する場合は、起動前にUTF-8へ変換する。
