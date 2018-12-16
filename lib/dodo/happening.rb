module Dodo
  class Happening
    attr_reader :duration

    def initialize(duration)
      @duration = duration
    end

    private

    attr_writer :duration
  end

  class OffsetHappening < SimpleDelegator
    attr_reader :offset
    def initialize(happening, offset)
      @offset = offset
      super happening
    end

    def freeze
      Timecop.freeze(offset) { yield }
    end

    def ==(other)
      offset == other.offset && __getobj__ == other.__getobj__
    end

    def <=>(other)
      offset <=> other.offset
    end
  end

  class ContextualMoment < OffsetHappening
    attr_reader :context
    def initialize(moment, offset, context)
      @context = context
      super moment, offset
    end

    def evaluate
      freeze { @context.instance_eval(&block) }
    end
  end
end
