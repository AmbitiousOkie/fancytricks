#!/bin/bash

# Function to display help menu
usage() {
    echo "Usage: $0 -a <fileA> -b <fileB>"
    echo "Description: Reads each line from fileA and iterates over lines in fileB."
    echo
    echo "Options:"
    echo "  -a <fileA>   Specify the first input file"
    echo "  -b <fileB>   Specify the second input file"
    echo "  -h           Show this help menu"
    exit 1
}

# Error handling: Check if required arguments are provided
if [[ $# -eq 0 ]]; then
    echo "Error: No arguments provided."
    usage
fi

# Parse command-line options
while getopts "a:b:h" opt; do
    case $opt in
        a) fileA="$OPTARG" ;;
        b) fileB="$OPTARG" ;;
        h) usage ;;
        *) echo "Invalid option"; usage ;;
    esac
done

# Ensure both files are specified
if [[ -z "$fileA" || -z "$fileB" ]]; then
    echo "Error: Both fileA and fileB must be specified."
    usage
fi

# Ensure both files exist and are readable
if [[ ! -r "$fileA" ]]; then
    echo "Error: File '$fileA' does not exist or is not readable."
    exit 1
fi

if [[ ! -r "$fileB" ]]; then
    echo "Error: File '$fileB' does not exist or is not readable."
    exit 1
fi

# Process files
while IFS= read -r lineA; do
    echo "Processing File A: $lineA"
    
    while IFS= read -r lineB; do
        echo "  File B: $lineB"
    done < "$fileB"

done < "$fileA"
