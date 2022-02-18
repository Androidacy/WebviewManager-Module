#!/system/bin/sh
OL="org.androidacy.WebviewOverlay"
LIST="/data/system/overlays.xml"
rm -rf /data/resource-cache/*
rm -rf /data/dalvik-cache/*
rm -rf /cache/dalvik-cache/*
rm -rf /data/*/com.android.webview*
rm -rf /data/*/org.bromite.webview*
rm -rf /data/system/package_cache/*
sed -i "/item packageName=\"${OL}\"/d" $LIST
echo "# Webview Switcher Cleanup Script
while test \"$(getprop sys.boot_completed)\" != \"1\"  && test ! -d /storage/emulated/0/Android ;
do sleep 2;
done
rm -rf /storage/emulated/0/WebviewManager
rm -rf /data/adb/service.d/ws-cleanup.sh
exit 0" >/data/adb/service.d/ws-cleanup.sh
chmod 755 /data/adb/service.d/ws-cleanup.sh
sleep 1
reboot
