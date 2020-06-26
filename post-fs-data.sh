#!/sbin/.magisk/busybox/ash
MODDIR=${0%/*}
YES=0
INFO=/data/adb/modules/.bromitewebview-files
MODID=bromitewebview
LIBDIR=/system
MODPATH=/data/adb/modules/bromitewebview
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
FINDLOG=$MODDIR/logs/find.log
PROPSLOG=$MODDIR/logs/props.log
touch $FINDLOG
OL="com.linuxandria.WebviewOverlay"
LIST="/data/system/overlays.xml"
DR="$(cat $MODDIR/location)"
API="$(getprop ro.build.version.sdk)"
touch $PROPSLOG
echo "Firing up logging NOW "
echo "---------- Device info: -----------" > $PROPSLOG
getprop >> $PROPSLOG
echo "------- End Device info ----------" >> $PROPSLOG
if grep 'com.linuxandria.android.webviewoverlay' /data/system/overlays.xml ;
then
	sed -i s|"com.linuxandria.android.webviewoverlay|com.linuxandria.WebviewOverlay|g"
	echo "Overlay needs updated, done"
	set YES="1" ;
fi
# It's actually probably desirable to have our overlay on custom ROMs
#if [ "getprop | grep 'havoc\|resurrection\|userdebug\|test-keys\|lineage\|dev-keys\|maintainer'" ];
# then
#	echo "Custom ROM is running"
#	set CT="1" ;
#fi
# if [ "$API" == "29" ];
#then
#	echo "Android 10 detected"
#	CT="1" ;
#fi
if [ "$API" -lt "27" ];
then
	set MODE="3" ;
else
	set MODE="6" ;
fi
if  [ ! "$YES" == "1" ];
then
 echo "Forcing the system to register our overlay..."
 sed -i "s|</overlays>|    <item packageName=\"${OL}\" userId=\"0\" targetPackageName=\"android\" baseCodePath=\"${DR}/WebviewOverlay.apk\" state=\"${MODE}\" isEnabled=\"true\" isStatic=\"true\" priority=\"98\" /></overlays>|" $LIST
fi
if [ "$YES" == "1" ];
then
#	echo "Sending out overlay into the void..."
#	rm -rf $MODDIR/system/product $MODDIR/system/vendor $MODDIR/system/overlay;
	echo "beep boop jobs done"
fi
