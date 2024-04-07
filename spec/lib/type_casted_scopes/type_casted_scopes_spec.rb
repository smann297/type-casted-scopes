# frozen_string_literal: true

require 'type_casted_scopes'
require 'spec_helper'

describe TypeCastedScopes do
  describe 'filtering active record models' do
    let(:admin) { User.create(admin: true) }
    let(:user) { User.create(admin: false) }
    let(:student1) do
      Student.create(first_name: 'John', last_name: 'Doe', age: 18,
                     gpa: 4.0, weighted_gpa: 4.26522643,
                     student_id: 24_672_467_426, university_id: 1, honor_roll: true)
    end
    let(:student2) do
      Student.create(first_name: 'Jane', last_name: 'Doe', age: 17,
                     gpa: 2.0, weighted_gpa: 2.45992473,
                     student_id: 82_737_272_737, university_id: 2, honor_roll: false)
    end

    describe '#type_casted_scopes' do
      it 'raises an ArgumentError if an argument is not a attribute' do
        expect { Student.type_casted_scopes(:undefined_attribute) }.to raise_error(ArgumentError)
      end

      it 'does not raise an error if the arguments are all attributes' do
        expect { Student.type_casted_scopes(:first_name, :last_name, :age, :gpa, :honor_roll) }.not_to raise_error
      end

      it 'creates a class method for each filter to be called later' do
        %i[first_name last_name age gpa honor_roll].each do |filter|
          expect(Student.respond_to?(:"type_casted_scope_#{filter}")).to eq(true)
        end
      end

      context 'scope type is string or text' do
        it 'is case insensitive' do
          expect(Student.process_typed_scopes(first_name: 'john')).to eq([student1])
        end
        it { expect(Student.process_typed_scopes(first_name: 'John')).to eq([student1]) }
      end

      context 'scope type is bigint' do
        it { expect(Student.process_typed_scopes(student_id: '24672467426')).to eq([student1]) }
        it { expect(Student.process_typed_scopes(student_id: '82737272737')).to eq([student2]) }
      end

      context 'scope type integer' do
        it { expect(Student.process_typed_scopes(age: '18')).to eq([student1]) }
        it { expect(Student.process_typed_scopes(age: '17')).to eq([student2]) }
      end

      context 'scope type decimal' do
        it { expect(Student.process_typed_scopes(weighted_gpa: '4.26522643')).to eq([student1]) }
        it { expect(Student.process_typed_scopes(weighted_gpa: '2.45992473')).to eq([student2]) }
      end

      context 'scope type float' do
        it { expect(Student.process_typed_scopes(gpa: '4.0')).to eq([student1]) }
        it { expect(Student.process_typed_scopes(gpa: '2.0')).to eq([student2]) }
      end

      context 'scope type is boolean' do
        it { expect(Student.process_typed_scopes(honor_roll: 'true')).to eq([student1]) }
        it { expect(Student.process_typed_scopes(honor_roll: 'false')).to eq([student2]) }
      end
    end

    describe '#process_typed_scopes' do
      it 'returns an ActiveRecord::Relation' do
        expect(Student.process_typed_scopes).to eq([student1, student2])
        expect(Student.where(first_name: 'John').process_typed_scopes).to eq([student1])
        expect(Student.where(first_name: 'Jane').process_typed_scopes).to eq([student2])
      end

      it 'raises an error if type_casted_scopes is not a hash or nil' do
        expect(Student.process_typed_scopes(nil)).to eq([student1, student2])
        expect(Student.process_typed_scopes({})).to eq([student1, student2])
        expect { Student.process_typed_scopes([{ first_name: 'john' }]) }.to raise_error(ArgumentError, 'The type_casted_scopes argument must be a hash or nil')
        expect { Student.process_typed_scopes('john') }.to raise_error(ArgumentError, 'The type_casted_scopes argument must be a hash or nil')
      end

      it 'does not require a second argument' do
        expect(Student.process_typed_scopes(first_name: 'John')).to eq([student1])
        expect(Student.process_typed_scopes(first_name: 'Jane')).to eq([student2])
      end

      it 'raises BlankValueError if filter value is blank' do
        expect { Student.process_typed_scopes(first_name: '') }.to raise_error(TypeCastedScopes::BlankValueError)
      end

      it 'handles single type_casted_scopes correctly' do
        expect(Student.process_typed_scopes({ at_risk: 'false' }, current_user: admin)).to eq([student1])
        expect(Student.process_typed_scopes({ at_risk: 'true' }, current_user: admin)).to eq([student2])
      end

      it 'handles multiple type_casted_scopes correctly' do
        expect(Student.process_typed_scopes({ at_risk: 'false', first_name: 'John' }, current_user: admin)).to eq([student1])
        expect(Student.process_typed_scopes({ at_risk: 'true', first_name: 'Jane' }, current_user: admin)).to eq([student2])
        expect { Student.process_typed_scopes({ at_risk: 'true', first_name: 'Jane' }, current_user: user) }.to raise_error(TypeCastedScopes::ForbiddenFilterError)
      end

      it 'does not mutate the previous active record relation' do
        expect(Student.where(first_name: 'John').process_typed_scopes({ at_risk: 'false', first_name: 'John' }, current_user: admin)).to eq([student1])
        expect(Student.where(first_name: 'Jane').process_typed_scopes({ at_risk: 'true', first_name: 'Jane' }, current_user: admin)).to eq([student2])
        expect(Student.where(first_name: 'Foo').process_typed_scopes({ at_risk: 'false', first_name: 'John' }, current_user: admin)).to eq([])
        expect(Student.where(first_name: 'Foo').process_typed_scopes({ at_risk: 'true', first_name: 'Jane' }, current_user: admin)).to eq([])
        expect(Student.where('1=0').process_typed_scopes({ at_risk: 'false', first_name: 'John' }, current_user: admin)).to eq([])
        expect(Student.where('1=0').process_typed_scopes({ at_risk: 'true', first_name: 'Jane' }, current_user: admin)).to eq([])
      end

      it 'raises InvalidFilterError if the filter does not exist' do
        expect { Student.process_typed_scopes({ state: 'Fl' }, current_user: user) }.to raise_error(TypeCastedScopes::InvalidFilterError)
      end
    end

    describe '.type_casted_scope' do
      context 'using a joins to filter a relationship' do
        let(:university1) { University.create(mascot: 'tiger') }
        let(:university2) { University.create(mascot: 'elephant') }

        before(:each) do
          student1.update(university_id: university1.id)
          student2.update(university_id: university2.id)
        end

        it { expect(Student.process_typed_scopes(university_mascot: 'Tiger')).to eq([student1]) }
        it { expect(Student.process_typed_scopes(university_mascot: 'Elephant')).to eq([student2]) }
      end

      it 'uses string as a default scope_type if none is given' do
        expect(Student.process_typed_scopes(fname: 'john')).to eq([student1])
        expect(Student.process_typed_scopes(fname: 'jane')).to eq([student2])
      end

      it 'can use a custom definition to validate the value' do
        expect { Student.process_typed_scopes(lname: 'foo') }.to raise_error(TypeCastedScopes::InvalidValueError)
        expect(Student.process_typed_scopes(lname: 'Doe')).to eq([student1, student2])
      end

      context 'scope type float' do
        it { expect(Student.process_typed_scopes({ at_risk: 'false' }, current_user: admin)).to eq([student1]) }
        it { expect(Student.process_typed_scopes({ at_risk: 'true' }, current_user: admin)).to eq([student2]) }
      end

      context 'scope type string' do
        it { expect(Student.process_typed_scopes(fname: 'John')).to eq([student1]) }
        it { expect(Student.process_typed_scopes(fname: 'Jane')).to eq([student2]) }
        it { expect(Student.process_typed_scopes(lname: 'Doe')).to eq([student1, student2]) }
      end

      context 'scope has optional arguments' do
        it { expect(Student.type_casted_scope_name_search('JOHN')).to eq([student1]) }
        it { expect(Student.type_casted_scope_name_search('JOHN', { case_sensitive: true })).to eq([]) }
      end

      context 'integer value' do
        it { expect(Student.type_casted_scope_university_id('1')).to eq([student1]) }
        it { expect(Student.type_casted_scope_university_id(1)).to eq([student1]) }
      end

      context 'float value' do
        it { expect(Student.type_casted_scope_gpa('4.0')).to eq([student1]) }
        it { expect(Student.type_casted_scope_gpa(4.0)).to eq([student1]) }
      end

      context 'boolean value' do
        it { expect(Student.type_casted_scope_honor_roll('true')).to eq([student1]) }
        it { expect(Student.type_casted_scope_honor_roll(true)).to eq([student1]) }
        it { expect(Student.type_casted_scope_honor_roll('false')).to eq([student2]) }
        it { expect(Student.type_casted_scope_honor_roll(false)).to eq([student2]) }
      end

      context 'process scopes with optional arguments' do
        it { expect(Student.process_typed_scopes({ at_risk: 'true', name_search: 'Jane' }, case_sensitive: true, current_user: admin)).to eq([student2]) }
      end
    end
  end
end
