# unikeybind

Linuxデスクトップのキーバインドを、用途ごとに一貫した操作体系へ寄せるための設計メモです。

- 入力系: Emacs風の編集操作
- ビューア系: vi風のナビゲーション操作
- 対象環境: Hyprland / Wayland を主軸に、必要に応じてX11や他Wayland環境も考慮

## 現行案

現行の実装方針は `xremap` 版です。

1. [linux_desktop_keybind_plan.md](linux_desktop_keybind_plan.md) - 現行の設計方針と段階的な実装計画
2. [xremap_setup.md](xremap_setup.md) - xremap の導入と起動手順
3. [config.example.yaml](config.example.yaml) - xremap 設定の最小サンプル
4. [xremap.service](xremap.service) - systemd user service の雛形
5. [firefox_keybind_conflicts.md](firefox_keybind_conflicts.md) - FirefoxショートカットとEmacs/vi操作の衝突検討表
6. [skk_fcitx5_notes.md](skk_fcitx5_notes.md) - SKK と fcitx5 のキー衝突回避メモ
7. [verification_log.md](verification_log.md) - 実機で確認したウィンドウクラスとデバイス
8. [linux_desktop_keybind_plan_archive_keyd.md](linux_desktop_keybind_plan_archive_keyd.md) - 旧 `keyd` 案のアーカイブ

`keyd` はグローバルなリマップには有力ですが、Hyprland の pure Wayland 環境でアプリ別コンテキスト切り替えを行う用途には制約があります。そのため、このリポジトリでは `xremap --features hypr` を本線として扱います。

## ショートカット一覧アプリ

`shortcut_app.rb` は、ローカル環境の設定ファイルから機械的に抽出できるショートカットを集めて、検索可能な HTML レポートを生成します。

対象:

- Hyprland: `~/.config/hypr/hyprland.conf` と `source = ...` で読み込まれる設定の `bind*`
- xremap: `~/.config/xremap/config.yaml` の `modmap` / `keymap`
- kitty: `~/.config/kitty/kitty.conf` の有効な `map` と、コメント化されたデフォルト `# map`

実行:

```sh
ruby shortcut_app.rb --json shortcut_report.json
```

生成される `shortcut_report.html` をブラウザで開くと、source / scope / shortcut / action / file で検索できます。
source / scope のチップをクリックすると、その条件で絞り込めます。

## 方針

- CapsLock は OS 非依存に近い基本操作として Ctrl/Esc 化する
- 通常アプリでは Emacs風の基本編集キーを使う
- ターミナル、Emacs、仮想マシンなどはアプリ本来のキー操作を優先する
- ブラウザやビューアの vi風操作は、入力欄との競合を避けながら段階的に導入する
- xremap は Hyprland の `exec-once` ではなく、systemd user service で常駐管理する
