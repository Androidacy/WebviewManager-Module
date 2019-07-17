# This is harder than it looks
######################################################################
# BROMITE WEBVIEW SYSTEMLESS INSTALLER
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
}

# Copy/extract your module files into $MODPATH in on_instaLL
on_install() {
	$BOOTMODE || abort "! This is for magisk manager only becauseit needs an internetconnection!"
  # Download corresponding libs/apk
  ui_print "- Extracting module files"
  chmod +x $TMPDIR/curl-$ARCH
  unzip -o "$ZIPFILE" "system/*" -d $MODPATH >&2
  # This for some reason breaks the script if removed
  ui_print "- $ARCH SDK $API system detected, selecting the appropriate files"
  ui_print "- Downloading extra files please be patient..."

  BROMITE_VERSION=75.0.3770.139
  URL=https://github.com/bromite/bromite/releases/download/$BROMITE_VERSION/${ARCH}_SystemWebView.apk

  if [ "$ARCH" = "arm64" ]
    then $TMPDIR/curl-$ARCH -k -L -o $TMPDIR/webview.apk $URL
  elif [ "$ARCH" = "arm" ]
    then $TMPDIR/curl-$ARCH -k -L -o $TMPDIR/webview.apk $URL
  elif [ "$ARCH" = "x86" ] || [ "$ARCH" = "x64" ]
    then $TMPDIR/curl-$ARCH -k -L -o $TMPDIR/webview.apk $URL
  fi
  #  ui_print "- Extracting downloaded files..."
  test -d $MODPATH/system/app/webview || mkdir -p $MODPATH/system/app/webview && cp -rf $TMPDIR/webview.apk $MODPATH/system/app/webview
  remove_old
  replace_webview
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
	ui_print "!!!!!!!!!!!!!!! VERY IMPORTANT PLEASE READ!!!!!!!!!!!!!!!!!"
	ui_print "Reboot immediately after flashing or you may experience some issues! "
	ui_print "!!!!!!!!!!!!!!! VERY IMPORTANT PLEASE READ!!!!!!!!!!!!!!!!!"
	ui_print "Also, if you had any other webview such as Google webview, it'll need reinstalled"
	ui_print "Chrome will be a preferred webview if installed, so you should disable it"
	ui_print "Next boot may take significantly longer, we have to clear Dalvik cache here"
    rm -rf /data/resource-cache/*
    rm -rf /data/dalvik-cache/*
    rm -rf /cache/dalvik-cache/*
    rm -rf /data/*/com.android.webview*
    rm -rf /data/system/package_cache/*
# For now, this next line is going to be removed until I can figure out how to make it less aggressive
#  rm -rf /data/*/*chrome*
}
replace_webview() {
	if [ "$(ls -d /system/product/app/Chrome 2>/dev/null)" ]
    then mkdir -p $MODPATH/system/product/app/Chrome && touch /system/product/app/Chrome/.replace
    fi
    if [ "$(ls -d /system/app/Chrome 2>/dev/null)" ]
    then mkdir -p $MODPATH/system/app/Chrome && touch /system/app/Chrome/.replace
    fi
	if [ "$(ls -d /system/product/app/chrome 2>/dev/null)" ]
    then mkdir -p $MODPATH/system/product/app/chrome && touch /system/product/app/chrome/.replace
    fi
    if [ "$(ls -d /system/app/chrome 2>/dev/null)" ]
    then mkdir -p $MODPATH/system/app/chrome && touch /system/app/chrome/.replace
    fi
}
