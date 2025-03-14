#!/usr/bin/env bash

###############################################################################
# Script Name  : gobuster_vhost_scan.sh
# Description  : Runs gobuster against a list of URLs and a wordlist for
#                virtual hosts. Outputs results to the specified directory.
# Usage        : ./gobuster_vhost_scan.sh -u <url-list-file> -w <vhost-wordlist> -o <output-directory>
# Example      : ./gobuster_vhost_scan.sh -u urls.txt -w vhost_words.txt -o ./results
###############################################################################

# Display the usage/help menu
usage() {
    cat <<EOF
Usage: $0 -u <url-list-file> -w <vhost-wordlist> -o <output-directory> [options]

This script runs 'gobuster vhost' using a list of URLs and a virtual host
wordlist. Results are written to the specified output directory.

Required Arguments:
  -u  Path to a file containing URLs (one per line)
  -w  Path to a file containing a list of virtual host words
  -o  Directory for storing gobuster output

Options:
  -h, --help   Show this help message and exit

Examples:
  $0 -u urls.txt -w vhost_words.txt -o ./results
EOF
}

###############################################################################
# Parse command-line arguments
###############################################################################
urlList=""
vhostWordList=""
outputDirectory=""

# Use getopts to parse flags
while getopts ":u:w:o:h-:" opt; do
    case "${opt}" in
        u)
            urlList="${OPTARG}"
            ;;
        w)
            vhostWordList="${OPTARG}"
            ;;
        o)
            outputDirectory="${OPTARG}"
            ;;
        h)
            usage
            exit 0
            ;;
        -)
            # Long option support: e.g., --help
            case "${OPTARG}" in
                help)
                    usage
                    exit 0
                    ;;
                *)
                    echo "Error: Invalid option '--${OPTARG}'"
                    usage
                    exit 1
                    ;;
            esac
            ;;
        \?)
            echo "Error: Invalid option '-${OPTARG}'"
            usage
            exit 1
            ;;
        :)
            echo "Error: Option '-${OPTARG}' requires an argument"
            usage
            exit 1
            ;;
    esac
done

# Shift off the parsed options
shift $((OPTIND - 1))

###############################################################################
# Validate that required parameters are set
###############################################################################
if [[ -z "${urlList}" || -z "${vhostWordList}" || -z "${outputDirectory}" ]]; then
    echo "Error: Missing one or more required arguments."
    usage
    exit 1
fi

###############################################################################
# Validate that necessary files and tools exist
###############################################################################
# Check if URL list file exists
if [[ ! -f "${urlList}" ]]; then
    echo "Error: URL list file '${urlList}' does not exist."
    exit 1
fi

# Check if vhost wordlist file exists
if [[ ! -f "${vhostWordList}" ]]; then
    echo "Error: vhost wordlist file '${vhostWordList}' does not exist."
    exit 1
fi

# Check if gobuster is installed
if ! command -v gobuster &> /dev/null; then
    echo "Error: 'gobuster' not found in PATH. Please install gobuster or update your PATH."
    exit 1
fi

###############################################################################
# Create output directory if it doesn't exist
###############################################################################
mkdir -p "${outputDirectory}" 2>/dev/null
if [[ $? -ne 0 ]]; then
    echo "Error: Could not create or write to output directory '${outputDirectory}'."
    exit 1
fi

###############################################################################
# Main script logic
###############################################################################
while IFS= read -r url; do
    # Skip empty lines
    if [[ -z "${url}" ]]; then
        continue
    fi

    echo "Working on URL: ${url}"
    echo "------------------"

    # Remove any "http://" or "https://" for the output filename
    outputFile="$(echo "${url}" | sed 's|https\?://||')"

    # Run gobuster command and check for errors
    gobuster vhost -k -r --no-error --random-agent \
        -o "${outputDirectory}/${outputFile}" \
        -w "${vhostWordList}" \
        -u "${url}"

    exitCode=$?
    if [[ ${exitCode} -eq 0 ]]; then
        echo "--- FINISHED ${url} ---"
    else
        echo "Error occurred with gobuster for ${url} (exit code: ${exitCode})."
        echo "Check '${outputDirectory}/${outputFile}' for any partial or error output."
    fi

    echo
done < "${urlList}"
