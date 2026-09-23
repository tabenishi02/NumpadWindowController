# Numpad Window Controller

Windows上で、一般的なテンキーを「ウィンドウ直接切り替え＋ショートカット実行用コントローラー」として利用するためのツールです。

AutoHotkey v2を利用し、テンキーの各キーに `Window / Shortcut / Function / Disabled` の動作種別を割り当てます。

## 現在の段階

現在は **Phase B実機検証完了 / Phase C設計前** です。本体実装はまだ開始していません。

- [MVP設計書](docs/MVP_DESIGN.md)
- [Phase A仕様](docs/PHASE_A_SPEC.md)
- [Phase B PoC手順](docs/PHASE_B_POC.md)
- [Phase B結果](docs/PHASE_B_RESULT.md)
- [暫定設計](docs/DESIGN_DRAFT.md)
- [設計引き継ぎ](PROJECT_HANDOFF.md)
- [実装タスク一覧](TASKS.md)
- [000キー識別PoC](poc/README.md)

> [!NOTE]
> 現在の設計は確定版ではありません。今後の議論で変更する前提の暫定スナップショットです。

## 現時点の主要方針

- Windows 11
- AutoHotkey v2
- 一般的なUSBテンキーを利用
- 実機で確認したKey Name / VK / SCを設計資料に記録
- キーごとに `Window / Shortcut / Function / Disabled` を設定
- Shortcut設定キーはWindow Binding対象外
- `000` キーは高速な `Numpad0` D-U×3を検出し、仮想キー `Virtual000` として利用
- `7 / 8 / 9` はChrome専用
- Chrome優先3ウィンドウは画面上の座標で自動割り当て
- `4 / 5 / 6` はVS Code専用
- VS Code優先3ウィンドウは開いた順に自動割り当て
- `1 / 2 / 3` の既定用途はExplorer / ChatGPTデスクトップ / pwsh
- 4つ目以降のChrome / VS Codeは一般候補として扱う
- HWNDはRuntime Bindingとして使用し、永続化しない
- 全Window Bindingを解除する機能を持つ
- Shortcutからアプリ起動やバッチファイル実行を行えるようにする

## 既定キー配置

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

同じアプリを複数ウィンドウで使用する環境でも、個々のウィンドウへ直接ジャンプできることを主目的とします。
