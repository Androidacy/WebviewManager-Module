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
FINDLOG=$MODDIR/logs/find.log
VERBOSELOG=$MODDIR/logs/service-verbose.log
touch "$VERBOSELOG"
echo "Started at $(date)"
if test -f "$MODDIR"/apk/webview.apk ;
then
	sleep 20
	pm install -r -g "$MODDIR"/apk/webview.apk 2>&3
	rm -rf "$MODDIR"/apk/webview.apk
	echo "Installed bromite webview as user app.."
	if pm list packages -a|grep -q com.google.android.webview 2>&3;
	then
		pm disable com.google.android.webview 2>&3;
	fi
	if pm list packages -a|grep -q com.android.chrome 2>&3;
	then
		pm disable com.android.chrome 2>&3;
	fi
	echo "Disabled chrome and google webview. You may re-enable but please be aware that may cause issues";
else
echo "File either moved or doesn't need installed...."
fi
while test ! "$(getprop sys.boot_completed)" = "1"  && test -d /sdcard/Android ;
do sleep 0.5;
done
{ echo "SDCARD DIR contains:"; find /sdcard/bromite; echo "Module DIR contains:"; find "$MODDIR"; } > "$FINDLOG"
tail -n +1 "$MODDIR"/logs/find.log cat "$MODDIR"/logs/props.log "$MODDIR"/logs/postfsdata-verbose.log "$MODDIR"/logs/service-verbose.log "$MODDIR"/logs/aapt.log > "$MODDIR"/logs/verbose.log 
cp -rf "$MODDIR"/logs /sdcard/bromite/logs