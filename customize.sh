##########################################################################################
#
# Unity Config Script
# by topjohnwu, modified by Zackptg5
#
##########################################################################################

##########################################################################################
# Unity Logic - Don't modify this
##########################################################################################

if [ -z $UF ]; then
  MAGISK=true; UF=$TMPDIR/META-INF/unity
  unzip -oq "$ZIPFILE" 'META-INF/unity/*' -d $TMPDIR >&2
  [ -f "$UF/util_functions.sh" ] || { ui_print "! Unable to extract zip file !"; exit 1; }
  . $UF/util_functions.sh
fi

##########################################################################################
# Config Flags
##########################################################################################

# Uncomment and change 'MINAPI' and 'MAXAPI' to the minimum and maximum android version for your mod
# Uncomment DYNLIB if you want libs installed to vendor for oreo+ and system for anything older
<<<<<<< HEAD:install.sh
# Uncomment SYSOVER if you want the mod to always be installed to system (even on magisk) - note that this can still be set to true by the user by adding 'sysover' to the zipname
# Uncomment DIRSEPOL if you want sepolicy patches applied to the boot img directly (not recommended) - THIS REQUIRES THE RAMDISK PATCHER ADDON (this addon requires minimum api of 17)
=======
>>>>>>> 5aeb810f1e70822d9fd27479f755a1d5dca5d600:customize.sh
# Uncomment DEBUG if you want full debug logs (saved to /sdcard in magisk manager and the zip directory in twrp) - note that this can still be set to true by the user by adding 'debug' to the zipname
MINAPI=17
#MAXAPI=25
#DYNLIB=true
<<<<<<< HEAD:install.sh
#SYSOVER=true
#DIRSEPOL=true
DEBUG=true
=======
#DEBUG=true
>>>>>>> 5aeb810f1e70822d9fd27479f755a1d5dca5d600:customize.sh

##########################################################################################
# Replace list
##########################################################################################

# List all directories you want to directly replace in the system
# Check the documentations for more info why you would need this

# Construct your list in the following format
# This is an example
REPLACE_EXAMPLE="
/system/app/Youtube
/system/priv-app/SystemUI
/system/priv-app/Settings
/system/framework
"

# Construct your own list here
REPLACE="
/system/app/webview"

##########################################################################################
# Custom Logic
##########################################################################################

set_permissions() {
  # Remove this if adding to this function
  set_perm_recursive $MODPATH 0 0 0755 0644

  # Note that all files/folders have the $UNITY prefix - keep this prefix on all of your files/folders
  # Also note the lack of '/' between variables - preceding slashes are already included in the variables
  # Use $VEN for vendor (Do not use /system$VEN, the $VEN is set to proper vendor path already - could be /vendor, /system/vendor, etc.)

  # Some examples:
  
  # For directories (includes files in them):
  # set_perm_recursive  <dirname>                <owner> <group> <dirpermission> <filepermission> <contexts> (default: u:object_r:system_file:s0)
  
  # set_perm_recursive $UNITY/system/lib 0 0 0755 0644
  # set_perm_recursive $UNITY$VEN/lib/soundfx 0 0 0755 0644

  # For files (not in directories taken care of above)
  # set_perm  <filename>                         <owner> <group> <permission> <contexts> (default: u:object_r:system_file:s0)
  
  # set_perm $UNITY/system/lib/libart.so 0 0 0644
}

# Custom Variables for Install AND Uninstall - Keep everything within this function - runs before uninstall/install
unity_custom() {
  : # Remove this if adding to this function
}

# Custom Functions for Install AND Uninstall - You can put them here

<<<<<<< HEAD:install.sh
ui_print "$ZIPFILE $MODPATH $TMPDIR"
=======
##########################################################################################
# Unity Logic - Don't touch anything after this
##########################################################################################

unity_main
>>>>>>> 5aeb810f1e70822d9fd27479f755a1d5dca5d600:customize.sh
