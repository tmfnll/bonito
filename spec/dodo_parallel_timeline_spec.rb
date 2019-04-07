# frozen_string_literal: true

require 'active_support/core_ext/numeric/time'

RSpec.describe Dodo::ParallelTimeline do
  let(:duration) { 2.weeks }
  let(:block) { proc { true } }
  let(:parallel) { described_class.new }
  let(:serial_duration) { 1.week }
  let(:serial) { Dodo::SerialTimeline.new serial_duration, &block }
  let(:offset) { 3.days }
  let(:offset_serial) { Dodo::OffsetTimeline.new serial, offset }

  describe '#initialize' do
    subject { parallel }

    context 'without a block' do
      it 'should have an initial duration of 0' do
        expect(subject.duration).to eq 0
      end
    end

    context 'with a block' do
      let(:allocated) { Dodo::ParallelTimeline.allocate }
      let(:block) { proc { true } }

      subject { Dodo::ParallelTimeline.new(&block) }

      it 'should have an initial duration of 0' do
        expect(subject.duration).to eq 0
      end

      it 'should call instance_eval using the block passed' do
        expect(allocated).to receive(:instance_eval) do |&blk|
          expect(blk).to eq block
        end
        allocated.send :initialize, &block
      end
    end
  end

  shared_examples 'an appender of timelines' do
    it 'should append to the timelines array' do
      expect { subject }.to change { parallel.to_a.size }.by 1
    end

    it 'should append the serial provided to the timelines array' do
      expect(subject.to_a.last).to eq offset_serial
    end

    it 'should return the parallel itself' do
      expect(subject).to be parallel
    end
  end

  shared_examples 'a method that allows additional timelines be ' \
                  'added to a parallel' do
    context 'when passed a single OffsetTimeline as an argument' do
      context 'with a newly initialized parallel' do
        it_behaves_like 'an appender of timelines'

        it 'should update the parallel duration to that of the
            appended serial' do
          subject
          expect(
            parallel.duration
          ).to eq offset_serial.duration + offset_serial.offset
        end
      end

      context 'with the sum of the duration of the appended serial and' \
              'its offset LESS than that of the parallels duration' do
        before do
          allow(parallel).to receive(:duration).and_return(3.weeks)
        end

        it_behaves_like 'an appender of timelines'

        it 'should not change the duration of the parallel' do
          expect { subject }.not_to(change { parallel.duration })
        end
      end

      context 'with the sum of the duration of the appended serial and' \
              'its offset GREATER that that of the parallels duration' do

        let(:offset) { duration + 1.week }

        it_behaves_like 'an appender of timelines'

        it 'should change the duration of the parallel to the sum of the ' \
           'appended serial and its offset' do
          expect(subject.duration).to eq(
            offset_serial.duration + offset_serial.offset
          )
        end
      end
    end
  end

  describe '#over' do
    let(:offset) { 0 }
    subject { parallel.over serial_duration, after: offset, &block }
    before do
      parallel # Ensure the parallel is created before patching the
      # serial constructor
      allow(Dodo::SerialTimeline).to receive(:new).and_return(serial)
    end
    it_behaves_like(
      'a method that allows additional timelines be added to a parallel'
    )
  end

  describe '#also' do
    subject { parallel.also after: offset, over: serial_duration, &block }

    before do
      parallel # Ensure the parallel is created before patching the
      # serial constructor
      allow(Dodo::SerialTimeline).to receive(:new).and_return(serial)
    end

    context 'with an integer provided' do
      it_behaves_like(
        'a method that allows additional timelines be added to a parallel'
      )
    end
  end

  describe '#use' do
    context 'with a pre-baked serial provided' do
      subject { parallel.use serial, after: offset }
      it_behaves_like(
        'a method that allows additional timelines be added to a parallel'
      )
    end

    context 'with many pre-baked timelines provided' do
      let(:timelines) { build_list :serial, 3 }
      let(:offset_timelines) do
        timelines.map { |serial| Dodo::OffsetTimeline.new serial, offset }
      end

      subject { parallel.use(*timelines, after: offset) }

      it 'should append to the timelines array' do
        expect { subject }.to change {
          parallel.to_a.size
        }.by timelines.size
      end

      it 'should append the serial provided to the timelines array' do
        expect(subject.to_a.last(timelines.size)).to eq offset_timelines
      end

      it 'should return the parallel itself' do
        expect(subject).to be parallel
      end
    end
  end

  describe '#repeat' do
    let(:times) { 3 }
    subject do
      parallel.repeat(
        times: times, over: serial_duration, after: offset, &block
      )
    end

    before do
      parallel # Ensure the parallel is created before patching the
      # serial constructor
      allow(Dodo::SerialTimeline).to receive(:new).and_return(serial)
    end

    it 'should append to the timelines array' do
      expect { subject }.to change { parallel.to_a.size }.by times
    end

    it 'should append the serial provided to the timelines array' do
      expect(subject.to_a.last(times)).to eq([offset_serial] * 3)
    end

    it 'should return the parallel itself' do
      expect(subject).to be parallel
    end
  end

  describe '#scheduler' do
    let(:starting_offset) { 2.days }
    let(:scope) { Dodo::Scope.new }
    let(:distribution) { starting_offset }
    subject { parallel.scheduler starting_offset, scope }
    context 'without opts' do
      it 'should create and return a new ParallelScheduler' do
        expect(subject).to be_a Dodo::ParallelScheduler
      end
      it 'should create a ParallelScheduler with an empty hash as opts' do
        expect(Dodo::ParallelScheduler).to receive(:new).with(
          parallel, starting_offset, scope, {}
        )
        subject
      end
    end
    context 'with opts' do
      let(:opts) { { stretch: 4 } }
      subject { parallel.scheduler starting_offset, scope, opts }
      it 'should create and return a new ParallelScheduler' do
        expect(subject).to be_a Dodo::ParallelScheduler
      end
      it 'should create a ParallelScheduler with an empty hash as opts' do
        expect(Dodo::ParallelScheduler).to receive(:new).with(
          parallel, starting_offset, scope, opts
        )
        subject
      end
    end
  end
end
