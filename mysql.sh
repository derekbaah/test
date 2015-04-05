#!/bin/bash
# <UDF name="db_password" Label="MySQL root Password" />
# <UDF name="db_name" Label="Database Name" default="" example="Create this database" />
# <UDF name="db_user" Label="MySQL Username" default="" example="Create this user" />
# <UDF name="db_user_password" Label="MySQL Username Password" default="" example="User's password" />

source main.sh

DB_PASSWORD="shellshock"

system_update
postfix_install_loopback_only
mysql_install "$DB_PASSWORD" && mysql_tune 90
mysql_create_database "$DB_PASSWORD" "$DB_NAME"
mysql_create_user "$DB_PASSWORD" "$DB_USER" "$DB_USER_PASSWORD"
mysql_grant_user "$DB_PASSWORD" "$DB_USER" "$DB_NAME"
goodstuff
restartServices
