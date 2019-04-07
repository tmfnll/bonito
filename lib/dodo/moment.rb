# frozen_string_literal: true

require 'dodo/timeline'

module Dodo
  class MomentScheduler < Scheduler # :nodoc:
    def each
      yield ScopedMoment.new(timeline, starting_offset, scope)
    end
  end

  # A Moment represents a single instant in time in which events may occur.
  # Scheduler classes may be used in order to yield a sequence of
  # Moment objects, each of which has been decorated with a Scope object,
  # within the context of which the events defined in the Moment will be
  # evaluated, as well as an Integer offset representing a number of
  # seconds from some arbitrary start point.
  #
  # Such a Scheduler object may be passed to a Runner, along with some fixed
  # starting point.  The runner can the be used to  evaluate the events defined
  # in each of the scheduled Moment objects, simulating the time at which they
  # occur to be that of the starting point plus the offset.
  class Moment < Timeline
    schedule_with MomentScheduler

    # Initialises a new Moment
    # [block] A Proc that will be evaluated at some simulated point in time by a Runner
    def initialize(&block)
      @block = block
      super 0
    end

    def to_proc # :nodoc:
      @block
    end
  end
end
