
## Description

This Bash script automates the creation, management, and deployment of a systemd service to establish an SSH reverse tunnel. It includes functionality to check for and remove existing services with a specific pattern, generate a new SSH key pair, copy the public key to a remote host, and create a new systemd service to maintain the SSH reverse tunnel.

```bash
#!/bin/bash

# Check for required arguments
if [[ $# -ne 3 ]]; then
    echo "Usage: $0 <remote_username> <remote_hostname> <remote_port>"
    exit 1
fi

# Store arguments
remote_username="$1"
remote_hostname="$2"
remote_port="$3"

# Pattern for existing service names
service_pattern="${remote_username}@${remote_hostname}-[0-9][0-9][0-9][0-9][0-9]"

# Check for existing services
existing_services=$(systemctl list-unit-files --type=service --no-legend | grep -E "$service_pattern")

if [[ -n "$existing_services" ]]; then  # Check if any services were found
    echo "Existing services found with the same pattern:"
    echo "$existing_services"  # Print the list of services
    
    # Disable and delete existing services
    echo "Disabling and deleting existing services..."
    while read -r service; do  # Iterate over each service line
        service_name=$(echo "$service" | awk '{print $1}')  # Extract service name
        sudo systemctl stop "$service_name"  # Stop the service
        sudo systemctl disable "$service_name"  # Disable the service
        sudo rm "/etc/systemd/system/${service_name}"  # Delete the service file
    done <<< "$existing_services"

    sudo systemctl daemon-reload  # Reload systemd
fi

# Generate random number between 40000 and 50000
random_nums=$((RANDOM % 10000 + 40000))
service_name="${remote_username}@${remote_hostname}-${random_nums}"

# Create Ed25519 key pair (ensure tilde expansion)
ssh_key_path="$HOME/.ssh/${service_name}"
ssh-keygen -t ed25519 -f "$ssh_key_path" -q -N ""

# Check if keys were created successfully
if [[ ! -f "$ssh_key_path" || ! -f "$ssh_key_path.pub" ]]; then
    echo "Error: SSH key pair creation failed. Exiting."
    exit 1
fi

# Copy public key to the remote host
echo "Connecting to $remote_hostname. Please enter your credentials when prompted."
ssh-copy-id -i "$ssh_key_path.pub" -p "$remote_port" "$remote_username@$remote_hostname" 

# Create systemd service file content (using $random_nums for port)
service_content="[Unit]
Description=SSH reverse tunnel
After=network-online.target  

[Service]
User=root
Restart=always
RestartSec=20

ExecStart=/usr/bin/ssh -o \"StrictHostKeyChecking=no\" -o \"UserKnownHostsFile=/dev/null\" -o \"ServerAliveInterval 30\" -o \"ServerAliveCountMax 3\" -o \"ExitOnForwardFailure yes\" -N -R ${random_nums}:localhost:22 '${remote_username}@${remote_hostname}' -i '$ssh_key_path'

[Install]
WantedBy=multi-user.target"

# Write the content to the service file
echo "$service_content" | sudo tee "/etc/systemd/system/${service_name}.service"

# Check and set service file permissions
service_file_path="/etc/systemd/system/${service_name}.service"
if [[ ! -x "$service_file_path" ]]; then
    echo "Setting permissions on service file..."
    sudo chmod +x "$service_file_path" 
fi

# Enable and start the service
sudo systemctl enable --now "$service_name"

# Check if service is active
if ! sudo systemctl is-active --quiet "$service_name"; then
    echo "Error: Service $service_name is not running. Exiting."
    exit 1
fi

# Check if SSH tunnel is connected
if ! ss -tulpn | grep -q "LISTEN.*:${random_nums}"; then
    echo "Error: SSH tunnel on port $random_nums is not connected. Exiting."
    exit 1
fi

echo "SSH reverse tunnel service created, started, and connected as $service_name."
```