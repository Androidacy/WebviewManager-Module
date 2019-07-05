#!/system/bin/sh
# Do NOT assume where your module will be located.
# ALWAYS use $MODDIR if you need to know where this script
# and module is placed.
# This will make sure your module will still work
# if Magisk change its mount point in the future
MODDIR=${0%/*}	
# This script will be executed in late_start service mode
# wait until boot completed
until [ `getprop sys.boot_completed`. = 1. ]; do sleep 1; done
# Bromite WebView needs to be installed as user app to prevent crashes
if [ ! "$(ls -d /data/app/com.android.webview-* 2>/dev/null)" ]
then pm install -r $MODDIR/system/app/*/*.apk
fi
