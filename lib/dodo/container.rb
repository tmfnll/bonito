# frozen_string_literal: true

require 'dodo/happening'
require 'dodo/window'
require 'algorithms'

module Dodo
  class Container < Happening # :nodoc:
    attr_reader :windows
    def initialize
      @windows = []
      super 0
    end

    def over(duration, after: 0, &block)
      use Dodo::Window.new(duration, &block), after: after
    end

    def also(over: duration, after: 0, &block)
      over(over, after: after, &block)
    end

    def use(*windows, after: 0)
      windows.each { |window| send :<<, OffsetHappening.new(window, after) }
      self
    end

    def repeat(times:, over:, after: 0, &block)
      times.times { over(over, after: after, &block) }
      self
    end

    def scheduler(starting_offset, context, opts = {})
      ContainerScheduler.new self, starting_offset, context, opts
    end

    # :reek:FeatureEnvy:
    # Any method to resolve this smell would have to be included on the
    # :HappeningOffset: class which would overload it somewhat.  It may be
    # worth creating a separate decorator for these offset :Window: objects
    # within :Container:s rather than recycling the existing :OffsetHappening:.
    def window_schedulers(starting_offset, context, opts)
      windows.map do |window|
        window.scheduler(starting_offset + window.offset, context, opts)
      end
    end

    private

    def <<(offset_window)
      @windows << offset_window
      self.duration = [
        duration, offset_window.offset + offset_window.duration
      ].max
      self
    end
  end

  class ContainerScheduler < Scheduler # :nodoc:
    def initialize(container, starting_offset, context, opts = {})
      super
      @window_schedulers = container.window_schedulers(
        starting_offset, context, opts
      ).map(&:to_enum)
      @heap = LazyMinHeap.new(*@window_schedulers)
    end

    def each
      @heap.each { |moment| yield moment }
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
