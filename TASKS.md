# Numpad Window Controller - Implementation Tasks

更新日: 2026-09-23  
対象: NumpadWindowController  
目的: 現在の暫定設計から、AutoHotkey v2による初期実装と実機検証までを完了するためのタスク一覧

## 0. 現在地点

完了済み:

- [x] プロジェクト名決定
- [x] GitHubリポジトリ作成
- [x] Windows 11 + AutoHotkey v2を基本技術として採用
- [x] 実機テンキーの主要キーについて Key Name / VK / SC を確認
- [x] `000` キーが独立キーではなく `Numpad0` を3回送ることを確認
- [x] キーModeを `Window / Shortcut / Function / Disabled` に整理
- [x] `7 / 8 / 9` をChrome専用とする方針を決定
- [x] `4 / 5 / 6` をVS Code専用とする方針を決定
- [x] `1 / 2 / 3` の既定用途を Explorer / ChatGPTデスクトップ / pwsh とする方針を決定
- [x] `0` を通常の任意キーへ変更
- [x] Chrome優先3Windowの座標ベースAuto Bind方針を決定
- [x] VS Code優先3Windowを「開いた順」で割り当てる方針を決定
- [x] ShortcutキーをWindow Binding対象から除外する方針を決定
- [x] HWNDをRuntime Bindingとして使用し、永続化しない方針を決定

---

# Phase A - 残仕様の確定 ✅ 完了

詳細仕様: [Phase A Specification](docs/PHASE_A_SPEC.md)

採用した内容:

- [x] **A-1 NumLock**
  - `NumLock` = Auto Bind All
  - `Ctrl + NumLock` = Clear All
  - 起動時に元のNumLock状態を保存してON固定
  - 正常終了時に起動前状態へ復元
  - NumLockはINIから変更できない予約Global Key
- [x] **A-2 Manual / Auto優先関係**
  - `Manual > Auto > None`
  - 有効なManual BindはAuto Bindで上書きしない
  - Manual対象HWND消滅時はNoneへ移行し、AutoBind=ONなら後のLazy/Auto Bindで復帰可能
  - Slot Clear直後には自動再割り当てしない
- [x] **A-3 重複Binding**
  - `1 HWND : 1 Slot` を例外なく適用
  - Manualで別Slotへ移す場合は旧SlotをNoneへする
  - Auto BindではUsed HWND Setで重複候補を除外
  - Allowed違反時は既存Bindingを変更しない
- [x] **A-4 Numpad1 / 2 / 3**
  - `1` = Explorer専用
  - `2` = ChatGPT Desktop専用
  - `3` = PowerShell系Terminal専用
  - Manual Bindでも専用用途のAllowed条件を強制
  - 実際のProcess/Class/Title判定値はPhase Bで確定
- [x] **A-5 任意キー**
  - `/ * - + DEL 0 000 . Enter` を初期 `Window / AutoBind=OFF`
  - `000` は論理キー `Virtual000`
  - 標準Shortcut割り当てはなし
  - サポート対象キーはINIで `Window / Shortcut / Disabled` を必ず明示
  - PassThrough ModeはMVPでは採用しない
- [x] **A-6 Hotkey体系**
  - `Key` = Activate / Shortcut
  - `Ctrl + Key` = Manual Bind
  - `Ctrl + Shift + Key` = Slot Clear
  - `Ctrl + Alt + Key` = 個別Auto Bind
  - `NumLock` = Auto Bind All
  - `Ctrl + NumLock` = Clear All
  - NumpadWindowControllerが扱うHotkeyは元アプリへ渡さない

Phase A完了条件を満たしたため、次工程は **Phase B - Window識別方式の技術検証** とする。

---

# Phase B - Window識別方式の技術検証 ✅ 完了

詳細結果: [Phase B Result](docs/PHASE_B_RESULT.md)  
PoC手順: [Phase B PoC Guide](docs/PHASE_B_POC.md)

実機結果により以下を確定した。

- [x] **B-1 Window列挙**
  - HWND / PID / Process / Class / Title / Geometry / MinMax / Style / ExStyle / Owner / Cloaked / ToolWindow / Monitorを取得可能
  - 共通Candidate Filterを確定
- [x] **B-2 Chrome識別**
  - 通常3Window配置で7/8/9候補を正しく分類
  - Chrome再起動後も新HWNDを座標から再分類可能
- [x] **B-3 Chrome Tolerance**
  - 現MVP Thresholdをそのまま採用
  - 実配置は概ね左40% / 右60%だが現Threshold内
  - Minimized / Maximized Chromeは新規座標分類対象外とする
- [x] **B-4 Monitor方針**
  - 実機は3840×2160 ×2
  - Chrome専用Auto BindはPrimary Monitor Work Area固定
  - Secondary Monitor追従はMVP後
- [x] **B-5 VS Code順序**
  - 起動前既存Windowの真のOpen順は復元不可
  - PID / Process Creation Timeは複数Windowで同一
  - 厳密なOpen順はMVP要件としない
  - Auto Bind時に未使用Code.exe候補をWinGetListの逆順で4→5→6へ割り当てる
  - 常時監視 / Observation Sequenceは採用しない
  - 順序差は許容し、必要時のみManual Bindで補正する
- [x] **B-6 Explorer**
  - Process=`explorer.exe`
  - Class=`CabinetWClass`
  - Shell_TrayWnd / Progman等は共通Filterで除外可能
- [x] **B-7 ChatGPT Desktop**
  - Process=`ChatGPT.exe`
  - Class=`Chrome_WidgetWin_1`
  - 識別はProcessを必須条件とする
- [x] **B-8 PowerShell / Windows Terminal**
  - top-levelは`WindowsTerminal.exe` / `CASCADIA_HOSTING_WINDOW_CLASS`
  - `pwsh.exe` 自体はPseudoConsoleWindowでCandidate外
  - Titleに`PowerShell 7`を含む条件でWindows PowerShell / cmdと区別
  - Phase Dへ `AllowedTitleContains` を追加要求

Phase B Known Limitation:

- Auto Bindをゼロから行う時、Minimized / Maximized Chromeは元の7/8/9位置を現在座標から判定しない。
- すでにHWND Binding済みなら、その後にMinimize / MaximizeしてもBindingは維持する。
- VS Codeの真のOpen順は保証せず、簡易な逆列挙順を使用する。

追加PoCはMVPには不要。次工程は **Phase C - Auto Bindアルゴリズム確定**。

---

# Phase C - Auto Bindアルゴリズム確定

## C-1. Auto Bind処理順を確定

基本案:

1. 対象Window列挙
2. 使用不可Window除外
3. Shortcut / Function / Disabledキー除外
4. Manual Bind維持処理
5. Chrome 3Windowを7/8/9へ割り当て
6. VS Code 3Windowを4/5/6へ割り当て
7. Explorer / ChatGPT / pwshを処理
8. その他Windowを任意Slotへ割り当て
9. 重複チェック
10. Runtime State更新

タスク:

- [ ] 上記順序を最終確定
- [ ] 候補不足時の挙動を決定
- [ ] Slot不足時の挙動を決定

## C-2. 4つ目以降のChrome / VS Code処理

- [ ] 一般候補へ回すことを実装仕様として明文化
- [ ] 一般候補内での順位を決める
- [ ] 任意Slotが不足する場合は未割り当てとするか決める

## C-3. 一般Windowの優先順位

- [ ] Explorer / ChatGPT / pwshを一般Windowより先にするか確定
- [ ] 残りWindowの並び順を決める
  - Z-order
  - 起動順
  - Process名
  - HWND
  - その他
- [ ] 未使用任意Slotへの割り当て順を決める

## C-4. Lazy Auto Bind仕様

- [ ] HWND無効時に自動再探索する条件を確定
- [ ] Shortcut Modeでは実行しないことを確認
- [ ] 再探索失敗時の通知を決める

---

# Phase D - Configuration仕様確定

## D-1. 設定ファイル形式を確定

候補:
- INI
- JSON

現時点ではINI案がある。

タスク:

- [ ] INIで必要なネスト・配列表現が十分か確認
- [ ] JSONとの比較
- [ ] 最終形式を決定

## D-2. Key設定スキーマ確定

最低限検討するフィールド:

- [ ] Key
- [ ] Mode
- [ ] Label
- [ ] AllowedProcess
- [ ] AllowedClass
- [ ] AutoBind
- [ ] AutoBindGroup
- [ ] AutoBindOrder
- [ ] ShortcutTarget
- [ ] ShortcutArguments
- [ ] ShortcutWorkingDirectory
- [ ] Function

## D-3. Shortcut仕様確定

- [ ] exe起動を対応
- [ ] bat / cmd実行を対応
- [ ] ps1を直接対応するか決める
- [ ] Argumentsを対応するか決める
- [ ] Working Directoryを対応するか決める
- [ ] 既に起動済みの場合の挙動を決める
- [ ] ファイル不存在時のエラー処理を決める

## D-4. 設定エラー処理

- [ ] 不正Mode
- [ ] 存在しないKey
- [ ] Shortcut Target不存在
- [ ] Allowed条件矛盾
- [ ] 同一物理キーの重複定義
- [ ] 必須項目不足

完了条件:
- 起動時に設定を検証し、安全に失敗できる

---

# Phase E - 実装設計

## E-1. ファイル構成確定

候補:

```text
NumpadWindowController/
├─ NumpadWindowController.ahk
├─ KeyBindings.ini
├─ lib/
│  ├─ Config.ahk
│  ├─ WindowRegistry.ahk
│  ├─ AutoBind.ahk
│  ├─ WindowActions.ahk
│  ├─ ShortcutActions.ahk
│  └─ Notifications.ahk
├─ tests/
└─ docs/
```

- [ ] 単一ファイル構成か分割構成か決定
- [ ] 初期版で過剰分割しない方針を決める

## E-2. Runtime Stateモデル

- [ ] Key定義オブジェクト
- [ ] Window Slot状態
- [ ] HWND
- [ ] BindingSource
- [ ] Window metadata
- [ ] Used HWND set

をどう保持するか決める。

## E-3. Logging方針

- [ ] 通常利用ではログ不要か決める
- [ ] Debug Modeを設けるか決める
- [ ] Auto Bind結果を確認できる診断出力を用意するか決める

---

# Phase F - AutoHotkey v2実装

## F-1. Skeleton

- [ ] `#Requires AutoHotkey v2.0`
- [ ] Single Instance設定
- [ ] 設定ファイル読込
- [ ] 起動時設定検証
- [ ] Runtime State初期化

## F-2. Hotkey登録

- [ ] Window Modeの通常押下
- [ ] `Ctrl + Key` Manual Bind
- [ ] Auto Bind All
- [ ] Slot Auto Bind
- [ ] Slot Clear
- [ ] Clear All
- [ ] Function Mode
- [ ] Shortcut Mode
- [ ] Disabled Mode

## F-3. Window基本操作

- [ ] Active Window取得
- [ ] HWND存在確認
- [ ] Process / Class / Title取得
- [ ] Minimized判定
- [ ] Restore
- [ ] Activate
- [ ] Window候補列挙

## F-4. Manual Bind

- [ ] Window Mode確認
- [ ] Allowed条件確認
- [ ] 重複処理
- [ ] HWND登録
- [ ] BindingSource=Manual
- [ ] 成功/失敗通知

## F-5. Chrome Auto Bind

- [ ] Chrome候補列挙
- [ ] Monitor / Position / Size取得
- [ ] 左上Chrome判定
- [ ] 左下Chrome判定
- [ ] 右大Chrome判定
- [ ] 7/8/9へBinding
- [ ] 4つ目以降を一般候補へ返す

## F-6. VS Code Auto Bind

- [ ] VS Code候補列挙
- [ ] B-5で決めた方式で開いた順を判定
- [ ] 4/5/6へBinding
- [ ] 4つ目以降を一般候補へ返す

## F-7. Explorer / ChatGPT / pwsh Auto Bind

- [ ] Explorer判定
- [ ] ChatGPT判定
- [ ] pwsh判定
- [ ] 1/2/3への割り当て

## F-8. 一般Window Auto Bind

- [ ] 残Window候補の整列
- [ ] 残り任意Slotの列挙
- [ ] 1 Window : 1 Slotを保証
- [ ] Slot不足時の処理

## F-9. Lazy Auto Bind

- [ ] HWND無効検知
- [ ] Slot単位再探索
- [ ] 成功時Activate
- [ ] 失敗時通知

## F-10. Clear処理

- [ ] Slot Clear
- [ ] Clear All
- [ ] Configurationを消さないことを確認

## F-11. Shortcut実行

- [ ] exe起動
- [ ] bat/cmd実行
- [ ] Arguments対応
- [ ] Working Directory対応
- [ ] 実行失敗通知

## F-12. NumLock Function

- [ ] A-1で確定した機能を実装

---

# Phase G - テスト

## G-1. 設定読込テスト

- [ ] 正常設定
- [ ] 不正Mode
- [ ] 不正Key
- [ ] Shortcut不存在
- [ ] 重複設定

## G-2. Manual Bindテスト

- [ ] Chrome -> 7/8/9 成功
- [ ] VS Code -> 7/8/9 拒否
- [ ] VS Code -> 4/5/6 成功
- [ ] Chrome -> 4/5/6 拒否
- [ ] ShortcutキーへのManual Bind拒否
- [ ] DisabledキーへのManual Bind拒否

## G-3. Chrome Auto Bindテスト

- [ ] 1Window
- [ ] 2Window
- [ ] 3Window
- [ ] 4Window以上
- [ ] 左上/左下/右大の正しい割り当て
- [ ] 数pxずれ
- [ ] 最小化
- [ ] 再起動後の再割り当て

## G-4. VS Code Auto Bindテスト

- [ ] 1Window
- [ ] 2Window
- [ ] 3Window
- [ ] 4Window以上
- [ ] 開いた順の正しい割り当て
- [ ] VS Code再起動
- [ ] Window Close後の再割り当て

## G-5. 1/2/3テスト

- [ ] Explorer
- [ ] ChatGPTデスクトップ
- [ ] pwsh
- [ ] 対象アプリ不存在
- [ ] 複数候補存在時

## G-6. Shortcutテスト

- [ ] exe
- [ ] bat/cmd
- [ ] Arguments
- [ ] Working Directory
- [ ] Target不存在
- [ ] Window Binding対象から除外されること

## G-7. Clear / Lazy Bindテスト

- [ ] Slot Clear
- [ ] Clear All
- [ ] Clear後Auto Bind
- [ ] HWND無効化後Lazy Auto Bind
- [ ] Manual Bindとの優先関係

## G-8. 長時間常駐テスト

- [ ] 数時間常駐
- [ ] Chromeのタブ変更
- [ ] Window増減
- [ ] Sleep / Resume
- [ ] Explorer再起動
- [ ] スクリプト再起動

---

# Phase H - 実機受入試験

## H-1. 日常操作シナリオ

- [ ] 7で左上Chromeへ移動
- [ ] 8で左下Chromeへ移動
- [ ] 9で右大Chromeへ移動
- [ ] 4/5/6でVS Codeを開いた順に切り替え
- [ ] 1でExplorer
- [ ] 2でChatGPTデスクトップ
- [ ] 3でpwsh
- [ ] 0を任意WindowまたはShortcutとして設定して利用
- [ ] 任意キーのShortcut実行
- [ ] Manual Bindで一時的に割り当て変更
- [ ] Clear / Auto Bindで復旧

## H-2. 操作感確認

- [ ] 誤操作しやすいキーがないか確認
- [ ] Hotkeyが複雑すぎないか確認
- [ ] ToolTip通知量が適切か確認
- [ ] Auto Bindの再現性を確認
- [ ] 日常的に手動再Bindingが必要にならないか確認

完了条件:
- 通常利用で追加操作なしに主要Windowへ安定して移動できる

---

# Phase I - 初期版完成処理

- [ ] 実装結果を `docs/DESIGN_DRAFT.md` へ反映
- [ ] Draft表記を見直す
- [ ] READMEへインストール方法を追加
- [ ] READMEへ設定例を追加
- [ ] READMEへ操作一覧を追加
- [ ] Known Limitationsを整理
- [ ] サンプル `KeyBindings.ini` を追加
- [ ] 必要ならLICENSEを追加
- [ ] バージョン番号を決定
- [ ] 初期リリース可否を判断

---

# 推奨する実行順

大きな依存関係は次の通り。

```text
Phase A  残仕様確定
   ↓
Phase B  技術PoC
   ↓
Phase C  Auto Bindアルゴリズム確定
   ↓
Phase D  Configuration仕様確定
   ↓
Phase E  実装設計
   ↓
Phase F  本実装
   ↓
Phase G  機能テスト
   ↓
Phase H  実機受入試験
   ↓
Phase I  初期版完成処理
```

## 最優先タスク

Phase BのPoC実装は完了済み。

次の作業はコード追加ではなく、`docs/PHASE_B_POC.md` の手順に従った実機実行と結果回収。

結果受領後:

1. B-1～B-8をまとめて評価
2. `docs/PHASE_B_RESULT.md` を作成
3. Window識別条件を確定
4. Phase Bを完了
5. Phase Cへ進む
