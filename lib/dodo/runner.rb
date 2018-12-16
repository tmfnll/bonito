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

    def call(window, start, context = nil, opts = {})
      Process.daemon if daemonise?
      context = Context.new if context.nil?
      window.enum(start, opts).each do |moment|
        occurring_at(moment.offset) do
          context.instance_eval(&moment.block)
        end
        @progress += 1
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

  class Context
    def initialize(parent=nil)
      @parent = parent
    end
    
    def push
      Context.new self
    end

    protected

    attr_reader :parent

    private

    def method_missing(symbol, *args)
      if is_assignment? symbol
        set symbol, args.fetch(0)
      else
        get symbol
      end
    rescue NoMethodError
      super
    end

    def is_assignment?(symbol)
      symbol.to_s.match? /\w+=/
    end

    def instance_var_for(symbol)
      :"@#{symbol.to_s.delete_suffix("=")}"
    end

    def get(symbol)
      context = self
      instance_var = instance_var_for symbol
      until context.nil?
        if context.instance_variable_defined? instance_var
          return context.instance_variable_get instance_var
        else
          context = context.parent
        end
      end
      raise NoMethodError
    end

    def set(attr, value)
      instance_variable_set instance_var_for(attr), value
    end
  end
end
