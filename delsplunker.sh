#!/bin/bash

# Define color codes
RED='\033[0;31m'
GREEN='\033[0;32m'
NC='\033[0m' # No Color

# Prompt for service to uninstall
echo -e "${GREEN}Which service would you like to uninstall?${NC}"
echo "1. Splunkd"
echo "2. SplunkForwarder"
read -p "Enter the number of your choice: " service_choice

# Set service name based on user choice
case $service_choice in
    1) splunk_service_name="Splunkd";;
    2) splunk_service_name="SplunkForwarder";;
    *) echo -e "${RED}Invalid choice. Exiting.${NC}"; exit 1;;
esac

# Display loading screen
echo -e "${GREEN}Uninstalling $splunk_service_name...${NC}"
sleep 2 # Pause for 2 seconds for the sake of demonstration

# Stop Splunk service
echo "Stopping $splunk_service_name service..."
/opt/splunk/bin/splunk stop

# Remove Splunk directory
read -p "Are you sure you want to remove the Splunk directory? (y/n) " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]
then
    echo "Removing Splunk directory..."
    rm -rf /opt/splunk
fi

# Remove Splunk user and its home directory
read -p "Are you sure you want to remove the Splunk user and its home directory? (y/n) " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]
then
    echo "Removing Splunk user and its home directory..."
    userdel -r splunker
fi

# Remove Splunk group
read -p "Are you sure you want to remove the Splunk group? (y/n) " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]
then
    echo "Removing Splunk group..."
    groupdel splunker
fi

# Remove systemd unit file for Splunk
read -p "Are you sure you want to remove the systemd unit file for $splunk_service_name? (y/n) " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]
then
    echo "Removing systemd unit file for $splunk_service_name..."
    if [ -f /etc/systemd/system/multi-user.target.wants/${splunk_service_name}.service ]; then
        rm /etc/systemd/system/multi-user.target.wants/${splunk_service_name}.service
    fi
fi

# Reload systemd daemon to apply changes
systemctl daemon-reload

echo -e "${GREEN}$splunk_service_name and all related files have been removed.${NC}"
