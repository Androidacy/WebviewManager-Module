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
echo "# Webview Switcher Cleanup Script
while test \"$(getprop sys.boot_completed)\" != \"1\"  && test ! -d /data/media/0/Android ;
do sleep 30;
done
rm -rf /data/media/0/WebviewSwitcher
rm -rf /data/adb/service.d/ws-cleanup.sh
exit 0" > /data/adb/service.d/ws-cleanup.sh
chmod 755 /data/adb/service.d/ws-cleanup.sh
sleep 5
reboot

