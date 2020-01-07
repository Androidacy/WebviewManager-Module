 # If you are reading this you owe me $10 => https://paypal.me/innonetlife
MODDIR=${0%/*}	
# wait until boot completed
while [ "`getprop sys.boot_completed | tr -d '\r' `" != "1" ] ;
do sleep 1;
done
# PM is broken if SElinux is set to enforcing
if [ ! "$(getenforce) == "Permissive" ];
then
	SETENFORCE=1;
fi
if [ $SETENFORCE == "1" ];
then
	setenforce 0
fi
# Bromite WebView needs to be installed as user app to prevent crashes
log -t BromiteBoot -p D "Starting BromiteBoot script"
if [ ! -f /data//media/0/bromite/installed ];
then
    pm install -r /sdcard/bromite/webview.apk
    touch /data/media/0/bromite/installed
fi
# Enable the overlay to allow our webview on incompatible ROMs
cmd overlay enable me.phh.treble.overlay.webview
if [ $SETENFORCE == "1" ];
then
	setenforce 1
fi
