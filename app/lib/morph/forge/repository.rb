# typed: strict
# frozen_string_literal: true

module Morph
  module Forge
    # One repository as the forge describes it, in the fields morph.io keeps.
    class Repository < T::Struct
      extend T::Sig

      const :id, Integer
      const :name, String
      const :full_name, String
      const :description, T.nilable(String)
      const :private, T::Boolean
      const :default_branch, T.nilable(String)
      const :web_url, String
      const :clone_url, String
      # The login of the user or organisation that owns it on the forge.
      const :owner_login, String
    end
  end
end
