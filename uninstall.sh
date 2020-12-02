#!/system/bin/sh
# If you are reading this you owe me $10 => https://paypal.me/innonetlife
# Set various vars
OL="com.linuxandria.WebviewOverlay"
LIST="/data/system/overlays.xml"
DR="$(find /system /system/product /vendor -maxdepth 1 | grep overlay)"
# Forces Android to rebuild package cache and re-register old webview
rm -rf /data/resource-cache/*
rm -rf /data/dalvik-cache/*
rm -rf /cache/dalvik-cache/*
rm -rf /data/*/com.android.webview*
rm -rf /data/system/package_cache/*
# Nuke old overlay, should prevent some bootloops
API="$(getprop ro.build.version.sdk)"
if test "$API" -lt "27" ;
then
	STATE="3" ;
else
	STATE="6" ;
fi
sed -i "s|    <item packageName=\"${OL}\" userId=\"0\" targetPackageName=\"android\" baseCodePath=\"${DR}/WebviewOverlay.apk\" state=\"${STATE}\" isEnabled=\"true\" isStatic=\"true\" priority=\"98\" />||" $LIST
# Instead we will restore our backup in the future. Sorry substratum users in the future
sleep 1
reboot

