require "dodo/version"
require "securerandom"
require "timecop"

module Dodo
  module TimeWarp
    class Window

      attr_reader :start, :duration

      def initialize(duration, &block)
        @duration = duration
        @happenings = []
        @total_child_duration = 0

        instance_eval &block
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

      def eval(starting:)
        total_offset = starting

        [@happenings, distribution].transpose do |happening, offset|
          total_offset += happening.eval(total_offset + offset)
        end

        starting + duration
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

      def eval(starting:)
        Timecop.freeze offset { @block.call }
        starting # + duration (== 0)
      end

      def duration
        0
      end
    end
  end
end
