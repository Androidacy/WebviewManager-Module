# Set some variables
SH=$(readlink -f "$0")
MODDIR=$(dirname "$SH")
exxit() {
	  set +euxo pipefail
	    [ $1 -ne 0 ] && abort "$2"
	      exit $1
      }

mkdir -p $MODDIR/logs
exec 2>$MODDIR/logs/postfsdata-verbose.log
set -x
set -euo pipefail
trap 'exxit $?' EXIT
# Determine where we're running from
# Set up logging. Much info, much wow
FINDLOG=$MODDIR/logs/find.log
PROPSLOG=$MODDIR/logs/props.log
mkdir -p $MODDIR/logs
touch $FINDLOG
# Verbose logs ON
OL="me.phh.treble.overlay.webview"
LIST="/data/system/overlays.xml"
DR="$(find /system /system/product /vendor -maxdepth 1 | grep overlay)"
API="$(getprop ro.build.version.sdk)"

# Logging stuffs
touch $PROPSLOG
echo "Firing up logging NOW "
echo "---------- Device info: -----------" >> $PROPSLOG
getprop >> $PROPSLOG
echo "------- End Device info ----------" >> $PROPSLOG

# Determines if we've already foricbly enabled our overlay
if [ grep '$OL' $LIST ] ;
then
	echo "Overlay already enabled, exiting"
	export CT=1;
fi
# Try to determine if the running ROM is custom or stock. Why can't custom ROMs just say they're custom? Sheesh
# Also Android 10 shouldn't need the webview, needs more testing
CUSTOM=$(getprop | grep 'havoc\|resurrection\|userdebug\|test-keys\|lineage\|dev-keys\|maintainer')
if typeset -p custom 2> /dev/null | grep -q '^'; then
	echo "Custom ROM is running"
	CT=1;
fi
if [ "$API" == "29" ];
then
	echo "Android 10 detected"
	CT=1;
fi
if [ "$API" <= "27" ];
then
	MODE=3;
else
	mode=6;
fi
# If we are assuming this is a stock ROM, then we need to force it to recognize our overlay
# Not actually sure this is needed. Android may take care of this for us
if  [ ! "$CT" == "1" ];
then
 echo "Forcing the system to register our overlay..."
 sed -i "s|</overlays>|    <item packageName=\"${OL}\" userId=\"0\" targetPackageName=\"android\" baseCodePath=\"${DR}/WebviewOverlay.apk\" state=\"${MODE}\" isEnabled=\"true\" isStatic=\"true\" priority=\"98\" /></overlays>|" $LIST
fi
# If we are assuming this is a custom ROM, send our overlay into the void because most don't enforce Google webviews
if [ "$CT" == "1" ];
then
	echo "Sending out overlay into the void..."
	rm -rf $MODDIR/system/product $MODDIR/system/vendor $MODDIR/system/overlay;
fi
