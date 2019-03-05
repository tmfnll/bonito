# frozen_string_literal: true

require 'rspec'
require 'active_support/core_ext/numeric/time'

RSpec.describe Dodo::ContainerScheduler do
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
    moments.each { |moment| window.use moment }
    window
  end
  let(:another_window) do
    window = build :window
    more_moments.each { |moment| window.use moment }
    window
  end

  let(:distributed_moments) do
    moments.map do |moment|
      Dodo::OffsetHappening.new moment, rand(10).days
    end.sort
  end
  let(:more_distributed_moments) do
    more_moments.map do |moment|
      Dodo::OffsetHappening.new moment, rand(7).days + after
    end.sort
  end

  let(:window_scheduler) do
    scheduler = window.scheduler(starting_offset, context, opts)
    allow(scheduler).to(
      receive(:to_enum)
    ).and_return distributed_moments.to_enum
    scheduler
  end

  let(:another_window_scheduler) do
    scheduler = another_window.scheduler(starting_offset + after, context, opts)
    allow(
      scheduler
    ).to receive(:to_enum).and_return more_distributed_moments.to_enum
    scheduler
  end

  before do
    allow(window).to receive(:scheduler).and_return(window_scheduler)
    allow(another_window).to receive(:scheduler).and_return(
      another_window_scheduler
    )
  end

  let(:container) do
    allow(Dodo::Window).to receive(:new).and_return(window, another_window)
    Dodo::Container.new.tap do |container|
      container.also after: 0, over: window.duration {}
      container.also after: after, over: another_window.duration {}
    end
  end

  let(:container_scheduler) do
    Dodo::ContainerScheduler.new container, starting_offset, context, opts
  end

  describe '#each' do
    subject { container_scheduler }

    context 'without opts' do
      let(:expected_moments) do
        (distributed_moments + more_distributed_moments).sort
      end

      it 'should provide any opts to the underlying window schedulers' do
        expect(window).to receive(:scheduler).with(
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
      it 'should not store more than 1 moment per window in the heap' do
        subject.each do
          expect(
            container_scheduler.instance_variable_get(:@moment_heap).size
          ).to be <= 2
        end
      end
    end
  end
end
