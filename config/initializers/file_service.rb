require "files/file_processor"

# Only run preprocess in non-test environments
unless Rails.env.test?
  FileProcessor.preprocess
end
