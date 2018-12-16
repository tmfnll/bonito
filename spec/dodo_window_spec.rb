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
    it 'should be an alias for #push_window' do
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

    it 'should append the new window to window@happenings' do
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

      it "should return a Window" do
        expect(subject).to be_a Dodo::Window
      end

      it "should return a window with two happenings" do
        expect(subject.happenings.size).to be k
      end
    end

    context "without a provided :over param" do
      before { params.delete :over}
      it "should invoke #over once with window.unused_duration as an arg" do
        expect(window).to receive(:over).with(window.unused_duration).once
        subject
      end
    end

  end

  describe '#enum' do
    let(:distribution) { double }
    let(:opts) { double }
    subject { window.enum distribution, opts }
    context 'with opts' do
      it 'should create a new WinowEnumerator with opts included' do
        expect(Dodo::WindowEnumerator).to receive(:new).with(window, distribution, opts)
        subject
      end
    end
    context 'without opts' do
      subject { window.enum distribution }
      it 'should create a new WindowEnumerator with an empty hash as opts' do
        expect(Dodo::WindowEnumerator).to receive(:new).with(window, distribution, {})
        subject
      end
    end
  end
end
