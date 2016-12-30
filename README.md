Wordpress Automator Scripts
===========================

These scripts are intended to automate routine operations on a WordPress site


Organization
------------

Data/
	* plugins.list 				/* List of common wp plugins and their urls. Format ID::URL */
	* themes.list 				/* List of supported wp themes and their urls. Format ID::URL */
	* auto_backup_sites.list 	/* Websites in this list will be backed up periodically. Format ID::SITENAME::INTERVAL(in days) */
	* credentials.list 			/* Variables used across the other scripts like SQL user info - scripts that need these vars need to run with sudo */
	
Log/
	* commandType_date.log /* By default all output will be logged */
	
Scripts/
	* configure.sh 		/* Configures an existing wordpress instance Or creates new one with supplied configuration information */
	* install.sh 		/* Installs WordPress with plugins and themes, creates directories, sets permissions and configures mysql user, optionally enables the website in apache */
	* backup.sh			/* Creates a copy of a WordPress instance, themes, uploads, plugins and database dump */
	* batch_backup.sh 	/* Performs backup for all the sites listed in file:auto_backup_sites.list */
	* uninstall.sh		/* Removes a WordPress instance, drops its database, disables it in apache */
	* clone.sh			/* Clones a WordPress instance into another and resets the heart beat */
	

	
	
