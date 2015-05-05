#!/usr/bin/env bash

# set local wordpress database configuration and log locations
echo -e "\n--- Set local wordpress database configuration and log locations ---\n"
APP_CONFIGPATH="/var/www/wp-dev.php"
APP_CONFIGSTRING="php_value auto_prepend_file $APP_CONFIGPATH"
DB_HOST="localhost"
DB_NAME="scotchbox"
DB_USER="root"
DB_PASS="root"
DocumentRoot="/var/www/public"
ErrorLog="/var/www/error.log"
CustomLog="/var/www/access.log"
IPADDRESS="192.168.2.10"

echo -e "\n--- Apply wordpress database variables ---\n"
# apply wordpress database variables
test -e $APP_CONFIGPATH || touch $APP_CONFIGPATH; cat > $APP_CONFIGPATH <<EOF
<?php
define('DB_NAME', '$DB_NAME');
define('DB_USER', '$DB_USER');
define('DB_PASSWORD', '$DB_PASS');
define('DB_HOST', '$DB_HOST');
?>
EOF

echo -e "\n--- Apply local wordpress config configuration and log locations ---\n"
# apply local wordpress config configuration and log locations
cat > /etc/apache2/sites-enabled/000-default.conf <<EOF
<VirtualHost *:80>
    DocumentRoot $DocumentRoot
    ErrorLog $ErrorLog
    CustomLog $CustomLog combined
    php_value include_path "."
    $APP_CONFIGSTRING
</VirtualHost>
EOF

# Ubuntu utilities
. '/var/www/vagrant-shell-scripts/ubuntu.sh'

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
printf "\r\nphp.ini: updating...open base directory"
printf "\n"
php-settings-update 'open_basedir' 'none'

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


printf "\rimporting /db/custom.sql..."

# Import custom SQL
if [ -e /var/www/db/custom.sql ]; then
sudo mysql -u"$DB_USER" -p"$DB_PASS" "$DB_NAME" < /var/www/db/custom.sql
fi

#crontab -u vagrant /var/www/mysqldump.cron
if [ -e /var/www/mysqldump.cron ]; then
crontab -u vagrant /var/www/mysqldump.cron; restart cron;

printf "\rsetting cron job mysqldump.cron..."

fi

if [ ! -f /usr/local/bin/wp ];
then

printf "\n"
printf "\rWP-CLI: not found, installing..."
wget --no-check-certificate https://raw.githubusercontent.com/wp-cli/builds/gh-pages/phar/wp-cli.phar > /dev/null 2>&1
printf "\n"

printf "\rWP-CLI: setting up..."
chmod +x wp-cli.phar > /dev/null 2>&1
printf "\n"

printf "\rWP-CLI: setting permissions..."
sudo mv wp-cli.phar /usr/local/bin/wp > /dev/null 2>&1
printf "\n"

printf "\rWP-CLI: installation complete"

else

printf "\rWP-CLI: found, skipping installation"

fi

if [ ! -f /vagrant/public/wp-admin/index.php ];
then

printf "\rWordPress: downloading..."
sudo -u vagrant -i -- wp core download --path="$DocumentRoot"

printf "\rWordPress: configuring..."
sudo -u vagrant -i -- wp core config --dbname="$DB_NAME" --dbuser="$DB_USER" --dbpass="$DB_PASS" --path="$DocumentRoot" --extra-php <<PHP
define( 'WP_DEBUG', true );
define( 'WP_DEBUG_LOG', true );
PHP
sudo -u vagrant -i -- wp core install --url="$IPADDRESS" --title="Blog" --admin_user="admin" --admin_password="password" --admin_email="change@me.com"  --path="$DocumentRoot"

printf "\rWordPress: installation complete"
else

printf "\rWordPress: found, skipping installation"

fi

# remount mysql sync
#"sudo mount -t vboxsf -o uid=`id -u apache`,gid=`id -g apache` test /test"
#sudo mount -t vboxsf -o uid=`id -u mysql`,gid=`id -g mysql` /var/www/db/ /var/lib/mysql/

#service mysql restart > /dev/null 2>&1
#service apache2 restart > /dev/null 2>&1

#printf "\rNodeJS: installing dependancies..."
#sudo apt-get install python-software-properties > /dev/null 2>&1

#printf "\rNodeJS: getting latest version..."
#sudo add-apt-repository ppa:chris-lea/node.js > /dev/null 2>&1
#sudo apt-get update > /dev/null 2>&1

#printf "\rNodeJS: installing..."
#sudo apt-get install nodejs > /dev/null 2>&1

#printf "\rNodeJS: installation complete"

# copy current mysql db
#/etc/init.d/mysql stop
#cp -R /var/lib/mysql/* /var/www/mysql/
#/etc/init.d/mysql starts

#create or read info file
test -e /var/www/info.txt || touch /var/www/info.txt; cat > /var/www/info.txt <<EOF
Document Root path: $DocumentRoot
Error log path: $ErrorLog

phpMyAdmin URI: http://$IPADDRESS/phpmyadmin
phpMyAdmin User: $DB_USER
phpMyAdmin Password: $DB_PASS

SSH/Virtual Machine Host: $IPADDRESS/
SSH User: vagrant
SSH Password: vagrant

Database Name: $DB_NAME
Database User: $DB_USER
Database Password: $DB_PASS
Database Host: $DB_HOST / 127.0.0.1

WordPress URI: http://$IPADDRESS/

Server Info URI: http://$IPADDRESS/info.txt

Installed Software:
MySQL, phpMyAdmin, Ruby, Composer,
Laravel Installer, Git, cURL,
GD/Imagick, NPM, Grunt, Bower,
Yeoman, Gulp
EOF
cat /var/www/info.txt