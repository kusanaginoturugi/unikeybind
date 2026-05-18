# Firefox キーバインド衝突検討表

Firefox / Chromium で xremap によって潰す候補を検討するための対比表。

方針:

- ブラウザ全体を Global Emacs 対象にはしない
- `C-f` などブラウザで頻用する機能は残す
- 印刷、新規ウィンドウ、サイドバー表示など優先度の低いショートカットは Emacs 風操作で上書きする
- `j/k` など単キーvi操作は Vimium 等のブラウザ拡張に任せる

参考:

- [Mozilla Support: Keyboard shortcuts - Perform common Firefox tasks quickly](https://support.mozilla.org/en-US/kb/keyboard-shortcuts-perform-firefox-tasks-quickly)
- [Mozilla Support: Customize keyboard shortcuts in Firefox](https://support.mozilla.org/en-US/kb/customize-keyboard-shortcuts-firefox)

## 現在 xremap で上書き済み

| キー | Firefox 既定 | Emacs / vi 側の意味 | 現在の割当 | 判定 | メモ |
|---|---|---|---|---|---|
| `C-p` | 印刷 | Emacs: 上へ移動 | `up` | 上書き済み | 印刷はメニューからで十分 |
| `C-n` | 新規ウィンドウ | Emacs: 下へ移動 | `down` | 上書き済み | 新規ウィンドウより新規タブ `C-t` の方が主用途 |
| `C-b` | ブックマークサイドバー | Emacs: 左へ移動 | `left` | 上書き済み | サイドバーのトグル挙動が弱いので潰す |
| `C-a` | 全選択 | Emacs: 行頭へ移動 | `home` | 上書き済み | 入力欄でのEmacs挙動と整合。ページ全体の全選択は不要 |
| `C-e` | 検索バーへ移動系の代替、環境により検索関連 | Emacs: 行末へ移動 | `end` | 上書き済み | 実挙動の価値が低い。入力欄でのEmacs挙動と整合 |
| `C-h` | 履歴サイドバー | Emacs: Backspace | `backspace` | 上書き済み | 履歴はメニューや履歴ページでよい |
| `C-j` | ダウンロード | ASCII/Emacs: LF | `linefeed` | 上書き済み | ダウンロード一覧はショートカットで頻用する機能ではない |

## 次に検討する候補

| キー | Firefox 既定 | Emacs / vi 側の意味 | 推奨 | 理由 |
|---|---|---|---|---|
| `C-k` | アドレスバー/検索バーへ移動系 | Emacs: 行末まで削除 | 保留 | 誤爆時の破壊力が高い。実装もアプリ差が出やすい |
| `C-y` | Redo | Emacs: yank / paste | 保留 | Firefox既定ではRedo。貼り付けは `C-v` があるため上書き価値は低め |
| `C-m` | Enter相当 | ASCII/Emacs: CR / Return | 不要 | 既に近い意味なので上書き不要 |

## 残す優先度が高い Firefox ショートカット

| キー | Firefox 既定 | Emacs / vi 側の意味 | 判定 | 理由 |
|---|---|---|---|---|
| `C-f` | ページ内検索 | Emacs: 右へ移動 | 残す | ブラウザでは検索の利用頻度が高い |
| `C-l` | アドレスバーへ移動 | Emacs: 画面再描画 | 残す | URL入力/検索の入口として重要 |
| `C-r` | 再読み込み | Emacs: reverse search など | 残す | ブラウザ操作として重要 |
| `C-t` | 新規タブ | なし | 残す | ブラウザ操作として重要 |
| `C-w` | タブを閉じる | Emacs: kill-region系 | 残す | ブラウザ操作として重要 |
| `C-d` | このページをブックマーク | Emacs: delete-char | 残す寄り | ブックマーク操作として使う可能性あり。削除はBackspace/Deleteで代替可 |
| `C-s` | ページ保存 | Emacs: incremental search | 残す寄り | ブラウザ上では保存やWebアプリ側ショートカットと競合しやすい |
| `C-u` | ページソース表示 | Emacs: prefix / 上半ページ | 残す寄り | Vimium の `u` と役割が違う。xremapで潰す優先度は低い |
| `C-i` | ページ情報 | Tab相当 / Emacsでは補完系 | 残す寄り | `Tab` と絡みやすく、潰すと副作用が読みにくい |

## vi / Vimium 側に任せる操作

| 操作 | Vimium 例 | xremap でやらない理由 |
|---|---|---|
| 下/上スクロール | `j` / `k` | 入力欄やWebアプリのDOMフォーカス判定が必要 |
| 左/右スクロール | `h` / `l` | 同上 |
| ページ先頭/末尾 | `gg` / `G` | ブラウザ内DOMとの相性を拡張側が扱える |
| 半ページ移動 | `d` / `u` | ページ状態に依存するため拡張側が自然 |
| リンク選択 | `f` / `F` | DOM上のリンクヒント生成が必要 |
| ページ内検索 | `/` | Firefox既定の `C-f` と併用可能 |

## xremap 設定への反映候補

現在のブラウザ個別レイヤー:

```yaml
- name: Browser Emacs Navigation
  application:
    only:
      - firefox
      - chromium
  remap:
    C-p: up
    C-n: down
    C-b: left
    C-a: home
    C-e: end
    C-h: backspace
    C-j: linefeed
```

`C-j` は `enter` ではなく `linefeed` として扱う。`C-m` は Enter / Return 系として別に扱う。

`C-k` は便利だが、入力中の破壊力が高く、ブラウザ/Webアプリ側の挙動差も大きいため後回しにする。
