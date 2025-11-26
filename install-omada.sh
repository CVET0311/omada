#!/usr/bin/env bash
# 
# Name: install-omada.sh
# Author: CVET0311
# Version: 1.0
# Last updated: 
# License: MIT
# 
# GitHub: https://github.com/CVET0311/omada
# Usage: ./install-omada.sh
# 
# Description:
#   Automates installation of the Omada SDN Controller on Ubuntu
#   using pinned package versions for reliability. Follows the same
#   steps as the manual installation instructions.
#
# Requirements:
#   - Ubuntu Server 24.04
#   - Internet access
#   - 'sudo' privileges

set -euo pipefail

# Set the desired versions here, but ensure it will not break the install
OMADA_VER="6.0.0.24"
JDK_VER="17"
MONGODB_VER="8.0.12"

echo "Using Omada version: $OMADA_VER"
echo "Using OpenJDK version: $JDK_VER"
echo "Using MongoDB version: $MONGODB_VER"


# 2. Update system
echo "Updating package database..."
sudo apt update && sudo apt dist-upgrade -y

# 3. Install Dependencies
echo "Installing base dependencies..."
sudo apt install -y \
    openjdk-$JDK_VER-jdk-headless \
    gnupg \
    jsvc

# 4. Install MongoDB
echo "Installing MongoDB repository key..."
curl -fsSL https://www.mongodb.org/static/pgp/server-8.0.asc | \
   sudo gpg -o /usr/share/keyrings/mongodb-server-8.0.gpg --dearmor

echo "Adding MongoDB repo..."
echo "deb [ arch=amd64,arm64 signed-by=/usr/share/keyrings/mongodb-server-8.0.gpg ] https://repo.mongodb.org/apt/ubuntu jammy/mongodb-org/8.0 multiverse" \
    | sudo tee /etc/apt/sources.list.d/mongodb-org-8.0.list

sudo apt update

echo "Installing MongoDB version $MONGODB_VER..."
sudo apt install -y --allow-downgrades \
    mongodb-org="$MONGODB_VER" \
    mongodb-org-database="$MONGODB_VER" \
    mongodb-org-server="$MONGODB_VER" \
    mongodb-mongosh \
    mongodb-org-shell="$MONGODB_VER" \
    mongodb-org-mongos="$MONGODB_VER" \
    mongodb-org-tools="$MONGODB_VER" \
    mongodb-org-database-tools-extra="$MONGODB_VER"

echo "Starting MongoDB..."
sudo systemctl daemon-reload
sudo systemctl enable --now mongod

# Prevent upgrades
echo "Holding MongoDB packages..."
for pkg in mongodb-org \
           mongodb-org-database \
           mongodb-org-server \
           mongodb-mongosh \
           mongodb-org-mongos \
           mongodb-org-tools; do
    echo "$pkg hold" | sudo dpkg --set-selections
done

# 5. Install Omada Controller
echo "Downloading the Omada Controller, version ${OMADA_VER}..."
wget "https://static.tp-link.com/upload/software/2025/202510/20251031/omada_v${OMADA_VER}_linux_x64_20251027202535.deb"

echo "Installing Omada, version ${OMADA_VER}..."
sudo dpkg -i omada_v*.deb

echo "Omada SDN Controller installation complete!"
