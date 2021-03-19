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
# shellcheck disable=SC1090
. "${MODDIR}"/status.txt
if $? -ne 0; then
	rm "${MODDIR}"/status.txt
	touch "${MODDIR}"/status.txt
fi
if test "$OVERLAY" != 'true'; then
	OVERLAY=false
fi
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
echo "---------- Device info: -----------" >"$PROPSLOG"
getprop >>"$PROPSLOG"
echo "------- End Device info ----------" >>"$PROPSLOG"
if test "$API" -lt "27"; then
	STATE="3"
else
	STATE="6"
fi
if grep 'com.linuxandria.android.webviewoverlay' /data/system/overlays.xml; then
	sed -i "s|com.linuxandria.android.webviewoverlay|com.linuxandria.WebviewOverlay|g"
	echo "Overlay needs updated, done"
fi
if ! $OVERLAY; then
	echo "Forcing the system to register our overlay..."
	sed -i "/item packageName=\"${OL}\"/d" /data/system/overlays.xml
	sed -i "s|</overlays>|    <item packageName=\"${OL}\" userId=\"0\" targetPackageName=\"android\" baseCodePath=\"${DR}/WebviewOverlay.apk\" state=\"${STATE}\" isEnabled=\"true\" isStatic=\"true\" priority=\"1\" /></overlays>|" $LIST
	sed -i "/OVERLAY/d" "${MODDIR}"/status.txt
	echo "OVERLAY=true" >>"${MODDIR}"/status.txt
fi
