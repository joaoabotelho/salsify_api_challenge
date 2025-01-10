class FileController < ApplicationController
  def show
    line_number = params[:id].to_i

    unless line_number.positive?
      render json: { error: 'Line number must be greater than 0' }, status: :bad_request
      return
    end
    
    line_content = FILE_PROCESSOR.get_line(line_number)

    if line_content
      render json: { line_number: line_number, content: line_content.strip}
    else
      render json: { error: 'Line number over the limit of the file' }, status: :content_too_large
    end
  end
end