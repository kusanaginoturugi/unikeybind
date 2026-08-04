# libskk の `commit` と `commit-unhandled`

`libskk` (fcitx5-skk / ibus-skk が使うやつ) のキーマップで指定するコマンド。
キー押下時に preedit (変換中・確定待ちの文字列) をどう扱うかと、
押されたキーをアプリ側に流すかどうかが違う。

## 定義

- `commit`
  - 現在の preedit を確定する。
  - トリガーになったキーはそこで吸収する (アプリには渡さない)。
- `commit-unhandled`
  - 現在の preedit を確定する。
  - トリガーになったキーを unhandled としてアプリ側にも渡す。

preedit が空のときは、見た目はほぼ同じになる。
違いは「キーが消費されるか、アプリに届くか」だけ。

## 使い分けの典型例

- `Return` を `commit-unhandled`
  - 確定 + 改行をアプリにも送る。
  - メール送信・チャット送信・フォーム submit を 1 発で走らせたいとき。
- `Return` を `commit`
  - 確定だけ。改行はアプリに渡さない。
  - 確定と送信を分けたい派。
- `C-j` を `commit`
  - ddskk 作法。確定のみで同じ行に留まる。
- `Right` / `Left` を `commit-unhandled`
  - 確定 + カーソル移動をアプリ側で効かせたい場合に使う。
  - ただし送り仮名の伸縮 (`expand-preedit` / `shrink-preedit`) に当てる流派もある。

## chantaku-skk での実状況

`/home/onoue/.config/libskk/rules/chantaku-skk/keymap/` の構成。

### default.json

```json
{
  "define": {
    "keymap": {
      "C-g": "abort",
      "\n": "commit-unhandled",
      "C-j": "commit-unhandled",
      "\b": "delete",
      "C-h": "delete",
      "/": "abbrev",
      "\\": "abort",
      " ": "next-candidate",
      "\t": "complete",
      "C-i": "complete",
      ">": "special-midasi",
      "x": "previous-candidate",
      "X": "purge-candidate",
      "C-f": "expand-preedit",
      "C-b": "shrink-preedit",
      "Right": "expand-preedit",
      "Left": "shrink-preedit"
    }
  }
}
```

### モード別の `C-j` 上書き

| モード             | `C-j`              | 備考             |
| ------------------ | ------------------ | ---------------- |
| `default`          | `commit-unhandled` | ベース           |
| `hiragana`         | `commit`           | 上書き           |
| `katakana`         | `commit`           | 上書き           |
| `hankaku-katakana` | `commit`           | 上書き           |
| `latin`            | `commit-unhandled` | 上書きなし       |
| `wide-latin`       | `commit-unhandled` | 上書きなし       |

`Return` (`\n`) は全モードで `commit-unhandled` のまま統一。

### 読み取れる意図

- かな系 3 モードでは ddskk 作法に合わせて
  「`C-j` は確定のみ、改行はアプリに送らない」に統一している。
- `latin` / `wide-latin` は preedit がほぼ発生しないので、
  default のまま `commit-unhandled` でも実害なし
  (実質ただの素通しになる)。
- `Return` は確定 + 改行 1 発、という挙動を全モードで保証している。

### 別解

`default.json` の `C-j` を最初から `commit` にして、
`latin` / `wide-latin` 側でだけ `commit-unhandled` に戻す書き方もできる。
「ddskk 派の C-j」という意図がより前面に出る。
今の構成は「default は素通し寄り、かな系で締める」発想で、これはこれで一貫している。

## 参考メモ

- libskk のキーマップでコマンドが見つからない場合、`include` した親側の
  定義が効いていることが多いので、`include` チェーンを追うのが先。
- `commit-unhandled` は「確定したい、かつアプリ側にもキーを届けたい」
  という二段ロケット用途のためのもの、と覚えると判断しやすい。
