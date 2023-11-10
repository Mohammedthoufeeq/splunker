
# Splunker

Splunker is a Bash script designed to simplify the installation and configuration process of Splunk and Splunk Universal Forwarder on Linux systems. It provides an interactive interface for users to choose between Splunk Enterprise and Universal Forwarder, create system users, download, and configure Splunk for boot start.

## Features

- **User-friendly Interface**: Interactive menu for users to select options.
- **System User Management**: Automatically creates a system user for Splunk.
- **Password Handling**: Checks if the user has a password and sets one if not.
- **Splunk Download and Extraction**: Downloads and extracts Splunk or Universal Forwarder.
- **Boot Start Configuration**: Configures Splunk for boot start with systemd.

## Usage

1. Clone the repository:

   ```bash
   git clone https://github.com/your-username/splunker.git
   cd splunker 
   Run the script(as a root user): ./splunker.sh



Follow the on-screen instructions to install and configure Splunk.

## Options
1. Splunk Enterprise: Installs and configures Splunk Enterprise.
2. Universal Forwarder: Installs and configures Splunk Universal Forwarder.
3. Check Splunk systemd unit files: Checks and creates/fixes Splunk systemd unit files.

## Requirements
1.Bash
2. wget
