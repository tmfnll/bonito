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

    def <<(offset_window)
      @windows << offset_window
      self.duration = [duration, offset_window.offset + offset_window.duration].max
      self
    end

    def also(after:, over:, &block)
      window = Dodo::Window.new over, &block
      self << OffsetHappening.new(window, after)
    end

    def also_use(window, after:)
      self << OffsetHappening.new(window, after)
    end

    def crammed(*)
      [self]
    end

    def scheduler(distribution, context, opts = {})
      ContainerScheduler.new self, distribution, context, opts
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
        window.scheduler([@starting_offset + window.offset].to_enum, @context, opts).each
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
