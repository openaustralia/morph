# typed: true
# frozen_string_literal: true

module Morph
  class RunResult
    attr_reader :status_code, :files, :time_params

    def initialize(status_code, files, time_params)
      @status_code = status_code
      @files = files
      @time_params = time_params
    end
  end
end
