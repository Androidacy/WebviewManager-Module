#!/data/adb/magisk/busybox ash
# shellcheck shell=dash
# shellcheck disable=SC2034
ASH_STANDALONE=1
SH=$(readlink -f "$0")
MODDIR=$(dirname "$SH")
it_failed() {
	mv "${EXT_DATA}"/logs "${TMPDIR}"
	rm -rf "${EXT_DATA:?}"/*
	mv "${TMPDIR}"/logs "${EXT_DATA}"/
	exit 1
}
INSTALL=false
# shellcheck disable=SC1090,SC1091
. "${MODDIR}"/status.txt
FINDLOG=$MODDIR/logs/find.log
VERBOSELOG=$MODDIR/logs/service.log
touch "$VERBOSELOG"
{
	echo "Module: WebviewManager v10"
	echo "Device: $BRAND $MODEL ($DEVICE)"
	echo "ROM: $ROM, sdk$API"
} >"$VERBOSELOG"
set -x >>"$VERBOSELOG"
echo "Started at $(date)"
while test ! -d /storage/emulated/0/Android; do
	sleep 1
done
detect_ext_data() {
	if touch /sdcard/.rw && rm /sdcard/.rw; then
		export EXT_DATA="/sdcard/WebviewManager"
	elif touch /storage/emulated/0/.rw && rm /storage/emulated/0/.rw; then
		export EXT_DATA="/storage/emulated/0/WebviewManager"
	elif touch /data/media/0/.rw && rm /data/media/0/.rw; then
		export EXT_DATA="/data/media/0/WebviewManager"
	else
		EXT_DATA='/storage/emulated/0/WebviewManager'
	fi
}
detect_ext_data
if ! $INSTALL; then
	if find "${MODDIR}" | grep -i 'webview[.]apk'; then
		pm install -r -g "$(find "${MODDIR}" | grep -i 'webview[.]apk')" 2>&3
	fi
	if find "${MODDIR}" | grep -i 'browser[.]apk'; then
		pm install -r -g "$(find "${MODDIR}" | grep -i 'browser[.]apk')" 2>&3
	fi
	echo "Installed webview as user app.."
	if pm list packages -a | grep -q com.android.chrome 2>&3; then
		pm uninstall com.android.chrome 2>&3
	fi
	if pm list packages -a | grep -q com.google.android.webview 2>&3; then
		pm uninstall com.android.chrome 2>&3
	fi
	echo "Disabled chrome and google webview. You may re-enable but please be aware that may cause issues"
	sed -i "/INSTALL/d" "${MODDIR}"/status.txt
	echo "INSTALL=true" >>"${MODDIR}"/status.txt
else
	echo "Skipping install, as the needed files are not present. This is most likely because they've already been installed"
fi
touch "$FINDLOG"
{
	echo -n "SDCARD DIR contains:"
	find "$EXT_DATA"
	echo -n "Module DIR contains:"
	find "$MODDIR"
} >"$FINDLOG"
tail -n +1 "$EXT_DATA"/logs/install.log "$MODDIR"/logs/aapt.log "$MODDIR"/logs/find.log "$MODDIR"/logs/postfsdata.log "$MODDIR"/logs/service.log >"$MODDIR"/logs/full-"$(date +%F-%T)".log
cp -rf "$MODDIR"/logs/full-"$(date +%F-%T)".log "$EXT_DATA"/logs
find "$EXT_DATA"/logs -mtime +3 -exec rm -f {} \;