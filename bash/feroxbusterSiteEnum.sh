#!/usr/bin/env bash

###############################################################################
# feroxbuster_wrapper.sh
#
# A simple wrapper to run Feroxbuster against a list of URLs.
# Usage:
#   feroxbuster_wrapper.sh <urls_file> <wordlist> <output_directory>
#   feroxbuster_wrapper.sh --help
###############################################################################

function usage() {
    cat <<EOF
Usage: $0 <urls_file> <wordlist> <output_directory>

This script reads URLs from <urls_file> (one per line) and runs Feroxbuster on each.
The results are saved into <output_directory>.

Arguments:
  <urls_file>        File containing URLs to scan (one per line).
  <wordlist>         Path to the wordlist to use with Feroxbuster.
  <output_directory> Directory to store Feroxbuster scan results.

Options:
  -h, --help         Show this help menu.

Examples:
  $0 urls.txt wordlist.txt results/
  $0 -h
EOF
}

###############################################################################
# Check for --help/-h
###############################################################################
if [[ "$1" == "--help" || "$1" == "-h" ]]; then
    usage
    exit 0
fi

###############################################################################
# Validate argument count
###############################################################################
if [[ $# -ne 3 ]]; then
    echo "Error: Invalid number of arguments."
    usage
    exit 1
fi

urls_file="$1"
wordlist="$2"
output_directory="$3"

###############################################################################
# Check that feroxbuster is installed
###############################################################################
if ! command -v feroxbuster &> /dev/null; then
    echo "Error: feroxbuster is not installed or not in the PATH."
    exit 1
fi

###############################################################################
# Validate input files and directories
###############################################################################
if [[ ! -f "$urls_file" ]]; then
    echo "Error: URLs file '$urls_file' does not exist or is not a regular file."
    exit 1
fi

if [[ ! -f "$wordlist" ]]; then
    echo "Error: Wordlist file '$wordlist' does not exist or is not a regular file."
    exit 1
fi

# Create the output directory if needed
if ! mkdir -p "$output_directory" 2>/dev/null; then
    echo "Error: Unable to create or access directory '$output_directory'."
    exit 1
fi

###############################################################################
# Main loop
###############################################################################
while IFS= read -r url; do
    # Skip empty lines and comments
    if [[ -z "$url" || "$url" =~ ^# ]]; then
        continue
    fi

    echo "Working on URL: $url"
    echo "------------------"

    # Generate output filename by removing protocol from the URL
    outputFile=$(echo "$url" | sed 's|https\?://||')

    # Run Feroxbuster and capture exit code
    feroxbuster \
        --scan-dir-listings \
        -f \
        -k \
        -A \
        --smart \
        -o "$output_directory/$outputFile" \
        -w "$wordlist" \
        -u "$url" \
        --dont-scan '^(https?:\/\/[^\/]+)\/\Index\/.*'

    # Check exit code
    if [[ $? -eq 0 ]]; then
        echo "--- FINISHED $url ---"
    else
        echo "Error: Feroxbuster encountered an issue while scanning $url."
    fi
    echo
done < "$urls_file"

exit 0
