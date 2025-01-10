require 'rails_helper'
require 'tmpdir'

# frozen_string_literal: true

describe FileController, type: :controller do
  let(:file_content) { "Line 1\nLine 2\nLine 3\n" }
  let(:file_path) do
    # Create a temporary file with test content
    tmp_file = Tempfile.new('test_file')
    tmp_file.write(file_content)
    tmp_file.rewind
    tmp_file.path
  end

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
        'error' => 'Line number over the limit of the file'
      })
    end

    it 'returns a 413 error with an empty file' do
      empty_tmp_file = Tempfile.new('empty_file')
      empty_tmp_file.write("")
      empty_tmp_file.rewind
      empty_tmp_file_path = empty_tmp_file.path
      file_processor = FileProcessor.new(empty_tmp_file_path)
      file_processor.preprocess
      stub_const('FILE_PROCESSOR', file_processor)

      get :show, params: { id: 1 }
      expect(response).to have_http_status(:content_too_large)
      expect(JSON.parse(response.body)).to eq({
        'error' => 'Line number over the limit of the file'
      })
    end
  end
end
