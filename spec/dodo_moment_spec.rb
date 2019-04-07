# frozen_string_literal: true

RSpec.describe Dodo::Moment do
  let(:block) { proc { p 'some block' } }
  let(:moment) { Dodo::Moment.new(&block) }
  let(:scope) { Dodo::Scope.new }
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
  describe '#to_proc' do
    subject { moment.to_proc }
    it 'should return block' do
      expect(subject).to eq block
    end
  end
  describe '#scheduler' do
    let(:starting_offset) { rand(10).days }
    let(:opts) { double }
    subject { moment.scheduler starting_offset, scope, opts }
    context 'with opts' do
      it 'should create a new MomentScheduler with opts included' do
        expect(Dodo::MomentScheduler).to receive(:new).with(
          moment, starting_offset, scope, opts
        )
        subject
      end
    end
    context 'without opts' do
      subject { moment.scheduler starting_offset, scope }
      it 'should create a new MomentScheduler with an empty ahs as opts' do
        expect(Dodo::MomentScheduler).to receive(:new).with(
          moment, starting_offset, scope, {}
        )
        subject
      end
    end
  end
end
