# frozen_string_literal: true

require 'timecop'
module Dodo
  class Runner
    def initialize(opts = {})
      @opts = opts
      @progress = opts.fetch(:progress) { 0 }
    end

    def live?
      @opts.fetch(:live) { false }
    end

    def daemonise?
      @opts.fetch(:daemonise) { false }
    end

    def call(window, start, context = nil)
      Process.daemon if daemonise?
      context = Context.new if context.nil?
      window.enum(0).each do |moment|
        occurring_at(start + moment.offset) do
          context.instance_eval(&moment.block)
          @progress += 1
        end
      end
    end

    private

    def occurring_at(instant)
      if live? && instant > Time.now
        nap_time = [instant - Time.now, 0].max
        sleep nap_time
        yield
      else
        Timecop.freeze(instant) { yield }
      end
    end
  end

  def self.starting(start, with = {}, &block)
    window = module_eval(&block)
    runner = Runner.new with
    runner.call window, start, nil, with
  end

  def self.ending(end_, with = {}, &block)
    window = module_eval(&block)
    start = end_ - window.duration
    runner = Runner.new with
    runner.call window, start, nil, with
  end

  class Context; end
end
