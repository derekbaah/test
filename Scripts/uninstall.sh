#!/bin/bash

source main.sh

if [ $# -ne 1 ]; then
	echo "domain name required"
	exit
fi

# disable site
a2dissite $1
service apache2 reload

#export database first

# drop database 
drop_db_for_site $1

# drop db user
# implement later

DOMAIN_PATH="/var/www/$1"

# trash contents
if [ ! -d $DOMAIN_PATH ]; then
	echo "Directory $DOMAIN_PATH does not exist"
	exit
fi

echo "== Removing contents =="
rm -r $DOMAIN_PATH 

echo -e "\n== Done =="





