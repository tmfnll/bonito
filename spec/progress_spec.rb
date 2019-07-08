# frozen_string_literal: true

require 'spec_helper'
require 'logger'

RSpec.describe Bonito::ProgressLogger do
  let(:logger) { instance_double Logger }
  let(:total) { 10 }
  let(:prefix) { 'Progress :' }
  let(:current) { 3 }

  let(:progress) do
    Bonito::ProgressLogger.new logger, total: total, prefix: prefix
  end

  before { allow(logger).to receive(:info) }

  describe '#initialize' do
    subject { progress }
    it 'should initialise successfully' do
      subject
    end
  end

  describe '#increment' do
    let(:increment) { 2 }
    let(:incremented) { current + increment }

    subject { progress.increment increment }

    before do
      progress.instance_variable_set :@current, current
    end

    it 'should add the value of increment to @current' do
      subject
      expect(progress.current).to eq(incremented)
    end

    it 'should return the incremented value' do
      subject
      expect(progress.current).to eq(incremented)
    end

    it 'should invoke on_increment' do
      expect(progress).to receive(:on_increment).with(increment)
      subject
    end

    it 'should log the current progress as a fraction of the total' do
      expect(logger).to receive(:info).with(
        "#{prefix} #{incremented} / #{total}"
      )
      subject
    end

    it 'should update the value of @current' do
      subject
      expect(progress.current).to eq current + increment
    end
    context 'without an integer total' do
      let(:progress) { Bonito::ProgressLogger.new logger, prefix: prefix }
      it 'should log the current progress by itself' do
        expect(logger).to receive(:info).with("#{prefix} #{incremented} / -")
        subject
      end
    end
    context 'without a prefix' do
      let(:progress) { Bonito::ProgressLogger.new logger, total: total }
      it 'should log the current progress with the default prefix' do
        expect(logger).to receive(:info).with(
          "Bonito::ProgressLogger{#{progress.object_id}} : " \
          "Progress Made : #{incremented} / #{total}"
        )
        subject
      end
    end
  end
end
