#!/bin/bash

# Function to print a green banner with text
print_banner() {
    echo -e "\e[32m
    ▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄
    ██░▄▄▄░██░▄▄░██░█████░██░██░▀██░██░█▀▄██░▄▄▄██░▄▄▀████▄▀█▀▄
    ██▄▄▄▀▀██░▀▀░██░█████░██░██░█░█░██░▄▀███░▄▄▄██░▀▀▄█▄▄███░██
    ██░▀▀▀░██░█████░▀▀░██▄▀▀▄██░██▄░██░██░██░▀▀▀██░██░████▀▄█▄▀
    ▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀
    \e[0m"

# Function to show a loading indicator
show_loading() {
    local message="$1"
    local duration="$2"
    local chars="/-\|"

    echo -n -e "$message ...\e[33m"
    
    for ((i = 0; i < duration * 5; i++)); do
        echo -n -e "${chars:i%4:1}\b"
        sleep 0.2
    done
    
    echo -e "\e[32mDone\e[0m"
}

# Function to download and extract Splunk or UF
download_and_extract() {
    local download_link="$1"
    local install_path="$2"

    show_loading "Downloading $install_path" 1
    wget -O "${install_path}.tgz" "$download_link" && \
    show_loading "Extracting $install_path" 1 && \
    tar -xzf "${install_path}.tgz" -C /opt && \
    show_loading "$install_path extracted successfully" 1 || \
    { echo -e "\e[31mExtraction of $install_path failed.\e[0m"; exit 1; }
}

# Function to create a user if it doesn't exist
create_user_if_not_exists() {
    local username="splunker"

    id "$username" &>/dev/null && show_loading "User '$username' already exists" 1 || \
    { adduser "$username" && show_loading "User '$username' created successfully" 1; }
}

# Function to add user to sudoers file
add_user_to_sudoers() {
    local username="splunker"

    if ! grep -q "$username" /etc/sudoers; then
        echo "$username ALL=(ALL:ALL) ALL" >> /etc/sudoers && \
        show_loading "Added user '$username' to sudoers file" 1
    else
        show_loading "User '$username' already in sudoers file" 1
    fi
}

# Function to configure Splunk for boot start
configure_splunk_for_boot_start() {
    local splunk_path="$1"
    local splunk_service_name=""

    if [[ "$splunk_path" == *"/splunkforwarder"* ]]; then
        splunk_service_name="SplunkForwarder"
    else
        splunk_service_name="Splunkd"
    fi

    show_loading "Configuring Splunk for boot start" 1
    "${splunk_path}/bin/splunk" enable boot-start -systemd-managed 1 -user splunker --accept-license && \
    show_loading "Splunk configured for boot start successfully" 1 || \
    echo -e "\e[31mSplunk configuration for boot start failed. Please configure it manually.\e[0m"
}

# Function to check Splunk systemd unit files
check_splunk_systemd_units() {
    local splunk_path="$1"
    local splunk_service_name=""

    if [[ "$splunk_path" == *"/splunkforwarder"* ]]; then
        splunk_service_name="SplunkForwarder"
    else
        splunk_service_name="Splunkd"
    fi

    local splunk_systemd_service="/etc/systemd/system/multi-user.target.wants/${splunk_service_name}.service"

    if [ -f "$splunk_systemd_service" ]; then
        show_loading "Splunk systemd unit file found" 1
        systemctl is-enabled --quiet "$splunk_service_name" && \
        show_loading "Splunk systemd unit file is enabled" 1 || \
        echo -e "\e[31mSplunk systemd unit file is not enabled.\e[0m"

        systemctl is-active --quiet "$splunk_service_name" && \
        show_loading "Splunk systemd unit file is active" 1 || {
            echo -e "\e[31mSplunk systemd unit file is not active. Starting the service...\e[0m"
            systemctl start "$splunk_service_name" && \
            show_loading "Splunk systemd service started" 1 || \
            echo -e "\e[31mFailed to start Splunk systemd service. Please start it manually.\e[0m"
        }
    else
        echo -e "\e[31mSplunk systemd unit file not found.\e[0m"
    fi
}

# Function to create or fix Splunk systemd unit files
create_or_fix_splunk_systemd_units() {
    local splunk_path="$1"
    local splunk_service_name=""

    if [[ "$splunk_path" == *"/splunkforwarder"* ]]; then
        splunk_service_name="SplunkForwarder"
    else
        splunk_service_name="Splunkd"
    fi

    local splunk_systemd_service="/etc/systemd/system/multi-user.target.wants/${splunk_service_name}.service"
    local systemd_unit_content="[Unit]\nDescription=Splunk Daemon\n\n[Service]\nExecStart=${splunk_path}/bin/splunk start --accept-license\nExecStop=${splunk_path}/bin/splunk stop\nRestart=always\n\n[Install]\nWantedBy=multi-user.target"

    if [ -f "$splunk_systemd_service" ]; then
        echo -e "\e[34mSplunk systemd unit file already exists.\e[0m"
    else
        echo -e "\e[34mSplunk systemd unit file not found. Creating and enabling it...\e[0m"
        echo -e "$systemd_unit_content" | sudo tee "$splunk_systemd_service" > /dev/null
        sudo systemctl enable "$splunk_service_name" && \
        show_loading "Splunk systemd unit file created and enabled" 1
    fi
}

# Main part of the script
main() {
    local splunk_path=""
    local splunk_download_link=""
    local choice=""

    # Print the green Splunker banner
    print_banner

    # User choice
    echo -e "\e[34m1. Splunk Enterprise\e[0m"
    echo -e "\e[34m2. Universal Forwarder\e[0m"
    echo -e "\e[34m3. Check Splunk systemd unit files\e[0m"
    echo -e "\e[34m4. Exit\e[0m"
    read -p "Select an option (1/2/3/4): " choice

    case $choice in
        1)
            splunk_path="/opt/splunk"
            splunk_download_link="https://download.splunk.com/products/splunk/releases/9.1.1/linux/splunk-9.1.1-64e843ea36b1-Linux-x86_64.tgz"
            ;;
        2)
            splunk_path="/opt/splunkforwarder"
            splunk_download_link="https://download.splunk.com/products/universalforwarder/releases/9.1.1/linux/splunkforwarder-9.1.1-64e843ea36b1-Linux-x86_64.tgz"
            ;;
        3)
            # Option 3: Check Splunk systemd unit files and create/fix them
            echo -e "\e[34mSelect an option (1/2) for Splunk version:\e[0m"
            echo -e "\e[34m1. Splunk Enterprise\e[0m"
            echo -e "\e[34m2. Universal Forwarder\e[0m"
            read -p "Select an option (1/2): " choice
            case $choice in
                1)
                    splunk_path="/opt/splunk"
                    ;;
                2)
                    splunk_path="/opt/splunkforwarder"
                    ;;
                *)
                    echo -e "\e[31mInvalid choice. Please select 1 or 2.\e[0m"
                    exit 1
                    ;;
            esac

            create_or_fix_splunk_systemd_units "$splunk_path"
            check_splunk_systemd_units "$splunk_path"
            exit 0
            ;;
        4)
            echo -e "\e[34mExiting the script.\e[0m"
            exit 0
            ;;
        *)
            echo -e "\e[31mInvalid choice. Please select 1, 2, 3, or 4.\e[0m"
            exit 1
            ;;
    esac

    # Create user if it doesn't exist
    create_user_if_not_exists

    # Check if the user has a password, and if not, set a password
    [ -z "$(getent passwd splunker | cut -d: -f2)" ] && passwd splunker || \
    show_loading "User 'splunker' already has a password" 1

    # Add user to sudoers file
    add_user_to_sudoers

    # Download and extract Splunk or UF
    download_and_extract "$splunk_download_link" "$splunk_path"
    chown -R splunker:splunker "$splunk_path"

    # Configure Splunk for boot start and prompt the user
    configure_splunk_for_boot_start "$splunk_path"

    # Option 3: Check Splunk systemd unit files
    check_splunk_systemd_units "$splunk_path"
}

# Call the main function to execute the script
main

