# frozen_string_literal: true

require 'rspec'

RSpec.describe Bonito::Scope do
  let(:parent) { described_class.new nil }
  let(:scope) { described_class.new parent }

  subject { scope }
  describe '#initialize' do
    context 'with a parent context provided' do
      it 'should set the parent' do
        expect(subject.send(:parent)).to be parent
      end
    end
    context 'without a parent context provided' do
      subject { Bonito::Scope.new }
      it 'should set nil as the parent' do
        expect(subject.parent).to be_nil
      end
    end
  end

  describe '#respond_to?' do
    let(:symbol) { :abc }
    subject { scope.respond_to? symbol }

    context 'where the symbol denotes a valid setter' do
      context 'where the symbol denotes a valid setter' do
        let(:symbol) { :abc= }
        it 'should return true' do
          expect(subject).to be true
        end
      end
    end

    context 'where the symbol is not valid' do
      let(:symbol) { :abc? }
      it 'should return false' do
        expect(subject).to be false
      end
    end

    context 'where symbol denotes a valid getter' do
      before { scope.abc = true }
      it 'should return true' do
        expect(subject).to be true
      end
    end
  end

  describe '#set' do
    subject { scope.foo = 'bar' }

    it 'should set the instance var :@foo' do
      subject
      expect(scope.instance_variable_get(:@foo)).to eq 'bar'
    end
  end

  describe '#get' do
    subject { scope.foo }
    context 'where foo is set on the child context only' do
      before { scope.foo = 'bar' }
      it 'should return bar' do
        expect(subject).to eq 'bar'
      end
    end
    context 'where foo is set on the child and parent contexts' do
      before do
        scope.foo = 'bar'
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
    subject { scope.push }
    it 'should return a scope that is a child of the instance' do
      expect(subject.parent).to be scope
    end
  end
end
