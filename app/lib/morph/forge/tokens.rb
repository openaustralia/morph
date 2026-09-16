# typed: strict
# frozen_string_literal: true

module Morph
  module Forge
    # The credentials a forge issues for one identity.
    class Tokens < T::Struct
      const :access_token, String
      const :refresh_token, T.nilable(String)
      const :expires_at, T.nilable(Time)
    end
  end
end
