module Dodo
  class Happening
    attr_reader :duration

    def initialize(duration)
      @duration = duration
    end
  end

  class OffsetHappening < SimpleDelegator
    attr_reader :offset
    def initialize(happening, offset)
      @offset = offset
      super happening
    end

    def self.adjust(offset_happening, offset)
      new offset_happening.__getobj__, offset
    end

    def ==(other)
      offset == other.offset && __getobj__ == other.__getobj__
    end

    def <=>(other)
      offset <=> other.offset
    end
  end
end
