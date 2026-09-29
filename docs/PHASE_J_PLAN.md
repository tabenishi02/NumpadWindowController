# Phase J - General-purpose Configuration / Public Default

更新日: 2026-09-29
状態: **Implemented / Automated verification PASS / Physical acceptance pending**
対象: NumpadWindowController post-MVP public generalization

## 1. 目的

現行NumpadWindowControllerは、MVPとしてユーザー本人の運用環境を基準に設計されている。

特に次の要素は個人環境への依存が強い。

- 7 / 8 / 9 = Chrome
- 4 / 5 / 6 = VS Code
- 1 = Explorer
- 2 = ChatGPT Desktop
- 3 = PowerShell 7用Windows Terminal
- Chrome 3Windowの座標ベースAuto Bind
- VS Code専用の列挙順Auto Bind
- 専用Slot 1～9をWindow Modeへ固定するValidation
- 物理000キーを前提としたVirtual000の標準有効化

Phase Jでは、これらをNumpadWindowController Coreから分離し、特定アプリや特定Window配置を必要としない一般公開向けConfiguration / Defaultを設計・実装・検証する。

既存v0.2.xの動作記録は履歴として維持し、過去Phase A～Iの仕様書・試験結果を後から一般向け仕様へ書き換えない。

---

## 2. 基本方針

1. **Coreと個人用Workflowを分離する**
   - Controller Coreは特定アプリ名や個人のWindow配置を前提にしない。
   - 現在のChrome / VS Code / Explorer / ChatGPT / PowerShell構成はPreset / Exampleとして維持可能にする。

2. **初回利用時に特定アプリを要求しない**
   - 一般公開Defaultだけで任意WindowのManual Bindを開始できる構成を目標とする。

3. **高度な自動化をDefault必須要件にしない**
   - Auto Bind一般化のためだけに大規模な汎用Rule Engineを導入しない。

4. **既存ユーザーの移行経路を用意する**
   - 現行ConfigVersion=1と現在のDeveloper Workflowを失わずに移行できる方法を定義する。

5. **現行Releaseと開発中仕様を混同しない**
   - Phase J完了まではv0.2.xの挙動を現行Release仕様として扱う。

---

## 3. J-1 Public Default仕様

- [x] 一般公開Defaultのキー配置を確定する
- [x] 1～9を含む各Slotについて、特定アプリ非依存の初期Modeを決定する
- [x] 任意WindowをManual Bindできる構成をDefaultの中心にするか確定する
- [x] Backspaceの安全な既定値を確認する
- [x] Virtual000を標準有効にするかopt-inにするか確定する
- [x] Chrome / VS Code / ChatGPT / PowerShell等がなくても正常利用できることを要件化する

## 4. J-2 Configuration一般化

- [x] 物理キーMetadataと用途Metadataを分離する
- [x] `Dedicated` 固定属性の扱いを見直す
- [x] 専用Slot 1～9の `Mode=Window` 強制を廃止またはConfig駆動へ変更する
- [x] Chrome 7/8/9・VS Code 4/5/6のAllowed条件同一強制を一般Configから分離する
- [x] Numpad1 / Numpad3専用のRequired Allowed条件を一般Configから分離する
- [x] Auto Bind設定をConfigへ持たせるかPreset層へ分離するか決定する
- [x] ConfigVersion更新要否とConfigVersion=1からのMigration方針を決定する
- [x] UTF-16 LE BOM固定を維持するか、UTF-8対応を追加するか判断する

## 5. J-3 Auto Bind / Preset分離

- [x] `Chrome / VSCode / Explorer / ChatGPT / PowerShell` 固定GroupをCoreから分離する
- [x] `AutoBind_Calculate()` の固定Group列挙を見直す
- [x] Chrome専用座標スコア処理とPrimary Monitor固定WorkflowをCore必須仕様から外す
- [x] VS Code専用逆順列挙ロジックをCore必須仕様から外す
- [x] 現在の個人用WorkflowをPreset / Exampleとして維持する方法を決定する
- [x] Generic Auto Bindを実装する場合の最小Scopeを決定し、不要なRule Engine化を避ける

## 6. J-4 User Configと配布Configの分離

- [x] trackedな配布Default / Templateとユーザー編集Configを分離する
- [x] `KeyBindings.ini` をGit管理対象のまま維持するか見直す
- [x] `KeyBindings.default.ini` / `KeyBindings.example.ini` 等の役割を整理する
- [x] fresh clone / ZIP展開後の初回Config生成方法を決定する
- [x] Config更新時にユーザー編集内容を上書きしない方式を確定する
- [x] `.gitignore` / `.gitattributes` を新Config運用へ同期する

## 7. J-5 Numpad0 / Virtual000一般化

- [x] 000キーを持たない一般的なテンキーを標準ケースとして扱う
- [x] Virtual000無効時はZero Detectorを起動しない構成を検討する
- [x] Virtual000無効時のNumpad0を通常Hotkeyとして即時処理できるようにする
- [x] 通常Numpad0へ不要な最大約80ms待機を発生させない
- [x] 000対応をopt-in機能として残す場合のConfig / Documentationを定義する
- [x] Numpad0 / Virtual000依存Validationを新仕様へ合わせて更新する

## 8. J-6 実装

- [x] `Config_Metadata()` の個人用途固定を解消する
- [x] Config Validatorを一般仕様へ変更する
- [x] Auto Bind Core / Preset境界を実装する
- [x] Public Default Configを作成する
- [x] Developer Workflow Preset / Exampleを作成する
- [x] User Config生成・読込方式を実装する
- [x] Virtual000 opt-in / Numpad0即時処理を実装する
- [x] Startup Taskとの互換性を維持する

## 9. J-7 Test / Migration

- [x] CoreテストからChrome / VS Code等の個人Workflow依存を分離する
- [x] 一般Public Defaultの自動テストを追加する
- [x] 任意SlotでWindow / Shortcut / Disabledを利用できることを確認する
- [x] ConfigVersion Migration Testを追加する
- [x] Developer Workflow PresetのRegression Testを追加する
- [x] Virtual000無効時のNumpad0即時処理を確認する
- [x] Virtual000有効時の既存000判定Regressionを確認する
- [x] Task Scheduler自動起動Regressionを確認する
- [ ] 実機テンキーでPublic Default受入試験を実施する（Physical acceptance pending）

## 10. J-8 Documentation / Release Preparation

- [x] READMEの主説明を一般的なWindow Controller中心へ変更する
- [x] Chrome / VS Code等の現行構成をPreset / Exampleとして説明する
- [x] Public Defaultのキー配置をREADMEへ反映する
- [x] Config Migration Guideを作成する
- [x] Known Limitationsを新仕様へ同期する
- [x] Phase C / Dの旧仕様は履歴として維持し、新仕様側から変更点を明示する
- [x] PROJECT_HANDOFF.md / CHANGELOGを更新する
- [x] Release Versionを決定する
- [x] Release前Regression / Public release auditを実施する

## 11. Phase J完了条件

- [x] Public DefaultがChrome / VS Code / ChatGPT Desktop / PowerShell 7等を必須としない
- [x] fresh clone / Release ZIPから一般ユーザーが個人Configを安全に作成・利用できる
- [x] 1～9を含む主要Slotが個人用Dedicated用途へコード固定されていない
- [x] 000キーなしでも不要なZero Detector負荷・待機を発生させない
- [x] 現在のDeveloper WorkflowをPreset / Example等で再現できる
- [x] 既存v0.2.xからの移行方法が明文化されている
- [ ] 自動テスト・Startup RegressionはPASS。Public Default実機受入のみpending
- [x] README / TASKS / PROJECT_HANDOFF / Known Limitations / CHANGELOGが新仕様と整合する

## 12. Phase J開始時の最初の作業

最初に **J-1 Public Default仕様** と **J-2 Configuration一般化** を設計し、次を確定する。

1. 一般公開Defaultのキー配置
2. Dedicated Slot廃止後のMetadata構造
3. Auto BindをConfig / Presetのどちらへ置くか
4. ConfigVersion / Migration
5. Virtual000のDefault
6. User Configと配布Configの分離方式

上記6項目は確定済み。実装・自動Regression・文書更新・Phase J差分監査まで完了した。正式なPhase J完了判定はPublic Defaultの物理テンキー受入後に行う。
