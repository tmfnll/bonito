require 'rspec'
require 'active_support/core_ext/numeric/time'

RSpec.describe Dodo::ContainerEnumerator do
  let(:duration) { 2.weeks }
  let(:opts) { { scale: 2, cram: 3 } }
  let(:moments) { build_list :moment, 5 }
  let(:offset_moments) do
    moments.map do |moment|
      Dodo::OffsetHappening.new(moment, rand(10).days)
    end.sort
  end

  let(:more_moments) { build_list :moment, 5 }
  let(:more_offset_moments) do
    more_moments.map do |moment|
      Dodo::OffsetHappening.new(moment, rand(10).days)
    end.sort
  end

  let(:sorted_offset_moments) { (offset_moments + more_offset_moments).sort }

  let(:window) { build :window }
  let(:another_window) { build :window }

  let(:window_enumerator) { Dodo::WindowEnumerator.new window }
  let(:another_window_enumerator) { Dodo::WindowEnumerator.new another_window }

  before do
    allow(window_enumerator).to receive(:each).and_return(offset_moments.each)
    allow(another_window_enumerator).to receive(:each).and_return(more_offset_moments.each)

    allow(window).to receive(:enum).and_return(window_enumerator)
    allow(another_window).to receive(:enum).and_return(another_window_enumerator)
  end

  let(:container) do
    allow(Dodo::Window).to receive(:new).and_return(window, another_window)
    container = Dodo::Container.new(over: window.duration) {}
    container.also after: 3.days, over: another_window.duration {}
    container
  end

  let(:container_enumerator) { Dodo::ContainerEnumerator.new container, opts }

  describe '#each' do
    subject { container_enumerator.each }

    context 'without a block provided' do
      it 'should return an enumerator' do
        expect(subject).to be_an Enumerator
      end
    end

    context 'without any opts' do
      it 'should provide any opts to the underlying window enumerators' do
        expect(window).to receive(:enum).with(nil, opts)
        subject
      end

      it 'should yield the expected number of moments' do
        expect(subject.to_a.size).to eq sorted_offset_moments.size
      end
      it 'should yield all offset moments' do
        expect(Set[*subject]).to eq Set[*sorted_offset_moments]
      end
      it 'should yield offset moments in chronological order' do
        expect(subject.to_a.map(&:offset)).to eq sorted_offset_moments.map(&:offset)
      end
      it 'should not store more than 1 moment per window in the heap' do
        subject.each do
          expect(
            container_enumerator.instance_variable_get(:@moment_heap).size
          ).to be <= 2
        end
      end
    end
  end
end
