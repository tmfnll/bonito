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
    window, starting:, context: Context.new,
    progress: ProgressLogger.new(Logger.new(STDOUT)), **opts
  )
    distribution = Distribution.new starting
    scheduler = window.scheduler(distribution, context, opts)
    scheduler = ProgressDecorator.new scheduler, progress
    runner = Runner.new scheduler, opts
    runner.call
  end

  class Context # :nodoc:
    def initialize(parent = nil)
      @parent = parent
    end

    def push
      Context.new self
    end

    protected

    attr_reader :parent

    private

    def method_missing(symbol, *args)
      return set symbol, args.fetch(0) if assignment? symbol

      get symbol
    rescue NoMethodError
      super
    end

    def respond_to_missing?(symbol, respond_to_private = false)
      return true if assignment? symbol

      get symbol
      true
    rescue NoMethodError
      super
    end

    # :reek:NilCheck
    def assignment?(symbol)
      !symbol.to_s.match(/\w+=/).nil?
    end

    def instance_var_for(symbol)
      :"@#{symbol.to_s.chomp('=')}"
    end

    def get(symbol)
      context = self
      instance_var = instance_var_for symbol
      while context
        if context.instance_variable_defined? instance_var
          return context.instance_variable_get instance_var
        end

        context = context.parent
      end
      raise NoMethodError
    end

    def set(attr, value)
      instance_variable_set instance_var_for(attr), value
    end
  end
end
