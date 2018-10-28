require 'timecop'
module Dodo
  class Runner
    def initialize(opts = {})
      @opts = opts
    end

    def live?
      @opts.fetch(:live) { false }
    end

    def daemonise?
      @opts.fetch(:daemonise) { false }
    end

    def call(window, start, enum_opts = {})
      Process.daemon if daemonise?

      window.enum(nil, enum_opts).each do |moment|
        occurring_at(start + moment.offset) { moment.call }
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
end