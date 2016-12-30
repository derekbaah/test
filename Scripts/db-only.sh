#!/bin/bash

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
echo -e "Installing mysql for $DOMAIN_NAME...";

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

echo "user name $SQL_USER and password $SQL_USER_PASS"
