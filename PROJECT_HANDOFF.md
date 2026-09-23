# PROJECT_HANDOFF

更新日: 2026-09-23  
対象: NumpadWindowController  
状態: Phase E完了 / Phase F実装前

## 1. プロジェクト概要

一般的なUSBテンキーを、Windows上の複数ウィンドウへ直接切り替えるためのコントローラーとして利用する。

現在は、Window切り替えだけでなく、キーごとにShortcutや特別機能も持てる設計へ拡張している。

## 2. 技術方針

- Windows 11
- AutoHotkey v2
- 一般的なUSBテンキー
- 実行中Window識別はHWND
- HWNDは永続化しない
- 永続ConfigurationとRuntime Bindingを分離する

## 3. キー動作モデル

設定可能な通常キーは次のいずれかのModeを持つ。

- Window
- Shortcut
- Disabled

NumLockは通常Modeとは別の予約Global Function Keyとして扱う。

ShortcutキーはWindow Binding対象外。

`000` は独立VK/SCを持たないが、高速なNumpad0 D-U×3をPoCで識別できたため、論理キー `Virtual000` として正式採用する。

## 4. 現在の既定配置

```text
NumLock  /       *       -
Function 任意    任意    任意

7        8       9       +
Chrome1  Chrome2 Chrome3 任意

4        5       6       DEL
VSCode1  VSCode2 VSCode3 任意

1        2       3       Enter
Explorer ChatGPT pwsh    任意

0        000     .       Enter
任意     仮想キー 任意   任意
```

NumLockには特別機能を持たせる予定。Numpad0は通常の任意キーとして扱う。

物理DELキーはAutoHotkey上では `Backspace` として検出される。

## 5. Auto Bind優先順位

### Chrome

最優先。

優先3Windowのみ `7 / 8 / 9` へ割り当てる。

- 7: 左上、画面幅約30% × 高さ約50%
- 8: 左下、画面幅約30% × 高さ約50%
- 9: 右側、画面幅約70% × 高さ100%

Chrome Windowは基本的に重ならない運用を前提とする。

4つ目以降のChromeは一般候補扱い。

### VS Code

Chromeの次に優先。

優先3Windowのみ、開いた順番で:

```text
1番目 -> 4
2番目 -> 5
3番目 -> 6
```

VS Code Windowは重なる運用を前提とする。

4つ目以降のVS Codeは一般候補扱い。

## 6. その他の専用Window

- 1: Explorer = `explorer.exe` + `CabinetWClass`
- 2: ChatGPT Desktop = `ChatGPT.exe`
- 3: PowerShell 7 = `WindowsTerminal.exe` + `CASCADIA_HOSTING_WINDOW_CLASS` + Title contains `PowerShell 7`

## 7. Shortcut Mode

設定ファイルからキーへShortcutを割り当て可能にする。

用途:

- アプリ起動
- バッチファイル実行

Shortcutが設定されたキーはWindow Binding対象から除外される。

Windowキーへ戻す場合は設定ファイルを編集後、スクリプトを再起動する。

## 8. 実機キー情報

Key HistoryでVK / SC / AutoHotkey Key Nameを確認済み。

詳細は `docs/DESIGN_DRAFT.md` の「実機で確認したAutoHotkeyキー情報」を参照。

## 9. 手動Binding

基本方針:

```text
NumpadX
  -> Window ModeならBinding済みWindowをActivate

Ctrl + NumpadX
  -> Window Modeなら現在Windowを手動Bind
```

Shortcut / DisabledキーへのWindow Bindingは拒否する。

Phase Aで以下を確定済み:

- `Ctrl + Shift + Key` -> Slot Clear
- `Ctrl + Alt + Key` -> 個別Auto Bind
- `NumLock` -> Auto Bind All
- `Ctrl + NumLock` -> Clear All

## 10. 次回以降の主要論点

Phase BのPoCコードはすべて作成済み。現在は実機結果待ち。

PoC:

1. B1 Window Enumeration
2. B2-B4 Chrome / Monitor Layout
3. B5 VS Code Observation Order
4. B6-B8 Explorer / ChatGPT / PowerShell系Terminal

詳細実行手順は `docs/PHASE_B_POC.md`。

実機結果をまとめて受領後、`docs/PHASE_B_RESULT.md` を作成して識別仕様を確定する。

## 11. 次回開始時に読む資料

1. `PROJECT_HANDOFF.md`
2. `docs/PHASE_E_SPEC.md`
3. `docs/PHASE_D_SPEC.md`
4. `docs/PHASE_C_SPEC.md`
4. `docs/PHASE_B_RESULT.md`
4. `docs/PHASE_A_SPEC.md`
4. `docs/PHASE_B_POC.md`
5. `docs/MVP_DESIGN.md`
6. `TASKS.md`
7. `docs/DESIGN_DRAFT.md`
8. `README.md`

## 12. 現在の段階

```text
プロジェクト立ち上げ
  ↓
Window Slot方式
  ↓
Chrome / VS Code制約
  ↓
Auto Bind案
  ↓
実機テンキー調査
  ↓
キーModeモデル導入
  ↓
実機配置・Chrome/VS Code優先順位・Shortcut仕様反映  ← 現在
  ↓
実装タスク一覧を作成
  ↓
Phase A 残仕様確定             ← 完了
  ↓
Phase B PoC実装                 ← 完了
  ↓
Phase B 実機結果評価             ← 完了
  ↓
Phase C Auto Bind設計            ← 完了
  ↓
Phase D Configuration設計        ← 完了
  ↓
Phase E 実装設計                 ← 完了
  ↓
Phase F AutoHotkey v2実装         ← 次
```


## 13. MVP設計レビュー

`docs/MVP_DESIGN.md` に、最低限動作する v0.1 を実装するための仕様を具体化した。実装はこの設計書のレビュー後に開始する。


## 14. Virtual000採用

物理 `000` が生成する高速な `Numpad0` D-U×3を80ms判定窓で識別し、内部では `Virtual000` として扱う。通常の `Numpad0` と分離し、`Window / Shortcut / Disabled` を設定可能とする。PoCでは通常使用時に誤認識なく動作した。


## 15. Phase A確定事項

詳細は `docs/PHASE_A_SPEC.md`。

- NumLock = Auto Bind All
- Ctrl+NumLock = Clear All
- Manual > Auto > None
- 1 HWND : 1 Slot
- 1/2/3 = Explorer / ChatGPT Desktop / PowerShell系Terminal専用
- 任意キーは原則初期Window / AutoBind OFF。ただし物理DEL=`Backspace` は安全のため標準Disabled
- Ctrl+Key = Manual Bind
- Ctrl+Shift+Key = Slot Clear
- Ctrl+Alt+Key = 個別Auto Bind
- Virtual000も通常論理キーと同一の操作体系


## 16. Phase B確定事項

詳細は `docs/PHASE_B_RESULT.md`。

- Chrome通常3Windowと再起動後は現Thresholdで7/8/9を識別可能
- Chrome座標基準はPrimary Monitor Work Area
- Minimized / Maximized Chromeは新規座標分類対象外
- VS Codeは常時監視せず、Auto Bind時に未使用Code.exe候補をWinGetListの逆順で4→5→6へ割り当てる
- 真のOpen順は保証せず、必要な場合だけManual補正
- Explorer = explorer.exe + CabinetWClass
- ChatGPT Desktop = ChatGPT.exe
- PowerShell 7 = WindowsTerminal.exe + CASCADIA_HOSTING_WINDOW_CLASS + Title contains "PowerShell 7"
- Phase Dへ AllowedTitleContains を追加


## 17. Phase C確定事項

詳細は `docs/PHASE_C_SPEC.md`。

- Auto Bindは専用Slot 1～9だけ
- 任意SlotはManual専用で一般Window Auto Bindなし
- NumLockは有効Manual / Auto Bindingを維持して欠損だけ補修
- 完全再構築は Ctrl+NumLock → NumLock
- Chromeは新規割り当て時だけ座標判定
- VS Codeは未使用候補を逆列挙順で空き4→5→6へ補充
- 4つ目以降のChrome / VS CodeはAuto Bindしない
- Lazy Auto BindはGroup / Slot単位の空Slot補充
- Lazy失敗時はNone + ToolTip、Background Retryなし
- Used HWND SetとCommit前検証で1 HWND : 1 Slotを保証


## 18. Phase D確定事項

詳細は `docs/PHASE_D_SPEC.md`。

- Configは `KeyBindings.ini` / INI / ConfigVersion=1
- UTF-16 LE BOM
- Mode = Window / Shortcut / Disabled
- AutoBind / GroupはConfigではなくBuilt-in Metadata
- AllowedProcess / AllowedClass / AllowedTitleContainsをWindow Modeで使用
- Shortcutは exe / bat / cmd / lnk
- ps1はpwsh.exe + -File
- Config変更はScript再起動で反映
- 起動時に構造 / Mode / Allowed / ShortcutをFatal Validation
- Backspaceは標準Disabled。明示有効化時は通常Keyboard Backspaceも巻き込むWarning
- Numpad0 Disabled時はVirtual000もDisabled必須


## 19. Phase E確定事項

詳細は `docs/PHASE_E_SPEC.md`。

- MVP本体は単一 `NumpadWindowController.ahk`
- `lib/` 分割はMVPでは行わない
- Global Runtime入口は1つのApp State
- Config / Key Definitionは起動後Immutable
- Runtime Binding正本はApp.Slots
- Slot StateはHwnd + BindingSource
- Window metadata / Used HWND Setは一時データ
- Auto BindはWorking Stateで計算後Commit
- Window ModeだけController修飾Hotkeyを登録
- ShortcutはNormalのみ、DisabledはHotkey未登録
- Numpad0 / Virtual000だけInputHook Detector
- 通常利用では永続Logなし、Debug時のみログ
