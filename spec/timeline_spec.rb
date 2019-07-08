# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Bonito::ScopedMoment do
  let(:moment) { build :moment }
  let(:offset) { 2.weeks.ago }
  let(:scope) { Bonito::Scope.new }
  let(:scoped_moment) { described_class.new moment, offset, scope }

  describe '#evaluate' do
    subject { scoped_moment.evaluate }

    it 'should evaluate the moment within the scope' do
      expect(scope).to receive(:instance_eval) do |&block|
        expect(block).to eq(moment.to_proc)
      end
      subject
    end

    it 'should evaluate the moment within the scope at the offset' do
      expect(scope).to receive(:instance_eval) do |&_block|
        expect(Time.now).to eq offset
      end
      subject
    end
  end
end
