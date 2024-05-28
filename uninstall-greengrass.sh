#!/bin/bash

# Stop the Greengrass service
echo "Stopping Greengrass service..."
sudo systemctl stop greengrass.service

# Disable the Greengrass service
echo "Disabling Greengrass service..."
sudo systemctl disable greengrass.service

# Remove Greengrass directories
echo "Removing Greengrass directories..."
sudo rm -rf /greengrass
# Remove Greengrass users and groups
sudo userdel -r ggc_user
sudo groupdel ggc_group

# Remove Greengrass systemd service file
echo "Removing Greengrass systemd service file..."
sudo rm /etc/systemd/system/greengrass.service

# Reload systemd daemon
echo "Reloading systemd daemon..."
sudo systemctl daemon-reload

# Verify removal
echo "Verifying Greengrass service removal..."
sudo systemctl list-units --type=service | grep greengrass

echo "Greengrass core uninstallation completed."
