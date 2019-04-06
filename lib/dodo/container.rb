# frozen_string_literal: true

require 'dodo/timeline'
require 'dodo/serial_timeline'
require 'algorithms'

module Dodo
  class ContainerScheduler < Scheduler # :nodoc:
    def initialize(container, starting_offset, context, opts = {})
      super
      @schedulers = container.map do |timeline|
        timeline.schedule(starting_offset, context, opts).to_enum
      end
      @heap = LazyMinHeap.new(*@schedulers)
    end

    def each
      @heap.each { |moment| yield moment }
    end
  end

  class Container < Timeline # :nodoc:
    schedule_with ContainerScheduler

    def initialize(&block)
      super 0
      instance_eval(&block) if block_given?
    end

    def over(duration, after: 0, &block)
      use Dodo::SerialTimeline.new(duration, &block), after: after
    end

    def also(over: duration, after: 0, &block)
      over(over, after: after, &block)
    end

    def use(*timelines, after: 0)
      timelines.each do |timeline|
        send :<<, OffsetTimeline.new(timeline, after)
      end
      self
    end

    def repeat(times:, over:, after: 0, &block)
      times.times { over(over, after: after, &block) }
      self
    end

    private

    def <<(offset_timeline)
      super offset_timeline
      self.duration = [
        duration, offset_timeline.offset + offset_timeline.duration
      ].max
      self
    end
  end

  class LazyMinHeap # :nodoc:
    include Enumerable

    def initialize(*sorted_enums)
      @heap = Containers::MinHeap.new []
      @enums = Set[*sorted_enums]
      @enums.each(&method(:push_from_enum))
    end

    def pop
      moment = @heap.next_key
      enum = @heap.pop
      push_from_enum enum
      moment
    end

    def empty?
      @enums.empty? && @heap.empty?
    end

    def each
      yield pop until empty?
    end

    private

    def push_from_enum(enum)
      @heap.push enum.next, enum
    rescue StopIteration
      @enums.delete enum
    end
  end
end
