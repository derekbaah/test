#!/bin/bash

source main.sh

DOMAIN_NAME=$1

echo "installing themes..." # move to config file
#TODO: for speed and efficiency, use a local copy (specified in themes.list)
add_theme $DOMAIN_NAME "http://justiceo.com/Avada.zip"
add_theme $DOMAIN_NAME "http://justiceo.com/Avada-Child-Theme.zip"	
	
echo "installing plugins..." # move to config file
#TODO: for speed and efficiency, use a local copy (specified in themes.list)
add_essential_plugins $DOMAIN_NAME