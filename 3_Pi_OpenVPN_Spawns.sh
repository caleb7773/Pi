#!/bin/bash

choice=n

while [[ ${choice} != [y/Y] ]];
do
read -p "What spawn is this : " spawn
echo "Is this spawn #${spawn}?"
read -p "y/[n] : " choice
done

sudo ls >/dev/null 
read -p "Press ENTER to continue"

sudo mv /tmp/client* /etc/openvpn/

sudo systemctl start openvpn@client${spawn}

