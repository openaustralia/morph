# typed: strict
# frozen_string_literal: true

module Morph
  module Forge
    # An account on the forge as it describes itself: a person or a group.
    class Profile < T::Struct
      const :uid, String
      const :login, String
      const :name, T.nilable(String)
      const :email, T.nilable(String)
      const :avatar_url, T.nilable(String)
      const :blog, T.nilable(String)
      const :company, T.nilable(String)
      const :location, T.nilable(String)
    end
  end
end
