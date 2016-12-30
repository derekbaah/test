#!/bin/bash

source main.sh

if [ $# -ne 1 ]; then
	echo "domain required";
	exit;
fi
export_db $(db_from_domain $1)
export_files $1

		


