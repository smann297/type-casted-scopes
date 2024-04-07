# frozen_string_literal: true

module TypeCastedScopes
  module Definitions
    def self.custom_definition(value)
      value != 'foo'
    end
  end
end

class Student < ActiveRecord::Base
  include TypeCastedScopes
  belongs_to :university

  type_casted_scopes :first_name, :last_name, :student_id, :age, :weighted_gpa, :gpa, :honor_roll, :university_id

  type_casted_scope :at_risk, :boolean, ->(value, context) {
    raise TypeCastedScopes::ForbiddenFilterError, :at_risk unless
    context[:current_user] && context[:current_user].admin?

    value ? where('gpa < ?', 2.5) : where('gpa >= ?', 2.5)
  }

  type_casted_scope :fname, ->(value) {
    where('first_name LIKE ?', value)
  }

  type_casted_scope :name_search, ->(value, options = nil) {
    if options && options[:case_sensitive]
      where('first_name = ?', value)
    else
      where('first_name LIKE ?', value)
    end
  }

  type_casted_scope :lname, :custom_definition, ->(value) {
    where('last_name LIKE ?', value)
  }

  type_casted_scope :university_mascot, :string, ->(value) {
    joins(:university).where('lower(universities.mascot) = ?', value.downcase)
  }
end

class User < ActiveRecord::Base
end

class University < ActiveRecord::Base
  has_many :students
end
