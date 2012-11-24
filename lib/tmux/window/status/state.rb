module Tmux
  class Window
    class Status
      # Each status can be in different states: normal, current and alert
      class State
        def initialize(window, state)
          @window = window
          @state  = state
        end

        # @!attribute background_color
        #
        # @return [Symbol]
        def background_color
          get_option "bg"
        end

        def background_color=(color)
          set_option "fg", color
        end

        # @!attribute foreground_color
        #
        # @return [Symbol]
        def foreground_color
          get_option "fg"
        end

        def foreground_color=(color)
          set_option "fg", color
        end

        # @!attribute format
        #
        # The format in which the window is displayed in the status line window list.
        #
        # @return [String]
        def format
          get_option "format"
        end

        def format=(value)
          set_option "format"
        end

        # @!attribute attributes
        #
        # @return [Symbol]
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
