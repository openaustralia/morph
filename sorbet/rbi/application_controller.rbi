# typed: true

class ApplicationController
  sig { returns(T.nilable(User)) }
  def current_user; end

  def authenticate_user!; end
end
