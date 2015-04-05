#!/bin/bash
#
# StackScript Bash Library
#
# Copyright (c) 2010 Linode LLC / Christopher S. Aker <caker@linode.com>
# All rights reserved.
#
# Redistribution and use in source and binary forms, with or without modification, 
# are permitted provided that the following conditions are met:
#
# * Redistributions of source code must retain the above copyright notice, this
# list of conditions and the following disclaimer.
#
# * Redistributions in binary form must reproduce the above copyright notice, this
# list of conditions and the following disclaimer in the documentation and/or
# other materials provided with the distribution.
#
# * Neither the name of Linode LLC nor the names of its contributors may be
# used to endorse or promote products derived from this software without specific prior
# written permission.
#
# THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY
# EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES
# OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT
# SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT,
# INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED
# TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR
# BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
# CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN
# ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH
# DAMAGE.


# We'll need these guys to make our work smooth
ROOT_PASS="linux55@"
if [ "$EUID" -ne 0 ]
  then echo "Please run as root"
  exit
fi

###########################################################
# System
###########################################################

function system_update {
    apt-get update
    apt-get -y install aptitude
    aptitude -y full-upgrade
}

function system_primary_ip {
    # returns the primary IP assigned to eth0
    echo $(ifconfig eth0 | awk -F: '/inet addr:/ {print $2}' | awk '{ print $1 }')
}

function get_rdns {
    # calls host on an IP address and returns its reverse dns

    if [ ! -e /usr/bin/host ]; then
        aptitude -y install dnsutils > /dev/null
    fi
    echo $(host $1 | awk '/pointer/ {print $5}' | sed 's/\.$//')
}

function get_rdns_primary_ip {
    # returns the reverse dns of the primary IP assigned to this system
    echo $(get_rdns $(system_primary_ip))
}

function system_set_hostname {
    # $1 - The hostname to define
    HOSTNAME="$1"
        
    if [ ! -n "$HOSTNAME" ]; then
        echo "Hostname undefined"
        exit;
    fi
    
    echo "$HOSTNAME" > /etc/hostname
    hostname -F /etc/hostname
}

function system_add_host_entry {
    # $1 - The IP address to set a hosts entry for
    # $2 - The FQDN to set to the IP
    IPADDR="$1"
    FQDN="$2"

    if [ -z "$IPADDR" -o -z "$FQDN" ]; then
        echo "IP address and/or FQDN Undefined"
        exit;
    fi
    
    echo $IPADDR $FQDN  >> /etc/hosts
}

function add_domain {

	if [ $# -ne 1 ]; then
		echo "domain name required"
		exit
	fi

	echo -e "\n==== ADDING DOMAIN $1 ===="
	DOMAIN_PATH="/var/www/$1"

	mkdir -p $DOMAIN_PATH/{log,public,backup}
	touch $DOMAIN_PATH/log/{access.log,error.log}
	touch $DOMAIN_PATH/public/index.html

	EXAMPLE="example.com"
	CONF_PATH="/etc/apache2/sites-available/"
	cp $CONF_PATH$EXAMPLE\.conf $CONF_PATH$1\.conf
	sed -i "s/example.com/$1/g" $CONF_PATH$1\.conf
	a2ensite $1
	service apache2 reload


	ln -s /usr/share/phpmyadmin $DOMAIN_PATH"/public/"

	chown www-data:www-data -R $DOMAIN_PATH

}


###########################################################
# Users and Authentication
###########################################################

function user_add_sudo {
    # Installs sudo if needed and creates a user in the sudo group.
    #
    # $1 - Required - username
    # $2 - Required - password
    USERNAME="$1"
    USERPASS="$2"

    if [ ! -n "$USERNAME" ] || [ ! -n "$USERPASS" ]; then
        echo "No new username and/or password entered"
        exit;
    fi
    
    aptitude -y install sudo
    adduser $USERNAME --disabled-password --gecos ""
    echo "$USERNAME:$USERPASS" | chpasswd
    usermod -aG sudo $USERNAME
}

function user_add_pubkey {
    # Adds the users public key to authorized_keys for the specified user. Make sure you wrap your input variables in double quotes, or the key may not load properly.
    #
    #
    # $1 - Required - username
    # $2 - Required - public key
    USERNAME="$1"
    USERPUBKEY="$2"
    
    if [ ! -n "$USERNAME" ] || [ ! -n "$USERPUBKEY" ]; then
        echo "Must provide a username and the location of a pubkey"
        exit;
    fi
    
    if [ "$USERNAME" == "root" ]; then
        mkdir /root/.ssh
        echo "$USERPUBKEY" >> /root/.ssh/authorized_keys
        exit;
    fi
    
    mkdir -p /home/$USERNAME/.ssh
    echo "$USERPUBKEY" >> /home/$USERNAME/.ssh/authorized_keys
    chown -R "$USERNAME":"$USERNAME" /home/$USERNAME/.ssh
}

function ssh_disable_root {
    # Disables root SSH access.
    sed -i 's/PermitRootLogin yes/PermitRootLogin no/' /etc/ssh/sshd_config
    touch /tmp/restart-ssh
    
}

###########################################################
# Postfix
###########################################################

function postfix_install_loopback_only {
    # Installs postfix and configure to listen only on the local interface. Also
    # allows for local mail delivery

    echo "postfix postfix/main_mailer_type select Internet Site" | debconf-set-selections
    echo "postfix postfix/mailname string localhost" | debconf-set-selections
    echo "postfix postfix/destinations string localhost.localdomain, localhost" | debconf-set-selections
    aptitude -y install postfix
    /usr/sbin/postconf -e "inet_interfaces = loopback-only"
    #/usr/sbin/postconf -e "local_transport = error:local delivery is disabled"

    touch /tmp/restart-postfix
}


###########################################################
# Apache
###########################################################

function apache_install {
    # installs the system default apache2 MPM
    aptitude -y install apache2

    a2dissite default # disable the interfering default virtualhost

    # clean up, or add the NameVirtualHost line to ports.conf
    sed -i -e 's/^NameVirtualHost \*$/NameVirtualHost *:80/' /etc/apache2/ports.conf
    if ! grep -q NameVirtualHost /etc/apache2/ports.conf; then
        echo 'NameVirtualHost *:80' > /etc/apache2/ports.conf.tmp
        cat /etc/apache2/ports.conf >> /etc/apache2/ports.conf.tmp
        mv -f /etc/apache2/ports.conf.tmp /etc/apache2/ports.conf
    fi
}

function apache_tune {
    # Tunes Apache's memory to use the percentage of RAM you specify, defaulting to 40%

    # $1 - the percent of system memory to allocate towards Apache

    if [ ! -n "$1" ];
        then PERCENT=40
        else PERCENT="$1"
    fi

    aptitude -y install apache2-mpm-prefork
    PERPROCMEM=10 # the amount of memory in MB each apache process is likely to utilize
    MEM=$(grep MemTotal /proc/meminfo | awk '{ print int($2/1024) }') # how much memory in MB this system has
    MAXCLIENTS=$((MEM*PERCENT/100/PERPROCMEM)) # calculate MaxClients
    MAXCLIENTS=${MAXCLIENTS/.*} # cast to an integer
    sed -i -e "s/\(^[ \t]*MaxClients[ \t]*\)[0-9]*/\1$MAXCLIENTS/" /etc/apache2/apache2.conf

    touch /tmp/restart-apache2
}

function apache_virtualhost {
    # Configures a VirtualHost

    # $1 - required - the hostname of the virtualhost to create 

    if [ ! -n "$1" ]; then
        echo "apache_virtualhost() requires the hostname as the first argument"
        exit;
    fi

    if [ -e "/etc/apache2/sites-available/$1" ]; then
        echo /etc/apache2/sites-available/$1 already exists
        return;
    fi

    mkdir -p /srv/www/$1/public_html /srv/www/$1/logs

    echo "<VirtualHost *:80>" > /etc/apache2/sites-available/$1
    echo "    ServerName $1" >> /etc/apache2/sites-available/$1
    echo "    DocumentRoot /srv/www/$1/public_html/" >> /etc/apache2/sites-available/$1
    echo "    ErrorLog /srv/www/$1/logs/error.log" >> /etc/apache2/sites-available/$1
    echo "    CustomLog /srv/www/$1/logs/access.log combined" >> /etc/apache2/sites-available/$1
    echo "</VirtualHost>" >> /etc/apache2/sites-available/$1

    a2ensite $1

    touch /tmp/restart-apache2
}

function apache_virtualhost_from_rdns {
    # Configures a VirtualHost using the rdns of the first IP as the ServerName

    apache_virtualhost $(get_rdns_primary_ip)
}


function apache_virtualhost_get_docroot {
    if [ ! -n "$1" ]; then
        echo "apache_virtualhost_get_docroot() requires the hostname as the first argument"
        exit;
    fi

    if [ -e /etc/apache2/sites-available/$1".conf" ];
        then echo $(awk '/DocumentRoot/ {print $2}' /etc/apache2/sites-available/$1".conf" )
    fi
}

function apache_virtualhost_get_siteroot {
    if [ ! -n "$1" ]; then
        echo "apache_virtualhost_get_siteroot() requires the hostname as the first argument"
        exit;
    fi

    if [ -e /etc/apache2/sites-available/$1".conf" ];
        then echo $(awk '/public:/ {print $3}' /etc/apache2/sites-available/$1".conf" )
    fi
}

# By default this should:
#	uninstall wordpress 
#	drop wordpress database
#	remove wordpress database user
# 	remove domain from apache hostname entry
function remove_site {

	if [ $# -ne 1 ]; then
		echo "domain name required"
		exit
	fi



	# disable site
	a2dissite $1
	service apache2 reload

	# drop database 
	# only execute if drop-db flag is set
	drop_db $1

	# drop db user
	# implement later

	DOMAIN_PATH="/var/www/$1"

	# trash contents
	trash $DOMAIN_PATH /var/trash/
}

###########################################################
# mysql-server
###########################################################

function mysql_install {
    # $1 - the mysql root password

    if [ ! -n "$1" ]; then
        echo "mysql_install() requires the root pass as its first argument"
        exit;
    fi

    echo "mysql-server mysql-server/root_password password $1" | debconf-set-selections
    echo "mysql-server mysql-server/root_password_again password $1" | debconf-set-selections
    apt-get -y install mysql-server mysql-client

    echo "Sleeping while MySQL starts up for the first time..."
    sleep 5
}

function mysql_tune {
    # Tunes MySQL's memory usage to utilize the percentage of memory you specify, defaulting to 40%

    # $1 - the percent of system memory to allocate towards MySQL

    if [ ! -n "$1" ];
        then PERCENT=40
        else PERCENT="$1"
    fi

    sed -i -e 's/^#skip-innodb/skip-innodb/' /etc/mysql/my.cnf # disable innodb - saves about 100M

    MEM=$(awk '/MemTotal/ {print int($2/1024)}' /proc/meminfo) # how much memory in MB this system has
    MYMEM=$((MEM*PERCENT/100)) # how much memory we'd like to tune mysql with
    MYMEMCHUNKS=$((MYMEM/4)) # how many 4MB chunks we have to play with

    # mysql config options we want to set to the percentages in the second list, respectively
    OPTLIST=(key_buffer sort_buffer_size read_buffer_size read_rnd_buffer_size myisam_sort_buffer_size query_cache_size)
    DISTLIST=(75 1 1 1 5 15)

    for opt in ${OPTLIST[@]}; do
        sed -i -e "/\[mysqld\]/,/\[.*\]/s/^$opt/#$opt/" /etc/mysql/my.cnf
    done

    for i in ${!OPTLIST[*]}; do
        val=$(echo | awk "{print int((${DISTLIST[$i]} * $MYMEMCHUNKS/100))*4}")
        if [ $val -lt 4 ]
            then val=4
        fi
        config="${config}\n${OPTLIST[$i]} = ${val}M"
    done

    sed -i -e "s/\(\[mysqld\]\)/\1\n$config\n/" /etc/mysql/my.cnf

    touch /tmp/restart-mysql
}

function mysql_create_database {
    # $1 - the mysql root password
    # $2 - the db name to create

    if [ ! -n "$1" ]; then
        echo "mysql_create_database() requires the root pass as its first argument"
        exit;
    fi
    if [ ! -n "$2" ]; then
        echo "mysql_create_database() requires the name of the database as the second argument"
        exit;
    fi

	DB_NAME=$2
	# replace . in domain name with _
	DB_NAME="${DB_NAME//./_}"

    echo "CREATE DATABASE $DB_NAME;" | mysql -u root -p$1
}

function mysql_create_user {
    # $1 - the user to create
    # $2 - their password

   
    if [ ! -n "$1" ]; then
        echo "mysql_create_user() requires username as the 1st argument"
        exit
    fi
    if [ ! -n "$2" ]; then
        echo "mysql_create_user() requires a password as the 2nd argument"
        exit
    fi

	echo -e "\ncreating new sql user $1 identified by $2"
    	echo "CREATE USER '$1'@'localhost' IDENTIFIED BY '$2';" | mysql -u root -p$ROOT_PASS
}

function mysql_grant_user {
    
    # $1 - the user to bestow privileges 
    # $2 - the database

    if [ ! -n "$1" ]; then
        echo "mysql_create_user() requires the username as its first argument"
        exit
    fi
    if [ ! -n "$2" ]; then
        echo "mysql_create_user() requires database as the second argument"
        exit
    fi
    

    echo "GRANT ALL PRIVILEGES ON $2.* TO '$1'@'localhost';" | mysql -u root -p$ROOT_PASS
    echo "FLUSH PRIVILEGES;" | mysql -u root -p$ROOT_PASS

}

function generate_random_user {

    LENGTH="8"
    MATRIX="ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz"

    while [ "${n:=1}" -le "$LENGTH" ]; do
    	USER="$USER${MATRIX:$(($RANDOM%${#MATRIX})):1}"
    	let n+=1
    done
    
    echo $USER
	
} # End function generate_random_pass

function generate_random_pass {

    LENGTH="15"
    MATRIX="0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz"

    while [ "${n:=1}" -le "$LENGTH" ]; do
    	PASS="$PASS${MATRIX:$(($RANDOM%${#MATRIX})):1}"
    	let n+=1
    done

    DB_USER_PASS=$PASS
    echo $PASS
	
} # End function generate_random_pass

function does_db_exist {

	if [ ! -n "$1" ]; then
        	echo "does_db_exist requires a database name"
        	exit;
    	fi
	
	echo "SELECT SCHEMA_NAME FROM INFORMATION_SCHEMA.SCHEMATA WHERE SCHEMA_NAME = '$1'" | mysql -u root -p$ROOT_PASS    	

}

function drop_db {

	if [ $# -ne 1 ]; then
        	echo "drop_db requires a database name"
        	exit;
    	fi

    	
	DB=$(db_from_domain $1)

	# check if database exist
	if [[ ! -n $(does_db_exist $DB) ]]; then		
		echo "***Database $1 was not found"
		return
	fi

	echo "==== DROPPING DATABASE $DB ===="

    	echo "DROP DATABASE $DB;" | mysql -u root -p$ROOT_PASS  
	echo "==== DROPPED DATABASE $DB ===="
	
}

function drop_db_user {

	if [ ! -n "$1" ]; then
        	echo "drop_db_user requires a database name"
        	exit;
    	fi

    	
	#task for tomorrow

}

function database_clone {

	if [ ! -n "$2" ]; then
        	echo "Source and Desination Database required"
        	exit;
    	fi

	
	SITE_1_DB=$1
	SITE_2_DB=$2

	echo -e "\n==== ATTEMPTING TO CLONE DATABASE $1 TO $2 ===="

	# check that site 1 db exists and site 2 db does not exists
	if [ ! -n "$(does_db_exist $SITE_1_DB)" ]; then
		echo "Database does not exist for $SITE_1"
		exit
	fi
	if [ -n "$(does_db_exist $SITE_2_DB)" ]; then
		echo "A database with $SITE_2_DB already exists"
		exit
	fi
	
	# clone database
	mysqldump $SITE_1_DB -uroot -p$ROOT_PASS > $SITE_1_DB".sql";
	mysql -uroot -p$ROOT_PASS -e "CREATE DATABASE $SITE_2_DB";
	sed -i 's/'$SITE_1'/'$SITE_2'/g' $SITE_1_DB".sql"
	mysql $SITE_2_DB -uroot -p$ROOT_PASS < $SITE_1_DB".sql";

	echo -e "==== DATABASE CLONE WAS SUCCESSFUL! ====\n"

}

function db_from_domain {

	if [ ! -n "$1" ]; then
        	echo "Domain is requird"
        	exit
    	fi
	SITE_NAME=$1
	SITE_NAME=${SITE_NAME//-/_}
	echo ${SITE_NAME//./_}"DB"
}

###########################################################
# PHP functions
###########################################################

function php_install_with_apache {
    aptitude -y install php5 php5-mysql libapache2-mod-php5
    touch /tmp/restart-apache2
}

function php_tune {
    # Tunes PHP to utilize up to 32M per process

    sed -i'-orig' 's/memory_limit = [0-9]\+M/memory_limit = 32M/' /etc/php5/apache2/php.ini
    touch /tmp/restart-apache2
}

###########################################################
# Wordpress functions
###########################################################

function wordpress_install {
    # installs the latest wordpress tarball from wordpress.org

    # $1 - required - The existing virtualhost to install into

    if [ ! -n "$4" ]; then
        echo "wordpress_install() requires domain name, db name, db user n db pass"
        exit
    fi

    if [ ! -e /usr/bin/wget ]; then
        aptitude -y install wget
    fi
	
    VPATH=$(apache_virtualhost_get_docroot $1)
	DB_NAME=$2
	DB_USER=$3
	DB_USER_PASS=$4


    if [ ! -d "$VPATH" ]; then
        echo "Could not determine DocumentRoot for $1"
        exit;
    fi

    # download, extract, chown, and get our config file started
    cd $VPATH
	echo "==== DOWNLOADING WORDPRESS ===="
	sleep 1
    wget http://wordpress.org/latest.tar.gz
    tar xfz latest.tar.gz 
    mv wordpress/* ./
    chown -R www-data: ./
    cp wp-config-sample.php wp-config.php
    chown www-data wp-config.php
    chmod 640 wp-config.php
    

    # configuration file updates    
    sed -i 's/database_name_here/'${DB_NAME}'/' wp-config.php
    sed -i 's/username_here/'$DB_USER'/' wp-config.php
    sed -i 's/password_here/'$DB_USER_PASS'/' wp-config.php

    
}

function add_essential_plugins {

 	if [ ! -n "$1" ]; then
        	echo "Domain name is required to install plugins"
        	exit;
    	fi

	VPATH=$(apache_virtualhost_get_docroot $1)

	if [ ! -d "$VPATH" ]; then
		echo "Could not determine DocumentRoot for $1"
		exit;
	fi

	cd $VPATH"/wp-content/plugins/"
	echo "==== DOWNLOADING PLUGINS ===="
	sleep 1
	wget http://downloads.wordpress.org/plugin/wp-super-cache.0.9.8.zip
	wget https://downloads.wordpress.org/plugin/contact-form-7.4.1.1.zip
	wget https://downloads.wordpress.org/plugin/anti-spam.3.5.zip
	wget https://downloads.wordpress.org/plugin/google-sitemap-generator.4.0.8.zip
	wget https://downloads.wordpress.org/plugin/better-wp-security.4.6.10.zip
	wget https://downloads.wordpress.org/plugin/woocommerce.2.3.6.zip
	wget https://downloads.wordpress.org/plugin/wordpress-seo.1.7.4.zip
	wget https://downloads.wordpress.org/plugin/wp-statistics.9.0.zip
	wget https://downloads.wordpress.org/plugin/wp-example-content.1.3.zip

	echo "==== INSTALLING PLUGINS ===="
	sleep 1
	for zip_file in *zip; do 
		unzip $zip_file;
		rm $zip_file; 
	done

	chown -R www-data $VPATH

}

function add_plugin {

 	if [ ! -n "$2" ]; then
        	echo "Domain name and plugin url is required to install plugins"
        	exit;
    	fi

	VPATH=$(apache_virtualhost_get_docroot $1)

	if [ ! -d "$VPATH" ]; then
		echo "Could not determine DocumentRoot for $1"
		exit;
	fi

	cd $VPATH"/wp-content/plugins/"
	echo "==== DOWNLOADING PLUGIN ===="
	sleep 1
	wget $2
	
	echo "==== INSTALLING PLUGINS ===="
	sleep 1
	for zip_file in *zip; do 
		unzip $zip_file; 
		rm $zip_file;
	done

	chown -R www-data $VPATH

}


function add_theme {

	if [ ! -n "$2" ]; then
        	echo "Domain name and theme download url is required to install plugins"
        	exit;
    	fi

	VPATH=$(apache_virtualhost_get_docroot $1)

	if [ ! -d "$VPATH" ]; then
		echo "Could not determine DocumentRoot for $1"
		exit;
	fi

	cd $VPATH"/wp-content/themes/"
	echo "==== DOWNLOADING THEME ===="
	sleep 1
	wget $2
	
	echo "==== INSTALLING THEME ===="
	sleep 1
	for zip_file in *zip; do 
		unzip $zip_file; 
		rm $zip_file;
	done

	chown -R www-data $VPATH
}



function wordpress_clone {

	if [ ! -n "$2" ]; then
        	echo "Source and Desination Domains required"
        	exit;
    	fi

	SITE_1=$1
	SITE_2=$2
	SITE_1_PATH=$(apache_virtualhost_get_siteroot $SITE_1)
	SITE_2_PATH=$(apache_virtualhost_get_siteroot $SITE_2)

	# check that site 1 exists and site 2 does not exist

	if [ ! -d "$SITE_1_PATH" ]; then
		echo "Could not determine DocumentRoot for $SITE_1_PATH"
		exit;
	fi

	if [ -d "$SITE_2_PATH" ]; then
		echo "Cannot overrite $SITE_2_PATH"
		exit;
	fi
	
	echo -e "\n==== CLONING $SITE_1 TO $SITE_2 ===="
	sleep 2

	#assumes a domain does not exist
	add_domain $SITE_2
	SITE_2_PATH=$(apache_virtualhost_get_siteroot $SITE_2)

	#for existing domain, wipe content and re-add

	# clone database if option supplied
	database_clone $(db_from_domain $SITE_1) $(db_from_domain $SITE_2)

	echo -e "copying $SITE_1_PATH to $SITE_2_PATH"
	cp -rf "$SITE_1_PATH"* $SITE_2_PATH 
	cd $SITE_2_PATH"/public"
	echo -e "current working directory: $PWD"
	chown www-data -R ./
	sleep 3

	# configuration file updates
	DB_NAME=$(db_from_domain $SITE_2)    
	DB_USER=$(generate_random_user)
	DB_USER_PASS=$(generate_random_pass)

	mysql_create_user $DB_USER $DB_USER_PASS
	mysql_grant_user $DB_USER $DB_NAME 

	cp wp-config-sample.php wp-config.php
    	chown www-data wp-config.php
    	chmod 640 wp-config.php
	
	echo -e "configuring wp-config files"
    	sed -i 's/database_name_here/'${DB_NAME}'/' wp-config.php
    	sed -i 's/username_here/'$DB_USER'/' wp-config.php
    	sed -i 's/password_here/'$DB_USER_PASS'/' wp-config.php

	#modify live site

}



###########################################################
# Other niceties!
###########################################################

function goodstuff {
    # Installs the REAL vim, wget, less, and enables color root prompt and the "ll" list long alias

    aptitude -y install wget vim less
    sed -i -e 's/^#PS1=/PS1=/' /root/.bashrc # enable the colorful root bash prompt
    sed -i -e "s/^#alias ll='ls -l'/alias ll='ls -al'/" /root/.bashrc # enable ll list long alias <3
}


###########################################################
# utility functions
###########################################################

function restartServices {
    # restarts services that have a file in /tmp/needs-restart/

    for service in $(ls /tmp/restart-* | cut -d- -f2-10); do
        /etc/init.d/$service restart
        rm -f /tmp/restart-$service
    done
}

function randomString {
    if [ ! -n "$1" ];
        then LEN=20
        else LEN="$1"
    fi

    echo $(</dev/urandom tr -dc A-Za-z0-9 | head -c $LEN) # generate a random string
}
