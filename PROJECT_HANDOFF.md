# PROJECT_HANDOFF

更新日: 2026-09-23  
対象: NumpadWindowController  
状態: 初期設計継続中 / 実装前

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

各物理キーは次のいずれかのModeを持つ。

- Window
- Shortcut
- Function
- Disabled

ShortcutキーはWindow Binding対象外。

`000` は独立キーとして識別できず、Numpad0を3回送信するためDisabled。

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
任意     使用不可 任意   任意
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

## 6. その他の既定Window

- 1: Explorer
- 2: ChatGPTデスクトップ
- 3: pwsh

実装時にProcess/Class等の正確な判別条件を確認する。ChatGPTデスクトップのProcess名は現時点で推測して固定しない。

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

Shortcut / Function / DisabledキーへのWindow Bindingは拒否する。

Auto Bind / Clear系の最終Hotkeyは未確定。

## 10. 次回以降の主要論点

1. NumLockの特別機能
2. Manual BindとAuto Bindの最終優先関係
3. Chrome座標判定のTolerance
4. マルチモニター時のChrome座標基準
5. VS Codeの「開いた順番」を取得・保持する具体的方法
6. Numpad1/2/3のAuto Bindをどこまで固定するか
7. 一般候補の優先順位
8. Auto Bind All / Clear等のHotkey
9. Shortcutの引数・Working Directory等
10. 設定ファイル形式
11. GUIの必要性

## 11. 次回開始時に読む資料

1. `PROJECT_HANDOFF.md`
2. `docs/DESIGN_DRAFT.md`
3. `TASKS.md`
4. `README.md`

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
実装タスク一覧を作成            ← 現在
  ↓
残りの設計論点を確定
  ↓
PoC
  ↓
実装
```
