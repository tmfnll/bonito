# frozen_string_literal: true

require 'timecop'
module Dodo
  class Runner
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
      if live? && ((nap_time = moment.offset - Time.now) > 0)
        sleep nap_time
      end
    end
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
      !!symbol.to_s.match(/\w+=/)
    end

    def instance_var_for(symbol)
      :"@#{symbol.to_s.chomp("=")}"
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
