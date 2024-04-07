# frozen_string_literal: true

require 'spec_helper'
require 'type_casted_scopes/version'

describe 'TypeCastedScopes::Version' do
  describe '.gem_version' do
    it 'provides valid semantic versioning' do
      expect(TypeCastedScopes.gem_version.to_s).to match(/\d+\.\d+\.\d+/)
    end
  end
end
