require 'dodo/happening'
require 'dodo/window'
require 'algorithms'

module Dodo
  class Container < Happening
    attr_reader :windows
    def initialize(over:, &block)
      @windows = []
      super 0
      window = Dodo::Window.new(over, &block)
      self << OffsetHappening.new(window, 0)
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

    def enum(starting_offset)
      ContainerEnumerator.new self, starting_offset
    end
  end

  class ContainerEnumerator
    include Enumerable

    def initialize(container, starting_offset)
      @container = container
      @starting_offset = starting_offset
      @moment_heap = Containers::MinHeap.new []
      @window_enumerators = container.windows.map do |window|
        window.enum(@starting_offset + window.offset).each
      end
      @window_enumerators.each { |enum| push_moment_from_enum enum }
    end

    def each
      return to_enum(:each) unless block_given?

      until @moment_heap.empty?
        moment = @moment_heap.next_key
        enum = @moment_heap.pop
        yield moment
        push_moment_from_enum enum
      end
    end

    private

    def push_moment_from_enum(enum)
      @moment_heap.push enum.next, enum
    rescue StopIteration
      # ignore
    end
  end
end
