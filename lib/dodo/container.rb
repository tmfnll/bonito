require 'dodo/window'
module Dodo
  class Container
    attr_reader :windows, :duration
    def initialize(over:, &block)
      @windows = []
      @duration = 0
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
  end
end
