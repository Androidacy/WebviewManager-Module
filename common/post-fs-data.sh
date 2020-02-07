# Set some variables
MODDIR=${0%/*}
FINDLOG=$MODDIR/logs/find.log
VERBOSELOG=$MODDIR/logs/verbose.log
mkdir -p $MODDIR/logs
touch $FINDLOG
touch $VERBOSELOG
OL="me.phh.treble.overlay.webview"
LIST="/data/system/overlays.xml"
DR="$(find /system /system/product /vendor -maxdepth 1 | grep overlay)"
API="$(getprop ro.build.version.sdk)"

# Logging stuffs
echo "Device info:" > $VERBOSELOG
getprop ro.product.cpu.abi >> $VERBOSELOG
getprop ro.product.brand >> $VERBOSELOG
getprop ro.product.name >> $VERBOSELOG
getprop ro.build.version.sdk >> $VERBOSELOG

# Determines if we've already foricbly enabled our overlay
if [ grep -i '$OL' $LIST ];
then
	echo "Overlay already enabled!" >> $VERBOSELOG
	CT=1;
fi
# Try to determine if the running ROM is custom or stock. Why can't custom ROMs just say they're custom? Sheesh
# Also Android 10 shouldn't need the webview, needs more testing
if [ getprop | grep -i 'havoc\|resurrection\|userdebug\|test-keys\|lineage\|dev-keys' ]; 
then
	echo "Custom ROM detected!" >> $VERBOSELOG
	CT=1;
elif [ $API == "29" ];
then
	echo "Android 10 detected! >> $VERBOSELOG
	CT=1;
fi
# If we are assuming this is a stock ROM, then we need to force it to recognize our overlay
# Not actually sure this is needed. Android may take care of this for us
if  [ $CT !== "1" ];
then
	echo "Forcing the system to register our overlay..." >> $VERBOSELOG
	sed -i 's|</overlays>|    <item packageName="$OL" userId="0" targetPackageName="android" baseCodePath="$DR/treble-overlay-webview.apk" state="6" isEnabled="true" isStatic="true" priority="98" />\n</overlays>|' $LIST
fi
# If we are assuming this is a custom ROM, send our overlay into the void because most don't enforce Google webviews
if [ $CT == "1" ];
then
	echo "Sending out overlay into the void...." >> $VERBOSELOG
	mv $MODDIR/*/overlay $MODDIR/*/*/overlay /dev/null;
fi
