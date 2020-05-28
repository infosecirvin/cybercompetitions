#!/bin/bash
#This script will prepare a Debian Cloud VM (Digital Ocean) into a Kali Machine.
#Created by Irvin Lemus for Bay Area Cyber Competitions

#Checking for Root:
if [[ $EUID -ne 0 ]]; then
   echo "This script must be run as root. Please try again." 
   exit 1
fi
clear
echo "#################################################################"
echo "This script will prepare a DEBIAN image for use as Kali Linux."
echo ""
echo "Please ensure this VM is a DEBIAN VM or you may run into issues."
echo ""
echo "#################################################################"
sleep 5
 
#Installing Updates                                   
clear
apt update && apt dist-upgrade -y
apt install dirmngr -y

#Adding Kali Repo
echo "deb http://http.kali.org/kali kali-rolling main non-free contrib" >> /etc/apt/sources.list
apt-key adv --keyserver hkp://keys.gnupg.net --recv-keys 7D8D0BF6
clear
apt update && apt dist-upgrade -y
apt install kali-linux-default -y

counter=1
while  [ $counter -le 100 ]
do
        useradd -s /bin/bash -m baccc$counter
        usermod -aG sudo baccc$counter
        echo baccc$counter:baccc123 | chpasswd
        ((counter++))
done

#enable RDP to the VM
apt install xfce4 xrdp -y
sed -i '7i\echo xfce4-session >~/.xsession\' /etc/xrdp/startwm.sh
service xrdp restart
echo "Ready for Work"