require 'spec_helper'

describe Morph::LineBuffer do
  let(:buffer) { Morph::LineBuffer.new }

  context 'nothing buffered' do
    describe '#extract' do
      it do
        lines = []
        buffer.extract { |line| lines << line }
        expect(lines).to eq []
      end

      it { expect(buffer.extract).to eq [] }
    end
  end

  context 'less than one line' do
    before(:each) { buffer << 'hello' }

    describe '#extract' do
      it do
        lines = []
        buffer.extract { |line| lines << line }
        expect(lines).to eq []
      end

      it { expect(buffer.extract).to eq [] }
    end

    describe '#finish' do
      it { expect(buffer.finish).to eq 'hello' }

      it 'should empty the buffer' do
        buffer.finish
        expect(buffer.finish).to eq ''
      end
    end
  end

  context 'one and a bit lines' do
    before(:each) { buffer << "hello\nfoo" }

    describe '#extract' do
      it do
        lines = []
        buffer.extract { |line| lines << line }
        expect(lines).to eq ["hello\n"]
      end

      it { expect(buffer.extract).to eq ["hello\n"] }
    end

    describe '#finish' do
      it do
        buffer.extract
        expect(buffer.finish).to eq 'foo'
      end

      it do
        expect { buffer.finish }.to raise_error
      end
    end
  end
end
