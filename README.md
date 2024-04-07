# Type Casted Scopes

![example branch parameter](https://github.com/smann297/type-casted-scopes/actions/workflows/build.yml/badge.svg?branch=main)

#### `#type_casted_scope`

The difference between a `#type_casted_scope` and a regular `#scope` is that the value passed into a `#type_casted_scope` is validated against a specified data type.

The available data types are `string, text, bigint, integer, float, decimal, boolean`.

This approach offers a cleaner alternative to validating argument values than writing guard statements within a scope. It proves particularly handy when the value originates from the client, such as through an API query.

The default data type is `string`.

```ruby
class Student < ActiveRecord::Base
  include TypeCastedScopes
  
  type_casted_scope :name, ->(value) {
    where("first_name LIKE ? || last_name LIKE ?", "%#{value}%") 
  }

  type_casted_scope :age, :integer, ->(value) {
    where(age: value)
  }
end
```

Like the `#scope` method, `#type_casted_scope` defines a singleton class method on your model.

```ruby
Student.type_casted_scope_name("John")
```

You can define your own data types or override existing data types, by adding a `TypeCastedScopes::Definitions` module to your application.

Each definition should receive a single argument and return either `true` or `false`. 

An error, `TypeCastedScopes::InvalidValueError`, will be raised if the validation fails.

```ruby
type_casted_scope :birthday_month, :month, ->(value) {
  where('MONTH(birth_date) = ?', value)
}

module TypeCastedScopes
  module Definitions
    def self.month(value)
      (1..12).include?(value&.to_i)
    end
  end
end
```

After the value passed into `#type_casted_scope` is validated to be of the specified data type, it is converted from a string to that data type _before_ it is called in the proceeding block.

There are no limits on passing additional arguments.

```ruby
type_casted_scope :by_weighted_gpa, :float, ->(value, options = {}) {
  where("gpa >= ?", options[:foo] ? value : bar(value))
}
```

#### `#type_casted_scopes`

```ruby
class Automobile < ActiveRecord::Base
  include TypeCastedScopes
  type_casted_scopes :name, :electric, :year
end
```

The `#type_casted_scopes` method accepts a list of attributes from your model with the following data types: `string, text, bigint, integer, float, decimal, boolean`.

It defines a singleton class method, `type_casted_scope_{attribute}`, for each attribute, with a basic `where clause` for the `&block` method call. 

By default, attributes with a data type of `string` and `text` are case insensitive.

```ruby
type_casted_scope :name, :string, ->(value) {
  where('name LIKE ?', value)
}

type_casted_scope :electric, :boolean, ->(value) {
  where(electric: value)
}

type_casted_scope :year, :integer, ->(value) {
  where(year: value)
}
```

#### `#process_typed_scopes`

The `#process_typed_scopes` method allows you to conveniently query your database with a chain of `type_casted_scope` method calls. 

It always returns an `ActiveRecord::Relation`.

```ruby
options[:foo] = :bar
params[:filter] = { first_name: 'John', last_name: 'Doe' }
Student.process_typed_scopes(params[:filter], options)
```

The first argument is a hash of key value pairs `{ first_name: 'John', last_name: 'Doe' }` that will call the corresponding `type_casted_scope_{key}({value})` method on the class.

```ruby
Student.type_casted_scope_first_name('John', options)
       .type_casted_scope_last_name('Doe', options)
```

## Installation

### Rails

1.  Add to your gemfile:

```ruby
gem 'type-casted-scopes'
```

2.  Execute:

```sh
$ bundle install
```
### Sinatra

1. Add to your gemfile

```ruby
gem 'sinatra/activerecord'
gem 'type-casted-scopes'
```

2.  Execute:

```sh
$ bundle install
```

## Running Tests

RSpec is used for testing.

```sh
$ bundle exec rspec
```

RuboCop for linting

```sh
$ bundle exec rubocop
```

## Contributing

<a href="https://rubystyle.guide/">Ruby Style Guide</a> :smiley:

## License

The gem is available as open source under the terms of the <a href="http://opensource.org/licenses/MIT">MIT License</a>.
