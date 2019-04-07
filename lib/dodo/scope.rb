module Dodo
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

    # :reek:BooleanParameter
    # Inherits interface from Object#respond_to_missing?
    def respond_to_missing?(symbol, respond_to_private = false)
      return true if assignment? symbol

      get symbol
      true
    rescue NoMethodError
      super
    end

    # :reek:NilCheck
    # String#match? Unavailable for Ruby 2.3
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
