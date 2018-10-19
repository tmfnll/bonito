# frozen_string_literal: true

require 'dodo/version'
require 'securerandom'
require 'timecop'

module Dodo
  class Window
    attr_reader :happenings, :duration, :total_child_duration

    def initialize(duration, &block)
      @duration = duration
      @happenings = []
      @moments = []
      @windows = []
      @total_child_duration = 0

      instance_eval(&block)
    end

    def total_moments
      @moments.size
    end

    def total_windows
      @windows.size
    end

    def over(duration, &block)
      self.class.new(duration, &block).tap { |window| push_window window }
    end

    def please(&block)
      Moment.new(&block).tap { |moment| push_moment moment }
    end

    def repeat(times: 2, &block)
      times.times.map { please &block }
    end

    def push_moment(moment)
      @moments << moment
      push moment
    end

    def push_window(window)
      @windows << window
      push window
    end

    alias :use :push_window

    def enum(distribution, opts = {})
      WindowEnumerator.new self, distribution, opts
    end

    private

    def push(happening)
      tap do
        @total_child_duration += happening.duration
        raise Exception if @total_child_duration > duration

        @happenings << happening
      end
    end
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

  module Scalable
    def cram
      @cram ||= @opts.fetch(:scale) {  @opts.fetch(:cram) { 1 } }.ceil
    end

    def stretch
      @stretch ||= @opts.fetch(:scale) {  @opts.fetch(:stretch) { 1 } }
    end
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
        happening.enum(distribution, @opts).map do |offset, moment|
          yield offset, moment
        end
      end
    end

    private

    def total_crammed_happenings
      (@window.total_moments * cram) + @window.total_windows
    end

    def distribute
      total_crammed_happenings.times.map do
        offset = SecureRandom.random_number((@window.duration - @window.total_child_duration).floor)
        offset *= stretch
        offset + @starting_offset
      end.sort.each
    end

  end

  class Moment

    attr_reader :duration

    def initialize(&block)
      @block = block
      @duration = 0
    end

    def call
      @block.call
    end

    def enum(distribution, opts = {})
      MomentEnumerator.new self, distribution, opts
    end
  end

  class MomentEnumerator
    include Enumerable
    include Scalable

    def initialize(moment, distribution, opts)
      @moment = moment
      @distribution = distribution
      @opts = opts
    end

    def each
      return to_enum(:each) unless block_given?

      cram.times { yield @distribution.next, @moment }
    end
  end

  class Runner
    def initialize(opts = {})
      @opts = opts
    end

    def live?
      @opts.fetch(:live) { false }
    end

    def daemonize?
      @opts.fetch(:daemonize) { false }
    end

    def call(window, start, opts = {})
      Process.daemon if daemonize?

      window.enum([0].each, opts).each do |offset, moment|
        occurring_at(offset) { moment.call }
      end
    end

    private

    def occurring_at(instant)
      if live? && instant > Time.now
        nap_time = [instant - Time.now, 0].max
        sleep nap_time
      end
      Timecop.freeze(instant) { yield }
    end
  end
end
