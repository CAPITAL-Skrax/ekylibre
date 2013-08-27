source 'https://rubygems.org'

gem 'rails', '3.2.14'

# Database adapters
gem 'pg' # Needed for some tasks
gem 'activerecord-postgis-adapter'
# gem 'activerecord-spatialite-adapter'
# gem 'squeel'

gem 'routing-filter'

# General
gem 'exception_notification'

# Views helpers
gem 'active-list'
gem 'haml'
gem 'turbolinks'
#gem "google_visualr", ">= 2.1"
gem 'lazy_high_charts'
gem "calendar_helper", "~> 0.2.5"

# Models helpers
gem 'acts_as_list'
gem 'state_machine'
gem 'awesome_nested_set'
gem 'enumerize'
gem 'sneaky-save'
# gem 'paper_trail'

# Authentication
gem 'devise'
gem 'devise-i18n-views'

# Attachments
gem 'paperclip'
gem 'paperclip-document'

# Forms
gem 'simple_form'
gem 'cocoon'

# I18n and localeapp
gem 'i18n-complements'
#gem "jeweler", "> 1.6.4"
#gem 'i18n-spec'
#gem 'localeapp'

# XML Parsing/Writing, HTML extraction
gem 'nokogiri'
gem 'libxml-ruby', :require => 'libxml'
gem 'mechanize'
gem 'savon', '~> 2.2.0'

# Security
gem 'strong_parameters'

# Reporting
# gem 'thinreports-rails'
# Need rjb which need $ sudo apt-get install openjdk-7-jdk and set JAVA_HOME and add a line in environement.rb
gem 'beardley'
gem 'prawn', '~> 0.12.0'

# Import/Export
gem 'fastercsv'
gem 'rgeo-shapefile'
gem 'rubyzip', :require => 'zip/zip'
gem 'ofx-parser'

# Demo data
gem 'ffaker'

# Javascript framework
gem 'jquery-rails'
gem 'jquery-ui-rails'
gem 'formize', '~> 1.1.0'
# gem 'jquery_mobile_rails'

# Reading RSS feeds
gem 'feedzirra', '~> 0.2.0.rc2'


# gem 'ruby-progressbar', '~> 1.0.2'

# Gems used only for assets and not required
# in production environments by default.
group :assets do
  gem 'sass-rails',   '~> 3.2.3'
  gem 'coffee-rails', '~> 3.2.1'
  gem 'compass', '~> 0.13.alpha.4'
  gem 'compass-rails'
  gem 'zurb-foundation'
  gem 'agric'
  # gem 'codemirror-rails'
  gem 'turbo-sprockets-rails3'
  gem 'oily_png'
  gem 'jquery-turbolinks'

  # See https://github.com/sstephenson/execjs#readme for more supported runtimes
  # gem 'libv8', '~> 3.11.8'
  gem 'therubyracer', :platform => :ruby

  gem 'uglifier', '>= 1.0.3'
end

group :development do
  # gem 'rack-mini-profiler'
  gem 'quiet_assets'
  gem 'better_errors'
  gem 'binding_of_caller'
  gem 'rails_best_practices'
  # Project Management / Model
  gem 'railroady'
  # gem 'rails-erd', github: "burisu/rails-erd"

  gem 'thin'
end

group :development, :test do
  gem 'factory_girl_rails'
  gem 'spinach-rails'
end

group :test do
  gem 'capybara'
  gem 'capybara-webkit'
  gem 'selenium-webdriver'
  gem 'capybara-screenshot'
  gem "launchy"
  gem 'rspec-rails'
  gem 'awesome_print'
  gem 'pry'
  # database_cleaner is not required, but highly recommended
  gem 'database_cleaner'
  gem 'coveralls', '>= 0.6', :require => false
end

