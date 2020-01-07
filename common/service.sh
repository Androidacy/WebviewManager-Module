 # If you are reading this you owe me $10 => https://paypal.me/innonetlife
MODDIR=${0%/*}	
# wait until boot completed
while [ "`getprop sys.boot_completed | tr -d '\r' `" != "1" ] ; do sleep 1; done
# Bromite WebView needs to be installed as user app to prevent crashes
log -t BromiteBoot -p D "Starting BromiteBoot script"
pm install -r /sdcard/bromite/webview.apk
# Enable the overlay to allow our webview on incompatible ROMs
cmd overlay enable me.phh.treble.overlay.webview
# Because Google 

