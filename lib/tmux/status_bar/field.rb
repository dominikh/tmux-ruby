module Tmux
  class StatusBar
    # This class represents a field in a {StatusBar status bar}. Every
    # {StatusBar status bar} has two fields, one on the left side and
    # one on the right side.
    #
    # A field can either display a simple {#text text}, or display a
    # {Widget widget}. While only one {Widget widget} can be displayed
    # at a time per field, a field will keep a stack of widgets, to
    # and from which new {Widget widgets} can be {#push_widget pushed}
    # and {#pop_widget popped}. This is useful for example when
    # temporarily displaying a {Widgets::ProgressBar progress bar}.
    class Field
      def initialize(status_bar, side)
        @status_bar = status_bar
        @side      = side
        @widgets   = []
        @backups   = []
      end

      # Pushes a widget to the stack, making it the currently visible
      # one.
      #
      # @param [Widget] widget the widget to push to the stack
      # @return [void]
      def push_widget(widget)
        @backups << self.text
        @widgets << widget
        widget.field = self
      end
      alias_method :add_widget, :push_widget

      # Removes the current {Widget widget} from the stack.
      #
      # @param [Widget] pop If not nil, try to remove the specified
      #   widget instead of popping off the topmost one.
      # @return [Widget, nil] the {Widget widget} which has been popped
      def pop_widget(pop = nil)
        widget = pop || @widgets.first
        pos = @widgets.index(widget)
        @widgets.delete_at(pos)
        backup = @backups.delete_at(pos)

        self.text = backup if backup and pos == 0
        widget
      end
      alias_method :remove_widget, :pop_widget

      # @overload widget
      #   @return [Widget] The currently displayed {Widget widget},
      #     that is the one on top of the stack.
      # @overload widget=(widget)
      #   Overwrites the stack of {Widget widgets} and makes `widget` the only
      #   {Widget widget}.
      #
      #   @return [Widget]
      # @return [Widget] The currently displayed {Widget widget},
      #   that is the one on top of the stack.
      attr_accessor :widget
      undef_method "widget"
      undef_method "widget="
      def widget
        @widgets.last
      end

      def widget=(widget)
        restore
        push_widget(widget)
      end

      # Removes all {Widget widgets} from the stack, restoring the
      # {StatusBar status bar's} original state.
      #
      # @return [void]
      def restore
        while pop_widget; end
      end

      # @return [String]
      attr_accessor :text
      undef_method "text"
      undef_method "text="
      def text
        @status_bar.session.options.get "status-#@side"
      end

      def text=(val)
        meth = "status_#@side="
        @status_bar.session.options.set "status-#@side", val
      end

      # @return [Symbol]
      attr_accessor :background_color
      undef_method "background_color"
      undef_method "background_color="
      def background_color
        @status_bar.session.options.get "status-#@side-bg"
      end

      def background_color=(color)
        @status_bar.session.options.set "status-#@side-bg", color
      end

      # @return [Symbol]
      attr_accessor :foreground_color
      undef_method "foreground_color"
      undef_method "foreground_color="
      def foreground_color
        @status_bar.session.options.get "status-#@side-fg"
      end

      def foreground_color=(color)
        @status_bar.session.options.set "status-#@side-fg", color
      end

      # @return [Number]
      attr_accessor :max_length
      undef_method "max_length"
      undef_method "max_length="
      def max_length
        @status_bar.session.options.get "status-#@side-length"
      end

      def max_length=(num)
        @status_bar.session.options.set "status-#@side-length", num
      end
    end
  end
end
