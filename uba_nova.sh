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

# Install required packages
sudo yum install -y bind-utils
check_success "Failed to install bind-utils"
success "bind-utils installed successfully"

# Modify sudoers file
echo "caspida ALL=(ALL) NOPASSWD:ALL" | sudo tee -a /etc/sudoers
check_success "Failed to modify sudoers file"
success "User added to sudoers file"

# Create user and group
sudo groupadd --gid 2018 caspida
sudo useradd --uid 2018 --gid 2018 -m -d /home/caspida -c "Caspida User" -s /bin/bash caspida
sudo passwd caspida
check_success "Failed to create user and group"
success "User and group created successfully"

# Create directories
sudo mkdir -p /var/vcap /var/vcap2
sudo chmod 755 /var/vcap /var/vcap2
sudo chown root:root /var/vcap /var/vcap2
check_success "Failed to create directories"
success "Directories created successfully"

# Create /etc/locale.conf file
echo "LANG=\"en_US.UTF-8\"" | sudo tee -a /etc/locale.conf
echo "LC_CTYPE=\"en_US.UTF-8\"" | sudo tee -a /etc/locale.conf
source /etc/locale.conf
check_success "Failed to update /etc/locale.conf"
success "/etc/locale.conf updated successfully"

# Modify SELINUX settings
sudo sed -i 's/SELINUX=enforcing/SELINUX=permissive/' /etc/sysconfig/selinux
check_success "Failed to set SELINUX to permissive"
success "SELINUX set to permissive"

# Check and configure bridge settings
if [ ! -f /proc/sys/net/bridge/bridge-nf-call-iptables ]; then
  sudo modprobe br_netfilter
  echo "br_netfilter" | sudo tee -a /etc/modules-load.d/br_netfilter.conf
fi
sudo sysctl -w net.bridge.bridge-nf-call-iptables=1
echo "net.bridge.bridge-nf-call-iptables=1" | sudo tee -a /etc/sysctl.d/splunkuba-bridge.conf
sudo chmod o+r /etc/sysctl.d/splunkuba-bridge.conf
check_success "Failed to configure bridge settings"
success "Bridge settings configured successfully"

# Create caspida.conf file
echo "caspida soft nproc unlimited" | sudo tee -a /etc/security/limits.d/caspida.conf
echo "caspida soft nofile 32768" | sudo tee -a /etc/security/limits.d/caspida.conf
echo "caspida hard nofile 32768" | sudo tee -a /etc/security/limits.d/caspida.conf
echo "caspida soft core unlimited" | sudo tee -a /etc/security/limits.d/caspida.conf
echo "caspida soft stack unlimited" | sudo tee -a /etc/security/limits.d/caspida.conf
echo "caspida soft memlock unlimited" | sudo tee -a /etc/security/limits.d/caspida.conf
echo "caspida hard memlock unlimited" | sudo tee -a /etc/security/limits.d/caspida.conf
check_success "Failed to create caspida.conf file"
success "Security limits configured successfully"

# Edit yum.conf for IPv4 addresses
echo "ip_resolve=4" | sudo tee -a /etc/yum.conf
check_success "Failed to update yum.conf for IPv4 addresses"
success "yum.conf updated for IPv4 addresses"

# Prompt for UBA download link
echo -n "Enter UBA download link: "
read uba_download_link

# Set umask for root user
umask 0022

# Download UBA and extract as root
wget --user-agent="Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/58.0.3029.110 Safari/537.3" -O "/home/caspida/uba.tgz" "$uba_download_link"
check_success "Failed to download UBA"

# Extract UBA
tar xvzf "/home/caspida/uba.tgz"
check_success "Failed to extract UBA"
success "UBA downloaded and extracted successfully"

# Find and extract Splunk-UBA-Platform package
uba_platform_package=$(find /home/caspida/ -type f -name "Splunk-UBA-Platform*.tgz" | head -n 1)
if [ -z "$uba_platform_package" ]; then
  error "Unable to find Splunk-UBA-Platform package in /opt/caspida/"
fi
sudo tar xvzf "$uba_platform_package" -C /opt/caspida/
check_success "Failed to extract Splunk-UBA-Platform package"
success "Splunk-UBA-Platform package extracted successfully"

# Find and extract Splunk-UBA-Packages-RHEL-8 package
uba_packages_package=$(find /home/caspida/ -type f -name "Splunk-UBA-*.tgz" | head -n 1)
if [ -z "$uba_packages_package" ]; then
  error "Unable to find Splunk-UBA-Packages-RHEL-8 package in /home/caspida/"
fi
sudo tar xvzf "$uba_packages_package" -C /home/caspida/
check_success "Failed to extract Splunk-UBA-Packages-RHEL-8 package"
success "Splunk-UBA-Packages-RHEL-8 package extracted successfully"

# Perform UBA installation
sudo su - caspida -c "/opt/caspida/bin/installer/redhat/INSTALL.sh /home/caspida/Splunk-UBA-5.3-Packages-RHEL-8"
check_success "Installation error"
success "UBA installed successfully"

# SSH key generation
sudo su - caspida -c "ssh-keygen -t rsa"
sudo cat /home/caspida/.ssh/id_rsa.pub >> /home/caspida/.ssh/authorized_keys
sudo chmod 600 /home/caspida/.ssh/authorized_keys
check_success "Failed to generate and authorize SSH keys"
success "SSH keys generated and authorized successfully"

# Prompt for ubahostname
prompt "Enter ubahostname: "
read ubahostname

# Run UBA pre-check script
sudo su - caspida -c "/opt/caspida/bin/utils/uba_pre_check.sh $ubahostname"
check_success "UBA pre-check failed"
success "UBA pre-check completed successfully"

# Run UBA setup
sudo su - caspida -c "/opt/caspida/bin/Caspida setup"
check_success "UBA setup failed"
success "UBA setup completed successfully"

