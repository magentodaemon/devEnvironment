#!/bin/sh


echo '===================================================================================================='
echo 'Export magento path'
echo '===================================================================================================='


export PATH=$PATH:/var/www/html/bin
#Add authentication keys here
composer config -g http-basic.repo.magento.com 0289563d0685aa50ee9259b9b47fb525 291de8a06bf1fa9c788ddae7f07ead73
composer config --global process-timeout 900

<<comment
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
comment



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
