class FileCache
  # Write line offset to the cache
  def self.write_offset(line_number, offset)
    Rails.cache.write("file_offset_#{line_number}", offset)
  end

  def self.write_total_lines(total_lines)
    Rails.cache.write("file_total_lines", total_lines)
  end

  # Cache the line content for a specific line number
  def self.fetch_line(line_number, expires_in: 5.minutes)
    return nil if line_number <= 0 || line_number > total_lines

    Rails.cache.fetch("file_line_#{line_number}", expires_in: expires_in) do
      offset = fetch_offset(line_number)
      FileProcessor.get_line_from_file(offset)
    end
  end

  private

  # Fetch total file lines from the cache
  def self.total_lines
    Rails.cache.fetch("file_total_lines") do
      FileProcessor.preprocess
    end
  end

  # Fetch line offset from the cache
  def self.fetch_offset(line_number)
     offset = Rails.cache.read("file_offset_#{line_number}")

     if offset.nil?
       FileProcessor.preprocess
       offset = Rails.cache.read("file_offset_#{line_number}")
     end

     offset
  end
end
