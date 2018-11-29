# frozen_string_literal: true

RSpec.describe Dodo::Moment do
  let(:block) { proc { p 'some block' } }
  let(:moment) { Dodo::Moment.new &block }
  describe '#initialize' do
    subject { moment }
    context 'when passed a block' do
      it 'should initialize successfully' do
        subject
      end
    end
  end
  describe '#duration' do
    subject { moment.duration }
    it 'should return 0' do
      expect(subject).to eq 0
    end
  end
  describe '#block' do
    subject { moment.block }
    it 'should return block' do
      expect(subject).to eq block
    end
  end
  describe '#enum' do
    let(:starting_offset) { rand(10).days }
    let(:opts) { double }
    subject { moment.enum starting_offset, opts }
    context 'with opts' do
      it 'should create a new MomentEnumerator with opts included' do
        expect(Dodo::MomentEnumerator).to receive(:new).with(
          moment, starting_offset, opts
        )
        subject
      end
    end
    context 'without opts' do
      subject { moment.enum starting_offset }
      it 'should create a new MomentEnumerator with an empty ahs as opts' do
        expect(Dodo::MomentEnumerator).to receive(:new).with(
          moment, starting_offset, {}
        )
        subject
      end
    end
  end
end
