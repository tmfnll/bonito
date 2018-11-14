module Dodo
  class Happening
    attr_reader :duration

    def initialize(duration)
      @duration = duration
    end
  end

  class OffsetHappening < SimpleDelegator
    attr_reader :offset
    def initialize(moment, offset)
      @offset = offset
      super moment
    end

    def ==(other)
      offset == other.offset && __getobj__ == other.__getobj__
    end
  end
end
