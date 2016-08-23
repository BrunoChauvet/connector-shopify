source 'https://rubygems.org'
ruby '2.2.3', :engine => 'jruby', :engine_version => '9.0.5.0'

# we are depending on a method that only appears in activesupport 4.2.5.1
# ActiveSupport::SecurityUtils.variable_size_secure_compare
gem 'rails', '>= 4.2.5.1'
gem 'turbolinks', '~> 2.5'
gem 'jquery-rails'
gem 'puma'
gem 'sinatra'
gem 'figaro'
gem 'httparty'
gem 'uglifier', '>= 1.3.0'
gem 'tzinfo-data', platforms: [:mingw, :mswin, :x64_mingw, :jruby]

# Shopify Api - Connec Gems
gem 'maestrano-connector-rails'
gem 'omniauth-shopify-oauth2', '~> 1.1'
gem 'shopify_api'

# jQuery based field validator for Twitter Bootstrap 3.
gem 'bootstrap-validator-rails'

gem 'redis-rails'

group :production, :uat do
  gem 'rails_12factor'
  gem 'activerecord-jdbcpostgresql-adapter', :platforms => :jruby
  gem 'pg', :platforms => :ruby
end

group :test, :develpment do
  gem 'activerecord-jdbcsqlite3-adapter', :platforms => :jruby
  gem 'sqlite3', :platforms => :ruby
end

group :test do
  gem 'simplecov'
  gem 'rspec-rails'
  gem 'factory_girl_rails'
  gem 'shoulda-matchers'
  gem 'timecop'
end
