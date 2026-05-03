# xremap セットアップ手順

## Arch Linux（Hyprland）

```sh
# 1. インストール（AUR、ビルド済みバイナリ）
yay -S xremap-hypr-bin

# 2. udev ルール（root なしで evdev/uinput を読むため）
lsmod | grep uinput
# 表示されない場合:
#   echo uinput | sudo tee /etc/modules-load.d/uinput.conf

echo 'KERNEL=="uinput", GROUP="input", TAG+="uaccess"' | sudo tee /etc/udev/rules.d/99-input.rules
sudo udevadm control --reload-rules && sudo udevadm trigger
sudo usermod -aG input $USER
# ← 再ログイン、または再起動が必要

# 3. 設定ファイル
mkdir -p ~/.config/xremap
# ~/.config/xremap/config.yaml を作成
# このリポジトリの config.example.yaml を雛形として使える

# 4. systemd user service で常駐管理する
```

このプロジェクトでは、Hyprland の `exec-once` ではなく systemd user service で xremap を起動する。

理由:

- 失敗時に `Restart=on-failure` で復帰できる
- `systemctl --user restart xremap.service` で設定反映が明確
- `journalctl --user -u xremap.service -f` でログを追える
- Hyprland の設定とキーマップ常駐プロセスの責務を分けられる

`xremap.service` を雛形として配置する。

```sh
mkdir -p ~/.config/systemd/user
cp xremap.service ~/.config/systemd/user/xremap.service
systemctl --user daemon-reload
systemctl --user enable --now xremap.service
systemctl --user status xremap.service
```

Hyprland側に `exec-once = xremap ...` を書いている場合は、二重起動を避けるため削除またはコメントアウトする。

```ini
# hyprland.conf
# exec-once = xremap --watch=config,device ~/.config/xremap/config.yaml
```

アプリ別条件が効かない場合は、systemd user service から Hyprland の環境変数が見えていない可能性がある。その場合は Hyprland 起動時に以下のような環境変数 import を検討する。

```ini
# hyprland.conf
exec-once = systemctl --user import-environment WAYLAND_DISPLAY HYPRLAND_INSTANCE_SIGNATURE XDG_CURRENT_DESKTOP
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

# udev ルール（root なしで evdev/uinput を読むため）
echo 'KERNEL=="uinput", GROUP="input", TAG+="uaccess"' | sudo tee /etc/udev/rules.d/99-input.rules
sudo udevadm control --reload-rules && sudo udevadm trigger
sudo usermod -aG input $USER
# 再ログイン、または再起動が必要

# 自動起動（GNOME の場合）
# ~/.config/autostart/ に .desktop ファイルを置く
```

> Ubuntu では環境（X11/GNOME/KDE）によって `--features` が異なる。GNOME Wayland なら `gnome` を使う。

GNOME Wayland でアプリ別リマップを使う場合は、xremap の GNOME Shell extension も必要になる。

## features 対応表

| 環境 | features | AURパッケージ |
|---|---|---|
| Hyprland | `hypr` | `xremap-hypr-bin` |
| Sway / wlroots系 | `wlroots` | `xremap-wlroots-bin` |
| GNOME Wayland | `gnome` | `xremap-gnome-bin` |
| KDE Plasma Wayland | `kde` | `xremap-kde-bin` |
| X11 | `x11` | `xremap-x11-bin` |

## 動作確認

```sh
# 設定ファイルのパスは環境に合わせる
xremap --watch=config,device ~/.config/xremap/config.yaml
```

通常ログではキー入力ごとのイベントは表示されない。起動時のデバイス選択と、アプリが切り替わったときの `application: ...` が主な確認ポイントになる。

別ターミナルでアクティブウィンドウのクラスを確認し、`application.only` / `application.not` に指定する名前を調整する。

```sh
hyprctl activewindow
hyprctl clients
```

キーイベントまで見たい場合は、サービスを止めてから debug ログで一時起動する。

```sh
systemctl --user stop xremap.service
RUST_LOG=debug xremap --watch=config,device ~/.config/xremap/config.yaml
systemctl --user start xremap.service
```

問題が出た場合は、まず `application.not` に対象アプリを追加してアプリ本来の動作を優先する。

systemd user service の確認:

```sh
systemctl --user restart xremap.service
journalctl --user -u xremap.service -f
```

### Firefox で `j/k` が効かない場合

現行設定では Firefox / Chromium は xremap の単キーvi対象にしていない。ブラウザは入力欄やWebアプリとの競合が大きいため、`j/k` スクロールは Vimium などのブラウザ拡張に任せる方針。

xremap の Viewer vi レイヤーは、まず `thunar` や `zathura` など入力フォームの少ないアプリで検証する。

---

**参考:**
- [xremap GitHub](https://github.com/xremap/xremap)
- [xremap Releases](https://github.com/xremap/xremap/releases)
- 設定例: `config.example.yaml`
