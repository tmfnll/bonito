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

    def crammed(*)
      [self]
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
      @distribution = Distribution.new window, starting_offset
    end

    def each
      return to_enum(:each) unless block_given?

      @distribution.each do |happening|
        happening.enum(happening.offset).map do |moment|
          yield moment
        end
      end
    end
  end

  class Distribution
    include Enumerable

    def initialize(window, starting_offset, scale_opts = {})
      @window = window
      @starting_offset = starting_offset
      @scale_opts = scale_opts
    end

    def each
      happenings_with_offsets do |happening, offset|
        yield OffsetHappening.new happening, offset
      end
    end

    def cram
      @cram ||= @scale_opts.fetch(:scale) {  @scale_opts.fetch(:cram) { 1 } }.ceil
    end

    def stretch
      @stretch ||= @scale_opts.fetch(:scale) { @scale_opts.fetch(:stretch) { 1 } }
    end

    private

    def crammed_happenings
      @crammed_happenings ||= @window.happenings.map do |happening|
        happening.crammed(factor: cram)
      end.flatten
    end

    def offsets
      @offsets ||= crammed_happenings.map do
        SecureRandom.random_number(@window.unused_duration)
      end.sort
    end

    def happenings_with_offsets
      consumed_duration = 0
      crammed_happenings.zip(offsets).each do |happening, offset|
        yield happening, @starting_offset + (stretch * (offset + consumed_duration))
        consumed_duration += happening.duration
      end
    end
  end
end
