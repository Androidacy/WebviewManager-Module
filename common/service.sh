<<<<<<< HEAD
 # If you are reading this you owe me $10 => https://paypal.me/innonetlife
MODDIR=${0%/*}	
# wait until boot completed
install_bromite_user() {
	pm install -r -d $MODPATH/system/app/webview/webview.apk
	touch /data/media/0/.bromiteinstalled
	echo "DO NOT TOUCH THIS FILE" > /data/media/0/.bromiteinstalled 
}    
while [ ! "$(getprop sys.boot_completed)" = "1" ]; do sleep 1; done
# Bromite WebView needs to be installed as user app to prevent crashes
log -t BromiteBoot -p D "Starting BromiteBoot script"
if [ -e /data/media/0/.bromiteinstalled ]
then
	log -t BromiteBoot -p D  "No need to reinstall apk"
else
    install_bromite_user
fi
# Determimes the appropriate overlay location and installs it
# Probably not needed 
# if [ "$(ls -d /system/product/overlay 2>/dev/null)" ]
# then pm install -r $MODPATH/system/product/overlay/treble-overlay-webview.apk $MODPATH/system/product/overlay
# fi
# if [ "$(ls -d /vendor/overlay 2>/dev/null)" ]
# then pm install -r $MODPATH/system/vendor/overlay/treble-overlay-webview.apk $MODPATH/vendor/overlay
# fi
# Enable the overlay to allow our webview on incompatible ROMs
cmd overlay enable me.phh.treble.overlay.webview
# Because Google 

=======
# This script will be executed in late_start service mode
# More info in the main Magisk thread
>>>>>>> 5bc76bf8094a5d1ee1da22ea560406f786012e9e
