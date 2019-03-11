# frozen_string_literal: true

require 'dodo/happening'

module Dodo
  class MomentScheduler < Scheduler # :nodoc:
    def each
      yield ContextualMoment.new(happening, starting_offset, context)
    end
  end

  class Moment < Happening # :nodoc:
    schedule_with MomentScheduler

    def initialize(&block)
      @block = block
      super 0
    end

    def to_proc
      @block
    end
  end
end
