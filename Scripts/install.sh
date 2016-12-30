#!/bin/bash
#
# Install.sh
#	- Creates the directories for a WordPress instance including Logs and Backups
#	- Installs a WordPress Instance
#	- Sets Directory Permissions
#	- Enables it in Apache
#	- Creates MySQL DB and associates a MySQL user with the WordPress instance
#
# Arguments
#	1) DOMAIN_NAME (e.g justiceo.com)
#	2) ADD_IF_NOT_EXISTS (default: true. Adds a new domain to apache)
#

echo -e "\nBegin WordPress Install"
echo -e "=======================\n"

source ../Data/credentials.list
source main.sh

if [ ! -n "$1" ]; then
	echo "Please enter a domain name (e.g. justiceo.com)";
	exit;
fi

ADD_IF_NOT_EXISTS=true;
if [ "$2" -eq "false" ]; then
	ADD_IF_NOT_EXISTS=false;
	exit;
fi

DOMAIN_NAME=$1;
echo -e "Installing WordPress for $DOMAIN_NAME...";


### Create Directories
echo "creating directories..."
DOMAIN_PATH="/var/www/$DOMAIN_NAME"
mkdir -p $DOMAIN_PATH/{log,public,backup}
touch $DOMAIN_PATH/log/{access.log,error.log}
touch $DOMAIN_PATH/public/index.html


### Configuring MySQL
SQL_USER=$(generate_random_user)
SQL_USER_PASS=$(generate_random_pass)
DB_NAME=${DOMAIN_NAME//./_}"DB"

echo "creating the database..."
#TODO: check if DB exists (dump it for restore sake, then drop it)
mysql_create_database $SQL_ROOT_PASS $DB_NAME

echo "creating mysql user..."
mysql_create_user $SQL_USER $SQL_USER_PASS
mysql_grant_user $SQL_USER $DB_NAME

### Installing Wordpress
echo "installing wordpress..."
#TODO: check if directory already exists (dump it for restore sake, then rm it)
wordpress_install $DOMAIN_NAME $DB_NAME $SQL_USER $SQL_USER_PASS

echo "installing themes..."
#TODO: for speed and efficiency, use a local copy (specified in themes.list)
while read theme_path; do
add_theme $DOMAIN_NAME $theme_path
done < $themesFile
	
echo "installing plugins..."
#TODO: for speed and efficiency, use a local copy (specified in themes.list)
#add_essential_plugins $DOMAIN_NAME
while read plugin_url; do
add_plugin $DOMAIN_NAME $plugin_url
done < $pluginsFile

echo "adding phpmyadmin shortcut..."
ln -s /usr/share/phpmyadmin $DOMAIN_PATH"/public/"

echo "setting file permissions..."
chown www-data:www-data -R $DOMAIN_PATH

### Configuring Apache
#TODO: ADD_IF_NOT_EXISTS
echo "configuring apache..."
APACHE_SAMPLE_CONF="/etc/apache2/sites-available/example.com.conf"
DOMAIN_CONF="/etc/apache2/sites-available/$DOMAIN_NAME\.conf"
cp APACHE_SAMPLE_CONF DOMAIN_CONF
sed -i "s/example.com/$DOMAIN_NAME/g" DOMAIN_CONF

echo "enabling website..."
a2ensite $DOMAIN_NAME
service apache2 reload

echo -e "\nTesting Settings"

echo "Testing MySQL database connection"
echo "Pinging WordPress instance"
echo "Pinging PHPmyAdmin"

echo "Success!!!"

echo -e "\nEnd WordPress Install"
echo -e "=====================\n"







