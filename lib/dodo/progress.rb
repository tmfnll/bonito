module Dodo
  class BaseProgress
    attr_reader :total
    attr_accessor :current

    def initialize(total: nil, prefix: nil)
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

  class ProgressLogger < BaseProgress

    def initialize(logger, total: nil, prefix: nil)
      @logger = logger
      super total: total, prefix: prefix
    end

    def current=(value)
      super value
      @logger.info to_s
    end
  end
end
