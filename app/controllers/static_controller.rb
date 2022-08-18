# typed: strict
# frozen_string_literal: true

class StaticController < ApplicationController
  extend T::Sig

  sig { void }
  def index; end
end
