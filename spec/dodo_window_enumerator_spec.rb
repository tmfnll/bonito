# frozen_string_literal: true

require 'active_support/core_ext/numeric/time'
require 'securerandom'

RSpec.describe Dodo::WindowEnumerator do
  let(:duration) { 2.weeks }
  let(:window) { Dodo::Window.new(duration) {} }

  let(:moment) { Dodo::Moment.new }
  let(:child_window) { Dodo::Window.new(1.day) {} }

  let!(:starting_offset) { parent_distribution.peek }
  let(:n) { 2 }
  let(:m) { 3 }
  let(:opts) { { cram: n, stretch: m } }

  let(:moments) { build_list :moment, 5 }

  let(:distribution) do
    distribution = Dodo::Distribution.new window, starting_offset
    patched = allow(distribution).to receive(:each)
    distributed_moments.each do |moment|
      patched.and_yield moment
    end
    distribution
  end

  let(:enumerator) { described_class.new window, parent_distribution, opts }

  let(:random_numbers) do
    [3.days, 8.days, 1.day, 11.days, 1.week]
  end
  let(:k) { random_numbers.size }

  describe '#each' do
    context 'with a total of :k happenings queued' do
      let(:starting_offset) { rand(10).days }
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
          expect(child_window).to receive(:enum).once.with(starting_offset, opts)
          expect(moment).to receive(:enum).exactly(k - 1).times.with(starting_offset, opts)
          subject
        end

        it 'should yield an offset and the moment itself for each moment' do
          expect { |b| enumerator.each(&b) }.to yield_successive_args(*offset_moments)
        end
      end
    end
  end
end
