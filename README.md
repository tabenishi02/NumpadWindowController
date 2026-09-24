# Numpad Window Controller

Windows上で、一般的なテンキーを「ウィンドウ直接切り替え＋ショートカット実行用コントローラー」として利用するためのツールです。

AutoHotkey v2を利用し、設定可能なテンキーキーに `Window / Shortcut / Disabled` の動作種別を割り当てます。Global操作はNumpadEnterのCtrl系Modifier Combinationへ予約します。

## 現在の段階

現在は **Phase F完了 / Phase Gテスト開始前** です。本体実装、自動検証、物理テンキーを使ったPhase F実機Smoke Testまで完了しています。次はChrome / VS Code等を含む網羅的なPhase G機能テストを行います。

- [Phase F実装・検証結果](docs/PHASE_F_RESULT.md)

- [MVP設計書](docs/MVP_DESIGN.md)
- [Phase A仕様](docs/PHASE_A_SPEC.md)
- [Phase B PoC手順](docs/PHASE_B_POC.md)
- [Phase B結果](docs/PHASE_B_RESULT.md)
- [Phase C仕様](docs/PHASE_C_SPEC.md)
- [Phase D仕様](docs/PHASE_D_SPEC.md)
- [Phase E仕様](docs/PHASE_E_SPEC.md)
- [暫定設計](docs/DESIGN_DRAFT.md)
- [設計引き継ぎ](PROJECT_HANDOFF.md)
- [実装タスク一覧](TASKS.md)
- [000キー識別PoC](poc/README.md)

## 起動と設定

AutoHotkey v2をインストールしたWindowsで、`NumpadWindowController.ahk`と`KeyBindings.ini`を同じDirectoryに置き、本体を起動してください。終了はトレイのAutoHotkeyアイコンからExitを選びます。PoCと同時には起動しないでください。

`KeyBindings.ini`はUTF-16 LE BOMを維持して編集し、反映には本体を再起動します。標準設定ではShortcutは未登録、BackspaceはDisabledです。詳細な設定形式とShortcut例は[Phase D仕様](docs/PHASE_D_SPEC.md)を参照してください。個人用Path等を含む実設定はコミットしないでください。

| 操作 | 動作 |
|---|---|
| Key | Window切替 / Shortcut起動 |
| Ctrl + Key | Active WindowをManual Bind |
| Ctrl + Shift + Key | Slot Clear |
| Ctrl + Alt + Key | 専用Slot / Groupの欠損補修 |
| Ctrl + NumpadEnter | 有効Bindingを維持してAuto Bind All |
| Ctrl + Shift + NumpadEnter | 全Binding解除 |

通常Keyboard Enterは `SC01C`、NumpadEnterは `SC11C` と実機確認済みで、Global操作はNumpadEnterだけを対象にします。

実行中はNumLockをON固定し、正常終了時に元の状態へ戻します。0/000判定中はSC052を消費し、未定義Modifier付き0も再送しません。通常の0入力を維持したい場合はNumpad0とVirtual000を両方Disabledにしてください。

検証は`.\tests\Run-PhaseFTests.ps1`で実行できます。デスクトップ操作を伴う確認と既知の制限は[Phase F検証結果](docs/PHASE_F_RESULT.md)に記載しています。

## 現時点の主要方針

- Windows 11
- AutoHotkey v2
- 一般的なUSBテンキーを利用
- 実機で確認したKey Name / VK / SCを設計資料に記録
- 設定可能キーは `Window / Shortcut / Disabled`。Ctrl+NumpadEnter / Ctrl+Shift+NumpadEnterは予約Global Combination
- Shortcut設定キーはWindow Binding対象外
- `000` キーは高速な `Numpad0` D-U×3を検出し、仮想キー `Virtual000` として利用
- `7 / 8 / 9` はChrome専用
- Chrome優先3ウィンドウは画面上の座標で自動割り当て
- `4 / 5 / 6` はVS Code専用
- VS Code優先3ウィンドウは未使用候補を逆列挙順で4→5→6へ簡易自動割り当て
- `1 / 2 / 3` の既定用途はExplorer / ChatGPTデスクトップ / pwsh
- 4つ目以降のChrome / VS Codeは自動割り当てせず、必要な場合だけ任意SlotへManual Bind
- HWNDはRuntime Bindingとして使用し、永続化しない
- Auto Bindは専用Slot 1～9の欠損補修のみ。任意SlotはManual専用
- ConfigはKeyBindings.ini（INI / ConfigVersion=1）。Auto Bind Groupはコード側固定
- MVP本体は単一AHKファイル。内部を責務Section / Prefix関数で分離
- 外付けテンキーのBackspaceは通常キーボードのBackspaceと区別できないため標準Disabled
- 通常利用では永続ログなし。必要時のみDebug Log
- 全Window Bindingを解除する機能を持つ
- Shortcutからアプリ起動やバッチファイル実行を行えるようにする

## 既定キー配置

```text
NumLock  /       *       -
未使用   任意    任意    任意

7        8       9       +
Chrome1  Chrome2 Chrome3 任意

4        5       6       Backspace
VSCode1  VSCode2 VSCode3 Disabled

1        2       3       Enter
Explorer ChatGPT pwsh    任意

0        000     .       Enter
任意     仮想キー 任意   任意
```

同じアプリを複数ウィンドウで使用する環境でも、個々のウィンドウへ直接ジャンプできることを主目的とします。
