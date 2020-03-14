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
      expect(moment.to_proc).to receive(:call).with(scope)
      subject
    end

    it 'should evaluate the moment within the scope at the offset' do
      expect(moment.to_proc).to receive(:call) do |&_block|
        expect(Time.now).to eq offset
      end
      subject
    end
  end
end
