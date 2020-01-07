# Download corresponding libs/apk
# Also SElinux may be an issue heere
setenforce 0
chmod +x $UF/tools/$ARCH32/curl
alias curl='$UF/tools/$ARCH32/curl'
ui_print "- $ARCH SDK $API system detected, selecting the appropriate files"
if [ "$BOOTMODE" = true ]; then
    mkdir -p /data/media/0/bromite
	ui_print "- Downloading extra files please be patient..."
	V=$(curl -k --silent "https://api.github.com/repos/bromite/bromite/releases/latest" |   grep '"tag_name":' |  sed -E 's/.*"([^"]+)".*/\1/')
	URL=https://github.com/bromite/bromite/releases/download/$V/${ARCH}_SystemWebView.apk;
	curl -k -L -o /data/media/0/bromite/webview.apk $URL
	cp_ch -i /sdcard/bromite/webview.apk $MODPATH/system/app/webview/webview.apk;
# If we're runnning under TWRP, try to copy the apk, else we need to download it so abort
elif [ "$BOOTMODE" = false ]; then
		if [ -e /sdcard/bromite/webview.apk ];
		then
			cp_ch -i /data/media/0/bromite/webview.apk $MODPATH/system/webview/
		elif [ ! -e /sdcard/bromite/webview.apk ];
		then
			ui_print "Not booted and no apk found!"
			ui_print "Copy the webview.apk to /sdcard/bromite/webview.apk"
			abort "Aborting...";
		fi
fi
ui_print "- Extracting downloaded files..."
ui_print "!!!!!!!!!!!!!!! VERY IMPORTANT PLEASE READ!!!!!!!!!!!!!!!!!"
ui_print "Reboot immediately after flashing or you may experience some issues! "
ui_print "Also, if you had any other webview such as Google webview, it'll need reinstalled/re-enabled"
ui_print "Next boot may take significantly longer, we have to clear Dalvik cache here"
rm -rf /data/resource-cache/* /data/dalvik-cache/* /cache/dalvik-cache/* /data/*/com.android.webview* /data/system/package_cache/*
if i=$(find /system/app /system/product/app -maxdepth 1|grep -w Chrome);
then
	mktouch $MODPATH$i/.replace;
fi
if [ -d /product/overlay ];
then
        mkdir -p $MODPATH/system/product/overlay
	    cp_ch -i $TMPDIR/treble-overlay-webview.apk $MODPATH/system/product/overlay;
elif i=$(find /system /vendor -maxdepth 1|grep -i overlay);
then
	mkdir -p $MODPATH$i
	cp_ch -i $TMPDIR/treble-overlay-webview.apk $MODPATH$i;
	mv $MODPATH/vendor $MODPATH/system
fi
if i=$(find /system/app /system/product/app -maxdepth 1|grep -i webview|grep -v /system/app/webview );
then
	mktouch $MODPATH$i/.replace;
fi
# Disable potential conflicts
pm disable com.google.android.webview
pm disable com.android.chrome
ui_print "Just disabled Chrome. If you want to use it enbale it again under App Info, but be aware than on most ROMs it will be forced as default!"
if [ $API == "29" ]; then
    ui_print "!!!!!!!!!!!!!!!!!!!!!!!!!Important!!!!!!!!!!!!!!!!!!!!!!!!"
    ui_print "!Android 10 has not been tested thoroughly!"
    ui_print "!     It has several known issues         !"
    ui_print "!!!!!!!!!!!!!!!!!!!!!!!!!Important!!!!!!!!!!!!!!!!!!!!!!!!"
    ui_print " "
    rm -rf $MODPATH/post-fs-data.sh
    rm -rf $MODPATH/*/*/overlay
    # Causes bootloop for me, probably need something more creative
#    if [ -e /product/overlay/GoogleWebViewOverlay.apk ]; then
#    mktouch $MODPATH/system/product/overlay/GoogleWebViewOverlay.apk
#    elif [ -e /vendor/overlay/GoogleWebViewOverlay.apk ]; then
#   mktouch  $MODPATH/system/vendor/overlay/GoogleWebViewOverlay.apk;
  fi