#!/bin/bash

set -e

if [ "$EUID" -ne 0 ]; then
    echo "Please run this script as root or using sudo."
    exit 1
fi

function echo_bold() {
    echo -e "\033[1m$1\033[0m"
}

echo_bold "NVMe Configuration Script"

echo_bold "Updating package lists..."
apt-get update -y

echo_bold "Installing required packages..."
REQUIRED_PACKAGES=(git python3 python3-pip nvme-cli)
for PACKAGE in "${REQUIRED_PACKAGES[@]}"; do
    if ! dpkg -l | grep -q "$PACKAGE"; then
        echo_bold "Installing $PACKAGE..."
        apt-get install -y "$PACKAGE"
    else
        echo "$PACKAGE is already installed."
    fi
done


NVMETCLI_DIR="/opt/nvmetcli"
if [ ! -d "$NVMETCLI_DIR" ]; then
    echo_bold "Cloning nvmetcli repository..."
    git clone git://git.infradead.org/users/hch/nvmetcli.git "$NVMETCLI_DIR"
else
    echo "nvmetcli is already cloned at $NVMETCLI_DIR."
fi

echo_bold "Installing nvmetcli..."
cd $NVMETCLI_DIR
./setup.py install

if ! lsmod | grep -q nvmet; then
    echo_bold "Loading nvmet kernel module..."
    modprobe nvmet
else
    echo "nvmet module is already loaded."
fi

if ! lsmod | grep -q nvmet_rdma; then
    echo_bold "Loading nvmet_rdma kernel module..."
    modprobe nvmet_rdma
else
    echo "nvmet_rdma module is already loaded."
fi

echo_bold "Verifying nvmetcli installation..."
if nvmetcli ls; then
    echo "nvmetcli is installed and working correctly."
else
    echo "nvmetcli installation failed. Please check the above output for errors."
    exit 1
fi

