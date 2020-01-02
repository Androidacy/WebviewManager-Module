# APK-Patcher Lite - Flashable Zip Template for Modifying System APKs On-Device

## Information
This is a modified version of APK-Patcher that will delete / inject files into System APK files instead of using a baksmali / apktool method.

The method used here is a similar method used in my ROMs to patch files, where instead of having to have like for example 4 SystemUI files, I only needed to keep the actual files that were changed. This method could also be used quite easily to apply OTA updates or addons on already pre-modified APK files.


## Usage
* Copy your pre-compiled resource files (including .dex files) to the patch folder, removing the .apk part of the filename (ie: SystemUI)

* Create a file in scripts with the same name (ie: SystemUI.sh) if you want to delete any existing files from the APK

* Make edits to envvar.sh, and also to extracmd.sh if needed

### Properties / Variables
* apklist="";

**apklist** is a string containing the list of APKs to be patched included in the patch zip, separated by spaces between the quotes. Each APK is automatically found recursively in /system, then copied to the working directory to be decompiled and acted on, then copied back to /system.

Modify config.sh to add your apklist

Multiple files can be patched, put a space between the filenames (ie: apklist="file1.apk file2.apk";)


### extracmd.sh
Modify the extracmd.sh to add any additional commands to be performed at the end of the patching process that aren't patch-related (/data file changes,


### scripts/$apkname.sh
* fileremove="";

$apkname is the name of the folder that you put your resources files in. Copy scripts_sample.sh and rename it to your APK (ie: SystemUI.sh)

Multiple files can be deleted, put a space between the paths (ie: fileremove="/res/drawable/file1.png /res/drawable/file1.png";)

## Credits:
* by djb77 @ xda-developers
* Based on [APK-Patcher](https://github.com/osm0sis/APK-Patcher) by osm0sis @ xda-developers
