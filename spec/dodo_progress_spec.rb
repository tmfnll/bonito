require 'spec_helper'
require 'logger'

RSpec.describe Dodo::ProgressLogger do
  let(:logger) { instance_double Logger }
  let(:total) { 10 }
  let(:prefix) { 'Progress :' }
  let(:current) { 3 }

  let(:progress) do
    Dodo::ProgressLogger.new logger, total: total, prefix: prefix
  end

  before { allow(logger).to receive(:info) }

  describe '#initialize' do
    subject { progress }
    it 'should initialise successfully' do
      subject
    end
  end

  describe '#current=' do
    subject { progress.current = current }
    it 'should log the current progress as a fraction of the total' do
      expect(logger).to receive(:info).with("#{prefix} #{current} / #{total}")
      subject
    end

    it 'should update the value of @current' do
      subject
      expect(progress.current).to eq current
    end
    context ' without an integer total' do
      let(:progress) { Dodo::ProgressLogger.new logger, prefix: prefix }
      it 'should log the current progress by itself' do
        expect(logger).to receive(:info).with("#{prefix} #{current}")
        subject
      end
    end
    context 'without a prefix' do
      let(:progress) { Dodo::ProgressLogger.new logger, total: total }
      it 'should log the current progress with the default prefix' do
        expect(logger).to receive(:info).with(
          "Dodo::ProgressLogger{#{progress.object_id}} : " +
          "Progress Made : #{current} / #{total}"
        )
        subject
      end
    end
  end

  describe '#+' do
    let(:increment) { 2 }

    subject { progress + increment }

    before do
      progress.current = current
    end

    it 'should add the value of increment to @current' do
      subject
      expect(progress.current).to eq(current + increment)
    end

    it 'should return the incremented value' do
      subject
      expect(progress.current).to eq(current + increment)
    end
  end
end
