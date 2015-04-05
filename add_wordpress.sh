#!/bin/bash

source main.sh


ROOT_PASS="linux55@"
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

add_theme $SITE_NAME "http://justiceo.com/flatsome2.2.3-main.zip"

add_theme $SITE_NAME "http://justiceo.com/flatsome-child.zip"


