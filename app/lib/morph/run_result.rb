# typed: strict
# frozen_string_literal: true

module Morph
  class RunResult
    extend T::Sig

    sig { returns(Integer) }
    attr_reader :status_code

    sig { returns(T::Hash[String, T.nilable(Tempfile)]) }
    attr_reader :files

    sig { returns(T.nilable(T::Hash[Symbol, T.untyped])) }
    attr_reader :time_params

    sig { params(status_code: Integer, files: T::Hash[String, T.nilable(Tempfile)], time_params: T.nilable(T::Hash[Symbol, T.untyped])).void }
    def initialize(status_code, files, time_params)
      @status_code = status_code
      @files = files
      @time_params = time_params
    end
  end
end
