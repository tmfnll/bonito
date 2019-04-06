# frozen_string_literal: true

require 'active_support/core_ext/numeric/time'
require 'securerandom'

RSpec.describe Dodo::SerialScheduler do
  let(:moments) { build_list :moment, 3 }
  let(:child_serial) { build :serial }
  let(:child_container) { build :container }
  let(:timelines) { [child_serial, child_container] + moments }

  let(:random_numbers) do
    random_numbers = serial.map do |_|
      rand(serial.unused_duration)
    end.sort
    2.times { random_numbers.pop }
    random_numbers.unshift 0 # ensure that the distribution achieves its lower
    random_numbers << serial.unused_duration # and upper bounds
  end

  let(:serial) do
    duration = child_serial.duration + child_container.duration + 1.day
    serial = build :serial, duration: duration
    timelines.each { |timeline| serial.use timeline }
    serial
  end

  let(:scale_opts) { {} }
  let(:stretch) { scale_opts.fetch(:stretch) { 1 } }

  let(:starting_offset) { rand(10).days }
  let(:context) { Dodo::Context.new }
  let(:scheduler) do
    described_class.new serial, starting_offset, context, scale_opts
  end

  before do
    allow(SecureRandom).to receive(:random_number).and_return(*random_numbers)
  end

  describe '#each' do
    subject { scheduler.to_a }

    shared_examples 'an scheduler of offset moments' do
      context 'where the last timeline in serial.to_a has a
               duration of 0' do
        it 'should return an scheduler of offset timelines' do
          expect(Set[*subject.map(&:class)]).to eq Set[Dodo::ContextualMoment]
        end

        it 'should yield multiple moments' do
          expect(subject.size).to eq(moments.size)
        end

        it 'should yield timelines within a range equal to that of the
            stretched duration' do
          expect(subject.last.offset - subject.first.offset).to eq(
            (serial.unused_duration - random_numbers[2]) * stretch
          )
        end

        it 'should yield timelines offset by the accumulated duration and a
            random value' do
          random_numbers[2..random_numbers.size].each_with_index do |rnd, index|
            expect(subject[index].offset).to eq(
              starting_offset +
              (stretch * (
                child_serial.duration + child_container.duration + rnd
              ))
            )
          end
        end

        it 'should yield timelines in ascending order of offset' do
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

    context 'where the only timeline with non-zero duration appears last in
             serial.to_a' do
      let(:timelines) { moments + [child_serial] }

      it 'should yield timelines within a range equal to that of the
          unused duration' do
        expect(subject.last.offset - subject.first.offset).to eq(
          random_numbers[-2]
        )
      end
    end
  end
end
