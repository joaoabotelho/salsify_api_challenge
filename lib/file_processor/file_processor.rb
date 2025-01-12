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

  # Fetch offsets from cache or preprocess the file in the cache
  def fetch_offsets
    Rails.cache.fetch(@cache_key) do
      preprocess
    end
  end

  # Get a specific line from cache or the file by its number
  def get_line(line_number)
    return nil if line_number <= 0 || line_number > offsets.size

    Rails.cache.fetch("file_line_#{line_number}", expires_in: 5.minutes) do
      get_line_from_file(line_number)
    end
  end

  private

  # Retrieve a specific line from the file by its number
  def get_line_from_file(line_number)
    File.open(file_path, "r") do |file|
      file.seek(offsets[line_number - 1])
      file.readline
    end
  rescue EOFError
    nil
  end

  # Process the file to calculate line offsets
  def preprocess
    line_offsets = []
    File.open(file_path, "r") do |file|
      offset = 0
      file.each_line do |line|
        line_offsets << offset
        offset += line.bytesize
      end
    end
    line_offsets
  end
end
