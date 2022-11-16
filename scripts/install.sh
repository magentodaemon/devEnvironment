#!/bin/sh

#Script to install PHP

#First update library

echo '===================================================================================================='
echo 'Updating distribution package list'
echo '===================================================================================================='

apt update
apt install -y lsb-release ca-certificates apt-transport-https software-properties-common gnupg2
echo "deb [trusted=yes] https://packages.sury.org/php/ $(lsb_release -sc) main" | tee /etc/apt/sources.list.d/sury-php.list
curl -fsSL  https://packages.sury.org/php/apt.gpg|  gpg --dearmor -o -y /etc/apt/trusted.gpg.d/sury-keyring.gpg
apt update

echo '===================================================================================================='
echo 'Updating PHP packages and list'
echo '===================================================================================================='


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

echo '===================================================================================================='
echo 'Installing GIT'
echo '===================================================================================================='
#Git is sometimes required by composer so install git on webserver
apt install -y git

echo '===================================================================================================='
echo 'Installing Maria DB Client'
echo '===================================================================================================='
#MariaDB client to check connection with DB
apt install -y mariadb-client

echo '===================================================================================================='
echo 'Installing Unzip'
echo '===================================================================================================='
#Install unzip as it is required by composer
apt install -y unzip


echo '===================================================================================================='
echo 'Overwriting configuration for nginx and phpfpm and php.ini'
echo '===================================================================================================='
#Overwrite Configuration for ngnix
cp /var/www/scripts/ngnixOverwrite/default.conf /etc/nginx/conf.d/
cp /var/www/scripts/ngnixOverwrite/magento.conf /etc/nginx/conf.d/
#Overwrite Configuration for PHP-FPM
cp /var/www/scripts/phpFpmOverwrite/www.conf /etc/php/8.1/fpm/pool.d/
cp /var/www/scripts/phpFpmOverwrite/php.ini /etc/php/8.1/fpm/

echo '===================================================================================================='
echo 'Restart nginx and phpfpm'
echo '===================================================================================================='

#Start PHP FPM as service
service php8.1-fpm start

service nginx reload

echo '===================================================================================================='
echo 'Installing composer and add it into export path add auth keys to composer, increase timeout'
echo '===================================================================================================='

#Install composer
curl -sS https://getcomposer.org/installer | php -- --install-dir=/usr/bin --filename=composer
#Change export path
export PATH=$PATH:/var/www/html/bin
#Add authentication keys here
composer config -g http-basic.repo.magento.com $MAGENTO_PUBLIC_KEY $MAGENTO_PRIVATE_KEY
composer config --global process-timeout 900

<<comment
#This is for first time load if magento repo doesn't exists
echo '===================================================================================================='
echo 'Clear and create project at webserver root';
echo '===================================================================================================='
cd /var/www/html/
#Remove all content inside webroot
rm -rf *
rm -rf .* 
#Create magento community-edition repository
composer create-project --repository-url=https://repo.magento.com/ magento/project-community-edition=2.4.5 /var/www/html
comment

echo '===================================================================================================='
echo 'Changing file permissions inside magento root directory'
echo '===================================================================================================='

#Changing file permissions 
find /var/www/html/var /var/www/html/generated /var/www/html/vendor /var/www/html/pub/static /var/www/html/pub/media /var/www/html/app/etc -type f -exec chmod g+w {} +

echo '===================================================================================================='
echo 'Changing directory permissions inside magento root directory'
echo '===================================================================================================='


find /var/www/html/var /var/www/html/generated /var/www/html/vendor /var/www/html/pub/static /var/www/html/pub/media /var/www/html/app/etc -type d -exec chmod g+ws {} +

echo '===================================================================================================='
echo 'Changing File directory ownership inside magento root directory'
echo '===================================================================================================='

chown -R :nginx /var/www/html/

echo '===================================================================================================='
echo 'Changing execute permission inside magento root directory'
echo '===================================================================================================='

chmod u+x /var/www/html/bin/magento

echo '===================================================================================================='
echo 'Create database for magento'
echo '===================================================================================================='
mysql -h $DB_HOST -u $DB_USER -p$DB_PASSWORD -e 'create database magento;'

echo '===================================================================================================='
echo 'Import data into magento'
echo '===================================================================================================='
zcat /var/www/scripts/magento.sql.gz | sed -e 's/DEFINER[ ]*=[ ]*[^*]*\*/\*/' | mysql -h $DB_HOST -P 3306 -p$DB_PASSWORD -u  $DB_USER magento


## This is for first time installation only
<<comment
echo '===================================================================================================='
echo 'Installing magento'
echo '===================================================================================================='


/var/www/html/bin/magento setup:install \
--base-url=http://localhost/ \
--db-host=$DB_HOST \
--db-name=$DB_NAME \
--db-user=$DB_USER \
--db-password=$DB_PASSWORD \
--admin-firstname=admin \
--admin-lastname=admin \
--admin-email=admin@admin.com \
--admin-user=admin \
--admin-password=admin123 \
--language=en_US \
--currency=USD \
--timezone=America/Chicago \
--use-rewrites=1 \
--search-engine=elasticsearch7 \
--elasticsearch-host=search \
--elasticsearch-port=9200 \
--elasticsearch-index-prefix=magento2 \
--elasticsearch-timeout=15 \
--amqp-host=$Q_HOST \
--amqp-port=$Q_PORT \
--amqp-user=$Q_USER \
--amqp-password=$Q_PASS \
--amqp-virtualhost="/"

comment

echo '===================================================================================================='
echo 'Setting up redis for backend cache'
echo '===================================================================================================='
/var/www/html/bin/magento setup:config:set --cache-backend=redis --cache-backend-redis-server=cache --cache-backend-redis-db=0

echo '===================================================================================================='
echo 'Setting up redis for page cache'
echo '===================================================================================================='
/var/www/html/bin/magento setup:config:set --page-cache=redis --page-cache-redis-server=cache --page-cache-redis-db=1


echo '===================================================================================================='
echo 'Disable Two factor authentication'
echo '===================================================================================================='

/var/www/html/bin/magento module:disable Magento_TwoFactorAuth


echo '===================================================================================================='
echo 'Installing cron on system'
echo '===================================================================================================='
apt install -y cron

echo '===================================================================================================='
echo 'Installing magento cron'
echo '===================================================================================================='

/var/www/html/bin/magento cron:install --force
