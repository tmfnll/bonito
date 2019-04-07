# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Dodo::ScopedMoment do
  let(:moment) { build :moment }
  let(:offset) { 2.weeks.ago }
  let(:scope) { Dodo::Scope.new }
  let(:scopeual_moment) { described_class.new moment, offset, scope }

  describe '#evaluate' do
    subject { scopeual_moment.evaluate }

    it 'should evaluate the moment within the scope' do
      allow(scope).to receive(:instance_eval) do |&block|
        expect(block).to eq(moment)
      end
    end

    it 'should evaluate the moment within the scope at the offset' do
      allow(scope).to receive(:instance_eval) do |&_block|
        expect(Time.now).to eq offset
      end
    end
  end
end
