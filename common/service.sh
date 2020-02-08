# Determine where we are
SH=$(readlink -f "$0")
MODDIR=$(dirname "$SH")
# Set up logging
FINDLOG=$MODDIR/logs/find.log
VERBOSELOG=$MODDIR/logs/bwv-service.log
exec 3>&1 4>&2
trap 'exec 2>&4 1>&3' 0 1 2 3
exec 1>$VERBOSELOG 2>&1
touch $FINDLOG
echo "Started at $(date)"
if [ ! -f $VERBOSELOG ] ;
then
	touch $VERBOSELOG
	echo "Post-fs-data scripts may not have ran, so our overlay may not be enabled if it's needed\n";
fi
# Determine the current SELinux state
if [ ! "$(getenforce)" == "Permissive" ];
then
	SETENFORCE=1;
else
echo "Already permissive, not resetting SELinux..\n";
fi
# PM is weird if SELinux is enforcing so let's make it not.
if [ "$SETENFORCE" -eq "1" ];
then
	setenforce 0
	echo "Resetting SELinux....\n";
fi
# Bromite WebView needs to be installed as user app to prevent crashes
if [ -f $MODDIR/apk/webview.apk ] ;
then
	sleep 30
	pm install $MODDIR/apk/webview.apk
	rm -rf $MODDIR/apk/webview.apk
	echo "Installed bromite webview as user app..\n.";
else
echo "File either moved or doesn't need installed....\n" >> $VERBOSELOG
fi
if [ "$SETENFORCE" -eq "1" ] ;
then
	setenforce 1
	echo "Reverting SELinux reset...\n";
fi


# Wait until internal storage is accessible
while [ ! "$(getprop sys.boot_completed)" == "1" ];
do sleep 0.5;
done
sleep 60
echo "SDCARD DIR contains:\n" >> $FINDLOG
find /storage/emulated/0/bromite >> $FINDLOG
echo "\nModule DIR contains:\n" >> $FINDLOG
find $MODDIR >> $FINDLOG
mkdir -p /sdcard/bromite/logs
echo "$(cat $MODDIR/logs/bwv-post.log)" > $MODDIR/logs/verbose.log
echo "Service logs" >> $MODDIR/logs/verbose.log
echo "$(cat $MODDIR/logs/bwv-service.log)" >> $MODDIR/logs/verbose.log
cp -f $MODDIR/logs/* /storage/emulated/0/bromite/logs
