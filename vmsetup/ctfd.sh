#!/bin/bash
#CTFd Install and Configuration Script
#Created by Jacobs Otto and Irvin Lemus
#Updated by Ryan Garcia, Janelly Servin and Brandon Pimentel.

CTF_NAME="CTFd"

#Root Required
if [[ $EUID -ne 0 ]]; then
   echo "This script must be run as root." 
   exit 1
fi

function setup {
#Perform updates
apt-get update -qq
apt-get install -qq -y build-essential git ufw libffi-dev \
python3-dev python3-pip software-properties-common

#Setup CTFd home.
mkdir /home/CTFd
cd /home/CTFd

#Get CTFd.
git clone https://github.com/CTFd/CTFd.git
cd CTFd
pip3 install -r requirements.in

#Uncomment if you want to edit the config file.
#vim CTFd/config.py;

cat > /home/CTFd/CTFd/start.sh <<EOL
cd /home/CTFd/CTFd
service nginx start
nohup gunicorn -c gunicorn.cfg "CTFd:create_app()"&
EOL
cat > /home/CTFd/CTFd/gunicorn.cfg <<EOL
import multiprocessing

bind = "0.0.0.0:8000"
workers = multiprocessing.cpu_count() * 2 + 1
threads = 2
worker_class = "gevent"
worker_connections = 400
timeout = 30
keepalive = 2
EOL
chmod +x start.sh
#Adding Postgres SQL
#pw=$(head /dev/urandom | md5sum)
#dbpw=$(echo $pw | awk '{print $1}')
#su postgres -c "psql -U postgres -d postgres -c \"alter user postgres with password '$dbpw';\""
#CREATE EXTENSION adminpack;
#echo "postgres://postgres:$dbpw@localhost/ctfd" >> config.py
#python config.py
}

function https {
#Install nginx.
apt-get -qq -y install nginx
ufw allow 'Nginx Full'
ufw allow 'Nginx HTTP'
ufw allow 'Nginx HTTPS'

#Nginx Configuration
rm /etc/nginx/nginx.conf
cat > /etc/nginx/nginx.conf <<EOL
user www-data;
worker_processes 4;
pid /run/nginx.pid;
worker_rlimit_nofile 1500;

events {
    	worker_connections 1500;
    	# multi_accept on;
}

http {

    	open_file_cache max=1024 inactive=10s;
    	open_file_cache_valid 120s;
    	open_file_cache_min_uses 1;
    	open_file_cache_errors on;

    	##
    	# Basic Settings
    	##

    	sendfile on;
    	tcp_nopush on;
    	tcp_nodelay on;
    	keepalive_timeout 65;
    	types_hash_max_size 2048;
    	# server_tokens off;

    	# server_names_hash_bucket_size 64;
    	# server_name_in_redirect off;

    	include /etc/nginx/mime.types;
    	default_type application/octet-stream;
        client_max_body_size 1G;

    	##
    	# SSL Settings
    	##

    	ssl_protocols TLSv1 TLSv1.1 TLSv1.2; # Dropping SSLv3, ref: POODLE
    	ssl_prefer_server_ciphers on;

    	##
    	# Logging Settings
    	##

    	access_log /var/log/nginx/access.log;
    	error_log /var/log/nginx/error.log;

    	##
    	# Gzip Settings
    	##

    	gzip on;
    	gzip_disable "msie6";

    	# gzip_vary on;
    	# gzip_proxied any;
    	# gzip_comp_level 6;
    	# gzip_buffers 16 8k;
    	# gzip_http_version 1.1;
    	# gzip_types text/plain text/css application/json application/javascript text/xml application/xml application/xml+rss text/javascript;

    	##
    	# Virtual Host Configs
    	##

    	include /etc/nginx/conf.d/*.conf;
    	include /etc/nginx/sites-enabled/*;
}


#mail {
#   	# See sample authentication script at:
#   	# http://wiki.nginx.org/ImapAuthenticateWithApachePhpScript
#
#   	# auth_http localhost/auth.php;
#   	# pop3_capabilities "TOP" "USER";
#   	# imap_capabilities "IMAP4rev1" "UIDPLUS";
#
#   	server {
#           	listen 	localhost:110;
#           	protocol   pop3;
#           	proxy  	on;
#   	}
#
#   	server {
#           	listen 	localhost:143;
#           	protocol   imap;
#           	proxy  	on;
#   	}
#}
EOL


#Install certbot.
nohup /home/CTFd/CTFd/start.sh
sleep 10
nohup /home/CTFd/CTFd/start.sh &
apt-get install -qq -y certbot python3-certbot-nginx
certbot --nginx --register-unsafely-without-email --agree-tos --no-redirect -d $dns
cat > /etc/nginx/sites-available/CTFd <<EOL
proxy_cache_path /home/CTFd/nginxCache levels=1:2 keys_zone=my_cache:10m max_size=8g
             	inactive=10m use_temp_path=off;
server {
    	listen 80 default_server;
    	listen [::]:80 default_server;
    	server_name _;
    	return 301 https://$dns$request_uri;
}

server {
    	listen 443 ssl;
    	ssl_certificate /etc/letsencrypt/live/$dns/fullchain.pem;
    	ssl_certificate_key /etc/letsencrypt/live/$dns/privkey.pem;
    	include /etc/letsencrypt/options-ssl-nginx.conf;
    	server_name CTFd;
    	location = /favicon.ico { access_log off; log_not_found off; }
 location /static/ {
    	root /home/CTFd/CTFd/CTFd;
 }
    	location / {
    	include proxy_params;
    	proxy_cache my_cache;
    	proxy_pass http://localhost:8000;
    	}
 }
EOL
rm /etc/nginx/sites-enabled/default
ln -s /etc/nginx/sites-available/CTFd /etc/nginx/sites-enabled/default
/etc/init.d/nginx restart

#Create File to run CTFd at boot
cat > /home/CTFd/CTFd/cron.sh <<EOL
#!/bin/bash
#Setup persistence for CTFd.
CTF_NAME="CTFd"
cd /etc/cron.d/;
echo -e "SHELL=/bin/sh" > $CTF_NAME;
echo -e "PATH=/usr/local/sbin:/usr/local/bin:/sbin:/bin:/usr/sbin:/usr/bin" >> $CTF_NAME;
EOL
chmod +x cron.sh && ./cron.sh;
echo "########################################################################"
echo "CTFd is ready"
echo "Please go to the https://"$dns" to continue."
echo "########################################################################"
}

function http {
#Create File to run CTFd at boot
cat > /home/CTFd/CTFd/gunicorn.cfg <<EOL
import multiprocessing

bind = "0.0.0.0:80"
workers = multiprocessing.cpu_count() * 2 + 1
threads = 2
worker_class = "gevent"
worker_connections = 400
timeout = 30
keepalive = 2
EOL

cat > /home/CTFd/CTFd/cron.sh <<EOL
#!/bin/bash
#Setup persistence for CTFd.
CTF_NAME="CTFd"
cd /etc/cron.d/;
echo -e "SHELL=/bin/sh" > $CTF_NAME;
echo -e "PATH=/usr/local/sbin:/usr/local/bin:/sbin:/bin:/usr/sbin:/usr/bin" >> $CTF_NAME;
EOL

chmod +x cron.sh && ./cron.sh;
nohup /home/CTFd/CTFd/start.sh
sleep 10
nohup /home/CTFd/CTFd/start.sh &
echo "########################################################################"
echo "CTFd is ready without a Domain"
echo "Please go to the IP address in a browser continue."
echo "########################################################################"
}

echo "########################################################################"
echo "This script will install and perform the intial configuration for CTFd."
echo "Do you have an FQDN for this server (y/n)"
echo "#######################################################################"
read answer
if [[ $answer == y ]]; then
	echo "What is the FQDN?"
	read dns
	setup
	https
else
	setup
	http
fi
