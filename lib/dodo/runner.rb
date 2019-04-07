# frozen_string_literal: true

require 'timecop'
module Dodo # :nodoc:
  class Runner # :nodoc:
    def initialize(enumerable, opts = {})
      @enumerable = enumerable
      @opts = opts
    end

    def live?
      @opts.fetch(:live) { false }
    end

    def daemonise?
      @opts.fetch(:daemonise) { false }
    end

    def call
      Process.daemon if daemonise?
      @enumerable.each do |moment|
        maybe_sleep moment
        moment.evaluate
      end
    end

    private

    def maybe_sleep(moment)
      return unless live? && (nap_time = moment.offset - Time.now).positive?

      sleep nap_time
    end
  end

  def self.run(
    serial, starting:, context: Context.new,
    progress_factory: ProgressLogger.factory, **opts
  )
    scheduler = serial.scheduler(starting, context, opts)
    progress = progress_factory.call total: scheduler.count
    scheduler = ProgressDecorator.new scheduler, progress
    Runner.new(scheduler, opts).call
  end
end
