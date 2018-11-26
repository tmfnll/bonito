require 'spec_helper'

RSpec.describe Dodo::Distribution do
  let(:moments) { build_list :moment, 3 }
  let(:child_window) { build :window }
  let(:happenings) { [child_window] + moments }

  let(:random_numbers) do
    random_numbers = Array.new(happenings.size - 2) { rand window.unused_duration }
    random_numbers.unshift 0 # ensure that the distribution achieves its lower
    random_numbers << window.unused_duration # and upper bounds
  end

  let(:window) do
    window = build :window, duration: child_window.duration + 1.day
    happenings.each { |happening| window << happening }
    window
  end

  let(:starting_offset) { rand(10).days }
  let(:distribution) { described_class.new window, starting_offset }

  before do
    allow(SecureRandom).to receive(:random_number).and_return(*random_numbers)
  end

  describe '#each' do
    subject { distribution.to_a }

    context 'where the last happening in window.happenings has a duration of 0' do
      it 'should return an enumerator of offset happenings' do
        expect(Set[*subject.map(&:class)]).to eq Set[Dodo::OffsetHappening]
      end

      it 'should yield happenings within a range equal to that of the duration' do
        expect(subject.last.offset - subject.first.offset).to eq window.duration
      end

      it 'should yield happenings in ascending order of offset' do
        expect(subject.sort).to eq subject
      end

      it 'should not yield a happening that has been offset to a point before the starting offset' do
        expect(subject.first.offset).to eq starting_offset
      end
    end
    context 'where the only happening with non-zero duration appears last in window.happenings' do
      let(:happenings) { moments + [child_window] }

      it 'should yield happenings within a range equal to that of the unused duration' do
        expect(subject.last.offset - subject.first.offset).to eq window.unused_duration
      end
    end
  end
end
