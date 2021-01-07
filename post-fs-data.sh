#!/sbin/.magisk/busybox/ash
# shellcheck shell=dash
MODDIR=${0%/*}
exxit() {
	  set +euxo pipefail
	    [ "$1" -ne 0 ] && abort "$2"
	      exit "$1"
      }
mkdir -p "$MODDIR"/logs
exec 2>"$MODDIR"/logs/postfsdata-verbose.log
set -x
set -euo pipefail
trap 'exxit $?' EXIT
FINDLOG="$MODDIR"/logs/find.log
PROPSLOG="$MODDIR"/logs/props.log
touch "$FINDLOG"
OL="com.linuxandria.WebviewOverlay"
LIST="/data/system/overlays.xml"
DR="$(cat "$MODDIR"/overlay)"
API="$(getprop ro.build.version.sdk)"
echo "Clearing caches..."
rm -rf /data/resource-cache/* /data/dalvik-cache/* /cache/dalvik-cache/* /data/*/com*webview* /data/system/package_cache/*
sed -i "/com*webview/d" /data/system/packages.list
sed -i "/com*webview/d" /data/system/packages.xml
touch "$PROPSLOG"
echo "Firing up logging NOW "
echo "---------- Device info: -----------" > "$PROPSLOG"
getprop >> "$PROPSLOG"
echo "------- End Device info ----------" >> "$PROPSLOG"
if test "$API" -lt "27" ;
then
	STATE="3" ;
else
	STATE="6" ;
fi
if grep 'com.linuxandria.android.webviewoverlay' /data/system/overlays.xml ;
then
	sed -i s|"com.linuxandria.android.webviewoverlay|com.linuxandria.WebviewOverlay|g"
	echo "Overlay needs updated, done"
fi
if ! grep 'com.linuxandria.WebviewOverlay' /data/system/overlays.xml ;
then
	echo "Forcing the system to register our overlay..."
	sed -i "s|</overlays>|    <item packageName=\"${OL}\" userId=\"0\" targetPackageName=\"android\" baseCodePath=\"${DR}/WebviewOverlay.apk\" state=\"${STATE}\" isEnabled=\"true\" isStatic=\"true\" priority=\"998\" /></overlays>|" $LIST
fi