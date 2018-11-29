# frozen_string_literal: true

require 'dodo/happening'
require 'dodo/scalable'

module Dodo
  class Moment < Happening
    attr_reader :block

    def initialize(&block)
      @block = block
      super 0
    end

    def enum(starting_offset, opts = {})
      MomentEnumerator.new self, starting_offset, opts
    end

    def crammed(factor:)
      Array.new(factor) { self }
    end
  end

  class MomentEnumerator
    include Enumerable

    def initialize(moment, offset, _opts = {})
      @moment = moment
      @offset = offset
    end

    def each
      return to_enum(:each) unless block_given?

      yield OffsetHappening.new(@moment, @offset)
    end
  end
end
