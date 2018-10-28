# frozen_string_literal: true

require 'dodo/scalable'

module Dodo
  class Moment
    attr_reader :duration, :block

    def initialize(&block)
      @block = block
      @duration = 0
    end

    def enum(distribution, opts = {})
      MomentEnumerator.new self, distribution, opts
    end

    def scales?
      true
    end
    end

  class MomentDecorator < SimpleDelegator
    attr_reader :offset
    def initialize(moment, offset)
      @offset = offset
      super moment
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
        dec = MomentDecorator.new(@moment, @distribution.next)
        yield dec
      end
    end
  end
end
