#!/bin/bash

clear

# Copy SSH Public Keys to Spawns
  choice=n
  
  while [[ ${choice} != [y/Y] ]];
  do
  clear
  read -p "Enter Spawn One IP : " spawn_one_ip
  read -p "Enter Spawn Two IP : " spawn_two_ip
  read -p "Enter Server IP : " serverip
  echo "${spawn_one_ip} and ${spawn_two_ip} : Spawns"
  echo "${serverip} : Server"
  echo "Is this information correct?"
  read -p "y/[n]" choice
 done
 

clear

# Grab the sudo password prior to advancing
  echo "Put in Sudo Password"
  sudo ls >/dev/null 
  read -p " Press ENTER to continue" enter
  clear

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
#  sudo apt-get update


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
  clear
# Grabbing new users Sudo Password
  sudo ls >/dev/null 
  read -p " Press ENTER to continue" enter
  clear
  
# Change ownership of git folder
  sudo chown vpnuser /home/kali/pi -R
  sudo chgrp vpnuser /home/kali/pi -R

# Install OpenVPN
#  sudo apt-get install openvpn git -y
  
# Generate SSH-Keys for future script
  ssh-keygen -b 2048 -t rsa -f ~/.ssh/id_rsa -N ""
  
  clear
  ssh-copy-id -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no vpnuser@${spawn_one_ip}
  read -p "Press ENTER to continue" ENTER
  
  clear
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
  mkdir {server,client-1,client-2}
  
# Server Certificates
  cp ca.crt ./server/
  grep -A 1000 'BEGIN CERTIFICATE' ./issued/vpn-server.crt > ./server/vpn-server.crt
  cp ./private/vpn-server.key ./server/
  #sudo cp dh.pem /etc/openvpn/dh.pem

# Generating Server Config file
  serverca=$(cat ./server/ca.crt)
  servercert=$(cat ./server/vpn-server.crt)
  serverkey=$(cat ./server/vpn-server.key)

sudo tee -a /etc/openvpn/vpn-server.conf << EOF
dev tun
topology subnet
server 10.99.99.0 255.255.255.0
#dh dh.pem
dh none
log vpnserver.log
keepalive 10 60
tls-server
<ca>
${serverca}
</ca>
<cert>
${servercert}
</cert>
<key>
${serverkey}
</key>
EOF


sudo systemctl enable openvpn@vpn-server
sudo systemctl start openvpn@vpn-server
  
# Client 1 Certificates to Compressed Tar
  grep -A 1000 'BEGIN CERTIFICATE' ./issued/vpn-client-1.crt > ./client-1/vpn-client-1.crt
  cp ./private/vpn-client-1.key ./client-1/

  
# Creating Spawn 1 Config file
  serverca=$(cat ./server/ca.crt)
  vpn1cert=$(cat ./client-1/vpn-client-1.crt)
  vpn1key=$(cat ./client-1/vpn-client-1.key)

sudo tee -a ./client-1/client1.conf << EOF
dev tun
client
remote ${serverip}
log vpnserver.log
keepalive 10 60
tls-client
<ca>
${serverca}
</ca>
<cert>
${vpn1cert}
</cert>
<key>
${vpn1key}
</key>
EOF

  scp -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no ./client-1/client1.conf spawn1:/tmp

  
# Client 2 Certificates to Compressed Tar
  grep -A 1000 'BEGIN CERTIFICATE' ./issued/vpn-client-2.crt > ./client-2/vpn-client-2.crt
  cp ./private/vpn-client-2.key ./client-2/

# Creating Spawn 1 Config file
  serverca=$(cat ./server/ca.crt)
  vpn2cert=$(cat ./client-2/vpn-client-2.crt)
  vpn2key=$(cat ./client-2/vpn-client-2.key)

sudo tee -a ./client-2/client2.conf << EOF
dev tun
client
remote ${serverip}
log vpn.log
keepalive 10 60
tls-client
<ca>
${serverca}
</ca>
<cert>
${vpn2cert}
</cert>
<key>
${vpn2key}
</key>
EOF

  scp -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no ./client-2/client2.conf spawn2:/tmp


echo " Complete... "

ping 10.99.99.1
