class FileController < ApplicationController
  def show
    line_number = params[:id].to_i

    file_path = Rails.application.config.file_path
    line_content = read_line(file_path, line_number)

    if line_content
      render json: { line_number: line_number, content: line_content.strip}
    else
      render json: { error: 'Line not found' }, status: :not_found
    end
  end

  private

  def read_line(file_path, line_number)
    return nil unless File.exist?(file_path)

    File.foreach(file_path).with_index(1) do |line, index|
      return line if index == line_number
    end
    nil
  end
end