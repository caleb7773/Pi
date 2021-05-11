#!/bin/bash

clear

# Grab the sudo password prior to advancing
  echo "Put in Sudo Password"
  sudo ls # Enter Default Password for Sudo
  read -p " Press ENTER to continue" enter

# Create new vpn user
  sudo useradd vpnuser

# Change users password  
  sudo sh -c 'echo vpnuser:vpnuserpassword | chpasswd'

# Add user to Sudo Group
  sudo usermod -aG sudo vpnuser

# Give user access to bash shell by default
  sudo sed -i 's/vpnuser:\/bin\/sh/vpnuser:\/bin\/bash/g' /etc/passwd

# Make users Home Directory  
  sudo mkdir /home/vpnuser

# Give ownership to new user
  sudo chown vpnuser /home/vpnuser
  
# Give group ownership to new user
  sudo chgrp vpnuser /home/vpnuser

# Update the system
  sudo apt-get update


# Delete default Kali User
sudo vim -E -s /etc/passwd << EOF
:g /kali/d
:wq
EOF

# Switching to new user
  clear
  echo "Switch users to vpnuser"
  su vpnuser     # Enter vpnuserpassword
  read -p " Press ENTER to continue" enter
  
# Grabbing new users Sudo Password
  sudo ls 
  read -p " Press ENTER to continue" enter

# Generate SSH-Keys for future script
  ssh-keygen -b 2048 -t rsa -f ~/.ssh/id_rsa -N ""
  
# Copy SSH Public Keys to Spawns
  choice=n
  
  while [[ ${choice} != [y/Y] ]];
  do
  read -p "Enter Spawn One IP : " spawn_one_ip
  read -p "Enter Spawn Two IP : " spawn_two_ip
  echo "${spawn_one_ip} and ${spawn_two_ip} : Are these correct?"
  read -p "y/[n]" choice
  done
  
  ssh-copy-id -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no vpnuser@${spawn_one_ip}
  read -p "Press ENTER to continue" ENTER
  
  ssh-copy-id -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no vpnuser@${spawn_two_ip}
  read -p "Press ENTER to continue" ENTER
  
# Creating SSH Config File
  sudo tee -a ~/.ssh/config << EOF
Host spawn1
        Hostname ${spawn_one_ip}
        Port 22
        User vpnuser
        IdentityFile ~/.ssh/id_rsa
        
Host spawn2
        Hostname ${spawn_two_ip}
        Port 22
        User vpnuser
        IdentityFile ~/.ssh/id_rsa
EOF
  
# Install GIT & OpenVPN
  sudo apt-get install openvpn git -y

# Install EasyRSA
  cd /opt
  sudo git clone https://github.com/OpenVPN/easy-rsa.git
  sudo chown vpnuser:vpnuser /opt/easy-rsa -R
  
# Create CA Certificate
  cd /opt/easy-rsa/easyrsa3
  ./easyrsa init-pki
  ./easyrsa --batch "--req-cn=openvpn.server" build-ca nopass
  
# Create Server Certificate
  ./easyrsa build-server-full vpn-server nopass
  
# Create Two Client Certificates
  ./easyrsa build-client-full vpn-client-1 nopass
  ./easyrsa build-client-full vpn-client-2 nopass

# Create the DH Key
  ./easyrsa gen-dh

# Compiling certificates
  cd pki
  mkdir {tar,server,client-1,client-2}
  
# Server Certificates to Compressed Tar
  cp ca.crt ./server/
  cp ./issued/vpn-server.crt ./server/
  cp ./private/vpn-server.key ./server/
  cp dh.pem ./server/

  tar cvf ./tar/server.tar ./server/*
  
# Client 1 Certificates to Compressed Tar
  cp ca.crt ./client-1/
  cp ./issued/vpn-client-1.crt ./client-1/
  cp ./private/vpn-client-1.key ./client-1/
  cp dh.pem ./client-1/

  tar cvf ./tar/client-1.tar ./client-1/*
  
# Client 2 Certificates to Compressed Tar
  cp ca.crt ./client-2/
  cp ./issued/vpn-client-2.crt ./client-2/
  cp ./private/vpn-client-2.key ./client-2/
  cp dh.pem ./client-2/

  tar cvf ./tar/client-2.tar ./client-2/*
  
# Push the Tar files out to the spawn clients
  scp -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no ./tar/client-1.tar spawn1:/tmp/
  scp -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no ./tar/client-2.tar spawn2:/tmp/


