#!/bin/bash

########################################

# Checking for WordPress, Joomla, Drupal, and phpBB installs and versions on a Media Temple Grid,
# DV's with Plesk or cPanel/WHM, and "DV Developers"

########################################

# Exit the script if not run using sudo/root on a VPS
function bye ()
{
return 0
}

# Doing the work
function search ()
{
# To handle directories with spaces in the name
SAVEIFS=$IFS
IFS=$(echo -en "\n\b")

# If WordPress installs are found
if [ -s ./wplist ]; then
	# Get the latest version of WordPress and define it
	new_wp_ver=$(curl -s http://api.wordpress.org/core/version-check/1.5/ | head -n 4 | tail -n 1)
		
	# Let the user know what the latest version is
	echo " "
	echo "WordPress - Latest version is $new_wp_ver"

	# For each WordPress in the temp file
	for f in $(cat ./wplist); do
	# Define the WordPress's version as a temporary variable
		wp_version=($(grep "wp_version =" $f | cut -d\' -f2));
	# Check the installed WordPress version against the latest version.
	# If the version is old send it to the file oldwp.txt 
		if [[ ${wp_version//./} -ne ${new_wp_ver//./} ]]; then
			echo -en "$f = $wp_version\n" >> ./oldwp.txt
	   	fi
    done
	# If only new WP installs exist then say so
    if [[ ! -s ./oldwp.txt ]]; then
    	echo "**WordPress installs found but are all up to date**"
	# If old WP installs exist, display the list but first remove the
	# file and its parent directory being checked and provide a better path 
    elif [[ -s ./oldwp.txt ]]; then
    	cat ./oldwp.txt | sed 's/wp-includes\/version.php//g' | sed 's/users\/\.home\///g'; rm ./oldwp.txt
	fi
else
	echo " "
	echo 'No WordPress installs found!'
fi

# On servers with a lot of CMS, the script will start outputting the next CMS check 
# before the previous one is done with its output. This makes each section wait a 
# second before continuing
sleep 1

# If Joomla installs are found
if [ -s ./joomlalist ]; then
	# Get the latest version of Joomla and define it
	new_joomla_ver=$( curl -s https://api.github.com/repos/joomla/joomla-cms/releases/latest | awk -F\" '/tag_name/ { print $4 }' )
		
	# Let the user know what the latest version is
	echo " "
	echo "Joomla - Latest version is $new_joomla_ver"

	# For each Joomla in the temp file
	for f in $(cat ./joomlalist); do
		# Define the Joomla's version as a temporary variable
		version=($(grep -E "var|const|public" $f | awk -F\' '/RELEASE/{print$2}').$(grep -E "var|const|public" $f | awk -F\' '/DEV_LEVEL/{print$2}'));
		# Check the installed Joomla version against the latest version.
		# If the version is old send it to the file oldjoomla.txt 
		if [[ ${version//./} -ne ${new_joomla_ver//./} ]]; then
			echo -en "$f = $version\n" >> ./oldjoomla.txt
    	fi
	done
	# If only new Joomla installs exist then say so
    if [[ ! -s ./oldjoomla.txt ]]; then
    	echo "**Joomla installs found but are all up to date**" & ./oldjoomla.txt 2> /dev/null
	# If old Joomla installs exist, display the list but first remove the 
	# file being checked and provide a better path
	elif [[ -s ./oldjoomla.txt ]]; then
    	cat ./oldjoomla.txt | sed 's/libraries\/.*.php//g' | sed 's/users\/\.home\///g' & rm ./oldjoomla.txt 2> /dev/null
	fi
else
	echo " "
	echo 'No Joomla installs found!'
fi

sleep 1

# If Drupal installs are found
if [ -s ./drupallist ]; then
	# Get the latest versions of Drupal and define it:
	# This first one is considered the latest but ready for production
	new_drupal_ver1=$( curl -s https://www.drupal.org/project/drupal | grep '<h4>Drupal core' | grep -v dev | head -n 1 | awk -F' ' '{print $3}' | awk -F'<' '{print $1}' )
	# This second one is considered older but still up to date
	new_drupal_ver2=$( curl -s https://www.drupal.org/project/drupal | grep '<h4>Drupal core' | grep -v dev | head -n 2 | tail -n 1 | awk -F' ' '{print $3}' | awk -F'<' '{print $1}' )
 
	# Let the user know what the latest version is
	echo " "
	echo "Drupal - Latest version is $new_drupal_ver1, stable version is $new_drupal_ver2"

	# For each Drupal in the temp file
	for f in $(cat ./drupallist); do
		# Define the Drupal version as a temporary variable
		version=$(grep "version = \"" $f | cut -d '"' -f2);
		# Check the installed Drupal version against the latest versions.
		# If the version is considered old, send it to the file olddrupal.txt
		if [[ ${version//./} -ne ${new_drupal_ver1//./} ]] && [[ ${version//./} -ne ${new_drupal_ver2//./} ]]; then
			echo -en "$f = $version\n" >> ./olddrupal.txt
		fi
	done
	# If only new Drupal installs exist then say so
    if [[ ! -s ./olddrupal.txt ]]; then
    		echo "**Drupal installs found but are all up to date**" & ./olddrupal.txt 2> /dev/null
	# If old Drupal installs exist, display the list but first remove the
	# file being checked and provide a better path 
    elif [[ -s ./olddrupal.txt ]]; then
    	cat ./olddrupal.txt | sed 's/modules\/system\/system\.info//g' | sed 's/users\/\.home\///g' & rm ./olddrupal.txt 2> /dev/null
	fi
else
	echo " "
	echo 'No Drupal installs found!'
fi

sleep 1

# If phpBB installs are found
if [ -s ./phpbblist ]; then
	# Get the latest version of phpBB and define it
	new_phpbb_ver=$( curl -s https://api.github.com/repos/phpbb/phpbb/tags | awk -F'"' '/name/ {print $4}' | awk -F'-' '!/-[A-Za-z]/ {print $0}' | awk -F'-' 'NR==2{print $2}' )

	# Let the user know what the latest version is
	echo " "
	echo "phpBB - Latest version is $new_phpbb_ver"

	# For each phpBB in the temp file
	for f in $(cat ./phpbblist); do
		# Define the phpBB's version as a temporary variable
		phpbb_version=$(grep -H "version.=." $f | awk '{print $3}');
		# Check the installed phpBB version against the latest version.
		# If the version is old send it to the file oldphpbb.txt 
		if [[ ${phpbb_version//./} -ne ${new_phpbb_ver//./} ]]; then
		echo -en "$f = $phpbb_version\n" >> ./oldphpbb.txt
		fi
	done
	# If only new phpBB installs exist then say so
    	if [[ ! -s ./oldphpbb.txt ]]; then
    		echo "**phpBB installs found but are all up to date**" & rm ./oldphpbb.txt 2> /dev/null
	# If old phpBB installs exist, display list but first remove the 
	# file being checked and provide a better path
		elif [[ -s ./oldphpbb.txt ]]; then
    			cat ./oldphpbb.txt | sed 's/prosilver\/style.cfg//g' | sed 's/users\/\.home\///g' & rm ./oldphpbb.txt 2> /dev/null
    	fi
else
	echo " "
	echo 'No phpBB installs found!'
fi

sleep 1

# If Magento installs are found
if [ -s ./magentolist ]; then
	# Get the latest version of Magento and define it
	new_magento_ver=$( curl -s https://api.github.com/repos/magento/magento2/tags | awk -F'"' '/name/ {print $4}' | awk -F'-' '!/-[A-Za-z]/ {print $0}' | head -1 )

	# Let the user know what the latest version is
	echo " "
	echo "Magento - Latest version is $new_magento_ver"

	# For each Magento in the temp file
	for f in $(cat ./magentolist); do
		# Define the Magento's version as a temporary variable
		magento_version=$(grep -A 4 'return array(' $f | awk -F"'" 'NR>=2{ print $4 }' | awk 'BEGIN { ORS = "." } { print }');
		# Check the installed Magento version against the latest version.
		# If the version is old send it to the file oldmagento.txt 
		if [[ ${magento_version//./} -ne ${new_magento_ver//./} ]]; then
		echo -en "$f = $magento_version\n" >> ./oldmagento.txt
		fi
	done
	# If only new Magento installs exist then say so
    	if [[ ! -s ./oldmagento.txt ]]; then
    		echo "**Magento installs found but are all up to date**" & rm ./oldmagento.txt 2> /dev/null
	# If old Magento installs exist, display list but first remove the 
	# file being checked and provide a better path
		elif [[ -s ./oldmagento.txt ]]; then
    			cat ./oldmagento.txt | sed 's/app\/Mage.php//g' | sed 's/users\/\.home\///g' & rm ./oldmagento.txt 2> /dev/null
    	fi
else
	echo " "
	echo 'No Magento installs found!'
	echo " "
fi

IFS=$SAVEIFS

# Delete all temporary lists
rm ./wplist ./drupallist ./joomlalist ./phpbblist ./magentolist 2> /dev/null
}

# Determine the server that the script is being run from, then find all installs within a 
# certain predefined number of sublevels respective to the server's webroot and add them to
# a temporary file

# If on a Grid
if [[ ! -z "$SITE" ]]; then
    find ~/domains/*/ -maxdepth 7 -iwholename "*/wp-includes/version.php" > ./wplist
    find ~/domains/*/ -maxdepth 7 \( -iwholename '*/libraries/joomla/version.php' -o -iwholename '*/libraries/cms/version.php' -o -iwholename '*/libraries/cms/version/version.php' \) > ./joomlalist
    find ~/domains/*/ -maxdepth 7 -iwholename "*/modules/system/system.info" > ./drupallist
    find ~/domains/*/ -maxdepth 7 -iwholename "*prosilver/style.cfg" > ./phpbblist
    find ~/domains/*/ -maxdepth 7 -iwholename "*/app/Mage.php" > ./magentolist
    search
# If on Plesk or a "DV Developer"
elif [[ -f "/usr/local/psa/version" ]] || [[ ! -f "/usr/local/psa/version" ]] && [[ ! -f "/usr/local/cpanel/version" ]]; then
	if [ "$(id -u)" != "0" ]; then
		echo "This should be run as root or sudo. Exiting..."
		bye
	else
		find /var/www/ -maxdepth 8 -iwholename "*/wp-includes/version.php" > ./wplist
		find /var/www/ -maxdepth 8 \( -iwholename '*/libraries/joomla/version.php' -o -iwholename '*/libraries/cms/version.php' -o -iwholename '*/libraries/cms/version/version.php' \) > ./joomlalist
		find /var/www/ -maxdepth 8 -iwholename "*/modules/system/system.info" -print > ./drupallist
		find /var/www/ -maxdepth 8 -iwholename "*prosilver/style.cfg" -print > ./phpbblist
		find /var/www/ -maxdepth 8 -iwholename "*/app/Mage.php" -print > ./magentolist
		search
	fi	
# If on cPanel
elif [[ -f "/usr/local/cpanel/version" ]]; then
	if [ "$(id -u)" != "0" ]; then
		echo "This should be run as root or sudo. Exiting..."
		bye
	else
		find /home/*/public_html/ -maxdepth 6 -iwholename "*/wp-includes/version.php" > ./wplist
		find /home/*/public_html/ -maxdepth 6 \( -iwholename '*/libraries/joomla/version.php' -o -iwholename '*/libraries/cms/version.php' -o -iwholename '*/libraries/cms/version/version.php' \) > ./joomlalist
		find /home/*/public_html/ -maxdepth 6 -iwholename "*/modules/system/system.info" > ./drupallist
		find /home/*/public_html/ -maxdepth 6 -iwholename "*prosilver/style.cfg" > ./phpbblist
		find /home/*/public_html/ -maxdepth 6 -iwholename "*/app/Mage.php" > ./magentolist
		search
	fi
fi
