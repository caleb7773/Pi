#!/bin/bash

#choice=n

#while [[ ${choice} != [y/Y] ]];
#do
#read -p "What spawn is this : " spawn
#echo "Is this spawn #${spawn}?"
#read -p "y/[n] : " choice
#done

sudo ls >/dev/null 
read -p "Press ENTER to continue"

sudo mv /tmp/client* /etc/openvpn/

config=$(sudo ls /etc/openvpn/client* | cut -d '.' -f 1)

sudo systemctl start openvpn@${config}
sudo systemctl stop openvpn@${config}
sudo systemctl enable openvpn@${config}
sudo systemctl start openvpn@${config}
