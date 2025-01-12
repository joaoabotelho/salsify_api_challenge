require 'file_processor/file_processor'

# frozen_string_literal: true

describe FileProcessor do
  let(:file_path) { 'spec/fixtures/files/test_file.txt' }
  let(:file_processor) { described_class.new(file_path) }

  let(:empty_file_path) { 'spec/fixtures/files/empty_file.txt' }
  let(:empty_file_processor) { described_class.new(empty_file_path) }

  describe '#preprocess' do
    it 'calculates the correct offsets for each line' do\
      file_processor.preprocess
      expect(Rails.cache.read("file_offset_1")).to eq(0)
      expect(Rails.cache.read("file_offset_2")).to eq(7)
      expect(Rails.cache.read("file_offset_3")).to eq(14)
      expect(Rails.cache.read("file_offset_4")).to be_nil
    end

    it 'handles successfully an empty file' do
      empty_file_processor.preprocess
      expect(Rails.cache.read("file_offset_1")).to be_nil
    end
  end

  describe '#get_line' do
    before { file_processor.preprocess }

    it 'returns the correct line content for a valid line number' do
      expect(file_processor.get_line(1)).to eq("Line 1\n")
      expect(file_processor.get_line(2)).to eq("Line 2\n")
      expect(file_processor.get_line(3)).to eq("Line 3\n")
    end

    it 'returns nil for an invalid line number' do
      expect(file_processor.get_line(0)).to be_nil
      expect(file_processor.get_line(4)).to be_nil
    end

    it 'handles successfully an empty file' do
      empty_file_processor.preprocess
      expect(empty_file_processor.get_line(1)).to be_nil
    end
  end
end
