# frozen_string_literal: true

require 'dodo/happening'

module Dodo
  class Moment < Happening # :nodoc:
    def initialize(&block)
      @block = block
      super 0
    end

    def scheduler(distribution, context, opts = {})
      MomentScheduler.new self, distribution, context, opts
    end

    def to_proc
      @block
    end
  end

  class MomentScheduler < Scheduler # :nodoc:
    def each
      yield ContextualMoment.new(@happening, @starting_offset, @context)
    end
  end
end
