require File.expand_path("../lib/tmux/version", __FILE__)

Gem::Specification.new do |gem|
  gem.name    = 'tmux-ruby'
  gem.version = String.new Tmux::VERSION
  gem.date    = Date.today.to_s

  gem.summary = "Ruby library to control tmux"
  gem.description = "Ruby library to control tmux"

  gem.authors  = ['Dominik Honnef']
  gem.email    = 'dominikh@fork-bomb.org'
  gem.homepage = 'https://github.com/dominikh/tmux-ruby'

  gem.files = Dir['{lib,examples}/**/*', 'README.md', 'LICENSE', '.yardopts']
end
