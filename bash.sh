#!/bin/bash

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

# Add the openssl & keytool commands & update ca certificate, 
curl -sSL -f -k http://aia.pki.co.sap.com/aia/SAPNetCA_G2.crt -o ca.crt &&\
curl -sSL -f -k http://aia.pki.co.sap.com/aia/SAP%20Global%20Root%20CA.crt -o root.crt &&\
openssl s_client -connect github.wdf.sap.corp:443 -showcerts </dev/null 2>/dev/null|openssl x509 -outform PEM >git.pem &&\
openssl s_client -connect jenkins.gtlc.only.sap:443 -showcerts </dev/null 2>/dev/null|openssl x509 -outform PEM >gtlc.pem &&\
keytool -import -noprompt -alias ca -keystore cacerts -storepass changeit -file ca.crt &&\
keytool -import -noprompt -alias root -keystore cacerts -storepass changeit -file root.crt &&\
keytool -import -noprompt -alias git -keystore cacerts -storepass changeit -file git.pem && \
keytool -import -noprompt -alias gtlc -keystore cacerts -storepass changeit -file gtlc.pem && \
mv ca.crt /usr/local/share/ca-certificates/ca.crt &&\
mv root.crt /usr/local/share/ca-certificates/root.crt &&\
update-ca-certificates

# Git configuration
git config --global user.email "gtlc_ci@sap.com" && \
git config --global user.name "gtlc_ci" && \
git config --global http.sslverify false

# Configure sudoers for Jenkins user
echo "jenkins ALL=(ALL) NOPASSWD:ALL" | sudo tee -a /etc/sudoers.d/jenkins && \
echo no |dpkg-reconfigure dash &&\
chown -R jenkins.jenkins /home/jenkins/ && \
ENV PATH="/opt/node/bin:${PATH}" 

# SDKMAN and Grails installation
su - jenkins -c 'curl -s https://get.sdkman.io | bash && \
. "$HOME/.sdkman/bin/sdkman-init.sh" && \
sdk install grails 2.4.4'

# Install SAP Machine
curl -LO https://github.com/SAP/SapMachine/releases/download/sapmachine-11.0.20/sapmachine-jdk-11.0.20_linux-x64_bin.tar.gz && \
tar zxvf sapmachine-jdk-11.0.20_linux-x64_bin.tar.gz -C /usr/local/ && \
ln -s /usr/local/sapmachine-jdk-11.0.20 /usr/local/jdk11 && \
chown jenkins.jenkins -R /usr/local/jdk11


# Install Git LFS
curl -s https://packagecloud.io/install/repositories/github/git-lfs/script.deb.sh | bash && \
apt-get install -y git-lfs && \
apt-get -q clean -y && rm -rf /var/lib/apt/lists/* && rm -f /var/cache/apt/*.bin && \
git lfs install && \
wget https://github.com/sapcc/kubernikus/releases/download/v1.0.0%2Bf4a0f3eff2603895b25d3f98f865a6fc7e3a26df/kubernikusctl_linux_amd64 && \ 
mv kubernikusctl_linux_amd64 /usr/bin/kubernikusctl && \
chmod +x /usr/bin/kubernikusctl

# Install Google Chrome and Xvfb
wget -q -O - https://dl-ssl.google.com/linux/linux_signing_key.pub | apt-key add - && \
echo "deb http://dl.google.com/linux/chrome/deb/ stable main" > /etc/apt/sources.list.d/google.list && \
apt-get update && \
apt-get install -y google-chrome-stable xvfb


# EXPOSE 22 is Docker specific and not needed in a bash script.

# Assuming the 'ssh' directory is in the current directory.
cp -R ssh /home/jenkins/.ssh

# RUN commands
mkdir -p /opt/config
cd /home/jenkins/
mkdir -p .gradle/{buildOutputCleanup,build-scan-data,caches,daemon,notifications,webdriver,workers}
chown -R jenkins:jenkins /opt/config /home/jenkins
chmod 600 /home/jenkins/.ssh/id_rsa
cd /opt

# Install packages
apt-get update
apt-get install -y --no-install-recommends xz-utils golang maven vim

# Cleanup
apt-get -q clean -y
rm -rf /var/lib/apt/lists/* 
rm -f /var/cache/apt/*.bin

# Download and setup Node.js
wget https://nodejs.org/dist/v14.17.3/node-v14.17.3-linux-x64.tar.xz
tar xf /opt/node-v14.17.3-linux-x64.tar.xz
rm -rf /opt/node-v14.17.3-linux-x64.tar.xz
ln -s /opt/node-v14.17.3-linux-x64 /opt/node
ln -s /opt/node/bin/node /bin/node
ln -s /opt/node/bin/npm /bin/npm
chmod -R 777 /opt/node-v14.17.3-linux-x64

# Install global npm packages
npm install --prefix /opt/node-v14.17.3-linux-x64 -g @angular/cli
ln -s /opt/node/bin/ng /bin/ng
npm install --prefix /opt/node-v14.17.3-linux-x64 -g @angular-devkit/build-angular
npm install --prefix /opt/node-v14.17.3-linux-x64 -g typescript

# Additional configurations (similar to ADD command)
cp config /home/jenkins/.kube/config
mkdir -p /home/jenkins/.m2
chown -R jenkins:jenkins /home/jenkins
cp settings.xml /home/jenkins/.m2

# CMD is Docker specific and not needed in a bash script.
# To run sshd: /usr/sbin/sshd -D

# Set PATH
export PATH="/opt/node/bin:${PATH}"
