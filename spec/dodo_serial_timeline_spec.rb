# frozen_string_literal: true

RSpec.describe Dodo::SerialTimeline do
  let(:duration) { 2.weeks }
  let(:serial) { Dodo::SerialTimeline.new(duration) {} }
  let(:moment) { Dodo::Moment.new {} }
  let(:block) { -> { true } }

  describe '#initialize' do
    let(:uninitialized) { Dodo::SerialTimeline.allocate }

    subject { serial }

    it 'should set duration' do
      expect(subject.duration).to eq duration
    end

    it 'should initialize @timelines as an empty array' do
      expect(subject.instance_variable_get(:@timelines)).to eq []
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

    context 'without a block provided' do
      subject { Dodo::SerialTimeline.new duration }
      it 'should set duration' do
        expect(subject.duration).to eq duration
      end

      it 'should initialize @timelines as an empty array' do
        expect(subject.instance_variable_get(:@timelines)).to eq []
      end

      it 'should initialize @total_child_duration as 0' do
        expect(subject.instance_variable_get(:@total_child_duration)).to eq 0
      end
    end
  end

  describe '#<<' do
    subject { serial.use timeline }

    context 'with a timeline whose duration is less than that of the serial' do
      let(:timeline) { Dodo::SerialTimeline.new(duration - 1) {} }

      it 'should successfully append the timeline' do
        expect(subject.instance_variable_get(:@timelines)).to eq [timeline]
      end

      it 'should increase the @total_child_duration by the ' \
         'duration of the timeline' do
        expect { subject }.to change {
          serial.instance_variable_get :@total_child_duration
        }.by timeline.duration
      end
    end

    context 'with a timeline whose duration is greater than
             that of the serial' do
      let(:timeline) { Dodo::SerialTimeline.new(duration + 1) {} }

      it 'should successfully append the timeline' do
        expect { subject }.to raise_error(Dodo::WindowDurationExceeded)
      end
    end
  end

  describe '#use' do
    let(:timeline_duration) { 1.day }
    let(:timelines) { build_list :serial, 3, duration: timeline_duration }
    subject { serial.use(*timelines) }

    it 'should successfully append the timelines' do
      expect(subject.instance_variable_get(:@timelines)).to eq timelines
    end

    it 'should increase the @total_child_duration by the ' \
       'duration of the sum of the timeline' do
      expect { subject }.to change {
        serial.instance_variable_get :@total_child_duration
      }.by(timelines.reduce(0) { |sum, timeline| sum + timeline.duration })
    end

    context 'with timelines whose duration is greater than
             that of the serial' do

      let(:timeline_duration) { serial.duration }

      it 'should successfully append the timeline' do
        expect { subject }.to raise_error(Dodo::WindowDurationExceeded)
      end
    end
  end

  describe '#over' do
    let(:child) { Dodo::SerialTimeline.new(duration - 1) {} }

    before do
      allow(serial.class).to receive(:new).and_return child
    end

    subject { serial.over(child.duration, &block) }

    it 'should instantiate a new child' do
      expect(serial.class).to receive(:new) do |dur, &blk|
        expect(dur).to eq child.duration
        expect(blk).to eq block
        child
      end
      subject
    end

    it 'should append the new serial to parent@timelines' do
      expect(serial).to receive(:<<).with(child)
      subject
    end

    it 'should return the child' do
      expect(subject).to eq child
    end
  end

  describe '#please' do
    before do
      allow(Dodo::Moment).to receive(:new).and_return(moment)
    end

    subject { serial.please(&block) }

    it 'should instantiate a new child' do
      expect(Dodo::Moment).to receive(:new) do |&blk|
        expect(blk).to eq block
        moment
      end
      subject
    end

    it 'should append the new serial to serial@timelines' do
      expect(serial).to receive(:<<).with(moment)
      subject
    end

    it 'should return the moment' do
      expect(subject).to eq moment
    end
  end

  describe '#repeat' do
    let(:block) { proc { please { true } } }
    let(:repeat_duration) { duration - 1 }
    let(:k) { 2 }
    let(:params) { { times: k, over: repeat_duration } }

    subject { serial.repeat params, &block }

    context 'with an integer as the :times argument and passing block' do
      it 'should invoke #over once with :repeat_duration as an arg' do
        expect(serial).to receive(:over).with(repeat_duration).once
        subject
      end

      it 'should return a SerialTimeline' do
        expect(subject).to be_a Dodo::SerialTimeline
      end

      it 'should return a serial with two timelines' do
        expect(subject.to_a.size).to be k
      end
    end
  end

  describe '#scheduler' do
    let(:offset) { 2.days.from_now }
    let(:context) { Dodo::Context.new }
    let(:opts) { double }
    subject { serial.scheduler offset, context, opts }
    context 'with opts' do
      it 'should create a new SerialScheduler with opts included' do
        expect(Dodo::SerialScheduler).to receive(:new).with(
          serial, offset, context, opts
        )
        subject
      end
    end
    context 'without opts' do
      subject { serial.scheduler offset, context }
      it 'should create a new SerialScheduler with an empty hash as opts' do
        expect(Dodo::SerialScheduler).to receive(:new).with(
          serial, offset, context, {}
        )
        subject
      end
    end
  end

  describe '#simultaneously' do
    let(:block) { proc { called? } }
    subject { serial.simultaneously(&block) }
    let(:parallel) { Dodo::ParallelTimeline.new }

    before do
      allow(Dodo::ParallelTimeline).to receive(:new).and_return parallel
    end

    it 'should append the parallel to the timeline array' do
      expect { subject }.to change {
        serial.to_a
      }.from([]).to([parallel])
    end

    it 'should evaluate the block passed' do
      expect(Dodo::ParallelTimeline).to receive(:new) do |&blk|
        expect(blk).to eq block
        parallel
      end
      subject
    end
  end

  describe '#+' do
    let(:serial) { build :serial }
    let(:another_serial) { build :serial }

    subject { serial + another_serial }

    it 'should return a serial' do
      expect(subject).to be_a Dodo::SerialTimeline
    end

    it 'should return a new serial whose duration is the sum of the
        two original serial' do
      expect(subject.duration).to eq(
        serial.duration + another_serial.duration
      )
    end

    it 'should return a new serial whose child serial array is a
        concatenation of the child serial arrays of the two original
        serial' do
      expect(subject.to_a).to eq(serial.to_a + another_serial.to_a)
    end
  end

  describe '#*' do
    let(:serial) { build :serial }
    let(:factor) { rand 1..5 }

    subject { serial * factor }

    it 'should return a serial' do
      expect(subject).to be_a Dodo::SerialTimeline
    end

    it 'should return a new serial whose duration is the product of the original
        serial\'s duration and the factor' do
      expect(subject.duration).to eq(
        serial.duration * factor
      )
    end

    it 'should return a new serial whose child serial array is that of the
        original serial concatenated with itself factor times' do
      expect(subject.to_a).to eq(serial.to_a * factor)
    end
  end

  describe '#**' do
    let(:serial) { build :serial }
    let(:factor) { rand 5 }

    subject { serial**factor }

    it 'should return a serial' do
      expect(subject).to be_a Dodo::SerialTimeline
    end

    it 'should return a new serial consisting of a single timeline' do
      expect(subject.size).to eq 1
    end

    it 'should return a new serial consisting of a single timeline' do
      expect(subject.first).to be_a Dodo::ParallelTimeline
    end

    it 'should return a new serial consisting of a single timeline which itself
        consists of the original serial parallelised factor times' do
      expect(
        subject.first.instance_variable_get(:@timelines).map(&:__getobj__)
      ).to eq([serial] * factor)
    end
  end
end
