class FileProcessor
  attr_reader :offsets

  def initialize(file_path)
    @file_path = file_path
    @offsets = []
  end

  def preprocess
    File.open(@file_path, "r") do |file|
      file.each_line.with_index do |_, index|
        @offsets[index] = file.pos
      end
    end
  end

  def get_line(line_number)
    return nil if line_number <= 0 || line_number > @offsets.size    

    offset_index = line_number - 1

    File.open(@file_path, "r") do |file|
      start_offset = if offset_index > 0 then offsets[offset_index - 1] else 0 end
      end_offset = offsets[offset_index] || file.size # Handle last line case

      file.seek(start_offset)
      file.read(end_offset - start_offset)
    end
  rescue EOFError
    nil
  end
end