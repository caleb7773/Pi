#!/bin/bash


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
  clear
# Grabbing new users Sudo Password
  sudo ls >/dev/null 
  read -p " Press ENTER to continue" enter
  clear
  
# Change ownership of git folder
  sudo chown vpnuser /home/kali/pi -R
  sudo chgrp vpnuser /home/kali/pi -R

# Install OpenVPN
  sudo apt-get install openvpn -y
  

looper() {
done=n
  if [[ -e /tmp/client1.conf ]] || [[ -e /tmp/client2.conf ]];
  then
  sudo mv /tmp/client* /etc/openvpn/
config=$(sudo ls /etc/openvpn/client* | cut -d '.' -f 1)
  sudo systemctl enable openvpn@${config}
  sudo systemctl start openvpn@${config}
done=y
  fi
}i
done=n
while [[ ${done} == 'n' ]];
do
looper
sleep 1s
echo "Still waiting..."
done
    
  ping 10.99.99.1
