#!/bin/bash

source main.sh

if [ $# -ne 2 ]; then
	echo "domains of original and target are required";
	exit;
fi

DB_1=$(db_from_domain $1);
DB_2=$(db_from_domain $2);

DB_1_PATH=$DB_1".sql";
DB_2_PATH=$DB_2".sql";

// copy db1 to db2
cp $DB_1_PAth $DB_2_PATH
sed -i 's/'$1'/ /'$2'/g' $DB_2_PATH;

import_db $DB_2
echo "done importing db, unziping archive"

# untar the zip archive
tar -xzf $1".tar.gz";
cp -rf $1 $2

SITE_2_PATH="/var/www/"$2
mv $2 $SITE_2_PATH 
cd $SITE_2_PATH"/public"

echo "currently in $PWD, configuring wp-config"
DB_USER=$(generate_random_user)
DB_USER_PASS=$(generate_random_pass)

mysql_create_user $DB_USER $DB_USER_PASS
mysql_grant_user $DB_USER $DB_2

cp wp-config-sample.php wp-config.php
sed -i 's/database_name_here/'${DB_2}'/' wp-config.php
sed -i 's/username_here/'$DB_USER'/' wp-config.php
sed -i 's/password_here/'$DB_USER_PASS'/' wp-config.php

chown -R www-data:www-admins ./
chmod -R 775 ./


