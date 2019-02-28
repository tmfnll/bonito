# frozen_string_literal: true

require 'dodo/happening'

module Dodo
  class Moment < Happening # :nodoc:
    def initialize(&block)
      @block = block
      super 0
    end

    def scheduler(distribution, context, opts = {})
      MomentScheduler.new self, distribution, context, opts
    end

    def to_proc
      @block
    end
  end

  class MomentScheduler # :nodoc:
    include Enumerable

    def initialize(moment, distribution, context, opts = {})
      @moment = moment
      @distribution = distribution
      @context = context
      @opts = opts
    end

    def each
      return to_enum(:each) unless block_given?

      yield ContextualMoment.new(@moment, @distribution.next, @context)
    end
  end
end
