module Tmux
  class Window
    class Status
      # Each status can be in different states: normal, current and alert
      class State
        def initialize(window, state)
          @window = window
          @state  = state
        end

        # @return [Symbol]
        attr_accessor :background_color
        undef_method "background_color"
        undef_method "background_color="
        def background_color
          get_option "bg"
        end

        def background_color=(color)
          set_option "fg", color
        end

        # @return [Symbol]
        attr_accessor :foreground_color
        undef_method "foreground_color"
        undef_method "foreground_color="
        def foreground_color
          get_option "fg"
        end

        def foreground_color=(color)
          set_option "fg", color
        end

        # The format in which the window is displayed in the status line window list.
        #
        # @return [String]
        attr_accessor :format
        undef_method "format"
        undef_method "format="
        def format
          get_option "format"
        end

        def format=(value)
          set_option "format"
        end

        # @return [Symbol]
        attr_accessor :attributes
        undef_method "attributes"
        undef_method "attributes="
        def attributes
          get_option "attr"
        end

        def attributes=(value)
          # FIXME string? array?
          set_option "attr", value
        end

        def get_option(option)
          @window.options.get option_name(option)
        end
        private :get_option

        def set_option(option, value)
          @window.options.set option_name(option), value
        end
        private :set_option

        def option_name(option)
          state = case @state
                  when :normal
                    ""
                  when :current
                    "current-"
                  when :alert
                    "alert-"
                  end
          "window-status-#{state}#{option}"
        end
        private :option_name
      end
    end
  end
end
