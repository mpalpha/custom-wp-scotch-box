#!/usr/bin/env bash

# Ubuntu utilities
. '/vagrant/vagrant-shell-scripts/ubuntu.sh'

# set php.ini options
printf "\n"
printf "\r\nphp.ini: updating...upload_max_filesize"
printf "\n"
php-settings-update 'upload_max_filesize' '240M'
printf "\r\nphp.ini: updating...post_max_size"
printf "\n"
php-settings-update 'post_max_size' '50M'
printf "\r\nphp.ini: updating...max_execution_time"
printf "\n"
php-settings-update 'max_execution_time' '100'
printf "\r\nphp.ini: updating...max_input_time"
printf "\n"
php-settings-update 'max_input_time' '223'

# update composer
printf "\n"
printf "\r\nComposer: updating..."
/usr/local/bin/composer self-update > /dev/null 2>&1

# if a file does not exist...
if [ ! -f /etc/dbconfig-common/phpmyadmin.conf ];
then

printf "\rphpMyAdmin not found, installing..."

#setup database
MYSQL_PASSWORD="root"
SYS_PASSWORD="root"

printf "\n"
printf "\r\nphpMyAdmin: configuring..."
echo "phpmyadmin phpmyadmin/dbconfig-install boolean false" | debconf-set-selections
echo "phpmyadmin phpmyadmin/reconfigure-webserver multiselect apache2" | debconf-set-selections

printf "\rphpMyAdmin: creating user..."
echo "phpmyadmin phpmyadmin/app-password-confirm password $SYS_PASSWORD" | debconf-set-selections
echo "phpmyadmin phpmyadmin/mysql/admin-pass password $MYSQL_PASSWORD" | debconf-set-selections
echo "phpmyadmin phpmyadmin/password-confirm password $SYS_PASSWORD" | debconf-set-selections
echo "phpmyadmin phpmyadmin/setup-password password $SYS_PASSWORD" | debconf-set-selections
echo "phpmyadmin phpmyadmin/database-type select mysql" | debconf-set-selections
echo "phpmyadmin phpmyadmin/mysql/app-pass password $SYS_PASSWORD" | debconf-set-selections

printf "\rphpMyAdmin: creating database..."
echo "dbconfig-common dbconfig-common/mysql/app-pass password $SYS_PASSWORD" | debconf-set-selections
echo "dbconfig-common dbconfig-common/mysql/app-pass password" | debconf-set-selections
echo "dbconfig-common dbconfig-common/password-confirm password $SYS_PASSWORD" | debconf-set-selections
echo "dbconfig-common dbconfig-common/app-password-confirm password $SYS_PASSWORD" | debconf-set-selections
echo "dbconfig-common dbconfig-common/app-password-confirm password $SYS_PASSWORD" | debconf-set-selections
echo "dbconfig-common dbconfig-common/password-confirm password $SYS_PASSWORD" | debconf-set-selections

#echo "CREATE DATABASE ado;" | mysql -u root -p$MYSQL_PASSWORD
#echo "CREATE USER 'ado'@'localhost' IDENTIFIED BY 'ado';" | mysql -u root -p$MYSQL_PASSWORD
#echo "GRANT ALL ON ado.* TO 'ado'@'localhost';" | mysql -u root -p$MYSQL_PASSWORD
#echo "GRANT CREATE ON ado.* TO 'ado'@'localhost';" | mysql -u root -p$MYSQL_PASSWORD
#echo "FLUSH PRIVILEGES;" | mysql -u root -p$MYSQL_PASSWORD

# install phpmyadmin
printf "\rphpMyAdmin: creating link..."
apt-get -y install phpmyadmin > /dev/null 2>&1

echo "Include /etc/phpmyadmin/apache.conf" | tee -a /etc/apache2/apache2.conf > /dev/null 2>&1

# Restart services
printf "\rphpMyAdmin: applying settings..."
service apache2 restart > /dev/null 2>&1
service mysql restart > /dev/null 2>&1

printf "\rphpMyAdmin: installation complete"

else

printf "\rphpMyAdmin was found, skipping installation"

fi


if [ ! -f /usr/local/bin/wp ];
then

printf "\n"
printf "\rWP-CLI not found, installing..."
#composer create-project wp-cli/wp-cli /usr/share/wp-cli --no-dev > /dev/null 2>&1
#composer create-project wp-cli/wp-cli --no-dev
wget --no-check-certificate https://raw.githubusercontent.com/wp-cli/builds/gh-pages/phar/wp-cli.phar > /dev/null 2>&1
printf "\n"
printf "\rWP-CLI: setting up..."
#sudo ln -s /usr/share/wp-cli/bin/wp /usr/bin/wp > /dev/null 2>&1
chmod +x wp-cli.phar > /dev/null 2>&1
#sudo ln -s /home/vagrant/wp-cli/bin/wp > /dev/null 2>&1
printf "\n"
printf "\rWP-CLI: setting permissions..."
sudo mv wp-cli.phar /usr/local/bin/wp > /dev/null 2>&1
#sudo -u vagrant -i chmod +x /usr/bin/wp > /dev/null 2>&1
printf "\n"
printf "\rphpMyAdmin: installation complete"

#printf "\rWP-CLI: installation complete"

else

printf "\rWP-CLI was found, skipping installation"

fi

if [ ! -f /vagrant/public/wp-admin/index.php ];
then

printf "\rWordPress: downloading..."
sudo -u vagrant -i -- wp core download --path=/var/www/public

printf "\rWordPress: configuring..."
sudo -u vagrant -i -- wp core config --dbname=scotchbox --dbuser=root --dbpass=root --path=/var/www/public --extra-php <<PHP
define( 'WP_DEBUG', true );
define( 'WP_DEBUG_LOG', true );
PHP
sudo -u vagrant -i -- wp core install --url="192.168.2.10" --title="Blog" --admin_user="admin" --admin_password="password" --admin_email="change@me.com"  --path=/var/www/public

printf "\rWordPress: installation complete"
else

printf "\rWordPress was found, skipping installation"

fi

#printf "\rNodeJS: installing dependancies..."
#sudo apt-get install python-software-properties > /dev/null 2>&1

#printf "\rNodeJS: getting latest version..."
#sudo add-apt-repository ppa:chris-lea/node.js > /dev/null 2>&1
#sudo apt-get update > /dev/null 2>&1

#printf "\rNodeJS: installing..."
#sudo apt-get install nodejs > /dev/null 2>&1

#printf "\rNodeJS: installation complete"

#read info file
cat /vagrant/info.txt
