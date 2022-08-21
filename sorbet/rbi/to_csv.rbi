# typed: true

class Array
  # No idea why sorbet doesn't already know about this
  sig { returns(String) }
  def to_csv; end
end