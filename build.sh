#!/bin/bash

# Exit on any error
set -e

# Check if Ruby is installed
if ! command -v ruby &> /dev/null; then
  echo "Error: Ruby is not installed. Please install Ruby before running this script."
  exit 1
fi

# Display Ruby version
ruby_version=$(ruby -v)
echo "Ruby is installed: $ruby_version"

# Check if Bundler is installed
if ! gem list bundler -i &> /dev/null; then
  echo "Bundler is not installed. Installing Bundler..."
  gem install bundler
else
  echo "Bundler is already installed."
fi

# Run bundle install
echo "Running bundle install..."
bundle install
echo "Dependencies successfully installed."