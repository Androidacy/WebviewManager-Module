#!/system/bin/sh
# If you are reading this you owe me $10 => https://paypal.me/linuxandria
# Set various vars
OL="com.linuxandria.WebviewOverlay"
LIST="/data/system/overlays.xml"
# Forces Android to rebuild package cache and re-register old webview
rm -rf /data/resource-cache/*
rm -rf /data/dalvik-cache/*
rm -rf /cache/dalvik-cache/*
rm -rf /data/*/com.android.webview*
rm -rf /data/system/package_cache/*
# Nuke old overlay, should prevent some bootloops
sed -i "/item packageName=\"${OL}\"/d" $LIST
# Instead we will restore our backup in the future. Sorry substratum users in the future
sleep 15
reboot

