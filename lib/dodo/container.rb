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

    def scheduler(distribution, context, opts = {})
      ContainerScheduler.new self, distribution, context, opts
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

  class ContainerScheduler # :nodoc:
    include Enumerable

    def initialize(container, distribution, context, opts = {})
      @container = container
      @starting_offset = distribution.next
      @context = context
      @moment_heap = Containers::MinHeap.new []
      @window_schedulers = container.windows.map do |window|
        window.scheduler(
          [@starting_offset + window.offset].to_enum, @context, opts
        ).each
      end
      @window_schedulers.each { |scheduler| push_moment_from_enum scheduler }
    end

    def each
      return to_enum(:each) unless block_given?

      until @moment_heap.empty?
        moment = @moment_heap.next_key
        scheduler = @moment_heap.pop
        yield moment
        push_moment_from_enum scheduler
      end
    end

    private

    def push_moment_from_enum(scheduler)
      @moment_heap.push scheduler.next, scheduler
    rescue StopIteration
      # ignore
    end
  end
end
