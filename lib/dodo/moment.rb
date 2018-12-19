# frozen_string_literal: true

require 'dodo/happening'
require 'dodo/scalable'

module Dodo
  class Moment < Happening

    def initialize(&block)
      @block = block
      super 0
    end

    def enum(distribution, context, opts = {})
      MomentEnumerator.new self, distribution, context, opts
    end

    def to_proc
      @block
    end

    def crammed(factor:)
      Array.new(factor) { self }
    end
  end

  class MomentEnumerator
    include Enumerable

    def initialize(moment, distribution, context, opts = {})
      @moment = moment
      @distribution = distribution
      @context = context
      @opts = opts
    end

    def cram
      @cram ||= @opts.fetch(:scale) {  @opts.fetch(:cram) { 1 } }.ceil
    end

    def each
      return to_enum(:each) unless block_given?
      cram.times { yield ContextualMoment.new(@moment, @distribution.next, @context) }
    end
  end
end
