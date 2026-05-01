# Linuxデスクトップ大統一キーバインド構想：計画書（xremap版）

## 1. 構想の背景と目的

Linuxデスクトップのキーバインド統一を目的とする。以下の二大原則に基づく。

- **入力系（エディットモード）**: Emacsキーバインドに統一
- **ビューア系（ナビゲーションモード）**: viキーバインドに統一

## 2. 技術選定：なぜ `xremap` なのか

当初 `keyd` を検討したが、アプリ別コンテキスト切り替えに使う `keyd-application-mapper` がWaylandネイティブウィンドウを検出できないことが判明（X11の `xprop` 依存、GitHub issue #694）。

Hyprland（pure Wayland）環境では `keyd` はグローバルリマップのみ有効で、Phase 2以降の実現手段がない。

**`xremap` を採用する理由:**
- evdev/uinput ベースで動作し、Wayland/X11 どちらでも有効
- Hyprland のウィンドウ情報を直接取得できる（`--features hypr` ビルド）
- YAML設定でアプリ別プロファイルを記述可能
- Rust製、アクティブ開発中

### アーキテクチャ

```
物理キーボード (QMK)
    ↓  ファームウェアレベルのリマップ（OS非依存）
evdev
    ↓
xremap デーモン（ユーザーセッション）
    ↓  アプリ別コンテキスト + グローバルEmacs/viバインド
各アプリケーション
```

## 3. 除外対象（パススルーリスト）

以下のアプリは xremap のリマップを無効にし、アプリ本来のキーバインドを優先する。

| アプリ | 理由 |
|---|---|
| `emacs` | 独自Emacsバインドを持つ |
| `kitty` / `alacritty` / `foot` | ターミナル内のシェル・アプリが独自バインドを持つ |
| `qemu` / 仮想マシン | ゲストOSへキーをそのまま渡す必要がある |

fcitx5がアクティブ（日本語入力中）のとき、IMEのキーハンドリングが優先されるため、その挙動は制御しない（許容）。

## 4. 実装ロードマップ

### Phase 1: グローバルEmacsレイヤー

全アプリ共通（除外リスト除く）のEmacsバインド。

```yaml
modmap:
  - name: Global
    remap:
      CapsLock:
        held: LeftControl
        alone: Escape

keymap:
  - name: Global Emacs
    remap:
      C-p: Up
      C-n: Down
      C-b: Left
      C-f: Right
      C-a: Home
      C-e: End
      C-h: Backspace
      C-m: Return
```

`C-k`（行末削除）は実装が複雑なため、Phase 1では保留。ターゲットアプリごとに動作確認後に追加する。

### Phase 2: アプリ別viレイヤー（Contextual vi）

ブラウザ・PDFビューア・ファイルマネージャがアクティブなとき、単キーでvi操作を有効化。

```yaml
keymap:
  - name: Browser vi
    application:
      only: [firefox, google-chrome, chromium]
    remap:
      j: Down
      k: Up
      h: Left
      l: Right
      g: C-Home
      G: C-End
      u: PageUp
      d: PageDown
      slash: C-f  # ブラウザ内検索
```

### Phase 3: モーダル制御の洗練

入力フォームにフォーカスがあるとき（`<input>`, `<textarea>`）はviバインドを自動無効化する。  
xremap単体での実現は困難なため、ブラウザ拡張（Vimium等）との役割分担も検討する。

## 5. セットアップ

→ [`xremap_setup.md`](xremap_setup.md)

## 6. 今後の課題

1. **Phase 2のWindow class一覧整備**: 対象アプリのクラス名をリストアップ
2. **C-k の実装方法検討**: xremap のマクロ機能で実現可能か検証
3. **Windows 11との筋肉記憶統一**: AutoHotkey等との対照表を作る
4. **QMKとの役割分担明確化**: どこまでをQMKで、どこからをxremapで担うかを決める

---

**参考:**
- [xremap GitHub](https://github.com/xremap/xremap)
- [keyd GitHub](https://github.com/rvaiya/keyd)（グローバルリマップの参考として）
- アーカイブ: `linux_desktop_keybind_plan_archive_keyd.md`（keyd案）
