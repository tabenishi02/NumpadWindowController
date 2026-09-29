# PROJECT_HANDOFF

更新日: 2026-09-29  
対象: NumpadWindowController  
状態: **Phase J実装・自動検証完了 / 物理受入 J-PA-7再試験pending**

## 現在地点

Phase A～IのMVP工程とv0.2.xのRelease作業は完了している。

Phase J - General-purpose Configuration / Public Defaultは、設計・実装・Migration・文書更新・自動Regression・公開差分監査まで完了した。

物理受入1回目では J-PA-1～6 がPASSし、J-PA-7 NumLock lifecycleのみFAILした。OFF状態から起動した際にNumLockがONへ遷移しなかったため、`NumLock_ForceOn()` を「Onへ明示遷移 → AlwaysOn」の順へ修正した。現在の残作業は **J-PA-7の再試験**。PASS後にPhase Jを正式Closeし、v0.3.0 Release判定へ進む。

現在のVersion / Release関係:

- Repository: **Public**
- 最新安定Release: GitHub Releasesを参照
- `v0.1.0`: 初回MVP Release
- `v0.2.0`: ログオン時自動起動追加
- `v0.2.1`: Release後ドキュメント同期
- 次期Release候補: **v0.3.0**
- License: MIT

## Phase Jの主要成果物

- `NumpadWindowController.ahk`: ConfigVersion 1 / 2両対応Core
- `KeyBindings.default.ini`: ConfigVersion 2 Public Default
- `KeyBindings.ini`: ローカルUser Config。Git管理対象外
- `examples/KeyBindings.example.ini`: ConfigVersion 2一般例
- `examples/KeyBindings.developer-workflow.ini`: v0.2.x相当のLegacy Developer Workflow
- `docs/PHASE_J_PLAN.md`: Phase J計画・進捗
- `docs/PHASE_J_RESULT.md`: Phase J実装・検証結果
- `docs/CONFIG_MIGRATION_V2.md`: ConfigVersion 1 → 2移行Guide
- `.github/workflows/phase-j-tests.yml`: Windows + AutoHotkey CI

## ConfigVersion 2 Public Core

Public Defaultでは1～9を含む通常Slotを特定アプリへ固定しない。

- Window / Shortcut / Disabledを選択可能
- Window ModeではAllowed条件を空欄にして任意WindowをManual Bind可能
- built-in Auto BindはOFF
- BackspaceはDisabled
- Virtual000はDisabled
- Numpad0は通常Hotkeyとして即時処理
- 特定のChrome / VS Code / ChatGPT / PowerShell環境を要求しない

User Configがない初回起動では:

```text
KeyBindings.default.ini
        ↓ copy
KeyBindings.ini
```

を自動生成する。既存User Configは上書きしない。

## Legacy Developer Workflow

従来の個人用WorkflowはConfigVersion 1として互換維持する。

```text
7 / 8 / 9 = Chrome
4 / 5 / 6 = VS Code
1 = Explorer
2 = ChatGPT Desktop
3 = PowerShell 7用Windows Terminal
```

使用する場合:

```powershell
Copy-Item .\examples\KeyBindings.developer-workflow.ini .\KeyBindings.ini -Force
```

旧Chrome座標Auto Bind、VS Code逆順Auto Bind、Lazy Auto Bind、Virtual000もこのProfileでRegression対象として維持している。

## 0 / 000

ConfigVersion 2 Public DefaultではVirtual000をDisabledとし、Zero Detectorを起動しない。

このため通常Numpad0に従来の最大約80ms判定待ちは発生しない。

Virtual000をWindow / Shortcutへ変更するとopt-inでZero Detectorへ切り替わり、従来どおり80ms以内の `D-U-D-U-D-U` をVirtual000として扱う。

## Configuration Encoding

Configuration INIはConfigVersionに関係なくUTF-8を前提とする。

Runtimeがサポートするのは:

- UTF-8 BOMなし
- UTF-8 BOMあり

のみ。UTF-16 LE / BEはサポートしない。配布INIはUTF-8 BOMなしへ統一した。

## 操作

| 操作 | 動作 |
|---|---|
| Key | Window Activate / Shortcut |
| Ctrl + Key | Manual Bind |
| Ctrl + Shift + Key | Slot Clear |
| Ctrl + Alt + Key | Auto Bind対応ProfileのみAuto Bind |
| Ctrl + NumpadEnter | Auto Bind All |
| Ctrl + Shift + NumpadEnter | Clear All |

## 自動起動

Windows Task Scheduler方式はPhase Jでも変更していない。

```powershell
.\scripts\install-startup-task.ps1
```

TaskはCurrent user / InteractiveToken / LeastPrivilegeで起動する。

## 検証状況

Phase J CI:

- Windows GitHub Actions runner
- AutoHotkey v2.0.28
- Controller Regression: **168 assertions PASS**
- NumLock OFF→ON Regression: PASS
- Startup Preview Regression: **24 assertions PASS**
- Startup Task Scheduler Integration Regression: **37 assertions PASS**
- ConfigVersion 2 Public Default: PASS
- ConfigVersion 1 Legacy Workflow: PASS
- Virtual000 ON / OFF Regression: PASS
- Config生成 / UTF-8読込 / UTF-16拒否: PASS

既存v0.2系検証履歴:

- Phase G: 65 / 65 PASS
- Phase H: 16 / 16 PASS
- Startup Integration: 37 assertions PASS
- 実ログオン / Task Scheduler運用試験: PASS

Phase J差分の公開監査:

- Credential / Secret: 検出なし
- 実ユーザー固有Path: 検出なし
- User ConfigはGit管理対象外へ変更済み

## Pending

物理受入1回目:

- [x] J-PA-1 初回起動 / Config
- [x] J-PA-2 Generic Manual Bind
- [x] J-PA-3 Slot Clear
- [x] J-PA-4 Clear All
- [x] J-PA-5 Public Default Numpad0
- [x] J-PA-6 Virtual000 opt-in
- [ ] J-PA-7 NumLock lifecycle — 初回FAIL、修正済み、再試験待ち

Phase J正式Close前に必要:

- [ ] J-PA-7を再試験してPASS
- [ ] Phase Jを正式Close
- [ ] v0.3.0 Release判定

## 次に読む資料

1. `README.md`
2. `docs/PHASE_J_RESULT.md`
3. `docs/CONFIG_MIGRATION_V2.md`
4. `docs/KNOWN_LIMITATIONS.md`
5. `docs/PUBLIC_RELEASE_AUDIT.md`
6. `CHANGELOG.md`

公開済みTagを後から移動して内容を書き換える運用は採用しない。
