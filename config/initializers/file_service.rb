require "file_processor/file_processor"

FILE_PROCESSOR = FileProcessor.new(Rails.application.config.file_path)
FILE_PROCESSOR.preprocess
