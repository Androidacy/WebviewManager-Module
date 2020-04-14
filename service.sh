#!/system/bin/sh
SH=$(readlink -f "$0")
MODDIR=$(dirname "$SH")
exxit() {
	  set +euxo pipefail
	    [ $1 -ne 0 ] && abort "$2"
	      exit $1
      }
exec 2>$MODDIR/logs/service-verbose.log
set -x 2
set -euo pipefail
trap 'exxit $?' EXIT
FINDLOG=$MODDIR/logs/find.log
VERBOSELOG=$MODDIR/logs/service-verbose.log
touch $VERBOSELOG
touch $FINDLOG
echo "Started at $(date)"
if [ -f $MODDIR/apk/webview.apk ] ;
then
	sleep 30
	pm install -r $MODDIR/apk/webview.apk
	rm -rf $MODDIR/apk/webview.apk
	echo "Installed bromite webview as user app.."
	if pm list packages -a|grep -q com.google.android.webview;
	then
		pm disable com.google.android.webview;
	fi
	if pm list packages -a|grep -q com.android.chrome;
	then
		pm disable com.android.chrome;
	fi
	echo "Disabled chrome and google webview. You may re-enable but please be aware that may cause issues";
else
echo "File either moved or doesn't need installed...."
fi
while [ ! "$(getprop sys.boot_completed)" == "1" ] && [ -d /sdcard/Android ];
do sleep 0.5;
done
echo "SDCARD DIR contains:" > $FINDLOG
find /sdcard/bromite >> $FINDLOG
echo "Module DIR contains:" >> $FINDLOG
find $MODDIR >> $FINDLOG
cat $MODDIR/logs/props.log > $MODDIR/logs/verbose.log
cat $MODDIR/logs/find.log >> $MODDIR/logs/verbose.log
echo "\n\n" >> $MODDIR/logs/verbose.log
cat $MODDIR/logs/postfsdata-verbose.log >> $MODDIR/logs/verbose.log
echo "\n\n" >> $MODDIR/logs/verbose.log
cat $MODDIR/logs/service-verbose.log >> $MODDIR/logs/verbose.log
cp -f $MODDIR/logs/* /sdcard/bromite/logs
