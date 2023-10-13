#!/bin/bash

# Check if Vagrant is installed
if ! [ -x "$(command -v vagrant)" ]; then
    echo "Vagrant is not installed. Please install Vagrant and retry."
    exit 1
fi

# Check if the required Vagrant box is available
vagrant box list | grep "ubuntu/focal64" || {
    echo "Downloading Ubuntu 20.0 Vagrant box..."
    vagrant box add ubuntu/folca64
}

# Create a directory for the Vagrant project
if [ ! -d Clusterlamp ]; then
    mkdir Clusterlamp
fi

# Create Vagrant project directory
mkdir -p Clusterlamp
cd Clusterlamp

# Initialize Vagrant project with two Ubuntu boxes
vagrant init ubuntu/focal64

cat <<EOF > Vagrantfile
Vagrant.configure("2") do |config|

config.vm.define "master" do |master|

    master.vm.hostname = "master"
    master.vm.box = "ubuntu/focal64"
    master.vm.network "private_network", ip: "192.168.33.11"

    master.vm.provision "shell", inline: <<-SHELL
    sudo apt-get update && sudo apt-get upgrade -y
     sudo apt-get install -y avahi-daemon libnss-mdns
    sudo apt install sshpass -y
   # sudo sed -i 's/PasswordAuthentication no/PasswordAuthentication yes/' /etc/ssh/sshd_config
   # sudo systemctl restart sshd
    SHELL
  end

  config.vm.define "slave" do |slave|

    slave.vm.hostname = "slave"
    slave.vm.box = "ubuntu/focal64"
    slave.vm.network "private_network", ip: "192.168.33.12"

    slave.vm.provision "shell", inline: <<-SHELL
    sudo apt-get update && sudo apt-get upgrade -y
    sudo apt install sshpass -y
    sudo sed -i 's/PasswordAuthentication no/PasswordAuthentication yes/' /etc/ssh/sshd_config
    sudo systemctl restart sshd
    sudo apt-get install -y avahi-daemon libnss-mdns
    SHELL
  end

    config.vm.provider "virtualbox" do |vb|
      vb.memory = "1024"
      vb.cpus = "2"
    end
end
EOF

# Create and configure Master Node
echo "Creating Master Node..."
vagrant up master

# Create and configure Slave Node
echo "Creating Slave Node..."
vagrant up slave

#  Create a user named altschool and grant altschool user root (superuser) privileges.
vagrant ssh master <<EOF
    sudo useradd -m -G sudo altschool
    sudo usermod -aG root altschool
EOF

# SSH key-based authentication setup
echo "Setting up SSH key-based authentication..."
ssh-keygen -t rsa -N "" -f ~/.ssh/id_rsa
cat ~/.ssh/id_rsa.pub | ssh vagrant@192.168.33.11 'cat >> ~/.ssh/authorized_keys'
cat ~/.ssh/id_rsa.pub | ssh vagrant@192.168.33.12 'cat >> ~/.ssh/authorized_keys'

# Copy files from Master to Slave
echo "Copying files from Master to Slave..."
rsync -avz -e ssh /mnt/altschool/ vagrant@192.168.33.11:/mnt/altschool/slave

# Install LAMP Stack on Master
echo "Installing LAMP Stack on Master..."
vagrant ssh master -c 'sudo apt update && sudo apt install -y apache2 php-mysql php libapache2-mod-php'

# Secure MySQL installation and initialize
echo "Securing MySQL installation on Master..."
vagrant ssh master -c 'sudo mysql_secure_installation'

# Create test PHP page on Master
echo "Creating test PHP page on Master..."
echo "<?php phpinfo(INFO_GENERAL); ?>" > /var/www/html/index.php

# Install LAMP Stack on Slave
echo "Installing LAMP Stack on Slave..."
vagrant ssh slave -c 'sudo apt update && sudo apt install -y apache2 php-mysql php libapache2-mod-php'

# Secure MySQL installation and initialize on Slave
echo "Securing MySQL installation on Slave..."
vagrant ssh slave -c 'sudo mysql_secure_installation'

# Create test PHP page on Slave
echo "Creating test PHP page on Slave..."
vagrant ssh slave -c 'echo "<?php phpinfo(INFO_GENERAL); ?>" > /var/www/html/index.php'

# Start Apache on both nodes
echo "Starting Apache on both nodes..."
vagrant ssh master -c 'sudo systemctl start apache2 && sudo systemctl enable apache2'
vagrant ssh slave -c 'sudo systemctl start apache2 && sudo systemctl enable apache2'

# Install nginx on Master for Load Balancing
echo "Installing nginx on Master for Load Balancing..."
vagrant ssh master -c 'sudo apt install -y nginx'

# Configure nginx for Load Balancing
echo "Configuring nginx for Load Balancing..."
cat <<EOF > /tmp/nginx.conf
http {
  upstream backend {
    server 192.168.33.11;
    server 192.168.33.12;
  }

  server {
    listen 80;
    server_name localhost;

    location / {
      proxy_pass http://backend;
      proxy_set_header Host \$host;
      proxy_set_header X-Real-IP \$remote_addr;
    }
  }
}
EOF
vagrant ssh master -c 'sudo cp /tmp/nginx.conf /etc/nginx/nginx.conf'
vagrant ssh master -c 'sudo systemctl restart nginx'

# Display process overview on Master
echo "Displaying process overview on Master..."
vagrant ssh master -c 'ps aux'

echo "Deployment completed!"
