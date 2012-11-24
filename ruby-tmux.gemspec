require File.expand_path("../lib/tmux/version", __FILE__)

Gem::Specification.new do |gem|
  gem.name    = 'tmux-ruby'
  gem.version = String.new Tmux::VERSION
  gem.date    = Date.today.to_s

  gem.summary = "ruby library to control tmux"
  gem.description = "ruby library to control tmux"

  gem.authors  = ['Dominik Honnef']
  gem.email    = 'dominikh@fork-bomb.org'
  gem.homepage = 'https://github.com/dominikh/tmux-ruby'

  #gem.add_dependency('rake')
  gem.add_development_dependency('rspec', [">= 2.0.0"])

  # ensure the gem is built out of versioned files
  gem.files = Dir['{bin,lib,man,test,spec}/**/*', 'README*', 'LICENSE*'] & `git ls-files -z`.split("\0")
end
