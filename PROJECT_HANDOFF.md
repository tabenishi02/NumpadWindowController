# PROJECT_HANDOFF

更新日: 2026-09-23  
対象: NumpadWindowController  
状態: 初期設計継続中 / 実装前

## 1. プロジェクト概要

一般的なUSBテンキーを、Windows上の複数ウィンドウへ直接切り替えるための専用コントローラーとして利用する。

特に、同一アプリを複数ウィンドウで使用する環境を重視する。

現在の主要ユースケース:

- Chromeを基本3ウィンドウで使用
- Chrome 3ウィンドウをテンキー `7 / 8 / 9` に1対1で割り当てる
- VS Codeを複数プロジェクトで使用
- VS Codeウィンドウを `4 / 5 / 6` に割り当てる
- その他のテンキーキーにも任意のウィンドウを登録可能にする
- 手動登録だけでなく、自動Bindingも行えるようにする

## 2. 技術方針

- Windows 11
- AutoHotkey v2
- 一般的なUSBテンキー
- Windowの実行中識別はHWND
- HWNDは永続化しない
- 永続ConfigurationとRuntime Bindingを分離する

## 3. 現時点の重要な設計方針

### Window Slot

テンキーの各物理キーをWindow Slotとして扱う。

Slotは以下を持つ想定:

- Key
- Label
- Allowed条件
- AutoBind設定
- Priority Rule
- HWND
- BindingSource

### 固定制約

- `Numpad7 / 8 / 9` → Chromeのみ
- `Numpad4 / 5 / 6` → VS Codeのみ
- その他 → 初期案では任意

### 手動Binding

```text
Ctrl + NumpadX
```

で、現在のアクティブウィンドウを対象Slotへ登録する。

SlotのAllowed条件に違反する場合は登録拒否。

### 通常操作

```text
NumpadX
```

で登録済みウィンドウへ切り替える。

最小化されていれば復元してActivateする。

### Auto Bind

Slotごとの条件とPriority Ruleを使用して、自動的にウィンドウをBindingする機能を持たせる。

候補条件:

- Process
- Window Class
- Title
- Monitor
- Position
- Size
- Z-order

### Clear

- 単一SlotのBinding解除
- 全SlotのBinding解除

の両方を持たせる。

Configuration自体はClearしない。

## 4. 操作ショートカットの状態

以下のうち、基本方針として比較的強いもの:

```text
NumpadX
  -> Slot XをActivate

Ctrl + NumpadX
  -> 現在のWindowをSlot Xへ手動Bind
```

以下は暫定案であり、変更前提:

```text
Ctrl + Alt + NumpadX
  -> Slot X Auto Bind

Ctrl + Shift + NumpadX
  -> Slot X Clear

Ctrl + Alt + NumpadEnter
  -> Auto Bind All

Ctrl + Alt + Shift + Numpad0
  -> Clear All
```

## 5. 次回の議論で重要な点

ユーザーは、現在の設計に変更したい点があると明示している。

そのため、次回は実装へ進まず、まず変更要求を受けて暫定設計を更新する。

特に確認・再設計候補:

1. テンキー各キーの最終用途
2. Hotkey体系
3. Manual / Auto Bindingの優先順位
4. Auto Bindのアルゴリズム
5. Priority Ruleの表現
6. Chrome 3ウィンドウの自動識別
7. VS Codeのプロジェクト識別方法
8. Clear Allの意味
9. 設定保存方式
10. GUIの必要性
11. NumLock OFFへの対応
12. 外付けテンキーのみを識別する必要性

## 6. 次回開始時に読む資料

1. `PROJECT_HANDOFF.md`
2. `docs/DESIGN_DRAFT.md`
3. `README.md`

## 7. 現在の段階

```text
プロジェクト立ち上げ
  ↓
初期ユースケース整理
  ↓
Window Slot方式を採用
  ↓
Chrome / VS Code制約を追加
  ↓
Auto Bind / Priority Rule案を追加
  ↓
GitHubへ暫定設計を保存  ← 現在
  ↓
設計変更点の議論
  ↓
仕様確定
  ↓
実装
```
