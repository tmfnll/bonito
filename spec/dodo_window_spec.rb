# frozen_string_literal: true

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
      subject { Dodo::Window.new duration }
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
    subject { window.use timeline }

    context 'with a timeline whose duration is less than that of the window' do
      let(:timeline) { Dodo::Window.new(duration - 1) {} }

      it 'should successfully append the timeline' do
        expect(subject.instance_variable_get(:@timelines)).to eq [timeline]
      end

      it 'should increase the @total_child_duration by the ' \
         'duration of the timeline' do
        expect { subject }.to change {
          window.instance_variable_get :@total_child_duration
        }.by timeline.duration
      end
    end

    context 'with a timeline whose duration is greater than
             that of the window' do
      let(:timeline) { Dodo::Window.new(duration + 1) {} }

      it 'should successfully append the timeline' do
        expect { subject }.to raise_error(Dodo::WindowDurationExceeded)
      end
    end
  end

  describe '#use' do
    let(:timeline_duration) { 1.day }
    let(:timelines) { build_list :window, 3, duration: timeline_duration }
    subject { window.use(*timelines) }

    it 'should successfully append the timelines' do
      expect(subject.instance_variable_get(:@timelines)).to eq timelines
    end

    it 'should increase the @total_child_duration by the ' \
       'duration of the sum of the timeline' do
      expect { subject }.to change {
        window.instance_variable_get :@total_child_duration
      }.by(timelines.reduce(0) { |sum, timeline| sum + timeline.duration })
    end

    context 'with timelines whose duration is greater than
             that of the window' do

      let(:timeline_duration) { window.duration }

      it 'should successfully append the timeline' do
        expect { subject }.to raise_error(Dodo::WindowDurationExceeded)
      end
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

    it 'should append the new window to parent@timelines' do
      expect(window).to receive(:<<).with(child)
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

    subject { window.please(&block) }

    it 'should instantiate a new child' do
      expect(Dodo::Moment).to receive(:new) do |&blk|
        expect(blk).to eq block
        moment
      end
      subject
    end

    it 'should append the new window to window@timelines' do
      expect(window).to receive(:<<).with(moment)
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

    subject { window.repeat params, &block }

    context 'with an integer as the :times argument and passing block' do
      it 'should invoke #over once with :repeat_duration as an arg' do
        expect(window).to receive(:over).with(repeat_duration).once
        subject
      end

      it 'should return a Window' do
        expect(subject).to be_a Dodo::Window
      end

      it 'should return a window with two timelines' do
        expect(subject.to_a.size).to be k
      end
    end
  end

  describe '#scheduler' do
    let(:offset) { 2.days.from_now }
    let(:context) { Dodo::Context.new }
    let(:opts) { double }
    subject { window.scheduler offset, context, opts }
    context 'with opts' do
      it 'should create a new WindowScheduler with opts included' do
        expect(Dodo::WindowScheduler).to receive(:new).with(
          window, offset, context, opts
        )
        subject
      end
    end
    context 'without opts' do
      subject { window.scheduler offset, context }
      it 'should create a new WindowScheduler with an empty hash as opts' do
        expect(Dodo::WindowScheduler).to receive(:new).with(
          window, offset, context, {}
        )
        subject
      end
    end
  end

  describe '#simultaneously' do
    let(:block) { proc { called? } }
    subject { window.simultaneously(&block) }
    let(:container) { Dodo::Container.new }

    before do
      allow(Dodo::Container).to receive(:new).and_return container
    end

    it 'should append the container to the timeline array' do
      expect { subject }.to change {
        window.to_a
      }.from([]).to([container])
    end

    it 'should evaluate the block passed' do
      expect(Dodo::Container).to receive(:new) do |&blk|
        expect(blk).to eq block
        container
      end
      subject
    end
  end

  describe '#+' do
    let(:window) { build :window }
    let(:another_window) { build :window }

    subject { window + another_window }

    it 'should return a window' do
      expect(subject).to be_a Dodo::Window
    end

    it 'should return a new window whose duration is the sum of the
        two original window' do
      expect(subject.duration).to eq(
        window.duration + another_window.duration
      )
    end

    it 'should return a new window whose child window array is a
        concatenation of the child window arrays of the two original
        window' do
      expect(subject.to_a).to eq(window.to_a + another_window.to_a)
    end
  end

  describe '#*' do
    let(:window) { build :window }
    let(:factor) { rand 1..5 }

    subject { window * factor }

    it 'should return a window' do
      expect(subject).to be_a Dodo::Window
    end

    it 'should return a new window whose duration is the product of the original
        window\'s duration and the factor' do
      expect(subject.duration).to eq(
        window.duration * factor
      )
    end

    it 'should return a new window whose child window array is that of the
        original window concatenated with itself factor times' do
      expect(subject.to_a).to eq(window.to_a * factor)
    end
  end

  describe '#**' do
    let(:window) { build :window }
    let(:factor) { rand 5 }

    subject { window**factor }

    it 'should return a window' do
      expect(subject).to be_a Dodo::Window
    end

    it 'should return a new window consisting of a single timeline' do
      expect(subject.size).to eq 1
    end

    it 'should return a new window consisting of a single timeline' do
      expect(subject.first).to be_a Dodo::Container
    end

    it 'should return a new window consisting of a single timeline which itself
        consists of the original window parallelised factor times' do
      expect(
        subject.first.instance_variable_get(:@timelines).map(&:__getobj__)
      ).to eq([window] * factor)
    end
  end
end
