require 'rbconfig'

source :rubygems

gemspec

gem 'bundler'
gem 'eventmachine', '~>1.0.0.beta'

unless ENV['TRAVIS']
  gem 'guard-rspec'

  case RbConfig::CONFIG['host_os']
  when /darwin/
    gem 'rb-fsevent'
    gem 'growl_notify'
  when /linux/
    gem 'rb-inotify'
    gem 'libnotify'
  end
end

platforms :jruby do
  gem 'jruby-openssl'
end
