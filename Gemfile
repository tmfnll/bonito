# frozen_string_literal: true

source 'https://rubygems.org'

git_source(:github) { |repo_name| "https://github.com/#{repo_name}" }

# Specify your gem's dependencies in dodo.gemspec
gemspec

gem 'timecop'

group :development, :test do
  gem 'activesupport', '~> 5.0'
  gem 'rubocop'
  gem 'simplecov', require: false
end

group :development do
  gem 'pry'
end
