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
  describe '#call' do
    subject { moment.call }
    it 'should call the underlying block' do
      expect(block).to receive(:call).with no_args
      subject
    end
  end
  describe '#enum' do
    let(:distribution) { double }
    let(:opts) { double }
    subject { moment.enum distribution, opts }
    context 'with opts' do
      it 'should create a new MomentEnumerator with opts included' do
        expect(Dodo::MomentEnumerator).to receive(:new).with(moment, distribution, opts)
        subject
      end
    end
    context 'without opts' do
      subject { moment.enum distribution }
      it 'should create a new MomentEnumerator with an empty ahs as opts' do
        expect(Dodo::MomentEnumerator).to receive(:new).with(moment, distribution, {})
        subject
      end
    end
  end
  describe '#scales?' do
    subject { moment.scales? }
    it 'returns true' do
      expect(subject).to be true
    end
  end
end
