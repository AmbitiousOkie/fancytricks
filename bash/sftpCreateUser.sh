#!/bin/bash

# Define the username
read -p "Enter the new username: " username

# Create a new user
sudo useradd $username

# Create a home and an SFTP directory for the user
sudo mkdir -p /home/$username/upload
sudo chown root:root /home/$username
sudo chmod 755 /home/$username
sudo chown $username:$username /home/$username/upload

# Update SSH config to restrict the user to SFTP access only
echo "Match User $username
ChrootDirectory /home/$username
ForceCommand internal-sftp
AllowTcpForwarding no
PasswordAuthentication no
X11Forwarding no" | sudo tee -a /etc/ssh/sshd_config

# Restart the SSH service
sudo systemctl restart sshd

# Generate an SSH key pair
ssh-keygen -t rsa -b 4096 -f "/root/.ssh/${username}_ssh_key"

# Ensure the .ssh directory exists with correct permissions
sudo mkdir -p /home/$username/.ssh
sudo chmod 700 /home/$username/.ssh
sudo chown $username:$username /home/$username/.ssh

# Add the public key to authorized_keys
sudo cp "/root/.ssh/${username}_ssh_key.pub" /home/$username/.ssh/authorized_keys
sudo chmod 600 /home/$username/.ssh/authorized_keys
sudo chown $username:$username /home/$username/.ssh/authorized_keys

echo "User $username created and configured for SFTP access only."
echo "SSH key pair generated in /root/.ssh/$username/"
