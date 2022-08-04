# typed: false
# frozen_string_literal: true

class OnlyAdmins < ActiveAdmin::AuthorizationAdapter
  def authorized?(_action, _subject = nil)
    user.admin?
  end
end
