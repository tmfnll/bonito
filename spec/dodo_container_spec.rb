# frozen_string_literal: true

require 'active_support/core_ext/numeric/time'

RSpec.describe Dodo::Container do
  let(:duration) { 2.weeks }
  let(:block) { proc { true } }
  let(:container) { described_class.new }
  let(:window_duration) { 1.week }
  let(:window) { Dodo::Window.new window_duration, &block }
  let(:offset) { 3.days }
  let(:offset_window) { Dodo::OffsetHappening.new window, offset }

  describe '#initialize' do
    subject { container }

    context 'with a block defining a Dodo::Window' do
      it 'should have an initial duration of 0' do
        expect(subject.duration).to eq 0
      end
    end
  end

  shared_examples 'an appender of windows' do
    it 'should append to the windows array' do
      expect { subject }.to change { container.windows.size }.by 1
    end

    it 'should append the window provided to the windows array' do
      expect(subject.windows.last).to eq offset_window
    end

    it 'should return the container itself' do
      expect(subject).to be container
    end
  end

  shared_examples 'a method that allows additional windows be ' \
                  'added to a container' do
    context 'when passed a single OffsetHappening as an argument' do
      context 'with a newly initialized container' do
        it_behaves_like 'an appender of windows'

        it 'should update the container duration to that of the
            appended window' do
          subject
          expect(
            container.duration
          ).to eq offset_window.duration + offset_window.offset
        end
      end

      context 'with the sum of the duration of the appended window and' \
              'its offset LESS than that of the containers duration' do
        before do
          allow(container).to receive(:duration).and_return(3.weeks)
        end

        it_behaves_like 'an appender of windows'

        it 'should not change the duration of the container' do
          expect { subject }.not_to(change { container.duration })
        end
      end

      context 'with the sum of the duration of the appended window and' \
              'its offset GREATER that that of the containers duration' do

        let(:offset) { duration + 1.week }

        it_behaves_like 'an appender of windows'

        it 'should change the duration of the container to the sum of the ' \
           'appended window and its offset' do
          expect(subject.duration).to eq(
            offset_window.duration + offset_window.offset
          )
        end
      end
    end
  end

  describe '#over' do
    let(:offset) { 0 }
    subject { container.over window_duration, after: offset, &block }
    before do
      container # Ensure the container is created before patching the
      # window constructor
      allow(Dodo::Window).to receive(:new).and_return(window)
    end
    it_behaves_like(
      'a method that allows additional windows be added to a container'
    )
  end

  describe '#also' do
    subject { container.also after: offset, over: window_duration, &block }

    before do
      container # Ensure the container is created before patching the
      # window constructor
      allow(Dodo::Window).to receive(:new).and_return(window)
    end

    context 'with an integer provided' do
      it_behaves_like(
        'a method that allows additional windows be added to a container'
      )
    end
  end

  describe '#use' do
    context 'with a pre-baked window provided' do
      subject { container.use window, after: offset }
      it_behaves_like(
        'a method that allows additional windows be added to a container'
      )
    end

    context 'with many pre-baked windows provided' do
      let(:windows) { build_list :window, 3 }
      let(:offset_windows) do
        windows.map { |window| Dodo::OffsetHappening.new window, offset }
      end

      subject { container.use(*windows, after: offset) }

      it 'should append to the windows array' do
        expect { subject }.to change { container.windows.size }.by windows.size
      end

      it 'should append the window provided to the windows array' do
        expect(subject.windows.last(windows.size)).to eq offset_windows
      end

      it 'should return the container itself' do
        expect(subject).to be container
      end
    end
  end

  describe '#repeat' do
    let(:times) { 3 }
    subject do
      container.repeat(
        times: times, over: window_duration, after: offset, &block
      )
    end

    before do
      container # Ensure the container is created before patching the
      # window constructor
      allow(Dodo::Window).to receive(:new).and_return(window)
    end

    it 'should append to the windows array' do
      expect { subject }.to change { container.windows.size }.by times
    end

    it 'should append the window provided to the windows array' do
      expect(subject.windows.last(times)).to eq([offset_window] * 3)
    end

    it 'should return the container itself' do
      expect(subject).to be container
    end
  end

  describe '#scheduler' do
    let(:starting_offset) { 2.days }
    let(:context) { Dodo::Context.new }
    let(:distribution) { starting_offset }
    subject { container.scheduler starting_offset, context }
    context 'without opts' do
      it 'should create and return a new ContainerScheduler' do
        expect(subject).to be_a Dodo::ContainerScheduler
      end
      it 'should create a ContainerScheduler with an empty hash as opts' do
        expect(Dodo::ContainerScheduler).to receive(:new).with(
          container, starting_offset, context, {}
        )
        subject
      end
    end
    context 'with opts' do
      let(:opts) { { stretch: 4 } }
      subject { container.scheduler starting_offset, context, opts }
      it 'should create and return a new ContainerScheduler' do
        expect(subject).to be_a Dodo::ContainerScheduler
      end
      it 'should create a ContainerScheduler with an empty hash as opts' do
        expect(Dodo::ContainerScheduler).to receive(:new).with(
          container, starting_offset, context, opts
        )
        subject
      end
    end
  end
end
