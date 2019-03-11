# frozen_string_literal: true

require 'dodo/timeline'

module Dodo
  class MomentScheduler < Scheduler # :nodoc:
    def each
      yield ContextualMoment.new(timeline, starting_offset, context)
    end
  end

  class Moment < Timeline # :nodoc:
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
