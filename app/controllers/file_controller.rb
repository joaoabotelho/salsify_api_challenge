class FileController < ApplicationController
  def show
    line_number = validate_line_number(params[:id])
    return unless line_number

    content = FILE_PROCESSOR.get_line(line_number)
    return render_error("Line #{line_number} not found", :content_too_large) unless content

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

  # Render a JSON error response
  def render_error(message, status)
    render json: { error: message }, status: status
  end
end
