local wezterm = require 'wezterm'
local act = wezterm.action

local config = wezterm.config_builder()

-- Appearance
-- Chosen from the gallery in ~/projects/wezterm-gallery (combos.html).
-- Runner-up, if this one wears thin:
--   config.color_scheme = 'Dracula'
--   config.font = wezterm.font_with_fallback { { family = 'Noto Sans Mono' } }
config.color_scheme = 'Night Owl (Gogh)'
config.font = wezterm.font_with_fallback { { family = 'IBM Plex Mono Text' } }
config.font_size = 10
config.line_height = 1.1
config.window_background_opacity = 1.0
config.window_decorations = 'TITLE | RESIZE'
config.window_padding = {
  left = 8,
  right = 8,
  top = 8,
  bottom = 8,
}

-- Measured in cells, not pixels, so the window gets physically smaller/larger
-- if font_size changes. Captured from a comfortable window at font_size 10.
config.initial_cols = 204
config.initial_rows = 45

-- Cursor
config.default_cursor_style = 'BlinkingBlock'
config.cursor_blink_rate = 600

-- Tab bar
config.use_fancy_tab_bar = true
config.tab_bar_at_bottom = false
config.hide_tab_bar_if_only_one_tab = false
config.show_new_tab_button_in_tab_bar = true

-- Scrollback / behavior
config.scrollback_lines = 10000
config.audible_bell = 'Disabled'
config.check_for_updates = false
config.adjust_window_size_when_changing_font_size = false

-- Right click pastes from the clipboard; left click still selects/copies.
config.mouse_bindings = {
  {
    event = { Down = { streak = 1, button = 'Right' } },
    mods = 'NONE',
    action = act.PasteFrom 'Clipboard',
  },
}

-- Left click: single click extends/creates selection as usual (default behavior kept).
-- Selecting text also copies it to the clipboard automatically.
config.selection_word_boundary = ' \t\n{}[]()"\'`,;:'

-- Handy extra keybindings (kept alongside the defaults)
config.keys = {
  { key = 'Enter', mods = 'ALT', action = act.ToggleFullScreen },
  { key = 'f', mods = 'CTRL|SHIFT', action = act.Search 'CurrentSelectionOrEmptyString' },
  { key = '|', mods = 'CTRL|SHIFT', action = act.SplitHorizontal { domain = 'CurrentPaneDomain' } },
  { key = '_', mods = 'CTRL|SHIFT', action = act.SplitVertical { domain = 'CurrentPaneDomain' } },
  { key = 'w', mods = 'CTRL|SHIFT', action = act.CloseCurrentPane { confirm = true } },
  { key = 'LeftArrow', mods = 'CTRL|SHIFT', action = act.ActivatePaneDirection 'Left' },
  { key = 'RightArrow', mods = 'CTRL|SHIFT', action = act.ActivatePaneDirection 'Right' },
  { key = 'UpArrow', mods = 'CTRL|SHIFT', action = act.ActivatePaneDirection 'Up' },
  { key = 'DownArrow', mods = 'CTRL|SHIFT', action = act.ActivatePaneDirection 'Down' },
}

return config
