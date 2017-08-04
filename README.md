# cmsms-update-script
A Bash script for helping perform CMS Made Simple updates.


## Details
This script helps automate the *diff* update process for [CMS Made Simple](https://www.cmsmadesimple.org/).  It does not currently help automate *non-diff* upgrades because those typically require upgrade steps for the site's database, but it could probably be adapted to handle full non-diff upgrades (minus the database portion).


## Background
I still had a few sites running CMSMS 1.x, so I was going over my checklist of steps to take to perform 1.x updates before upgrading to 2.x. I figured I could just make a quick Bash script to do a couple of quick things:
1. Enable owner write permission on config file
2. Move the custom admin dir to default location
3. Unpack diff
4. Move the admin dir to custom location
5. Restore original permissions on config file

Simple enough. I wrote the script and then decided I wanted to automate more stuff. After a lot of tinkering, my checklist of tasks to automate quickly grew to this:
1. Get site directory
2. Backup config file
3. Enable owner write permission on config file
4. Edit config file admin dir setting to default location
5. Move the custom admin dir to default location
6. Unpack diff
7. Move the admin dir to custom location
8. Edit config file admin dir setting to custom location
9. Restore original permissions on config file
10. Optional: Verify checksums

After a while, I decided to make it available to the community in case that it might help people who are apprehensive about the update process (extracting a zip/tar from shell, dealing with custom admin directories, etc.). My hope is that this might help people through the update process and get more people to move to 2.x.  So, here we are.

The script is licensed under GPLv3. Anyone is welcome to submit issues, feature requests, or pull requests via GitHub. The script certainly needs some cleanup, and I'm sure it needs improvements. As with any update process, ***you should back up your site before running this script***.

I do have a couple of additional features I'd considered adding, such as:
1. Offer an optional site directory backup
2. Offer an optional automatic database backup using config.php values
3. Attempt automatic download of diff/update file if one is not detected locally
4. Attempt automatic download of checksum file if one is not detected locally
5. Try to detect where the user is on the [Upgrade Path](https://docs.cmsmadesimple.org/upgrading/old-versions)

Before I add those though, I wanted to try to get through some more testing.

If this script helps even one other person, then I'm happy with that. If it doesn't help anyone other than myself, well then at least I had fun writing it.


## Usage Instructions
You can download a zip file containing the [0.8 release here](https://github.com/RytoEX/cmsms-update-script/archive/0.8.zip) or the [master release here](https://github.com/RytoEX/cmsms-update-script/archive/master.zip). Then, upload it to your web server and unzip it, or unzip it on your computer and upload only the CMSMSUpdateDiff.sh file to your server. Upload your desired CMSMS 1.x diff file to the same directory as this script. Optionally, you can also upload the checksum file for the CMSMS version to which you are updating. Open a terminal for your server, and run the script with:
```
./CMSMSUpdateDiff.sh
```

The script will try to walk you through confirming the CMSMS 1.x diff update steps. The script will then execute the diff update steps after a user confirmation.
