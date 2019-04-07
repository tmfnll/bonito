# frozen_string_literal: true

require 'dodo/timeline'
require 'dodo/moment'
require 'securerandom'
require 'timecop'

module Dodo # :nodoc:
  class SerialScheduler < Scheduler # :nodoc:
    def initialize(serial, starting_offset, parent_scope, opts = {})
      super serial, starting_offset, parent_scope.push, opts
      @distribution = Distribution.new starting_offset, serial, opts
    end

    # :reek:NestedIterators:
    # Not sure how this can be avoided nicely at the moment
    def each
      @distribution.each do |timeline, offset|
        timeline.scheduler(offset, scope, opts).each do |moment|
          yield moment
        end
      end
    end
  end

  # A SerialTimeline is a data structure with a duration (measured in seconds) that
  # contains +timelines+. A +timeline+ is any instance of a class that inherits
  # from the Timeline base class.
  #
  # A SerialTimeline serves to define an interval in which it may be _simulated_ that
  # one or more Moment objects are _evaluated_ _in_ series_.
  #
  # A SerialTimeline exposes methods that can either be used to define these
  # Moment objects directly or to create additional _child_ data structures
  # (i.e ParallelTimeline objects or further, child SerialTimeline objects) which can in
  # turn be provide more fine grained control over precisely _when_
  # any given Moment objects may be evaluated.
  #
  # @example
  #
  #   Dodo.over(2.weeks) do
  #     please { puts Time.now }
  #   end
  #
  # The above defines a SerialTimeline (using the Dodo#over module method) that
  # specifies a 2 week time period. A single Moment is included in this serial
  # (via the #please factory method).  When the top level SerialTimeline is
  # evaluated (using a Runner object) the block
  #
  #   puts Time.now
  #
  # is evaluated _exactly_ _once_. Furthermore, the simulated time at which
  # the block is evaluated will be contained at some point within the 2 week
  # interval beginning on some start date provided when instantiating the
  # Runner object.
  #
  # As mentioned, it is also possible to include other data structures within
  # SerialTimeline objects, including other SerialTimeline objects.
  #
  # @example
  #
  # We could use the #over method to add an empty SerialTimeline to the previous
  # example in order to force the already included Moment to be evaluated
  # during the last day of the 2 week period.
  #
  #   Dodo.over(2.weeks) do
  #     over(2.weeks - 1.day)  # This defines an empty serial
  #     please { puts Time.now }
  #   end
  #
  # The empty SerialTimeline returned by the #over factory method consumes 13 days
  # of the parent SerialTimeline object's total duration of 2 weeks.  This means that
  # when this parent SerialTimeline is evaluated, the Moment will be _as_ _if_ _it_
  # _occurred_ during the _final_ _day_ of the 2 week period.
  #
  # Finally, we may also define ParallelTimeline objects within serials using the
  # #simultaneously method.  These allow for multiple SerialTimeline
  # objects to be defined over the same time period and for any Moment
  # objects contained within to be _interleaved_ when the parent SerialTimeline is
  # ultimately evaluated.
  #
  # The #simultaneously method instantiates a ParallelTimeline object, whilst accepting
  # a block.  The block is evaluated within the context of the new ParallelTimeline.
  # Timelines defined within this block will be evaluated in parallel.
  #
  # Note that ParallelTimeline implements many of the same methods as SerialTimeline
  #
  # @example
  #
  #   Dodo.over(2.weeks) do
  #     simultaneously do
  #       over 1.week do
  #         puts "SerialTimeline 1 #{Time.now}"
  #       end
  #       over 6.days, after: 1.day do
  #         puts "SerialTimeline 2 #{Time.now}"
  #       end
  #     end
  #
  #     over 1.week {}  # This defines an empty serial
  #   end
  #
  # Now, when evaluating this SerialTimeline both the blocks
  #   puts "SerialTimeline 1 #{Time.now}"
  # and
  #   puts "SerialTimeline 2 #{Time.now}"
  # will be evaluated once during the first week.  The precise instant is
  # chosen randomly within this interval with the only constraint being
  # that the second block cannot be evaluated during the first day (This
  # offset is controlled by the +after+ parameter of the #simultaneously
  # method).
  #
  # *Note* that the moment from the second SerialTimeline could still be evaluated at
  # a simulated time _before_ that at which the moment from the first SerialTimeline
  # is evaluated.
  class SerialTimeline < Timeline
    schedule_with SerialScheduler

    # Instantiate a new SerialTimeline object
    #
    # @param [Integer] duration The total time period (in seconds) that the
    # SerialTimeline encompasses
    # @param [Timeline] parent If the SerialTimeline is a child of another Timeline,
    # parent is this Timeline
    # @param [Proc] block A block that will be evaluated within the context of
    # the newly created SerialTimeline.  Note that the following two statements are
    # equivalent
    #
    #   a_serial = Dodo::SerialTimeline.new(1.week) do
    #     please { p Time.now }
    #   end
    #
    #   another_serial = Dodo::SerialTimeline.new 1.week
    #   serial.please { p Time.now }
    #
    # The ability to include a block in this way is in order to allow the
    # code used to define a given SerialTimeline will reflect its hierarchy.
    def initialize(duration, parent = nil, &block)
      @parent = parent
      @total_child_duration = 0
      super duration
      instance_eval(&block) if block_given?
    end

    # The the amount of #duration remaining taking into account the duration of
    # any Timeline objects included as children of the SerialTimeline.
    def unused_duration
      duration - @total_child_duration
    end

    # Define a new SerialTimeline and add it as a child to the current SerialTimeline
    #
    # @param [Integer] duration
    # The duration (in seconds) of the newly created child SerialTimeline
    #
    # @params [Proc] block A block passed to the #new method on the child SerialTimeline
    # object
    #
    # @return [SerialTimeline] The newly created SerialTimeline object
    def over(duration, &block)
      self.class.new(duration, self, &block).tap(&method(:use))
    end

    # Define a new Moment and add it as a child to the current SerialTimeline
    #
    # @params [Proc] block A block passed to the #new method on the child Moment
    # object
    #
    # @return [Moment] The newly created Moment object
    def please(&block)
      Moment.new(&block).tap(&method(:use))
    end

    # Define a new serial and append it multiple times as a child of the
    # current SerialTimeline object.
    #
    # @param [Integer] times The number of times that the new SerialTimeline object to
    # be appended to the current SerialTimeline
    #
    # @param [Integer] over The total duration (in senconds) of the new
    # repeated SerialTimeline objects.
    #
    # @param [Proc] block A block passed to the #new method on the child SerialTimeline
    # object
    #
    # @return [SerialTimeline] The current SerialTimeline
    def repeat(times:, over:, &block)
      repeated_block = proc { times.times { instance_eval(&block) } }
      over(over, &repeated_block)
    end

    # Define a new ParallelTimeline object append it as a child to the current
    # SerialTimeline. Also permit the evaluation of methods within the context
    # of the new ParallelTimeline.
    #
    # @param [Proc] block
    # A block to be passed to the #new method on the child ParallelTimeline method.
    #
    # @return [SerialTimeline] The current SerialTimeline object
    def simultaneously(&block)
      use ParallelTimeline.new(&block)
    end

    # Append an existing Timeline as a child of the current SerialTimeline
    #
    # @params [Array] timelines An array of Timeline objects that will be
    # appended, in order to the current SerialTimeline
    #
    # @return [SerialTimeline] The current SerialTimeline object
    def use(*timelines)
      timelines.each { |timeline| send :<<, timeline }
      self
    end

    # Combine two Windows into a single, larger SerialTimeline object.
    #
    # @param [SerialTimeline] other Some other SerialTimeline object
    #
    # @return [SerialTimeline] a SerialTimeline object consisting of the ordered child Timeline
    # objects of the current SerialTimeline with the ordered child Timeline objects of
    # +other+ appended to the end.
    def +(other)
      SerialTimeline.new duration + other.duration do
        use(*(to_a + other.to_a))
      end
    end

    # Repeatedly apply the #+ method of the current SerialTimeline to itself
    #
    # @param [Integer] other Denotes the number of times the current serial
    # should be added to itself.
    #
    # @return [SerialTimeline] A new SerialTimeline object
    #
    # Note that the following statements are equivalent for
    # some serial +serial+:
    #
    #   serial * 3
    #   serial + serial + serial
    #
    def *(other)
      SerialTimeline.new(duration * other) do
        use(*Array.new(other) { entries }.reduce(:+))
      end
    end

    # Scale up a serial by parallelising it according to some factor
    #
    # @param [Integer] other An Integer denoting the degree of parallelism with
    # which to scale the serial.
    #
    # @return [ParallelTimeline] A new ParallelTimeline whose child timelines are precisely
    # the current serial repeated +other+ times.
    def **(other)
      this = self
      SerialTimeline.new(duration) do
        simultaneously { use(*Array.new(other) { this }) }
      end
    end

    private

    def <<(timeline)
      tap do
        @total_child_duration += timeline.duration
        if @total_child_duration > duration
          raise WindowDurationExceeded, "#{@total_child_duration} > #{duration}"
        end

        super timeline
      end
    end
  end

  class DodoException < StandardError
  end

  class WindowDurationExceeded < DodoException
  end

  def self.over(duration, &block)
    SerialTimeline.new duration, &block
  end

  class Distribution # :nodoc:
    include Enumerable

    def initialize(start, serial, stretch: 1)
      @start = start
      @serial = serial
      @stretch = stretch
    end

    def each
      @serial.zip(generate_offsets).reduce(0) do |consumed, zipped|
        timeline, offset = zipped
        yield timeline, @start + (@stretch * (offset + consumed))
        consumed + timeline.duration
      end
    end

    private

    def interval
      @serial.unused_duration
    end

    def size
      @serial.size
    end

    def generate_offsets
      Array.new(size) { SecureRandom.random_number(interval) }.sort
    end
  end
end
