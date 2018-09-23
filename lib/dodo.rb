# frozen_string_literal: true

require 'dodo/version'
require 'securerandom'
require 'timecop'

module Dodo
  class Window
    attr_reader :duration

    def initialize(duration, &block)
      @duration = duration
      @happenings = []
      @total_child_duration = 0

      instance_eval(&block)
    end

    def over(duration, &block)
      self.class.new(duration, &block).tap do |window|
        self << window
      end
    end

    def please(&block)
      Moment.new(&block).tap { |moment| self << moment }
    end

    def repeat(times: 2, &block)
      times.times.map { please &block }
    end

    def eval(starting:)
      [@happenings, distribution].transpose.each do |happening, offset|
        happening.eval(starting + offset)
      end

      starting + duration
    end

    def <<(happening)
      tap do
        @total_child_duration += happening.duration
        raise Exception if @total_child_duration > duration

        @happenings << happening
      end
    end

    alias use <<

    private

    def distribution
      @happenings.size.times.map do
        SecureRandom.random_number (duration - @total_child_duration).to_i
      end.sort
    end
  end

  def over(duration, &block)
    Window.new duration, &block
  end

  def starting(start)
    window = yield
    window.eval starting: start
  end

  def ending(end_)
    window = yield
    start = end_ - window.duration
    window.eval starting: start
  end

  class Moment
    def initialize(&block)
      @block = block
    end

    def eval(starting:)
      Timecop.freeze offset { @block.call }
      starting + duration
    end

    def duration
      0
    end
  end
end
