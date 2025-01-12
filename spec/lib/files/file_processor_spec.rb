require 'files/file_processor'
require 'rails_helper'

# frozen_string_literal: true

describe FileProcessor do
  let(:file_path) { 'spec/fixtures/files/test_file.txt' }

  let(:empty_file_path) { 'spec/fixtures/files/empty_file.txt' }

  describe '#preprocess' do
    it 'calculates the correct offsets for each line' do\
      expect(described_class.preprocess(file_path: file_path)).to eq(3)
      expect(Rails.cache.read("file_offset_1")).to eq(0)
      expect(Rails.cache.read("file_offset_2")).to eq(7)
      expect(Rails.cache.read("file_offset_3")).to eq(14)
      expect(Rails.cache.read("file_offset_4")).to be_nil
    end

    it 'handles successfully an empty file' do
      expect(described_class.preprocess(file_path: empty_file_path)).to eq(0)
      expect(Rails.cache.read("file_offset_1")).to be_nil
    end
  end

  describe '#get_line_from_file' do
    it 'returns the correct line content for a valid offset number' do
      expect(described_class.get_line_from_file(0, file_path: file_path)).to eq("Line 1\n")
      expect(described_class.get_line_from_file(7, file_path: file_path)).to eq("Line 2\n")
      expect(described_class.get_line_from_file(14, file_path: file_path)).to eq("Line 3\n")
    end

    it 'returns nil for an EOF offset number' do
      expect(described_class.get_line_from_file(50, file_path: file_path)).to be_nil
    end

    it 'handles successfully an empty file' do
      expect(described_class.get_line_from_file(0, file_path: empty_file_path)).to be_nil
    end
  end
end
