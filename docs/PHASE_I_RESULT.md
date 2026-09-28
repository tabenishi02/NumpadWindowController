# Phase I 初期版完成処理結果

更新日: 2026-09-28  
対象: NumpadWindowController / **v0.1.0**  
状態: **PASS - Phase I完了 / Release Ready**

## 1. 結論

Phase I「初期版完成処理」は完了した。

Phase A～Hで確定・検証した内容を、MVP初期版 **v0.1.0** として設計書、README、Configurationサンプル、Known Limitations、タスク管理、引き継ぎ情報へ反映した。

Phase F～Hの検証結果に未解決のFAIL / BLOCKEDはなく、Phase Iでは実装機能の追加変更を行っていない。

**v0.1.0は現在のKnown Limitationsを受け入れたMVP初期版としてRelease Readyと判断する。**

---

## 2. 完了した作業

### 2.1 設計書正式化

- `docs/DESIGN_DRAFT.md`
  - 旧Draftの未確定案を現行実装へ更新
  - ファイル名は既存リンク互換のため維持
  - 状態をFinalizedへ変更
- `docs/MVP_DESIGN.md`
  - `Review Required / 未実装` を解消
  - v0.1.0のFinal設計へ全面更新
- Phase A / C / D / E仕様書
  - `Adopted for Review` を `Implemented / Verified` へ変更

### 2.2 README完成

READMEへ次を整理した。

- 必要環境
- AutoHotkey v2導入
- Git clone / 配置
- 起動・終了
- 既定キー配置
- Window Mode操作
- Global Action
- Auto Bind
- Configuration
- Window / Shortcut / Disabled設定例
- Arguments / WorkingDirectory
- PowerShell Script実行例
- Backspace
- 0 / 000
- NumLock
- テスト
- バージョン
- Release Status
- License方針

### 2.3 Known Limitations集約

`docs/KNOWN_LIMITATIONS.md` を追加した。

Phase A～Hへ分散していた現行制限を一か所へまとめた。

主な内容:

- Chrome Primary Monitor制約
- Minimized / Maximized Chromeの新規分類制約
- VS Code真のOpen順非保証
- 4つ目以降のChrome / VS Code非Auto Bind
- 任意Slot Manual専用
- HWND非永続
- Config Hot Reloadなし
- Backspaceデバイス識別制約
- NumLock入力制約
- 0 / 000判定
- Shortcut制約
- Background Retryなし
- 常設GUIなし

### 2.4 サンプルConfiguration

`examples/KeyBindings.example.ini` を追加した。

- UTF-16 LE BOM
- ConfigVersion=1
- 18 Key Section
- Window Mode例
- Shortcut Mode例
- Disabled Mode例
- 専用Slotの標準Allowed条件

標準 `KeyBindings.ini` もUTF-16 LE BOMを維持したまま、Backspaceの旧誤認由来Labelを `Backspace` へ修正した。

### 2.5 バージョン

初期版の正式バージョンを:

```text
v0.1.0
```

とした。

今後はSemantic Versioning形式を使用する。

### 2.6 LICENSE

Phase I完了時点ではprivate運用だったためLICENSEを未追加とした。

その後、2026-09-28のPublic release preparationで方針を更新し、**MIT License** を採用して `LICENSE` を追加した。

現在のLicense状態についてはREADMEおよび `LICENSE` を正とする。

---

## 3. リリース判定根拠

### Phase F

- 本体実装完了
- 自動試験完了
- 実機Regression完了
- Phase F固有未解決事項なし

### Phase G

```text
65 / 65 PASS
```

- FAILなし
- BLOCKEDなし
- 新規Regression FAILなし

### Phase H

```text
16 / 16 PASS
```

- 日常操作シナリオPASS
- 操作感確認PASS
- 通常利用で追加操作なしに主要Windowへ安定して移動できる
- 実装修正要求なし

### Phase I

- 設計文書と現行実装を同期
- 利用者向けREADMEを完成
- Known Limitationsを集約
- 配布用Configサンプルを追加
- バージョンをv0.1.0へ確定
- LICENSE方針を判断

---

## 4. Phase Iで行っていないこと

次はPhase Iの「初期リリース可否判断」とは別操作のため実施していない。

- GitHub Tag `v0.1.0` の作成
- GitHub Releaseの作成
- Repositoryのpublic化
- 新機能実装

※ LICENSE追加はPhase I後のPublic release preparationで完了済み。

これらは必要になった時点で個別タスクとして実施する。

---

## 5. 最終判定

**PASS - Phase I完了**

**MVP v0.1.0: Release Ready**

Phase A～Iをもって、NumpadWindowControllerのMVP初期版完成工程を終了する。


---

## 6. Phase I後の公開準備追記

2026-09-28にPublic release preparationを実施した。

- MIT `LICENSE` 追加
- `SECURITY.md` / `CONTRIBUTING.md` 追加
- `docs/PUBLIC_RELEASE_AUDIT.md` 追加
- 個人情報・秘密情報パターン監査
- `.gitignore` / `.gitattributes` 公開向け整備
- READMEのPrivacy / Security / License更新

この追記はPhase I当時の判断履歴を保持しつつ、現在のPublic release状態を明確化するためのもの。


---

## 7. 現在のVersion状態

Phase Iはv0.1.0初期MVPを完成させた時点の履歴記録である。

その後の実際のRepository状態:

- RepositoryはPublic化済み
- `v0.1.0` Tag / GitHub Releaseは公開済み
- `v0.1.0` Tagは自動起動機能追加前のCommitを指す
- Windows Task Schedulerによるログオン時自動起動を後続実装として追加
- **v0.2.0 Tag / GitHub Releaseを公開済み**
- v0.2.0は自動起動機能を含む現行Release

v0.2.0の自動起動実装・検証については [STARTUP_TASK_TEST.md](STARTUP_TASK_TEST.md) を参照する。

このため、本書内の「Phase Iで行っていないこと」はPhase I完了時点の履歴であり、現在の未実施事項を意味しない。
