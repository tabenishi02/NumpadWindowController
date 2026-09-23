# PROJECT_HANDOFF

更新日: 2026-09-23  
対象: NumpadWindowController  
状態: Phase A完了 / Phase B技術検証前 / 実装前

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

設定可能な通常キーは次のいずれかのModeを持つ。

- Window
- Shortcut
- Disabled

NumLockは通常Modeとは別の予約Global Function Keyとして扱う。

ShortcutキーはWindow Binding対象外。

`000` は独立VK/SCを持たないが、高速なNumpad0 D-U×3をPoCで識別できたため、論理キー `Virtual000` として正式採用する。

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
任意     仮想キー 任意   任意
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

Shortcut / DisabledキーへのWindow Bindingは拒否する。

Phase Aで以下を確定済み:

- `Ctrl + Shift + Key` -> Slot Clear
- `Ctrl + Alt + Key` -> 個別Auto Bind
- `NumLock` -> Auto Bind All
- `Ctrl + NumLock` -> Clear All

## 10. 次回以降の主要論点

Phase Aは完了済み。次はPhase Bの技術検証を行う。

1. 可視トップレベルWindow列挙
2. Chrome座標・サイズ識別
3. Chrome判定Tolerance
4. Primary Monitor / Work Area基準の検証
5. VS Code First Observed Orderの実現性
6. Explorer通常Windowの識別
7. ChatGPT DesktopのProcess / Class確認
8. PowerShell系Terminalの識別
9. 非表示 / Tool Window等の除外条件

## 11. 次回開始時に読む資料

1. `PROJECT_HANDOFF.md`
2. `docs/PHASE_A_SPEC.md`
3. `docs/MVP_DESIGN.md`
4. `TASKS.md`
5. `docs/DESIGN_DRAFT.md`
6. `README.md`

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
実装タスク一覧を作成
  ↓
Phase A 残仕様確定             ← 完了
  ↓
Phase B Window識別技術検証      ← 次
  ↓
Phase C以降
  ↓
実装
```


## 13. MVP設計レビュー

`docs/MVP_DESIGN.md` に、最低限動作する v0.1 を実装するための仕様を具体化した。実装はこの設計書のレビュー後に開始する。


## 14. Virtual000採用

物理 `000` が生成する高速な `Numpad0` D-U×3を80ms判定窓で識別し、内部では `Virtual000` として扱う。通常の `Numpad0` と分離し、`Window / Shortcut / Disabled` を設定可能とする。PoCでは通常使用時に誤認識なく動作した。


## 15. Phase A確定事項

詳細は `docs/PHASE_A_SPEC.md`。

- NumLock = Auto Bind All
- Ctrl+NumLock = Clear All
- Manual > Auto > None
- 1 HWND : 1 Slot
- 1/2/3 = Explorer / ChatGPT Desktop / PowerShell系Terminal専用
- 任意キー `/ * - + DEL 0 000 . Enter` は初期Window / AutoBind OFF
- Ctrl+Key = Manual Bind
- Ctrl+Shift+Key = Slot Clear
- Ctrl+Alt+Key = 個別Auto Bind
- Virtual000も通常論理キーと同一の操作体系
