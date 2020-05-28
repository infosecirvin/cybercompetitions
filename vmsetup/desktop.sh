#!/bin/bash
#Created by Irvin Lemus for Bay Area Cyber Competitions
#This script will prepare an Ubuntu Cloud VM (Digital Ocean / Google Cloud) for use with 100 users via RDP with Brave, and OpenVPN installed. 

#Checking for Root:
if [[ $EUID -ne 0 ]]; then
   echo "This script must be run as root. Please try again." 
   exit 1
fi
#Updates First
apt update && apt dist-upgrade -y

#Install Necessary Programs
apt install apt-transport-https curl xfce4 xrdp -y
curl -s https://brave-browser-apt-release.s3.brave.com/brave-core.asc | sudo apt-key --keyring /etc/apt/trusted.gpg.d/brave-browser-release.gpg add -
source /etc/os-release
echo "deb [arch=amd64] https://brave-browser-apt-release.s3.brave.com/ $UBUNTU_CODENAME main" | sudo tee /etc/apt/sources.list.d/brave-browser-release-${UBUNTU_CODENAME}.list

#Install Programs
apt update && apt install openvpn firefox gcc gdb python3 python3-pip docker.io brave-browser zip unzip openjdk-11-jre icoutils wireshark -y

#User Creation; comment the while loop if you are deploying this locally
clear
echo "Creating Users"
counter=1
while  [ $counter -le 100 ]
do
        useradd -s /bin/bash -m baccc$counter
        usermod -aG sudo baccc$counter
        usermod -aG admin baccc$counter #comment this line if running on docker
        echo baccc$counter:baccc123 | chpasswd
        ((counter++))
done

#enable RDP
sed -i '7i\echo xfce4-session >~/.xsession\' /etc/xrdp/startwm.sh
service xrdp restart
echo "Ready for Work"