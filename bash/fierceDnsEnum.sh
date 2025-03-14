#!/usr/bin/env bash

# Exit immediately on uninitialized variable or error
set -o nounset
set -o errexit
set -o pipefail

# Function: Display usage/help menu
usage() {
  echo "Usage: $0 [-h] -f <hosts_file> -o <output_directory>"
  echo
  echo "  -h                  Display this help menu and exit."
  echo "  -f <hosts_file>     Path to the file containing a list of hosts."
  echo "  -o <output_dir>     Directory to store output results."
  echo
  echo "Example:"
  echo "  $0 -f hosts.txt -o results"
  exit 1
}

# Check if dnsrecon is installed
if ! command -v dnsrecon &> /dev/null; then
  echo "Error: 'dnsrecon' command not found. Please install dnsrecon before running this script."
  exit 1
fi

# Parse command-line arguments
HOSTS=""
OUTPUT_DIR=""

while getopts ":hf:o:" opt; do
  case $opt in
    h)
      usage
      ;;
    f)
      HOSTS="$OPTARG"
      ;;
    o)
      OUTPUT_DIR="$OPTARG"
      ;;
    \?)
      echo "Error: Invalid option -$OPTARG" >&2
      usage
      ;;
    :)
      echo "Error: Option -$OPTARG requires an argument." >&2
      usage
      ;;
  esac
done

# Verify that necessary arguments are provided
if [[ -z "$HOSTS" || -z "$OUTPUT_DIR" ]]; then
  echo "Error: Missing required arguments."
  usage
fi

# Check whether the hosts file exists
if [[ ! -f "$HOSTS" ]]; then
  echo "Error: Hosts file '$HOSTS' does not exist."
  exit 1
fi

# Create the output directory if it doesn't exist
mkdir -p "$OUTPUT_DIR"

# Read the hosts file line-by-line
while IFS= read -r host; do
  # Skip empty lines in the hosts file
  if [[ -z "$host" ]]; then
    continue
  fi

  echo "Working on host: $host"
  echo "----------------------"
  echo "Output directory: $OUTPUT_DIR"
  echo "Domain: $host"

  # Run dnsrecon
  dnsrecon -s -a -k -z -b -d "$host" -c "$OUTPUT_DIR/$host.csv"
  if [[ $? -eq 0 ]]; then
    echo "--- FINISHED $host ---"
  else
    echo "Error occurred while running dnsrecon for host: $host"
  fi

  echo
done < "$HOSTS"
