require "date"
require "tmux/filterable_hash"
require "tmux/exception"
require "tmux/server"
require "tmux/session"
require "tmux/client"
require "tmux/window"
require "tmux/pane"
require "tmux/buffer"
require "tmux/status_bar"
require "tmux/options_list"
require "tmux/options"
require "tmux/widget"

# @todo Support querying and modifying keymaps
module Tmux
  @binary = `which tmux`.chomp
  @verbose = false

  class << self
    # Path of the tmux binary.
    # @return [String]
    attr_accessor :binary

    # Print verbose information on $stderr?
    # @return [Boolean]
    attr_accessor :verbose
    alias_method :verbose?, :verbose

    # Invokes a tmux command and returns all output.
    #
    # @param [String] command Command to invoke
    # @param [Boolean] unset_tmux If true, unsets $TMUX before calling
    #   tmux, to allow nesting
    # @return [String] all output
    # @raise [Exception::UnknownCommand]
    # @api private
    def invoke_command(cmd, unset_tmux = false)
      command = ""
      command << "TMUX='' " if unset_tmux
      command << "#{@binary} #{cmd}"

      $stderr.puts(command) if verbose?
      ret = `#{command} 2>&1`
      if ret.start_with?("unknown command:")
        raise Exception::UnknownCommand, ret.split(":", 2).last.strip
      else
        return ret
      end
    end
  end
end
