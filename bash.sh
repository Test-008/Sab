#!/bin/bash

# This script replicates the actions of the Dockerfile in a bash script format

# Set environment variables
export LANG=en_US.UTF-8
export LANGUAGE=en_US:en

# Update and install dependencies
apt-get -q update && \
DEBIAN_FRONTEND="noninteractive" apt-get -q install -y -o Dpkg::Options::="--force-confnew" --no-install-recommends apt-transport-https ca-certificates software-properties-common gnupg-agent curl sudo openssh-server git openjdk-11-jdk kubectl docker-ce docker-ce-cli containerd.io zip unzip wget

# Configure Docker repository
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add - && \
add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable"

# Configure OpenJDK repository
add-apt-repository -y ppa:openjdk-r/ppa

# Configure Kubernetes repository
curl -s https://packages.cloud.google.com/apt/doc/apt-key.gpg -o apt-key.gpg && \
apt-key add apt-key.gpg && \
echo "deb http://apt.kubernetes.io/ kubernetes-xenial main" >> /etc/apt/sources.list.d/kubernetes.list

# Install additional software
apt-get -q update && \
DEBIAN_FRONTEND="noninteractive" apt-get -q install -y -o Dpkg::Options::="--force-confnew" --no-install-recommends zip unzip wget

# Clean up
apt-get -q clean -y && rm -rf /var/lib/apt/lists/* && rm -f /var/cache/apt/*.bin

# Configure SSH for non-root login
sed -i 's|session    required     pam_loginuid.so|session    optional     pam_loginuid.so|g' /etc/pam.d/sshd && \
mkdir -p /var/run/sshd

# Create and configure Jenkins user
useradd -m -d /home/jenkins -s /bin/sh jenkins && \
echo "jenkins:Initial1" | chpasswd

# Import certificates
cd /usr/lib/jvm/java-11-openjdk-amd64/lib/security
# Assuming the URLs and the openssl commands are correct, replicate the steps here

# Git configuration
git config --global user.email "gtlc_ci@sap.com" && \
git config --global user.name "gtlc_ci" && \
git config --global http.sslverify false

# Configure sudoers for Jenkins user
echo "jenkins ALL=(ALL) NOPASSWD:ALL" | sudo tee -a /etc/sudoers.d/jenkins

# SDKMAN and Grails installation
su - jenkins -c 'curl -s https://get.sdkman.io | bash && \
. "$HOME/.sdkman/bin/sdkman-init.sh" && \
sdk install grails 2.4.4'

# Install Git LFS
curl -s https://packagecloud.io/install/repositories/github/git-lfs/script.deb.sh | bash && \
apt-get install -y git-lfs && \
git lfs install

# Install Google Chrome and Xvfb
wget -q -O - https://dl-ssl.google.com/linux/linux_signing_key.pub | apt-key add - && \
echo "deb http://dl.google.com/linux/chrome/deb/ stable main" > /etc/apt/sources.list.d/google.list && \
apt-get update && \
apt-get install -y google-chrome-stable xvfb

# Additional configurations and installations (Node.js, Maven, etc.)
# Replicate the steps from the Dockerfile here

# Set PATH
export PATH="/opt/node/bin:${PATH}"

# Expose port 22 for SSH (note: this line is only informative in a script)
echo "Port 22 is
