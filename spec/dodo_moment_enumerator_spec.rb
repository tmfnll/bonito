# frozen_string_literal: true

require 'rspec'
RSpec.describe Dodo::MomentEnumerator do
  let(:block) { -> { true } }
  let(:starting_offset) { rand(10).days }
  let(:cram) { 2 }
  let(:stretch) { 2 }
  let(:opts) { { cram: cram, stretch: stretch } }
  let(:moment) { Dodo::Moment.new &block }
  let(:enum) { Dodo::MomentEnumerator.new moment, starting_offset, opts }

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
        expect { |b| subject.each(&b) }.to yield_control.once
      end
      it 'should yield the (decorated) moment cram times' do
        expect { |b| subject.each(&b) }.to yield_with_args(
          have_attributes(__getobj__: moment, offset: starting_offset )
        )
      end
    end
  end
end
