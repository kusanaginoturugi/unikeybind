# 端末の行編集とクリップボードメモ

kitty 上で見える `C-v` / `C-c` / `C-y` は、kitty 固有のショートカットではなく、端末ドライバや zsh の行編集が処理していることが多い。

## `C-v`: quoted-insert

`C-v` は多くの端末環境で quoted-insert / literal-next として扱われる。

1 回目の `C-v` は「次のキーを文字として入力する」待ち状態になるため、画面には何も出ない。続けて `C-v` を押すと、制御文字 `0x16` が入力され、端末上では `^V` と表示される。

確認:

```sh
stty -a | rg lnext
bindkey | rg '\\^V|quoted-insert'
```

実用例:

```text
C-v C-m  # CR 文字を入力する。画面上では ^M と見える
C-v Tab  # Tab 文字を入力する。画面上では ^I と見えることがある
C-v C-c  # 割り込みではなく ETX 制御文字を入力する
```

現代のシェルスクリプトでは `$'\r'` や `$'\t'` と書ける場面も多いが、対話中に制御文字そのものを入力したい場合は `C-v` が便利。

## `C-c`: interrupt

`C-c` は通常、端末ドライバの interrupt 文字で、フォアグラウンドプロセスに `SIGINT` を送る。

確認:

```sh
stty -a | rg intr
```

`C-v C-c` と入力すると、割り込みではなく `C-c` 相当の制御文字を入力できる。低レベルな検証以外では、普段は「実行中コマンドを止めるキー」として扱う。

## `C-y`: kill-ring から yank

zsh の Emacs 風行編集では、`C-y` は clipboard 貼り付けではなく yank。直近に kill した内容を zsh 内部の kill-ring / `CUTBUFFER` から戻す。

代表的な操作:

```text
C-k  カーソル位置から行末まで kill
C-u  行頭まで kill
C-w  直前の単語を kill
C-y  直近の kill を yank
M-y  kill-ring の過去候補に切り替え
```

確認:

```sh
bindkey | rg '\\^Y|yank|kill'
```

## kill-ring と clipboard

kill-ring / `CUTBUFFER` と Wayland clipboard は別物。

- `CUTBUFFER`: zsh の現在の行編集で使う一時バッファ
- kill-ring: zsh が保持する kill 履歴
- Wayland clipboard: `wl-copy` / `wl-paste` で扱うアプリ間共有クリップボード
- PRIMARY selection: 選択したテキストを一時的に保持する選択バッファ。中クリック貼り付け系の動作で使われることがある
- kitty の貼り付け: 通常は `Ctrl+Shift+V`

双方向同期は事故りやすい。kill-ring は「いま編集中のコマンドラインの一部を戻す」ための短命な編集状態で、clipboard はブラウザやエディタなど全アプリで共有される最後のコピー内容だから。

危険な例:

1. ブラウザで URL やトークンをコピーする
2. シェルで `C-k` する
3. 双方向同期により clipboard がコマンド断片で上書きされる、または `C-y` で秘密情報がプロンプトに入る

実用上は片方向が扱いやすい。この環境では「zsh で kill した内容を clipboard にも入れる」だけにする。`C-y` は zsh の yank のまま残し、通常の clipboard 貼り付けは kitty の `Ctrl+Shift+V` を使う。

`~/.zshrc` には以下の方針で設定する。

```zsh
if (( $+commands[wl-copy] )); then
    copy-cutbuffer-to-clipboard() {
        [[ -n $CUTBUFFER ]] && print -rn -- "$CUTBUFFER" | wl-copy
    }

    kill-line-copy-to-clipboard() {
        zle .kill-line
        copy-cutbuffer-to-clipboard
    }

    backward-kill-line-copy-to-clipboard() {
        zle .backward-kill-line
        copy-cutbuffer-to-clipboard
    }

    backward-kill-word-copy-to-clipboard() {
        zle .backward-kill-word
        copy-cutbuffer-to-clipboard
    }

    kill-word-copy-to-clipboard() {
        zle .kill-word
        copy-cutbuffer-to-clipboard
    }

    zle -N kill-line-copy-to-clipboard
    zle -N backward-kill-line-copy-to-clipboard
    zle -N backward-kill-word-copy-to-clipboard
    zle -N kill-word-copy-to-clipboard

    bindkey '^K' kill-line-copy-to-clipboard
    bindkey '^U' backward-kill-line-copy-to-clipboard
    bindkey '^W' backward-kill-word-copy-to-clipboard
    bindkey '^[d' kill-word-copy-to-clipboard
fi
```

## kitty の選択コピー

kitty では、マウスで範囲選択したテキストを自動で clipboard に入れられる。

```conf
copy_on_select clipboard
```

これにより、kitty 上でドラッグ選択した内容が通常の clipboard に入る。`Ctrl+Shift+C` を押さずに、他アプリや kitty 内で `Ctrl+Shift+V` などから貼り付けられる。

PRIMARY selection も同時に使う設定はある。

```conf
copy_on_select clipboard primary
```

ただしこの環境では `primary` は有効化しない。clipboard と PRIMARY の両方を更新すると、選択しただけで複数の貼り付け経路が変わり、意図しない貼り付けが増えるため。

注意点として、`copy_on_select clipboard` は範囲選択だけで clipboard を上書きする。ブラウザやエディタでコピーしていた内容は、kitty で少し選択しただけで置き換わる。この挙動が困る場合は以下に戻す。

```conf
copy_on_select no
```
