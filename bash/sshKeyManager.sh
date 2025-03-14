#!/bin/bash

SSH_DIR="$HOME/.ssh"
CONFIG_FILE="$SSH_DIR/config"

# Ensure the SSH directory exists
mkdir -p "$SSH_DIR"
chmod 700 "$SSH_DIR"

echo "Select an option:"
echo "1) Create an SSH Key"
echo "2) Upload an Existing SSH Key"
read -p "Enter your choice (1 or 2): " OPTION

upload_ssh_key() {
    local pubkey="$1"
    read -p "Enter remote SSH hostname: " HOSTNAME
    read -p "Enter remote SSH username: " USERNAME
    read -p "Enter remote SSH port (default 22): " PORT
    PORT=${PORT:-22}
    read -p "Enter a name for this remote SSH server: " SERVER_NAME

    echo "Uploading SSH key to remote server..."
    ssh-copy-id -f -i "$pubkey" -p "$PORT" "$USERNAME@$HOSTNAME"

    echo "Updating SSH config..."
    echo -e "\nHost $SERVER_NAME\n  HostName $HOSTNAME\n  User $USERNAME\n  Port $PORT\n  IdentityFile ${pubkey%.pub}" >> "$CONFIG_FILE"
    chmod 600 "$CONFIG_FILE"
    echo "SSH key uploaded and config updated."
}

if [[ "$OPTION" == "1" ]]; then
    read -p "Enter a name for the SSH key (without extension): " KEY_NAME
    KEY_PATH="$SSH_DIR/$KEY_NAME"

    if [[ -f "$KEY_PATH" ]]; then
        echo "Error: Key already exists. Choose a different name."
        exit 1
    fi

    echo "Generating SSH key..."
    ssh-keygen -t ed25519 -f "$KEY_PATH" -N ""

    read -p "Do you want to upload the key to a remote SSH server? (y/n): " UPLOAD
    if [[ "$UPLOAD" == "y" ]]; then
        upload_ssh_key "$KEY_PATH.pub"
    fi

elif [[ "$OPTION" == "2" ]]; then
    echo "Available SSH public keys:"
    ls -1 "$SSH_DIR"/*.pub 2>/dev/null
    read -p "Enter the name of the public key file to upload: " PUBKEY_NAME
    PUBKEY_PATH="$SSH_DIR/$PUBKEY_NAME"

    if [[ ! -f "$PUBKEY_PATH" ]]; then
        echo "Error: File not found."
        exit 1
    fi

    upload_ssh_key "$PUBKEY_PATH"
else
    echo "Invalid option. Exiting."
    exit 1
fi
