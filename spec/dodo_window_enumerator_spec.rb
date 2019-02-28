# frozen_string_literal: true

require 'active_support/core_ext/numeric/time'
require 'securerandom'

RSpec.describe Dodo::WindowScheduler do
  let(:moments) { build_list :moment, 3 }
  let(:child_window) { build :window }
  let(:child_container) { build :container }
  let(:happenings) { [child_window, child_container] + moments }

  let(:random_numbers) do
    random_numbers = window.send(:happenings).map do |_|
      rand(window.unused_duration)
    end.sort
    2.times { random_numbers.pop }
    random_numbers.unshift 0 # ensure that the distribution achieves its lower
    random_numbers << window.unused_duration # and upper bounds
  end

  let(:window) do
    duration = child_window.duration + child_container.duration + 1.day
    window = build :window, duration: duration
    happenings.each { |happening| window << happening }
    window
  end

  let(:scale_opts) { {} }

  let(:starting_offset) { rand(10).days }
  let(:context) { Dodo::Context.new }
  let(:parent_distribution) { [starting_offset].to_enum }
  let(:scheduler) do
    described_class.new window, parent_distribution, context, scale_opts
  end

  before do
    allow(SecureRandom).to receive(:random_number).and_return(*random_numbers)
  end

  describe '#stretch' do
    subject { scheduler.stretch }
    context 'without opts' do
      it 'should have a default value of 1' do
        expect(subject).to eq 1
      end
    end
    context 'with a stretch param passed in the scale_opts hash' do
      let(:stretch) { rand 7 + rand }
      let(:scale_opts) { { stretch: stretch } }
      it 'should return the value of the stretch opt' do
        expect(subject).to eq stretch
      end
      context 'with a scale param passed in the scaled_opts hash' do
        let(:scale) { rand 7 + rand }
        let(:scale_opts) { { scale: scale, stretch: stretch } }
        it 'should return the value of the scale opt' do
          expect(subject).to eq scale
        end
      end
    end
  end

  describe '#each' do
    subject { scheduler.to_a }

    shared_examples 'an scheduler of offset moments' do
      context 'where the last happening in window.happenings has a
               duration of 0' do
        it 'should return an scheduler of offset happenings' do
          expect(Set[*subject.map(&:class)]).to eq Set[Dodo::ContextualMoment]
        end

        it 'should yield multiple moments' do
          expect(subject.size).to eq(moments.size)
        end

        it 'should yield happenings within a range equal to that of the
            stretched duration' do
          expect(subject.last.offset - subject.first.offset).to eq(
            (window.unused_duration - random_numbers[2]) * scheduler.stretch
          )
        end

        it 'should yield happenings offset by the accumulated duration and a
            random value' do
          random_numbers[2..random_numbers.size].each_with_index do |rnd, index|
            expect(subject[index].offset).to eq(
              starting_offset +
              (scheduler.stretch * (
                child_window.duration + child_container.duration + rnd
              ))
            )
          end
        end

        it 'should yield happenings in ascending order of offset' do
          expect(subject.sort).to eq subject
        end
      end
    end

    context 'without any scale_opts' do
      it_behaves_like 'an scheduler of offset moments'
    end

    context 'with a stretch parameter provided in scale_opts' do
      let(:stretch) { rand 2..5 }
      let(:scale_opts) { { stretch: stretch } }

      it_behaves_like 'an scheduler of offset moments'
    end

    context 'with a scale parameter provided in scale_opts' do
      let(:scale) { rand 2..5 }
      let(:scale_opts) { { scale: scale } }

      it_behaves_like 'an scheduler of offset moments'
    end

    context 'where the only happening with non-zero duration appears last in
             window.happenings' do
      let(:happenings) { moments + [child_window] }

      it 'should yield happenings within a range equal to that of the
          unused duration' do
        expect(subject.last.offset - subject.first.offset).to eq(
          random_numbers[-2]
        )
      end
    end
  end
end
