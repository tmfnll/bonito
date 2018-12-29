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

    def crammed(factor:)
      Array.new(factor) { self }
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

    def cram
      @cram ||= @opts.fetch(:scale) { @opts.fetch(:cram) { 1 } }.ceil
    end

    def each
      return to_enum(:each) unless block_given?

      cram.times do
        yield ContextualMoment.new(@moment, @distribution.next, @context)
      end
    end
  end
end
