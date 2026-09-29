# Numpad Window Controller - Implementation Tasks

更新日: 2026-09-29
対象: NumpadWindowController  
目的: AutoHotkey v2によるNumpadWindowControllerの設計・実装・検証・Release後の一般化までを管理するタスク一覧

## 0. 現在地点

**Phase A～I完了 / ログオン時自動起動統合済み / Release済み。Phase J - General-purpose Configuration / Public Defaultを新設し、次工程として未着手。最新ReleaseはGitHub Releasesを参照。**

完了済み:

- [x] プロジェクト名決定
- [x] GitHubリポジトリ作成
- [x] Windows 11 + AutoHotkey v2を基本技術として採用
- [x] 実機テンキーの主要キーについて Key Name / VK / SC を確認
- [x] `000` キーが独立キーではなく `Numpad0` を3回送ることを確認
- [x] 設定可能キーのModeを `Window / Shortcut / Disabled` に整理し、Global ActionはNumpadEnterのCtrl系Combinationへ割り当てる
- [x] `7 / 8 / 9` をChrome専用とする方針を決定
- [x] `4 / 5 / 6` をVS Code専用とする方針を決定
- [x] `1 / 2 / 3` の既定用途を Explorer / ChatGPTデスクトップ / pwsh とする方針を決定
- [x] `0` を通常の任意キーへ変更
- [x] Chrome優先3Windowの座標ベースAuto Bind方針を決定
- [x] VS Code優先3Windowを未使用候補の`WinGetList`逆順で4→5→6へ簡易割り当てする方針を決定（真のOpen順は保証しない）
- [x] ShortcutキーをWindow Binding対象から除外する方針を決定
- [x] HWNDをRuntime Bindingとして使用し、永続化しない方針を決定

---

# Phase A - 残仕様の確定 ✅ 完了

詳細仕様: [Phase A Specification](docs/PHASE_A_SPEC.md)

採用した内容:

- [x] **A-1 Global Function / NumLock**
  - `Ctrl + NumpadEnter` = Auto Bind All
  - `Ctrl + Shift + NumpadEnter` = Clear All
  - NumpadEnter単押しはConfigどおりの通常Action
  - Standard Enter=SC01C / NumpadEnter=SC11Cを実機確認し分離
  - 物理NumLockはAHK / Raw Input双方でEventなしのためController Actionから除外
  - 起動時に元のNumLock状態を保存してON固定
  - 正常終了時に起動前状態へ復元
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
  - `/ * - + Backspace 0 000 . Enter` を初期 `Window / AutoBind=OFF`
  - `000` は論理キー `Virtual000`
  - 標準Shortcut割り当てはなし
  - サポート対象キーはINIで `Window / Shortcut / Disabled` を必ず明示
  - PassThrough ModeはMVPでは採用しない
- [x] **A-6 Hotkey体系**
  - `Key` = Activate / Shortcut
  - `Ctrl + Key` = Manual Bind
  - `Ctrl + Shift + Key` = Slot Clear
  - `Ctrl + Alt + Key` = 個別Auto Bind
  - 例外: `Ctrl + NumpadEnter` = Auto Bind All
  - 例外: `Ctrl + Shift + NumpadEnter` = Clear All
  - NumpadEnterでは上記Global ActionがGeneric Manual Bind / Slot Clearより優先
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
  - 任意Slot `/ * - + Backspace 0 000 . Enter` はManual専用
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
  - `Ctrl + NumpadEnter` は有効Bindingを維持して欠損補修
  - 完全再構築は `Ctrl + Shift + NumpadEnter → Ctrl + NumpadEnter`
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
  - NumLockはController入力ではないためConfig対象外
  - NumpadEnterのCtrl / Ctrl+ShiftはGlobal ActionとしてConfig Modeより優先
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
  - 外付けテンキーのBackspaceは通常Keyboard Backspaceと区別不可
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

# Phase F - AutoHotkey v2実装 ✅ 完了

本体実装、自動テスト、実機Smoke Test、入力系Regression Testまで完了。
R-13でClear AllとLazy Auto Bindを分離確認し、R-14でNumLock lifecycleもPASSした。
Phase F固有の未解決事項はない。
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
- [x] 旧NumLock Global Actionを廃止
- [x] Ctrl+NumpadEnter Auto Bind Allを実装
- [x] Ctrl+Shift+NumpadEnter Clear Allを実装
- [x] OnExit NumLock復元（R-14実機PASS）
- [x] ToolTip通知
- [x] Debug Log / Slot Snapshot
- [x] Debug File I/O失敗がController動作へ波及しないことを確認

## F-13. 初回Manual Test後の修正

- [x] Backspace→KeypadDel名称変更案を撤回
  - 初回記録はユーザーの誤認
  - 実機物理キーもBackspace
  - `Key-Backspace` を維持
- [x] 初回NumLock Hotkey修正案（SC145 / ^Pause）を検証
- [x] NumLock Input PoCでAHK / Raw InputともEventなしを確認
- [x] NumLock Global Action案を廃止しNumpadEnter Modifier Combinationへ移行
- [x] 初回修正としてModifier付きVirtual000判定窓を120msへ拡張
- [x] R-7ログ解析で失敗原因が時間超過ではなくInterruptと確認
- [x] 通常 / Modifier付き000の判定窓を80msへ統一
- [x] 同一Modifier状態の再DownをZero DetectorのInterrupt対象外へ変更
- [x] その他のInterruptへVK / SC / ignored診断を追加
- [x] Ctrl押下継続中000の自動Regression Testを追加
- [x] NumLock InputHook + Raw Input観測PoCを追加
- [x] NumLock PoC実機試験 R-8
- [x] Ctrl押下継続000実機試験 R-9（5/5 PASS）
- [x] Global ActionをNumpadEnterへ変更
- [x] R-10 新Global Action自動テスト
- [x] R-11 NumpadEnter Global Action初回確認（R-13でLazy Auto Bindと確定）
- [x] R-12 NumpadEnter / Standard Enter分離
- [x] R-13 Clear All直後 / Lazy Auto Bind分離再試験
- [x] R-14 NumLock lifecycle再試験（OFF復元 / ON復元 / 実行中ON固定）
- [x] Phase F最終完了判定

---

# Phase G - テスト ✅ 完了

詳細手順: [Phase G Test Guide](docs/PHASE_G_TEST.md)  
結果: [Phase G Result](docs/PHASE_G_RESULT.md)

Phase A～Fで確定した現行仕様を基準に、実Window / 実Configを使って機能を網羅確認した。G-1～G-8の65項目をすべて完了し、Phase GはPASS。未解決のPhase G固有不具合はない。
Phase Fの自動テストで確認済みの内部ロジックも、Phase Gではユーザー操作から見た期待結果で再確認する。

## G-1. 設定読込テスト

- [x] 正常なUTF-16 LE BOM / `ConfigVersion=1`設定で起動成功
- [x] 不正Modeを起動時Fatalとして拒否
- [x] 未知Section / 必須Key Section不足 / 未知Fieldを起動時Fatalとして拒否
- [x] 重複Section / Fieldを起動時Fatalとして拒否
- [x] 専用Slot 1～9のMode / Allowed条件不整合を起動時Fatalとして拒否
- [x] Shortcut Target不存在 / 解決失敗を起動時Fatalとして拒否
- [x] `.ps1`直接Targetを起動時Fatalとして拒否
- [x] `Numpad0=Disabled` かつ `Virtual000!=Disabled` を起動時Fatalとして拒否
- [x] Backspaceを有効化した設定で起動時Warning
- [x] Window / Shortcut / Disabledの全Modeで`Label`必須・空欄拒否を確認
- [x] Mode別に許可されないField混在を起動時Fatalとして拒否（ShortcutにAllowed系 / Disabledに追加Field等）

## G-2. Manual Bindテスト

- [x] Chrome -> 7/8/9 成功
- [x] VS Code -> 7/8/9 はAllowed違反として拒否し、既存Bindingを変更しない
- [x] VS Code -> 4/5/6 成功
- [x] Chrome -> 4/5/6 はAllowed違反として拒否し、既存Bindingを変更しない
- [x] 1/2/3は各専用用途以外のWindowを拒否
- [x] 同一HWNDを別SlotへManual Bindすると旧SlotがNoneになり、1 HWND : 1 Slotを維持
- [x] Shortcut ModeではCtrl+KeyをController Manual Bindとして登録せず、Runtime Bindingを変更しない
- [x] Disabled ModeではController Hotkeyを登録せず、Runtime Bindingを変更しない

## G-3. Chrome Auto Bindテスト

- [x] 1Window時、Window位置に対応する7/8/9の該当SlotだけBinding
- [x] 2Window時、各Window位置に対応するSlotだけBindingし、不足SlotはNone
- [x] 3Window時、左上=7 / 左下=8 / 右大=9へ正しくBinding
- [x] 4Window以上では専用Slotは最大3個までとし、余剰Chromeを任意Slotへ自動転送しない
- [x] 数px程度の座標ずれがPhase BのThreshold内なら同じ分類になる
- [x] Primary Monitor外のChromeを新規Auto Bind候補にしない
- [x] Minimized / Maximized Chromeを新規座標分類対象にしない
- [x] 既存Binding済みChromeはMinimize / Maximize / 位置変更後もHWNDとAllowed条件が有効ならBindingを維持
- [x] Chrome再起動で旧HWNDを無効化し、新HWNDを現在座標から再割り当て

## G-4. VS Code Auto Bindテスト

- [x] 1Window時、未使用候補を空きSlot 4→5→6の先頭へBinding
- [x] 2Window時、未使用候補を`WinGetList`逆順で空きSlot 4→5→6へBinding
- [x] 3Window時、未使用候補を`WinGetList`逆順で4→5→6へBinding
- [x] 4Window以上では最大3個までBindingし、余剰VS Codeを任意Slotへ自動転送しない
- [x] 真のOpen順は期待値にせず、Auto Bind時点の`WinGetList`逆順を期待値とする
- [x] 有効な既存4/5/6 BindingはAuto Bind Allで再ソートしない
- [x] VS Code再起動で旧HWNDを無効化し、未使用新候補で空Slotを補充
- [x] Window Close後、無効BindingをNoneへ落とし、Lazy / 明示Auto Bindで空Slotを補充

## G-5. 1/2/3テスト

- [x] Explorer: `explorer.exe` + `CabinetWClass` をNumpad1へBinding
- [x] ChatGPT Desktop: `ChatGPT.exe` をNumpad2へBinding
- [x] PowerShell 7用Windows Terminal: `WindowsTerminal.exe` + `CASCADIA_HOSTING_WINDOW_CLASS` + Title contains `PowerShell 7` をNumpad3へBinding
- [x] Windows PowerShell / cmd等、Numpad3条件外のTerminalを候補にしない
- [x] 対象アプリ不存在時は該当SlotをNoneのまま維持
- [x] 複数候補存在時は非Minimizedを優先し、同条件ならZ-orderが前のWindowを選択

## G-6. Shortcutテスト

- [x] exe起動
- [x] bat/cmd起動
- [x] lnk起動
- [x] Argumentsを正しく渡す
- [x] Working Directoryを正しく適用
- [x] Shortcut押下ごとにTargetをRunし、既存Window Activateへ置き換えない
- [x] 起動後にTargetが消失する等のRuntime実行失敗では通知し、Scriptを継続
- [x] Shortcut Mode KeyをWindow Binding / Auto Bind対象から除外

## G-7. Clear / Lazy Bindテスト

- [x] Slot Clear直後は対象SlotをNoneにし、即時Auto Bindしない
- [x] Clear All直後は全Runtime BindingをNoneにし、即時Auto Bindしない
- [x] Clear All後に`Ctrl + NumpadEnter`を実行すると専用Slot 1～9を再構築
- [x] Clear後に専用Slotを通常押下すると必要な場合だけLazy Auto BindしてActivate
- [x] HWND消滅 / Allowed条件違反を検知したBindingはNoneへ落とし、Lazy Auto Bindを試行
- [x] Chrome / VS CodeのLazy Auto BindはGroup単位で空Slotを補充
- [x] 1/2/3のLazy Auto Bindは対象Slot単位で補充
- [x] AutoBind=OFFの任意Window Slot / Shortcut / DisabledではLazy Auto Bindしない
- [x] 有効なManual BindingはAuto Bind Allで上書きしない

## G-8. 長時間常駐テスト

- [x] 数時間常駐
- [x] Chromeのタブ変更で既存Bindingが不必要に解除されない
- [x] Window増減後も重複Bindingを作らず、必要時に欠損だけ補修
- [x] Sleep / Resume後も操作継続可能
- [x] Explorer再起動後、旧HWND無効化からLazy / Auto Bindで復旧
- [x] スクリプト再起動時にHWNDを永続復元せず、新しいRuntime BindingをAuto Bindで構築

---

# Phase H - 実機受入試験 ✅ 完了

結果: [Phase H Result](docs/PHASE_H_RESULT.md)

H-1 / H-2の16項目をすべて完了し、受入条件を満たした。Phase H固有のFAIL / BLOCKED、実装修正要求、追加Known Limitationはない。

## H-1. 日常操作シナリオ

- [x] 7で左上Chromeへ移動
- [x] 8で左下Chromeへ移動
- [x] 9で右大Chromeへ移動
- [x] 4/5/6で現在のAuto Bind規則により割り当てられたVS Codeへ切り替え
- [x] 1でExplorer
- [x] 2でChatGPTデスクトップ
- [x] 3でPowerShell 7用Windows Terminal
- [x] 0を任意WindowまたはShortcutとして設定して利用
- [x] 任意キーのShortcut実行
- [x] Manual Bindで一時的に割り当て変更
- [x] Clear / Auto Bindで復旧

## H-2. 操作感確認

- [x] 誤操作しやすいキーがないか確認
- [x] Hotkeyが複雑すぎないか確認
- [x] ToolTip通知量が適切か確認
- [x] Auto Bindの再現性を確認
- [x] 日常的に手動再Bindingが必要にならないか確認

完了条件:
- [x] 通常利用で追加操作なしに主要Windowへ安定して移動できる

---

# Phase I - 初期版完成処理 ✅ 完了

結果: [Phase I Result](docs/PHASE_I_RESULT.md)

Phase A～Hで確定・検証した内容を初期版v0.1.0として整理し、設計・利用者向け文書・サンプル設定・Known Limitations・バージョン・リリース判定を同期した。

- [x] 実装結果を `docs/DESIGN_DRAFT.md` へ反映
  - 旧Draftの未確定案を現行仕様へ更新
  - ファイル名は既存リンク互換のため維持
  - 状態を `Finalized - Phase I反映済み` へ変更
- [x] Draft表記を見直す
  - `docs/MVP_DESIGN.md` を `Final / 実装・機能テスト・実機受入試験完了` へ更新
  - Phase A / C / D / E仕様書を `Implemented / Verified` へ更新
- [x] READMEへインストール方法を追加
  - AutoHotkey v2導入、リポジトリ取得、必要ファイル、起動、終了を整理
- [x] READMEへ設定例を追加
  - Window / Shortcut / Disabled
  - Arguments / WorkingDirectory
  - PowerShell Scriptの `pwsh.exe -File` 例
- [x] READMEへ操作一覧を追加
  - Window Mode操作
  - Global Action
  - Auto Bind / Clear / 0 / 000 / NumLockを整理
- [x] Known Limitationsを整理
  - `docs/KNOWN_LIMITATIONS.md` を新設
  - Phase A～Hに分散していた現行制限を集約
- [x] サンプル `KeyBindings.ini` を追加
  - `examples/KeyBindings.example.ini`
  - 正規EncodingのUTF-16 LE BOM
  - Window / Shortcut / Disabledの例を含む
- [x] 標準 `KeyBindings.ini` の文言整合
  - Backspaceの旧誤認由来Labelを `Backspace` へ修正
- [x] LICENSE要否を判断
  - Phase I時点ではprivate運用のため未追加とした
  - 2026-09-28のPublic release preparationで **MIT License** を採用し、`LICENSE` を追加済み
- [x] バージョン番号を決定
  - 初期版 = **v0.1.0**
  - Semantic Versioning形式を採用
- [x] 初期リリース可否を判断
  - **Release Ready**
  - Phase F～H完了、Phase G 65/65 PASS、Phase H 16/16 PASS
  - 現行Known Limitationsを受け入れたMVP初期版としてリリース可能
  - GitHub Tag / Release作成は別操作とし、Phase Iでは実施しない

Phase I完了条件:

- [x] 設計書が現行実装と矛盾しない
- [x] 利用者がREADMEだけで導入・基本操作・主要設定を確認できる
- [x] Known Limitationsが一か所に集約されている
- [x] 配布用サンプルConfigが正規Encodingで存在する
- [x] v0.1.0のリリース可否が明示されている

**Phase I最終判定: PASS - MVP v0.1.0初期版完成**

---

# Phase J - General-purpose Configuration / Public Default ⏳ 未着手

計画: [Phase J Plan](docs/PHASE_J_PLAN.md)

目的:

現行MVPでコード・Configへ固定されている個人用WorkflowをCoreから分離し、特定アプリや特定Window配置を前提としない一般公開向けDefaultへ移行する。

## J-1. Public Default仕様
- [ ] 特定アプリ非依存の既定キー配置を確定
- [ ] 主要Slotを任意WindowのManual Bind中心にするか確定
- [ ] Backspace / Virtual000を含む安全な既定値を確定
- [ ] 特定アプリなしでも初回利用可能な要件を確定

## J-2. Configuration一般化
- [ ] 物理キーMetadataと用途Metadataを分離
- [ ] Dedicated Slot 1～9の固定制約を見直す
- [ ] Auto BindをConfig / Presetのどちらへ置くか決定
- [ ] ConfigVersion / Migration方針を決定
- [ ] UTF-16 LE BOM固定の見直し要否を判断

## J-3. Auto Bind / Preset分離
- [ ] 固定Auto Bind GroupをCoreから分離
- [ ] Chrome座標Auto BindとVS Code逆順Auto Bindを個人Workflow側へ分離
- [ ] 現行WorkflowをPreset / Exampleとして再利用可能にする
- [ ] 汎用Rule Engineを必要以上に導入しない最小Scopeを確定

## J-4. User Config / Distribution Config
- [ ] trackedな配布Defaultとユーザー編集Configを分離
- [ ] fresh clone / ZIPからの初回Config生成方法を確定
- [ ] ユーザーConfigを更新時に上書きしない方式を確定
- [ ] .gitignore / .gitattributesを新運用へ同期

## J-5. Numpad0 / Virtual000一般化
- [ ] 000キーなしを標準ケースとして扱う
- [ ] Virtual000無効時はZero Detectorを使用しない方式を検討
- [ ] Virtual000無効時のNumpad0即時処理を実現
- [ ] 000対応をopt-inとして維持する場合の仕様を確定

## J-6. 実装
- [ ] Metadata / Config Validatorを一般仕様へ変更
- [ ] Auto Bind Core / Preset境界を実装
- [ ] Public Default Configを作成
- [ ] Developer Workflow Preset / Exampleを作成
- [ ] User Config生成・読込方式を実装
- [ ] Virtual000 opt-in / Numpad0即時処理を実装

## J-7. Test / Migration
- [ ] Core Testと個人Workflow Testを分離
- [ ] Public Default Testを追加
- [ ] Config Migration Testを追加
- [ ] Developer Workflow Regression Testを追加
- [ ] Virtual000 ON/OFF Regressionを追加
- [ ] Startup Task Regressionを実施
- [ ] Public Default実機受入試験を実施

## J-8. Documentation / Release
- [ ] READMEを一般利用中心へ変更
- [ ] Migration Guideを作成
- [ ] Known Limitationsを同期
- [ ] CHANGELOGを更新
- [ ] Release Versionを決定
- [ ] Release前Regression / Public release auditを実施

Phase J完了条件:
- [ ] Public Defaultが特定アプリを必須としない
- [ ] 主要Slotが個人用途へコード固定されていない
- [ ] ユーザーConfigと配布Configが安全に分離されている
- [ ] 000なしテンキーで不要なZero Detector待機を発生させない
- [ ] 現行Developer WorkflowをPreset / Exampleで再現できる
- [ ] v0.2.xからの移行方法が明文化されている
- [ ] 自動テスト・実機受入・Startup RegressionがPASS
- [ ] 利用者向け・開発者向け文書が新仕様と整合

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
   ↓
Phase J  General-purpose Configuration / Public Default
```

## 最優先タスク

Phase A～Iは正式完了。Phase Jを次工程として新設した。

公開状態:

- Repository: **Public**
- 最新Release: **GitHub Releasesを参照**
- `v0.1.0`: 初回MVP Release
- `v0.2.0`: ログオン時自動起動追加
- `v0.2.1`: Release後ドキュメント同期

`v0.1.0` は自動起動実装前の初回MVP Release。自動起動を含む実装は `v0.2.0` としてRelease済み。

必要に応じた後続作業:

- [x] v0.2.0 Tag / GitHub Releaseを作成
- [ ] Public RepositoryのPrivate vulnerability reporting設定を確認
- [ ] GitHub Secret scanning alertを確認
- [ ] v0.2.x bugfix
- [ ] v0.3.0以降の機能拡張

---

# Public Release Preparation ✅ 完了

更新日: 2026-09-28

- [x] 現行Repository Treeの個人情報・秘密情報パターン監査
- [x] Commit author / committer email確認
- [x] 履歴上の誤commit Config backup確認
- [x] 削除済み重複PoCの秘密情報パターン確認
- [x] RuntimeにNetwork / Telemetry送信処理がないことを確認
- [x] MIT `LICENSE` を追加
- [x] `SECURITY.md` を追加
- [x] `CONTRIBUTING.md` を追加
- [x] `docs/PUBLIC_RELEASE_AUDIT.md` を追加
- [x] `.gitignore` を公開運用向けに強化
- [x] `.gitattributes` でUTF-16 Configの正規化を抑止
- [x] READMEをMIT / Privacy / Security / Contributing対応へ更新
- [x] 現行ドキュメントのLICENSE / private運用表記を同期

公開準備判定: **PASS**

GitHub Repository操作:

- [x] VisibilityをPrivateからPublicへ変更
- [x] Tag / Release `v0.1.0` を作成
- [ ] Private vulnerability reporting設定を確認
- [ ] Secret scanning alertを確認

監査詳細: [Public Release Audit](docs/PUBLIC_RELEASE_AUDIT.md)


---

# v0.2.0 - ログオン時自動起動統合 ✅ 実装・検証完了

v0.1.0のWindow Controller機能を維持したまま、Windowsログオン時の非表示・自動起動を追加した。

## 実装

- [x] Windows Task Schedulerを正式な自動起動方式として採用
- [x] 現在ユーザーのLogon Trigger
- [x] InteractiveToken / 通常権限
- [x] 既定Delay 0秒
- [x] 任意Delay秒
- [x] AutoHotkey v2自動検出
- [x] `-AutoHotkeyPath` による明示指定
- [x] AHK Script Path / Working Directoryの明示
- [x] 空白を含むPathの引用
- [x] 同名Taskの安全な登録・更新
- [x] Task Scheduler `IgnoreNew`
- [x] 本体 `#SingleInstance Force`
- [x] `scripts/install-startup-task.ps1`
- [x] `scripts/uninstall-startup-task.ps1`
- [x] Preview / PassThru
- [x] 未登録状態のuninstallを正常終了
- [x] 対象外Scheduled Taskを変更しない

## 検証

- [x] Preview / Path / Arguments: 24 assertions PASS
- [x] Task Scheduler Integration: 37 assertions PASS
- [x] Phase F Regression: 134 assertions PASS
- [x] 本番Task登録・更新・定義照合
- [x] Task Schedulerからの起動・常駐
- [x] 実際のサインアウト / ログオンによる自動起動
- [x] 自動起動後のWindow操作 / Virtual000 / NumLock lifecycle
- [x] 自動起動状態からの手動再起動で1インスタンス維持
- [x] Task無効化 / 削除後の次回ログオン非起動

詳細: [ログオン時自動起動テスト](docs/STARTUP_TASK_TEST.md)

## バージョン整理

- `v0.1.0`: 公開済み初回MVP。自動起動機能なし
- `v0.2.0`: ログオン時自動起動機能を追加したRelease
- `v0.2.1`: v0.2.0公開後のドキュメント同期Release
- 自動起動は後方互換のある機能追加のためMinor Versionを更新
