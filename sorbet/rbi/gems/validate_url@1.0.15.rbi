# typed: true

# DO NOT EDIT MANUALLY
# This is an autogenerated file for types exported from the `validate_url` gem.
# Please instead update this file by running `bin/tapioca gem validate_url`.

# source://validate_url-1.0.15/lib/validate_url.rb:6
module ActiveModel
  class << self
    # source://activemodel-5.2.8.1/lib/active_model.rb:69
    def eager_load!; end

    # Returns the version of the currently loaded \Active \Model as a <tt>Gem::Version</tt>
    #
    # source://activemodel-5.2.8.1/lib/active_model/gem_version.rb:5
    def gem_version; end

    # Returns the version of the currently loaded \Active \Model as a <tt>Gem::Version</tt>
    #
    # source://activemodel-5.2.8.1/lib/active_model/version.rb:7
    def version; end
  end
end

# == Active \Model \Validations
#
# Provides a full validation framework to your objects.
#
# A minimal implementation could be:
#
#   class Person
#     include ActiveModel::Validations
#
#     attr_accessor :first_name, :last_name
#
#     validates_each :first_name, :last_name do |record, attr, value|
#       record.errors.add attr, 'starts with z.' if value.to_s[0] == ?z
#     end
#   end
#
# Which provides you with the full standard validation stack that you
# know from Active Record:
#
#   person = Person.new
#   person.valid?                   # => true
#   person.invalid?                 # => false
#
#   person.first_name = 'zoolander'
#   person.valid?                   # => false
#   person.invalid?                 # => true
#   person.errors.messages          # => {first_name:["starts with z."]}
#
# Note that <tt>ActiveModel::Validations</tt> automatically adds an +errors+
# method to your instances initialized with a new <tt>ActiveModel::Errors</tt>
# object, so there is no need for you to do this manually.
#
# source://validate_url-1.0.15/lib/validate_url.rb:7
module ActiveModel::Validations
  include GeneratedInstanceMethods
  include ::ActiveSupport::Callbacks
  include ::ActiveModel::Validations::HelperMethods

  mixes_in_class_methods GeneratedClassMethods
  mixes_in_class_methods ::ActiveModel::Validations::ClassMethods
  mixes_in_class_methods ::ActiveModel::Callbacks
  mixes_in_class_methods ::ActiveSupport::Callbacks::ClassMethods
  mixes_in_class_methods ::ActiveSupport::DescendantsTracker
  mixes_in_class_methods ::ActiveModel::Translation
  mixes_in_class_methods ::ActiveModel::Validations::HelperMethods

  # Returns the +Errors+ object that holds all information about attribute
  # error messages.
  #
  #   class Person
  #     include ActiveModel::Validations
  #
  #     attr_accessor :name
  #     validates_presence_of :name
  #   end
  #
  #   person = Person.new
  #   person.valid? # => false
  #   person.errors # => #<ActiveModel::Errors:0x007fe603816640 @messages={name:["can't be blank"]}>
  #
  # source://activemodel-5.2.8.1/lib/active_model/validations.rb:303
  def errors; end

  # Performs the opposite of <tt>valid?</tt>. Returns +true+ if errors were
  # added, +false+ otherwise.
  #
  #   class Person
  #     include ActiveModel::Validations
  #
  #     attr_accessor :name
  #     validates_presence_of :name
  #   end
  #
  #   person = Person.new
  #   person.name = ''
  #   person.invalid? # => true
  #   person.name = 'david'
  #   person.invalid? # => false
  #
  # Context can optionally be supplied to define which callbacks to test
  # against (the context is defined on the validations using <tt>:on</tt>).
  #
  #   class Person
  #     include ActiveModel::Validations
  #
  #     attr_accessor :name
  #     validates_presence_of :name, on: :new
  #   end
  #
  #   person = Person.new
  #   person.invalid?       # => false
  #   person.invalid?(:new) # => true
  #
  # @return [Boolean]
  #
  # source://activemodel-5.2.8.1/lib/active_model/validations.rb:375
  def invalid?(context = T.unsafe(nil)); end

  # Hook method defining how an attribute value should be retrieved. By default
  # this is assumed to be an instance named after the attribute. Override this
  # method in subclasses should you need to retrieve the value for a given
  # attribute differently:
  #
  #   class MyClass
  #     include ActiveModel::Validations
  #
  #     def initialize(data = {})
  #       @data = data
  #     end
  #
  #     def read_attribute_for_validation(key)
  #       @data[key]
  #     end
  #   end
  def read_attribute_for_validation(*_arg0); end

  # Runs all the specified validations and returns +true+ if no errors were
  # added otherwise +false+.
  #
  #   class Person
  #     include ActiveModel::Validations
  #
  #     attr_accessor :name
  #     validates_presence_of :name
  #   end
  #
  #   person = Person.new
  #   person.name = ''
  #   person.valid? # => false
  #   person.name = 'david'
  #   person.valid? # => true
  #
  # Context can optionally be supplied to define which callbacks to test
  # against (the context is defined on the validations using <tt>:on</tt>).
  #
  #   class Person
  #     include ActiveModel::Validations
  #
  #     attr_accessor :name
  #     validates_presence_of :name, on: :new
  #   end
  #
  #   person = Person.new
  #   person.valid?       # => true
  #   person.valid?(:new) # => false
  #
  # @return [Boolean]
  #
  # source://activemodel-5.2.8.1/lib/active_model/validations.rb:336
  def valid?(context = T.unsafe(nil)); end

  # Runs all the specified validations and returns +true+ if no errors were
  # added otherwise +false+.
  #
  #   class Person
  #     include ActiveModel::Validations
  #
  #     attr_accessor :name
  #     validates_presence_of :name
  #   end
  #
  #   person = Person.new
  #   person.name = ''
  #   person.valid? # => false
  #   person.name = 'david'
  #   person.valid? # => true
  #
  # Context can optionally be supplied to define which callbacks to test
  # against (the context is defined on the validations using <tt>:on</tt>).
  #
  #   class Person
  #     include ActiveModel::Validations
  #
  #     attr_accessor :name
  #     validates_presence_of :name, on: :new
  #   end
  #
  #   person = Person.new
  #   person.valid?       # => true
  #   person.valid?(:new) # => false
  #
  # @return [Boolean]
  #
  # source://activemodel-5.2.8.1/lib/active_model/validations.rb:336
  def validate(context = T.unsafe(nil)); end

  # Runs all the validations within the specified context. Returns +true+ if
  # no errors are found, raises +ValidationError+ otherwise.
  #
  # Validations with no <tt>:on</tt> option will run no matter the context. Validations with
  # some <tt>:on</tt> option will only run in the specified context.
  #
  # source://activemodel-5.2.8.1/lib/active_model/validations.rb:384
  def validate!(context = T.unsafe(nil)); end

  # Passes the record off to the class or classes specified and allows them
  # to add errors based on more complex conditions.
  #
  #   class Person
  #     include ActiveModel::Validations
  #
  #     validate :instance_validations
  #
  #     def instance_validations
  #       validates_with MyValidator
  #     end
  #   end
  #
  # Please consult the class method documentation for more information on
  # creating your own validator.
  #
  # You may also pass it multiple classes, like so:
  #
  #   class Person
  #     include ActiveModel::Validations
  #
  #     validate :instance_validations, on: :create
  #
  #     def instance_validations
  #       validates_with MyValidator, MyOtherValidator
  #     end
  #   end
  #
  # Standard configuration options (<tt>:on</tt>, <tt>:if</tt> and
  # <tt>:unless</tt>), which are available on the class version of
  # +validates_with+, should instead be placed on the +validates+ method
  # as these are applied and tested in the callback.
  #
  # If you pass any additional configuration options, they will be passed
  # to the class and available as +options+, please refer to the
  # class version of this method for more information.
  #
  # source://activemodel-5.2.8.1/lib/active_model/validations/with.rb:137
  def validates_with(*args, &block); end

  private

  # Clean the +Errors+ object if instance is duped.
  #
  # source://activemodel-5.2.8.1/lib/active_model/validations.rb:285
  def initialize_dup(other); end

  # @raise [ValidationError]
  #
  # source://activemodel-5.2.8.1/lib/active_model/validations.rb:413
  def raise_validation_error; end

  # source://activemodel-5.2.8.1/lib/active_model/validations.rb:408
  def run_validations!; end

  module GeneratedClassMethods
    def __callbacks; end
    def __callbacks=(value); end
    def __callbacks?; end
    def _validators; end
    def _validators=(value); end
    def _validators?; end
  end

  module GeneratedInstanceMethods
    def __callbacks; end
    def __callbacks?; end
    def _validators; end
    def _validators?; end
  end
end

# source://validate_url-1.0.15/lib/validate_url.rb:70
module ActiveModel::Validations::ClassMethods
  # Returns +true+ if +attribute+ is an attribute method, +false+ otherwise.
  #
  #  class Person
  #    include ActiveModel::Validations
  #
  #    attr_accessor :name
  #  end
  #
  #  User.attribute_method?(:name) # => true
  #  User.attribute_method?(:age)  # => false
  #
  # @return [Boolean]
  #
  # source://activemodel-5.2.8.1/lib/active_model/validations.rb:272
  def attribute_method?(attribute); end

  # Clears all of the validators and validations.
  #
  # Note that this will clear anything that is being used to validate
  # the model for both the +validates_with+ and +validate+ methods.
  # It clears the validators that are created with an invocation of
  # +validates_with+ and the callbacks that are set by an invocation
  # of +validate+.
  #
  #   class Person
  #     include ActiveModel::Validations
  #
  #     validates_with MyValidator
  #     validates_with OtherValidator, on: :create
  #     validates_with StrictValidator, strict: true
  #     validate :cannot_be_robot
  #
  #     def cannot_be_robot
  #       errors.add(:base, 'A person cannot be a robot') if person_is_robot
  #     end
  #   end
  #
  #   Person.validators
  #   # => [
  #   #      #<MyValidator:0x007fbff403e808 @options={}>,
  #   #      #<OtherValidator:0x007fbff403d930 @options={on: :create}>,
  #   #      #<StrictValidator:0x007fbff3204a30 @options={strict:true}>
  #   #    ]
  #
  # If one runs <tt>Person.clear_validators!</tt> and then checks to see what
  # validators this class has, you would obtain:
  #
  #   Person.validators # => []
  #
  # Also, the callback set by <tt>validate :cannot_be_robot</tt> will be erased
  # so that:
  #
  #   Person._validate_callbacks.empty?  # => true
  #
  # source://activemodel-5.2.8.1/lib/active_model/validations.rb:236
  def clear_validators!; end

  # Copy validators on inheritance.
  #
  # source://activemodel-5.2.8.1/lib/active_model/validations.rb:277
  def inherited(base); end

  # Adds a validation method or block to the class. This is useful when
  # overriding the +validate+ instance method becomes too unwieldy and
  # you're looking for more descriptive declaration of your validations.
  #
  # This can be done with a symbol pointing to a method:
  #
  #   class Comment
  #     include ActiveModel::Validations
  #
  #     validate :must_be_friends
  #
  #     def must_be_friends
  #       errors.add(:base, 'Must be friends to leave a comment') unless commenter.friend_of?(commentee)
  #     end
  #   end
  #
  # With a block which is passed with the current record to be validated:
  #
  #   class Comment
  #     include ActiveModel::Validations
  #
  #     validate do |comment|
  #       comment.must_be_friends
  #     end
  #
  #     def must_be_friends
  #       errors.add(:base, 'Must be friends to leave a comment') unless commenter.friend_of?(commentee)
  #     end
  #   end
  #
  # Or with a block where self points to the current record to be validated:
  #
  #   class Comment
  #     include ActiveModel::Validations
  #
  #     validate do
  #       errors.add(:base, 'Must be friends to leave a comment') unless commenter.friend_of?(commentee)
  #     end
  #   end
  #
  # Note that the return value of validation methods is not relevant.
  # It's not possible to halt the validate callback chain.
  #
  # Options:
  # * <tt>:on</tt> - Specifies the contexts where this validation is active.
  #   Runs in all validation contexts by default +nil+. You can pass a symbol
  #   or an array of symbols. (e.g. <tt>on: :create</tt> or
  #   <tt>on: :custom_validation_context</tt> or
  #   <tt>on: [:create, :custom_validation_context]</tt>)
  # * <tt>:if</tt> - Specifies a method, proc or string to call to determine
  #   if the validation should occur (e.g. <tt>if: :allow_validation</tt>,
  #   or <tt>if: Proc.new { |user| user.signup_step > 2 }</tt>). The method,
  #   proc or string should return or evaluate to a +true+ or +false+ value.
  # * <tt>:unless</tt> - Specifies a method, proc or string to call to
  #   determine if the validation should not occur (e.g. <tt>unless: :skip_validation</tt>,
  #   or <tt>unless: Proc.new { |user| user.signup_step <= 2 }</tt>). The
  #   method, proc or string should return or evaluate to a +true+ or +false+
  #   value.
  #
  # NOTE: Calling +validate+ multiple times on the same method will overwrite previous definitions.
  #
  # source://activemodel-5.2.8.1/lib/active_model/validations.rb:154
  def validate(*args, &block); end

  # This method is a shortcut to all default validators and any custom
  # validator classes ending in 'Validator'. Note that Rails default
  # validators can be overridden inside specific classes by creating
  # custom validator classes in their place such as PresenceValidator.
  #
  # Examples of using the default rails validators:
  #
  #   validates :terms, acceptance: true
  #   validates :password, confirmation: true
  #   validates :username, exclusion: { in: %w(admin superuser) }
  #   validates :email, format: { with: /\A([^@\s]+)@((?:[-a-z0-9]+\.)+[a-z]{2,})\z/i, on: :create }
  #   validates :age, inclusion: { in: 0..9 }
  #   validates :first_name, length: { maximum: 30 }
  #   validates :age, numericality: true
  #   validates :username, presence: true
  #
  # The power of the +validates+ method comes when using custom validators
  # and default validators in one call for a given attribute.
  #
  #   class EmailValidator < ActiveModel::EachValidator
  #     def validate_each(record, attribute, value)
  #       record.errors.add attribute, (options[:message] || "is not an email") unless
  #         value =~ /\A([^@\s]+)@((?:[-a-z0-9]+\.)+[a-z]{2,})\z/i
  #     end
  #   end
  #
  #   class Person
  #     include ActiveModel::Validations
  #     attr_accessor :name, :email
  #
  #     validates :name, presence: true, length: { maximum: 100 }
  #     validates :email, presence: true, email: true
  #   end
  #
  # Validator classes may also exist within the class being validated
  # allowing custom modules of validators to be included as needed.
  #
  #   class Film
  #     include ActiveModel::Validations
  #
  #     class TitleValidator < ActiveModel::EachValidator
  #       def validate_each(record, attribute, value)
  #         record.errors.add attribute, "must start with 'the'" unless value =~ /\Athe/i
  #       end
  #     end
  #
  #     validates :name, title: true
  #   end
  #
  # Additionally validator classes may be in another namespace and still
  # used within any class.
  #
  #   validates :name, :'film/title' => true
  #
  # The validators hash can also handle regular expressions, ranges, arrays
  # and strings in shortcut form.
  #
  #   validates :email, format: /@/
  #   validates :gender, inclusion: %w(male female)
  #   validates :password, length: 6..20
  #
  # When using shortcut form, ranges and arrays are passed to your
  # validator's initializer as <tt>options[:in]</tt> while other types
  # including regular expressions and strings are passed as <tt>options[:with]</tt>.
  #
  # There is also a list of options that could be used along with validators:
  #
  # * <tt>:on</tt> - Specifies the contexts where this validation is active.
  #   Runs in all validation contexts by default +nil+. You can pass a symbol
  #   or an array of symbols. (e.g. <tt>on: :create</tt> or
  #   <tt>on: :custom_validation_context</tt> or
  #   <tt>on: [:create, :custom_validation_context]</tt>)
  # * <tt>:if</tt> - Specifies a method, proc or string to call to determine
  #   if the validation should occur (e.g. <tt>if: :allow_validation</tt>,
  #   or <tt>if: Proc.new { |user| user.signup_step > 2 }</tt>). The method,
  #   proc or string should return or evaluate to a +true+ or +false+ value.
  # * <tt>:unless</tt> - Specifies a method, proc or string to call to determine
  #   if the validation should not occur (e.g. <tt>unless: :skip_validation</tt>,
  #   or <tt>unless: Proc.new { |user| user.signup_step <= 2 }</tt>). The
  #   method, proc or string should return or evaluate to a +true+ or
  #   +false+ value.
  # * <tt>:allow_nil</tt> - Skip validation if the attribute is +nil+.
  # * <tt>:allow_blank</tt> - Skip validation if the attribute is blank.
  # * <tt>:strict</tt> - If the <tt>:strict</tt> option is set to true
  #   will raise ActiveModel::StrictValidationFailed instead of adding the error.
  #   <tt>:strict</tt> option can also be set to any other exception.
  #
  # Example:
  #
  #   validates :password, presence: true, confirmation: true, if: :password_required?
  #   validates :token, length: 24, strict: TokenLengthException
  #
  #
  # Finally, the options +:if+, +:unless+, +:on+, +:allow_blank+, +:allow_nil+, +:strict+
  # and +:message+ can be given to one specific validator, as a hash:
  #
  #   validates :password, presence: { if: :password_required?, message: 'is forgotten.' }, confirmation: true
  #
  # @raise [ArgumentError]
  #
  # source://activemodel-5.2.8.1/lib/active_model/validations/validates.rb:105
  def validates(*attributes); end

  # This method is used to define validations that cannot be corrected by end
  # users and are considered exceptional. So each validator defined with bang
  # or <tt>:strict</tt> option set to <tt>true</tt> will always raise
  # <tt>ActiveModel::StrictValidationFailed</tt> instead of adding error
  # when validation fails. See <tt>validates</tt> for more information about
  # the validation itself.
  #
  #   class Person
  #     include ActiveModel::Validations
  #
  #     attr_accessor :name
  #     validates! :name, presence: true
  #   end
  #
  #   person = Person.new
  #   person.name = ''
  #   person.valid?
  #   # => ActiveModel::StrictValidationFailed: Name can't be blank
  #
  # source://activemodel-5.2.8.1/lib/active_model/validations/validates.rb:146
  def validates!(*attributes); end

  # Validates each attribute against a block.
  #
  #   class Person
  #     include ActiveModel::Validations
  #
  #     attr_accessor :first_name, :last_name
  #
  #     validates_each :first_name, :last_name, allow_blank: true do |record, attr, value|
  #       record.errors.add attr, 'starts with z.' if value.to_s[0] == ?z
  #     end
  #   end
  #
  # Options:
  # * <tt>:on</tt> - Specifies the contexts where this validation is active.
  #   Runs in all validation contexts by default +nil+. You can pass a symbol
  #   or an array of symbols. (e.g. <tt>on: :create</tt> or
  #   <tt>on: :custom_validation_context</tt> or
  #   <tt>on: [:create, :custom_validation_context]</tt>)
  # * <tt>:allow_nil</tt> - Skip validation if attribute is +nil+.
  # * <tt>:allow_blank</tt> - Skip validation if attribute is blank.
  # * <tt>:if</tt> - Specifies a method, proc or string to call to determine
  #   if the validation should occur (e.g. <tt>if: :allow_validation</tt>,
  #   or <tt>if: Proc.new { |user| user.signup_step > 2 }</tt>). The method,
  #   proc or string should return or evaluate to a +true+ or +false+ value.
  # * <tt>:unless</tt> - Specifies a method, proc or string to call to
  #   determine if the validation should not occur (e.g. <tt>unless: :skip_validation</tt>,
  #   or <tt>unless: Proc.new { |user| user.signup_step <= 2 }</tt>). The
  #   method, proc or string should return or evaluate to a +true+ or +false+
  #   value.
  #
  # source://activemodel-5.2.8.1/lib/active_model/validations.rb:87
  def validates_each(*attr_names, &block); end

  # Validates whether the value of the specified attribute is valid url.
  #
  #   class Unicorn
  #     include ActiveModel::Validations
  #     attr_accessor :homepage, :ftpsite
  #     validates_url :homepage, allow_blank: true
  #     validates_url :ftpsite, schemes: ['ftp']
  #   end
  # Configuration options:
  # * <tt>:message</tt> - A custom error message (default is: "is not a valid URL").
  # * <tt>:allow_nil</tt> - If set to true, skips this validation if the attribute is +nil+ (default is +false+).
  # * <tt>:allow_blank</tt> - If set to true, skips this validation if the attribute is blank (default is +false+).
  # * <tt>:schemes</tt> - Array of URI schemes to validate against. (default is +['http', 'https']+)
  #
  # source://validate_url-1.0.15/lib/validate_url.rb:85
  def validates_url(*attr_names); end

  # Passes the record off to the class or classes specified and allows them
  # to add errors based on more complex conditions.
  #
  #   class Person
  #     include ActiveModel::Validations
  #     validates_with MyValidator
  #   end
  #
  #   class MyValidator < ActiveModel::Validator
  #     def validate(record)
  #       if some_complex_logic
  #         record.errors.add :base, 'This record is invalid'
  #       end
  #     end
  #
  #     private
  #       def some_complex_logic
  #         # ...
  #       end
  #   end
  #
  # You may also pass it multiple classes, like so:
  #
  #   class Person
  #     include ActiveModel::Validations
  #     validates_with MyValidator, MyOtherValidator, on: :create
  #   end
  #
  # Configuration options:
  # * <tt>:on</tt> - Specifies the contexts where this validation is active.
  #   Runs in all validation contexts by default +nil+. You can pass a symbol
  #   or an array of symbols. (e.g. <tt>on: :create</tt> or
  #   <tt>on: :custom_validation_context</tt> or
  #   <tt>on: [:create, :custom_validation_context]</tt>)
  # * <tt>:if</tt> - Specifies a method, proc or string to call to determine
  #   if the validation should occur (e.g. <tt>if: :allow_validation</tt>,
  #   or <tt>if: Proc.new { |user| user.signup_step > 2 }</tt>).
  #   The method, proc or string should return or evaluate to a +true+ or
  #   +false+ value.
  # * <tt>:unless</tt> - Specifies a method, proc or string to call to
  #   determine if the validation should not occur
  #   (e.g. <tt>unless: :skip_validation</tt>, or
  #   <tt>unless: Proc.new { |user| user.signup_step <= 2 }</tt>).
  #   The method, proc or string should return or evaluate to a +true+ or
  #   +false+ value.
  # * <tt>:strict</tt> - Specifies whether validation should be strict.
  #   See <tt>ActiveModel::Validations#validates!</tt> for more information.
  #
  # If you pass any additional configuration options, they will be passed
  # to the class and available as +options+:
  #
  #   class Person
  #     include ActiveModel::Validations
  #     validates_with MyValidator, my_custom_key: 'my custom value'
  #   end
  #
  #   class MyValidator < ActiveModel::Validator
  #     def validate(record)
  #       options[:my_custom_key] # => "my custom value"
  #     end
  #   end
  #
  # source://activemodel-5.2.8.1/lib/active_model/validations/with.rb:81
  def validates_with(*args, &block); end

  # List all validators that are being used to validate the model using
  # +validates_with+ method.
  #
  #   class Person
  #     include ActiveModel::Validations
  #
  #     validates_with MyValidator
  #     validates_with OtherValidator, on: :create
  #     validates_with StrictValidator, strict: true
  #   end
  #
  #   Person.validators
  #   # => [
  #   #      #<MyValidator:0x007fbff403e808 @options={}>,
  #   #      #<OtherValidator:0x007fbff403d930 @options={on: :create}>,
  #   #      #<StrictValidator:0x007fbff3204a30 @options={strict:true}>
  #   #    ]
  #
  # source://activemodel-5.2.8.1/lib/active_model/validations.rb:194
  def validators; end

  # List all validators that are being used to validate a specific attribute.
  #
  #   class Person
  #     include ActiveModel::Validations
  #
  #     attr_accessor :name , :age
  #
  #     validates_presence_of :name
  #     validates_inclusion_of :age, in: 0..99
  #   end
  #
  #   Person.validators_on(:name)
  #   # => [
  #   #       #<ActiveModel::Validations::PresenceValidator:0x007fe604914e60 @attributes=[:name], @options={}>,
  #   #    ]
  #
  # source://activemodel-5.2.8.1/lib/active_model/validations.rb:256
  def validators_on(*attributes); end

  private

  # source://activemodel-5.2.8.1/lib/active_model/validations/validates.rb:160
  def _parse_validates_options(options); end

  # When creating custom validators, it might be useful to be able to specify
  # additional default keys. This can be done by overwriting this method.
  #
  # source://activemodel-5.2.8.1/lib/active_model/validations/validates.rb:156
  def _validates_default_keys; end
end

# source://activemodel-5.2.8.1/lib/active_model/validations.rb:91
ActiveModel::Validations::ClassMethods::VALID_OPTIONS_FOR_VALIDATE = T.let(T.unsafe(nil), Array)

# source://validate_url-1.0.15/lib/validate_url.rb:8
class ActiveModel::Validations::UrlValidator < ::ActiveModel::EachValidator
  # @return [UrlValidator] a new instance of UrlValidator
  #
  # source://validate_url-1.0.15/lib/validate_url.rb:11
  def initialize(options); end

  # source://validate_url-1.0.15/lib/validate_url.rb:21
  def validate_each(record, attribute, value); end

  protected

  # source://validate_url-1.0.15/lib/validate_url.rb:46
  def filtered_options(value); end

  # source://validate_url-1.0.15/lib/validate_url.rb:52
  def validate_url(record, attribute, value, schemes); end
end

# source://validate_url-1.0.15/lib/validate_url.rb:9
ActiveModel::Validations::UrlValidator::RESERVED_OPTIONS = T.let(T.unsafe(nil), Array)
