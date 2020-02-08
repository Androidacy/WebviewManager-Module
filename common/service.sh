MODDIR=${0%/*} 
FINDLOG=$MODDIR/logs/find.log
VERBOSELOG=$MODDIR/logs/verbose.log
touch $FINDLOG
if [ ! -f $VERBOSELOG ] ;
then
	touch $VERBOSELOG
	echo "Post-fs-data scripts may not have ran, so our overlay may not be enabled if it's needed" > $VERBOSELOG;
fi
# PM is broken if SElinux is set to enforcing
if [ ! "$(getenforce)" == "Permissive" ];
then
	SETENFORCE=1;
else
echo "Already permissive, not resetting SELinux..." >> $VERBOSELOG ;
fi
if [ "$SETENFORCE" -eq "1" ];
then
	setenforce 0
	echo "Resetting SELinux...." >> $VERBOSELOG;
fi
# Bromite WebView needs to be installed as user app to prevent crashes
if [ -f $MODDIR/apk/webview.apk ];
then
	pm install -r $MODDIR/apk/webview.apk
	rm -rf $MODDIR/apk/webview.apk
	echo "Installed bromite webview as user app..." >> $VERBOSELOG;
fi
# Enable the overlay to allow our webview on incompatible ROMs
# RRO don't need this
#cmd overlay enable me.phh.treble.overlay.webview
if [ "$SETENFORCE" -eq "1" ];
then
	setenforce 1
	echo "Reverting SELinux reset..." >> $VERBOSELOG;
fi


# Logging
echo "SDCARD DIR contains:" > $FINDLOG
find /sdcard/bromite >> $FINDLOG
echo "Module DIR contains:" >> $FINDLOG
find $MODDIR >> $FINDLOG
mkdir -p /sdcard/bromite/logs
cp -f $FINDLOG $VERBOSELOG /sdcard/bromite/logs
