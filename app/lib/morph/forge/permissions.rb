# typed: strict
# frozen_string_literal: true

module Morph
  module Forge
    # A permission set on one repository, in GitHub's five-level shape, which
    # is what the collaborations table stores. Other forges map onto it.
    class Permissions < T::Struct
      const :pull, T::Boolean
      const :triage, T::Boolean
      const :push, T::Boolean
      const :maintain, T::Boolean
      const :admin, T::Boolean
    end
  end
end
