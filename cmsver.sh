#!/bin/bash

###############################################################################

# Find popular CMS (and the WP Revslider plugin) installed on a Media Temple
# Grid or DV with Plesk/cPanel, and verify the version against the latest
# official version release.

###############################################################################

# To make things easier to read
BoldOn="\033[1m"
BoldOff="\033[22m"

# To handle directories/files with spaces in the name
SAVEIFS=$IFS
IFS=$(echo -en "\n\b")

echo "Searching for installed CMS..."
echo
# Check what type of server it is, then define variables with the appropriate search path
## If it's a Grid
if [[ ! -z "$SITE" ]]; then
  wp_search=$(find ~/domains/*/ -maxdepth 7 -iwholename "*/wp-includes/version.php") 
  joomla_search=$(find ~/domains/*/ -maxdepth 7 \( -iwholename '*/libraries/joomla/version.php' -o -iwholename '*/libraries/cms/version.php' -o -iwholename '*/libraries/cms/version/version.php' \)) 
  drupal_search=$(find ~/domains/*/ -maxdepth 7 -iwholename "*/modules/system/system.info")
  phpbb_search=$(find ~/domains/*/ -maxdepth 7 -iwholename "*prosilver/style.cfg") 
  magento_search=$(find ~/domains/*/ -maxdepth 7 -iwholename "*/app/Mage.php") 
  opencart_search=$(find ~/domains/*/ -maxdepth 7 -iwholename "*/upload/index.php") 
  moodle_search=$(find $(find ~/domains/*/ -maxdepth 5 -type f -name "TRADEMARK.txt" | sed 's/TRADEMARK.txt//') -maxdepth 1 -name "version.php" -print > ./moodlelist) 
## If it's a DV with Plesk or DV Dev
elif [[ -f "/usr/local/psa/version" ]] || [[ ! -f "/usr/local/psa/version" ]] && [[ ! -f "/usr/local/cpanel/version" ]]; then
  # Exit the script if not run using sudo/root
  if [ "$(id -u)" != "0" ]; then
    echo "This script needs to run as root or sudo. Exiting..."
    exit 0
  else
  wp_search=$(find /var/www/ -maxdepth 7 -iwholename "*/wp-includes/version.php")
  joomla_search=$(find /var/www/ -maxdepth 7 \( -iwholename '*/libraries/joomla/version.php' -o -iwholename '*/libraries/cms/version.php' -o -iwholename '*/libraries/cms/version/version.php' \))
  drupal_search=$(find /var/www/ -maxdepth 7 -iwholename "*/modules/system/system.info")
  phpbb_search=$(find /var/www/ -maxdepth 7 -iwholename "*prosilver/style.cfg")
  magento_search=$(find /var/www/ -maxdepth 7 -iwholename "*/app/Mage.php")
  opencart_search=$(find /var/www/ -maxdepth 7 -iwholename "*/upload/index.php")
  moodle_search=$(find $(find /var/www/ -maxdepth 5 -type f -name "TRADEMARK.txt" | sed 's/TRADEMARK.txt//') -maxdepth 1 -name "version.php" -print > ./moodlelist)
  fi

## If it's a DV with cPanel
elif [[ -f "/usr/local/cpanel/version" ]]; then
  # Exit the script if not run using sudo/root
  if [ "$(id -u)" != "0" ]; then
    echo "This script needs to run as root or sudo. Exiting..."
    exit 0
  else
    wp_search=$(find /home/*/ -maxdepth 6 -iwholename "*/wp-includes/version.php")
    joomla_search=$(find /home/*/ -maxdepth 6 \( -iwholename '*/libraries/joomla/version.php' -o -iwholename '*/libraries/cms/version.php' -o -iwholename '*/libraries/cms/version/version.php' \))
    drupal_search=$(find /home/*/ -maxdepth 6 -iwholename "*/modules/system/system.info")
    phpbb_search=$(find /home/*/ -maxdepth 6 -iwholename "*prosilver/style.cfg")
    magento_search=$(find /home/*/ -maxdepth 6 -iwholename "*/app/Mage.php")
    opencart_search=$(find /home/*/ -maxdepth 6 -iwholename "*/upload/index.php")
    moodle_search=$(find $(find /home/*/ -maxdepth 6 -type f -name "TRADEMARK.txt" | sed 's/TRADEMARK.txt//') -maxdepth 1 -name "version.php" -print > ./moodlelist)
  fi
fi

# WordPress
if [[ -z $wp_search ]]; then
  echo 'No WordPress installs found!'
else
  # Get the latest version of WordPress and define it
  #new_wp_ver=$(curl -s http://api.wordpress.org/core/version-check/1.5/ | head -n 4 | tail -n 1)
  # Let the user know what the latest version is
  echo -e "${BoldOn}WordPress - Latest version is $new_wp_ver${BoldOff}"
  for wp_path in $wp_search; do
    # For each WordPress define the WordPress's version as a temporary variable
    wp_version=$(grep '$wp_version =' $wp_path | cut -d\' -f2)
    # Check the installed WordPress version against the latest version
    if [[ ${wp_version//./} -ne ${new_wp_ver//./} ]]; then
      echo "$(echo "$wp_path" | sed 's/wp-includes\/version.php//g; s/users\/\.home\///g') = "$wp_version""
    fi
  done
fi
echo

# Joomla
if [[ -z $joomla_search ]]; then
  echo 'No Joomla installs found!'
else
  # Get the latest version of Joomla and define it
  new_joomla_ver=$(curl -s https://api.github.com/repos/joomla/joomla-cms/releases/latest | awk -F\" '/tag_name/ { print $4 }')
  # Let the user know what the latest version is
  echo -e "${BoldOn}Joomla - Latest version is $new_joomla_ver${BoldOff}"
  for joomla_path in $joomla_search; do
    # For each Joomla define the Joomla's version as a temporary variable
    joomla_version="$(grep -E "var|const|public" $joomla_path | awk -F\' '/RELEASE/{print$2}').$(grep -E "var|const|public" $joomla_path | awk -F\' '/DEV_LEVEL/{print$2}')"
    # Check the installed Joomla version against the latest version
    if [[ ${joomla_version//./} -ne ${new_joomla_ver//./} ]]; then
      echo "$(echo "$joomla_path" | sed 's/libraries\/.*.php//g; s/users\/\.home\///g') = "$joomla_version""
    fi
  done
fi
echo

# Drupal
if [[ -z $drupal_search ]]; then
  echo 'No Drupal installs found!'
else
  # Get the latest version of Drupal and define it
  # This first one is considered the latest but ready for production
  new_drupal_ver1=$( curl -s https://www.drupal.org/project/drupal | grep '<h4>Drupal core' | grep -v dev | head -n 1 | awk -F' ' '{print $3}' | awk -F'<' '{print $1}' )
  # This second one is considered older but still up to date
  new_drupal_ver2=$( curl -s https://www.drupal.org/project/drupal | grep '<h4>Drupal core' | grep -v dev | head -n 2 | tail -n 1 | awk -F' ' '{print $3}' | awk -F'<' '{print $1}' )
  # Let the user know what the latest version is
  echo -e "${BoldOn}Drupal - Latest version is $new_drupal_ver1, stable version is $new_drupal_ver2${BoldOff}"
  for drupal_path in $drupal_search; do
    # For each Drupal define the Drupal's version as a temporary variable
    drupal_version=$(grep "version = \"" $drupal_path | cut -d '"' -f2)
    # Check the installed Drupal version against the latest version
    if [[ ${drupal_version//./} -ne ${new_drupal_ver1//./} ]] && [[ ${drupal_version//./} -ne ${new_drupal_ver2//./} ]]; then
      echo "$(echo "$drupal_path" | sed 's/modules\/system\/system\.info//g; s/users\/\.home\///g') = "$drupal_version""
    fi
  done
fi
echo

# phpBB
if [[ -z $phpbb_search ]]; then
  echo 'No phpBB installs found!'
else
  # Get the latest version of phpBB and define it
  new_phpbb_ver=$(curl -s https://api.github.com/repos/phpbb/phpbb/tags | awk -F'"' '/name/ {print $4}' | awk -F'-' '!/-[A-Za-z]/ {print $0}' | awk -F'-' 'NR==2{print $2}')
  # Let the user know what the latest version is
  echo -e "${BoldOn}phpBB - Latest version is $new_phpbb_ver${BoldOff}"
  for phpbb_path in $phpbb_search; do
    # For each phpBB define the phpBB's version as a temporary variable
    phpbb_version=$(grep -H "version.=." $phpbb_path | awk 'NR==1{print $3}')
    # Check the installed phpBB version against the latest version
    if [[ ${phpbb_version//./} -ne ${new_phpbb_ver//./} ]]; then
      echo "$(echo "$phpbb_path" | sed 's/styles\/prosilver\/style.cfg//g; s/users\/\.home\///g') = "$phpbb_version""
    fi
  done
fi
echo

# Magento
if [[ -z $magento_search ]]; then
  echo 'No Magento installs found!'
else
  # Get the latest version of Magento and define it
  new_magento_ver=$(curl -s https://api.github.com/repos/magento/magento2/tags | awk -F'"' '/name/ {print $4}' | awk -F'-' '!/-[A-Za-z]/ {print $0}' | head -1)
  # Let the user know what the latest version is
  echo -e "${BoldOn}Magento - Latest version is $new_magento_ver${BoldOff}"
  for magento_path in $magento_search; do
    # For each Magento define the Magento's version as a temporary variable
    magento_version=$(grep "return '" $magento_path | awk -F"'" '{ print $2 }')
    # Check the installed Magento version against the latest version
    if [[ ${magento_version//./} -ne ${new_magento_ver//./} ]]; then
      echo "$(echo "$magento_path" | sed 's/app\/Mage.php//g; s/users\/\.home\///g') = "$magento_version""
    fi
  done
fi
echo

# Opencart
if [[ -z $opencart_search ]]; then
  echo 'No Opencart installs found!'
else
  # Get the latest version of Opencart and define it
  new_opencart_ver=$(curl -s https://api.github.com/repos/opencart/opencart/tags | head -3 | awk -F'"' '/name/ {print $4}')
  # Let the user know what the latest version is
  echo -e "${BoldOn}Opencart - Latest version is $new_opencart_ver${BoldOff}"
  for opencart_path in $opencart_search; do
    # For each Opencart define the Opencart's version as a temporary variable
    opencart_version=$(grep VERSION $opencart_path | awk -F"'" '{print $4}')
    # Check the installed Opencart version against the latest version
    if [[ ${opencart_version//./} -ne ${new_opencart_ver//./} ]]; then
      echo "$(echo "$opencart_path" | sed 's/upload\/index.php//g; s/users\/\.home\///g') = "$opencart_version""
    fi
  done
fi
echo

# Moodle
if [[ -z $moodle_search ]]; then
  echo 'No Moodle installs found!'
else
  # Get the latest version of Moodle and define it
  new_moodle_ver=$(curl -s "https://git.moodle.org/gw?p=moodle.git;a=tags" | grep "list name" | head -1 | sed 's/\(.*\)>v\(.*\)<\/a>\(.*\)/\2/g')
  # Let the user know what the latest version is
  echo -e "${BoldOn}Moodle - Latest version is $new_moodle_ver${BoldOff}"
  for moodle_path in $moodle_search; do
    # For each Moodle define the Moodle's version as a temporary variable
    moodle_version=$(grep VERSION $moodle_path | awk -F"'" '{print $4}')
    # Check the installed Moodle version against the latest version
    if [[ ${moodle_version//./} -ne ${new_moodle_ver//./} ]]; then
      echo "$(echo "$moodle_path" | sed 's/upload\/index.php//g; s/users\/\.home\///g') = "$moodle_version""
    fi
  done
fi
echo

IFS=$SAVEIFS
