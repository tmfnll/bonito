# frozen_string_literal: true

require 'rspec'
require 'active_support/core_ext/numeric/time'

RSpec.describe Dodo::Runner do
  let(:live) { false }
  let(:daemonise) { false }
  let(:opts) { { live: live, daemonise: daemonise } }
  let(:n) { 5 }
  let(:block) { proc { true } }
  let(:moments) do
    (1..n).map do |offset|
      Dodo::OffsetHappening.new(Dodo::Moment.new(&block), offset)
    end
  end
  let(:window) do
    window = Dodo::Window.new(3.weeks) {}
    moments.each { |moment| window << moment }
    window
  end
  let(:start) { 2.weeks.ago }
  let(:context) { Dodo::Context.new }
  let(:runner) { described_class.new opts }

  describe '#initialize' do
    subject { runner }
    context 'without any opts' do
      let(:runner) { described_class.new }
      it 'should initialise successfully' do
        subject
      end
    end
    context 'with opts' do
      it 'should initialise successfully' do
        subject
      end
    end
  end
  describe '#live?' do
    subject { runner.live? }
    context 'when initialised without any opts' do
      let(:runner) { described_class.new }
      it 'should return false' do
        expect(subject).to be false
      end
    end
    context 'with opts' do
      it 'should return the value of the opt provided' do
        expect(subject).to be live
      end
    end
  end
  describe '#daemonise?' do
    subject { runner.daemonise? }
    context 'when initialised without any opts' do
      let(:runner) { described_class.new }
      it 'should return false' do
        expect(subject).to be false
      end
    end
    context 'with opts' do
      it 'should return the value of the opt provided' do
        expect(subject).to be daemonise
      end
    end
  end
  describe '#call' do
    let(:enum_opts) { double }
    before do
      allow(window).to receive(:enum).and_return moments
    end

    context 'with a context provided' do
      subject { runner.call window, start, context, enum_opts }

      it 'should invoke window.enum with nil and opts' do
        expect(window).to receive(:enum).with(nil, enum_opts)
        subject
      end
      it 'should make a call to occurring_at once for each yielded moment' do
        expect(runner).to receive(:occurring_at).exactly(n).times
        subject
      end
      it 'should pass an offset of start + moment.offset into occurring_at, for each moment' do
        moments.map do |moment|
          expect(runner).to receive(:occurring_at).with(start + moment.offset).ordered
        end
        subject
      end
      it 'should evaluate each moment within context' do
        moments.map do |moment|
          expect(context).to receive(:instance_eval) do |&blk|
            expect(blk).to be moment.block
          end.ordered
        end
        subject
      end
      context 'with daemonize = false' do
        it 'does not run as a daemon' do
          expect(Process).not_to receive(:daemon)
          subject
        end
      end
      context 'with daemonise = true' do
        let(:daemonise) { true }
        it 'runs as a daemon' do
          expect(Process).to receive(:daemon).with no_args
          subject
        end
      end
    end
    context 'without any context provided' do
      let(:context) { nil }
      it 'should complete successfully having created a new context' do
        subject
      end
    end
  end
  describe 'occurring_at' do
    let(:now) { Time.now }
    let(:instant) { Time.now - 2.minutes }

    subject { runner.send(:occurring_at, instant, &block) }

    context 'with live = true' do
      let(:live) { true }

      context 'with instant being some point in the future' do
        let(:instant) { Time.now + 2.weeks }
        before do
          allow(runner).to receive(:sleep)
        end

        it 'should sleep for (instant - now) seconds' do
          expect(runner).to receive(:sleep).with(instant - now)
          Timecop.freeze(now) do
            subject
          end
        end
        it 'should yield control' do
          expect { |b| runner.send(:occurring_at, instant, &b) }.to yield_control
          subject
        end
        it 'should not freeze time' do
          expect(Timecop).not_to receive(:freeze)
          subject
        end
        context 'with instant being only just in the future' do
          let(:instant) { now + 0.000001.seconds }
          before do
            allow(Time).to receive(:now).and_return(now, now + 0.000002)
          end
          it 'should never be able invoke sleep with a negative argument' do
            expect(runner).to receive(:sleep).with(0)
            subject
          end
        end
      end
      context 'with instant being some point in the past' do
        it 'should freeze time at instant' do
          expect(Timecop).to receive(:freeze).with(instant)
          subject
        end
        it 'should yield control' do
          expect { |b| runner.send(:occurring_at, instant, &b) }.to yield_control
          subject
        end
      end
    end
    context 'with live = false' do
      it 'should freeze time at instant' do
        expect(Timecop).to receive(:freeze).with(instant)
        subject
      end
      it 'should yield control' do
        expect { |b| runner.send(:occurring_at, instant, &b) }.to yield_control
        subject
      end
    end
  end
end
