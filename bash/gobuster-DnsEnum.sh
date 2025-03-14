#!/usr/bin/env bash

#############################################
# Gobuster Automation Script
# Author: Your Name
# Description:
#   This script automates running gobuster against
#   a list of domains using a specified wordlist.
# Usage:
#   ./gobuster_script.sh -d domains.txt -w wordlist.txt -o output_dir
#############################################

# Print help menu
usage() {
    echo "Usage: $0 [options]"
    echo "  -d <domain list file>"
    echo "  -w <word list file>"
    echo "  -o <output directory>"
    echo "  -h Show this help message"
    echo
    echo "Example:"
    echo "  $0 -d domains.txt -w wordlist.txt -o results_dir"
    exit 1
}

# Parse command line arguments
while getopts "d:w:o:h" opt; do
    case "$opt" in
        d) domainList="$OPTARG" ;;
        w) wordList="$OPTARG" ;;
        o) outputDirectory="$OPTARG" ;;
        h) usage ;;
        ?) usage ;;
    esac
done

# Check if required arguments are provided
if [[ -z "$domainList" || -z "$wordList" || -z "$outputDirectory" ]]; then
    echo "Error: Missing required argument(s)."
    usage
fi

# Verify the domain list file exists
if [[ ! -f "$domainList" ]]; then
    echo "Error: Domain list file '$domainList' does not exist."
    exit 1
fi

# Verify the word list file exists
if [[ ! -f "$wordList" ]]; then
    echo "Error: Word list file '$wordList' does not exist."
    exit 1
fi

# Check if gobuster is installed
if ! command -v gobuster &> /dev/null; then
    echo "Error: 'gobuster' is not installed or not in PATH."
    exit 1
fi

# Attempt to create output directory if it doesn't exist
if ! mkdir -p "$outputDirectory"; then
    echo "Error: Failed to create output directory '$outputDirectory'."
    exit 1
fi

# Process the domain list
while IFS= read -r host; do
    # Skip empty lines
    [[ -z "$host" ]] && continue

    echo "Working on domain: $host"
    echo "--------------------------------"

    # Remove any "http://" or "https://" from the domain
    cleanHost=$(echo "$host" | sed 's|https\?://||')

    echo "Output directory: $outputDirectory"
    echo "Domain: $host"

    # Run gobuster command
    gobuster dns -o "$outputDirectory/$cleanHost" -w "$wordList" -d "$host" -c -i
    exitCode=$?

    if [[ $exitCode -eq 0 ]]; then
        echo "Finished processing: $host"
    else
        echo "Error: gobuster failed for domain '$host' (exit code: $exitCode)"
    fi

    echo
done < "$domainList"
