# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Dodo::ContextualMoment do
  let(:moment) { build :moment }
  let(:offset) { 2.weeks.ago }
  let(:context) { Dodo::Context.new }
  let(:contextual_moment) { described_class.new moment, offset, context }

  describe '#evaluate' do
    subject { contextual_moment.evaluate }

    it 'should evaluate the moment within the context' do
      allow(context).to receive(:instance_eval) do |&block|
        expect(block).to eq(moment)
      end
    end

    it 'should evaluate the moment within the context at the offset' do
      allow(context).to receive(:instance_eval) do |&_block|
        expect(Time.now).to eq offset
      end
    end
  end
end
