# frozen_string_literal: true

require 'rspec'
RSpec.describe Dodo::MomentScheduler do
  let(:block) { -> { true } }
  let(:starting_offset) { rand 100 }
  let(:stretch) { 2 }
  let(:opts) { { stretch: stretch } }
  let(:moment) { Dodo::Moment.new(&block) }
  let(:scope) { Dodo::Scope.new }
  let(:scheduler) do
    Dodo::MomentScheduler.new moment, starting_offset, scope, opts
  end

  describe '#initialize' do
    subject { scheduler }
    context 'with distribution and opts' do
      it 'should initialise successfully' do
        subject
      end
    end
  end
  describe '#each' do
    context 'with a block' do
      subject { scheduler }
      it 'should yield exactly once' do
        expect { |b| subject.each(&b) }.to yield_control.once
      end
      it 'should yield the (decorated) moment once' do
        expect { |b| subject.each(&b) }.to yield_with_args(
          have_attributes(__getobj__: moment)
        )
      end
      it 'should offset the moment by the starting offset' do
        expect { |b| subject.each(&b) }.to yield_with_args(
          have_attributes(offset: starting_offset)
        )
      end
    end
  end
end
