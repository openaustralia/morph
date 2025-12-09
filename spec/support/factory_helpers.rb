# typed: false
# frozen_string_literal: true

module FactoryHelpers
  LOREM = "Lorem ipsum dolor sit amet, consectetur adipiscing elit, " \
    "sed do eiusmod tempor incididunt ut labore et dolore magna aliqua. " \
    "Ut enim ad minim veniam, quis nostrud exercitation ullamco laboris nisi ut aliquip ex ea commodo consequat. " \
    "Duis aute irure dolor in reprehenderit in voluptate velit esse cillum dolore eu fugiat nulla pariatur. " \
    "Excepteur sint occaecat cupidatat non proident, sunt in culpa qui officia deserunt mollit anim id est laborum. "

  def self.max_string(prefix, length)
    # Natural text with XSS vectors embedded
    base = "#{prefix} where the \"quick\" &xss; `brown` fox jumped over the </lazy> dog's $tail 1234567890 times, "
    lorem_count = ((length - base.length) / LOREM.length).to_i + 1
    base = "#{base}#{LOREM * lorem_count}"
    "#{base[0...(length - 1)]}!"
  end

  def self.max_serialized(prefix, length)
    array = []
    loop do
      next_item = "#{prefix}#{array.size}"
      break if (array + [next_item]).to_yaml.length >= length

      array << next_item
    end
    array
  end

  # Returns a name (can be used with urls as well)
  def self.max_name(prefix, length)
    name = "#{prefix}-#{length}"
    prefix = prefix.gsub(%r{[-:/_]+}, "-")
    loop do
      next_name = "#{name}_#{prefix}-#{length - (name.size + prefix.size + 2)}"
      break if next_name.length > length

      name = next_name
    end
    name
  end
end

if defined?(RSpec) && RSpec.respond_to?(:configure)
  RSpec.configure do |config|
    config.include FactoryHelpers
  end
end
