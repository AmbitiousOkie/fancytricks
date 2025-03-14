#!/usr/bin/env bash
#
# reverse_ssh_service.sh
#
# Description:
#   This Bash script automates the creation, management, and deployment
#   of a systemd service that maintains an SSH reverse tunnel.
#   It will:
#       1) Check for existing services that match the pattern <user>@<host>-<port>
#       2) Disable and remove any existing matching services
#       3) Generate a new SSH key pair
#       4) Copy the public key to the remote host
#       5) Create and enable a systemd service to maintain the SSH reverse tunnel

################################################################################
# Usage function: displays help menu
################################################################################
usage() {
    echo "Usage:"
    echo "  $0 <remote_username> <remote_hostname> <remote_port>"
    echo
    echo "Description:"
    echo "  This script automates the creation, management, and deployment of a systemd service"
    echo "  to establish a persistent SSH reverse tunnel. It requires three arguments:"
    echo "    1) remote_username - the username on the remote host"
    echo "    2) remote_hostname - the hostname/IP of the remote host"
    echo "    3) remote_port     - the SSH port on the remote host"
    echo
    echo "Options:"
    echo "  -h, --help     Show this help menu."
    echo
    echo "Example:"
    echo "  $0 myuser example.com 22"
    echo
    exit 1
}

################################################################################
# Parse arguments and display help if needed
################################################################################
if [[ $# -lt 1 ]]; then
    usage
fi

# Check for '-h' or '--help' anywhere among the arguments
for arg in "$@"; do
    if [[ "$arg" == "-h" || "$arg" == "--help" ]]; then
        usage
    fi
done

# Check that exactly 3 non-help arguments were provided
if [[ $# -ne 3 ]]; then
    echo "Error: You must provide exactly 3 arguments (remote_username remote_hostname remote_port)."
    usage
fi

################################################################################
# Main Script
################################################################################

# Store arguments
remote_username="$1"
remote_hostname="$2"
remote_port="$3"

# Pattern for existing service names
service_pattern="${remote_username}@${remote_hostname}-[0-9][0-9][0-9][0-9][0-9]"

# Check for existing services
existing_services=$(systemctl list-unit-files --type=service --no-legend | grep -E "$service_pattern")

if [[ -n "$existing_services" ]]; then
    echo "Existing services found matching pattern '$service_pattern':"
    echo "$existing_services"
    
    # Disable and delete existing services
    echo "Disabling and deleting existing services..."
    while read -r service; do
        service_name=$(echo "$service" | awk '{print $1}')
        sudo systemctl stop "$service_name" || {
            echo "Warning: Failed to stop service $service_name"
        }
        sudo systemctl disable "$service_name" || {
            echo "Warning: Failed to disable service $service_name"
        }
        sudo rm -f "/etc/systemd/system/${service_name}" || {
            echo "Warning: Failed to remove service file /etc/systemd/system/${service_name}"
        }
    done <<< "$existing_services"
    sudo systemctl daemon-reload
fi

# Generate a random port between 40000 and 50000
random_nums=$((RANDOM % 10000 + 40000))
service_name="${remote_username}@${remote_hostname}-${random_nums}"

# Create an Ed25519 key pair
ssh_key_path="$HOME/.ssh/${service_name}"
echo "Generating SSH key pair at $ssh_key_path ..."
ssh-keygen -t ed25519 -f "$ssh_key_path" -q -N "" || {
    echo "Error: Failed to generate SSH key pair."
    exit 1
}

# Verify that keys were created successfully
if [[ ! -f "$ssh_key_path" || ! -f "$ssh_key_path.pub" ]]; then
    echo "Error: SSH key pair creation failed. Exiting."
    exit 1
fi

# Copy public key to the remote host
echo "Copying public key to the remote host ($remote_username@$remote_hostname)."
echo "You may be prompted for your remote password."
ssh-copy-id -i "$ssh_key_path.pub" -p "$remote_port" "$remote_username@$remote_hostname" || {
    echo "Error: Failed to copy public key to remote host."
    exit 1
}

# Create the systemd service file
service_file_path="/etc/systemd/system/${service_name}.service"
echo "Creating systemd service file at $service_file_path"
service_content="[Unit]
Description=SSH reverse tunnel for ${remote_username}@${remote_hostname}
After=network-online.target  

[Service]
User=root
Restart=always
RestartSec=20

ExecStart=/usr/bin/ssh \\
    -o \"StrictHostKeyChecking=no\" \\
    -o \"UserKnownHostsFile=/dev/null\" \\
    -o \"ServerAliveInterval=30\" \\
    -o \"ServerAliveCountMax=3\" \\
    -o \"ExitOnForwardFailure=yes\" \\
    -N -R ${random_nums}:localhost:22 \\
    '${remote_username}@${remote_hostname}' -i '$ssh_key_path'

[Install]
WantedBy=multi-user.target"

# Write the content to the service file
echo "$service_content" | sudo tee "$service_file_path" > /dev/null

# Set executable permissions (though not strictly required for systemd .service files)
sudo chmod 644 "$service_file_path" || {
    echo "Warning: Failed to set permissions on $service_file_path"
}

# Enable and start the new service
echo "Enabling and starting service: $service_name"
sudo systemctl enable --now "$service_name" || {
    echo "Error: Failed to enable/start service $service_name"
    exit 1
}

# Check if the service is active
if ! sudo systemctl is-active --quiet "$service_name"; then
    echo "Error: Service $service_name is not running."
    exit 1
fi

# Verify the SSH tunnel is listening
if ! ss -tulpn 2>/dev/null | grep -q "LISTEN.*:${random_nums}"; then
    echo "Error: SSH tunnel on port $random_nums is not connected."
    exit 1
fi

echo "Success!"
echo "The SSH reverse tunnel service is running as: $service_name"
echo "You can manage it using standard systemd commands, for example:"
echo "  sudo systemctl status $service_name"
echo "  sudo systemctl stop $service_name"
echo "  sudo systemctl start $service_name"
