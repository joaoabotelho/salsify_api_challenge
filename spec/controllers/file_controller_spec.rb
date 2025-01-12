require 'rails_helper'

# frozen_string_literal: true

describe FileController, type: :controller do
  describe 'GET #show with test file' do
    before do
      Rails.application.config.file_path = "spec/fixtures/files/test_file.txt"
    end

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
        'error' => 'Line 4 not found'
      })
    end
  end

  describe 'GET #show with empty file' do
    before do
      Rails.application.config.file_path = "spec/fixtures/files/empty_file.txt"
    end

    it 'returns a 413 error with an empty file' do
      get :show, params: { id: 1 }
      expect(response).to have_http_status(:content_too_large)
      expect(JSON.parse(response.body)).to eq({
        'error' => 'Line 1 not found'
      })
    end
  end
end
