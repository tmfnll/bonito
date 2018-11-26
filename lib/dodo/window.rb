# frozen_string_literal: true

require 'dodo/happening'
require 'dodo/moment'
require 'securerandom'
require 'timecop'

module Dodo
  class Window < Happening
    attr_reader :happenings

    def initialize(duration, parent = nil, &block)
      @parent = parent
      @happenings = []
      @total_child_duration = 0
      super duration
      instance_eval(&block)
    end

    def unused_duration
      duration - @total_child_duration
    end

    def over(duration, &block)
      self.class.new(duration, self, &block).tap { |window| self << window }
    end

    def please(&block)
      Moment.new(&block).tap { |moment| self << moment }
    end

    def repeat(times: 2, over: duration, &block)
      return if times.zero?

      duration_per_window = (over / times).floor
      Array.new(times) { over(duration_per_window, &block) }
    end

    def simultaneously(over:, &block)
      Container.new(over: over, &block).tap { |container| self << container }
    end

    def enum(starting_offset)
      WindowEnumerator.new self, starting_offset
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

  class WindowEnumerator
    include Enumerable

    def initialize(window, starting_offset)
      @window = window
      @starting_offset = starting_offset
    end

    def each
      return to_enum(:each) unless block_given?

      @window.happenings.each do |happening|
        happening.enum(distribution.next).map do |moment|
          yield moment
        end
      end
    end

    private

    # This is a bit too mad now
    def distribution
      @distribution ||= begin
        offsets = Array.new(@window.happenings.size) do
          SecureRandom.random_number(@window.unused_duration)
        end.sort
        current_offset = 0
        [@window.happenings, offsets].transpose.map do |happening, offset|
          actual_offset = @starting_offset + current_offset + offset
          current_offset += happening.duration
          actual_offset
        end
      end.each
    end
  end
end
