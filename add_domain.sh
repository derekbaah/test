#!/bin/bash

if [ $# -ne 1 ]; then
	echo "domain name required"
	exit
fi

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

