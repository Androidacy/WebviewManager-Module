# Here we set up the internal storage location
$BOOTMODE && SDCARD=/storage/emulated/0 || SDCARD=/data/media/0
# Also SElinux may be an issue here
if [ ! "$(getenforce)" == "Permissive" ];
then
	SETENFORCE=1;
fi
if [ $SETENFORCE == "1" ];
then
	setenforce 0
fi
chmod +x $UF/tools/$ARCH32/curl
alias curl='$UF/tools/$ARCH32/curl'
ui_print "- $ARCH SDK $API system detected, selecting the appropriate files"
if [ "$BOOTMODE" = true ];
then
    mkdir -p /data/media/0/bromite/logs
	ui_print "- Downloading extra files please be patient..."
	V=$(curl -k --silent "https://api.github.com/repos/bromite/bromite/releases/latest" |   grep '"tag_name":' |  sed -E 's/.*"([^"]+)".*/\1/')
	URL=https://github.com/bromite/bromite/releases/download/${V}/${ARCH}_SystemWebView.apk
	if [ -f ${SDCARD}/bromite/webview.apk ];
	then
		if [ "${V}" -gt "$(${SDCARD}/bromite/VERSION)" ];
		then
			curl -k -L -o /data/media/0/bromite/webview.apk $URL
			echo "${V}" > /data/media/0/bromite/version
	fi
	ui_print "- Extracting webview files..."
	if [ ! -f ${SDCARD}/bromite/webview.apk ];
	then
		ui_print "Sorry! A problem occurred. No capable apk was found, the files failed to download, or both!"
		abort;
	fi
	cp_ch -i ${SDCARD}/bromite/webview.apk $MODPATH/system/app/webview/webview.apk
# If we're runnning under TWRP, try to copy the apk, else we need to download it so abort
elif [ "$BOOTMODE" = false ]; then
	# Deal with broken recoveries
	recovery_actions
	ensure_bb
	setup_flashable
	if [ -f ${SDCARD}/bromite/webview.apk ];
	then
		cp_ch -i ${SDCARD}/bromite/webview.apk $MODPATH/system/webview;
	elif [ ! -f ${SDCARD}/bromite/webview.apk ];
	then
		ui_print "Not booted and no apk found!"
		ui_print "Copy the webview.apk to /sdcard/bromite/webview.apk"
		ui_print "Aborting..."
		abort ;
	fi
fi
ui_print "!!!!!!!!!!!!!!! VERY IMPORTANT PLEASE READ!!!!!!!!!!!!!!!!!"
ui_print "Reboot immediately after flashing or you may experience some issues! "
ui_print "Also, if you had any other webview such as Google webview, it'll need reinstalled/re-enabled"
ui_print "Next boot may take significantly longer, we have to clear Dalvik cache here"
rm -rf /data/resource-cache/* /data/dalvik-cache/* /cache/dalvik-cache/* /data/*/com.android.webview* /data/system/package_cache/*
if [ -d /product/overlay ];
then
        mkdir -p $MODPATH/system/product/overlay
	    cp_ch -i $TMPDIR/treble-overlay-webview.apk $MODPATH/system/product/overlay;
elif [ -d /vendor/overlay ]
then
	mkdir -p $MODPATH/vendor/overlay
	cp_ch -i $TMPDIR/treble-overlay-webview.apk $MODPATH/system/vendor/overlay;
elif [ -d /system/overlay ]
then
	mkdir -p $MODPATH/vendor/overlay
	cp_ch -i $TMPDIR/treble-overlay-webview.apk $MODPATH/system/overlay;
fi
# Disable potential conflicts
pm disable com.google.android.webview
pm disable com.android.chrome
ui_print "Just disabled Chrome and Google System Webview. If you want to use it enbale it again under App Info, but be aware than on most ROMs it will be forced as default!"
if [ "${API}" == "29" ]; then
    ui_print "!!!!!!!!!!!!!!!!!!!!!!!!!Important!!!!!!!!!!!!!!!!!!!!!!!!"
    ui_print "!Android 10 has not been tested thoroughly!"
    ui_print "!     It has several known issues         !"
    ui_print "!!!!!!!!!!!!!!!!!!!!!!!!!Important!!!!!!!!!!!!!!!!!!!!!!!!"
    ui_print " "
    rm -rf $MODPATH/post-fs-data.sh
    rm -rf $MODPATH/*/*/overlay
fi
# Debugging stuffs
find $MODPATH &> ${SDCARD}/bromite/logs/find.log
if [ $SETENFORCE == "1" ];
then
	setenforce 1
fi