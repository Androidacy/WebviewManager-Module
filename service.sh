#!/data/adb/magisk/busybox ash
# shellcheck shell=dash
# shellcheck disable=SC2034
ASH_STANDALONE=1
SH=$(readlink -f "$0")
MODDIR=$(dirname "$SH")
exxit() {
	set +euxo pipefail
	[ "$1" -ne 0 ] && echo "$2"
	exit "$1"
}
exec 3>&2 2>"$MODDIR"/logs/service-verbose.log
set -x 2
set -euo pipefail
trap 'exxit $?' EXIT
it_failed() {
	ui_print " "
	ui_print "⚠⚠⚠⚠⚠⚠⚠⚠⚠⚠⚠⚠⚠⚠⚠⚠⚠⚠⚠⚠⚠⚠⚠⚠⚠⚠"
	ui_print " "
	ui_print " Uh-oh, the installer encountered an issue!"
	ui_print " It's probably one of these reasons:"
	ui_print "       1) Installer is corrupt"
	ui_print "       2) You didn't follow instructions"
	ui_print "       3) You have an unstable internet connection"
	ui_print "       4) Your ROM is broken"
	ui_print "       5) There's a *tiny* chance we screwed up"
	ui_print " Please fix any issues and retry."
	ui_print " If you feel this is a bug or need assistance, head to our telegram"
	mv "${EXT_DATA}"/logs "${TMPDIR}"
	rm -rf "${EXT_DATA:?}"/*
	mv "${TMPDIR}"/logs "${EXT_DATA}"/
	ui_print " "
	ui_print "⚠⚠⚠⚠⚠⚠⚠⚠⚠⚠⚠⚠⚠⚠⚠⚠⚠⚠⚠⚠⚠⚠⚠⚠⚠⚠"
	ui_print " "
	exit 1
}
INSTALL=false
# shellcheck disable=SC1090,SC1091
. "${MODDIR}"/status.txt
FINDLOG=$MODDIR/logs/find.log
VERBOSELOG=$MODDIR/logs/service-verbose.log
touch "$VERBOSELOG"
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
tail -n +1 "$EXT_DATA"/logs/install.log "$MODDIR"/logs/aapt.log "$MODDIR"/logs/find.log "$MODDIR"/logs/props.log "$MODDIR"/logs/postfsdata-verbose.log "$MODDIR"/logs/service-verbose.log >"$MODDIR"/logs/full-"$(date +%F-%T)".log
cp -rf "$MODDIR"/logs/full-"$(date +%F-%T)".log "$EXT_DATA"/logs
find "$EXT_DATA"/logs -mtime +5 -exec rm {} \;