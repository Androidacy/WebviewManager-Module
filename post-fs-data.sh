#!/sbin/.magisk/busybox/ash
# shellcheck shell=dash
MODDIR=${0%/*}
YES=0
exxit() {
	  set +euxo pipefail
	    [ $1 -ne 0 ] && abort "$2"
	      exit $1
      }
mkdir -p "$MODDIR"/logs
exec 2>"$MODDIR"/logs/postfsdata-verbose.log
set -x
set -euo pipefail
trap 'exxit $?' EXIT
FINDLOG="$MODDIR"/logs/find.log
PROPSLOG="$MODDIR"/logs/props.log
touch "$FINDLOG"
OL="com.linuxandria.WebviewOverlay"
LIST="/data/system/overlays.xml"
DR="$(cat "$MODDIR"/location)"
API="$(getprop ro.build.version.sdk)"
touch "$PROPSLOG"
echo "Firing up logging NOW "
echo "---------- Device info: -----------" > "$PROPSLOG"
getprop >> "$PROPSLOG"
echo "------- End Device info ----------" >> "$PROPSLOG"
if grep 'com.linuxandria.android.webviewoverlay' /data/system/overlays.xml ;
then
	sed -i s|"com.linuxandria.android.webviewoverlay|com.linuxandria.WebviewOverlay|g"
	echo "Overlay needs updated, done"
	YES="1" ;
fi
if [ "$API" -lt "27" ];
then
	MODE="3" ;
else
	MODE="6" ;
fi
if  test ! "$YES" = "1" ;
then
 echo "Forcing the system to register our overlay..."
 sed -i "s|</overlays>|    <item packageName=\"${OL}\" userId=\"0\" targetPackageName=\"android\" baseCodePath=\"${DR}/WebviewOverlay.apk\" state=\"${MODE}\" isEnabled=\"true\" isStatic=\"true\" priority=\"98\" /></overlays>|" $LIST
fi
if test "$YES" = "1" ;
then
#	echo "Sending out overlay into the void..."
#	rm -rf "$MODDIR"/system/product "$MODDIR"/system/vendor "$MODDIR"/system/overlay;
	echo "beep boop jobs done"
fi
