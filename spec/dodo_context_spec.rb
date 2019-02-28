# frozen_string_literal: true

require 'rspec'

RSpec.describe Dodo::Context do
  let(:parent) { described_class.new nil }
  let(:context) { described_class.new parent }

  subject { context }
  describe '#initialize' do
    context 'with a parent context provided' do
      it 'should set the parent' do
        expect(subject.send(:parent)).to be parent
      end
    end
    context 'without a parent context provided' do
      subject { Dodo::Context.new }
      it 'should set nil as the parent' do
        expect(subject.parent).to be_nil
      end
    end
  end

  describe '#set' do
    subject { context.foo = 'bar' }

    it 'should set the instance var :@foo' do
      subject
      expect(context.instance_variable_get(:@foo)).to eq 'bar'
    end
  end

  describe '#get' do
    subject { context.foo }
    context 'where foo is set on the child context only' do
      before { context.foo = 'bar' }
      it 'should return bar' do
        expect(subject).to eq 'bar'
      end
    end
    context 'where foo is set on the child and parent contexts' do
      before do
        context.foo = 'bar'
        parent.foo = 'baz'
      end
      it 'should return bar' do
        expect(subject).to eq 'bar'
      end
    end
    context 'where foo is set on the parent context only' do
      before { parent.foo = 'bar' }
      it 'should return bar' do
        expect(subject).to eq 'bar'
      end
    end
    context 'when foo has not been set on any context' do
      it 'should raise NoMethodError' do
        expect { subject }.to raise_exception(NoMethodError)
      end
    end
  end

  describe '#push' do
    subject { context.push }
    it 'should return a context that is a child of the instance' do
      expect(subject.parent).to be context
    end
  end
end
