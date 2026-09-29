# Phase J - General-purpose Configuration / Public Default Result

更新日: 2026-09-29  
状態: **AUTOMATED PASS / Physical Acceptance Pending**  
次期Release候補: **v0.3.0**

## 1. 結果概要

Phase Jでは、v0.2.xまでユーザー本人の運用環境へ固定されていたConfiguration / Auto Bind設計を一般公開向けに分離した。

設計・実装・Config移行・自動Regression・Startup Regression・Documentation・公開差分監査は完了している。

残る完了条件はPublic Defaultを物理テンキーで操作する実機受入のみ。手順は `docs/PHASE_J_MANUAL_TEST.md` に固定した。

---

## 2. 確定した設計

### ConfigVersion 2

ConfigVersion 2を一般公開向けConfigurationとして追加した。

- 1～9を含む通常Slotは特定アプリへ固定しない
- 各SlotでWindow / Shortcut / Disabledを利用可能
- Window ModeのAllowed条件は任意
- built-in Auto BindはDefaultでOFF
- BackspaceはDefault Disabled
- Virtual000はDefault Disabled

ConfigVersion 1は削除せずLegacy Developer Workflowとして互換維持する。

### Core / Workflow分離

Built-in MetadataからChrome / VS Code / Explorer / ChatGPT / PowerShell用途を外した。

旧用途はConfigVersion 1を読み込んだ場合だけLegacy Metadataとして復元する。

これによりConfigVersion 2 Coreは特定アプリを要求しない。

### Public Default / User Config分離

配布側:

```text
KeyBindings.default.ini
```

User側:

```text
KeyBindings.ini
```

とした。

User Configが存在しない場合だけDefaultから自動生成する。User Configは `.gitignore` 対象で、Repository更新による上書きを避ける。

### Legacy Preset

旧個人用構成を:

```text
examples/KeyBindings.developer-workflow.ini
```

へ保存した。

Chrome / VS Code / Explorer / ChatGPT / PowerShell Auto Bindを引き続き再現できる。

### Numpad0 / Virtual000

Public DefaultではVirtual000をDisabledにした。

その場合:

- Zero Detectorを起動しない
- Numpad0は通常Hotkeyとして直接処理する
- 約80msの000識別待機は発生しない

Virtual000を有効化した場合だけNumpad0 / Virtual000をZero Detector経路へ切り替える。

### Encoding

ConfigVersion 2 TemplateはUTF-8へ変更した。

Runtimeは:

- UTF-8 BOMなし
- UTF-8 BOMあり
- UTF-16 LE BOM

を読み込めるため、既存ConfigVersion 1の互換性を維持する。

---

## 3. 主な実装変更

### NumpadWindowController.ahk

追加・変更:

- `Config_EnsureUserConfig()`
- `Config_ReadText()`
- ConfigVersion 1 / 2 Validation
- Legacy Group / SlotOrderの動的付与
- ConfigVersion 2ではDedicated制約を適用しない
- ConfigVersion 2ではGroup Allowed一致制約を適用しない
- Virtual000状態によるInputStrategy切り替え
- Auto Bind対象が存在しない場合のno-op処理

### Distribution Config

追加:

- `KeyBindings.default.ini`
- `examples/KeyBindings.developer-workflow.ini`

更新:

- `examples/KeyBindings.example.ini`
- `.gitignore`
- `.gitattributes`

削除:

- tracked root `KeyBindings.ini`

---

## 4. Regression Test

`tests/PhaseF.Tests.ahk` をPublic / Legacy両Profile対応へ拡張した。

確認内容:

- ConfigVersion 2 Public Default
- ConfigVersion 1 Legacy Workflow
- 旧Dedicated SlotのLegacy Validation
- ConfigVersion 2で旧Dedicated SlotをShortcutへ変更可能
- User Config初回生成
- UTF-8 Configuration
- UTF-16 LE Legacy Configuration
- Public Default built-in Auto Bindなし
- Legacy Auto Bind Regression
- Virtual000 Disabled時のNumpad0 direct hotkey
- Virtual000 opt-in時のZero Detector
- Numpad0 / Virtual000依存Validation

---

## 5. GitHub Actions検証

Windows GitHub Actions runnerへAutoHotkey v2.0.28を導入してRegressionを実行した。

結果:

```text
PASS 167 assertions (AHK 2.0.28)
PASS 24 startup-task assertions
PASS 37 startup-task assertions (Integration)
```

判定:

- Controller Regression: **PASS**
- ConfigVersion 2: **PASS**
- ConfigVersion 1 Compatibility: **PASS**
- Virtual000 ON / OFF: **PASS**
- Startup Preview Regression: **PASS**
- Startup Task Scheduler Integration Regression: **PASS**

---

## 6. 既存検証との関係

Phase Jでは既存Phase A～Iの試験記録を書き換えない。

v0.2系の既存検証:

- Phase G: 65 / 65 PASS
- Phase H: 16 / 16 PASS
- Startup Integration: 37 assertions PASS
- 実ログオン試験: PASS

は過去Release仕様の検証履歴として維持する。

ConfigVersion 1 Legacy Presetにより旧Workflowの互換Regressionも継続する。

---

## 7. Documentation

更新・追加済み:

- `README.md`
- `docs/PHASE_J_PLAN.md`
- `docs/CONFIG_MIGRATION_V2.md`
- `docs/PHASE_J_MANUAL_TEST.md`
- `docs/KNOWN_LIMITATIONS.md`
- `docs/PUBLIC_RELEASE_AUDIT.md`
- `CONTRIBUTING.md`
- `CHANGELOG.md`
- `TASKS.md`
- `PROJECT_HANDOFF.md`

---

## 8. Public Release Audit

Phase J差分について以下を再確認した。

- Credential / Token
- OpenAI-style secret
- password / token / api_key形式
- 実ユーザー固有Windows Path

結果:

**公開を妨げる秘密情報・個人情報は検出しなかった。**

User Configをtracked fileから外したため、今後の個人Path混入リスクも低減した。

---

## 9. Pending Physical Acceptance

このチャットから接続可能な実機PCがオフラインだったため、物理テンキー入力を伴う受入試験は実施できていない。

確認対象:

- [ ] Public Defaultで任意WindowをCtrl+KeyにManual Bindできる
- [ ] Key単押しでBinding先へActivateできる
- [ ] Ctrl+Shift+KeyでSlot Clearできる
- [ ] Ctrl+Shift+NumpadEnterでClear Allできる
- [ ] Virtual000 Disabled時にNumpad0が違和感なく即時反応する
- [ ] 必要に応じてVirtual000 opt-inが物理000キーで従来どおり動作する

---

## 10. 現在判定

```text
Design                 PASS
Implementation         PASS
Config Migration       PASS
Controller Regression  PASS (167 assertions)
Startup Preview         PASS (24 assertions)
Startup Integration     PASS (37 assertions)
Documentation          PASS
Public Delta Audit     PASS
Physical Acceptance    PENDING
```

したがってPhase Jは **実装・自動検証完了** とする。

ただしPhase Jの正式な最終完了判定とv0.3.0 Release Ready判定は、Public Defaultの物理テンキー受入PASS後に行う。
