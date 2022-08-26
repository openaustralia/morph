# typed: true

# DO NOT EDIT MANUALLY
# This is an autogenerated file for types exported from the `rspec-sorbet` gem.
# Please instead update this file by running `bin/tapioca gem rspec-sorbet`.

# source://rspec-sorbet-1.8.3/lib/rspec/sorbet/doubles.rb:6
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

# source://rspec-core-3.11.0/lib/rspec/core.rb:187
RSpec::MODULES_TO_AUTOLOAD = T.let(T.unsafe(nil), Hash)

# source://rspec-core-3.11.0/lib/rspec/core/shared_context.rb:54
RSpec::SharedContext = RSpec::Core::SharedContext

# source://rspec-sorbet-1.8.3/lib/rspec/sorbet/doubles.rb:7
module RSpec::Sorbet
  extend ::RSpec::Sorbet::Doubles
end

# source://rspec-sorbet-1.8.3/lib/rspec/sorbet/doubles.rb:8
module RSpec::Sorbet::Doubles
  # source://rspec-sorbet-1.8.3/lib/rspec/sorbet/doubles.rb:9
  def allow_doubles!; end

  # source://rspec-sorbet-1.8.3/lib/rspec/sorbet/doubles.rb:9
  def allow_instance_doubles!; end

  private

  # @raise [TypeError]
  #
  # source://rspec-sorbet-1.8.3/lib/rspec/sorbet/doubles.rb:78
  def call_validation_error_handler(_signature, opts); end

  # @return [Boolean]
  #
  # source://rspec-sorbet-1.8.3/lib/rspec/sorbet/doubles.rb:68
  def double_message_with_ellipsis?(message); end

  # source://rspec-sorbet-1.8.3/lib/rspec/sorbet/doubles.rb:26
  def inline_type_error_handler(error); end

  # @return [Boolean]
  #
  # source://rspec-sorbet-1.8.3/lib/rspec/sorbet/doubles.rb:74
  def typed_array_message?(message); end

  # @return [Boolean]
  #
  # source://rspec-sorbet-1.8.3/lib/rspec/sorbet/doubles.rb:60
  def unable_to_check_type_for_message?(message); end
end

# source://rspec-sorbet-1.8.3/lib/rspec/sorbet/doubles.rb:23
RSpec::Sorbet::Doubles::INLINE_DOUBLE_REGEX = T.let(T.unsafe(nil), Regexp)

# source://rspec-sorbet-1.8.3/lib/rspec/sorbet/doubles.rb:72
RSpec::Sorbet::Doubles::TYPED_ARRAY_MESSAGE = T.let(T.unsafe(nil), Regexp)

# source://rspec-sorbet-1.8.3/lib/rspec/sorbet/doubles.rb:65
RSpec::Sorbet::Doubles::VERIFYING_DOUBLE_OR_DOUBLE = T.let(T.unsafe(nil), Regexp)