# If you are reading this you owe me $10 => https://paypal.me/innonetlife
# Set various vars
OL="me.phh.treble.overlay.webview"
LIST="/data/system/overlays.xml"
DR="$(find /system /system/product /vendor -maxdepth 1 | grep overlay)"
# Forces Android to rebuild package cache and re-registered old webview
rm -rf /data/resource-cache/*
rm -rf /data/dalvik-cache/*
rm -rf /cache/dalvik-cache/*
rm -rf /data/*/com.android.webview*
rm -rf /data/system/package_cache/*
# Nuke old overlay, should prevent some bootloops
sed -i 's|<item packageName="$OL" userId="0" targetPackageName="android" baseCodePath="$DR/treble-overlay-webview.apk" state="6" isEnabled="true" isStatic="true" priority="98" />\n</overlays>|</overlays>|' $LIST
# Reinstall old webview
# for i in /system/product/app /system/app; 
# do
#	pm install - r $i/.eb.iew*/.eb.ie*.apk
# 
