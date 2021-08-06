#!/data/adb/magisk/busybox ash
# shellcheck shell=dash
# shellcheck disable=SC2034
ASH_STANDALONE=1
SH=$(readlink -f "$0")
MODDIR=$(dirname "$SH")
OVERLAY=false
# shellcheck disable=SC1090,SC1091
. "${MODDIR}"/status.txt
FINDLOG="$MODDIR"/logs/find.log
PROPSLOG="$MODDIR"/logs/postfsdata.log
touch "$FINDLOG"
OL="org.androidacy.WebviewOverlay"
LIST="/data/system/overlays.xml"
DR="$(cat "$MODDIR"/overlay.txt)"
API="$(getprop ro.build.version.sdk)"
touch "$PROPSLOG"
echo "Firing up logging NOW "
BRAND=$(getprop ro.product.brand)
MODEL=$(getprop ro.product.model)
DEVICE=$(getprop ro.product.device)
ROM=$(getprop ro.build.display.id)
API=$(grep_prop ro.build.version.sdk)
{
	echo "Module: WebviewManager v10"
	echo "Device: $BRAND $MODEL ($DEVICE)"
	echo "ROM: $ROM, sdk$API"
} >"$PROPSLOG"
set -x >>"$PROPSLOG"
if test "$API" -lt "27"; then
	STATE="3"
else
	STATE="6"
fi
if ! $OVERLAY; then
	echo "Clearing caches..."
	rm -rf /data/resource-cache/* /data/dalvik-cache/* /cache/dalvik-cache/* /data/*/com*android.webview* /data/*/*/com*android.webview* /data/system/package_cache/*
	sed -i "/com*webview/d" /data/system/packages.list
	sed -i "/com*webview/d" /data/system/packages.xml
	sed -i "/com.linuxandria.WebviewOverlay/d" "$LIST"
	sed -i "/com.linuxandria.android.webviewoverlay/d" "$LIST"
	echo "Forcing the system to register our overlay..."
	sed -i "/item packageName=\"${OL}\"/d" /data/system/overlays.xml
	sed -i "s|</overlays>|    <item packageName=\"${OL}\" userId=\"0\" targetPackageName=\"android\" baseCodePath=\"${DR}/WebviewOverlay.apk\" state=\"${STATE}\" isEnabled=\"true\" isStatic=\"true\" priority=\"9999\" /></overlays>|" $LIST
	sed -i "/OVERLAY/d" "${MODDIR}"/status.txt
	echo "OVERLAY=true" >>"${MODDIR}"/status.txt
fi
