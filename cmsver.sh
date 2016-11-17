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
#To handle directories and files with spaces - Start
SAVEIFS=$IFS
IFS=$(echo -en "\n\b")

# If WordPress installs are found
if [ -s ./wplist ]; then
	# Get the latest version of WordPress.
	result=$(curl -s http://api.wordpress.org/core/version-check/1.5/ | head -n 4 | tail -n 1)
	# If the version is only two numbers, i.e. "4.6", then we need to add a .0
	# at the end so our comparison works later.
	if [[ ${result//./} -lt 100 ]]; then
		echo "$result" | awk '{print $0".0"}' > ./version-check
	else
		echo "$result" > ./version-check
	fi
	# Define the resulting version and delete the temp file
	latest_version=(`cat ./version-check`)
	rm ./version-check

	# Let the user know what the latest version is
	echo " "
	echo "WordPress - Latest version is $latest_version"

	# For each WordPress in the temp file
		for f in $(cat ./wplist); do
	# Define the WordPress's version as a temporary variable
		version_wip=$(grep "wp_version =" $f | cut -d\' -f2);
			if [[ ${version_wip//./} -lt 100 ]]; then
			echo "$version_wip" | awk '{print $0".0"}' > ./version_tmp
			else
			echo "$version_wip" > ./version_tmp
			fi
			# Define the resulting version and delete the temp file
			version=(`cat ./version_tmp`)
	# Check the installed WordPress version against the latest version:
	# If the version is old send it to the file oldwp.txt 
		if [[ ${version//./} -lt ${latest_version//./} ]]; then
			echo -en "$f = $version\n" >> ./oldwp.txt
	# If the version is the same send it to the file newwp.txt
    	elif [[ ${version//./} -eq ${latest_version//./} ]]; then
    		echo "found" >> ./newwp.txt
    	fi
       	done
	# If only new WP installs exist then say so
    	if [[ -s ./newwp.txt ]] && [[ ! -s ./oldwp.txt ]]; then
    		echo "**WordPress installs found but are all up to date**" & rm ./newwp.txt ./oldwp.txt 2> /dev/null
	# If both new and old WP installs exist, display the old WP installs only, but
	# first remove the file being checked and provide a better path 
    	elif [[ -s ./newwp.txt ]] && [[ -s ./oldwp.txt ]]; then
    		cat ./oldwp.txt | sed 's/wp-includes\/version.php/ /g' | sed 's/users\/\.home\///g'; rm ./newwp.txt ./oldwp.txt
	# If new WP installs arent found but old ones are, then display the old ones, but
	# first remove the file being checked and provide a better path 
    	elif [[ ! -s ./newwp.txt ]] && [[ -s ./oldwp.txt ]]; then
    		cat ./oldwp.txt | sed 's/wp-includes\/version.php/ /g' | sed 's/users\/\.home\///g'; rm ./oldwp.txt
   		fi
else
	echo " "
	echo 'No WordPress installs found!'
fi

# On servers with a lot of CMS, the script will start outputting the other CMS checks 
# too fast causing things to get messy. This makes each section wait a second
# before continuing
sleep 1

# If Joomla installs are found
if [ -s ./joomlalist ]; then
	# Get the latest version of Joomla and define it
	latest_version=$( curl -s https://api.github.com/repos/joomla/joomla-cms/releases/latest | awk -F\" '/tag_name/ { print $4 }' )

	# Let the user know what the latest version is
	echo " "
	echo "Joomla - Latest version is $latest_version"

	# For each Joomla in the temp file
		for f in $(cat ./joomlalist); do
		# Define the Joomla's version as a temporary variable
		version=($(grep -E "var|const|public" $f | awk -F\' '/RELEASE/{print$2}').$(grep -E "var|const|public" $f | awk -F\' '/DEV_LEVEL/{print$2}'));
	# Check the installed Joomla version against the latest version:
	# If the version is old send it to the file oldjoomla.txt 
		if [[ ${version//./} -lt ${latest_version//./} ]]; then
		echo -en "$f = $version\n" >> ./oldjoomla.txt
    	# If the version is the same send it to the file newjoomla.txt
    	elif [[ ${version//./} -eq ${latest_version//./} ]]; then
    		echo "found" >> ./newjoomla.txt
		fi
		done
	# If only new Joomla installs exist then say so
    		if [[ -s ./newjoomla.txt ]] && [[ ! -s ./oldjoomla.txt ]]; then
    		echo "**Joomla installs found but are all up to date**" & rm ./newjoomla.txt ./oldjoomla.txt 2> /dev/null
	# If both new and old Joomla installs exist, display the old Joomla installs only, but
	# first remove the file being checked and provide a better path
			elif [[ -s ./newjoomla.txt ]] && [[ -s ./oldjoomla.txt ]]; then
    		cat ./oldjoomla.txt | sed 's/libraries\/cms\/version\/version\.php//g' | sed 's/users\/\.home\///g' & rm ./newjoomla.txt ./oldjoomla.txt
	# If new Joomla installs arent found but old ones are, then display the old ones, but
	# first remove the file being checked and provide a better path
    		elif [[ ! -s ./newjoomla.txt ]] && [[ -s ./oldjoomla.txt ]]; then
    		cat ./oldjoomla.txt | sed 's/libraries\/cms\/version\/version\.php//g' | sed 's/users\/\.home\///g' & rm ./oldjoomla.txt
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
	latest_version1=$( curl -s https://www.drupal.org/project/drupal | grep '<h4>Drupal core' | grep -v dev | head -n 1 | awk -F' ' '{print $3}' | awk -F'<' '{print $1}' )
	# This second one is considered older but still up to date
	latest_version2=$( curl -s https://www.drupal.org/project/drupal | grep '<h4>Drupal core' | grep -v dev | head -n 2 | tail -n 1 | awk -F' ' '{print $3}' | awk -F'<' '{print $1}' )
 
	# Let the user know what the latest version is
	echo " "
	echo "Drupal - Latest version is $latest_version1, stable version is $latest_version2"
	# For each Drupal in the temp file
		for f in $(cat ./drupallist); do
	# Define the Drupal version as a temporary variable
		version=$(grep "version = \"" $f | cut -d '"' -f2);
	# Check the installed Drupal version against the latest versions,
	# If the version is considered old for the latest version, send it to the file olddrupal.txt
			if [[ ${version//./} -lt ${latest_version1//./} ]] && [[ ${version//./} -gt ${latest_version2//./} ]]; then
				echo -en "$f = $version\n" >> ./olddrupal.txt
	# If the version is considered old for the stable version, send it to the file olddrupal.txt
			elif [[ ${version//./} -lt ${latest_version2//./} ]]; then
				echo -en "$f = $version\n" >> ./olddrupal.txt
	# If the version is the up to date for either latest or stable, send it to the file newdrupal.txt
			elif [[ ${version//./} -eq ${latest_version1//./} ]] || [[ ${version//./} -eq ${latest_version2//./} ]]; then
				echo -en "$f = $version\n" >> ./newdrupal.txt
			fi
		done
	# If only new Drupal installs exist then say so
    		if [[ -s ./newdrupal.txt ]] && [[ ! -s ./olddrupal.txt ]]; then
    		echo "**Drupal installs found but are all up to date**" & rm ./newdrupal.txt ./olddrupal.txt 2> /dev/null
	# If both new and old Drupal installs exist, display the old Drupal installs only, but
	# first remove the file being checked and provide a better path 
    		elif [[ -s ./newdrupal.txt ]] && [[ -s ./olddrupal.txt ]]; then
    		cat ./olddrupal.txt | sed 's/modules\/system\/system\.info//g' | sed 's/users\/\.home\///g' & rm ./newdrupal.txt ./olddrupal.txt
	# If new Drupal installs arent found but old ones are, then display the old ones, but
	# first remove the file being checked and provide a better path 
    		elif [[ ! -s ./newdrupal.txt ]] && [[ -s ./olddrupal.txt ]]; then
    		cat ./olddrupal.txt | sed 's/modules\/system\/system\.info//g' | sed 's/users\/\.home\///g' & rm ./olddrupal.txt
   			fi
else
	echo " "
	echo 'No Drupal installs found!'
fi

sleep 1

# If phpBB installs are found
if [ -s ./phpbblist ]; then
	# Get the latest version of phpBB and define it
	latest_version=$( curl -s https://api.github.com/repos/phpbb/phpbb/tags | awk -F'"' '/name/ {print $4}' | awk -F'-' '!/-[A-Za-z]/ {print $0}' | awk -F'-' 'NR==2{print $2}' )

	# Let the user know what the latest version is
	echo " "
	echo "phpBB - Latest version is $latest_version"

	# For each phpBB in the temp file
		for f in $(cat ./phpbblist); do
		# Define the phpBB's version as a temporary variable
		version=($(grep -H "version.=." $f | awk '{print $0}'));
	# Check the installed phpBB version against the latest version:
	# If the version is old send it to the file oldphpbb.txt 
		if [[ ${version//./} -lt ${latest_version//./} ]]; then
		echo -en "$f = $version\n" >> ./oldphpbb.txt
    	# If the version is the same send it to the file newphpbb.txt
    	elif [[ ${version//./} -eq ${latest_version//./} ]]; then
    		echo "found" >> ./newphpbb.txt
		fi
		done
	# If only new phpBB installs exist then say so
    		if [[ -s ./newphpbb.txt ]] && [[ ! -s ./oldphpbb.txt ]]; then
    		echo "**phpBB installs found but are all up to date**" & rm ./newphpbb.txt ./oldphpbb.txt 2> /dev/null
	# If both new and old phpBB installs exist, display the old phpBB installs only, but
	# first remove the file being checked and provide a better path
			elif [[ -s ./newphpbb.txt ]] && [[ -s ./oldphpbb.txt ]]; then
    		cat ./oldphpbb.txt | sed 's/libraries\/cms\/version\/version\.php//g' | sed 's/users\/\.home\///g' & rm ./newphpbb.txt ./oldphpbb.txt
	# If new phpBB installs arent found but old ones are, then display the old ones, but
	# first remove the file being checked and provide a better path
    		elif [[ ! -s ./newphpbb.txt ]] && [[ -s ./oldphpbb.txt ]]; then
    		cat ./oldphpbb.txt | sed 's/libraries\/cms\/version\/version\.php//g' | sed 's/users\/\.home\///g' & rm ./oldphpbb.txt
   			fi
else
	echo " "
	echo 'No phpBB installs found!'
	echo " "
fi
#To handle directories and files with spaces - End
IFS=$SAVEIFS

# Delete all temporary lists
rm ./wplist ./version_tmp ./drupallist ./joomlalist ./phpbblist 2> /dev/null
}

# Determine the server that the script is being run from, then find all installs within a 
# certain predefined number of sublevels respective to the server's webroot and add them to
# a temporary file

# If on a Grid
if [[ ! -z "$SITE" ]]; then
    find ~/domains/*/ -maxdepth 6 -iwholename "*/wp-includes/version.php" > ./wplist
    find ~/domains/*/ -maxdepth 7 \( -iwholename '*/libraries/joomla/version.php' -o -iwholename '*/libraries/cms/version.php' -o -iwholename '*/libraries/cms/version/version.php' \) > ./joomlalist
    find ~/domains/*/ -maxdepth 7 -iwholename "*/modules/system/system.info" > ./drupallist
    find ~/domains/*/ -maxdepth 6 -iwholename "*prosilver/style.cfg" > ./phpbblist
    search
# If on Plesk or a "DV Developer"
elif [[ -f "/usr/local/psa/version" ]] || [[ ! -f "/usr/local/psa/version" ]] && [[ ! -f "/usr/local/cpanel/version" ]]; then
	if [ "$(id -u)" != "0" ]; then
		echo "This should be run as root or sudo. Exiting..."
		bye
	else
		find /var/www/ -maxdepth 7 -iwholename "*/wp-includes/version.php" > ./wplist
		find /var/www/ -maxdepth 8 \( -iwholename '*/libraries/joomla/version.php' -o -iwholename '*/libraries/cms/version.php' -o -iwholename '*/libraries/cms/version/version.php' \) > ./joomlalist
		find /var/www/ -maxdepth 8 -iwholename "*/modules/system/system.info" -print > ./drupallist
		find /var/www/ -maxdepth 7 -iwholename "*prosilver/style.cfg" -print > ./phpbblist
		search
	fi	
# If on cPanel
elif [[ -f "/usr/local/cpanel/version" ]]; then
	if [ "$(id -u)" != "0" ]; then
		echo "This should be run as root or sudo. Exiting..."
		bye
	else
		find /home/*/public_html/ -maxdepth 5 -iwholename "*/wp-includes/version.php" > ./wplist
		find /home/*/public_html/ -maxdepth 6 \( -iwholename '*/libraries/joomla/version.php' -o -iwholename '*/libraries/cms/version.php' -o -iwholename '*/libraries/cms/version/version.php' \) > ./joomlalist
		find /home/*/public_html/ -maxdepth 6 -iwholename "*/modules/system/system.info" > ./drupallist
		find /home/*/public_html/ -maxdepth 5 -iwholename "*prosilver/style.cfg" > ./phpbblist
		search
	fi
fi
