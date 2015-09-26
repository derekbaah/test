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
if [ $2 = false ]; then
	ADD_IF_NOT_EXISTS=false;
	exit;
fi

DOMAIN_NAME=$1;
echo -e "Installing WordPress for $DOMAIN_NAME...";


### Create Directories
echo "creating directories..."
INSTALL_PATH=$DEFAULT_WORDPRESS_INSTALL_PATH".$DOMAIN_NAME"
mkdir -p $INSTALL_PATH/{log,public,backup}
touch $INSTALL_PATH/log/{access.log,error.log}
touch $INSTALL_PATH/public/index.html


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
#TODO: expects that domain is already existing, attempts to fetch from apache2. Dependency should be removed
wordpress_install $DOMAIN_NAME $DB_NAME $SQL_USER $SQL_USER_PASS

### Configure Wordpress Options
echo "configuring wordpress..."
configure.sh $DOMAIN_NAME

echo "adding phpmyadmin shortcut..."
ln -s /usr/share/phpmyadmin $INSTALL_PATH"/public/"

echo "setting file permissions..."
chown www-data:www-data -R $INSTALL_PATH

### Configuring Apache
#TODO: ADD_IF_NOT_EXISTS
echo "configuring apache..."
APACHE_SAMPLE_CONF=$(apache_virtualhost_get_conf example.com)
DOMAIN_CONF=$(apache_virtualhost_get_conf $DOMAIN_NAME)
if [ -f $DOMAIN_CONF  || ADD_IF_NOT_EXISTS ]; then
	cp APACHE_SAMPLE_CONF DOMAIN_CONF
	sed -i "s/example.com/$DOMAIN_NAME/g" DOMAIN_CONF

	echo "enabling website..."
	a2ensite $DOMAIN_NAME
	service apache2 reload
fi

echo -e "\nTesting Settings"

echo "Testing MySQL database connection"
echo "Pinging WordPress instance"
echo "Pinging PHPmyAdmin"

echo "Success!!!"

echo -e "\nEnd WordPress Install"
echo -e "=====================\n"







