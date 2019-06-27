# This is harder than it looks
##########################################################################################
#
# Magisk Module Installer Script
#
##########################################################################################
##########################################################################################
#
# Instructions:
#
# 1. Place your files into system folder (delete the placeholder file)
# 2. Fill in your module's info into module.prop
# 3. Configure and implement callbacks in this file
# 4. If you need boot scripts, add them into common/post-fs-data.sh or common/service.sh
# 5. Add your additional or modified system properties into common/system.prop
#
##########################################################################################

##########################################################################################
# Config Flags
##########################################################################################

# Set to true if you do *NOT* want Magisk to mount
# any files for you. Most modules would NOT want
# to set this flag to true
SKIPMOUNT=false

# Set to true if you need to load system.prop
PROPFILE=false

# Set to true if you need post-fs-data script
POSTFSDATA=false

# Set to true if you need late_start service script
LATESTARTSERVICE=true 

##########################################################################################
# Replace list
##########################################################################################

# List all directories you want to directly replace in the system
# Check the documentations for more info why you would need this

# Construct your list in the following format
# This is an example
#REPLACE_EXAMPLE="
#/system/app/webview
#/system/priv-app/SystemUI
#/system/priv-app/Settings
#/system/framework
#"

# You won't believe how many names Google's webview goes by
REPLACE="
/system/app/Chrome
/system/app/webview
"

##########################################################################################
#
# Function Callbacks
#
# The following functions will be called by the installation framework.
# You do not have the ability to modify update-binary, the only way you can customize
# installation is through implementing these functions.
#
# When running your callbacks, the installation framework will make sure the Magisk
# internal busybox path is *PREPENDED* to PATH, so all common commands shall exist.
# Also, it will make sure /data, /system, and /vendor is properly mounted.
#
##########################################################################################
##########################################################################################
#
# The installation framework will export some variables and functions.
# You should use these variables and functions for installation.
#
# ! DO NOT use any Magisk internal paths as those are NOT public API.
# ! DO NOT use other functions in util_functions.sh as they are NOT public API.
# ! Non public APIs are not guranteed to maintain compatibility between releases.
#
# Available variables:
#
# MAGISK_VER (string): the version string of current installed Magisk
# MAGISK_VER_CODE (int): the version code of current installed Magisk
# BOOTMODE (bool): true if the module is currently installing in Magisk Manager
# MODPATH (path): the path where your module files should be installed
# TMPDIR (path): a place where you can temporarily store files
# ZIPFILE (path): your module's installation zip
# ARCH (string): the architecture of the device. Value is either arm, arm64, x86, or x64
# IS64BIT (bool): true if $ARCH is either arm64 or x64
# API (int): the API level (Android version) of the device
#
# Availible functions:
#
# ui_print <msg>
#     print <msg> to console
#     Avoid using 'echo' as it will not display in custom recovery's console
#
# abort <msg>
#     print error message <msg> to console and terminate installation
#     Avoid using 'exit' as it will skip the termination cleanup steps
#
# set_perm <target> <owner> <group> <permission> [context]
#     if [context] is empty, it will default to "u:object_r:system_file:s0"
#     this function is a shorthand for the following commands
#       chown owner.group target
#       chmod permission target
#       chcon context target
#
# set_perm_recursive <directory> <owner> <group> <dirpermission> <filepermission> [context]
#     if [context] is empty, it will default to "u:object_r:system_file:s0"
#     for all files in <directory>, it will call:
#       set_perm file owner group filepermission context
#     for all directories in <directory> (including itself), it will call:
#       set_perm dir owner group dirpermission context
#
##########################################################################################
##########################################################################################
# If you need boot scripts, DO NOT use general boot scripts (post-fs-data.d/service.d)
# ONLY use module scripts as it respects the module status (remove/disable) and is
# guaranteed to maintain the same behavior in future Magisk releases.
# Enable boot scripts by setting the flags in the config section above.
##########################################################################################

# Set what you want to display when installing your module

print_modname() {
  ui_print "*******************************"
  ui_print "  Bromite Systemless Webview  "
  ui_print "*******************************"
  ui_print "ONLY FLASH VIA MANAGER, NEVER TWRP OR IT WILL FAIL"
}

# Copy/extract your module files into $MODPATH in on_instaLL
on_install() {
  # Download, Unzip and copy corresponding libs/apk
  ui_print "- Extracting module files"
#  unzip -o "$ZIPFILE" "curl/*" -d $TMPDIR
  chmod +x $TMPDIR/curl-$ARCH32
  unzip -o "$ZIPFILE" "system/*" -d $MODPATH >&2
  # This for some reason breaks the script if removed
  ui_print "- $ARCH SDK $API system detected, selecting the appropriate files"
  ui_print "- Downloading extra files please be patient..."
  if [ "$ARCH" = "arm64" ]
    then $TMPDIR/curl-$ARCH32 -k -o $TMPDIR/webview.apk https://raw.githubusercontent.com/alexa-v2/bromite-systemless-files/master/arm64-v8a/webview.apk
  elif [ "$ARCH" = "arm" ]
    then $TMPDIR/curl-$ARCH32 -k -o $TMPDIR/webview.apk https://raw.githubusercontent.com/alexa-v2/bromite-systemless-files/master/armeabi-v7a/webview.apk
  elif [ "$ARCH" = "x86" ] || [ "$ARCH" = "x64" ]
    then $TMPDIR/curl-$ARCH32 -k -o $TMPDIR/webview.apk https://raw.githubusercontent.com/alexa-v2/bromite-systemless-files/master/x86_64/webview.apk
  fi
  
  #  ui_print "- Extracting downloaded files..."
  test -d $MODPATH/system/app/webview || mkdir -p $MODPATH/system/app/webview && cp -rf $TMPDIR/webview.apk $MODPATH/system/app/webview
#  cp -af "$TMPDIR/webview.apk" $MODPATH/system/app/webview
# Only for debugging 
#  ls -a $MODDIR/system/app/webview
#  ui_print "$MODPATH $TMPDIR $ARCH"
#  ls $TMPDIR
#  ui_print $ARCH
  remove_old
}

# Only some special files require specific permissions
# This function will be called after on_install is done
# The default permissions should be good enough for most cases

set_permissions() {
  # The following is the default rule, DO NOT remove
  set_perm_recursive $MODPATH 0 0 0755 0644

  # Here are some examples:
  # set_perm_recursive  $MODPATH/system/lib       0     0       0755      0644
  # set_perm  $MODPATH/system/bin/app_process32   0     2000    0755      u:object_r:zygote_exec:s0
  # set_perm  $MODPATH/system/bin/dex2oat         0     2000    0755      u:object_r:dex2oat_exec:s0
  # set_perm  $MODPATH/system/lib/libart.so       0     0       0644
}

# You can add more functions to assist your custom script code
remove_old() {
	ui_print "- Removing old webview traces and clearing cache..."
	ui_print "!!!!!!!!!!!!!!! VERY IMPORTANT !!!!!!!!!!!!!!!!!"
	ui_print "Reboot immediately after flashing or you may experience some issues! "
	ui_print "!!!!!!!!!!!!!!! VERY IMPORTANT !!!!!!!!!!!!!!!!!"
	ui_print" Also, if you had any other webview such as Google webview, it'll need reinstalled"
  rm -rf /data/resource-cache/*
  rm -rf /data/dalvik-cache/*
  rm -rf /cache/dalvik-cache/*
  rm -rf /data/*/*webview*
  rm -rf /data/system/package_cache/*
  rm -rf /data/system/packages.list
  rm -rf /data/resource-cache/*
}
