# frozen_string_literal: true

require 'rspec'
require 'active_support/core_ext/numeric/time'

RSpec.describe Dodo::ParallelScheduler do
  let(:duration) { 2.weeks }
  let(:opts) { {} }
  let(:after) { 2.days }

  let(:starting_offset) { 0.seconds }

  let(:context) do
    instance_double(Dodo::Context).tap do |context|
      allow(context).to receive(:push).and_return(context)
    end
  end

  let(:moments) { build_list :moment, 5 }
  let(:offset_moments) do
    moments.map do |moment|
      Dodo::OffsetTimeline.new(moment, rand(10).days)
    end.sort
  end

  let(:more_moments) { build_list :moment, 5 }
  let(:more_offset_moments) do
    more_moments.map do |moment|
      Dodo::OffsetTimeline.new(moment, rand(7).days)
    end.sort
  end

  let(:serial) do
    serial = build :serial
    moments.each { |moment| serial.use moment }
    serial
  end
  let(:another_serial) do
    serial = build :serial
    more_moments.each { |moment| serial.use moment }
    serial
  end

  let(:distributed_moments) do
    moments.map do |moment|
      Dodo::OffsetTimeline.new moment, rand(10).days
    end.sort
  end
  let(:more_distributed_moments) do
    more_moments.map do |moment|
      Dodo::OffsetTimeline.new moment, rand(7).days + after
    end.sort
  end

  let(:serial_scheduler) do
    scheduler = serial.scheduler(starting_offset, context, opts)
    allow(scheduler).to(
      receive(:to_enum)
    ).and_return distributed_moments.to_enum
    scheduler
  end

  let(:another_serial_scheduler) do
    scheduler = another_serial.scheduler(starting_offset + after, context, opts)
    allow(
      scheduler
    ).to receive(:to_enum).and_return more_distributed_moments.to_enum
    scheduler
  end

  before do
    allow(serial).to receive(:scheduler).and_return(serial_scheduler)
    allow(another_serial).to receive(:scheduler).and_return(
      another_serial_scheduler
    )
  end

  let(:parallel) do
    allow(Dodo::SerialTimeline).to receive(:new).and_return(serial, another_serial)
    Dodo::ParallelTimeline.new.tap do |parallel|
      parallel.also after: 0, over: serial.duration {}
      parallel.also after: after, over: another_serial.duration {}
    end
  end

  let(:parallel_scheduler) do
    Dodo::ParallelScheduler.new parallel, starting_offset, context, opts
  end

  describe '#each' do
    subject { parallel_scheduler }

    context 'without opts' do
      let(:expected_moments) do
        (distributed_moments + more_distributed_moments).sort
      end

      it 'should provide any opts to the underlying serial schedulers' do
        expect(serial).to receive(:scheduler).with(
          starting_offset, context, opts
        )
        subject
      end

      it 'should yield the expected number of moments' do
        expect(subject.count).to eq expected_moments.size
      end

      it 'should yield all moments' do
        expected = Set[*expected_moments.map(&:__getobj__)]
        actual = Set[*subject(&:__getobj__)]
        expect(actual).to eq expected
      end
      it 'should yield offset moments in chronological order' do
        expect(subject.map(&:offset)).to eq expected_moments.map(&:offset)
      end
    end
  end
end
