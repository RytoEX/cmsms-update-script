#!/bin/bash
#
# Perform the CMS Made Simple (CMSMS) 1.x diff update process
#
# Author:  RytoEX
# Created: April 19, 2016
# Updated: April 21, 2016
# Version: 0.8


# todo(ryto):  maybe run the CMSMS checksum script? or a regular md5 check?
#   could run it while admin_dir is still set to "admin"
#   or alter the checksum file to match the custom admin_dir setting
#
#   I think this works now?  Need to test more.
# todo(ryto):  cleanup checksum code
#   may be able to remove lines for /tmp and /install
# todo(ryto):  check CMSMSDir with trailing slash
#   /home/rytoex/scripts/cmsms-update-script/cmsms_test//config.php
#   Doesn't seem to cause it to fail, but should probably fix anyway.
# todo(ryto):  check admin_dir setting and skip some sed commands if we can
#   See Steps #4, #8, and #10
# todo(ryto):  handle multiple matches for diff_file
#   look into  ls cms*diff-$cmsms_version_current*.tar.gz | wc -l
# todo(ryto):  handle multiple matches for checksum_file
#   look into  ls cms*$cmsms_version_new*checksum.dat | wc -l
# todo(ryto):  handle zero matches for diff_file
# todo(ryto):  handle zero matches for checksum_file
#   for the above two entries, we could let it fail and have the script
#   notice diff_file/checksum_file are empty, but that wouldn't be graceful
# todo(ryto):  usage/help message
# todo(ryto):  see if this works with a full non-diff update
#   it _should_ work, but will have to change diff_file detection
# todo(ryto):  check minimum versions of bash, grep, tar, etc.
#   Here's a list of what versions I used when building this script:
#   GNU bash, version 4.2.25(1)-release
#   grep (GNU grep) 2.10
#   tar (GNU tar) 1.26
#   GNU sed version 4.2.1
#   GNU coreutils 8.13
#   - chmod
#   - cp
#   - date
#   - ls
#   - md5sum
#   - mv
#   - stat



# Overall Steps
#  1. Get site dir
#  2. Backup config file
#  3. Enable owner write permission on config file
#  4. Edit config file admin dir setting to default location
#  5. Move the admin dir to default location
#  6. Unpack diff
#  7. Move the admin dir to custom location
#  8. Edit config file admin dir setting to custom location
#  9. Restore original permissions on config file
# 10. Optional: Verify checksums


# 1. Get site dir
# Setup variables
# CMSMS Web Directory (Full Path)
CMSMSDir="/home/rytoex/scripts/cmsms-update-script/cmsms_min_test"


echo
echo
echo "#################################"
echo "  CMSMS Diff Update Script"
echo

echo "Looks like you're trying to update CMSMS with a diff!"
echo "I'll try to help you with that."
echo "Let's get started!"
echo

echo "You'll need to upload the appropriate .tar.gz diff file into the same directory"
echo "as this script."
#echo "You can also upload the corresponding .dat checksum file, and this script will"
#echo "try to use it to verify the update."
echo

# Ask the user to confirm CMSMSDir
while true; do
  echo "The setting for the CMSMS directory is:  $CMSMSDir"
	read -e -p "Is this correct? (y/n) " -i "y" yn
	case $yn in
		[Yy]* )
      echo "Okay!"
      echo
      break
      ;;
		[Nn]* )
      echo "Sorry about that."
      read -e -p "Where is the CMSMS directory? " CMSMSDir
      ;;
		* ) echo "Please answer yes (Y/y) or no (N/n).";;
	esac
done


# Config file
configFileName="config.php"
# Version file
versionFileName="version.php"
# Set full config path
configFile=$CMSMSDir/$configFileName
# Set full version path
versionFile=$CMSMSDir/$versionFileName
# Get config file permissions
configFilePerm=$(stat --printf '%a' $configFile)
# Set default admin_dir
admin_dir_default="admin"
# Check for custom admin_dir setting
admin_dir_custom_default="custom"
admin_dir_custom=$(grep -Po "($config\['admin_dir'\] = ')\K(.*)(?=')" $configFile)
# If admin_dir is not explicitly set, assume it's admin_dir_default ("admin")
if [ -z $admin_dir_custom ]; then
  admin_dir_custom=$admin_dir_default
fi
# Current datestamp
datestamp=$(date +%Y-%m-%d)
# Current CMSMS Version
#cmsms_version_current=$(grep -Po 'CMS_VERSION = "([0-9.]+)"' $versionFile | cut -d ' ' -f3 | tr -d '"')
cmsms_version_current=$(grep -Po 'CMS_VERSION = "\K([0-9.]+)(?=")' $versionFile)
# Diff file
diff_file="cmsmadesimple-english-diff-1.12.1-1.12.2.tar.gz"
#diff_file=$(ls cms*diff*$cmsms_version_current*.tar.gz)
diff_file=$(ls cms*diff-$cmsms_version_current*.tar.gz)
# New CMSMS Version
cmsms_version_new=$(echo $diff_file | grep -Po "\-\K([0-9.]*)(?=.tar.gz)")


# Ask the user to confirm admin_dir_custom
while true; do
  echo "The setting for the CMSMS Admin Dir is:  $admin_dir_custom"
	read -e -p "Is this correct? (y/n) " -i "y" yn
	case $yn in
		[Yy]* )
      echo "Okay!"
      echo
      break
      ;;
		[Nn]* )
      echo "Sorry about that."
      read -e -p "Where is the CMSMS Admin Dir? " admin_dir_custom
      ;;
		* ) echo "Please answer yes (Y/y) or no (N/n).";;
	esac
done


# Ask the user to confirm diff_file
while true; do
  echo "The setting for the CMSMS diff file is:  $diff_file"
	read -e -p "Is this correct? (y/n) " -i "y" yn
	case $yn in
		[Yy]* )
      echo "Okay!"
      echo
      break
      ;;
		[Nn]* )
      echo "Sorry about that."
      read -e -p "Where is the CMSMS diff file? " diff_file
      ;;
		* ) echo "Please answer yes (Y/y) or no (N/n).";;
	esac
done

echo
echo "Let's review your settings."
echo
echo "CMSMS directory:         $CMSMSDir"
echo "CMSMS admin_dir config:  $admin_dir_custom"
echo "Diff file to apply:      $diff_file"
echo "CMSMS config file perm:  $configFilePerm"
echo "Current CMSMS Version:   $cmsms_version_current"
echo "New CMSMS Version:       $cmsms_version_new"
echo

# Ask the user to confirm all settings
while true; do
	read -e -p "Are your settings correct? (y/n) " -i "y" yn
	case $yn in
		[Yy]* )
      echo "Okay!"
      echo
      break
      ;;
		[Nn]* )
      echo "Sorry about that."
      echo "Please rerun this script to start over."
      echo
      exit 1
      ;;
		* ) echo "Please answer yes (Y/y) or no (N/n).";;
	esac
done


# Continue the update script
echo "Proceeding with the update"

# 2. Backup config
echo "Backing up config file..."
echo " Copying"
echo "  $configFile"
echo "  to"
echo "  $configFile.bak.$datestamp"
#cp -p $CMSMSDir/$config $CMSMSDir/$config
cp -p $configFile $configFile.bak.$datestamp
echo " Done!"

# 3. Enable owner write permission on config.php
echo "Unlocking config file..."
chmod u+w $configFile
echo " Done!"

# 4. Edit config file admin dir setting to default location
echo "Editing admin_dir config..."
oldConfigLine="\$config\['admin_dir'\] = '$admin_dir_custom';"
newConfigLine="\$config\['admin_dir'\] = '$admin_dir_default';"
sed -i "s/$oldConfigLine/$newConfigLine/" $configFile
echo " Done!"

# 5. Move the admin dir to default location
echo "Rename admin_dir to default setting for the update if needed..."
if [ $admin_dir_custom != $admin_dir_default ]; then
  echo " CMSMS admin_dir had custom setting"
  echo " Renaming admin_dir to the default for the update..."
  echo " Renaming"
  echo "  $CMSMSDir/$admin_dir_custom"
  echo "  to"
  echo "  $CMSMSDir/$admin_dir_default"
  mv $CMSMSDir/$admin_dir_custom $CMSMSDir/$admin_dir_default
  echo " Done!"
else
  echo " CMSMS admin_dir had default setting"
  echo " Skipping admin_dir rename"
fi

# 6. Unpack diff
echo "Unpacking the diff"
tar -xzf $diff_file -C $CMSMSDir
echo " Done!"

# 7. Move the admin dir to custom location
echo "Rename admin_dir back to custom setting if needed..."
if [ $admin_dir_custom != $admin_dir_default ]; then
  echo " CMSMS admin_dir had custom setting"
  echo " Renaming admin_dir back to custom setting..."
  echo " Renaming"
  echo "  $CMSMSDir/$admin_dir_default"
  echo "  to"
  echo "  $CMSMSDir/$admin_dir_custom"
  mv $CMSMSDir/$admin_dir_default $CMSMSDir/$admin_dir_custom
  echo " Done!"
else
  echo " CMSMS admin_dir had default setting"
  echo " Skipping admin_dir rename"
fi

# 8. Edit config file admin dir setting to custom location
echo "Editing admin_dir config..."
oldConfigLine="\$config\['admin_dir'\] = '$admin_dir_default';"
newConfigLine="\$config\['admin_dir'\] = '$admin_dir_custom';"
sed -i "s/$oldConfigLine/$newConfigLine/" $configFile
echo " Done!"

# 9. Restore original permissions on config file
echo "Restoring config file permissions..."
echo " Changing config file permission to $configFilePerm"
chmod $configFilePerm $configFile
echo " Done!"

# Everything should be done!
admin_dir_custom_check=$(grep -Po "($config\['admin_dir'\] = ')\K(.*)(?=')" $configFile)
cmsms_version_current_check=$(grep -Po 'CMS_VERSION = "\K([0-9.]+)(?=")' $versionFile)
echo
echo "CMSMS admin_dir config:  $admin_dir_custom_check"
echo "Updated CMSMS Version:   $cmsms_version_current_check"
echo

# Check that the diff update version and the new current version match
if [ $cmsms_version_new == $cmsms_version_current_check ]; then
  echo "The update should be complete!"
else
  echo "There may have been a problem.  Please double check your install."
  exit 2
fi

# Maybe do checksum stuff here as a final check?
while true; do
	read -e -p "Do you want to verify the file checksums? (y/n) " -i "y" yn
	case $yn in
		[Yy]* )
      verify_checksums=true;
      echo "Okay!"
      echo
      break
      ;;
		[Nn]* )
      verify_checksums=false;
      echo "Okay then."
      echo "Exiting now."
      echo
      exit
      ;;
		* ) echo "Please answer yes (Y/y) or no (N/n).";;
	esac
done

if $verify_checksums; then
  echo "Verifying file checksums..."
  echo " Showing only failed checksums"
  echo
  checksum_file="cmsmadesimple-1.12.1-english-checksum.dat"
  checksum_file="cmsmadesimple-1.12.2-english-test-checksum.dat"
  #checksum_file="cmsmadesimple-1.12.2-english-checksum.dat"
  checksum_file=$(ls cms*$cmsms_version_new*checksum.dat)
  sed -i "s#\./admin_dir_default/#\./$admin_dir_custom/#g" $checksum_file

  script_dir=$PWD
  #echo $script_dir
  cd $CMSMSDir
  #echo $PWD

  # Verify file checksums
  md5sum --check --quiet $script_dir/$checksum_file
fi

echo
echo "The update script is complete."
echo
echo
