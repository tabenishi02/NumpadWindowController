# Phase J - Public Default Physical Acceptance Test

更新日: 2026-09-29  
状態: **Complete / J-PA-7 Not Executed (hardware N/A)**  
対象: ConfigVersion 2 Public Default

## 1. 目的

Phase Jで追加した一般公開Defaultを、一般的な物理テンキーから操作して最終受入確認する。

自動Regressionでは確認済みのため、本試験では物理入力・操作感・実Window切り替えだけを確認する。

---

## 2. 事前準備

1. Repositoryを最新mainへ更新する。
2. 既存 `KeyBindings.ini` を残す必要がある場合はMigration Guideに従ってバックアップする。
3. Public Defaultで試験するため、必要なら現在Configを退避する。

```powershell
Copy-Item .\KeyBindings.ini .\KeyBindings.phasej-backup.ini -ErrorAction SilentlyContinue
Copy-Item .\KeyBindings.default.ini .\KeyBindings.ini -Force
```

4. `NumpadWindowController.ahk` を起動する。
5. 任意のWindow A / Bを2つ用意する。

---

## 3. J-PA-1 初回起動 / Config

手順:

1. `KeyBindings.ini` を一時的に削除または別名へ退避。
2. Controllerを起動。
3. Repository Rootを確認。

期待:

- `KeyBindings.ini` が自動生成される。
- 起動時Configuration Errorが出ない。
- Chrome / VS Code / ChatGPT / PowerShellが起動していなくても正常常駐する。

---

## 4. J-PA-2 Generic Manual Bind

手順:

1. Window AをActiveにする。
2. `Ctrl + Numpad7`。
3. Window Bへ移動する。
4. `Numpad7`。

期待:

- Window AがNumpad7へManual Bindされる。
- Numpad7単押しでWindow Aへ戻る。
- Chrome等のProcess制約はない。

同様にNumpad4 / Numpad1のいずれかでも任意Windowを登録できることを確認する。

---

## 5. J-PA-3 Slot Clear

手順:

1. Window AをNumpad7へBind。
2. `Ctrl + Shift + Numpad7`。
3. Numpad7を押す。

期待:

- Numpad7 BindingがClearされる。
- Public DefaultにはAuto Bindがないため、自動で別Windowへ再割り当てされない。

---

## 6. J-PA-4 Clear All

手順:

1. Numpad7とNumpad4へ別WindowをBind。
2. `Ctrl + Shift + NumpadEnter`。
3. Numpad7 / Numpad4を押す。

期待:

- 全BindingがClearされる。
- 自動再構築されない。

---

## 7. J-PA-5 Public Default Numpad0

前提:

`Key-Virtual000` がDisabledであること。

手順:

1. Window AをActive。
2. `Ctrl + Numpad0`。
3. Window Bへ移動。
4. Numpad0を複数回操作する。

期待:

- Numpad0でWindow Aへ移動できる。
- 従来000判定の約80ms待機を意識する遅延がない。
- 押下漏れ・二重発火がない。

---

## 8. J-PA-6 Virtual000 opt-in（000キー搭載テンキーのみ）

000キーを持たないテンキーではSKIP可能。

設定:

```ini
[Key-Virtual000]
Mode=Window
Label=Virtual 000
AllowedProcess=
AllowedClass=
AllowedTitleContains=
```

Controllerを再起動。

手順:

1. Window AをActive。
2. `Ctrl + 000`。
3. Window Bへ移動。
4. 000を押す。
5. 通常0も確認する。

期待:

- 000がVirtual000として1 Actionだけ発火する。
- Window Aへ移動できる。
- 通常0と000が従来仕様どおり区別される。

---

## 9. J-PA-7 NumLock lifecycle

### 判定

**Not Executed / N/A（対象テンキーの既知ハードウェア仕様）**

Phase F R-8 PoCで、この外付けテンキーの物理NumLockはAutoHotkey InputHook / Windows Raw Inputの双方へNumLock Keyboard Eventを送信しないことを確認済み。

物理NumLockキー自体はテンキー内部の入力切替として機能するため、テンキー側の入力モードとWindows側NumLock状態は独立している。

したがって、外付けテンキーのNumLockキーを使ってWindows側NumLock lifecycleを確認する試験は成立しない。

Windows側NumLock lifecycleについてはPhase F R-14で、通常Keyboard側NumLock / osk.exeを使用して以下を実機PASS済み。

- 起動前OFF → 実行中ON → 終了後OFF
- 起動前ON → 実行中ON → 終了後ON
- 実行中にWindows側NumLockを操作してもON固定

---

## 10. 合格条件

必須:

- [x] J-PA-1 PASS
- [x] J-PA-2 PASS
- [x] J-PA-3 PASS
- [x] J-PA-4 PASS
- [x] J-PA-5 PASS
- [x] J-PA-7 NOT EXECUTED / N/A — 対象テンキーのNumLockは内部入力切替で、Windows NumLock Eventを送らない既知仕様。Windows側lifecycleはPhase F R-14でPASS済み

000キー搭載機のみ:

- [x] J-PA-6 PASS または対象外としてSKIP記録

J-PA-1～6 PASS、J-PA-7は既知ハードウェア仕様によりNot Executed / N/Aとし、Phase Jの物理受入を完了とする。

### 10.1 1回目の試験結果

2026-09-29実施。

- J-PA-1～5: PASS
- J-PA-6: PASS
- J-PA-7: 当初FAIL記録
  - 外付けテンキーNumLockで「OFF」を作って確認したため、Windows側NumLock stateを試験できていなかった
  - Phase F R-8 / R-14の既存結果と照合し、対象テンキーの内部入力切替による既知ハードウェア仕様と確定
  - J-PA-7はNot Executed / N/Aへ再分類
  - 一時的に追加したNumLock workaroundは不要と判断してrevert済み

## 11. 試験後の復元

必要なら試験前Configへ戻す。

```powershell
Copy-Item .\KeyBindings.phasej-backup.ini .\KeyBindings.ini -Force
```

Controllerを再起動する。
