require 'active_support/core_ext/numeric/time'

RSpec.describe Dodo::Container do
  let(:duration) { 2.weeks }
  let(:block) { proc { true } }
  let(:container) { described_class.new over: duration, &block }
  let(:window_duration) { 1.week }
  let(:window) { Dodo::Window.new window_duration, &block }
  let(:offset) { 3.days }
  let(:offset_window) { Dodo::OffsetHappening.new window, offset }

  describe '#initialize' do
    subject { container }

    context 'with a block defining a Dodo::Window' do
      it 'should append to the windows array' do
        expect(subject.windows.size).to eq 1
      end

      it 'should append an offset happening' do
        expect(subject.windows.first).to be_a Dodo::OffsetHappening
      end

      it 'should append an offset happening with a duration specified by the over arg' do
        expect(subject.windows.first.duration).to eq duration
      end

      it 'should append an offset happening with an offset of 0' do
        expect(subject.windows.first.offset).to eq 0
      end

      it 'should have a duration equal to the over arg' do
        expect(subject.duration).to eq duration
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

  shared_examples 'a method that allows additional windows be added to a container' do

    context 'when passed a single OffsetHappening as an argument' do


      context 'with the sum of the duration of the appended window and' \
              'its offset LESS than that of the containers duration' do

        it_behaves_like 'an appender of windows'

        it 'should not change the duration of the container' do
          expect { subject }.not_to change { container.duration }
        end
      end

      context 'with the sum of the duration of the appended window and' \
              'its offset GREATER that that of the containers duration' do

        let(:offset) { duration + 1.week }

        it_behaves_like 'an appender of windows'

        it 'should change the duration of the container to the sum of the appended' \
           'window and its offset' do
          expect(subject.duration).to eq(offset_window.duration + offset_window.offset)
        end
      end
    end
  end

  describe '#<<' do
    subject { container << offset_window }
    it_behaves_like 'a method that allows additional windows be added to a container'
  end
  describe '#also' do
    before do
      container # Ensure the container is created before patching the window constructor
      allow(Dodo::Window).to receive(:new).and_return(window)
    end
    context 'with an integer provided' do
      subject { container.also after: offset, over: window_duration, &block }
      it_behaves_like 'a method that allows additional windows be added to a container'
    end
  end
end
