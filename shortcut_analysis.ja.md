# ショートカット解析

- 合計: 175
- 有効: 95
- 無効/デフォルト: 80
- 同一スコープ内の有効な重複: 0
- スコープをまたぐ有効な重複: 2
- 無効/デフォルトを含む重複: 0
- 無効/デフォルトを含む潜在的な衝突: 5
- 参考: スコープ付き xremap の重なり: 6

## 同一スコープ内の重複

同一スコープ内の有効な重複は見つかりませんでした。

## スコープをまたぐ重複

### `DOWN`
- `Down` -> CursorDown 0 (fcitx5, ime addon, enabled, ~/.config/fcitx5/conf/skk.conf:30 / CursorDown)
- `Down` -> Hotkey/NextPage 0 (fcitx5, ime hotkey, enabled, ~/.config/fcitx5/config:29 / Hotkey/NextPage)

### `UP`
- `Up` -> CursorUp 0 (fcitx5, ime addon, enabled, ~/.config/fcitx5/conf/skk.conf:27 / CursorUp)
- `Up` -> Hotkey/PrevPage 0 (fcitx5, ime hotkey, enabled, ~/.config/fcitx5/config:26 / Hotkey/PrevPage)


## 無効/デフォルトを含む重複

無効/デフォルトを含めても重複は見つかりませんでした。

## 無効/デフォルトを含む潜在的な衝突

### `CTRL+SEMICOLON`
- `Control+semicolon` -> open clipboard history (fcitx5-default, ime addon default, disabled, ~/src/unikeybind/shortcut_catalog.yaml / Known fcitx5 Clipboard add-on default; local ~/.config/fcitx5/conf/clipboard.conf may override it)
- `Ctrl+;` -> open emoji chooser (gtk, gtk text input, enabled, ~/src/unikeybind/shortcut_catalog.yaml / GTK 4 default binding for Gtk.TextView::insert-emoji; https://docs.gtk.org/gtk4/signal.TextView.insert-emoji.html)

### `DOWN`
- `Down` -> CursorDown 0 (fcitx5, ime addon, enabled, ~/.config/fcitx5/conf/skk.conf:30 / CursorDown)
- `Down` -> Hotkey/NextPage 0 (fcitx5, ime hotkey, enabled, ~/.config/fcitx5/config:29 / Hotkey/NextPage)

### `KMOD+LEFT_BRACKET`
- `kmod+[` -> previous_tab (kitty, terminal, enabled, ~/.config/kitty/kitty.conf:2708 / custom; kmod = kitty_mod = ctrl+shift)
- `kmod+[` -> previous_window (kitty, terminal default, disabled, ~/.config/kitty/kitty.conf:2621 / default from commented kitty.conf; kmod = kitty_mod = ctrl+shift)

### `KMOD+RIGHT_BRACKET`
- `kmod+]` -> next_tab (kitty, terminal, enabled, ~/.config/kitty/kitty.conf:2702 / custom; kmod = kitty_mod = ctrl+shift)
- `kmod+]` -> next_window (kitty, terminal default, disabled, ~/.config/kitty/kitty.conf:2617 / default from commented kitty.conf; kmod = kitty_mod = ctrl+shift)

### `UP`
- `Up` -> CursorUp 0 (fcitx5, ime addon, enabled, ~/.config/fcitx5/conf/skk.conf:27 / CursorUp)
- `Up` -> Hotkey/PrevPage 0 (fcitx5, ime hotkey, enabled, ~/.config/fcitx5/config:26 / Hotkey/PrevPage)

## 利用可能なグローバル候補

候補範囲: SUPER, SUPER+SHIFT, SUPER+CTRL, SUPER+ALT x 56 個の一般的なキー。これは実用的な探索範囲であり、ここにないキーがすべてグローバルに安全であることを証明するものではありません。

- `SUPER+A`
- `SUPER+B`
- `SUPER+C`
- `SUPER+F`
- `SUPER+G`
- `SUPER+H`
- `SUPER+I`
- `SUPER+K`
- `SUPER+N`
- `SUPER+O`
- `SUPER+U`
- `SUPER+W`
- `SUPER+X`
- `SUPER+Y`
- `SUPER+HOME`
- `SUPER+END`
- `SUPER+PAGE_UP`
- `SUPER+PAGE_DOWN`
- `SUPER+F1`
- `SUPER+F2`
- `SUPER+F3`
- `SUPER+F4`
- `SUPER+F5`
- `SUPER+F6`
- `SUPER+F7`
- `SUPER+F8`
- `SUPER+F9`
- `SUPER+F10`
- `SUPER+F11`
- `SUPER+F12`
- `SUPER+SHIFT+A`
- `SUPER+SHIFT+B`
- `SUPER+SHIFT+C`
- `SUPER+SHIFT+D`
- `SUPER+SHIFT+E`
- `SUPER+SHIFT+F`
- `SUPER+SHIFT+G`
- `SUPER+SHIFT+H`
- `SUPER+SHIFT+I`
- `SUPER+SHIFT+J`
- `SUPER+SHIFT+K`
- `SUPER+SHIFT+L`
- `SUPER+SHIFT+M`
- `SUPER+SHIFT+N`
- `SUPER+SHIFT+O`
- `SUPER+SHIFT+P`
- `SUPER+SHIFT+Q`
- `SUPER+SHIFT+R`
- `SUPER+SHIFT+T`
- `SUPER+SHIFT+U`
- `SUPER+SHIFT+V`
- `SUPER+SHIFT+W`
- `SUPER+SHIFT+X`
- `SUPER+SHIFT+Y`
- `SUPER+SHIFT+Z`
- `SUPER+SHIFT+LEFT`
- `SUPER+SHIFT+RIGHT`
- `SUPER+SHIFT+UP`
- `SUPER+SHIFT+DOWN`
- `SUPER+SHIFT+HOME`
- `SUPER+SHIFT+END`
- `SUPER+SHIFT+PAGE_UP`
- `SUPER+SHIFT+PAGE_DOWN`
- `SUPER+SHIFT+F1`
- `SUPER+SHIFT+F2`
- `SUPER+SHIFT+F3`
- `SUPER+SHIFT+F4`
- `SUPER+SHIFT+F5`
- `SUPER+SHIFT+F6`
- `SUPER+SHIFT+F7`
- `SUPER+SHIFT+F8`
- `SUPER+SHIFT+F9`
- `SUPER+SHIFT+F10`
- `SUPER+SHIFT+F11`
- `SUPER+SHIFT+F12`
- `SUPER+CTRL+A`
- `SUPER+CTRL+B`
- `SUPER+CTRL+C`
- `SUPER+CTRL+D`
- `SUPER+CTRL+E`

## 参考: スコープ付き xremap の重なり

`only` や `not` などの xremap アプリケーションスコープを使っているため、通常は意図的な設定です。通常のスコープ間重複としては数えません。

### `CTRL+A`
- `C-a` -> home (xremap, not: emacs, kitty, dropdown, alacritty, foot, firefox, chromium, code-oss, org.remmina.Remmina, qemu, enabled, ~/.config/xremap/config.yaml / Global Emacs)
- `C-a` -> home (xremap, only: firefox, chromium, enabled, ~/.config/xremap/config.yaml / Browser Emacs Navigation)

### `CTRL+B`
- `C-b` -> left (xremap, not: emacs, kitty, dropdown, alacritty, foot, firefox, chromium, code-oss, org.remmina.Remmina, qemu, enabled, ~/.config/xremap/config.yaml / Global Emacs)
- `C-b` -> left (xremap, only: firefox, chromium, enabled, ~/.config/xremap/config.yaml / Browser Emacs Navigation)

### `CTRL+E`
- `C-e` -> end (xremap, not: emacs, kitty, dropdown, alacritty, foot, firefox, chromium, code-oss, org.remmina.Remmina, qemu, enabled, ~/.config/xremap/config.yaml / Global Emacs)
- `C-e` -> end (xremap, only: firefox, chromium, enabled, ~/.config/xremap/config.yaml / Browser Emacs Navigation)

### `CTRL+H`
- `C-h` -> backspace (xremap, not: emacs, kitty, dropdown, alacritty, foot, firefox, chromium, code-oss, org.remmina.Remmina, qemu, enabled, ~/.config/xremap/config.yaml / Global Emacs)
- `C-h` -> backspace (xremap, only: firefox, chromium, enabled, ~/.config/xremap/config.yaml / Browser Emacs Navigation)

### `CTRL+N`
- `C-n` -> down (xremap, not: emacs, kitty, dropdown, alacritty, foot, firefox, chromium, code-oss, org.remmina.Remmina, qemu, enabled, ~/.config/xremap/config.yaml / Global Emacs)
- `C-n` -> down (xremap, only: firefox, chromium, enabled, ~/.config/xremap/config.yaml / Browser Emacs Navigation)

### `CTRL+P`
- `C-p` -> up (xremap, not: emacs, kitty, dropdown, alacritty, foot, firefox, chromium, code-oss, org.remmina.Remmina, qemu, enabled, ~/.config/xremap/config.yaml / Global Emacs)
- `C-p` -> up (xremap, only: firefox, chromium, enabled, ~/.config/xremap/config.yaml / Browser Emacs Navigation)

