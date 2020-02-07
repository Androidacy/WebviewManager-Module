MODDIR=${0%/*}
FINDLOG=$MODDIR/find.log
VERBOSELOG=$MODDIR/logs/verbose.log
touch $FINDLOG
touch $VERBOSELOG
# wait until boot completed and hopefully internal storage decrypted
while [ ! -d /data/media/0/bromite ] ;
do sleep 0.5;
done
# PM is broken if SElinux is set to enforcing
if [ ! "$(getenforce) == "Permissive" ];
then
	SETENFORCE=1;
	echo "Already permissive, not resetting SELinux..." >> $VERBOSELOG;
fi
if [ $SETENFORCE == "1" ];
then
	setenforce 0
	echo "Resetting SELinux...." >> $VERBOSELOG;
fi
# Bromite WebView needs to be installed as user app to prevent crashes
log -t BromiteBoot -p D "Starting BromiteBoot script"
if [ ! -f /data/media/0/bromite/.installed ];
then
	pm install -r /data/media/0/bromite/webview.apk
	touch /data/media/0/bromite/.installed
	echo "Installed bromite webview as user app..." >> $VERBOSELOG;
fi
# Enable the overlay to allow our webview on incompatible ROMs
# RRO don't need this
#cmd overlay enable me.phh.treble.overlay.webview
if [ $SETENFORCE == "1" ];
then
	setenforce 1
	echo "Reverting SELinux reset..." >> $VERBOSELOG;
fi


# Logging
echo "SDCARD DIR contains:" > $FINDLOG
find /data/media/0/bromite >> $FINDLOG
echo "Module DIR contains:" >> $FINDLOG
find $MODDIR/bromitewebview >> $FINDLOG

mkdir -p /data/media/0/bromite/logs
mv $FINDLOG $VERBOSELOG /data/media/0/bromite/logs
