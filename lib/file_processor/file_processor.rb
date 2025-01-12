class FileProcessor
  attr_reader :file_path

  def initialize(file_path)
    @file_path = file_path
    @line_count = 0
  end

  # Process the file to calculate line offsets
  def preprocess
    offset = 0
    @line_count = 0

    File.open(file_path, "r") do |file|
      file.each_line.with_index(1) do |line, line_number|
        Rails.cache.write("file_offset_#{line_number}", offset)
        offset += line.bytesize
        @line_count = line_number
      end
    end
  end

  # Get a specific line from cache or the file by its number
  def get_line(line_number)
    return nil if line_number <= 0 || line_number > @line_count

    Rails.cache.fetch("file_line_#{line_number}", expires_in: 5.minutes) do
      get_line_from_file(line_number)
    end
  end

  private

  # Retrieve a specific line from the file by its number
  def get_line_from_file(line_number)
    offset = fetch_offset(line_number)

    File.open(file_path, "r") do |file|
      file.seek(offset)
      file.readline
    end
  rescue EOFError
    nil
  end

  def fetch_offset(line_number)
    Rails.cache.fetch("file_offset_#{line_number}") do
      preprocess
    end
  end
end
