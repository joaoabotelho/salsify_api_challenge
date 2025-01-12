require 'rails_helper'

# frozen_string_literal: true

describe FileCache do
  describe '#write_offset' do
    it 'writes to cache successfully' do\
      described_class.write_offset(1, 1)
      expect(Rails.cache.read("file_offset_1")).to eq(1)
    end
  end

  describe '#write_total_lines' do
    it 'writes to cache successfully' do\
      described_class.write_total_lines(1)
      expect(Rails.cache.read("file_total_lines")).to eq(1)
    end
  end

  describe '#fetch_line' do
    before do
      Rails.cache.write("file_total_lines", 100)
    end

    context 'when the line is cached' do
      it 'fetches from cache successfully' do
        Rails.cache.write("file_line_1", "Hello World")
        expect(described_class.fetch_line(1)).to eq("Hello World")
      end
    end

    context 'when the line is not cached' do
      it 'fetches the line using fetch_offset and mocks get_line_from_file' do
        # Stub fetch_offset to return a specific offset
        allow(described_class).to receive(:fetch_offset).with(1).and_return(100)

        # Mock FileProcessor.get_line_from_file to return a specific string
        allow(FileProcessor).to receive(:get_line_from_file).with(100).and_return("Mocked line content")

        # Now test fetch_line
        result = described_class.fetch_line(1)

        expect(result).to eq("Mocked line content")
        expect(FileProcessor).to have_received(:get_line_from_file).with(100)
        expect(described_class).to have_received(:fetch_offset).with(1)
      end
    end
  end
end
