# xremap セットアップ手順

## Arch Linux（Hyprland）

```sh
# 1. インストール（AUR、ビルド済みバイナリ）
yay -S xremap-hypr-bin

# 2. udev ルール（root なしで evdev/uinput を読むため）
echo 'KERNEL=="uinput", GROUP="input", MODE="0660"' | sudo tee /etc/udev/rules.d/99-input.rules
sudo udevadm control --reload-rules && sudo udevadm trigger
sudo usermod -aG input $USER
# ← 再ログインが必要

# 3. 設定ファイル
mkdir -p ~/.config/xremap
# ~/.config/xremap/config.yaml を作成

# 4. Hyprland 自動起動（hyprland.conf に追記）
#   exec-once = xremap ~/.config/xremap/config.yaml --watch
```

アクティブウィンドウのクラス名確認:
```sh
hyprctl activewindow | grep class
# または全クライアント一覧
hyprctl clients | grep class
```

## Ubuntu（GNOME Wayland 等）

AURが使えないため、GitHubリリースのバイナリか cargo でビルドする。

```sh
# cargo でビルドする場合（GNOME Wayland 向け）
cargo install xremap --features gnome

# または GitHub Releases からバイナリをダウンロード
# https://github.com/xremap/xremap/releases
# 環境に合った features のバイナリを選ぶ

# udev ルール（Arch と同じ）
echo 'KERNEL=="uinput", GROUP="input", MODE="0660"' | sudo tee /etc/udev/rules.d/99-input.rules
sudo udevadm control --reload-rules && sudo udevadm trigger
sudo usermod -aG input $USER

# 自動起動（GNOME の場合）
# ~/.config/autostart/ に .desktop ファイルを置く
```

> Ubuntu では環境（X11/GNOME/KDE）によって `--features` が異なる。`gnome` が最も一般的。

## features 対応表

| 環境 | features | AURパッケージ |
|---|---|---|
| Hyprland | `hypr` | `xremap-hypr-bin` |
| Sway / wlroots系 | `wlroots` | `xremap-wlroots-bin` |
| GNOME Wayland | `gnome` | `xremap-gnome-bin` |
| KDE Plasma Wayland | `kde` | `xremap-kde-bin` |
| X11 | `x11` | `xremap-x11-bin` |

---

**参考:**
- [xremap GitHub](https://github.com/xremap/xremap)
- [xremap Releases](https://github.com/xremap/xremap/releases)
- 設定例: `~/.config/xremap/config.yaml`（`linux_desktop_keybind_plan.md` 参照）
