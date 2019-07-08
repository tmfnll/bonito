# frozen_string_literal: true

lib = File.expand_path('lib', __dir__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'bonito/version'

Gem::Specification.new do |spec|
  spec.name          = 'bonito'
  spec.version       = Bonito::VERSION
  spec.authors       = ['Tom Finill']
  spec.email         = ['tomfinill@gmail.com']

  spec.summary       = 'A simple tool to create demo data'
  spec.description   = 'Create realistic demo data by simulating events occurring over some time period'
  spec.homepage      = 'https://github.com/TomFinill/bonito'
  spec.license       = 'MIT'

  # Prevent pushing this gem to RubyGems.org. To allow pushes either
  # set the 'allowed_push_host' to allow pushing to a single host or delete
  # this section to allow pushing to any host.
  if spec.respond_to?(:metadata)
    spec.metadata['allowed_push_host'] = "TODO: Set to 'http://mygemserver.com'"
  else
    raise 'RubyGems 2.0 or newer is required to protect against ' \
      'public gem pushes.'
  end

  spec.require_paths = ['lib']

  spec.add_dependency 'algorithms', '~> 0.5'
  spec.add_dependency 'ruby-progressbar'
  spec.add_dependency 'timecop'

  spec.add_development_dependency 'activesupport'
  spec.add_development_dependency 'bundler', '~> 2.0'
  spec.add_development_dependency 'factory_bot'
  spec.add_development_dependency 'faker', '~> 1.9.1'
  spec.add_development_dependency 'rake', '~> 12.3'
  spec.add_development_dependency 'rdoc'
  spec.add_development_dependency 'reek'
  spec.add_development_dependency 'rspec', '~> 3.0'
  spec.add_development_dependency 'rubocop'
  spec.add_development_dependency 'simplecov'

end
