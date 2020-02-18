#!/system/bin/sh
exxit() {
	  set +euxo pipefail
	    [ $1 -ne 0 ] && abort "$2"
	      exit $1
      }

exec 2>/data/media/0/bromite/logs/service-verbose.log
set -x
set -euo pipefail
trap 'exxit $?' EXIT
SH=$(readlink -f "$0")
MODDIR=$(dirname "$SH")
FINDLOG=$MODDIR/logs/find.log
VERBOSELOG=$MODDIR/logs/bwv-service.log
touch $VERBOSELOG
set -x 2>$MODDIR/logs/bwv-service.log
touch $FINDLOG
echo "Started at $(date)"
if [ -f $MODDIR/apk/webview.apk ] ;
then
	sleep 30
	pm install $MODDIR/apk/webview.apk
	rm -rf $MODDIR/apk/webview.apk
	echo "Installed bromite webview as user app..\n"
	pm disable com.google.android.webview
	pm disable com.android.chrome
	echo "Disabled chrome and google webview. You may re-enable but please be aware that may cause issues\n";
else
echo "File either moved or doesn't need installed....\n"
fi
while [ ! "$(getprop sys.boot_completed)" == "1" ];
do sleep 0.5;
done
sleep 40
echo "SDCARD DIR contains:\n" > $FINDLOG
find /storage/emulated/0/bromite >> $FINDLOG
echo "\nModule DIR contains:\n" >> $FINDLOG
find $MODDIR >> $FINDLOG
mkdir -p /sdcard/bromite/logs
cat $MODDIR/logs/props.log > $MODDIR/logs/verbose.log
echo "Post-fs-data logs" >> $MODDIR/logs/verbose.log
cat $MODDIR/logs/postfsdata-verbose.log >> $MODDIR/logs/verbose.log
echo "Service logs" >> $MODDIR/logs/verbose.log
cat $MODDIR/logs/service-verbosee.log >> $MODDIR/logs/verbose.log
cp -f $MODDIR/logs/* /storage/emulated/0/bromite/logs

