class FileController < ApplicationController
  def show
    line_number = validate_line_number(params[:id])
    return unless line_number

    content = fetch_or_cache_line(line_number)
    if content.nil?
      render_error("Line #{line_number} not found", :content_too_large)
      return nil
    end

    render json: { line_number: line_number, content: content.strip }
  end

  private

  # Validate the line number parameter
  def validate_line_number(line_param)
    line_number = line_param.to_i
    if line_number <= 0
      render_error("Line number must be greater than 0", :bad_request)
      return nil
    end
    line_number
  end

  # Fetch the line content from cache or file processor
  def fetch_or_cache_line(line_number)
    cache_key = "file_line_#{line_number}"

    Rails.cache.fetch(cache_key, expires_in: 5.minutes) do
      FILE_PROCESSOR.get_line(line_number)
    end
  end

  # Render a JSON error response
  def render_error(message, status)
    render json: { error: message }, status: status
  end
end
