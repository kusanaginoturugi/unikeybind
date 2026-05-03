# SKK / fcitx5 キー設定メモ

## 目的

fcitx5 + libskk で、SKKの入力モード切り替えキーを安定して使う。

xremap は IME 内部のキー処理までは制御しない。日本語入力中のキーは fcitx5 と libskk の設定を優先して調整する。

## libskk: latin からひらがなへ戻るキー

対象ルール:

```text
~/.config/libskk/rules/chantaku/
```

`latin` / `wide-latin` で `C-;` を `set-input-mode-hiragana` に割り当てる。

```json
{
  "keymap": {
    "latin": {
      "C-;": "set-input-mode-hiragana"
    }
  }
}
```

実際の確認コマンド:

```sh
rg 'C-;' ~/.config/libskk/rules/chantaku/keymap/
```

期待する状態:

```text
~/.config/libskk/rules/chantaku/keymap/latin.json
~/.config/libskk/rules/chantaku/keymap/wide-latin.json
```

上記2ファイルで `"C-;": "set-input-mode-hiragana"` になっている。

## `C-m` を避ける理由

`C-m` は端末・アプリ・IMEの各層で Return / Enter と同系統に扱われやすい。

libskk では `hiragana` / `katakana` / `hankaku-katakana` で `C-m` を `commit` に使い、`default` でも `commit-unhandled` にしているため、入力モード切り替え用途には使わない。

## fcitx5: Clipboard アドオンの衝突回避

fcitx5 の Clipboard アドオンは、デフォルトで `Control+semicolon` をクリップボード履歴のトリガーに使う。

SKK側で `C-;` を使う場合は、fcitx5 の Clipboard アドオンのトリガーキーを空にする。

GUIでの変更:

```text
fcitx5-configtool
  -> アドオン
  -> Clipboard
  -> Trigger Key を空にする
```

設定ファイル上の期待値:

```ini
# ~/.config/fcitx5/conf/clipboard.conf
TriggerKey=
PastePrimaryKey=
```

確認コマンド:

```sh
sed -n '1,20p' ~/.config/fcitx5/conf/clipboard.conf
```

変更後は fcitx5 を再起動する。

```sh
fcitx5 -r
```

## fcitx5: 入力モードをトレイに文字で表示する

SKK の入力モードは、切り替え時だけカーソル付近に一時表示される。常時見える場所に近い表示が欲しい場合は、fcitx5 の Classic User Interface のトレイアイコンを文字表示にする。

GUIでの変更:

```text
fcitx5-configtool
  -> アドオン
  -> Classic User Interface
  -> テキストアイコンを優先する
```

これにより、トレイの fcitx5 アイコンが通常のアイコン表示から `あ` などのテキスト表示に変わる。

設定ファイル上の期待値:

```ini
# ~/.config/fcitx5/conf/classicui.conf
PreferTextIcon=True
ShowLayoutNameInIcon=True
UseInputMethodLanguageToDisplayText=True
```

環境によっては KDE Input Method Panel 側にも同名設定がある。

```ini
# ~/.config/fcitx5/conf/kimpanel.conf
PreferTextIcon=True
```

変更が表示へ反映されない場合は、fcitx5 を再起動する。

```sh
fcitx5 -r
```

## 切り分けの観点

`C-;` でクリップボード履歴が出る場合は、まず fcitx5 の Clipboard アドオンを疑う。

DMS / Hyprland 側のクリップボード履歴とは別物。Hyprland の `dms ipc call clipboard toggle` バインドが無効でも、fcitx5 Clipboard アドオンの `Control+semicolon` は独立して発火する。
