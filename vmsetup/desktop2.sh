#!/bin/bash
#Created by Irvin Lemus for Bay Area Cyber Competitions
#This script will prepare an Ubuntu Cloud VM (Digital Ocean / Google Cloud) for use with 100 users via VNC with Brave, and OpenVPN installed. 

#Checking for Root:
if [[ $EUID -ne 0 ]]; then
   echo "This script must be run as root. Please try again." 
   exit 1
fi

#Installing Programs
apt update && apt dist-upgrade -y
mkdir /home/guac
apt install apt-transport-https curl xfce4 -y
curl -s https://brave-browser-apt-release.s3.brave.com/brave-core.asc | sudo apt-key --keyring /etc/apt/trusted.gpg.d/brave-browser-release.gpg add -
source /etc/os-release
echo "deb [arch=amd64] https://brave-browser-apt-release.s3.brave.com/ $UBUNTU_CODENAME main" | sudo tee /etc/apt/sources.list.d/brave-browser-release-${UBUNTU_CODENAME}.list
apt update && apt install openvpn firefox gcc gdb python3 python3-pip docker.io brave-browser zip unzip openjdk-11-jre icoutils wireshark -y

#Guacamole Server Install
apt install -y tightvncserver autoconf libcairo2-dev libjpeg-turbo8-dev libpng-dev libossp-uuid-dev libavcodec-dev libavutil-dev libswscale-dev libvncserver-dev libssl-dev libwebp-dev tomcat9 tomcat9-admin tomcat9-common tomcat9-user
wget https://sourceforge.net/projects/guacamole/files/current/source/guacamole-server-0.9.14.tar.gz
tar xzf guacamole-server-0.9.14.tar.gz 
cd guacamole-server-0.9.14
./configure --with-init-dir=/etc/init.d
make
make install
ldconfig
systemctl enable guacd
systemctl start guacd

#Guacamole Client Install
mkdir /etc/guacamole && cd /etc/guacamole
wget https://sourceforge.net/projects/guacamole/files/current/binary/guacamole-0.9.14.war
ln -s /etc/guacamole/guacamole.war /var/lib/tomcat9/webapps/
systemctl restart tomcat9
systemctl restart guacd
mkdir /etc/guacamole/extensions
mkdir /etc/guacamole/lib
echo "GUACAMOLE_HOME=/etc/guacamole" >> /etc/default/tomcat9
cat > /etc/guacamole.properties <<EOF
guacd-hostname: localhost
guacd-port:    4822
user-mapping:    /etc/guacamole/user-mapping.xml
auth-provider:    net.sourceforge.guacamole.net.basic.BasicFileAuthenticationProvider
EOF
ln -s /etc/guacamole/usr/share/tomcat9/.guacamole
cat > /etc/guacamole/user-mapping.xml <<EOF
<user-mapping>
        
    <!-- Per-user authentication and config information -->

    <!-- A user using md5 to hash the password
         amos user and its md5 hashed password below is used to 
             login to Guacamole Web UI-->
    <authorize 
            username="root"
            password="924a613e6af2068815caf77825c684cb"
            encoding="md5">

        <!-- First authorized connection -->
        <connection name="BACCC Desktop">
            <protocol>vnc</protocol>
            <param name="hostname">localhost/param>
            <param name="port">5901</param>
            <param name="username">root</param>
        </connection>

    </authorize>

</user-mapping>
EOF

#Create Users
clear
echo "Creating Users"
counter=1
while  [ $counter -le 100 ]
do
        useradd -s /bin/bash -m bcl$counter
        usermod -aG sudo bcl$counter
        echo bcl$counter:cyber123$ | chpasswd
        ((counter++))
done
tightvncserver
#}

#function certbot {
#Install certbot.
#add-apt-repository ppa:certbot/certbot -y;
#apt update;
#apt install certbot python-certbot-nginx -y;
#certbot --nginx certonly
#/etc/init.d/nginx restart

#function final {
#echo "########################################################################"
#echo "Desktop Server is ready."
#echo "Please go to the https://"$dns" to continue."
#echo "########################################################################"
#}

#echo "############################################################################################"
#echo "This script will install and perform the intial configuration for a Desktop Ubuntu with VNC."
#echo "Do you have an FQDN for this system (y/n)"
#echo "############################################################################################"
#read answer
#if [[ $answer == y ]]; then
#	echo "What is the FQDN?"
#	read dns
#	programs
#	guacamole
#	guac-client
#	certbot
#	bashusers
#	final
#else
#echo "halt"