# frozen_string_literal: true
require 'dodo/happening'
require 'dodo/scalable'

module Dodo
  class Moment < Happening
    attr_reader :block

    def initialize(&block)
      @block = block
      super 0
    end

    def enum(distribution, opts = {})
      MomentEnumerator.new self, distribution, opts
    end

    def scales?
      true
    end
    end

  class OffsetHappening < SimpleDelegator
    attr_reader :offset
    def initialize(moment, offset)
      @offset = offset
      super moment
    end

    def ==(other)
      offset == other.offset && __getobj__ == other.__getobj__
    end
  end

  class MomentEnumerator
    include Enumerable
    include Scalable

    def initialize(moment, distribution, opts)
      @moment = moment
      @distribution = distribution
      @opts = opts
    end

    def each
      return to_enum(:each) unless block_given?

      cram.times do
        dec = OffsetHappening.new(@moment, @distribution.next)
        yield dec
      end
    end
  end
end
