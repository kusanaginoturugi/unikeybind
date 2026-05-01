# Linuxデスクトップ大統一キーバインド構想：計画書

## 1. 構想の背景と目的
Linuxデスクトップは、長年「デスクトップ元年」と言われながらも、キーバインドの統一性の欠如（Emacs, vi, Mac, Windowsの混在）がユーザビリティを著しく阻害している。
本プロジェクトは、この「キメラ操作」を打破し、以下の二大原則に基づいた一貫性のある操作体系をOSレイヤーで構築することを目的とする。

- **入力系（エディットモード）**: Emacsキーバインドに統一
- **ビューア系（ナビゲーションモード）**: viキーバインドに統一

Windowsにおけるかつての `xkeymacs` を超える、歴史上最強の操作環境をLinux上に再構築する。

## 2. 技術選定：なぜ `keyd` なのか
Wayland/X11が混在する現代のLinuxにおいて、GUIツールキット（GTK/Qt）やアプリケーションの独自実装に依存せず、最も低レイヤーでキーイベントを制御できる **`keyd`** を中核に据える。

### `keyd` を選ぶ利点:
- **低レイヤー動作**: `evdev` レベルで動作するため、あらゆるアプリに強制適用可能。
- **コンテキスト認識**: `keyd-application-mapper` により、アクティブなウィンドウ（Window Class/Title）に応じたプロファイルの動的切り替えが可能。
- **軽量・堅牢**: デーモンとして動作し、設定ファイルの記述が簡潔。

## 3. 実装ロードマップ

### Phase 1: 基本編集レイヤー（Global Emacs）
全てのアプリケーションで共通して使用可能なEmacsバインドを定義する。
- `C-p/n/b/f`: 上下左右移動
- `C-a/e`: 行頭・行末
- `C-h`: Backspace
- `C-k`: 行末まで削除
- `C-y`: 貼り付け
- `C-m`: Enter

### Phase 2: ビューア専用レイヤー（Contextual vi）
ブラウザ、PDFビューア、ファイルマネージャ等がアクティブな際、単キーでのvi操作を有効化する。
- `j/k/h/l`: 移動
- `g/G`: 文頭・文末
- `/`: 検索
- `u/d`: スクロール

### Phase 3: モーダル切り替えの洗練
「入力中」と「閲覧中」の区別を、ウィンドウクラスによる自動切り替え、または手動トグル（Esc, `i` 等）で制御する。

## 4. `keyd` 設定プロトタイプ (`/etc/keyd/default.conf`)

```ini
[main]
# CapsLockをControlに、長押しでControl、単押しでEsc
capslock = overload(control, esc)

[control]
# Emacs風基本移動
p = up
n = down
b = left
f = right
a = home
e = end
h = backspace
k = C-S-end backspace

# ブラウザ等でのviバインド（keyd-application-mapperが必要）
[window(class=google-chrome|firefox|zathura)]
j = down
k = up
h = left
l = right

# ターミナル等、干渉を避けたいアプリの設定
[window(class=alacritty|foot|kitty)]
# デフォルト挙動を優先
```

## 5. 今後の課題（CLIでの作業項目）
1. **Window Classの特定**: `xprop` (X11) や `wayland-info` 等を用いて、対象アプリのクラス名をリストアップする。
2. **keyd-application-mapperの導入**: AURやソースからビルドし、ユーザセッションで自動起動する設定を行う。
3. **マクロの微調整**: `C-k`（行末削除）などの複合操作を、ターゲットアプリで確実に動作させるためのマクロ記述の最適化。
4. **競合排除**: アプリケーション側のショートカット設定と `keyd` 側の競合を整理する。

---
**参考情報:**
- [keyd GitHub Repository](https://github.com/rvaiya/keyd)
- 歴史的背景: `xkeymacs` の思想を継承しつつ、Unixライクなモーダル操作を融合させる。
