#!/usr/bin/env bash

################################################################################
# Name: run_crt.sh
# Description:
#   1. Checks if we are in a directory called "crt.sh" or if there is a .git
#      directory present. If both are missing, clones the "crt.sh" repository
#      and cd's into it.
#   2. Loops over a text file of domains and runs './crt.sh -d <domain>'.
# Usage:
#   ./run_crt.sh -f domains.txt
# Options:
#   -f, --file     Path to the file containing the list of domains
#   -h, --help     Display this help menu
################################################################################

function show_help() {
  echo "Usage: $0 [options]"
  echo "Options:"
  echo "  -f, --file FILE   Path to the file containing the list of domains"
  echo "  -h, --help        Show this help menu"
}

# --- STEP 1: Ensure we're in the crt.sh directory or have a .git directory ---
DIR_NAME="$(basename "$PWD")"

if [[ "$DIR_NAME" != "crt.sh" && ! -d .git ]]; then
  echo "Neither directory 'crt.sh' nor a .git folder found."
  echo "Cloning crt.sh repository from GitHub..."
  git clone https://github.com/az7rb/crt.sh
  cd crt.sh || {
    echo "Error: Failed to enter 'crt.sh' directory. Exiting."
    exit 1
  }
fi

# --- STEP 2: Parse command-line arguments ---
FILE=""

while [[ $# -gt 0 ]]; do
  case "$1" in
    -f|--file)
      FILE="$2"
      shift 2
      ;;
    -h|--help)
      show_help
      exit 0
      ;;
    *)
      echo "Error: Unknown option '$1'"
      show_help
      exit 1
      ;;
  esac
done

# --- STEP 3: Validate the file argument ---
if [[ -z "$FILE" ]]; then
  echo "Error: No file specified."
  show_help
  exit 1
fi

if [[ ! -f "$FILE" ]]; then
  echo "Error: The file '$FILE' does not exist."
  exit 1
fi

# --- STEP 4: Loop through the file and run './crt.sh -d <domain>' ---
while IFS= read -r domain || [[ -n "$domain" ]]; do
  # Skip empty lines
  [[ -z "$domain" ]] && continue

  echo "Running: ./crt.sh -d ${domain}"
  ./crt.sh -d "${domain}"
done < "$FILE"
