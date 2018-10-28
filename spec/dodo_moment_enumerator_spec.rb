# frozen_string_literal: true

require 'rspec'
RSpec.describe Dodo::MomentEnumerator do
  let(:block) { -> { true } }
  let(:distribution) { double }
  let(:cram) { 2 }
  let(:stretch) { 2 }
  let(:opts) { { cram: cram, stretch: stretch } }
  let(:moment) { Dodo::Moment.new &block }
  let(:enum) { Dodo::MomentEnumerator.new moment, distribution, opts }

  before do
    allow(distribution).to receive(:next).and_return(*(1..cram))
  end

  describe '#initialize' do
    subject { enum }
    context 'with distribution and opts' do
      it 'should initialise successfully' do
        subject
      end
    end
  end
  describe '#each' do
    context 'without a block' do
      subject { enum.each }
      it 'should return an Enumerator' do
        expect(subject).to be_an Enumerator
      end
    end
    context 'with a block' do
      subject { enum }
      it 'should yield according to the cram factor' do
        expect { |b| subject.each(&b) }.to yield_control.exactly(cram).times
      end
      it 'should yield the (decorated) moment cram times' do
        expect { |b| subject.each(&b) }.to yield_successive_args(
          *Array.new(cram) { have_attributes __getobj__: moment }
        )
      end
      it 'should offset these moments according to the distribution' do
        expect { |b| subject.each(&b) }.to yield_successive_args(
          *(1..cram).map { |offset| have_attributes offset: offset }
        )
      end
    end
  end
end
