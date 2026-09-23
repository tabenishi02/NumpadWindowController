# Triple Zero Detection PoC

## 目的

このPoCは、テンキーの通常の `0` と、物理 `000` キーをソフトウェアで区別できるか確認するためのものです。

この実機では `000` が独立したVK/SCを持たず、次の入力を高速に送信します。

```text
Numpad0 Down
Numpad0 Up
Numpad0 Down
Numpad0 Up
Numpad0 Down
Numpad0 Up
```

実測では、この6イベントが概ね数十ms以内に完了しました。そのため初期判定窓を **80ms** としています。

## ファイル

```text
poc/
├─ TripleZeroDetectionPoC.ahk
├─ README.md
└─ logs/                       # 実行時に自動作成。Git管理対象外
   └─ triple_zero_poc.log
```

## 前提

- Windows 11
- AutoHotkey v2
- NumLock ON
- 対象キーの実測値:
  - VK: `60`
  - SC: `052`
  - Key: `Numpad0`

スクリプト起動時にNumLockをONへ設定します。

## 実行方法

`TripleZeroDetectionPoC.ahk` をAutoHotkey v2で実行します。

実行中は **SC052のNumpad0入力だけを抑止**します。したがって、テスト中に通常の `0` や `000` を押しても、アクティブなアプリへ数字の0は入力されません。

その他のキーは通常どおりアプリへ渡されます。

操作:

| 操作 | 動作 |
|---|---|
| `F9` | ログファイルを開く |
| `F8` | PoC内部状態をリセット |
| `Ctrl + Esc` | PoC終了 |

## 初期判定ルール

```text
最初のNumpad0 Down
        ↓
80msの判定窓
        ↓
D-U-D-U-D-U が80ms以内に完成
        ↓
TRIPLE_ZERO
```

別キーのDownが途中に入った場合は `INTERRUPTED` とします。

### 判定結果

| Result | 意味 |
|---|---|
| `TRIPLE_ZERO` | 000キー候補。D-U ×3 が80ms以内 |
| `SINGLE_ZERO` | 通常の0キー候補。80ms内のDownが1回 |
| `FAST_DOUBLE_ZERO` | 80ms内にDownが2回 |
| `AMBIGUOUS` | 3回以上だが000の厳密パターンではない等 |
| `INTERRUPTED` | 判定中に別キーが押された |

通常の0が80msより長く押されても、80ms時点でDownが1回だけなら `SINGLE_ZERO` と判定し、その後の物理Upまでキーリピートを無視します。

## 推奨テスト

以下をそれぞれ10～20回程度実行してください。

1. 通常の `0` を1回ずつ押す
2. `000` を1回ずつ押す
3. 通常の `0` を約1秒長押しする
4. 通常の `0` を人間の手で素早く3連打する
5. `0` の直後に別キーを押す

期待結果:

```text
通常0            -> SINGLE_ZERO
000              -> TRIPLE_ZERO
通常0長押し      -> SINGLE_ZERO（キーリピートは追加判定しない）
人力の0×3        -> 通常はSINGLE_ZEROが3回
途中に別キー     -> INTERRUPTED
```

## ログ例

```text
20260923163000 EVENT +0ms D Numpad0 vk=60 sc=052
20260923163000 EVENT +1ms U Numpad0 vk=60 sc=052
20260923163000 EVENT +18ms D Numpad0 vk=60 sc=052
20260923163000 EVENT +19ms U Numpad0 vk=60 sc=052
20260923163000 EVENT +37ms D Numpad0 vk=60 sc=052
20260923163000 EVENT +38ms U Numpad0 vk=60 sc=052
20260923163000 RESULT TRIPLE_ZERO pattern=DUDUDU downs=3 lastEvent=38ms
```

## 判定窓の調整

先頭の次の値を変更します。

```ahk
global DETECTION_WINDOW_MS := 80
```

000が `TRIPLE_ZERO` にならない場合は90～100msへ広げます。

人力3連打が誤って `TRIPLE_ZERO` になる場合は60～70msへ狭めます。

まず80msのまま複数回測定し、ログを確認してから変更してください。

## PoCの合格条件

最低限、次を満たせばNumpadWindowController本体で000を独立操作相当として利用可能と判断します。

- 000テストで `TRIPLE_ZERO` の取りこぼしがない
- 通常0で `TRIPLE_ZERO` の誤判定がない
- 0長押しで `TRIPLE_ZERO` の誤判定がない
- 人力3連打で実用上問題となる誤判定がない

このPoCでは判定だけを行い、Window切り替えやAuto Bindなどの本体機能は実行しません。
