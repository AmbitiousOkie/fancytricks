#!/usr/bin/env bash

############################################################
# Print usage/help menu
############################################################
usage() {
    echo "Usage: $0 -d <domain_list_file> -n <nameserver_list_file> -o <output_directory>"
    echo "  -d  File containing domains (one per line)"
    echo "  -n  File containing DNS servers (one per line)"
    echo "  -o  Output directory to store results"
    echo "  -h  Show this help message"
    echo
    echo "Example:"
    echo "  $0 -d domains.txt -n dnsservers.txt -o results/"
    echo
    exit 1
}

############################################################
# Check if dnsrecon is installed
############################################################
command -v dnsrecon >/dev/null 2>&1
if [ $? -ne 0 ]; then
    echo "Error: dnsrecon is not installed or not in PATH."
    echo "Install dnsrecon and try again."
    exit 1
fi

############################################################
# Parse command-line arguments with getopts
############################################################
while getopts "d:n:o:h" opt; do
    case ${opt} in
        d ) domainList=${OPTARG};;
        n ) nameserverList=${OPTARG};;
        o ) outputDirectory=${OPTARG};;
        h ) usage;;
        \? )
            echo "Error: Invalid option -$OPTARG" >&2
            usage
            ;;
        : )
            echo "Error: Option -$OPTARG requires an argument." >&2
            usage
            ;;
    esac
done


############################################################
# Ensure required arguments are provided
############################################################
if [ -z "${domainList}" ] || [ -z "${nameserverList}" ] || [ -z "${outputDirectory}" ]; then
    echo "Error: Missing required arguments."
    usage
fi

# Check if domain list file exists
if [ ! -f "${domainList}" ]; then
    echo "Error: Domain list file '${domainList}' not found."
    exit 1
fi

# Check if DNS server list file exists
if [ ! -f "${nameserverList}" ]; then
    echo "Error: DNS server list file '${nameserverList}' not found."
    exit 1
fi

# Check or create output directory
if [ -d "${outputDirectory}" ]; then
    echo "Directory '${outputDirectory}' already exists. Using existing directory."
else
    echo "Directory '${outputDirectory}' does not exist. Creating now..."
    mkdir -p "${outputDirectory}" || {
        echo "Failed to create directory '${outputDirectory}'. Check permissions."
        exit 1
    }
    echo "Directory '${outputDirectory}' created."
fi

############################################################
# Main script logic
############################################################

# Outer loop: nameservers
while IFS= read -r dnsserver; do
    # Skip empty lines
    [ -z "$dnsserver" ] && continue

    echo "###############################"
    echo "Working on DNS server: $dnsserver"
    echo "###############################"

    # Directory for this nameserver under the output directory
    nameserverDir="${outputDirectory}/${dnsserver}"

    # Create a directory for the current nameserver (if needed)
    if [ -d "$nameserverDir" ]; then
        echo "Directory '$nameserverDir' already exists."
    else
        echo "Directory '$nameserverDir' does not exist. Creating now..."
        mkdir -p "$nameserverDir" || {
            echo "Failed to create directory '$nameserverDir'. Check permissions."
            continue
        }
        echo "Directory '$nameserverDir' created."
    fi

    # Nested loop: domains
    while IFS= read -r domain; do
        # Skip empty lines
        [ -z "$domain" ] && continue

        echo "Running dnsrecon for domain '$domain' against DNS server '$dnsserver'..."

        outputFile="${nameserverDir}/${domain}.csv"
        dnsrecon -a -z -d "$domain" -c "$outputFile" -n "$dnsserver"

        if [ $? -eq 0 ]; then
            echo "--- FINISHED $domain with DNS server $dnsserver ---"
        else
            echo "Error: dnsrecon command failed for domain '$domain' on DNS server '$dnsserver'."
        fi

        echo
    done < "${domainList}"

    echo
done < "$nameserverList"

cat $nameserverList
