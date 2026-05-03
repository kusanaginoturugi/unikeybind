# 動作検証ログ

## 2026-05-01 Hyprland

### 確認したウィンドウクラス

| class | 用途 | 方針 |
|---|---|---|
| `kitty` | 通常ターミナル | Emacs/viレイヤーから除外 |
| `dropdown` | ドロップダウンターミナル | Emacs/viレイヤーから除外 |
| `firefox` | ブラウザ | Phase 2では xremap の単キーvi対象にしない |
| `chromium` | ブラウザ | Phase 2では xremap の単キーvi対象にしない |
| `thunar` | ファイルマネージャ | Viewer vi の対象候補 |
| `code-oss` | エディタ | エディタ固有ショートカットを優先 |
| `libreoffice-calc` | スプレッドシート | Phase 1の検証候補 |
| `org.remmina.Remmina` | リモートデスクトップ | パススルー優先 |

### 確認した入力デバイス

| device | name | 方針 |
|---|---|---|
| `/dev/input/event3` | `USB-HID Keyboard` | 自動選択対象 |
| `/dev/input/event7` | `USB-HID Keyboard` | 自動選択対象 |
| `/dev/input/event8` | `ELECOM  ELECOM  Lunaris  USB tenkeyboard` | 自動選択対象 |
| `/dev/input/event22` | `xremap` | 短時間起動時に作成された仮想デバイス。プロセス終了後は消える |

### メモ

- `xremap --watch=config,device ~/.config/xremap/config.yaml` で設定ファイルとデバイス追加の両方を監視する。
- `xremap --watch ~/.config/xremap/config.yaml` はデバイス追加のみを監視するため、設定変更の反映には再起動が必要になる。
- 2026-05-01時点では常駐 xremap プロセスは未検出。短時間起動テスト後の `xremap --list-devices` では仮想デバイスが消えていることを確認した。
- 起動管理は Hyprland `exec-once` ではなく systemd user service を本線にする。
- 2026-05-01 20:34 JST に `xremap.service` を `systemctl --user enable --now` 済み。`/dev/input/event3`, `/dev/input/event7`, `/dev/input/event8` を自動選択して active running を確認。
- `~/.config/hypr/hyprland.conf` の `exec-once = xremap ...` はコメントアウト済み。systemd user service 用に `systemctl --user import-environment WAYLAND_DISPLAY HYPRLAND_INSTANCE_SIGNATURE XDG_CURRENT_DESKTOP` を追加済み。
- `journalctl --user -u xremap.service` で `application-client: Hypr (supported: true)` と `application: firefox` / `application: kitty` を確認済み。アプリ判定は動作している。
- Firefox は現行設定では単キーvi対象外。`j/k` スクロールは Vimium 等に任せる方針。
- Firefox / Chromium では `C-p` を `up`、`C-n` を `down`、`C-b` を `left`、`C-a` を `home`、`C-e` を `end`、`C-h` を `backspace`、`C-j` を `linefeed` にする。`C-m` は Enter / Return として別扱い。ブラウザ全体を Global Emacs 対象へ戻すと `C-f` なども潰れるため、個別レイヤーで扱う。
