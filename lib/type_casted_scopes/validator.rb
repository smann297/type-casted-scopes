# frozen_string_literal: true

require 'type_casted_scopes/error'
require 'type_casted_scopes/definitions'
require 'active_record'

module TypeCastedScopes
  class Validator
    class << self
      def validate_type_casted_scope(scope_type, value)
        raise TypeCastedScopes::InvalidValueError, value unless
        Definitions.public_send(scope_type.to_sym, value)
      end

      def validate_scope_type(scope_type)
        raise ArgumentError, "#{scope_type} is not a valid scope type" unless
        ['bigint', :bigint,
         'boolean', :boolean,
         'decimal', :decimal,
         'integer', :integer,
         'float', :float,
         'string', :string,
         'text', :text].include?(scope_type) || Definitions.respond_to?(scope_type.to_sym)
      end

      def validate(type, value)
        case type
        when 'string', :string, 'text', :text
          true
        when 'boolean', :boolean
          raise TypeCastedScopes::InvalidValueError, value unless [true, false].include?(value) || value&.boolean_value?
        when 'bigint', :bigint, 'integer', :integer
          raise TypeCastedScopes::InvalidValueError, value unless value.is_a?(Integer) || value&.integer_value?
        when 'decimal', :decimal, 'float', :float
          raise TypeCastedScopes::InvalidValueError, value unless value.is_a?(Float) || value&.decimal_or_float_value?
        else
          validate_type_casted_scope(type, value)
        end
      end
    end
  end
end
