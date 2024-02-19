#!/bin/bash

# Function to display success message
success() {
  echo -e "\e[32mSuccess: $1\e[0m"
}

# Function to display error message and exit
error() {
  echo -e "\e[31mError: $1\e[0m"
  exit 1
}

# Function to prompt and continue on success or exit
prompt() {
  read -p "$1 (Press Enter to continue or Ctrl+C to exit)"
}

# Function to check the success of the last command
check_success() {
  if [ $? -ne 0 ]; then
    error "$1"
  fi
}

# Prompt user for IP address and instance details
read -p "Enter the IP address: " ip_address
read -p "Enter the hostname of the instance: " instance_hostname

# Backup old repository configuration
sudo mv /etc/yum.repos.d/almalinux.repo /etc/yum.repos.d/almalinux.repo.bak || error "Failed to create a backup of /etc/yum.repos.d/almalinux.repo"

# Create a new almalinux.repo file with updated configurations
sudo tee /etc/yum.repos.d/almalinux.repo > /dev/null <<EOF
# almalinux.repo

[baseos]
name=AlmaLinux \$releasever - BaseOS
baseurl=https://repo.almalinux.org/vault/8.6/BaseOS/x86_64/os/
enabled=1
gpgcheck=1
countme=1
gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-AlmaLinux

[appstream]
name=AlmaLinux \$releasever - AppStream
baseurl=https://repo.almalinux.org/vault/8.6/AppStream/x86_64/os/
enabled=1
gpgcheck=1
countme=1
gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-AlmaLinux

[extras]
name=AlmaLinux \$releasever - Extras
baseurl=https://repo.almalinux.org/vault/8.6/extras/x86_64/os/
enabled=1
gpgcheck=1
countme=1
gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-AlmaLinux
EOF
check_success "Failed to create new almalinux.repo file"
success "/etc/yum.repos.d/almalinux.repo modified successfully"

# Modify /etc/hosts file
sudo cp /etc/hosts /etc/hosts.bak || error "Failed to create a backup of /etc/hosts"
sudo echo "$ip_address $instance_hostname" | sudo tee -a /etc/hosts
check_success "Failed to modify /etc/hosts"
success "/etc/hosts modified successfully"

# Modify /usr/lib/os-release file
sudo cp /usr/lib/os-release /usr/lib/os-release.bak || error "Failed to create a backup of /usr/lib/os-release"
sudo tee /usr/lib/os-release > /dev/null <<EOF
NAME="Red Hat"
VERSION="8.6 (Sapphire Caracal)"
ID="Red Hat"
ID_LIKE="rhel centos fedora"
VERSION_ID="8.6"
PLATFORM_ID="platform:el8"
PRETTY_NAME="Red Hat 8.6 (Sapphire Caracal)"
EOF
check_success "Failed to modify /usr/lib/os-release"
success "/usr/lib/os-release modified successfully"

# Modify /etc/almalinux-release file
sudo cp /etc/almalinux-release /etc/almalinux-release.bak || error "Failed to create a backup of /etc/almalinux-release"
echo "Red Hat release 8.6 (Sapphire Caracal)" | sudo tee /etc/almalinux-release > /dev/null
check_success "Failed to modify /etc/almalinux-release"
success "/etc/almalinux-release modified successfully"


# Execute upgrade commands
prompt "Ready to execute upgrade commands. Press Enter to continue."
sudo dnf upgrade
check_success "Failed to upgrade the system"
success "System upgraded successfully"

# Install required packages
sudo yum install -y libnetfilter_conntrack.x86_64 bind-utils
check_success "Failed to install required packages"
success "Packages installed successfully"

# Inform the user about further steps
echo "Please continue with the rest of your UBA upgrade practices."
