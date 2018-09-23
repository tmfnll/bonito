# frozen_string_literal: true

require 'active_support/core_ext/numeric/time'
require 'securerandom'

RSpec.describe Dodo::Window do
  let(:duration) { 2.weeks }
  let(:window) { Dodo::Window.new(duration) {} }
  let(:moment) { Dodo::Moment.new {} }
  let(:block) { -> { true } }

  describe '#initialize' do
    let(:uninitialized) { Dodo::Window.allocate }

    subject { window }

    it 'should set duration' do
      expect(subject.duration).to eq duration
    end

    it 'should initialize @happenings as an empty array' do
      expect(subject.instance_variable_get(:@happenings)).to eq []
    end

    it 'should initialize @total_child_duration as 0' do
      expect(subject.instance_variable_get(:@total_child_duration)).to eq 0
    end

    it 'should invoke instance_eval' do
      expect(uninitialized).to receive(:instance_eval) do |&blk|
        expect(blk).to eq block
      end
      uninitialized.send(:initialize, duration, &block)
    end
  end

  describe '#<<' do
    subject { window << happening }

    context 'with a happening whose duration is less than that of the window' do
      let(:happening) { Dodo::Window.new(duration - 1) {} }

      it 'should successfully append the happening' do
        expect(subject.instance_variable_get(:@happenings)).to eq [happening]
      end

      it 'should increase the @total_child_duration by the duration of the happening' do
        expect { subject }.to change {
          window.instance_variable_get :@total_child_duration
        }.by happening.duration
      end
    end

    context 'with a happening whose duration is greater than that of the window' do
      let(:happening) { Dodo::Window.new(duration + 1) {} }

      it 'should successfully append the happening' do
        expect { subject }.to raise_error(Exception)
      end
    end
  end

  describe '#use' do
    it 'should be an alias for #<<' do
      expect(window.method(:use)).to eq(window.method(:<<))
    end
  end

  describe '#over' do
    let(:child) { Dodo::Window.new(duration - 1) {} }

    before do
      allow(window.class).to receive(:new).and_return child
    end

    subject { window.over(child.duration, &block) }

    it 'should instantiate a new child' do
      expect(window.class).to receive(:new) do |dur, &blk|
        expect(dur).to eq child.duration
        expect(blk).to eq block
        child
      end
      subject
    end

    it 'should append the new window to parent@happenings' do
      expect(window).to receive(:<<).with(child)
      subject
    end

    it 'should return the child' do
      expect(subject).to eq child
    end
  end

  describe 'please' do
    before do
      allow(Dodo::Moment).to receive(:new).and_return(moment)
    end

    subject { window.please(&block) }

    it 'should instantiate a new child' do
      expect(Dodo::Moment).to receive(:new) do |&blk|
        expect(blk).to eq block
        moment
      end
      subject
    end

    it 'should append the new window to window@happenings' do
      expect(window).to receive(:<<).with(moment)
      subject
    end

    it 'should return the moment' do
      expect(subject).to eq moment
    end
  end

  describe '#repeat' do
    before do
      allow(window).to receive(:please).and_return(moment)
    end

    context 'with no args and passing block' do
      subject { window.repeat &block }
      it 'should invoke #please twice passing block' do
        expect(window).to receive(:please) do |&blk|
          expect(blk).to eq block
        end.exactly(2).times
        subject
      end

      it 'should return an array of Moments' do
        expect(subject).to eq [moment, moment]
      end
    end

    context 'with an integer as the :times argument and passing block' do
      let(:this_many) { 3 }

      subject { window.repeat times: this_many, &block }

      it 'should invoke #please :repetitions times passing block' do
        expect(window).to receive(:please) do |&blk|
          expect(blk).to eq block
        end.exactly(this_many).times
        subject
      end
    end
  end

  describe '#distribution' do
    subject { window.send(:distribution) }

    context 'with a total of :this_many happenings queued' do
      let(:this_many) { 5 }

      let(:random_numbers) do
        [3.days, 8.days, 1.day, 11.days, 1.week].map(&:to_i)
      end

      subject { window.send(:distribution) }

      context 'with @total_child_duration = 0' do
        before do
          this_many.times { window << moment }
          allow(SecureRandom).to receive(:random_number).and_return(*random_numbers)
        end

        it 'should call SecureRandom::random_number :this_many times, with a limit of window.duration' do
          expect(SecureRandom).to receive(:random_number) do |limit|
            expect(limit).to eq window.duration
          end.exactly(this_many).times
          subject
        end

        it 'should return a sorted array of offsets' do
          expect(subject).to eq random_numbers.sort
        end
      end

      context 'with @total_child_duration = :a_couple_of_days' do
        let(:a_couple_of_days) { 2.days }

        let(:child) { Dodo::Window.new(a_couple_of_days) {} }

        before do
          window << child
          (this_many - 1).times { window << moment }
          allow(SecureRandom).to receive(:random_number).and_return(*random_numbers)
        end

        it 'should call SecureRandom::random_number :this_many times, with a limit of window.duration - window.@total_child_duration' do
          expect(SecureRandom).to receive(:random_number) do |limit|
            expect(limit).to eq window.duration - window.instance_variable_get(:@total_child_duration)
          end.exactly(this_many).times
          subject
        end

        it 'should return a sorted array of offsets' do
          expect(subject).to eq random_numbers.sort
        end
      end
    end
  end

  describe '#eval' do
    context 'with a total of :this_many happenings queued' do
      let(:this_many) { 5 }

      let(:some_time_ago) { 3.weeks.ago }

      let(:distribution) do
        [1.days, 3.days, 1.week, 8.days, 11.days].map(&:to_i)
      end

      before do
        this_many.times { window << moment }
        allow(window).to receive(:distribution).and_return(distribution)
        allow(moment).to receive(:eval, &:itself)
      end

      subject { window.eval starting: some_time_ago }

      it 'should call eval on each queued happening' do
        expect(moment).to receive(:eval).exactly(this_many).times
        subject
      end

      it 'should return the initial offset plus the duration of the window' do
        expect(subject).to eq some_time_ago + window.duration
      end

      it 'should call eval, offset according to distribution' do
        offsets = []
        allow(moment).to receive(:eval) do |offset|
          offsets << offset
          offset
        end
        subject
        expect(offsets).to eq distribution.map { |offset| some_time_ago + offset }
      end
    end
  end
end
