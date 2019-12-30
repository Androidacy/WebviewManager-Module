# If you are reading this you owe me $10 => https://paypal.me/innonetlife
# Set some variables
OL="me.phh.treble.overlay.webview"
LIST="/data/system/overlays.xml"
DR=$(find /system /system/product /vendor -maxdepth 1 | grep overlay)
# Determines if we've already foricbly enabled our overlay
NY=1
if [ ! grep '$OL' $LIST ];
then
	NY=0;
fi
# Try to determine if the running ROM is custom or stock
# Also Android 10 shouldn't beed the webview
CT=2
if [ grep -i 'havoc\|resurrection\|userdebug\|test-keys\|lineage\|maintainer' /system/build.prop ]; 
then
	CT=1;
elif [ "$API" = "29" ];
then CT=1;
fi
# If we are assuming this is a stock ROM, then we need to force it to recognize our overlay
if CT=2 and NY=0;
then
	sed -i 's|</overlays>|    <item packageName="$OL" userId="0" targetPackageName="android" baseCodePath="$DR/treble-overlay-webview.apk" state="6" isEnabled="true" isStatic="true" priority="98" />\n</overlays>|' $LIST
fi
# If we are assuming this is a custom ROM, send our overlay into the void because most don't enforce Google webviews
if CT=1;
then
	rm -rf $MODPATH/*/overlay $MODPATH/*/*/overlay;
fi
