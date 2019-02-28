# frozen_string_literal: true

require 'rspec'
RSpec.describe Dodo::MomentScheduler do
  let(:block) { -> { true } }
  let(:distribution) { double }
  let(:stretch) { 2 }
  let(:opts) { { stretch: stretch } }
  let(:moment) { Dodo::Moment.new(&block) }
  let(:context) { Dodo::Context.new }
  let(:scheduler) do
    Dodo::MomentScheduler.new moment, distribution, context, opts
  end
  let(:dist_next) { rand 10 }

  before do
    allow(distribution).to receive(:next).and_return(dist_next)
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
    context 'without a block' do
      subject { scheduler.each }
      it 'should return an Enumerator' do
        expect(subject).to be_an Enumerator
      end
    end
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
      it 'should offset these moments according to the distribution' do
        expect { |b| subject.each(&b) }.to yield_with_args(
          have_attributes(offset: dist_next)
        )
      end
    end
  end
end
