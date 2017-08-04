#!/bin/bash
#
# Help perform the CMS Made Simple (CMSMS) 1.x diff update process
#
# Author:   Ryan Foster
# Created:  April 19, 2016
# Updated:  August 4, 2017
# Version:  0.9-dev
# Name:     Why Did I Do This Again
#
# CMSMSUpdateDiff - Help perform the CMS Made Simple (CMSMS) 1.x diff update process
# Copyright (C) 2016  Ryan Foster
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.


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


script_author="Ryan Foster"
script_updated="August 4, 2017"
script_version="0.9-dev"
script_version_name="Why Did I Do This Again"
script_cmd="CMSMSUpdateDiff"


# file select menu using file glob pattern in arg1
function selectFile() {
	# first arg should be file glob pattern
	if [ -n "$1" ]; then
		file_glob="$1"
	fi
	PS3="Select a file: "
	local selected_file
	select selected_file in $file_glob;
	do
		echo "$selected_file"
		break
	done
}

# Usage and options
usage="Usage: $script_cmd.sh [-hv] -- program to help perform CMS Made Simple 1.x updates

where:
  -h  show this help text and exit
  -v  output version information and exit"

while getopts ':hv' option; do
	case "$option" in
		h) echo "$usage"
			exit
			;;
		v) echo "$script_cmd $script_version"
			exit
			;;
		:) printf "missing argument for -%s\n" "$OPTARG" >&2
			echo "$usage" >&2
			exit 1
			;;
		\?) printf "illegal option: -%s\n" "$OPTARG" >&2
			echo "$usage" >&2
			exit 1
			;;
	esac
done
shift $((OPTIND - 1))


# 1. Get site dir
# Setup variables
# CMSMS Web Directory (Full Path)
CMSMSDir="/home/rytoex/scripts/cmsms-update-script/cmsms_min_test"
CMSMSDir="$PWD/cmsms_test"


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
echo "You can also upload the corresponding .dat checksum file, and this script will"
echo "try to use it to verify the update."
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

# Fix trailing slash on CMSMSDir
CMSMSDir=${CMSMSDir%"/"}
# Current datestamp
datestamp=$(date +%Y-%m-%d)
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
# Using a diff?
updateWithDiff=true
# Set default admin_dir
admin_dir_default="admin"
# Set flag for if there is a custom admin dir config setting
hasCustomAdminDir=true
# Check for custom admin_dir setting
admin_dir_config_default="custom"
admin_dir_config=$(grep -Po "($config\['admin_dir'\] = ')\K(.*)(?=')" $configFile)
# If admin_dir is not explicitly set, assume it's admin_dir_default ("admin")
# Set hasCustomAdminDir to false
if [ -z $admin_dir_config ] || [ $admin_dir_config == $admin_dir_default ]; then
	admin_dir_config=$admin_dir_default
	hasCustomAdminDir=false
fi

# Ask the user to confirm admin_dir_config
while true; do
	echo "The setting for the CMSMS Admin Dir is:  $admin_dir_config"
	read -e -p "Is this correct? (y/n) " -i "y" yn
	case $yn in
		[Yy]* )
			echo "Okay!"
			echo
			break
			;;
		[Nn]* )
			echo "Sorry about that."
			read -e -p "Where is the CMSMS Admin Dir? " admin_dir_config
			;;
		* ) echo "Please answer yes (Y/y) or no (N/n).";;
	esac
done


# Current CMSMS Version
#cmsms_version_current=$(grep -Po 'CMS_VERSION = "([0-9.]+)"' $versionFile | cut -d ' ' -f3 | tr -d '"')
cmsms_version_current=$(grep -Po 'CMS_VERSION = "\K([0-9.]+)(?=")' $versionFile)

# Get a diff file
diff_file_glob="cms*diff-$cmsms_version_current-*.tar.gz"
diff_file_count=$(ls $diff_file_glob | wc -l)
if [ $diff_file_count -gt 1 ]; then
	# multiple valid diff files present
	echo "There are too many valid diff files.  Please choose one."
	diff_file=$(selectFile "$diff_file_glob")
elif [ $diff_file_count -eq 0 ]; then
	# no valid diff files present
	echo "There doesn't seem to be a valid diff file."
	echo "Please add a diff file to this directory and rerun this script."
	echo
	exit 3
else
	diff_file=$(ls $diff_file_glob)
fi

# New CMSMS Version
cmsms_version_new=$(echo $diff_file | grep -Po "\-\K([0-9.]*)(?=.tar.gz)")

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
echo "CMSMS admin_dir config:  $admin_dir_config"
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
			exit 3
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
echo "Editing admin_dir config if needed..."
if $hasCustomAdminDir; then
	echo " CMSMS admin_dir had custom setting"
	echo " Replacing"
	echo "  \$config['admin_dir'] = '$admin_dir_config';"
	echo "  with"
	echo "  \$config['admin_dir'] = '$admin_dir_default';"
	oldConfigLine="\$config\['admin_dir'\] = '$admin_dir_config';"
	newConfigLine="\$config\['admin_dir'\] = '$admin_dir_default';"
	sed -i "s/$oldConfigLine/$newConfigLine/" $configFile
	echo " Done!"
else
	echo " No custom admin_dir setting."
	echo " Skipping."
fi

# 5. Move the admin dir to default location
echo "Rename admin_dir to default setting for the update if needed..."
if $hasCustomAdminDir; then
	echo " CMSMS admin_dir had custom setting"
	echo " Renaming admin_dir to the default for the update..."
	echo " Renaming"
	echo "  $CMSMSDir/$admin_dir_config"
	echo "  to"
	echo "  $CMSMSDir/$admin_dir_default"
	mv $CMSMSDir/$admin_dir_config $CMSMSDir/$admin_dir_default
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
if $hasCustomAdminDir; then
	echo " CMSMS admin_dir had custom setting"
	echo " Renaming admin_dir back to custom setting..."
	echo " Renaming"
	echo "  $CMSMSDir/$admin_dir_default"
	echo "  to"
	echo "  $CMSMSDir/$admin_dir_config"
	mv $CMSMSDir/$admin_dir_default $CMSMSDir/$admin_dir_config
	echo " Done!"
else
	echo " CMSMS admin_dir had default setting"
	echo " Skipping admin_dir rename"
fi

# 8. Edit config file admin dir setting to custom location
echo "Editing admin_dir config if needed..."
if $hasCustomAdminDir; then
	echo " CMSMS admin_dir had custom setting"
	echo " Replacing"
	echo "  \$config['admin_dir'] = '$admin_dir_default';"
	echo "  with"
	echo "  \$config['admin_dir'] = '$admin_dir_config';"
	oldConfigLine="\$config\['admin_dir'\] = '$admin_dir_default';"
	newConfigLine="\$config\['admin_dir'\] = '$admin_dir_config';"
	sed -i "s/$oldConfigLine/$newConfigLine/" $configFile
	echo " Done!"
else
	echo " No custom admin_dir setting."
	echo " Skipping."
fi

# 9. Restore original permissions on config file
echo "Restoring config file permissions..."
echo " Changing config file permission to $configFilePerm"
chmod $configFilePerm $configFile
echo " Done!"

# Everything should be done!
admin_dir_config_check=$(grep -Po "($config\['admin_dir'\] = ')\K(.*)(?=')" $configFile)
cmsms_version_current_check=$(grep -Po 'CMS_VERSION = "\K([0-9.]+)(?=")' $versionFile)
echo
echo "CMSMS admin_dir config:  $admin_dir_config_check"
echo "Updated CMSMS Version:   $cmsms_version_current_check"
echo

# Check that the diff update version and the new current version match
if [ $cmsms_version_new == $cmsms_version_current_check ]; then
	echo "The update should be complete!"
	echo
else
	echo "There may have been a problem.  Please double check your install."
	echo
	exit 2
fi

# 10. Optional: Verify checksums
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
			echo
			break
			;;
		* ) echo "Please answer yes (Y/y) or no (N/n).";;
	esac
done

if $verify_checksums; then
	# It's unlikely that there would be multiple checksum files unless
	# the user uploaded more than one copy.  We'll check anyway to be
	# safe.
	checksum_file_glob="cms*-$cmsms_version_new-*checksum.dat"
	checksum_file_count=$(ls $checksum_file_glob | wc -l)
	if [ $checksum_file_count -gt 1 ]; then
		# multiple checksum files present
		echo "There are too many checksum files.  Please choose one."
		checksum_file=$(selectFile "$checksum_file_glob")
		continue_checksum=true
	elif [ $checksum_file_count -eq 0 ]; then
		# no valid checksum files present
		echo "There doesn't seem to be a valid checksum file."
		#echo "Please add a checksum file to this directory and rerun this script."
		echo "Skipping the checksum verification."
		continue_checksum=false
	else
		checksum_file=$(ls $checksum_file_glob)
		continue_checksum=true
	fi

	if $continue_checksum; then
		echo "Verifying file checksums..."
		echo " Checksum file:  $checksum_file"
		echo " Showing only failed checksums"
		echo

		# make a temp copy of the checksum file
		checksum_file_temp="cmsms-checksum-temp-${datestamp}.dat"
		cp -p "$checksum_file" "$checksum_file_temp"
		# edit checksum file to accommodate admin_dir_config if needed
		if $hasCustomAdminDir; then
			sed -i "s#\./$admin_dir_default/#\./$admin_dir_config/#g" $checksum_file_temp
		fi

		# if updating using a diff, remove checksums for ./install directory
		# this might not be needed after all since ./install shouldn't be
		#  present before/after a diff
		# might keep it to give user an option to keep temp checksum file
		#  for use with built-in checksum verification to avoid lots of
		#  errors about custom admin_dir and missing ./install files
		if $updateWithDiff; then
			sed -i -r "s#.+ \*\./install/.+##g" $checksum_file_temp
			sed -i -e /^$/d $checksum_file_temp
		fi

		script_dir="$PWD"
		#echo $script_dir
		cd $CMSMSDir
		#echo $PWD

		# Verify file checksums
		md5sum --check --quiet $script_dir/$checksum_file_temp

		# edit checksum file to restore original admin_dir setting if needed
		cd $script_dir
		if $hasCustomAdminDir; then
			sed -i "s#\./$admin_dir_config/#\./$admin_dir_default/#g" $checksum_file_temp
		fi

		# remove temp checksum file if we want
		rm "$checksum_file_temp"
	fi
fi

echo "
The update script is complete!
You should now run any necessary additional steps recommended by the
CMSMS Dev Team. You may also wish to run CMSMS' built-in checksum
verification process."
echo
echo
