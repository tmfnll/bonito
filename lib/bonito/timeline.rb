# frozen_string_literal: true

module Bonito
  class Timeline # :nodoc:
    include Enumerable

    class << self
      attr_reader :scheduler_class

      def schedule_with(klass)
        @scheduler_class = klass
      end
    end

    attr_reader :duration

    def initialize(duration)
      @duration = duration
      @timelines = []
    end

    def each
      @timelines.each { |timeline| yield timeline }
    end

    def size
      @timelines.size
    end

    def scheduler(starting_offset, scope, opts = {})
      self.class.scheduler_class.new self, starting_offset, scope, opts
    end

    private

    attr_writer :duration

    def <<(timeline)
      @timelines << timeline
    end
  end

  class OffsetTimeline < SimpleDelegator # :nodoc:
    attr_reader :offset
    def initialize(timeline, offset)
      @offset = offset
      super timeline
    end

    def ==(other)
      offset == other.offset && __getobj__ == other.__getobj__
    end

    def <=>(other)
      offset <=> other.offset
    end

    def schedule(starting_offset, scope, opts = {})
      __getobj__.scheduler(starting_offset + offset, scope, opts)
    end
  end

  class ScopedMoment < OffsetTimeline # :nodoc:
    def initialize(moment, offset, scope)
      @scope = scope
      super moment, offset
    end

    def evaluate
      freeze { @scope.instance_eval(&self) }
    end

    private

    def freeze
      Timecop.freeze(offset) { yield }
    end
  end

  class Scheduler # :nodoc:
    include Enumerable

    def initialize(timeline, starting_offset, scope, opts = {})
      @timeline = timeline
      @starting_offset = starting_offset
      @scope = scope
      @opts = opts
    end

    private

    attr_reader :timeline, :starting_offset, :scope, :opts
  end
end
