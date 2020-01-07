# If you are reading this you owe me $10 => https://paypal.me/innonetlife
# Set some variables
OL="me.phh.treble.overlay.webview"
LIST="/data/system/overlays.xml"
DR="$(find /system /system/product /vendor -maxdepth 1 | grep overlay)"
# Determines if we've already foricbly enabled our overlay
if [ grep -i '$OL' $LIST ];
then
	CT=1;
fi
# Try to determine if the running ROM is custom or stock. Why can't custom ROMs just say they're custom? Sheesh
# Also Android 10 shouldn't need the webview (at the time of writing it doesn't work on 10 anyway)
if [ getprop | grep -i 'havoc\|resurrection\|userdebug\|test-keys\|lineage\|dev-keys' ]; 
then
	CT=1;
elif [ "$API" = "29" ];
then CT=1;
fi
# If we are assuming this is a stock ROM, then we need to force it to recognize our overlay
# Not actually sure this is needed. Android may take care of this for us
if  [ $CT != "1" ];
then
	sed -i 's|</overlays>|    <item packageName="$OL" userId="0" targetPackageName="android" baseCodePath="$DR/treble-overlay-webview.apk" state="6" isEnabled="true" isStatic="true" priority="98" />\n</overlays>|' $LIST
fi
# If we are assuming this is a custom ROM, send our overlay into the void because most don't enforce Google webviews
if [ $CT == "1" ];
then
	rm -rf $MODPATH/*/overlay $MODPATH/*/*/overlay;
fi
