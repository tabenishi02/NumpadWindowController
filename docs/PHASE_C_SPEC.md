# Numpad Window Controller - Phase C Specification

更新日: 2026-09-24  
対象: MVP / v0.1  
状態: Adopted for Review  
目的: Phase C「Auto Bindアルゴリズム確定」を完了し、Phase A / Bで確定した仕様を実装可能な処理手順へ落とし込む。

> 本書はAuto Bindアルゴリズムに関して `docs/MVP_DESIGN.md` より具体的な仕様として扱う。
> ユーザーレビューで変更指摘があった場合は、その指摘を優先して改訂する。

---

## 1. Phase Cの基本方針

MVPのAuto Bindは、全Windowを空きキーへ自動配分する機能にはしない。

Auto Bind対象は次の専用Slotだけとする。

| Group | Slot | 対象 |
|---|---|---|
| Chrome | 7 / 8 / 9 | Primary Monitor上のChrome 3Window |
| VS Code | 4 / 5 / 6 | Code.exe Window 最大3個 |
| Explorer | 1 | Explorer |
| ChatGPT | 2 | ChatGPT Desktop |
| PowerShell | 3 | PowerShell 7用Windows Terminal |

任意Slot:

`/ * - + DEL 0 000 . Enter`

はPhase Aどおり `AutoBind=OFF` とし、Auto Bindでは触らない。

4つ目以降のChrome / VS Codeやその他一般Windowは、自動では任意Slotへ入れない。

必要な場合だけManual Bindする。

---

# 2. C-1 Auto Bind処理順

## 2.1 Auto Bind Allの意味

`NumLock` のAuto Bind Allは「現在有効なBindingを全部並べ替える」処理ではなく、次の処理とする。

1. 現在Bindingを検証する。
2. 有効なManual Bindを維持する。
3. 有効なAuto Bindも維持する。
4. 無効なBindingだけNoneへ落とす。
5. 空いたAutoBind=ON Slotだけを補充する。

これにより、日常操作中にNumLockを押しても既存割り当てが不用意に入れ替わらない。

完全にAuto Bindを再構築したい場合は既存操作を使用する。

~~~text
Ctrl + NumLock
→ Clear All

NumLock
→ Auto Bind All
~~~

この場合はManual Bindも含めて全Runtime Bindingが消えるため、完全な初期再構築になる。

## 2.2 Binding ValidityとCandidate Eligibilityを分離する

既存Bindingを維持できるかの判定と、新規候補にできるかの判定は分ける。

### Existing Binding Validity

既存HWNDは最低限:

- HWNDがまだ存在する
- SlotのAllowed条件に一致する

なら有効とする。

既存Chrome Bindingについては、現在Minimized / Maximizedでも有効。

つまり「現在座標がChrome1/2/3閾値から外れた」という理由だけでは既存Bindingを解除しない。

### New Candidate Eligibility

新規Auto Bind候補はPhase Bの共通Filterを満たす必要がある。

- Visible
- DWM Cloakedではない
- Ownerなし
- ToolWindowではない
- Width / Height > 0
- Titleあり

さらに各Group固有条件を適用する。

Chromeだけは新規座標分類時に `MinMax=0` のNormal Windowを要求する。

## 2.3 Auto Bind All処理

推奨処理順:

~~~text
1. 現在Runtime Bindingを作業用Stateへコピー
2. 全BindingのValidity検証
3. 無効BindingをNoneへ変更
4. 有効BindingのHWNDをUsed HWND Setへ登録
5. AutoBind=ONの空Slotだけ抽出
6. Chrome Groupを補充
7. VS Code Groupを補充
8. Explorer Slotを補充
9. ChatGPT Slotを補充
10. PowerShell Slotを補充
11. 1 HWND : 1 Slotを最終検証
12. Runtime StateへCommit
~~~

実装中に予期しない例外が発生した場合、途中までRuntime Stateを書き換えないよう、可能な範囲で作業用State上で計算して最後にCommitする。

## 2.4 Group順序

Group順序は:

1. Chrome
2. VS Code
3. Explorer
4. ChatGPT
5. PowerShell

とする。

Phase Bで識別条件が互いにほぼ排他的であるため、この順序自体が結果へ大きく影響することはない。

既存設計との整合性を優先してChrome / VS Codeを先に処理する。

## 2.5 候補不足

候補数が空Slot数より少ない場合:

- 見つかった候補だけBinding
- 残りSlotはNone
- エラーにはしない

例:

~~~text
Chrome候補2個
→ 7 / 8だけBinding可能
→ 9はNone
~~~

どのSlotに入るかは各Group固有Ruleで決定する。

## 2.6 候補過多

候補数が専用Slot数より多い場合:

- 専用Slot数までAuto Bind
- 余剰候補は無視
- 任意Slotへ自動転送しない
- エラーにはしない

---

# 3. Group別Auto Bind

## 3.1 Chrome Group

対象Slot:

- 7 = Chrome1
- 8 = Chrome2
- 9 = Chrome3

処理:

1. 有効な既存7/8/9 Bindingを維持。
2. Used HWNDを除外。
3. `chrome.exe` の新規候補を抽出。
4. Primary Monitor上だけ残す。
5. `MinMax=0` のNormal Windowだけ残す。
6. Phase Bで確定した座標ThresholdでChrome1/2/3へ分類。
7. 空Slotにだけ割り当てる。
8. 同じ分類に複数候補がある場合はIdeal Rectangle Score最小を採用。

重要:

既存Binding済みChromeが移動・Minimize・Maximizeしても、そのHWNDが存在して `chrome.exe` のままならBindingは維持する。

座標は「新規割り当て時」だけ使う。

### Chrome SlotがManualで占有されている場合

Manual Bindingを固定し、そのSlotはAuto対象外。

例:

~~~text
7 = Chrome A (Manual)
8 = None
9 = None
~~~

の場合、Chrome Auto Bindは8 / 9だけ補充する。

Chrome AはUsed HWNDなので8 / 9候補にはならない。

---

## 3.2 VS Code Group

対象Slot:

- 4
- 5
- 6

処理:

1. 有効な既存4/5/6 Bindingを維持。
2. Used HWNDを除外。
3. `Code.exe` Windowを取得。
4. 未使用候補だけを `WinGetList` の列挙順から逆順にする。
5. 空Slotを `4 → 5 → 6` の順に取得。
6. 候補を先頭から空Slotへ割り当てる。
7. 4つ目以降の候補は無視。

厳密なOpen順は保証しない。

既存Bindingが有効なら、後のAuto Bind Allで再ソートしない。

例:

~~~text
4 = Project A (Auto)
5 = None
6 = Project C (Manual)

新規候補:
Project B
Project D
~~~

では、4と6を維持し、逆列挙順の先頭候補1個だけを5へ入れる。

残り候補は無視する。

---

## 3.3 Explorer Slot

Numpad1がNoneの場合だけ探索する。

条件:

- Process = `explorer.exe`
- Class = `CabinetWClass`

複数候補:

1. 非Minimizedを優先
2. 同条件ならZ-orderが前のWindowを優先

すべてMinimizedなら、その中でZ-orderが前の候補を使用してよい。

---

## 3.4 ChatGPT Slot

Numpad2がNoneの場合だけ探索する。

必須条件:

- Process = `ChatGPT.exe`

Class / TitleはMVPでは補助情報とし、必須条件にしない。

複数候補:

1. 非Minimizedを優先
2. 同条件ならZ-orderが前のWindowを優先

---

## 3.5 PowerShell Slot

Numpad3がNoneの場合だけ探索する。

条件:

- Process = `WindowsTerminal.exe`
- Class = `CASCADIA_HOSTING_WINDOW_CLASS`
- Title contains `PowerShell 7`

複数候補:

1. 非Minimizedを優先
2. 同条件ならZ-orderが前のWindowを優先

Title条件はPhase Dで `AllowedTitleContains` としてConfigurationへ持たせる。

Windows PowerShell / cmd.exeは対象外。

---

# 4. C-2 4つ目以降のChrome / VS Code

## 4.1 決定

4つ目以降のChrome / VS CodeはMVPではAuto Bindしない。

以前の「一般候補へ回して任意Slotへ自動配置する」案は不採用とする。

理由:

- Phase Aで任意SlotはManual専用と確定済み。
- 予期しないWindowが任意キーを占有することを避けたい。
- MVPのAuto Bindアルゴリズムを単純に保てる。
- 4つ目以降は利用頻度・用途が固定とは限らない。

## 4.2 利用したい場合

任意SlotへManual Bindする。

例:

~~~text
4つ目のChromeをActive
Ctrl + Numpad0
→ Numpad0へManual Bind
~~~

同じHWNDが専用Slotに存在する場合はPhase Aの重複Ruleに従い、旧Slotから移動する。

---

# 5. C-3 一般Windowの優先順位

## 5.1 決定

MVPでは「一般Window Auto Bind」自体を実装しない。

したがって:

- 一般Window間の優先順位
- 一般Windowの起動順
- Z-orderによる一般配分
- 任意Slotの自動使用順

は定義しない。

対象外Windowを使いたい場合はManual BindまたはShortcutを使用する。

## 5.2 専用1/2/3との関係

Explorer / ChatGPT / PowerShellは「一般Windowより先」という扱いではなく、それぞれ専用Slot 1 / 2 / 3だけのAuto Bind対象とする。

他の任意Slotへ自動的に流さない。

---

# 6. C-4 Lazy Auto Bind

## 6.1 発動条件

Window Modeかつ `AutoBind=ON` のキーを通常押下した時に、次のいずれかならLazy Auto Bindを実行する。

- BindingSource=None
- HWNDが存在しない
- HWNDがSlotのAllowed条件から外れた

Shortcut / DisabledではLazy Auto Bindしない。

AutoBind=OFFの任意Window SlotでもLazy Auto Bindしない。

## 6.2 無効Bindingの扱い

押下時に既存Bindingが無効と判定された場合:

1. 対象SlotのHWNDをclear
2. BindingSource=None
3. 対応するGroup / SlotのLazy Auto Bindを実行

## 6.3 Group単位

Chrome 7/8/9またはVS Code 4/5/6のいずれかからLazy Auto Bindが発動した場合、そのキー1つだけでなくGroup全体の空Slot補充を行う。

理由:

- Chromeでは候補重複防止が必要。
- VS Codeでは空Slot順と逆列挙順を一度に扱う方が決定的。
- 既存有効Bindingは維持するため、Group処理しても不要な再配置は起きない。

例:

~~~text
Numpad8押下
↓
8のHWNDが無効
↓
Chrome Group補充
↓
7/9の有効Bindingは維持
↓
8を再探索
↓
成功ならActivate
~~~

Numpad1 / 2 / 3は単一Slotだけ再探索する。

## 6.4 成功時

Lazy Auto Bindで対象Slotが埋まった場合:

1. BindingSource=Auto
2. 対象WindowがMinimizedならRestore
3. Activate

成功通知は通常表示しない。

## 6.5 失敗時

候補が見つからなければ:

- SlotはNoneのまま
- 他Slotを変更しない
- 短時間ToolTipで通知
- 自動Retryしない
- Timer / Background pollingを開始しない

通知例:

~~~text
No window found: Chrome2
~~~

次回通常押下、個別Auto Bind、Auto Bind Allのいずれかで再探索できる。

---

# 7. 個別Auto Bind

`Ctrl + Alt + Key` の仕様をPhase Cで具体化する。

## 7.1 Group Slot

Chrome / VS Codeキーの場合、対象Groupの「空Slot補充」を実行する。

~~~text
Ctrl + Alt + Numpad7
→ Chrome Group補充

Ctrl + Alt + Numpad5
→ VS Code Group補充
~~~

有効な既存Bindingは維持する。

## 7.2 Single Slot

1 / 2 / 3の場合、対象Slotだけ補充する。

## 7.3 AutoBind=OFF

任意Slotで `Ctrl + Alt + Key` を押してもAuto Bindは行わない。

ToolTip:

~~~text
Auto Bind disabled for this slot
~~~

と通知する。

---

# 8. Clearとの関係

## 8.1 Slot Clear後

~~~text
Ctrl + Shift + Key
~~~

でNoneになったSlotは、その場では再Bindingしない。

その後:

- 通常押下 → Lazy Auto Bind
- Ctrl + Alt + Key → 個別Auto Bind
- NumLock → Auto Bind All

のいずれかで補充可能。

## 8.2 Auto Bindingを意図的にやり直す方法

単一Slot / Group:

~~~text
Ctrl + Shift + Key
→ Clear
Ctrl + Alt + Key
→ Auto Bind
~~~

全体:

~~~text
Ctrl + NumLock
→ Clear All
NumLock
→ Auto Bind All
~~~

---

# 9. 1 HWND : 1 Slot保証

Auto Bind計算中はUsed HWND Setを使用する。

初期Used Set:

- 有効Manual Binding
- 有効Auto Binding

新しいBindingを確定するたびにHWNDをUsed Setへ追加する。

候補抽出時はUsed HWNDを除外する。

最後に重複がないことを検証してからRuntime StateへCommitする。

重複が検出された場合は実装上の内部エラーとして扱い、少なくとも新しい計算結果をCommitしない。

---

# 10. Runtime State更新方針

Auto Bind処理では、可能な限り次の形を採用する。

~~~text
Current Runtime State
        ↓ copy
Working State
        ↓ validate / fill
Final Validation
        ↓
Commit
~~~

これにより、候補列挙途中の失敗や内部例外でRuntime Bindingが半端な状態になることを避ける。

これは永続Transactionではなく、AHK内の一時Stateによる簡易なAtomic Updateとする。

---

# 11. Phase C確定事項まとめ

- Auto Bind対象は専用Slot 1～9だけ。
- 任意Slotは自動配分しない。
- Auto Bind Allは有効Manual / Auto Bindingを維持し、欠損だけ補充する。
- 完全再構築は `Ctrl+NumLock → NumLock`。
- Chromeは新規割り当て時だけ座標分類する。
- Binding済みChromeは移動 / Minimize / Maximizeしても維持する。
- VS Codeは未使用候補を逆列挙順で空き4→5→6へ補充する。
- 4つ目以降のChrome / VS Codeは無視し、必要ならManual Bind。
- 一般Window Auto Bindは実装しない。
- Lazy Auto Bindは対象Group / Slotだけ補充する。
- Lazy失敗時はNone + ToolTip、Background Retryなし。
- 1 HWND : 1 SlotはUsed HWND Set + Final Validationで保証する。
- Auto Bind結果はWorking Stateで計算後にCommitする。

---

# 12. 次工程への引き継ぎ

Phase DではConfiguration仕様を確定する。

Phase Cから必要となるConfiguration項目:

- Mode
- Label
- AllowedProcess
- AllowedClass
- AllowedTitleContains
- AutoBind
- AutoBindGroup
- Shortcut Target / Arguments / WorkingDirectory

MVPでは一般Window Auto Bindを採用しないため、汎用的な `AutoBindOrder` は必須ではない。

Chrome / VS Codeの割り当て順はコード側のGroup固有Ruleとして保持する。
