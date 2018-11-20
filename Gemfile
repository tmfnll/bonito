# frozen_string_literal: true

source 'https://rubygems.org'

git_source(:github) { |repo_name| "https://github.com/#{repo_name}" }

# Specify your gem's dependencies in dodo.gemspec
gemspec

group :development, :test do
  gem 'activesupport'
  gem 'rubocop'
  gem 'simplecov', require: false
  gem 'travis'
  gem 'travis-lint'
  gem 'factory_bot'
end

group :development do
  gem 'pry'
end
