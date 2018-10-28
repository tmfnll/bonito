module Dodo
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

      window.enum(nil, opts).each do |moment|
        occurring_at(start + moment.offset) { moment.call }
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