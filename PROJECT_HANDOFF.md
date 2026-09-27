# PROJECT_HANDOFF

更新日: 2026-09-28  
対象: NumpadWindowController  
状態: **Phase I完了 / MVP v0.1.0 Release Ready**

## 現在地点

Phase A～Iまで完了。

- Phase F: 実装・自動試験・実機Regression完了
- Phase G: 65 / 65 PASS
- Phase H: 16 / 16 PASS
- Phase I: 初期版完成処理完了
- 現行バージョン: **v0.1.0**
- リリース判定: **Release Ready**
- FAIL / BLOCKED: なし

GitHub Tag / Releaseはまだ作成していない。

LICENSEは現在private運用のため未追加。public化する場合に公開方針と合わせて選定する。

---

## 現在の主要成果物

- `NumpadWindowController.ahk`: AutoHotkey v2本体
- `KeyBindings.ini`: 標準Config / UTF-16 LE BOM / ConfigVersion=1
- `examples/KeyBindings.example.ini`: 配布用サンプルConfig / UTF-16 LE BOM
- `README.md`: インストール・操作・設定例・Release Status
- `docs/MVP_DESIGN.md`: v0.1.0正式MVP設計
- `docs/DESIGN_DRAFT.md`: 旧Draftファイル名を維持した設計確定記録
- `docs/KNOWN_LIMITATIONS.md`: 現行Known Limitations集約
- `docs/PHASE_F_RESULT.md`: Phase F検証結果
- `docs/PHASE_G_RESULT.md`: Phase G機能テスト結果
- `docs/PHASE_H_RESULT.md`: Phase H実機受入試験結果
- `docs/PHASE_I_RESULT.md`: 初期版完成処理結果
- `TASKS.md`: Phase A～I完了状態
- `tests/PhaseF.Tests.ahk`: 自動テスト
- `tests/Run-PhaseFTests.ps1`: テスト実行入口

---

## v0.1.0の操作

| 操作 | 動作 |
|---|---|
| Key | Window Activate / Shortcut起動 |
| Ctrl + Key | Manual Bind |
| Ctrl + Shift + Key | Slot Clear |
| Ctrl + Alt + Key | Group / Slot Auto Bind |
| Ctrl + NumpadEnter | Auto Bind All |
| Ctrl + Shift + NumpadEnter | Clear All |

専用Slot:

- 7 / 8 / 9 = Chrome
- 4 / 5 / 6 = VS Code
- 1 = Explorer
- 2 = ChatGPT Desktop
- 3 = PowerShell 7用Windows Terminal

任意Slotは一般Window Auto Bindを行わずManual専用。

Backspaceは標準Disabled。

---

## Auto Bind要点

Auto Bindは専用Slot 1～9の欠損補修。

有効なManual / Auto Bindingは維持し、無効BindingだけNoneへ落として空Slotを補充する。

完全再構築:

```text
Ctrl + Shift + NumpadEnter
Ctrl + NumpadEnter
```

Chrome:

- Primary Monitor
- 新規分類はNormal Window
- 左上=7 / 左下=8 / 右大=9

VS Code:

- 未使用 `Code.exe` 候補
- `WinGetList` 逆順
- 空き4→5→6

4つ目以降のChrome / VS Codeは自動割り当てしない。

---

## Configuration要点

`KeyBindings.ini`:

- Scriptと同じDirectory
- UTF-16 LE BOM
- ConfigVersion=1
- Canonical 18 Key Section必須
- Mode = Window / Shortcut / Disabled
- Config Hot Reloadなし

専用SlotのAuto Bind属性はコード側Built-in Metadataへ固定。

Shortcut:

- exe / bat / cmd / lnk
- Arguments対応
- WorkingDirectory対応
- ps1直接Targetは禁止
- PowerShell Scriptは `pwsh.exe -File ...`

---

## 入力系要点

### NumpadEnter

Standard Enter=`SC01C`、NumpadEnter=`SC11C`。

Global ActionはNumpadEnterだけを対象にする。

### 0 / 000

物理000はSC052のD-U×3。

最初のDownから80ms以内の `D-U-D-U-D-U` を `Virtual000` とする。

同一Modifier状態の再DownはInterrupt対象外。

### NumLock

対象実機の物理NumLockはAHK InputHook / Raw Input双方でEventなし。

Controller Actionには使用しない。

Windows側NumLockは:

- Config Validation後に元状態保存
- 実行中ON固定
- 正常終了時復元

---

## Known Limitations

正本:

`docs/KNOWN_LIMITATIONS.md`

主要項目:

- Chrome新規Auto BindはPrimary Monitor基準
- Minimized / Maximized Chromeは新規座標分類しない
- VS Code真のOpen順非保証
- 4つ目以降のChrome / VS Code非Auto Bind
- 任意Slot Manual専用
- HWND非永続
- Config Hot Reloadなし
- Backspaceを通常Keyboardと区別できない
- Keyboard Device単位識別なし
- Background Retryなし
- 常設GUIなし

---

## テスト

基本:

```powershell
.\tests\Run-PhaseFTests.ps1
```

Desktop操作込み:

```powershell
.\tests\Run-PhaseFTests.ps1 -Desktop
```

Phase G / Hの実機結果は各Result文書を参照する。

---

## 次に読む資料

初期版を理解する場合:

1. `README.md`
2. `docs/MVP_DESIGN.md`
3. `docs/KNOWN_LIMITATIONS.md`
4. `docs/PHASE_I_RESULT.md`

実装詳細を追う場合:

1. `NumpadWindowController.ahk`
2. `docs/PHASE_E_SPEC.md`
3. `docs/PHASE_D_SPEC.md`
4. `docs/PHASE_C_SPEC.md`
5. `docs/PHASE_B_RESULT.md`

試験履歴:

1. `docs/PHASE_F_RESULT.md`
2. `docs/PHASE_G_RESULT.md`
3. `docs/PHASE_H_RESULT.md`
4. `docs/PHASE_I_RESULT.md`

---

## 次の任意タスク

MVP初期版完成後の任意作業:

- GitHub Tag `v0.1.0` 作成
- GitHub Release作成
- public化する場合のLICENSE選定
- v0.1.x bugfix
- v0.2.0機能拡張

これらはPhase I完了条件には含まれない。
