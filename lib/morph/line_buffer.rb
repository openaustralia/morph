module Morph
  class LineBuffer
    def initialize
      @buffer = ''
    end

    def extract
      r = []
      while i = @buffer.index("\n")
        line = @buffer[0..i]
        yield line if block_given?
        r << line
        @buffer = @buffer[i + 1..-1]
      end
      r
    end

    def <<(text)
      @buffer << text
    end

    def finish
      fail if @buffer.include?("\n")
      r = @buffer
      @buffer = ''
      r
    end
  end
end
