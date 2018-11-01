require 'dodo/window'
module Dodo
  class Container
    attr_reader :windows, :duration
    def initialize(over:, &block)
      window = Dodo::Window.new(over, &block)
      @windows = [OffsetHappening.new(window, 0)]
      @duration = over
    end

    def <<(offset_window)
      @windows << offset_window
      @duration = [@duration, offset_window.offset + offset_window.duration].max
      self
    end
  end
end
