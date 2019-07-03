#!/system/bin/sh
MODDIR=${0%/*}
# wait until boot completed
until [ `getprop sys.boot_completed`. = 1. ]; do sleep 1; done
# Bromite WebView needs to be installed as user app to prevent crashes
pm install -r $MODDIR/system/app/*/*.apk