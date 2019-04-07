# frozen_string_literal: true

require 'rspec'

RSpec.shared_examples 'a moment scheduler' do
  let(:starting_offset) { rand(10).days }
  let(:opts) { double }
  let(:scope) { Dodo::Scope.new }
  subject { timeline.scheduler starting_offset, scope, opts }
  context 'with opts' do
    it 'should create a new MomentScheduler with opts included' do
      expect(described_class.scheduler_class).to receive(:new).with(
        timeline, starting_offset, scope, opts
      )
      subject
    end
  end
  context 'without opts' do
    subject { timeline.scheduler starting_offset, scope }
    it 'should create a new MomentScheduler with an empty hash as opts' do
      expect(described_class.scheduler_class).to receive(:new).with(
        timeline, starting_offset, scope, {}
      )
      subject
    end
  end
end
