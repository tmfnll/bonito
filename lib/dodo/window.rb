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
      self.class.new(duration, self, &block).tap do |window|
        self << window
      end
    end

    def please(&block)
      Moment.new(&block).tap { |moment| self << moment }
    end

    def repeat(times:, over: unused_duration, &block)
      repeated_block = proc { times.times { instance_eval(&block) } }
      over(over, &repeated_block)
    end

    def simultaneously(over:, &block)
      Container.new.tap do |container|
        container.also(after: 0, over: over, &block)
        self << container
      end
    end

    def scheduler(distribution, context, opts = {}) # :nodoc:
      WindowScheduler.new self, distribution, context, opts
    end

    def crammed(*) # :nodoc:
      [self]
    end

    def <<(happening)
      tap do
        @total_child_duration += happening.duration
        if @total_child_duration > duration
          raise WindowDurationExceeded, "#{@total_child_duration} > #{duration}"
        end

        @happenings << happening
      end
    end

    alias use <<
  end

  class DodoException < StandardError
  end

  class WindowDurationExceeded < DodoException
  end

  def self.over(duration, &block)
    Window.new duration, &block
  end

  class WindowScheduler # :nodoc:
    include Enumerable

    def initialize(window, parent_distribution, parent_context, opts = {})
      @window = window
      @starting_offset = parent_distribution.next
      @context = parent_context.push
      @opts = opts
    end

    def each
      return to_enum(:each) unless block_given?
      distribution = Distribution.new(
        @starting_offset, @window.unused_duration, crammed_happenings.size,
        stretch: stretch
      )

      @window.happenings.each do |happening|
        happening.scheduler(distribution, @context, @opts).map do |moment|
          yield moment
        end
        distribution.consume happening.duration
      end
    end

    def cram
      @cram ||= @opts.fetch(:scale) {  @opts.fetch(:cram) { 1 } }.ceil
    end

    def stretch
      @stretch ||= @opts.fetch(:scale) { @opts.fetch(:stretch) { 1 } }
    end

    private

    def crammed_happenings
      @crammed_happenings ||= @window.happenings.map do |happening|
        happening.crammed(factor: cram)
      end.flatten
    end
  end

  class Distribution

    def initialize(start, interval = 0, count = 1, stretch: 1)
      @start = start
      @interval = interval
      @count = count
      @stretch = stretch
      @distribution = generate
      @consumed = 0
      @current = 0
    end

    attr_reader :count

    def next
      if @current == @count
        raise StopIteration
      end
      offset = @start + (@stretch * (@distribution[@current] + @consumed))
      @current += 1
      offset
    end

    def consume(duration)
      @consumed += duration
    end

    private

    def generate
     Array.new(@count) do
       @interval > 0 ? SecureRandom.random_number(@interval) : 0
     end.sort
    end

  end
end
