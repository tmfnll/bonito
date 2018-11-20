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
      @duration = [@duration, offset_window.offset + offset_window.duration].max
      self
    end

    def also(after:, over:, &block)
      window = Dodo::Window.new over, &block
      self << OffsetHappening.new(window, after)
    end

    def also_use(window, after:)
      self << OffsetHappening.new(window, after)
    end

    def scales?
      false
    end

    def enum(opts = {})
      ContainerEnumerator.new self, opts
    end
  end

  class ContainerEnumerator
    include Enumerable
    include Scalable

    def initialize(container, opts = {})
      @container = container
      @opts = opts
      @moment_heap = Containers::MinHeap.new []
      @window_enumerators = container.windows.map do |window|
        window.enum(nil, opts).each
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
