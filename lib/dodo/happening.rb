# frozen_string_literal: true

module Dodo
  class Happening # :nodoc:
    class << self
      attr_reader :scheduler_class

      def schedule_with(klass)
        @scheduler_class = klass
      end
    end

    attr_reader :duration
    def initialize(duration)
      @duration = duration
    end

    def scheduler(starting_offset, context, opts = {})
      self.class.scheduler_class.new self, starting_offset, context, opts
    end

    private

    attr_writer :duration
  end

  class OffsetHappening < SimpleDelegator # :nodoc:
    attr_reader :offset
    def initialize(happening, offset)
      @offset = offset
      super happening
    end

    def ==(other)
      offset == other.offset && __getobj__ == other.__getobj__
    end

    def <=>(other)
      offset <=> other.offset
    end

    def schedule(starting_offset, context, opts = {})
      __getobj__.scheduler(starting_offset + offset, context, opts)
    end
  end

  class ContextualMoment < OffsetHappening # :nodoc:
    def initialize(moment, offset, context)
      @context = context
      super moment, offset
    end

    def evaluate
      freeze { @context.instance_eval(&self) }
    end

    private

    def freeze
      Timecop.freeze(offset) { yield }
    end
  end

  class Scheduler # :nodoc:
    include Enumerable

    def initialize(happening, starting_offset, context, opts = {})
      @happening = happening
      @starting_offset = starting_offset
      @context = context
      @opts = opts
    end

    private

    attr_reader :happening, :starting_offset, :context, :opts
  end
end
