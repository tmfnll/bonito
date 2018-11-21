# frozen_string_literal: true

require 'active_support/core_ext/numeric/time'
require 'securerandom'

RSpec.describe Dodo::WindowEnumerator do
  let(:duration) { 2.weeks }
  let(:window) { Dodo::Window.new(duration) {} }

  let(:moment) { Dodo::Moment.new }
  let(:child_window) { Dodo::Window.new(1.day) {} }

  let(:parent_distribution) { [1, 2, 3].each }
  let!(:starting_offset) { parent_distribution.peek }
  let(:n) { 2 }
  let(:m) { 3 }
  let(:opts) { { cram: n, stretch: m } }

  let(:enumerator) { described_class.new window, parent_distribution, opts }

  let(:random_numbers) do
    [3.days, 8.days, 1.day, 11.days, 1.week]
  end
  let(:k) { random_numbers.size }

  describe '#initialize' do
    subject { enumerator }

    context 'with a distribution' do
      it 'should set the starting offset to the first value in the parent distribution' do
        expect(subject.instance_variable_get(:@starting_offset)).to eq starting_offset
      end
      it 'should set the cram factor to n' do
        expect(subject.cram).to eq n
      end

      it 'should set the stretch factor to m' do
        expect(subject.stretch).to eq m
      end
    end

    context 'without a distribution' do
      let(:parent_distribution) { nil }
      let(:starting_offset) { nil }
      it 'should set the starting offset to 0' do
        expect(subject.instance_variable_get(:@starting_offset)).to eq 0
      end
    end
  end

  describe '#total_crammed_happenings' do
    subject { enumerator.send(:total_crammed_happenings) }

    context 'with a single moment and a single child window' do
      before do
        window << moment
        window << child_window
      end

      context 'with a cram factor of 1' do
        let(:n) { 1 }
        it 'should return 2' do
          expect(subject).to eq 2
        end
      end

      context 'with a cram factor of n' do
        let(:n) {  SecureRandom.random_number 100 }
        it 'should return n + 1' do
          expect(subject).to eq (n + 1)
        end
      end
    end
  end

  describe '#distribution' do
    subject { enumerator.send(:distribution) }

    context 'with a total of :k happenings queued' do
      before do
        allow(enumerator).to receive(:total_crammed_happenings).and_return(random_numbers.size)
        allow(SecureRandom).to receive(:random_number).and_return(*random_numbers)
      end

      context 'with a child window' do
        before do
          window << child_window
          (k - 1).times { window << moment }
        end

        it 'should call SecureRandom::random_number :k times, with a limit of window.duration - window.@total_child_duration' do
          enum = random_numbers.each
          expect(SecureRandom).to receive(:random_number) do |limit|
            expect(limit).to eq(window.duration - window.total_child_duration)
            enum.next
          end.exactly(k).times
          subject
        end

        it 'should return a sorted array of integers, each stretched by a factor of m, each offset by the staring offset' do
          expected = random_numbers.sort.map { |i| (i * m) + starting_offset }
          expect([*subject]).to eq expected
        end
      end
    end
  end

  describe '#each' do
    context 'with a total of :k happenings queued' do
      let(:distribution) { random_numbers.each }
      before do
        allow(enumerator).to receive(:distribution).and_return(distribution)
      end

      before do
        window << child_window
        (k - 1).times { window << moment }
      end

      subject { enumerator.each }
      context 'without a block' do
        it 'should return an enum' do
          expect(subject).to be_an Enumerator
        end
      end
      context 'with some block' do
        subject { enumerator.each {} }

        let(:offset_moments) do
          [random_numbers[1..-1], [moment] * (k - 1)].transpose
        end

        let(:expected_yield) do
          offset_moments.map { |tuple| [tuple] }
        end

        before do
          allow(child_window).to receive(:enum).and_return([])
          allow(moment).to receive(:enum).and_return(*expected_yield)
        end

        it 'should invoke each happening\'s enum method' do
          expect(child_window).to receive(:enum).once.with(distribution, opts)
          expect(moment).to receive(:enum).exactly(k - 1).times.with(distribution, opts)
          subject
        end

        it 'should yield an offset and the moment itself for each moment' do
          expect { |b| enumerator.each(&b) }.to yield_successive_args(*offset_moments)
        end
      end
    end
  end
end
