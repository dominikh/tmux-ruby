require "tmux/status_bar/field"

module Tmux
  # Every {Session session} has a status bar. This is where various
  # information as well as a list of {Window windows} will be
  # displayed. For this purpose, the status bar is divided into three
  # parts: the left, center and right part. While the center part
  # displays the window list, the left and right part can be set to
  # display any text.
  #
  # This class allows accessing various attributes (e.g. the
  # {#background_color background color} of the bar) and the
  # editable parts ({#left left} and {#right right}).
  #
  # Note: You will not have to instantiate this class. Use
  # {Session#status_bar} instead.
  class StatusBar
    # @return [Session]
    attr_reader :session
    # The left {Field field} which may display custom {Field#text
    # text} and {Widget widgets}.
    #
    # @return [Field]
    attr_reader :left

    # The right {Field field} which may display custom {Field#text
    # text} and {Widget widgets}.
    #
    # @return [Field]
    attr_reader :right
    # @param [Session] session
    def initialize(session)
      @session = session
      @left    = Field.new(self,  :left)
      @right   = Field.new(self, :right)
    end

    # Hides the status bar.
    #
    # @return [void]
    def hide
      @session.options.status = false
    end

    # Shows the status bar.
    #
    # @return [void]
    def show
      @session.options.status = true
    end

    # @return [Symbol]
    attr_accessor :background_color
    undef_method "background_color"
    undef_method "background_color="
    def background_color
      @session.options.status_bg
    end

    def background_color=(color)
      @session.options.status_bg = color
    end

    # @return [Symbol]
    attr_accessor :foreground_color
    undef_method "foreground_color"
    undef_method "foreground_color="
    def foreground_color
      @session.options.status_fg
    end

    def foreground_color=(color)
      @session.options.status_fg = color
    end

    # @return [Number] The interval in which the status bar will be
    #   updated.
    attr_accessor :interval
    undef_method "interval"
    undef_method "interval="
    def interval
      @session.options.status_interval
    end

    def interval=(value)
      @session.options.status_interval = value
    end

    # Sets the justification of the window list component of the status
    # line.
    #
    # @return [Symbol<:left, :right, :centre>]
    attr_accessor :justification
    undef_method "justification"
    undef_method "justification="
    def justification
      @session.options.status_justify
    end

    def justification=(val)
      @session.options.status_justify = val
    end

    # @return [Symbol<:emacs, :vi>]
    attr_accessor :keymap
    undef_method "keymap"
    undef_method "keymap="
    def keymap
      # TODO keymap class?
      @session.options.status_keys
    end

    def keymap=(val)
      @session.options.status_keys = val
    end

    # Instruct tmux to treat top-bit-set characters in
    # {StatusBar::Field#text} as UTF-8. Notably, this is important for
    # wide characters. This option defaults to false.
    #
    # @return [Boolean]
    attr_accessor :utf8
    undef_method "utf8"
    undef_method "utf8="
    def utf8
      @session.options.status_utf8
    end
    alias_method :utf8?, :utf8

    def utf8=(bool)
      @session.options.status_utf8 = bool
    end
  end
end
