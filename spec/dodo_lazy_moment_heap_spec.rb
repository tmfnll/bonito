# frozen_string_literal: true

require 'rspec'

RSpec.describe Dodo::LazyMinHeap do
  let(:arrays) do
    Array.new(rand(2..5)) { Array.new(rand(1..5)) { rand 100 }.sort }
  end
  let(:enums) { arrays.map(&:to_enum) }

  let(:heap) { described_class.new(*enums) }

  describe '#initialize' do
    subject { heap }

    it "the internal MinHeap should contain precisely the same number of
        items as enums added" do
      expect(subject.instance_variable_get(:@heap).size).to eq enums.size
    end

    it 'should ensure precisely 1 item is retieved from each enum' do
      enums.each do |enum|
        expect(enum).to receive(:next).with(no_args).and_return(double).once
      end
      subject
    end
  end

  describe '#pop' do
    subject { heap.pop }

    it 'should return the minumum value across all enums' do
      expected = enums.map { |enum| enum.dup.min }.min
      expect(subject).to eq expected
    end
  end

  describe '#each' do
    subject { heap.to_a }

    it 'should return an array of items sorted low ot high' do
      expect(subject).to eq arrays.flatten.sort
    end

    it 'should ensure that there are never more than enums.size items in the
        internal MinHeap' do
      heap.each do
        expect(heap.instance_variable_get(:@heap).size).to be <= enums.size
      end
    end
  end
end
