require 'rspec'
require 'active_support/core_ext/numeric/time'

RSpec.describe Dodo::ContainerEnumerator do
  let(:duration) { 2.weeks }
  let(:opts) { {} }
  let(:after) { 2.days }

  let(:starting_offset) { 0.seconds }

  let(:moments) { build_list :moment, 5 }
  let(:offset_moments) do
    moments.map do |moment|
      Dodo::OffsetHappening.new(moment, rand(10).days)
    end.sort
  end

  let(:more_moments) { build_list :moment, 5 }
  let(:more_offset_moments) do
    more_moments.map do |moment|
      Dodo::OffsetHappening.new(moment, rand(7).days)
    end.sort
  end

  let(:window) do
    window = build :window
    moments.each { |moment| window << moment }
    window
  end
  let(:another_window) do
    window = build :window
    more_moments.each { |moment| window << moment }
    window
  end

  let(:distribution) { moments.map { rand(10).days }.sort.each }
  let(:another_distribution) { more_moments.map { rand(7).days + after }.sort.each }

  let(:window_enumerator) do
    enum = window.enum([starting_offset].each, opts)
    allow(enum).to receive(:distribution).and_return distribution
    enum
  end

  let(:another_window_enumerator) do
    enum = another_window.enum([starting_offset + after].each, opts)
    allow(enum).to receive(:distribution).and_return another_distribution
    enum
  end

  before do
    allow(window).to receive(:enum).and_return(window_enumerator)
    allow(another_window).to receive(:enum).and_return(another_window_enumerator)
  end

  let(:container) do
    allow(Dodo::Window).to receive(:new).and_return(window, another_window)
    container = Dodo::Container.new(over: window.duration) {}
    container.also after: after, over: another_window.duration {}
    container
  end

  let(:container_enumerator) do
    Dodo::ContainerEnumerator.new container, [starting_offset].each, opts
  end

  describe '#each' do
    subject { container_enumerator.each }

    context 'without a block provided' do
      it 'should return an enumerator' do
        expect(subject).to be_an Enumerator
      end
    end

    context 'without opts' do
      let(:some_expected_moments) do
        [[*distribution], moments].transpose.map do |offset, moment|
          Dodo::OffsetHappening.new moment, (starting_offset + offset)
        end
      end
      let(:more_expected_moments) do
        [[*another_distribution], more_moments].transpose.map do |offset, moment|
          Dodo::OffsetHappening.new moment, (starting_offset + offset)
        end
      end

      let(:all_expected_moments) do
        (some_expected_moments + more_expected_moments).sort
      end

      it 'should provide any opts to the underlying window enumerators' do
        expect(window).to receive(:enum).with(
          satisfy { |dist| dist.next == starting_offset }, opts
        )
        subject
      end

      it 'should yield the expected number of moments' do
        expect(subject.to_a.size).to eq all_expected_moments.size
      end
      it 'should yield all moments' do
        expected = Set[*all_expected_moments.map(&:__getobj__)]
        actual = Set[*subject(&:__getobj__)]
        expect(actual).to eq expected
      end
      it 'should yield offset moments in chronological order' do
        expect(subject.to_a.map(&:offset)).to eq all_expected_moments.map(&:offset)
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
