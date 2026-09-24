# Numpad Window Controller - Implementation Tasks

更新日: 2026-09-24
対象: NumpadWindowController  
目的: 現在の暫定設計から、AutoHotkey v2による初期実装と実機検証までを完了するためのタスク一覧

## 0. 現在地点

完了済み:

- [x] プロジェクト名決定
- [x] GitHubリポジトリ作成
- [x] Windows 11 + AutoHotkey v2を基本技術として採用
- [x] 実機テンキーの主要キーについて Key Name / VK / SC を確認
- [x] `000` キーが独立キーではなく `Numpad0` を3回送ることを確認
- [x] 設定可能キーのModeを `Window / Shortcut / Disabled` に整理し、NumLockは予約Global Functionとする
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

# Phase C - Auto Bindアルゴリズム確定 ✅ 完了

詳細仕様: [Phase C Specification](docs/PHASE_C_SPEC.md)

採用した内容:

- [x] **C-1 Auto Bind処理順**
  - Auto Bind対象は専用Slot `1～9` のみ
  - 有効なManual / Auto Bindingは維持
  - 無効BindingだけNoneへ落とし、空Slotだけ補充
  - Group順は Chrome → VS Code → Explorer → ChatGPT → PowerShell
  - 候補不足は残りSlot=None、候補過多は余剰候補を無視
  - Working State上で計算し、最終検証後にRuntime StateへCommit
- [x] **C-2 4つ目以降のChrome / VS Code**
  - 自動割り当てしない
  - 任意Slotへ自動転送しない
  - 必要な場合だけManual Bind
- [x] **C-3 一般Window**
  - 一般Window Auto Bind自体をMVPでは実装しない
  - 任意Slot `/ * - + DEL 0 000 . Enter` はManual専用
  - 一般Windowの優先順位 / 自動Slot順は定義しない
- [x] **C-4 Lazy Auto Bind**
  - Binding None / HWND消滅 / Allowed条件違反時のみ発動
  - Chrome / VS CodeはGroup単位で空Slot補充
  - 1 / 2 / 3は対象Slotだけ補充
  - Shortcut / Disabled / AutoBind=OFFでは実行しない
  - 失敗時はNoneのままToolTip、Background Retryなし
- [x] **個別Auto Bind**
  - `Ctrl + Alt + 7/8/9` = Chrome Group補充
  - `Ctrl + Alt + 4/5/6` = VS Code Group補充
  - `Ctrl + Alt + 1/2/3` = 対象Slot補充
- [x] **完全再構築**
  - `NumLock` 単体は有効Bindingを維持して欠損補修
  - 完全再構築は `Ctrl + NumLock → NumLock`
- [x] **1 HWND : 1 Slot**
  - Used HWND Setで候補重複を防止
  - Commit前に最終重複検証

Phase C完了。次工程は **Phase D - Configuration仕様確定**。

---

# Phase D - Configuration仕様確定 ✅ 完了

詳細仕様: [Phase D Configuration Specification](docs/PHASE_D_SPEC.md)

採用した内容:

- [x] **D-1 設定ファイル形式**
  - INIを正式採用
  - ファイル名は `KeyBindings.ini`
  - Scriptと同じDirectoryに固定
  - `[General] ConfigVersion=1` 必須
  - UTF-16 LE BOMを正規Encodingとする
  - Hot Reloadなし、編集後はScript再起動
- [x] **D-2 Key設定スキーマ**
  - Key identityはSection名
  - 18 Key Sectionをすべて必須
  - Modeは `Window / Shortcut / Disabled`
  - 共通Fieldは `Mode / Label`
  - Window Modeは `AllowedProcess / AllowedClass / AllowedTitleContains`
  - `AutoBind / AutoBindGroup / AutoBindOrder` はConfigから除外し、コード側Built-in Metadataへ固定
  - NumLockはConfig対象外
- [x] **D-3 Shortcut**
  - Target対応: `.exe / .bat / .cmd / .lnk`
  - Arguments / WorkingDirectory対応
  - `.ps1` 直接Targetは禁止
  - PowerShell Scriptは `pwsh.exe -File ...` を使用
  - Shortcutは毎回Targetを実行し、既存Window Activateは行わない
  - Target解決失敗 / 不存在は起動時Fatal
  - 実行時失敗は通知してScript継続
- [x] **D-4 設定Validation**
  - Config不存在 / Version不正 / 未知Section / Section不足 / 重複 / 未知FieldをFatal
  - Mode / Label / Mode別Field整合を検証
  - 専用Slot 1～9はWindow Mode固定
  - Chrome 7/8/9、VS Code 4/5/6のAllowed条件整合を検証
  - Numpad3へ `AllowedTitleContains=PowerShell 7` を正式採用
  - `Numpad0=Disabled` の場合は `Virtual000=Disabled` を必須
- [x] **Backspace安全方針**
  - 物理DELは通常Keyboard Backspaceと区別不可
  - 標準Configは `Key-Backspace Mode=Disabled`
  - Disabled KeyはController Hotkeyを登録せずネイティブ入力を通す
  - Backspaceを有効化した場合は起動時Warning

Phase D完了。次工程は **Phase E - 実装設計**。

---

# Phase E - 実装設計 ✅ 完了

詳細仕様: [Phase E Implementation Design](docs/PHASE_E_SPEC.md)

採用した内容:

- [x] **E-1 ファイル構成**
  - MVP本体は `NumpadWindowController.ahk` 1ファイル
  - Configurationは `KeyBindings.ini`
  - Phase Fでは `lib/` 分割しない
  - 単一ファイル内を責務Section＋Prefix関数で整理
- [x] **E-2 Runtime State**
  - AHK v2の `Map` + 単純Objectを使用
  - Global入口は1つの `App State`
  - Config / Key Definitionは起動後Immutable扱い
  - Runtime Bindingの正本は `App.Slots`
  - Slot Stateは基本 `Hwnd + BindingSource`
  - Window metadataは都度取得して永続キャッシュしない
  - Used HWND SetはAuto Bind処理中だけ生成する一時Map
  - Auto BindはWorking Stateで計算し、最終Validation後にCommit
- [x] **E-3 Input / Action責務**
  - Window Modeだけ通常 / Ctrl / Ctrl+Shift / Ctrl+Alt Controller Hotkeyを登録
  - Shortcut Modeは通常押下だけ登録
  - DisabledはHotkeyを登録せずネイティブ入力を通す
  - Numpad0 / Virtual000だけInputHook Detectorを使用
  - Logical Key化後は共通Dispatcherへ渡す
- [x] **E-4 Logging / Diagnostics**
  - 通常利用では永続Logなし
  - Debugはコード内定数で明示有効化
  - Debug時のみ `logs/NumpadWindowController_<timestamp>.log`
  - 全Key Down/Upは常時記録しない
  - Auto Bind後のSlot Snapshotを診断出力可能にする
- [x] **E-5 Startup / Shutdown**
  - Config Validation完了前にNumLock / Hotkey状態を変更しない
  - Validation後に元NumLock状態を保存しOnExit登録
  - 正常終了時にNumLock状態を復元
- [x] **E-6 実装責務**
  - Config / Runtime / Input / Zero Detector / Window Probe / Auto Bind / Actions / Notification / Debugを関数Prefixで分離
  - MVPではClass階層や汎用Rule Engineを作らない

Phase E完了。次工程は **Phase F - AutoHotkey v2実装**。

---

# Phase F - AutoHotkey v2実装

初回実機テストまで実施済み。Window制御系は概ねPASSし、特殊入力系の修正版を実装した。
現在は [Phase F Manual Test Guide](docs/PHASE_F_MANUAL_TEST.md) のR-1～R-7による再テスト待ち。
詳細: [Phase F検証結果](docs/PHASE_F_RESULT.md)。

## F-1. Skeleton / App State

- [x] `#Requires AutoHotkey v2.0`
- [x] Single Instance設定
- [x] App State生成
- [x] Built-in Metadata生成
- [x] 起動 / OnExit骨格
- [x] Config Validation前にNumLockやHotkeyを変更しないことを確認

## F-2. Config / Runtime初期化

- [x] UTF-16 LE BOM INI読込
- [x] ConfigVersion / Section / Field Validation
- [x] Mode / Allowed / Shortcut Validation
- [x] Key Definition生成
- [x] Slot State生成
- [x] Backspace Warning
- [x] Numpad0 / Virtual000整合Validation

## F-3. Window Probe / 基本操作

- [x] Active Window取得
- [x] HWND存在確認
- [x] Process / Class / Title取得
- [x] Minimized判定
- [x] Restore
- [x] Activate
- [x] Window候補列挙

## F-4. Manual Bind

- [x] Window Mode確認
- [x] Allowed条件確認
- [x] 重複処理
- [x] HWND登録
- [x] BindingSource=Manual
- [x] 成功/失敗通知

## F-5. Chrome Auto Bind

- [x] Chrome候補列挙
- [x] Monitor / Position / Size取得
- [x] 左上Chrome判定
- [x] 左下Chrome判定
- [x] 右大Chrome判定
- [x] 7/8/9へBinding
- [x] 4つ目以降をAuto Bind対象外として残す

## F-6. VS Code Auto Bind

- [x] VS Code候補列挙
- [x] 未使用候補をWinGetList逆順で空き4→5→6へ割り当て
- [x] 4/5/6へBinding
- [x] 4つ目以降をAuto Bind対象外として残す

## F-7. Explorer / ChatGPT / pwsh Auto Bind

- [x] Explorer判定
- [x] ChatGPT判定
- [x] pwsh判定
- [x] 1/2/3への割り当て

## F-8. Auto Bind State整合性

- [x] 有効Manual / Auto Bindingを維持
- [x] 無効BindingをNoneへ変更
- [x] Used HWND Setを構築
- [x] Working State上でAuto Bind結果を計算
- [x] Commit前に1 HWND : 1 Slotを検証
- [x] 一般Windowを任意Slotへ自動割り当てしないことを確認

## F-9. Lazy Auto Bind

- [x] Binding None / HWND無効 / Allowed違反を検知
- [x] Chrome / VS CodeはGroup単位で空Slot補充
- [x] 1 / 2 / 3はSlot単位再探索
- [x] AutoBind=OFF / Shortcut / Disabledでは実行しない
- [x] 成功時Activate
- [x] 失敗時None維持 + ToolTip
- [x] Background Retryを行わない

## F-10. Clear処理

- [x] Slot Clear
- [x] Clear All
- [x] Configurationを消さないことを確認

## F-11. Shortcut実行

- [x] exe起動
- [x] bat/cmd実行
- [x] lnk実行
- [x] Arguments対応
- [x] Working Directory対応
- [x] 実行失敗通知

## F-12. Input / Hotkey / NumLock / Debug

- [x] Window Mode Hotkey登録
- [x] Shortcut Mode通常Hotkey登録
- [x] Disabled KeyはHotkey未登録
- [x] Common Dispatcher
- [x] Numpad0 / Virtual000 InputHook Detector
- [ ] NumLock Auto Bind All（物理SC145修正版の再テスト待ち）
- [ ] Ctrl+NumLock Clear All（^Pause修正版の再テスト待ち）
- [ ] OnExit NumLock復元（再テスト待ち）
- [x] ToolTip通知
- [x] Debug Log / Slot Snapshot
- [x] Debug File I/O失敗がController動作へ波及しないことを確認

## F-13. 初回Manual Test後の修正

- [x] Backspace→KeypadDel名称変更案を撤回
  - 初回記録はユーザーの誤認
  - 実機物理キーもBackspace
  - `Key-Backspace` を維持
- [x] 通常NumLockを物理 `SC145` Hotkeyへ変更
- [x] Ctrl+NumLockをAutoHotkey仕様どおり `^Pause` Hotkeyへ変更
- [x] NumLock Global Action後にAlwaysOnを再適用・ON確認
- [x] Modifier付きVirtual000判定窓を120msへ拡張
- [x] 通常0/000の80ms判定窓は維持
- [x] Debug LogへInput Dispatch / Zero timing診断を追加
- [x] NumLock / Modifier付き000の自動テストを追加
- [ ] Manual Test R-1～R-7をPASS
- [ ] Phase F最終完了判定

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

初回Phase F Manual Testで見つかった入力系問題への修正版を実装済み。
次は [Phase F Manual Test Guide](docs/PHASE_F_MANUAL_TEST.md) のR-1～R-7を実施する。
特に物理NumLock / Ctrl+NumLock、Ctrl+000、Numpad0 Clear後通知、NumLock終了時復元を確認する。
すべてPASS後にPhase Fを閉じ、Phase G/Hへ進む。
