class FileProcessor
  attr_reader :file_path

  def initialize(file_path)
    @file_path = file_path
    @cache_key = "file_offsets"
  end

  # Lazily load offsets
  def offsets
    @offsets ||= fetch_offsets
  end

  # Preprocess the file to calculate line offsets and store them in the cache
  def preprocess
    line_offsets = []
    File.open(file_path, "r") do |file|
      offset = 0
      file.each_line do |line|
        line_offsets << offset
        offset += line.bytesize
      end
    end
    Rails.cache.write(@cache_key, line_offsets, expires_in: 1.hour)
    line_offsets
  end

  # Retrieve a specific line from the file by its number
  def get_line(line_number)
    return nil if line_number <= 0 || line_number > offsets.size

    File.open(file_path, "r") do |file|
      file.seek(offsets[line_number - 1])
      file.readline
    end
  rescue EOFError
    nil
  end

  # Clear the cached offsets
  def clear_cache
    Rails.cache.delete(@cache_key)
  end

  private

  # Fetch offsets from cache or preprocess if necessary
  def fetch_offsets
    Rails.cache.fetch(@cache_key, expires_in: 1.hour) do
      preprocess
    end
  end
end
