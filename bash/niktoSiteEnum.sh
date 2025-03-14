#!/usr/bin/env bash

###############################################################################
# Name: improved_nikto_runner.sh
#
# Description:
#   This script reads a list of URLs from a file and runs nikto against
#   each URL, storing the results in the specified output directory.
#
# Usage:
#   improved_nikto_runner.sh -i <urls_file> -o <output_directory>
#
# Options:
#   -i  Path to file containing URLs (required)
#   -o  Directory to store output files (required)
#   -h  Display this help message and exit
###############################################################################

# Print usage (help) message
usage() {
  echo "Usage: $0 -i <urls_file> -o <output_directory>"
  echo ""
  echo "  -i <urls_file>         Path to file containing URLs to process."
  echo "  -o <output_directory>  Directory to store output files."
  echo "  -h                     Display this help message."
  echo ""
  exit 1
}

# Parse command-line options
while getopts ":i:o:h" opt; do
  case "${opt}" in
    i)
      urls_file="${OPTARG}"
      ;;
    o)
      output_directory="${OPTARG}"
      ;;
    h)
      usage
      ;;
    \?)
      echo "Error: Invalid option -${OPTARG}" >&2
      usage
      ;;
    :)
      echo "Error: Option -${OPTARG} requires an argument." >&2
      usage
      ;;
  esac
done

# Check that required arguments are provided
if [[ -z "$urls_file" || -z "$output_directory" ]]; then
  echo "Error: Missing required argument(s)."
  usage
fi

# Check if the URLs file exists and is readable
if [[ ! -f "$urls_file" ]]; then
  echo "Error: URLs file '$urls_file' does not exist."
  exit 1
fi

if [[ ! -r "$urls_file" ]]; then
  echo "Error: URLs file '$urls_file' is not readable."
  exit 1
fi

# Attempt to create the output directory if it doesn't exist
mkdir -p "$output_directory" 2>/dev/null
if [[ $? -ne 0 ]]; then
  echo "Error: Failed to create or access directory '$output_directory'."
  exit 1
fi

# Try changing to the output directory
cd "$output_directory" 2>/dev/null
if [[ $? -ne 0 ]]; then
  echo "Error: Unable to enter directory '$output_directory'."
  exit 1
fi

# Read each URL from the file and run nikto against it
while IFS= read -r url; do
  # Skip empty lines
  if [[ -z "$url" ]]; then
    continue
  fi

  echo "Working on URL: $url"
  echo "------------------"

  # Remove any "http://" or "https://" from the URL to create an output filename
  output_file="$(echo "$url" | sed 's|https\?://||')"

  # Call nikto; adjust path as necessary
  ../program/nikto.pl -h "$url" | tee "$output_file"

  if [[ $? -eq 0 ]]; then
    echo "--- FINISHED $url ---"
  else
    echo "Error occurred with nikto for $url."
  fi
  echo

done < "$urls_file"

echo "All URLs processed. Results are in: $output_directory"
exit 0
