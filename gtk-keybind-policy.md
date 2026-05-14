# Linux / Firefox / GTK の不要ショートカット対策メモ

## 方針

この環境では、以下の方針を取る。

- Firefox は使い続ける
- Hyprland も使い続ける
- Chromium 系ブラウザへの移行は避ける
- GTK の不要な入力ショートカットは局所的に潰す
- 特に `Ctrl+;` による絵文字入力 UI は無効化する
- 必要に応じて Hyprland 側でキー入力を先に捕まえて、アプリへ渡さない

---

## 問題の概要

Linux 版 Firefox の検索バーや入力欄で `Ctrl+;` を押すと、絵文字入力画面が表示される。

これは以下ではない。

- Firefox 拡張機能
- IBus
- Fcitx
- SKK
- Hyprland 固有機能

原因は、Firefox が Linux 版で GTK を使っており、GTK の `GtkEntry` / `GtkTextView` 系の標準入力機能として絵文字入力が割り当てられているため。

特に GTK3 では、以下が絵文字入力に割り当てられている。

| キー | GTK 側の用途 |
|---|---|
| `Ctrl+.` | 絵文字入力 |
| `Ctrl+;` | 絵文字入力 |

---

## Firefox 側で絵文字入力 UI を無効化する

Firefox だけを対象にする場合は、まずこれを設定する。

Firefox のアドレスバーで以下を開く。

```text
about:config
````

次の設定を検索する。

```text
widget.gtk.native-emoji-dialog
```

値を `false` にする。

```text
widget.gtk.native-emoji-dialog = false
```

これにより、Firefox が GTK の native emoji dialog を呼び出さなくなる。

Firefox だけの問題として処理できるため、副作用が少ない。

---

## GTK3 側で絵文字ショートカットを無効化する

GTK3 アプリ全体で `Ctrl+;` / `Ctrl+.` を潰す場合は、以下を設定する。

```sh
mkdir -p ~/.config/gtk-3.0
vim ~/.config/gtk-3.0/gtk.css
```

以下を追加する。

```css
@binding-set DisableEmoji {
  unbind "<Control>semicolon";
  unbind "<Control>period";
}

entry, textview {
  -gtk-key-bindings: DisableEmoji;
}
```

Firefox を完全終了してから起動し直す。

```sh
pkill firefox
firefox
```

---

## `Ctrl+,` も潰したい場合

`Ctrl+,` も GTK3 側で殺したい場合は、`comma` も追加する。

```css
@binding-set DisableUnwantedGtkKeys {
  unbind "<Control>semicolon";
  unbind "<Control>period";
  unbind "<Control>comma";
}

entry, textview {
  -gtk-key-bindings: DisableUnwantedGtkKeys;
}
```

注意点として、絵文字入力として一般的に知られているのは `Ctrl+;` と `Ctrl+.`。
`Ctrl+,` はアプリ側で「設定」「preferences」などに使われることがあるため、GTK の絵文字入力そのものとは別扱いになる可能性がある。

---

## GTK4 について

GTK4 では GTK3 のような `-gtk-key-bindings` による制御がそのまま効くとは限らない。

GTK4 は以下の仕組みに寄っている。

* `GtkShortcutController`
* `GtkShortcut`
* action ベースのショートカット

そのため、GTK4 では GTK3 の `gtk.css` 方式で一括無効化するのは期待しすぎない方がよい。

一応、設定場所だけ作っておく。

```sh
mkdir -p ~/.config/gtk-4.0
touch ~/.config/gtk-4.0/gtk.css
```

ただし、GTK4 アプリのショートカットはアプリごとの実装に依存する可能性が高い。

---

## Hyprland 側で `Ctrl+;` / `Ctrl+.` を潰す

GTK や Firefox にキー入力が届く前に、Hyprland 側で横取りする方法。

`~/.config/hypr/hyprland.conf` または分割している rules / binds 用設定ファイルに以下を追加する。

```ini
# GTK emoji 対策
bind = CTRL, semicolon, exec, true
bind = CTRL, period, exec, true
```

`true` は何もしないコマンド。
Hyprland がこのキー入力を消費できれば、Firefox / GTK には届かない。

設定を再読み込みする。

```sh
hyprctl reload
```

確認する。

```sh
hyprctl binds | grep -Ei 'semicolon|period'
```

---

## `Ctrl+,` も Hyprland 側で潰す場合

```ini
# GTK / アプリ側に渡したくない Ctrl 系ショートカット
bind = CTRL, semicolon, exec, true
bind = CTRL, period, exec, true
bind = CTRL, comma, exec, true
```

確認。

```sh
hyprctl reload
hyprctl binds | grep -Ei 'semicolon|period|comma'
```

---

## キー名を確認する

Hyprland の key 名が分からない場合は `wev` を使う。

```sh
sudo pacman -S wev
wev
```

対象キーを押して、`keysym` を確認する。

よく使う名前は以下。

| キー  | Hyprland / keysym 名の例 |
| --- | --------------------- |
| `;` | `semicolon`           |
| `.` | `period`              |
| `,` | `comma`               |

---

## GTK / Firefox / Hyprland の優先順位

大まかな入力処理のイメージ。

```text
キーボード
  ↓
Wayland compositor / Hyprland
  ↓
アプリケーション
  ↓
Firefox
  ↓
GTK 入力処理
  ↓
Fcitx / IME など
```

Hyprland 側で bind して消費できれば、Firefox / GTK 側には届かない。

そのため、GTK の挙動を根本的に変えるより、Hyprland 側で横取りする方が確実な場合がある。

---

## 判明している GTK / Firefox 周辺のショートカット

現時点で把握しているもの。

| キー             | 由来                                 | 用途                      | 対応方針        |
| -------------- | ---------------------------------- | ----------------------- | ----------- |
| `Ctrl+;`       | GTK `GtkEntry` / `GtkTextView` 系   | 絵文字入力                   | 無効化対象       |
| `Ctrl+.`       | GTK `GtkEntry` / `GtkTextView` 系   | 絵文字入力                   | 無効化対象       |
| `Ctrl+,`       | アプリ側で使われることが多い                     | 設定 / Preferences など     | 必要なら無効化     |
| `Ctrl+Shift+I` | Firefox / GTK Inspector / DevTools | 開発者ツール、GTK Inspector    | 基本は残す       |
| `Ctrl+Shift+D` | GTK Inspector / Firefox ブックマーク系    | GTK Inspector またはブックマーク | 要確認         |
| `Ctrl+L`       | Firefox                            | アドレスバーへ移動               | 残す          |
| `Ctrl+T`       | Firefox                            | 新規タブ                    | 残す          |
| `Ctrl+W`       | Firefox                            | タブを閉じる                  | 残す          |
| `Ctrl+R`       | Firefox                            | 再読み込み                   | 残す          |
| `Ctrl+F`       | Firefox                            | ページ内検索                  | 残す          |
| `Ctrl+Q`       | Firefox / GTK アプリ                  | 終了                      | 必要なら別途無効化検討 |
| `Ctrl+S`       | Firefox / GTK アプリ                  | 保存                      | 残す          |
| `Ctrl+O`       | Firefox / GTK アプリ                  | 開く                      | 残す          |
| `Ctrl+P`       | Firefox / GTK アプリ                  | 印刷                      | 残す          |
| `Ctrl+A`       | Firefox / GTK 入力欄                  | 全選択                     | 残す          |
| `Ctrl+C`       | Firefox / GTK 入力欄                  | コピー                     | 残す          |
| `Ctrl+V`       | Firefox / GTK 入力欄                  | 貼り付け                    | 残す          |
| `Ctrl+X`       | Firefox / GTK 入力欄                  | 切り取り                    | 残す          |
| `Ctrl+Z`       | Firefox / GTK 入力欄                  | Undo                    | 残す          |
| `Ctrl+Y`       | Firefox / GTK 入力欄                  | Redo                    | 残す          |

---

## GTK のショートカット一覧を調べる

GTK はショートカットを一元管理していない。
そのため、完全な一覧を出す標準コマンドは期待しにくい。

現実的には `grep` で調べる。

```sh
grep -RInE '<Control>|<Ctrl>|Control|Ctrl|ctrl|CONTROL|semicolon|period|comma|emoji|insert-emoji' \
  /usr/share/gtk-3.0 \
  /usr/share/gtk-4.0 \
  /usr/share/themes \
  ~/.config/gtk-3.0 \
  ~/.config/gtk-4.0 \
  ~/.config/fcitx5 \
  ~/.config/hypr \
  ~/.config/i3 \
  2>/dev/null \
  | sort
```

スクリプト化する場合。

```sh
mkdir -p ~/bin

cat > ~/bin/list-ctrl-bindings <<'EOF'
#!/bin/sh

targets="
/usr/share/gtk-3.0
/usr/share/gtk-4.0
/usr/share/themes
$HOME/.config/gtk-3.0
$HOME/.config/gtk-4.0
$HOME/.config/fcitx5
$HOME/.config/hypr
$HOME/.config/i3
$HOME/.config/sway
"

grep -RInE \
  '(<Control>|<Ctrl>|Control|Ctrl|ctrl|CONTROL|semicolon|period|comma|emoji|insert-emoji)' \
  $targets 2>/dev/null \
  | sort
EOF

chmod +x ~/bin/list-ctrl-bindings
```

実行。

```sh
~/bin/list-ctrl-bindings | less
```

絵文字関連だけ見る。

```sh
~/bin/list-ctrl-bindings | grep -Ei 'emoji|semicolon|period|comma'
```

---

## Firefox を使い続ける理由

Chromium 系への一本化は避けたい。

現状、Linux で現実的に使えるブラウザは以下に偏っている。

| 系統               | 代表                                | 問題                        |
| ---------------- | --------------------------------- | ------------------------- |
| Gecko            | Firefox / LibreWolf               | Linux 版は GTK 依存がある        |
| Blink / Chromium | Chromium / Brave / Vivaldi / Edge | Chromium 独占に寄る            |
| WebKitGTK        | GNOME Web / Luakit                | GTK 依存が強い                 |
| QtWebEngine      | qutebrowser / Falkon              | GTK は避けやすいが中身は Chromium 系 |

そのため、非 Chromium かつ非 GTK で、日常利用に耐えるブラウザはほぼない。

現実的には以下の方針にする。

```text
Firefox / LibreWolf を使い続ける
GTK の嫌な挙動だけ局所的に潰す
必要なら Hyprland でキー入力を横取りする
```

---

## 推奨設定まとめ

### Firefox

```text
about:config

widget.gtk.native-emoji-dialog = false
```

### GTK3

```css
@binding-set DisableUnwantedGtkKeys {
  unbind "<Control>semicolon";
  unbind "<Control>period";
  unbind "<Control>comma";
}

entry, textview {
  -gtk-key-bindings: DisableUnwantedGtkKeys;
}
```

保存先。

```text
~/.config/gtk-3.0/gtk.css
```

### Hyprland

```ini
# GTK emoji / 不要 Ctrl ショートカット対策
bind = CTRL, semicolon, exec, true
bind = CTRL, period, exec, true
bind = CTRL, comma, exec, true
```

反映。

```sh
hyprctl reload
```

確認。

```sh
hyprctl binds | grep -Ei 'semicolon|period|comma'
```

---

## 運用方針

1. Firefox 側で `widget.gtk.native-emoji-dialog = false` を設定する
2. GTK3 側で `Ctrl+;` / `Ctrl+.` / `Ctrl+,` を unbind する
3. それでも漏れる場合は Hyprland 側で横取りする
4. 将来的に GTK4 アプリで同様の問題が出た場合は、アプリ個別の shortcut controller / action を確認する
5. Chromium 系への移行は避け、Firefox を維持する
