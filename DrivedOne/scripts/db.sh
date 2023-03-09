echo '===================================================================================================='
echo 'Create database for magento we can run this command in bash'
echo '===================================================================================================='
zcat magento.sql.gz | sed -e 's/DEFINER[ ]*=[ ]*[^*]*\*/\*/' | mysql -h localhost -P 3306 -pmagento -u  magento magento