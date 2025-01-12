require "files/file_cache"

class FileProcessor
  # Process the file to calculate line offset and cache it
  def self.preprocess(file_path: Rails.application.config.file_path)
    offset = 0
    line_count = 0

    File.open(file_path, "r") do |file|
      file.each_line.with_index(1) do |line, line_number|
        FileCache.write_offset(line_number, offset)
        offset += line.bytesize
        line_count = line_number
      end
    end

    FileCache.write_total_lines(line_count)
    line_count
  end

  # Retrieve a specific line from the file by its offset
  def self.get_line_from_file(offset, file_path: Rails.application.config.file_path)
    File.open(file_path, "r") do |file|
      file.seek(offset)
      file.readline
    end
  rescue EOFError
    nil
  end
end
