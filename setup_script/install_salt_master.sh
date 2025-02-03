#!/bin/bash

set -e

detect_os() {
    if [[ -f /etc/os-release ]]; then
        . /etc/os-release
        OS=$ID
        VER=$VERSION_ID
    elif [[ -f /etc/lsb-release ]]; then
        . /etc/lsb-release
        OS=$DISTRIB_ID
        VER=$DISTRIB_RELEASE
    elif [[ -f /etc/debian_version ]]; then
        OS=debian
        VER=$(cat /etc/debian_version)
    elif [[ -f /etc/redhat-release ]]; then
        OS=$(cat /etc/redhat-release | cut -d " " -f 1)
        VER=$(cat /etc/redhat-release | grep -oE '[0-9]+\.[0-9]+')
    else
        echo "Unsupported OS. Exiting."
        exit 1
    fi
}

install_salt_master() {
    case $OS in
        ubuntu|debian)
            echo "Installing Salt Master on $OS $VER..."
            sudo mkdir -p /etc/apt/keyrings
            sudo curl -fsSL -o /etc/apt/keyrings/salt-archive-keyring-2023.gpg https://repo.saltproject.io/salt/py3/debian/12/amd64/SALT-PROJECT-GPG-PUBKEY-2023.gpg
            echo "deb [signed-by=/etc/apt/keyrings/salt-archive-keyring-2023.gpg arch=amd64] https://repo.saltproject.io/salt/py3/debian/12/amd64/latest bookworm main" | sudo tee /etc/apt/sources.list.d/salt.list
            sudo apt-get update
            sudo apt-get install -y salt-master salt-ssh
            ;;
        centos|redhat)
            echo "Installing Salt Master on $OS $VER..."
            sudo yum install -y https://repo.saltproject.io/py3/redhat/salt-py3-repo-latest.el$(echo $VER | cut -d. -f1).noarch.rpm
            sudo yum clean expire-cache
            sudo yum install -y salt-master
            ;;
        *)
            echo "Unsupported OS for Salt Master installation. Exiting."
            exit 1
            ;;
    esac
}

install_salt_minion() {
    case $OS in
        ubuntu|debian)
            echo "Installing Salt Minion on $OS $VER..."
            sudo mkdir -p /etc/apt/keyrings
            sudo curl -fsSL -o /etc/apt/keyrings/salt-archive-keyring-2023.gpg https://repo.saltproject.io/salt/py3/debian/12/amd64/SALT-PROJECT-GPG-PUBKEY-2023.gpg
            echo "deb [signed-by=/etc/apt/keyrings/salt-archive-keyring-2023.gpg arch=amd64] https://repo.saltproject.io/salt/py3/debian/12/amd64/latest bookworm main" | sudo tee /etc/apt/sources.list.d/salt.list
            sudo apt-get update
            sudo apt-get install -y salt-minion
            ;;
        centos|redhat)
            echo "Installing Salt Minion on $OS $VER..."
            sudo yum install -y https://repo.saltproject.io/py3/redhat/salt-py3-repo-latest.el$(echo $VER | cut -d. -f1).noarch.rpm
            sudo yum clean expire-cache
            sudo yum install -y salt-minion
            ;;
        *)
            echo "Unsupported OS for Salt Minion installation. Exiting."
            exit 1
            ;;
    esac
}

configure_salt_master() {
    echo "Configuring Salt Master..."
    sudo mkdir -p /etc/salt/master.d
    cat <<EOT | sudo tee /etc/salt/master.d/custom.conf
interface: 127.0.0.1
file_roots:
  base:
    - /srv/salt
EOT

    echo "Enabling and starting Salt Master service..."
    sudo systemctl enable salt-master
    sudo systemctl start salt-master
}

configure_salt_minion() {
    echo "Configuring Salt Minion..."
    sudo mkdir -p /etc/salt/minion.d
    cat <<EOT | sudo tee /etc/salt/minion.d/custom.conf
master: salt
id: $(hostname)
EOT

    echo "Enabling and starting Salt Minion service..."
    sudo systemctl enable salt-minion
    sudo systemctl start salt-minion
}

setup_master() {
    detect_os
    install_salt_master
    configure_salt_master
    echo "Salt Master installation and configuration completed."
}

setup_minion() {
    detect_os
    install_salt_minion
    configure_salt_minion
    echo "Salt Minion installation and configuration completed."
}

setup_minion