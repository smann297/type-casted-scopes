# frozen_string_literal: true

require './lib/type_casted_scopes/version'

Gem::Specification.new do |s|
  s.name = 'type-casted-scopes'
  s.version = TypeCastedScopes.gem_version.to_s
  s.date = '2022-09-11'
  s.authors = ['Sean Manning']
  s.summary = 'Module providing type casted scopes for' \
              'filtering of ActiveRecord models.'
  s.homepage = 'https://github.com/smann297/type-casted-scopes'
  s.files = ['lib/type_casted_scopes.rb']
  s.require_paths = ['lib']
  s.license = 'MIT'
  s.required_ruby_version = '>= 2.5'
  s.add_dependency 'activerecord', ENV['ACTIVE_RECORD_VERSION'] || '>= 5.0.7.2'
  s.add_development_dependency 'database_cleaner'
  s.add_development_dependency 'rspec', '>= 3.2'
  s.add_development_dependency 'rubocop'
  s.add_development_dependency 'sqlite3'
end
