#!/bin/bash
if id deployer >/dev/null 2>&1; then
    echo "User deployer already exists"
else
    # Add deployer group and user
    groupadd -g 10000 deployer
    useradd -g 10000 deployer

    # Setup PAM rules to allow deployer members to do su -l deployer
    sed -i '/pam_rootok.so$/a auth            [success=ignore default=1] pam_succeed_if.so user = deployer\nauth            sufficient      pam_succeed_if.so use_uid user ingroup deployer' /etc/pam.d/su

    # Setup yum repository for installing Docker Community Engine
    yum install -y yum-utils device-mapper-persistent-data lvm2   
    yum-config-manager --add-repo https://download.docker.com/linux/centos/docker-ce.repo

    # Install Docker Community Engine
    yum install -y docker-ce docker-ce-cli containerd.io

    # Create docker group and add deployer to it
    groupadd docker
    usermod -aG docker deployer

    # Enable Docker to always run as a daemon
    systemctl enable docker
    systemctl start docker
    
    # Install Docker Compose
    curl -L "https://github.com/docker/compose/releases/download/1.25.4/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
    chmod +x /usr/local/bin/docker-compose
    ln -s /usr/local/bin/docker-compose /usr/bin/docker-compose
    
    # Install the Cloud Monitoring Agent
    curl -sSO https://dl.google.com/cloudagents/add-monitoring-agent-repo.sh
    bash add-monitoring-agent-repo.sh
    yum install -y stackdriver-agent
    
    # Enable the Cloud Monitoring Agent to run as a daemon
    systemctl enable stackdriver-agent
    systemctl start stackdriver-agent
fi
