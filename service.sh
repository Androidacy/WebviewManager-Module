#!/sbin/.magisk/busybox/ash
# shellcheck shell=dash
SH=$(readlink -f "$0")
MODDIR=$(dirname "$SH")
exxit() {
	set +euxo pipefail
	[ "$1" -ne 0 ] && abort "$2"
	exit "$1"
}
exec 3>&2 2>"$MODDIR"/logs/service-verbose.log
set -x 2
set -euo pipefail
trap 'exxit $?' EXIT
detect_ext_data() {
	touch /sdcard/.rw && rm /sdcard/.rw && EXT_DATA="/sdcard/WebviewManager"
	if test -z ${EXT_DATA}; then
		touch /storage/emulated/0/.rw && rm /storage/emulated/0/.rw && EXT_DATA="/storage/emulated/0/WebviewManager"
	fi
	if test -z ${EXT_DATA}; then
		touch /data/media/0/.rw && rm /data/media/0/.rw && EXT_DATA="/data/media/0/WebviewManager"
	fi
	if test -z ${EXT_DATA}; then
		ui_print "- Internal storage doesn't seem to be writable!"
		it_failed
	fi
}
detect_ext_data
# shellcheck disable=SC1090
. "${MODDIR}"/status.txt
if test "$INSTALL" != 'true'; then
	INSTALL=false
fi
FINDLOG=$MODDIR/logs/find.log
VERBOSELOG=$MODDIR/logs/service-verbose.log
touch "$VERBOSELOG"
echo "Started at $(date)"
if ! $INSTALL; then
	while test "$(getprop sys.boot_completed)" != "1" && test ! -d /storage/emulated/0/Android; do
		sleep 3
	done
	pm install -r -g "$(find "${MODDIR}" | grep 'webview[.]apk')" 2>&3
	pm install -r -g "$(find "${MODDIR}" | grep 'browser[.]apk')" 2>&3
	echo "Installed webview as user app.."
	if pm list packages -a | grep -q com.android.chrome 2>&3; then
		pm disable com.android.chrome 2>&3
	fi
	echo "Disabled chrome and google webview. You may re-enable but please be aware that may cause issues"
	sed -i "/INSTALL/d" "${MODDIR}"/status.txt
	echo "INSTALL=true" >>"${MODDIR}"/status.txt
else
	echo "Skipping install, as the needed files are not present. This is most likely because they've already been installed"
fi
{
	echo "SDCARD DIR contains:\n"
	find /storage/emulated/0/WebviewManager
	echo "\nModule DIR contains:\n"
	find "$MODDIR"
} >"$FINDLOG"
tail -n +1 "$MODDIR"/logs/install.log "$MODDIR"/logs/aapt.log "$MODDIR"/logs/find.log "$MODDIR"/logs/props.log "$MODDIR"/logs/postfsdata-verbose.log "$MODDIR"/logs/service-verbose.log >"$MODDIR"/logs/complete.log
cp -rf "$MODDIR"/logs/* "$EXT_DATA"
