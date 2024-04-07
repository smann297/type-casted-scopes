# frozen_string_literal: true

require 'type_casted_scopes/error'
require 'type_casted_scopes/validator'
require 'type_casted_scopes/core_ext'
require 'type_casted_scopes/definitions'
require 'type_casted_scopes/converter'

module TypeCastedScopes
  extend ActiveSupport::Concern

  class_methods do
    def process_typed_scopes(scopes = {}, *args)
      return where(nil) if scopes.nil? || (scopes.is_a?(Hash) && scopes.blank?)

      raise ArgumentError, 'The type_casted_scopes argument must be a hash or nil' unless
      scopes.is_a?(Hash)

      results = self
      scopes.each do |key, value|
        raise BlankValueError unless value.present?

        begin
          results = results.public_send(:"type_casted_scope_#{key}", *[value, args].flatten.compact)
        rescue NoMethodError
          raise InvalidFilterError, key
        end
      end
      results
    end

    def type_casted_scopes(*type_casted_scopes)
      @valid_attribute_scopes ||=
        columns.select { |x| %i[bigint boolean decimal integer float string text].include?(x.type) }
               .map { |x| [x.name, x.type] }.to_h

      type_casted_scopes.each do |attribute|
        unless @valid_attribute_scopes.key?(attribute.to_s)
          raise ArgumentError, "\"#{attribute}\" is not a valid attribute " \
            'filter. It must have a datatype of bigint, boolean, decimal, integer, float, ' \
            'string or text. The type_casted_scope method may be helpful.'
        end
        define_scope(attribute)
      end
    end

    def define_scope(attribute)
      define_singleton_method :"type_casted_scope_#{attribute}" do |value, *_args|
        type = @valid_attribute_scopes[attribute.to_s]
        Validator.validate(type, value)
        if %i[string text].include?(type)
          where("lower(#{attribute}) = ?", value.downcase)
        else
          where(attribute => value)
        end
      end
    end

    def type_casted_scope(scope_name, scope_type = 'string', body, &block)
      Validator.validate_scope_type(scope_type)
      define_singleton_method :"type_casted_scope_#{scope_name}" do |value, *args|
        Validator.validate(scope_type, value)
        scope(scope_name, body, &block)
        public_send(scope_name, *[Converter.convert_value(scope_type, value), args].flatten.compact)
      end
    end
  end
end
