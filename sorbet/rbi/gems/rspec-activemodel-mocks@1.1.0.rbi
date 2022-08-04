# typed: true

# DO NOT EDIT MANUALLY
# This is an autogenerated file for types exported from the `rspec-activemodel-mocks` gem.
# Please instead update this file by running `bin/tapioca gem rspec-activemodel-mocks`.

# source://rspec-activemodel-mocks-1.1.0/lib/rspec/active_model/mocks/version.rb:1
module RSpec
  class << self
    # source://rspec-core-3.11.0/lib/rspec/core.rb:70
    def clear_examples; end

    # source://rspec-core-3.11.0/lib/rspec/core.rb:85
    def configuration; end

    # source://rspec-core-3.11.0/lib/rspec/core.rb:49
    def configuration=(_arg0); end

    # source://rspec-core-3.11.0/lib/rspec/core.rb:97
    def configure; end

    # source://rspec-core-3.11.0/lib/rspec/core.rb:194
    def const_missing(name); end

    # source://rspec-core-3.11.0/lib/rspec/core/dsl.rb:42
    def context(*args, &example_group_block); end

    # source://rspec-core-3.11.0/lib/rspec/core.rb:122
    def current_example; end

    # source://rspec-core-3.11.0/lib/rspec/core.rb:128
    def current_example=(example); end

    # source://rspec-core-3.11.0/lib/rspec/core.rb:154
    def current_scope; end

    # source://rspec-core-3.11.0/lib/rspec/core.rb:134
    def current_scope=(scope); end

    # source://rspec-core-3.11.0/lib/rspec/core/dsl.rb:42
    def describe(*args, &example_group_block); end

    # source://rspec-core-3.11.0/lib/rspec/core/dsl.rb:42
    def example_group(*args, &example_group_block); end

    # source://rspec-core-3.11.0/lib/rspec/core/dsl.rb:42
    def fcontext(*args, &example_group_block); end

    # source://rspec-core-3.11.0/lib/rspec/core/dsl.rb:42
    def fdescribe(*args, &example_group_block); end

    # source://rspec-core-3.11.0/lib/rspec/core/dsl.rb:42
    def feature(*args, &example_group_block); end

    # source://rspec-core-3.11.0/lib/rspec/core/dsl.rb:42
    def ffeature(*args, &example_group_block); end

    # source://rspec-core-3.11.0/lib/rspec/core.rb:58
    def reset; end

    # source://rspec-core-3.11.0/lib/rspec/core/shared_example_group.rb:110
    def shared_context(name, *args, &block); end

    # source://rspec-core-3.11.0/lib/rspec/core/shared_example_group.rb:110
    def shared_examples(name, *args, &block); end

    # source://rspec-core-3.11.0/lib/rspec/core/shared_example_group.rb:110
    def shared_examples_for(name, *args, &block); end

    # source://rspec-core-3.11.0/lib/rspec/core.rb:160
    def world; end

    # source://rspec-core-3.11.0/lib/rspec/core.rb:49
    def world=(_arg0); end

    # source://rspec-core-3.11.0/lib/rspec/core/dsl.rb:42
    def xcontext(*args, &example_group_block); end

    # source://rspec-core-3.11.0/lib/rspec/core/dsl.rb:42
    def xdescribe(*args, &example_group_block); end

    # source://rspec-core-3.11.0/lib/rspec/core/dsl.rb:42
    def xfeature(*args, &example_group_block); end
  end
end

# source://rspec-activemodel-mocks-1.1.0/lib/rspec/active_model/mocks/version.rb:2
module RSpec::ActiveModel; end

# source://rspec-activemodel-mocks-1.1.0/lib/rspec/active_model/mocks/version.rb:3
module RSpec::ActiveModel::Mocks; end

# source://rspec-activemodel-mocks-1.1.0/lib/rspec/active_model/mocks/mocks.rb:6
class RSpec::ActiveModel::Mocks::IllegalDataAccessException < ::StandardError; end

# source://rspec-activemodel-mocks-1.1.0/lib/rspec/active_model/mocks/mocks.rb:7
module RSpec::ActiveModel::Mocks::Mocks
  # Creates a test double representing `string_or_model_class` with common
  # ActiveModel methods stubbed out. Additional methods may be easily
  # stubbed (via add_stubs) if `stubs` is passed. This is most useful for
  # impersonating models that don't exist yet.
  #
  # ActiveModel methods, plus <tt>new_record?</tt>, are
  # stubbed out implicitly.  <tt>new_record?</tt> returns the inverse of
  # <tt>persisted?</tt>, and is present only for compatibility with
  # extension frameworks that have yet to update themselves to the
  # ActiveModel API (which declares <tt>persisted?</tt>, not
  # <tt>new_record?</tt>).
  #
  # `string_or_model_class` can be any of:
  #
  #   * A String representing a Class that does not exist
  #   * A String representing a Class that extends ActiveModel::Naming
  #   * A Class that extends ActiveModel::Naming
  #
  # source://rspec-activemodel-mocks-1.1.0/lib/rspec/active_model/mocks/mocks.rb:94
  def mock_model(string_or_model_class, stubs = T.unsafe(nil)); end

  # Creates an instance of `Model` with `to_param` stubbed using a
  # generated value that is unique to each object. If `Model` is an
  # `ActiveRecord` model, it is prohibited from accessing the database.
  #
  # For each key in `stubs`, if the model has a matching attribute
  # (determined by `respond_to?`) it is simply assigned the submitted values.
  # If the model does not have a matching attribute, the key/value pair is
  # assigned as a stub return value using RSpec's mocking/stubbing
  # framework.
  #
  # <tt>persisted?</tt> is overridden to return the result of !id.nil?
  # This means that by default persisted? will return true. If  you want
  # the object to behave as a new record, sending it `as_new_record` will
  # set the id to nil. You can also explicitly set :id => nil, in which
  # case persisted? will return false, but using `as_new_record` makes the
  # example a bit more descriptive.
  #
  # While you can use stub_model in any example (model, view, controller,
  # helper), it is especially useful in view examples, which are
  # inherently more state-based than interaction-based.
  #
  # @example
  #
  #   stub_model(Person)
  #   stub_model(Person).as_new_record
  #   stub_model(Person, :to_param => 37)
  #   stub_model(Person) {|person| person.first_name = "David"}
  #
  # source://rspec-activemodel-mocks-1.1.0/lib/rspec/active_model/mocks/mocks.rb:243
  def stub_model(model_class, stubs = T.unsafe(nil)); end

  private

  # source://rspec-activemodel-mocks-1.1.0/lib/rspec/active_model/mocks/mocks.rb:273
  def next_id; end
end

# source://rspec-activemodel-mocks-1.1.0/lib/rspec/active_model/mocks/mocks.rb:9
module RSpec::ActiveModel::Mocks::Mocks::ActiveModelInstanceMethods
  # Stubs `persisted?` to return false and `id` to return nil
  #
  # @return self
  #
  # source://rspec-activemodel-mocks-1.1.0/lib/rspec/active_model/mocks/mocks.rb:12
  def as_new_record; end

  # Returns true by default. Override with a stub.
  #
  # @return [Boolean]
  #
  # source://rspec-activemodel-mocks-1.1.0/lib/rspec/active_model/mocks/mocks.rb:19
  def persisted?; end

  # Returns false for names matching <tt>/_before_type_cast$/</tt>,
  # otherwise delegates to super.
  #
  # @return [Boolean]
  #
  # source://rspec-activemodel-mocks-1.1.0/lib/rspec/active_model/mocks/mocks.rb:25
  def respond_to?(message, include_private = T.unsafe(nil)); end
end

# source://rspec-activemodel-mocks-1.1.0/lib/rspec/active_model/mocks/mocks.rb:183
module RSpec::ActiveModel::Mocks::Mocks::ActiveModelStubExtensions
  # Stubs `persisted` to return false and `id` to return nil
  #
  # source://rspec-activemodel-mocks-1.1.0/lib/rspec/active_model/mocks/mocks.rb:185
  def as_new_record; end

  # Returns `true` by default. Override with a stub.
  #
  # @return [Boolean]
  #
  # source://rspec-activemodel-mocks-1.1.0/lib/rspec/active_model/mocks/mocks.rb:192
  def persisted?; end
end

# source://rspec-activemodel-mocks-1.1.0/lib/rspec/active_model/mocks/mocks.rb:48
module RSpec::ActiveModel::Mocks::Mocks::ActiveRecordInstanceMethods
  # Transforms the key to a method and calls it.
  #
  # source://rspec-activemodel-mocks-1.1.0/lib/rspec/active_model/mocks/mocks.rb:56
  def [](key); end

  # Transforms the key to a method and calls it.
  # Rails>4.2 uses _read_attribute internally, as an optimized
  # alternative to record['id']
  #
  # source://rspec-activemodel-mocks-1.1.0/lib/rspec/active_model/mocks/mocks.rb:56
  def _read_attribute(key); end

  # Returns an object representing an association from the mocked
  # model's perspective. For use by Rails internally only.
  #
  # source://rspec-activemodel-mocks-1.1.0/lib/rspec/active_model/mocks/mocks.rb:71
  def association(association_name); end

  # Stubs `persisted?` to return `false` and `id` to return `nil`.
  #
  # source://rspec-activemodel-mocks-1.1.0/lib/rspec/active_model/mocks/mocks.rb:50
  def destroy; end

  # Returns the opposite of `persisted?`
  #
  # @return [Boolean]
  #
  # source://rspec-activemodel-mocks-1.1.0/lib/rspec/active_model/mocks/mocks.rb:65
  def new_record?; end
end

# source://rspec-activemodel-mocks-1.1.0/lib/rspec/active_model/mocks/mocks.rb:197
module RSpec::ActiveModel::Mocks::Mocks::ActiveRecordStubExtensions
  # Stubs `id` (or other primary key method) to return nil
  #
  # source://rspec-activemodel-mocks-1.1.0/lib/rspec/active_model/mocks/mocks.rb:199
  def as_new_record; end

  # Raises an IllegalDataAccessException (stubbed models are not allowed to access the database)
  #
  # @raise [RSpec::ActiveModel::Mocks::IllegalDataAccessException]
  #
  # source://rspec-activemodel-mocks-1.1.0/lib/rspec/active_model/mocks/mocks.rb:211
  def connection; end

  # Returns the opposite of `persisted?`.
  #
  # @return [Boolean]
  #
  # source://rspec-activemodel-mocks-1.1.0/lib/rspec/active_model/mocks/mocks.rb:205
  def new_record?; end
end

# Starting with Rails 4.1, ActiveRecord associations are inversible
# by default. This class represents an association from the mocked
# model's perspective.
#
# @private
#
# source://rspec-activemodel-mocks-1.1.0/lib/rspec/active_model/mocks/mocks.rb:35
class RSpec::ActiveModel::Mocks::Mocks::Association
  # @return [Association] a new instance of Association
  #
  # source://rspec-activemodel-mocks-1.1.0/lib/rspec/active_model/mocks/mocks.rb:38
  def initialize(association_name); end

  # Returns the value of attribute inversed.
  #
  # source://rspec-activemodel-mocks-1.1.0/lib/rspec/active_model/mocks/mocks.rb:36
  def inversed; end

  # Sets the attribute inversed
  #
  # @param value the value to set the attribute inversed to.
  #
  # source://rspec-activemodel-mocks-1.1.0/lib/rspec/active_model/mocks/mocks.rb:36
  def inversed=(_arg0); end

  # source://rspec-activemodel-mocks-1.1.0/lib/rspec/active_model/mocks/mocks.rb:42
  def inversed_from(record); end

  # Returns the value of attribute target.
  #
  # source://rspec-activemodel-mocks-1.1.0/lib/rspec/active_model/mocks/mocks.rb:36
  def target; end

  # Sets the attribute target
  #
  # @param value the value to set the attribute target to.
  #
  # source://rspec-activemodel-mocks-1.1.0/lib/rspec/active_model/mocks/mocks.rb:36
  def target=(_arg0); end
end

# source://rspec-activemodel-mocks-1.1.0/lib/rspec/active_model/mocks/version.rb:4
module RSpec::ActiveModel::Mocks::Version; end

# source://rspec-activemodel-mocks-1.1.0/lib/rspec/active_model/mocks/version.rb:5
RSpec::ActiveModel::Mocks::Version::STRING = T.let(T.unsafe(nil), String)

# source://rspec-core-3.11.0/lib/rspec/core.rb:187
RSpec::MODULES_TO_AUTOLOAD = T.let(T.unsafe(nil), Hash)

# source://rspec-core-3.11.0/lib/rspec/core/shared_context.rb:54
RSpec::SharedContext = RSpec::Core::SharedContext
