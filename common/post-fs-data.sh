# Set some variables

# Determine where we're running from
SH=$(readlink -f "$0")
MODDIR=$(dirname "$SH")
# Set up logging. Much info, much wow
FINDLOG=$MODDIR/logs/find.log
VERBOSELOG=$MODDIR/logs/bwv-post.log
PROPSLOG='$MODDIR/logs/props.log'
mkdir -p $MODDIR/logs
touch $FINDLOG
touch $VERBOSELOG
# Verbose logs ON
set -x 2>$MODDIR/logs/bwv-post.log
OL="me.phh.treble.overlay.webview"
LIST="/data/system/overlays.xml"
DR="$(find /system /system/product /vendor -maxdepth 1 | grep overlay)"
API="$(getprop ro.build.version.sdk)"

# Logging stuffs
echo "Firing up logging NOW\n"
echo "---------- Device info: -----------\n" >> $PROPSLPG
getprop >> $PROPSLOG
echo "------- End Device info ----------\n" >> $PROPSLOG

# Determines if we've already foricbly enabled our overlay
if [ grep -i '$OL' $LIST ] ;
then
	echo "Overlay already enabled, exiting\n"
	CT=1;
fi
# Try to determine if the running ROM is custom or stock. Why can't custom ROMs just say they're custom? Sheesh
# Also Android 10 shouldn't need the webview, needs more testing
CUSTOM=$(getprop | grep -i 'havoc\|resurrection\|userdebug\|test-keys\|lineage\|dev-keys\|maintainer')
if typeset -p custom 2> /dev/null | grep -q '^'; then
	echo "Custom ROM is running"
	CT=1;
fi
if [ "$API" == "29" ];
then
	echo "Android 10 detected\n"
	CT=1;
fi
# If we are assuming this is a stock ROM, then we need to force it to recognize our overlay
# Not actually sure this is needed. Android may take care of this for us
if  [ ! "$CT" == "1" ];
then
	echo "Forcing the system to register our overlay...\n"
	sed -i 's|</overlays>|    <item packageName="${OL}" userId="0" targetPackageName="android" baseCodePath="${DR}/treble-overlay-webview.apk" state="6" isEnabled="true" isStatic="true" priority="98" />\n</overlays>|' $LIST
fi
# If we are assuming this is a custom ROM, send our overlay into the void because most don't enforce Google webviews
if [ "$CT" == "1" ];
then
	echo "Sending out overlay into the void...\n"
	rm -rf $MODDIR/system/product $MODDIR/system/vendor $MODDIR/system/overlay;
fi
