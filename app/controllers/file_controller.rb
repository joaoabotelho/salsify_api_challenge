class FileController < ApplicationController
  def show
    line_number = validate_line_number(params[:id])
    return unless line_number

    result = fetch_or_cache_line(line_number)
    render json: result
  rescue ActionController::RoutingError => e
    render_error(e.message, :content_too_large)
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
    file_digest = FILE_PROCESSOR.current_checksum # ensures cache invalidation when the file changes
    cache_key = "file_line_#{file_digest}_#{line_number}"

    Rails.cache.fetch(cache_key, expires_in: 1.hour) do
      content = FILE_PROCESSOR.get_line(line_number)
      raise ActionController::RoutingError, "Line not found" if content.nil?

      { line_number: line_number, content: content.strip }
    end
  end

   # Render a JSON error response
   def render_error(message, status)
    render json: { error: message }, status: status
  end
end
