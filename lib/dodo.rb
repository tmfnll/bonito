require "dodo/version"
require "securerandom"

module Dodo
  module TimeWarp
    class Window

      attr_reader :starting, :duration

      def initialize(duration, starting: 0, &block)
        @duration = duration
        @starting = starting
        @offset = starting
        @happenings = []
        @total_child_duration = 0

        instance_eval &block
      end

      def ending
        starting + duration
      end

      def over(duration, &block)
        self.class.new(duration, &block).tap do |window|
          self << window
        end
      end

      def now(&block)
        Moment.new(&block).tap { |moment|  self << moment }
      end

      def repeat(times: 1, &block)
        times.times { now &block }
      end

      def use(happening)
        self << happening
      end

      def schedule(offset)
        schedule = []

        schedule.concat [@happenings, distribution].transpose do |happening, dist_offset|
          offset += dist_offset
          happening.schedule(offset).tap { |_moments| offset += happening.duration}
        end

        offset = ending
        schedule
      end

      def << (happening)
        @total_child_duration += happening.duration
        raise Exception if @total_child_duration > duration
        @happenings << happening
      end

      private

      def distribution
       @happenings.map do |_h|
          SecureRandom.random_number (duration - @total_child_duration).to_i
       end.sort
      end
    end

    class Moment
      def initialize(&block)
        @block = block
        @starting = nil
      end

      def schedule(offset)
        @starting = offset
        [self]
      end

      def ending
        starting
      end

      def duration
        0
      end
    end
  end
end
