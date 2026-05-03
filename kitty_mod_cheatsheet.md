# kmod Cheat Sheet

Source: `/home/onoue/.config/kitty/kitty.conf`

## Modifier

| Alias | Keys |
|---|---|
| `kmod` | `kitty_mod` = `Ctrl+Shift` |

This cheat sheet abbreviates `kitty_mod` as `kmod`.
`kitty_mod ctrl+shift` is shown as the default value in the config comments.

## Active Mappings

These `kmod` mappings are explicitly enabled in `kitty.conf`.

| Shortcut | Action | Description |
|---|---|---|
| `kmod+]` | `next_tab` | Move to next tab |
| `kmod+[` | `previous_tab` | Move to previous tab |

## Default Mappings Listed In Config

The following mappings are listed in commented default/example lines in `kitty.conf`.
They document kitty's default `kitty_mod` shortcuts, but they are not explicit custom lines in this file.
Shortcut notation uses `kmod` for readability.

### Clipboard And Selection

| Shortcut | Action |
|---|---|
| `kmod+c` | Copy to clipboard |
| `kmod+v` | Paste from clipboard |
| `kmod+s` | Paste from selection |
| `kmod+o` | Pass selection to program |

### Scrolling And Scrollback

| Shortcut | Action |
|---|---|
| `kmod+up` / `kmod+k` | Scroll line up |
| `kmod+down` / `kmod+j` | Scroll line down |
| `kmod+page_up` | Scroll page up |
| `kmod+page_down` | Scroll page down |
| `kmod+home` | Scroll to top |
| `kmod+end` | Scroll to bottom |
| `kmod+z` | Scroll to previous prompt |
| `kmod+x` | Scroll to next prompt |
| `kmod+h` | Show scrollback |
| `kmod+g` | Show last command output |
| `kmod+/` | Search scrollback |

### Windows

| Shortcut | Action |
|---|---|
| `kmod+enter` | New window |
| `kmod+n` | New OS window |
| `kmod+w` | Close window |
| `kmod+]` | Next window |
| `kmod+[` | Previous window |
| `kmod+f` | Move window forward |
| `kmod+b` | Move window backward |
| ``kmod+` `` | Move window to top |
| `kmod+r` | Start resizing window |
| `kmod+1` ... `kmod+0` | Focus first through tenth window |
| `kmod+f7` | Focus visible window |
| `kmod+f8` | Swap with visible window |

### Tabs

| Shortcut | Action |
|---|---|
| `kmod+right` | Next tab |
| `kmod+left` | Previous tab |
| `kmod+t` | New tab |
| `kmod+q` | Close tab |
| `kmod+.` | Move tab forward |
| `kmod+,` | Move tab backward |
| `kmod+alt+t` | Set tab title |

### Layout And Font Size

| Shortcut | Action |
|---|---|
| `kmod+l` | Next layout |
| `kmod+equal` / `kmod+plus` / `kmod+kp_add` | Increase font size |
| `kmod+minus` / `kmod+kp_subtract` | Decrease font size |
| `kmod+backspace` | Reset font size |

### Hints And Kittens

| Shortcut | Action |
|---|---|
| `kmod+e` | Open URL with hints |
| `kmod+p>f` | Hint file paths and paste/open with program |
| `kmod+p>shift+f` | Hint file paths |
| `kmod+p>c` | Choose files |
| `kmod+p>d` | Choose directories |
| `kmod+p>l` | Hint lines |
| `kmod+p>w` | Hint words |
| `kmod+p>h` | Hint hashes |
| `kmod+p>n` | Hint line numbers |
| `kmod+p>y` | Hint hyperlinks |
| `kmod+u` | Unicode input |

### Kitty Commands And Debugging

| Shortcut | Action |
|---|---|
| `kmod+f1` | Show kitty documentation overview |
| `kmod+f3` | Command palette |
| `kmod+f11` | Toggle fullscreen |
| `kmod+f10` | Toggle maximized |
| `kmod+f2` | Edit config file |
| `kmod+escape` | Open kitty shell |
| `kmod+delete` | Clear terminal and reset active screen |
| `kmod+f5` | Load config file |
| `kmod+f6` | Debug config |

### Background Opacity

| Shortcut | Action |
|---|---|
| `kmod+a>m` | Increase background opacity |
| `kmod+a>l` | Decrease background opacity |
| `kmod+a>1` | Set background opacity to opaque |
| `kmod+a>d` | Reset background opacity to default |
