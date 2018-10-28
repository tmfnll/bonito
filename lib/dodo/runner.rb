# frozen_string_literal: true

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

    def call(window, start, context = nil, enum_opts = {})
      Process.daemon if daemonise?
      context = Context.new if context.nil?

      window.enum(nil, enum_opts).each do |moment|
        occurring_at(start + moment.offset) do
          context.instance_eval(&moment.block)
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

  class Context; end
end
