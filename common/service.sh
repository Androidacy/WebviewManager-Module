# Determine where we are
SH=$(readlink -f "$0")
MODDIR=$(dirname "$SH")
# Set up logging
FINDLOG=$MODDIR/logs/find.log
VERBOSELOG=$MODDIR/logs/bwv-service.log
touch $VERBOSELOG
set -x 2>$MODDIR/logs/bwv-service.log
touch $FINDLOG
echo "Started at $(date)"
# Bromite WebView needs to be installed as user app to prevent crashes
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

# Wait until internal storage is accessible
while [ ! "$(getprop sys.boot_completed)" == "1" ];
do sleep 0.5;
done
sleep 45
echo "SDCARD DIR contains:\n" >> $FINDLOG
find /storage/emulated/0/bromite >> $FINDLOG
echo "\nModule DIR contains:\n" >> $FINDLOG
find $MODDIR >> $FINDLOG
mkdir -p /sdcard/bromite/logs
cat $MODDIR/logs/props.log > $MODDIR/logs/verbose.log
echo "Post-fs-data logs >> $MODDIR/logs/verbose.log
cat $MODDIR/logs/bwv-post.log >> $MODDIR/logs/verbose.log
echo "Service logs" >> $MODDIR/logs/verbose.log
cat $MODDIR/logs/bwv-service.log >> $MODDIR/logs/verbose.log
cp -f $MODDIR/logs/* /storage/emulated/0/bromite/logs
