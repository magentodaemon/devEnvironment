#!/bin/sh

#Script to install PHP

#First update library
apt update
apt install -y lsb-release ca-certificates apt-transport-https software-properties-common gnupg2
echo "deb [trusted=yes] https://packages.sury.org/php/ $(lsb_release -sc) main" | tee /etc/apt/sources.list.d/sury-php.list
curl -fsSL  https://packages.sury.org/php/apt.gpg|  gpg --dearmor -o -y /etc/apt/trusted.gpg.d/sury-keyring.gpg
apt update

#Install php and its dependencies
apt install -y php8.1
apt install -y php8.1-mysql
apt install -y php8.1-bcmath
apt install -y php8.1-fpm
apt install -y php8.1-cgi
apt install -y php8.1-pdo
apt install -y php8.1-xml
apt install -y php8.1-zip
apt install -y php8.1-intl
apt install -y php8.1-gd
apt install -y php8.1-cli
apt install -y php8.1-bz2
apt install -y php8.1-curl
apt install -y php8.1-mbstring
apt install -y php8.1-opcache
apt install -y php8.1-soap
apt install -y php8.1-pdo
apt install -y php8.1-iconv
apt install -y libxml2
apt install -y openssl
apt install -y libapache2-mod-php

#Overwrite Configuration for ngnix
cp /var/www/html/ngnixOverwrite/default.conf /etc/nginx/conf.d/

#Overwrite Configuration for PHP-FPM
cp /var/www/html/phpFpmOverwrite/www.conf /etc/php/8.1/fpm/pool.d/

cp /var/www/html/phpFpmOverwrite/php.ini /etc/php/8.1/fpm/

#Start PHP FPM as service
service php8.1-fpm start

service nginx reload

#Install composer

curl -sS https://getcomposer.org/installer | php -- --install-dir=/usr/bin --filename=composer

