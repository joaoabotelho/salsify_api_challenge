require 'rails_helper'

# frozen_string_literal: true

describe FileController, type: :controller do
  let(:file_path) { 'spec/fixtures/files/test_file.txt' }

  before do
    # Preprocess the file and set it up as the global FILE_PROCESSOR
    @file_processor = FileProcessor.new(file_path)
    @file_processor.preprocess
    stub_const('FILE_PROCESSOR', @file_processor)
  end

  describe 'GET #show' do
    it 'returns the correct line content for a valid line number' do
      get :show, params: { id: 1 }
      expect(response).to have_http_status(:ok)
      expect(JSON.parse(response.body)).to eq({
        'line_number' => 1,
        'content' => 'Line 1'
      })
    end

    it 'returns a 400 error for an invalid line number' do
      get :show, params: { id: 0 }
      expect(response).to have_http_status(:bad_request)
      expect(JSON.parse(response.body)).to eq({
        'error' => 'Line number must be greater than 0'
      })

      get :show, params: { id: 'a' }
      expect(response).to have_http_status(:bad_request)
      expect(JSON.parse(response.body)).to eq({
        'error' => 'Line number must be greater than 0'
      })
    end

    it 'returns a 413 error for a line number over the EOF' do
      get :show, params: { id: 4 }
      expect(response).to have_http_status(:content_too_large)
      expect(JSON.parse(response.body)).to eq({
        'error' => 'Line not found'
      })
    end

    it 'returns a 413 error with an empty file' do
      empty_tmp_file_path = 'spec/fixtures/files/empty_file.txt'
      file_processor = FileProcessor.new(empty_tmp_file_path)
      file_processor.preprocess
      stub_const('FILE_PROCESSOR', file_processor)

      get :show, params: { id: 1 }
      expect(response).to have_http_status(:content_too_large)
      expect(JSON.parse(response.body)).to eq({
        'error' => 'Line not found'
      })
    end

    it 'caches the response for a valid line number' do
      get :show, params: { id: 1 }
      expect(Rails.cache.read("file_line_1")).to eq({
        line_number: 1,
        content: 'Line 1'
      })
    end
  end
end
