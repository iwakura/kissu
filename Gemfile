source :rubygems

gem 'sinatra'
gem 'sinatra-flash', :require => 'sinatra/flash'
gem 'rack_csrf', :require => 'rack/csrf'
gem 'erubis'

gem 'mechanize', :require => false
gem 'json', :require => false
gem 'rubyzip', :require => false


group :test do
  gem 'shoulda'
  gem 'rack-test', :require => 'rack/test'
end

group :production do
  gem 'unicorn'
end

group :development do
  gem 'awesome_print'
end
