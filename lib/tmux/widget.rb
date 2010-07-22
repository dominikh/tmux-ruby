module Tmux
  # @abstract Subclass this class, provide a meaningful #display
  #   method and make sure it is being called.
  class Widget
    # @return [Field]
    attr_accessor :field
    undef_method "field="

    def field=(new_field)
      @field = new_field
      if new_field
        @max_length = new_field.max_length # Cache this to avoid constantly pulling the option
      else
        @max_length = 0
      end
    end

    def initialize
      @max_length = 0
      @field      = nil
    end

    # Displays the widget if `@field` is not `nil`.
    #
    # @api abstract
    # @return [void]
    def display
    end

    # @return [Boolean] True if `@field` is not `nil` and `@max_length` is > 0
    def can_display?
      true if @field && @max_length > 0
    end
  end
end
