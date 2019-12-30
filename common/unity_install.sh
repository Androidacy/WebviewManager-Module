# If you are reading this you owe me $10 => https://paypal.me/innonetlife

# Download corresponding libs/apk
chmod +x $TMPDIR/META-INF/unity/tools/$ARCH32/$ARCH32/curl-$ARCH32
alias curl=$TMPDIR/common/unityfiles/tools/$ARCH32/curl-$ARCH32
ui_print "- $ARCH SDK $API system detected, selecting the appropriate files"
if [ "$BOOTMODE" = "true" ];
then
	ui_print "- Downloading extra files please be patient...";
	V=$(curl -k --silent "https://api.github.com/repos/bromite/bromite/releases/latest" |   grep '"tag_name":' |  sed -E 's/.*"([^"]+)".*/\1/')
	URL=https://github.com/bromite/bromite/releases/download/$V/${ARCH}_SystemWebView.apk;
fi
# If we're runnning under TWRP, try to copy the apk, else we need to download it
if [ "$BOOTMODE" = "false" ]; then
	while [ find /sdcard/bromite|grep -i webview*.apk ];
	do
		if [ -d /sdcard/bromite/webvuew.apk ];
		then
			cp -rf /sdcard/bromite/webview*.apk $TMPDIR/webiew.apk
		elif [ ! -d /sdcard/bromite/webview.apk ]
		then
			ui_print "Not booted and no apk found!"
			ui_print "Copy the webview.apk to /sdcard/bromite/webview.apk"
			abort;
		fi
		done;
fi
if [ "$BOOTMODE" = "true" ];
then
	curl -k -L -o $TMPDIR/webview.apk $URL
	cp -rf $TMPDIR/webview.apk /sdcard/bromite/webview-${V}.apk;
fi
ui_print "- Extracting downloaded files..."
cp_ch -i $TMPDIR/webview.apk $MODPATH/system/app/webview/webview.apk
ui_print "- Removing old webview traces and clearing cache..."
rm -rf /data/resource-cache/* /data/dalvik-cache/* /cache/dalvik-cache/* /data/*/com.android.webview* /data/system/package_cache/*
ui_print "!!!!!!!!!!!!!!! VERY IMPORTANT PLEASE READ!!!!!!!!!!!!!!!!!"
ui_print "Reboot immediately after flashing or you may experience some issues! "
ui_print "!!!!!!!!!!!!!!! VERY IMPORTANT PLEASE READ!!!!!!!!!!!!!!!!!"
ui_print "Also, if you had any other webview such as Google webview, it'll need reinstalled/re-enabled"
ui_print "Next boot may take significantly longer, we have to clear Dalvik cache here"

# for i in /system/product/app /system/app; do
#	[ -d $ORIGDIR$i/Chrome ] && mktouch $MODPATH$i/Chrome/.replace
#	[ -d $ORIGDIR$i/chrome ] && mktouch $MODPATH$i/chrome/.replace
# done
# for i in /system/product/overlay /system/vendor/overlay; do
#	[ -d $ORIGDIR$i ] && cp_ch -i $TMPDIR/treble-overlay-webview.apk $MODPATH$i/treble-overlay-webview.apk
# done
while i=$(find /system/app /system/product/app -maxdepth 1|grep -i chrome);
do
	mktouch $MODPATH$i/.replace
done
while i=$(find /system /system/product /vendor -maxdepth 1|grep -i overlay);
do
	mkdir -p $MODPATH$i
	cp_ch -i $TMPDIR/treble-overlay-webview.apk $MODPATH$i
done
#    for i in /system/product/app /system/app; do
#        WEBVIEW=$(ls $i|grep -i webview*)
#	done
#echo $(ls /system/app /system/product/app|grep -i webview*) > $TMPDIR/webviews
while i=$(find /system/app /system/product/app -maxdepth 1|grep -i webview);
do
	mktouch $MODPATH$i/.replace
done
#    for i in /system/product/app /system/app; do
#		mktouch $MODPATH$i/$WEBVIEW/.replace
# done
# Disabel potential conflicts
pm disable com.google.android.webview
pm disable com.android.chrome
ui_print "Just disabled Chrome. If you want to use it enbale \nit again under App Info, but be aware than on most ROMs \n it will be forced as default!"
if $API=29:
then 
	ui_print"WARNING!!! THIS MODULE HAS KNOWN ISSUES WITH ANDROID 10!!!";
fi
