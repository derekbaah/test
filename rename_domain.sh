#!/bin/bash

if [ $# -ne 2 ]; then
	echo "enter original and new domain name"
	exit
fi

ORIGINAL=$1
NEW=$2
FILE_PATH="/var/www/"
mv  $FILE_PATH{$ORIGINAL,$NEW} 

CONF_PATH="/etc/apache2/sites-available/"
mv $CONF_PATH{$ORIGINAL\.conf,$CONF_PATH$NEW\.conf}
sed -i "s/$ORIGINAL/$NEW/g" $CONF_PATH$NEW\.conf
a2ensite $NEW
a2dissite $ORIGINAL
service apache2 reload


