# typed: strict
# frozen_string_literal: true

module Morph
  module Forge
    class Collaborator < T::Struct
      const :login, String
      const :permissions, Permissions
    end
  end
end
