require 'file_processor/file_processor'

# frozen_string_literal: true

describe FileProcessor do
  let(:file_content) { "Line 1\nLine 2\nLine 3\n" }
  let(:file_path) do
    # Create a temporary file with test content
    tmp_file = Tempfile.new('test_file')
    tmp_file.write(file_content)
    tmp_file.rewind
    tmp_file.path
  end
  let(:file_processor) { described_class.new(file_path) }

  let(:empty_file_path) do
    empty_tmp_file = Tempfile.new('empty_file')
    empty_tmp_file.write("")
    empty_tmp_file.rewind
    empty_tmp_file.path
  end
  let(:empty_file_processor) { described_class.new(empty_file_path) }

  describe 'preprocess' do
    it 'calculates the correct offsets for each line' do\
      file_processor.preprocess
      expect(file_processor.offsets).to eq([ 0, 7, 14 ])
    end

    it 'handles successfully an empty file' do
      empty_file_processor.preprocess
      expect(empty_file_processor.offsets).to eq([])
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

  describe 'Caching' do
    it 'stores offsets in cache after preprocessing' do
      file_processor.preprocess
      expect(Rails.cache.read("file_offsets_#{Digest::SHA256.hexdigest(file_path)}")).to eq([ 0, 7, 14 ])
    end

    it 'clears cache when calling clear_cache' do
      file_processor.preprocess
      file_processor.clear_cache
      expect(Rails.cache.read("file_offsets_#{Digest::SHA256.hexdigest(file_path)}")).to be_nil
    end
  end
end
