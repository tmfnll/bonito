# frozen_string_literal: true

module Dodo
  class Accessor # :nodoc:
    def initialize(scope, symbol)
      @scope = scope
      @symbol = symbol
    end

    def access(*args)
      assignment? ? set(*args) : get
    end

    # :reek:NilCheck
    # String#match? Unavailable for Ruby 2.3
    def assignment?
      !@symbol.to_s.match(/\w+=/).nil?
    end

    private

    def get
      scope = @scope
      while scope
        if scope.instance_variable_defined? instance_var
          return scope.instance_variable_get instance_var
        end

        scope = scope.parent
      end
      raise NoMethodError
    end

    def set(value)
      @scope.instance_variable_set instance_var, value
    end

    def instance_var
      :"@#{@symbol.to_s.chomp('=')}"
    end
  end

  class Scope # :nodoc:
    def initialize(parent = nil)
      @parent = parent
    end

    def push
      self.class.new self
    end

    protected

    attr_reader :parent

    private

    def method_missing(symbol, *args)
      Accessor.new(self, symbol).access(*args)
    rescue NoMethodError
      super
    end

    # :reek:BooleanParameter
    # Inherits interface from Object#respond_to_missing?
    def respond_to_missing?(symbol, respond_to_private = false)
      accessor = Accessor.new(self, symbol)
      return true if accessor.assignment?

      accessor.access
      true
    rescue NoMethodError
      super
    end
  end
end
