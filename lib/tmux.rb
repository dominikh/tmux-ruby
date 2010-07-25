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
    # @return [String] all output
    # @api private
    def invoke_command(command)
      command = "#{@binary} #{command}"

      $stderr.puts(command) if verbose?
      `#{command} 2>&1`
    end
  end
end
