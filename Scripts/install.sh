#!/bin/bash

source ../Data/credentials.list
source main.sh

if [ $# -ne 1 ]; then
	echo "domain name required"
	exit
fi

# Adding Domain Name
DOMAIN_PATH="/var/www/$1"

mkdir -p $DOMAIN_PATH/{log,public,backup}
touch $DOMAIN_PATH/log/{access.log,error.log}
touch $DOMAIN_PATH/public/index.html

EXAMPLE="example.com"
CONF_PATH="/etc/apache2/sites-available/"
cp $CONF_PATH$EXAMPLE\.conf $CONF_PATH$1\.conf
sed -i "s/example.com/$1/g" $CONF_PATH$1\.conf
a2ensite $1
service apache2 reload


ln -s /usr/share/phpmyadmin $DOMAIN_PATH"/public/"


chown www-data:www-data -R $DOMAIN_PATH

# Addign MySQL user

SQL_ROOT_PASS=$ROOT_PASS
SQL_USER=$(generate_random_user)
SQL_USER_PASS=$(generate_random_pass)
SITE_NAME=$1
DB_NAME=${SITE_NAME//./_}"DB"


mysql_create_database $SQL_ROOT_PASS $DB_NAME

mysql_create_user $SQL_USER $SQL_USER_PASS

mysql_grant_user $SQL_USER $DB_NAME

wordpress_install $SITE_NAME $DB_NAME $SQL_USER $SQL_USER_PASS
	
add_essential_plugins $SITE_NAME


add_theme $SITE_NAME "http://justiceo.com/Avada.zip"
add_theme $SITE_NAME "http://justiceo.com/Avada-Child-Theme.zip"



