require File.expand_path("../lib/tmux/version", __FILE__)

Gem::Specification.new do |gem|
  gem.name    = 'tmux-ruby'
  gem.version = String.new Tmux::VERSION

  gem.summary = "Ruby library to control tmux"
  gem.description = "Ruby library to control tmux"

  gem.authors  = ['Dominik Honnef']
  gem.email    = 'dominikh@fork-bomb.org'
  gem.homepage = 'https://github.com/dominikh/tmux-ruby'
  gem.license  = 'MIT'

  gem.add_dependency "filesize"
  gem.required_ruby_version = ">=1.9.1"
  gem.has_rdoc = "yard"

  gem.files = Dir['{lib}/**/*', 'README.md', 'LICENSE', '.yardopts']
end
