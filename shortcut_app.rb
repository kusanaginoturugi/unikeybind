#!/usr/bin/env ruby
# frozen_string_literal: true

require "fileutils"
require "json"
require "optparse"
require "pathname"
require "set"
require "yaml"

Shortcut = Struct.new(
  :source,
  :scope,
  :shortcut,
  :action,
  :file,
  :line,
  :enabled,
  :directive,
  :note,
  keyword_init: true
)

DEFAULT_HYPRLAND = File.expand_path("~/.config/hypr/hyprland.conf")
DEFAULT_XREMAP = File.expand_path("~/.config/xremap/config.yaml")
DEFAULT_KITTY = File.expand_path("~/.config/kitty/kitty.conf")
DEFAULT_FCITX5 = File.expand_path("~/.config/fcitx5")
DEFAULT_CATALOG = "shortcut_catalog.yaml"
COMMON_MOD_SETS = [
  "SUPER",
  "SUPER+SHIFT",
  "SUPER+CTRL",
  "SUPER+ALT"
].freeze
COMMON_KEYS = [
  *("A".."Z").to_a,
  *("0".."9").to_a,
  "LEFT",
  "RIGHT",
  "UP",
  "DOWN",
  "HOME",
  "END",
  "PAGE_UP",
  "PAGE_DOWN",
  *Array.new(12) { |index| "F#{index + 1}" }
].freeze
MOD_ALIASES = {
  "C" => "CTRL",
  "CONTROL" => "CTRL",
  "CTRL" => "CTRL",
  "M" => "ALT",
  "A" => "ALT",
  "ALT" => "ALT",
  "S" => "SHIFT",
  "SHIFT" => "SHIFT",
  "SUPER" => "SUPER",
  "WIN" => "SUPER",
  "META" => "SUPER",
  "CMD" => "SUPER",
  "KMOD" => "KMOD"
}.freeze
MOD_ORDER = {
  "CTRL" => 0,
  "ALT" => 1,
  "SHIFT" => 2,
  "SUPER" => 3,
  "KMOD" => 4
}.freeze
KEY_ALIASES = {
  "," => "COMMA",
  ";" => "SEMICOLON",
  "." => "PERIOD",
  "/" => "SLASH",
  "`" => "GRAVE",
  "[" => "LEFT_BRACKET",
  "]" => "RIGHT_BRACKET",
  "-" => "MINUS",
  "=" => "EQUAL",
  "RETURN" => "ENTER",
  "PGUP" => "PAGE_UP",
  "PGDN" => "PAGE_DOWN",
  "PAGEUP" => "PAGE_UP",
  "PAGEDOWN" => "PAGE_DOWN",
  "ESC" => "ESCAPE",
  "SEMICOLON" => "SEMICOLON"
}.freeze

def strip_comment(line)
  escaped = false
  line.each_char.with_index do |char, index|
    if char == "\\" && !escaped
      escaped = true
      next
    end
    return line[0...index].rstrip if char == "#" && !escaped

    escaped = false
  end
  line.rstrip
end

def display_path(path)
  absolute = Pathname.new(path).expand_path
  home = Pathname.new(Dir.home)
  relative = absolute.relative_path_from(home)
  "~/#{relative}"
rescue ArgumentError
  path.to_s
end

def replace_variables(value, variables)
  variables.reduce(value.to_s) do |text, (key, replacement)|
    text.gsub("$#{key}", replacement)
  end.strip
end

def normalize_mods(mods)
  mods.to_s.gsub(",", " ").split(/\s+/).reject(&:empty?).join("+")
end

def join_shortcut(mods, key)
  normalized = normalize_mods(mods)
  key = key.to_s.strip
  normalized.empty? ? key : "#{normalized}+#{key}"
end

def normalize_key_name(value)
  key = value.to_s.strip
  key = key.upcase unless key.match?(/[a-z].*[A-Z]|[A-Z].*[a-z]/)
  KEY_ALIASES.fetch(key.upcase, key.upcase)
end

def normalize_chord(value)
  text = value.to_s.strip
  return "" if text.empty?

  text = text.gsub(/\b(C|M|A|S)-(?=[^-+\s]+)/i) { "#{Regexp.last_match(1)}+" }
  text = text.gsub(/\b(Ctrl|Control|Alt|Shift|Super|Win|Meta|Cmd)-(?=[^-+\s]+)/i) { "#{Regexp.last_match(1)}+" }
  parts = text.split("+").map(&:strip).reject(&:empty?)
  return normalize_key_name(text) if parts.length <= 1

  mods = []
  key_parts = []
  parts.each_with_index do |part, index|
    canonical_mod = MOD_ALIASES[part.upcase]
    if canonical_mod && index < parts.length - 1
      mods << canonical_mod
    else
      key_parts << normalize_key_name(part)
    end
  end
  ([*mods.uniq.sort_by { |mod| MOD_ORDER.fetch(mod, 99) }, key_parts.join("+")]).reject(&:empty?).join("+")
end

def normalize_shortcut(value)
  value.to_s.split(">").map { |part| normalize_chord(part) }.join(">")
end

def parse_csvish(value, max_parts = 4)
  parts = value.to_s.split(",", max_parts).map(&:strip)
  return parts if parts.length <= max_parts

  parts[0...(max_parts - 1)] + [parts[(max_parts - 1)..].join(",").strip]
end

def expand_config_path(raw, base_path, variables)
  value = replace_variables(raw, variables)
  value = File.expand_path(value, File.dirname(base_path))
  matches = Dir.glob(value)
  matches.empty? ? [value] : matches
end

def parse_hyprland(root)
  shortcuts = []
  variables = {}
  visited = {}

  parse_file = lambda do |path|
    path = File.expand_path(path)
    return if visited[path] || !File.file?(path)

    visited[path] = true
    File.readlines(path, chomp: true, encoding: "UTF-8").each_with_index do |raw_line, index|
      line_no = index + 1
      line = strip_comment(raw_line).strip
      next if line.empty?

      if (match = line.match(/^\$([A-Za-z0-9_]+)\s*=\s*(.+)$/))
        variables[match[1]] = replace_variables(match[2], variables)
        next
      end

      if (match = line.match(/^source\s*=\s*(.+)$/))
        expand_config_path(match[1], path, variables).each { |source_path| parse_file.call(source_path) }
        next
      end

      match = line.match(/^(bind[a-z]*)\s*=\s*(.+)$/)
      next unless match

      kind = match[1]
      parts = parse_csvish(match[2], 4)
      next if parts.length < 3

      mods = replace_variables(parts[0], variables)
      key = replace_variables(parts[1], variables)
      dispatcher = replace_variables(parts[2], variables)
      args = parts[3] ? replace_variables(parts[3], variables) : ""
      action = [dispatcher, args].reject(&:empty?).join(" ")

      shortcuts << Shortcut.new(
        source: "hyprland",
        scope: "global",
        shortcut: join_shortcut(mods, key),
        action: action,
        file: display_path(path),
        line: line_no,
        enabled: true,
        directive: kind,
        note: ""
      )
    end
  end

  parse_file.call(root)
  shortcuts
end

def stringify_action(value)
  case value
  when Hash
    value.map { |key, nested| "#{key}: #{stringify_action(nested)}" }.join(", ")
  when Array
    value.map(&:to_s).join(" ")
  else
    value.to_s
  end
end

def xremap_scope(entry)
  application = entry["application"]
  return "global" unless application

  if application["only"]
    "only: #{application["only"].map(&:to_s).join(", ")}"
  elsif application["not"]
    "not: #{application["not"].map(&:to_s).join(", ")}"
  else
    "application scoped"
  end
end

def parse_xremap(path)
  return [] unless File.file?(path)

  data = YAML.safe_load_file(path, permitted_classes: [Symbol], aliases: true) || {}
  shortcuts = []

  Array(data["modmap"]).each do |entry|
    name = entry["name"] || "modmap"
    (entry["remap"] || {}).each do |from, to|
      if to.is_a?(Hash)
        to.each do |mode, action|
          shortcuts << Shortcut.new(
            source: "xremap",
            scope: "global",
            shortcut: "#{from} (#{mode})",
            action: stringify_action(action),
            file: display_path(path),
            line: 0,
            enabled: true,
            directive: "modmap",
            note: name
          )
        end
      else
        shortcuts << Shortcut.new(
          source: "xremap",
          scope: "global",
          shortcut: from.to_s,
          action: stringify_action(to),
          file: display_path(path),
          line: 0,
          enabled: true,
          directive: "modmap",
          note: name
        )
      end
    end
  end

  Array(data["keymap"]).each do |entry|
    name = entry["name"] || "keymap"
    scope = xremap_scope(entry)
    (entry["remap"] || {}).each do |from, to|
      shortcuts << Shortcut.new(
        source: "xremap",
        scope: scope,
        shortcut: from.to_s,
        action: stringify_action(to),
        file: display_path(path),
        line: 0,
        enabled: true,
        directive: "keymap",
        note: name
      )
    end
  end

  shortcuts
end

def parse_kitty(path)
  return [] unless File.file?(path)

  lines = File.readlines(path, chomp: true, encoding: "UTF-8")
  kitty_mod = "ctrl+shift"
  shortcuts = []

  lines.each do |raw_line|
    active = strip_comment(raw_line).strip
    commented = raw_line.strip
    if (match = active.match(/^kitty_mod\s+(.+)$/))
      kitty_mod = match[1].strip
    elsif (match = commented.match(/^#\s*kitty_mod\s+(.+)$/))
      kitty_mod = match[1].strip
    end
  end

  lines.each_with_index do |raw_line, index|
    line = strip_comment(raw_line).strip
    commented_match = raw_line.strip.match(/^#\s+map\s+(.+)$/)

    if line.start_with?("map ")
      parts = line.split(/\s+/, 3)
      next if parts.length < 3

      shortcuts << Shortcut.new(
        source: "kitty",
        scope: "terminal",
        shortcut: parts[1].gsub("kitty_mod", "kmod"),
        action: parts[2].strip,
        file: display_path(path),
        line: index + 1,
        enabled: true,
        directive: "map",
        note: "custom; kmod = kitty_mod = #{kitty_mod}"
      )
    elsif commented_match
      default_line = "map #{commented_match[1].strip}"
      parts = default_line.split(/\s+/, 3)
      next if parts.length < 3

      shortcuts << Shortcut.new(
        source: "kitty",
        scope: "terminal default",
        shortcut: parts[1].gsub("kitty_mod", "kmod"),
        action: parts[2].strip,
        file: display_path(path),
        line: index + 1,
        enabled: false,
        directive: "map",
        note: "default from commented kitty.conf; kmod = kitty_mod = #{kitty_mod}"
      )
    end
  end

  shortcuts
end

def parse_fcitx5_hotkey_value(value)
  value.to_s.split(",").map(&:strip).reject(&:empty?)
end

def fcitx5_hotkey_entry?(section, key)
  return key.match?(/^\d+$/) if section.start_with?("Hotkey/") || section.match?(/(?:Page.*Key|Cursor)/)

  return %w[
    TriggerKeys
    ActivateKeys
    DeactivateKeys
    AltTriggerKeys
    EnumerateForwardKeys
    EnumerateBackwardKeys
    EnumerateGroupForwardKeys
    EnumerateGroupBackwardKeys
  ].include?(key) if section == "Hotkey"

  %w[TriggerKey PastePrimaryKey].include?(key)
end

def parse_fcitx5_file(path)
  return [] unless File.file?(path)

  shortcuts = []
  section = "global"
  comments = []
  File.readlines(path, chomp: true, encoding: "UTF-8").each_with_index do |raw_line, index|
    line = raw_line.strip
    if line.start_with?("#")
      comments << line.delete_prefix("#").strip
      next
    end

    next if line.empty?

    if (match = line.match(/^\[(.+)\]$/))
      section = match[1]
      comments = []
      next
    end

    match = line.match(/^([^=]+)=(.*)$/)
    next unless match

    key = match[1].strip
    next unless fcitx5_hotkey_entry?(section, key)

    values = parse_fcitx5_hotkey_value(match[2])
    next if values.empty?

    action = comments.last.to_s.empty? ? "#{section} #{key}" : comments.last
    values.each do |shortcut|
      shortcuts << Shortcut.new(
        source: "fcitx5",
        scope: section.start_with?("Hotkey") ? "ime hotkey" : "ime addon",
        shortcut: shortcut,
        action: action,
        file: display_path(path),
        line: index + 1,
        enabled: true,
        directive: key,
        note: section
      )
    end
    comments = []
  end
  shortcuts
end

def parse_fcitx5(root)
  root = File.expand_path(root)
  paths = [
    File.join(root, "config"),
    *Dir.glob(File.join(root, "conf", "*.conf")).reject { |path| File.basename(path) == "cached_layouts" }
  ]
  paths.flat_map { |path| parse_fcitx5_file(path) }
end

def parse_catalog(path)
  return [] unless path && File.file?(path)

  data = YAML.safe_load_file(path, permitted_classes: [Symbol], aliases: true) || []
  entries = data.is_a?(Hash) ? Array(data["shortcuts"]) : Array(data)
  entries.map do |entry|
    Shortcut.new(
      source: entry.fetch("source"),
      scope: entry.fetch("scope", "known default"),
      shortcut: entry.fetch("shortcut"),
      action: entry.fetch("action", ""),
      file: display_path(path),
      line: 0,
      enabled: entry.fetch("enabled", true),
      directive: entry.fetch("directive", "catalog"),
      note: entry.fetch("note", "")
    )
  end
end

def collect_shortcuts(paths)
  [
    *parse_hyprland(paths[:hyprland]),
    *parse_xremap(paths[:xremap]),
    *parse_kitty(paths[:kitty]),
    *parse_fcitx5(paths[:fcitx5]),
    *parse_catalog(paths[:catalog])
  ].sort_by { |item| [item.source, item.scope, item.shortcut, item.action] }
end

def shortcut_location(shortcut)
  line = shortcut.line.to_i
  line.positive? ? "#{shortcut.file}:#{line}" : shortcut.file.to_s
end

def shortcut_label(shortcut)
  status = shortcut.enabled ? "enabled" : "disabled"
  note = shortcut.note.to_s.empty? ? "" : " / #{shortcut.note}"
  "- `#{shortcut.shortcut}` -> #{shortcut.action} (#{shortcut.source}, #{shortcut.scope}, #{status}, #{shortcut_location(shortcut)}#{note})"
end

def grouped_duplicates(shortcuts, include_disabled: false, scoped: true)
  items = include_disabled ? shortcuts : shortcuts.select(&:enabled)
  groups = items.group_by do |shortcut|
    key = normalize_shortcut(shortcut.shortcut)
    scoped ? [shortcut.scope, key] : key
  end
  groups.select { |_key, members| members.length > 1 }
        .sort_by { |key, members| [key.to_s, members.length] }
end

def scoped_xremap_overlap?(members)
  members.all? { |shortcut| shortcut.source == "xremap" } &&
    members.any? { |shortcut| shortcut.scope.start_with?("only:", "not:") }
end

def available_shortcuts(shortcuts, scope: "global", limit: 80)
  used = shortcuts.select { |shortcut| shortcut.enabled && shortcut.scope == scope }
                  .map { |shortcut| normalize_shortcut(shortcut.shortcut) }
                  .to_set
  candidates = COMMON_MOD_SETS.product(COMMON_KEYS).map { |mods, key| "#{mods}+#{key}" }
  candidates.reject { |candidate| used.include?(normalize_shortcut(candidate)) }.first(limit)
end

def analysis_text(locale)
  ja = locale == :ja
  {
    title: ja ? "ショートカット解析" : "Shortcut Analysis",
    total: ja ? "合計" : "total",
    enabled: ja ? "有効" : "enabled",
    disabled: ja ? "無効/デフォルト" : "disabled/default",
    same_scope_count: ja ? "同一スコープ内の有効な重複" : "duplicate active shortcuts in same scope",
    cross_scope_count: ja ? "スコープをまたぐ有効な重複" : "duplicate active shortcuts across scopes",
    all_dup_count: ja ? "無効/デフォルトを含む重複" : "duplicate shortcuts including disabled/defaults",
    possible_count: ja ? "無効/デフォルトを含む潜在的な衝突" : "possible overlaps including disabled/defaults",
    xremap_count: ja ? "参考: スコープ付き xremap の重なり" : "reference scoped xremap overlaps",
    same_scope: ja ? "同一スコープ内の重複" : "Same-scope duplicates",
    same_scope_empty: ja ? "同一スコープ内の有効な重複は見つかりませんでした。" : "No enabled duplicates found in the same scope.",
    in_scope: ja ? "in" : "in",
    cross_scope: ja ? "スコープをまたぐ重複" : "Cross-scope duplicates",
    cross_scope_empty: ja ? "スコープをまたぐ有効な重複は見つかりませんでした。" : "No enabled duplicates found across scopes.",
    all_dup: ja ? "無効/デフォルトを含む重複" : "Duplicates including disabled/defaults",
    all_dup_empty: ja ? "無効/デフォルトを含めても重複は見つかりませんでした。" : "No duplicates found when disabled/default entries are included.",
    possible: ja ? "無効/デフォルトを含む潜在的な衝突" : "Potential overlaps including disabled/defaults",
    possible_empty: ja ? "無効/デフォルトを含めたスコープ間の衝突は見つかりませんでした。" : "No cross-scope overlaps found when disabled/default entries are included.",
    available: ja ? "利用可能なグローバル候補" : "Available global candidates",
    candidate_space: ja ? "候補範囲: #{COMMON_MOD_SETS.join(', ')} x #{COMMON_KEYS.length} 個の一般的なキー。これは実用的な探索範囲であり、ここにないキーがすべてグローバルに安全であることを証明するものではありません。" : "Candidate space: #{COMMON_MOD_SETS.join(', ')} x #{COMMON_KEYS.length} common keys. This is a practical search space, not proof that every omitted key is globally safe.",
    xremap: ja ? "参考: スコープ付き xremap の重なり" : "Reference: scoped xremap overlaps",
    xremap_note: ja ? "`only` や `not` などの xremap アプリケーションスコープを使っているため、通常は意図的な設定です。通常のスコープ間重複としては数えません。" : "These entries use xremap application scopes such as `only` and `not`, so they are usually intentional and are not counted as ordinary cross-scope duplicates.",
    xremap_empty: ja ? "スコープ付き xremap の重なりは見つかりませんでした。" : "No scoped xremap overlaps found."
  }
end

def render_analysis(shortcuts, locale: :en)
  text = analysis_text(locale)
  active_duplicates = grouped_duplicates(shortcuts, scoped: true)
  all_cross_scope_duplicates = grouped_duplicates(shortcuts, scoped: false)
                               .select { |_key, members| members.map(&:scope).uniq.length > 1 }
  xremap_scoped_overlaps = all_cross_scope_duplicates.select { |_key, members| scoped_xremap_overlap?(members) }
  cross_scope_duplicates = all_cross_scope_duplicates.reject { |_key, members| scoped_xremap_overlap?(members) }
  all_duplicates = grouped_duplicates(shortcuts, include_disabled: true, scoped: true)
  possible_overlaps = grouped_duplicates(shortcuts, include_disabled: true, scoped: false)
                      .select { |_key, members| members.map(&:scope).uniq.length > 1 }
                      .reject { |_key, members| scoped_xremap_overlap?(members) }
  global_available = available_shortcuts(shortcuts)

  lines = []
  lines << "# #{text[:title]}"
  lines << ""
  lines << "- #{text[:total]}: #{shortcuts.length}"
  lines << "- #{text[:enabled]}: #{shortcuts.count(&:enabled)}"
  lines << "- #{text[:disabled]}: #{shortcuts.count { |shortcut| !shortcut.enabled }}"
  lines << "- #{text[:same_scope_count]}: #{active_duplicates.length}"
  lines << "- #{text[:cross_scope_count]}: #{cross_scope_duplicates.length}"
  lines << "- #{text[:all_dup_count]}: #{all_duplicates.length}"
  lines << "- #{text[:possible_count]}: #{possible_overlaps.length}"
  lines << "- #{text[:xremap_count]}: #{xremap_scoped_overlaps.length}"
  lines << ""
  lines << "## #{text[:same_scope]}"
  lines << ""
  if active_duplicates.empty?
    lines << text[:same_scope_empty]
  else
    active_duplicates.each do |(scope, key), members|
      lines << "### `#{key}` #{text[:in_scope]} `#{scope}`"
      members.each { |shortcut| lines << shortcut_label(shortcut) }
      lines << ""
    end
  end
  lines << ""
  lines << "## #{text[:cross_scope]}"
  lines << ""
  if cross_scope_duplicates.empty?
    lines << text[:cross_scope_empty]
  else
    cross_scope_duplicates.each do |key, members|
      next if members.map(&:scope).uniq.length < 2

      lines << "### `#{key}`"
      members.each { |shortcut| lines << shortcut_label(shortcut) }
      lines << ""
    end
  end
  lines << ""
  lines << "## #{text[:all_dup]}"
  lines << ""
  if all_duplicates.empty?
    lines << text[:all_dup_empty]
  else
    all_duplicates.each do |(scope, key), members|
      lines << "### `#{key}` #{text[:in_scope]} `#{scope}`"
      members.each { |shortcut| lines << shortcut_label(shortcut) }
      lines << ""
    end
  end
  lines << ""
  lines << "## #{text[:possible]}"
  lines << ""
  if possible_overlaps.empty?
    lines << text[:possible_empty]
  else
    possible_overlaps.each do |key, members|
      lines << "### `#{key}`"
      members.each { |shortcut| lines << shortcut_label(shortcut) }
      lines << ""
    end
  end
  lines << "## #{text[:available]}"
  lines << ""
  lines << text[:candidate_space]
  lines << ""
  global_available.each { |shortcut| lines << "- `#{shortcut}`" }
  lines << ""
  lines << "## #{text[:xremap]}"
  lines << ""
  lines << text[:xremap_note]
  lines << ""
  if xremap_scoped_overlaps.empty?
    lines << text[:xremap_empty]
  else
    xremap_scoped_overlaps.each do |key, members|
      lines << "### `#{key}`"
      members.each { |shortcut| lines << shortcut_label(shortcut) }
      lines << ""
    end
  end
  lines << ""
  lines.join("\n")
end

def render_html(shortcuts)
  payload = JSON.pretty_generate(shortcuts.map(&:to_h))
  safe_payload = payload.gsub("<", "\\u003c")

  <<~HTML
    <!doctype html>
    <html lang="ja">
    <head>
      <meta charset="utf-8">
      <meta name="viewport" content="width=device-width, initial-scale=1">
      <title>Shortcut Index</title>
      <style>
        :root {
          color-scheme: light dark;
          --bg: #f7f7f4;
          --fg: #1f2328;
          --muted: #687076;
          --line: #d8dadd;
          --panel: #ffffff;
          --accent: #146c74;
          --chip: #e9efef;
        }
        @media (prefers-color-scheme: dark) {
          :root {
            --bg: #171a1c;
            --fg: #eceff1;
            --muted: #a3adb5;
            --line: #33383d;
            --panel: #202427;
            --accent: #63c7ce;
            --chip: #283236;
          }
        }
        * { box-sizing: border-box; }
        body {
          margin: 0;
          background: var(--bg);
          color: var(--fg);
          font: 14px/1.5 system-ui, -apple-system, BlinkMacSystemFont, "Segoe UI", sans-serif;
        }
        header {
          padding: 22px 28px 12px;
          border-bottom: 1px solid var(--line);
          background: var(--panel);
        }
        h1 {
          margin: 0 0 12px;
          font-size: 24px;
          font-weight: 700;
        }
        .summary {
          display: flex;
          flex-wrap: wrap;
          gap: 8px;
          color: var(--muted);
        }
        .chip,
        .filter-chip {
          padding: 4px 9px;
          border: 0;
          border-radius: 7px;
          background: var(--chip);
          color: var(--fg);
          font: inherit;
          white-space: nowrap;
        }
        .filter-chip {
          cursor: pointer;
        }
        .filter-chip:hover,
        .filter-chip.active {
          outline: 2px solid var(--accent);
          outline-offset: -2px;
        }
        main { padding: 18px 28px 32px; }
        .controls {
          display: grid;
          grid-template-columns: minmax(220px, 1fr) repeat(2, minmax(150px, 220px));
          gap: 10px;
          margin-bottom: 10px;
        }
        .quick-filters {
          display: flex;
          flex-wrap: wrap;
          gap: 8px;
          margin-bottom: 14px;
        }
        input, select {
          width: 100%;
          min-height: 38px;
          border: 1px solid var(--line);
          border-radius: 7px;
          padding: 8px 10px;
          background: var(--panel);
          color: var(--fg);
          font: inherit;
        }
        .table-wrap {
          overflow: auto;
          border: 1px solid var(--line);
          border-radius: 8px;
          background: var(--panel);
        }
        table {
          width: 100%;
          border-collapse: collapse;
          min-width: 980px;
        }
        th, td {
          padding: 8px 10px;
          border-bottom: 1px solid var(--line);
          text-align: left;
          vertical-align: top;
        }
        th {
          position: sticky;
          top: 0;
          background: var(--panel);
          color: var(--muted);
          font-weight: 650;
          z-index: 1;
        }
        tr:last-child td { border-bottom: 0; }
        code {
          padding: 2px 5px;
          border-radius: 5px;
          background: var(--chip);
          font-family: ui-monospace, SFMono-Regular, Menlo, Consolas, monospace;
          font-size: 13px;
        }
        .muted { color: var(--muted); }
        .source {
          color: var(--accent);
          font-weight: 700;
        }
        @media (max-width: 760px) {
          header, main { padding-left: 14px; padding-right: 14px; }
          .controls { grid-template-columns: 1fr; }
          h1 { font-size: 21px; }
        }
      </style>
    </head>
    <body>
      <header>
        <h1>Shortcut Index</h1>
        <div class="summary" id="summary"></div>
      </header>
      <main>
        <div class="controls">
          <input id="query" type="search" placeholder="検索: shortcut / action / scope / file">
          <select id="source"></select>
          <select id="scope"></select>
        </div>
        <div class="quick-filters" id="quick-filters"></div>
        <div class="table-wrap">
          <table>
            <thead>
              <tr>
                <th>source</th>
                <th>shortcut</th>
                <th>action</th>
                <th>scope</th>
                <th>note</th>
                <th>file</th>
              </tr>
            </thead>
            <tbody id="rows"></tbody>
          </table>
        </div>
      </main>
      <script type="application/json" id="shortcut-data">#{safe_payload}</script>
      <script>
        const shortcuts = JSON.parse(document.getElementById('shortcut-data').textContent);
        const query = document.getElementById('query');
        const source = document.getElementById('source');
        const scope = document.getElementById('scope');
        const rows = document.getElementById('rows');
        const summary = document.getElementById('summary');
        const quickFilters = document.getElementById('quick-filters');

        function escapeHtml(value) {
          return String(value ?? '').replace(/[&<>"']/g, c => ({
            '&': '&amp;', '<': '&lt;', '>': '&gt;', '"': '&quot;', "'": '&#39;'
          }[c]));
        }

        function optionList(values, label) {
          return [`<option value="">${label}</option>`]
            .concat([...new Set(values)].sort().map(v => `<option value="${escapeHtml(v)}">${escapeHtml(v)}</option>`))
            .join('');
        }

        function renderSummary(items) {
          const counts = shortcuts.reduce((acc, item) => {
            acc[item.source] = (acc[item.source] || 0) + 1;
            return acc;
          }, {});
          summary.innerHTML = [
            `<span class="chip">total ${shortcuts.length}</span>`,
            ...Object.entries(counts).sort().map(([name, count]) => `<button class="filter-chip" type="button" data-filter="source" data-value="${escapeHtml(name)}" translate="no">${escapeHtml(name)} ${count}</button>`),
            `<span class="chip">shown ${items.length}</span>`
          ].join('');
        }

        function renderQuickFilters() {
          const sources = [...new Set(shortcuts.map(item => item.source))].sort();
          const scopes = [...new Set(shortcuts.map(item => item.scope))].sort();
          quickFilters.innerHTML = [
            `<button class="filter-chip" type="button" data-filter="clear" data-value="">すべて</button>`,
            ...sources.map(value => `<button class="filter-chip" type="button" data-filter="source" data-value="${escapeHtml(value)}" translate="no">${escapeHtml(value)}</button>`),
            ...scopes.map(value => `<button class="filter-chip" type="button" data-filter="scope" data-value="${escapeHtml(value)}" translate="no">${escapeHtml(value)}</button>`)
          ].join('');
        }

        function applyFilter(filterKind, value) {
          if (filterKind === 'clear') {
            query.value = '';
            source.value = '';
            scope.value = '';
          } else if (filterKind === 'source') {
            source.value = value;
          } else if (filterKind === 'scope') {
            scope.value = value;
          }
          render();
        }

        function syncActiveChips() {
          document.querySelectorAll('.filter-chip[data-filter]').forEach(button => {
            const filterKind = button.dataset.filter;
            const value = button.dataset.value;
            const active = (filterKind === 'source' && source.value === value) ||
              (filterKind === 'scope' && scope.value === value) ||
              (filterKind === 'clear' && !source.value && !scope.value && !query.value);
            button.classList.toggle('active', active);
          });
        }

        function render() {
          const q = query.value.trim().toLowerCase();
          const src = source.value;
          const scp = scope.value;
          const filtered = shortcuts.filter(item => {
            if (src && item.source !== src) return false;
            if (scp && item.scope !== scp) return false;
            if (!q) return true;
            return [item.source, item.scope, item.shortcut, item.action, item.note, item.file]
              .join(' ')
              .toLowerCase()
              .includes(q);
          });

          rows.innerHTML = filtered.map(item => `
            <tr>
              <td translate="no"><button class="filter-chip source" type="button" data-filter="source" data-value="${escapeHtml(item.source)}">${escapeHtml(item.source)}</button></td>
              <td translate="no"><code>${escapeHtml(item.shortcut)}</code></td>
              <td translate="no">${escapeHtml(item.action)}</td>
              <td translate="no"><button class="filter-chip" type="button" data-filter="scope" data-value="${escapeHtml(item.scope)}">${escapeHtml(item.scope)}</button></td>
              <td class="muted" translate="no">${escapeHtml(item.note)}</td>
              <td class="muted" translate="no">${escapeHtml(item.file)}${item.line ? ':' + item.line : ''}</td>
            </tr>
          `).join('');
          renderSummary(filtered);
          syncActiveChips();
        }

        source.innerHTML = optionList(shortcuts.map(item => item.source), 'all sources');
        scope.innerHTML = optionList(shortcuts.map(item => item.scope), 'all scopes');
        renderQuickFilters();
        document.addEventListener('click', event => {
          const button = event.target.closest('.filter-chip[data-filter]');
          if (!button) return;
          applyFilter(button.dataset.filter, button.dataset.value);
        });
        [query, source, scope].forEach(el => el.addEventListener('input', render));
        render();
      </script>
    </body>
    </html>
  HTML
end

options = {
  hyprland: DEFAULT_HYPRLAND,
  xremap: DEFAULT_XREMAP,
  kitty: DEFAULT_KITTY,
  fcitx5: DEFAULT_FCITX5,
  catalog: DEFAULT_CATALOG,
  html: "shortcut_report.html",
  json: nil,
  analysis: nil,
  analysis_ja: nil
}

OptionParser.new do |parser|
  parser.banner = "Usage: ruby shortcut_app.rb [options]"
  parser.on("--hyprland PATH", "Hyprland config path") { |value| options[:hyprland] = File.expand_path(value) }
  parser.on("--xremap PATH", "xremap config path") { |value| options[:xremap] = File.expand_path(value) }
  parser.on("--kitty PATH", "kitty config path") { |value| options[:kitty] = File.expand_path(value) }
  parser.on("--fcitx5 PATH", "fcitx5 config directory") { |value| options[:fcitx5] = File.expand_path(value) }
  parser.on("--catalog PATH", "Known shortcut catalog YAML") { |value| options[:catalog] = value }
  parser.on("--html PATH", "Write searchable HTML report") { |value| options[:html] = value }
  parser.on("--json PATH", "Write collected data as JSON") { |value| options[:json] = value }
  parser.on("--analysis PATH", "Write duplicate/free-candidate analysis as Markdown") { |value| options[:analysis] = value }
  parser.on("--analysis-ja PATH", "Write Japanese duplicate/free-candidate analysis as Markdown") { |value| options[:analysis_ja] = value }
  parser.on("--no-html", "Do not write HTML") { options[:html] = nil }
end.parse!

shortcuts = collect_shortcuts(options)

if options[:json]
  FileUtils.mkdir_p(File.dirname(options[:json])) unless File.dirname(options[:json]) == "."
  File.write(options[:json], "#{JSON.pretty_generate(shortcuts.map(&:to_h))}\n")
end

if options[:html]
  FileUtils.mkdir_p(File.dirname(options[:html])) unless File.dirname(options[:html]) == "."
  File.write(options[:html], render_html(shortcuts))
end

if options[:analysis]
  FileUtils.mkdir_p(File.dirname(options[:analysis])) unless File.dirname(options[:analysis]) == "."
  File.write(options[:analysis], render_analysis(shortcuts))
end

if options[:analysis_ja]
  FileUtils.mkdir_p(File.dirname(options[:analysis_ja])) unless File.dirname(options[:analysis_ja]) == "."
  File.write(options[:analysis_ja], render_analysis(shortcuts, locale: :ja))
end

puts "Collected #{shortcuts.length} shortcuts"
puts "HTML: #{options[:html]}" if options[:html]
puts "JSON: #{options[:json]}" if options[:json]
puts "Analysis: #{options[:analysis]}" if options[:analysis]
puts "Analysis JA: #{options[:analysis_ja]}" if options[:analysis_ja]
