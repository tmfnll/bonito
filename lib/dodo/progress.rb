module Dodo
   module ProgressCounter
    attr_accessor :total
    attr_accessor :current

    def setup(total: nil, prefix: nil)
      @total = total
      @prefix = prefix
      @current = 0
    end

    def +(other)
      self.current = (current + other)
      self
    end

    def to_s
      "#{prefix} #{current}#{total.nil? ? '' : " / #{total}"}"
    end

    private

    def prefix
      @prefix ||= "#{self.class}{#{object_id}} : Progress Made :"
    end
  end

  class ProgressLogger
    include ProgressCounter

    def initialize(logger, total: nil, prefix: nil)
      @logger = logger
      setup total: total, prefix: prefix
    end

    def current=(value)
      @current = value
      @logger.info to_s
    end
  end

  class ProgressDecorator < SimpleDelegator
    def initialize(enumerable, progress)
      @enumerable = enumerable
      @progress = progress
      super enumerable
    end

    def each
      return to_enum(:each) unless block_given?
      @enumerable.each do |item|
        yield item
        @progress += 1
      end
    end
  end
end
