module Tmux

  module Options
    require "tmux/options/option"
    require "tmux/options/number_option"
    require "tmux/options/string_option"
    require "tmux/options/boolean_option"
    require "tmux/options/word_array_option"
    require "tmux/options/char_array_option"
    require "tmux/options/symbol_option"
    require "tmux/options/bell_action_option"
    require "tmux/options/color_option"
    require "tmux/options/attr_option"
    require "tmux/options/keymap_option"
    require "tmux/options/justification_option"
    require "tmux/options/clock_mode_style_option"

    # Table with option names and their appropriate typecasts.
    Mapping = {
      "base-index" => NumberOption,
      "bell-action" => BellActionOption,
      "buffer-limit" => NumberOption,
      "default-command" => StringOption,
      "default-path" => StringOption,
      "default-shell" => StringOption,
      "default-terminal" => StringOption,
      "detach-on-destroy" => BooleanOption,
      "display-panes-colour" => ColorOption,
      "display-panes-active-colour" => ColorOption,
      "display-panes-time" => NumberOption,
      "display-time" => NumberOption,
      "history-limit" => NumberOption,
      "lock-after-time" => NumberOption,
      "lock-command" => StringOption,
      "lock-server" => BooleanOption,
      "message-attr" => AttrOption,
      "message-bg" => ColorOption,
      "message-fg" => ColorOption,
      "message-limit" => NumberOption,
      "mouse-select-pane" => BooleanOption,
      "pane-active-border-bg" => ColorOption,
      "pane-active-border-fg" => ColorOption,
      "pane-border-bg" => ColorOption,
      "pane-border-fg" => ColorOption,
      "prefix" => SymbolOption, #  C-b # TODO keycombo
      "repeat-time" => NumberOption,
      "set-remain-on-exit" => BooleanOption,
      "set-titles" => BooleanOption,
      "set-titles-string" => StringOption,
      "status" => BooleanOption,
      "status-attr" => AttrOption,
      "status-bg" => ColorOption,
      "status-fg" => ColorOption,
      "status-interval" => NumberOption,
      "status-justify" => JustificationOption,
      "status-keys" => KeymapOption,
      "status-left" => StringOption,
      "status-left-attr" => AttrOption,
      "status-left-bg" => ColorOption,
      "status-left-fg" => ColorOption,
      "status-left-length" => NumberOption,
      "status-right" => StringOption,
      "status-right-attr" => AttrOption,
      "status-right-bg" => ColorOption,
      "status-right-fg" => ColorOption,
      "status-right-length" => NumberOption,
      "status-utf8" => BooleanOption,
      "terminal-overrides" => StringOption, #TODO "*88col*:colors=88,*256col*:colors=256"
      "update-environment" => WordArrayOption,
      "visual-activity" => BooleanOption,
      "visual-bell" => BooleanOption,
      "visual-content" => BooleanOption,
      "escape-time" => NumberOption,
      "quiet" => BooleanOption,
      "aggressive-resize" => BooleanOption,
      "alternate-screen" => BooleanOption,
      "automatic-rename" => BooleanOption,
      "clock-mode-colour" => ColorOption,
      "clock-mode-style" => ClockModeStyleOption,
      "force-height" => NumberOption,
      "force-width" => NumberOption,
      "main-pane-height" => NumberOption,
      "main-pane-width" => NumberOption,
      "mode-attr" => AttrOption,
      "mode-bg" => ColorOption,
      "mode-fg" => ColorOption,
      "mode-keys" => KeymapOption,
      "mode-mouse" => BooleanOption,
      "monitor-activity" => BooleanOption,
      "monitor-content" => StringOption,
      "remain-on-exit" => BooleanOption,
      "synchronize-panes" => BooleanOption,
      "utf8" => BooleanOption,
      "window-status-alert-attr" => AttrOption,
      "window-status-alert-bg" => ColorOption,
      "window-status-alert-fg" => ColorOption,
      "window-status-attr" => AttrOption,
      "window-status-bg" => ColorOption,
      "window-status-current-attr" => AttrOption,
      "window-status-current-bg" => ColorOption,
      "window-status-current-fg" => ColorOption,
      "window-status-current-format" => StringOption,
      "window-status-fg" => ColorOption,
      "window-status-format" => StringOption,
      "word-separators" => CharArrayOption,
      "xterm-keys" => BooleanOption,
    }
  end
end
