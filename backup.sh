#!/bin/bash

source main.sh

backup_list="backup_sites"
if [ ! -f $backup_list ]; then
	echo "cannot find list of sites to backup"
	exit
fi

while read line
do
	site=$line
	wordpress_backup $site
done < $backup_list
 
