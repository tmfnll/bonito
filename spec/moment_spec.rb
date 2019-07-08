# frozen_string_literal: true

RSpec.describe Bonito::Moment do
  let(:block) { proc { p 'some block' } }
  let(:moment) { Bonito::Moment.new(&block) }
  let(:scope) { Bonito::Scope.new }
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
    let(:timeline) { moment }
    it_behaves_like 'a moment scheduler'
  end
end
