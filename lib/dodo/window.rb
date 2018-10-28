# frozen_string_literal: true

require 'dodo/moment'
require 'securerandom'
require 'timecop'

module Dodo
  class Window
    attr_reader :happenings, :duration, :total_child_duration

    def initialize(duration, &block)
      @duration = duration
      @happenings = []
      @total_child_duration = 0

      instance_eval(&block)
    end

    def over(duration, &block)
      self.class.new(duration, &block).tap { |window| self << window }
    end

    def please(&block)
      Moment.new(&block).tap { |moment| self << moment }
    end

    def repeat(times: 2, &block)
      Array.new(times) { please(&block) }
    end

    def enum(distribution, opts = {})
      WindowEnumerator.new self, distribution, opts
    end

    def scales?
      false
    end

    def <<(happening)
      tap do
        @total_child_duration += happening.duration
        raise Exception if @total_child_duration > duration

        @happenings << happening
      end
    end

    alias use <<
  end

  def self.over(duration, &block)
    Window.new duration, &block
  end

  def self.starting(start, with = {}, &block)
    window = module_eval &block
    runner = Runner.new with
    runner.call window, start, with
  end

  def self.ending(end_, with = {}, &block)
    window = module_eval &block
    start = end_ - window.duration
    runner = Runner.new with
    runner.call window, start, with
  end

  class WindowEnumerator
    include Enumerable
    include Scalable

    def initialize(window, parent_distribution = nil, opts = {})
      @window = window
      @starting_offset = parent_distribution&.next || 0
      @opts = opts
    end

    def each
      return to_enum(:each) unless block_given?

      distribution = distribute

      @window.happenings.each do |happening|
        happening.enum(distribution, @opts).map do |moment|
          yield moment
        end
      end
    end

    private

    def total_crammed_happenings
      @window.happenings.reduce(0) do |sum, happening|
        sum + (happening.scales? ? cram : 1)
      end
    end

    def distribute
      Array.new(total_crammed_happenings) do
        offset = SecureRandom.random_number((@window.duration - @window.total_child_duration).floor)
        offset *= stretch
        offset + @starting_offset
      end.sort.each
    end
  end
end
