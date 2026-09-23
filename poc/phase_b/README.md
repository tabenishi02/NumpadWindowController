# Phase B PoCs

Phase BのWindow識別技術検証用PoCです。

詳細手順は [Phase B PoC Guide](../../docs/PHASE_B_POC.md) を参照してください。

## 実行順

1. `B1_WindowEnumerationPoC.ahk`
2. `B2_B4_ChromeLayoutPoC.ahk` を4ケース
3. `B5_VSCodeOrderPoC.ahk`
4. `B6_B8_TargetAppsPoC.ahk`

結果はすべて `results/` に出力されます。

`B5_VSCodeOrderPoC.ahk` 以外はSnapshot型で、実行すると結果TSVを開いて終了します。

B5だけは継続監視型で、`Ctrl + Esc` で終了します。

コードはAutoHotkey v2を前提とし、Phase Bの観測だけを行います。本体のWindow BindingやActivateは実行しません。
