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

  class WindowEnumerator
    include Enumerable
    include Scalable

    def initialize(window, parent_distribution, opts = {})
      @window = window
      @parent_distribution = parent_distribution
      @opts = opts
    end

    def each
      return to_enum(:each) unless block_given?

      @window.happenings.each do |happening|
        happening.enum(distribution, @opts).map do |moment|
          yield moment
        end
      end
    end

    private

    def crammed_happenings
      @window.happenings do |happening|
        (happening.scales? ? cram : 1).times { yield happening }
      end
    end

    def starting_offset
      @starting_offset ||= @parent_distribution.next
    end

    # This is a bit too mad now
    def distribution
      accumulation = 0
      @distribution ||= crammed_happenings.map do |happening|
        offset = SecureRandom.random_number @window.unused_duration
        offset += accumulation
        offset *= stretch
        accumulation += happening.duration
        offset + starting_offset
      end.sort.each
    end
  end
end
