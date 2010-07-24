# -*- coding: utf-8 -*-
module Tmux
  module Widgets
    # # Description
    #
    # Tmux::Widgets::ProgressBar offers an easy way of displaying progress
    # bars in the {Tmux::StatusBar status bar}.
    #
    # Thanks to the widget and stack system of tmux-ruby, a progress
    # bar can be temporarily displayed without destroying previous
    # contents of the {Tmux::StatusBar status bar}, offering an
    # unobtrusive way of displaying the progress of a long running
    # system. As soon as the progress bar is not needed anymore, it
    # can be removed from the stack, revealing any previous content of
    # the {Tmux::StatusBar status bar}.
    #
    #
    # # Features
    #
    # - a freely definable maximum value
    # - automatic conversion of absolute values to their respective
    #   percentage
    # - automatic scaling of the progress bar, adapting to the available width in the status bar
    # - labels
    #
    #
    # # Example
    #     require "tmux"
    #     require "tmux/widgets/progress_bar" # widgets won't be required by default
    #
    #     server = Tmux::Server.new
    #     session = server.session # returns the first available session. Actual applications can determine the appropriate session.
    #
    #     pbar = Tmux::Widgets::ProgressBar.new("Download") # initialize a new progress bar with the label "Download"
    #     session.status_bar.right.add_widget(pbar) # add the progress bar to the right part of the status bar and display it
    #
    #     num_files = 24 # in a real application, we would dynamically determine the amount of files/mails/… to download
    #     pbar.total = num_files
    #
    #     num_files.times do
    #       # in a real application, we would be downloading something here
    #       pbar.value += 1
    #       sleep 0.1
    #     end
    #
    #     sleep 1 # give the user a chance to see that the process has finished
    #
    #     # Remove the progress bar again, restoring any old content of the status bar.
    #     # Note: by passing the progress bar to #pop_widget, we avoid breaking the stack
    #     # if another application decided to display it's own widget on top of ours.
    #     session.status_bar.right.pop_widget(pbar)
    #
    #
    # # Screenshot
    # ![Screenshot of ProgressBar](http://doc.fork-bomb.org/tmux/screenshots/progress_bar.png)

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

      # @return [String]
      attr_accessor :label
      # @return [Number]
      attr_accessor :total

      # @param [String] label Label for the progress bar
      # @param [Number] total The maximal value of the progress bar
      # @param field (see Widget#initialize)
      def initialize(label = "Progress", total = 100)
        super()
        @label      = label
        @total      = total
        @value      = 0
      end

      # Display the progress bar. {#value=} automatically calls this
      # method to update the widget.
      #
      # @return [void]
      def display
        return unless can_display?
        s = "#{@label}: "
        remaining_chars = @max_length - s.size - 3 # 3 = "|" + "|" + ">"
        return if remaining_chars <= 0

        bar = "=" * (((@value / @total.to_f) * remaining_chars).ceil - 1) + ">"
        bar << " " * (remaining_chars - bar.size) unless (remaining_chars - bar.size) < 0
        s << "|#{bar}|"

        @field.text = s
      end
    end
  end
end
