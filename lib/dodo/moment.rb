# frozen_string_literal: true

require 'dodo/happening'
require 'dodo/scalable'

module Dodo
  class Moment < Happening

    def initialize(&block)
      @block = block
      super 0
    end

    def enum(starting_offset, context, opts = {})
      MomentEnumerator.new self, starting_offset, context, opts
    end

    def to_proc
      @block
    end

    def crammed(factor:)
      Array.new(factor) { self }
    end
  end

  class MomentEnumerator
    include Enumerable

    def initialize(moment, offset, context, _opts = {})
      @moment = moment
      @offset = offset
      @context = context
    end

    def each
      return to_enum(:each) unless block_given?

      yield ContextualMoment.new(@moment, @offset, @context)
    end
  end
end
