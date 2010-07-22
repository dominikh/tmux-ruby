module Tmux
  # @api private
  module FilterableHash
    # @param [Hash] search
    # @return [Hash]
    # @api private
    def filter(search)
      self.select { |key, value|
        value.all? { |v_key, v_value|
          !search.has_key?(v_key) || v_value == search[v_key]
        }
      }
    end
  end
end
