# frozen_string_literal: true

require 'ruby-progressbar'
module Dodo
  module ProgressCounter # :nodoc:
    attr_reader :total
    attr_reader :current

    class Unknown # :nodoc:
      include Singleton
      def to_s
        '-'
      end
    end

    module ClassMethods # :nodoc:
      def factory(*args)
        ->(total: nil, prefix: nil) { new(*args, total: total, prefix: prefix) }
      end
    end

    def self.included(base)
      base.extend ClassMethods
    end

    def setup(total: ProgressCounter::Unknown.instance, prefix: nil)
      @total = total
      @prefix = prefix
      @current = 0
    end

    def increment(change)
      @current += change
      on_increment change
      self
    end

    def to_s
      "#{prefix} #{current} / #{total}"
    end

    private

    def prefix
      @prefix ||= "#{self.class}{#{object_id}} : Progress Made :"
    end
  end

  class ProgressLogger # :nodoc:
    include ProgressCounter

    def initialize(logger = Logger.new(STDOUT), **opts)
      @logger = logger
      setup opts
    end

    def on_increment(_increment)
      @logger.info to_s
    end
  end

  class ProgressBar # :nodoc:
    include ProgressCounter

    def initialize(**opts)
      @bar = ::ProgressBar.create opts
      @bar.total = opts[:total]
      setup opts
    end

    def on_increment(increment)
      increment.times { @bar.increment }
    end
  end

  class ProgressDecorator < SimpleDelegator # :nodoc:
    def initialize(enumerable, progress)
      @progress = progress
      super enumerable
    end

    def each
      return to_enum(:each) unless block_given?

      __getobj__.each do |item|
        yield item
        @progress.increment 1
      end
    end
  end
end
