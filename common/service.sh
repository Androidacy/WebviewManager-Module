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
	pm install $MODDIR/apk/webview.apk
	rm -rf $MODDIR/apk/webview.apk
	echo "Installed bromite webview as user app.."
	pm disable com.google.android.webview
	pm disable com.android.chrome
	echo "Disabled chrome and google webview. You may re-enable but please be aware that may cause issues";
else
echo "File either moved or doesn't need installed...."
fi
while [ ! "$(getprop sys.boot_completed)" == "1" ];
do sleep 0.5;
done
sleep 40
echo "SDCARD DIR contains:" > $FINDLOG
find /storage/emulated/0/bromite >> $FINDLOG
echo "Module DIR contains:" >> $FINDLOG
find $MODDIR >> $FINDLOG
cat $MODDIR/logs/* > $MODDIR/logs/verbose.log
cp -f $MODDIR/logs/* /storage/emulated/0/bromite/logs
