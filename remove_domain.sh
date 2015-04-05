#!/bin/bash

source main.sh

if [ $# -ne 1 ]; then
	echo "domain name required"
	exit
fi

# disable site
a2dissite $1
service apache2 reload

# drop database 
drop_db $1

# drop db user
# implement later

DOMAIN_PATH="/var/www/$1"

# trash contents
trash $DOMAIN_PATH /var/trash/






