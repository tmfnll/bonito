# frozen_string_literal: true

require 'dodo/timeline'
require 'dodo/moment'
require 'securerandom'
require 'timecop'

module Dodo # :nodoc:
  class WindowScheduler < Scheduler # :nodoc:
    def initialize(window, starting_offset, parent_context, opts = {})
      super window, starting_offset, parent_context.push, opts
      @distribution = Distribution.new starting_offset, window, opts
    end

    # :reek:NestedIterators:
    # Not sure how this can be avoided nicely at the moment
    def each
      @distribution.each do |timeline, offset|
        timeline.scheduler(offset, context, opts).each do |moment|
          yield moment
        end
      end
    end
  end

  # A Window is a data structure with a duration (measured in seconds) that
  # contains Timelines. A Timeline is an instance of either the Moment,
  # Container Window classes.
  #
  # A Window serves to define an interval in which it may be +simulated+ that
  # one or more Moment objects are _evaluated_ _in_ series_.
  #
  # A Window exposes methods that can either be used to define these
  # Moment objects directly or to create additional _child_ data structures
  # (i.e Container objects or further, child Window objects) which can in
  # turn be provide more fine grained control over precisely _when_
  # any given Moment objects may be evaluated.
  #
  # @example
  #
  #   Dodo.over(2.weeks) do
  #     please { puts Time.now }
  #   end
  #
  # The above defines a Window (using the Dodo#over method) that encompasses
  # a 2 week time period. A single Moment is included in this window
  # (via the #please factory method).  When the top level Window is
  # evaluated (using a Runner object) the block
  #
  #   puts Time.now
  #
  # is evaluated _exactly_ _once_. Furthermore, the simulated time at which
  # the block is evaluated will be contained at some point within the 2 week
  # interval beginning on the start date provided when instantiating the
  # Runner object.
  #
  # As mentioned, it is also possible to include other data structures within
  # Window objects, including other Window objects.
  #
  # @example
  #
  # We could use the #over method to add an empty Window to the previous
  # example in order to force the already included Moment to be evaluated
  # during the last day of the 2 week period.
  #
  #   Dodo.over(2.weeks) do
  #     over(2.weeks - 1.day) {}  # This defines a non-operational window
  #     please { puts Time.now }
  #   end
  #
  # The empty Window returned by the #over factory method consumes 13 days
  # of the parent Window object's total duration of 2 weeks.  This means that
  # when this parent Window is evaluated, the Moment will be as if it
  # occurred during the final day of the 2 week period.
  #
  # Finally, we may also define Container objects within windows using the
  # #simultaneously factory method.  These allow for multiple Window
  # objects to be defined over the same time period and for any Moment
  # objects contained within to be _interleaved_ when the parent Window is
  # ultimately evaluated.
  #
  # @example
  #
  #   Dodo.over(2.weeks) do
  #     simultaneously(over: 1.week) do
  #       please do
  #         puts "Window 1 #{Time.now}"
  #       end
  #     end.also(after: 1.day, over: 6.days) do
  #       please do
  #         puts "Window 2 #{Time.now}"
  #       end
  #     end
  #
  #     over 1.week {}  # This defines an non-operational window
  #   end
  #
  # Now, when evaluating this Window both the blocks
  #   puts "Window 1 #{Time.now}"
  # and
  #   puts "Window 2 #{Time.now}"
  # will be evaluated once during the first week.  The precise instant is
  # chosen randomly within this interval with the only constraint being
  # that the second block cannot be evaluated during the first day (This
  # offset is controlled by the +after+ parameter of the #simultaneously
  # method).
  #
  # *Note* that the moment from the second Window could easily be evaluated at
  # a simulated time _before_ that at which the moment from the first Window
  # is evaluated.
  class Window < Timeline
    schedule_with WindowScheduler

    def initialize(duration, parent = nil, &block)
      @parent = parent
      @total_child_duration = 0
      super duration
      instance_eval(&block)
    end

    def unused_duration
      duration - @total_child_duration
    end

    def over(duration, &block)
      self.class.new(duration, self, &block).tap(&method(:use))
    end

    def please(&block)
      Moment.new(&block).tap(&method(:use))
    end

    def repeat(times:, over:, &block)
      repeated_block = proc { times.times { instance_eval(&block) } }
      over(over, &repeated_block)
    end

    def simultaneously(&block)
      Container.new.tap do |container|
        container.instance_eval(&block)
        use container
      end
    end

    def use(*timelines)
      timelines.each { |timeline| send :<<, timeline }
      self
    end

    private

    def <<(timeline)
      tap do
        @total_child_duration += timeline.duration
        if @total_child_duration > duration
          raise WindowDurationExceeded, "#{@total_child_duration} > #{duration}"
        end

        @timelines << timeline
      end
    end
  end

  class DodoException < StandardError
  end

  class WindowDurationExceeded < DodoException
  end

  def self.over(duration, &block)
    Window.new duration, &block
  end

  class Distribution # :nodoc:
    include Enumerable

    def initialize(start, window, stretch: 1)
      @start = start
      @window = window
      @stretch = stretch
    end

    def each
      @window.zip(generate_offsets).reduce(0) do |consumed, zipped|
        timeline, offset = zipped
        yield timeline, @start + (@stretch * (offset + consumed))
        consumed + timeline.duration
      end
    end

    private

    def interval
      @window.unused_duration
    end

    def size
      @window.size
    end

    def generate_offsets
      Array.new(size) { SecureRandom.random_number(interval) }.sort
    end
  end
end
