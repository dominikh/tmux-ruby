module Tmux
  module Widgets
    class ProgressBar < Widget
      # @overload value
      #   @return [Number]
      # @overload value=(new_value)
      #   Sets an absolute value. It will be automatically
      #   converted to a percentage when rendered.
      #
      #   @return [Number]
      # @return [Number]
      attr_accessor :value
      undef_method "value="

      def value=(new_value)
        @value = new_value
        display
      end

      # @param [String] title Title for the progress bar
      # @param [Number] total The maximal value of the progress bar
      # @param field (see Widget#initialize)
      def initialize(title, total)
        super()
        @title      = title
        @total      = total.to_f
        @value      = 0
      end

      # Display the progress bar. {#value=} automatically calls this
      # method to update the bar.
      #
      # @return [void]
      def display
        return unless can_display?
        s = "#{@title}: "
        remaining_chars = @max_length - s.size - 3 # 3 = "|" + "|" + ">"
        return if remaining_chars <= 0

        bar = "=" * (((@value / @total) * remaining_chars).ceil - 1) + ">"
        bar << " " * (remaining_chars - bar.size) unless (remaining_chars - bar.size) < 0
        s << "|#{bar}|"

        @field.text = s
      end
    end
  end
end
