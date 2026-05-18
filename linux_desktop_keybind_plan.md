# Linuxデスクトップ大統一キーバインド構想：計画書（xremap版）

## 1. 構想の背景と目的

Linuxデスクトップのキーバインド統一を目的とする。以下の二大原則に基づく。

- **入力系（エディットモード）**: Emacsキーバインドに統一
- **ビューア系（ナビゲーションモード）**: viキーバインドに統一

## 2. 技術選定：なぜ `xremap` なのか

当初 `keyd` を検討したが、アプリ別コンテキスト切り替えに使う `keyd-application-mapper` がWaylandネイティブウィンドウを検出できないことが判明（X11の `xprop` 依存、GitHub issue #694 [https://github.com/rvaiya/keyd/issues/694]）。

Hyprland（pure Wayland）環境では `keyd` はグローバルリマップのみ有効で、Phase 2以降の実現手段がない。

**`xremap` を採用する理由:**
- evdev/uinput ベースで動作し、Wayland/X11 どちらでも有効
- Hyprland のウィンドウ情報を直接取得できる（`--features hypr` ビルド）
- YAML設定でアプリ別プロファイルを記述可能
- Rust製、アクティブ開発中

起動管理は Hyprland の `exec-once` ではなく、systemd user service を本線とする。失敗時の自動復帰、明示的な再起動、ログ確認、Hyprland設定との責務分離がしやすいため。

### アーキテクチャ

```
物理キーボード (QMK)
    ↓  ファームウェアレベルのリマップ（OS非依存）
evdev
    ↓
xremap デーモン（systemd user service）
    ↓  アプリ別コンテキスト + グローバルEmacs/viバインド
各アプリケーション
```

## 3. 除外対象（パススルーリスト）

以下のアプリはアプリ本来のキーバインドを優先する。

CapsLock の Ctrl/Esc 化はOS全体の基本操作として残し、`C-p` などの編集キーや単キーvi操作だけを除外する。

| アプリ | 理由 |
|---|---|
| `emacs` | 独自Emacsバインドを持つ |
| `kitty` / `dropdown` / `alacritty` / `foot` | ターミナル内のシェル・アプリが独自バインドを持つ |
| `firefox` / `chromium` | `C-f` などブラウザ固有ショートカットとの競合が大きい |
| `code-oss` | エディタ固有ショートカットとの競合が大きい |
| `org.remmina.Remmina` / `qemu` / 仮想マシン | リモート・ゲストOSへキーをそのまま渡す必要がある |

fcitx5がアクティブ（日本語入力中）のとき、IMEのキーハンドリングが優先される場合がある。その挙動はアプリや入力メソッド側に依存するため、xremap側では原則として制御しない。

## 4. 実装ロードマップ

### Phase 1: グローバルEmacsレイヤー

全アプリ共通（除外リスト除く）のEmacsバインド。

```yaml
modmap:
  - name: CapsLock as Ctrl/Esc
    remap:
      CapsLock:
        held: LeftControl
        alone: Escape

keymap:
  - name: Global Emacs
    application:
      not: [emacs, kitty, dropdown, alacritty, foot, firefox, chromium, code-oss, org.remmina.Remmina, qemu]
    remap:
      C-p: up
      C-n: down
      C-b: left
      C-f: right
      C-a: home
      C-e: end
      C-h: backspace
      C-m: enter
```

`C-k`（行末削除）は実装が複雑なため、Phase 1では保留。ターゲットアプリごとに動作確認後に追加する。

ブラウザは `C-f` など固有ショートカットとの競合が大きいため、Global Emacs からは除外する。ただし `C-p` の印刷、`C-n` の新規ウィンドウ、`C-b` のブックマークサイドバー、`C-a` の全選択、`C-e` の検索系代替、`C-h` の履歴表示、`C-j` のダウンロード一覧は日常操作として優先度が低いため、Firefox / Chromium ではEmacs風の移動・削除・LFだけを個別に有効化する。

```yaml
keymap:
  - name: Browser Emacs Navigation
    application:
      only: [firefox, chromium]
    remap:
      C-p: up
      C-n: down
      C-b: left
      C-a: home
      C-e: end
      C-h: backspace
      C-j: linefeed
```

### Phase 2: アプリ別viレイヤー（Contextual vi）

PDFビューア・ファイルマネージャなど、入力フォームの少ないビューア系アプリがアクティブなとき、単キーでvi操作を有効化。

ブラウザ内の入力欄やWebアプリでは干渉しやすいため、Firefox / Chromium は xremap の単キーvi対象にしない。ブラウザの `j/k` スクロールは Vimium 等の拡張に任せる。

```yaml
keymap:
  - name: Viewer vi
    application:
      only: [zathura, org.pwmt.zathura, thunar, org.gnome.Nautilus]
    remap:
      j: down
      k: up
      h: left
      l: right
      g: C-home
      Shift-g: C-end
      u: pageup
      d: pagedown
      slash: C-f
```

### Phase 3: モーダル制御の洗練

入力フォームにフォーカスがあるとき（`<input>`, `<textarea>`）はviバインドを自動無効化したいが、xremap単体ではDOMフォーカスを見られない。ブラウザでは Vimium 等に任せ、xremap はアプリ単位で安全に適用できる範囲に絞る。

必要であれば xremap の `mode` 機能で手動トグルを作る。ただし、モード状態が見えないと誤操作が増えるため、Phase 1/2の安定後に扱う。

## 5. セットアップ

→ [`xremap_setup.md`](xremap_setup.md)

## 6. 今後の課題

1. **Phase 2のWindow class一覧整備**: 対象アプリのクラス名を `hyprctl` でリストアップ
2. **C-k の実装方法検討**: xremap のマクロ機能で実現可能か検証
3. **Windows 11との筋肉記憶統一**: AutoHotkey等との対照表を作る
4. **QMKとの役割分担明確化**: どこまでをQMKで、どこからをxremapで担うかを決める
5. **実機検証ログの作成**: アプリ別に「効く/干渉する/除外する」を記録する

---

**参考:**
- [xremap GitHub](https://github.com/xremap/xremap)
- [keyd GitHub](https://github.com/rvaiya/keyd)（グローバルリマップの参考として）
- アーカイブ: `linux_desktop_keybind_plan_archive_keyd.md`（keyd案）
