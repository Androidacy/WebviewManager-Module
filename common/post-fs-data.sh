#!/system/bin/sh
# Do NOT assume where your module will be located.
# ALWAYS use $MODDIR if you need to know where this script
# and module is placed.
# This will make sure your module will still work
# if Magisk change its mount point in the future
MODDIR=${0%/*}
if echo $ARCH | grep -q $arch; then
      pm install $MODDIR/system/app/webview.apk
      break
# This script will be executed in post-fs-data mode
