# Here we set up the internal storage location
$BOOTMODE && SDCARD=/storage/emulated/0 || SDCARD=/sdcard
VERSIONFILE='/sdcard/bromite/version'
chmod 0755 $MODPATH/common/tools/curl-$ARCH32
alias curl='$MODPATH/common/tools/curl-$ARCH32'
ui_print "- $ARCH SDK $API system detected, selecting the appropriate files"
# Set up version check
if [ ! -f /sdcard/bromite/version ];
then
	mktouch $VERSIONFILE
	echo "0" > $VERSIONFILE;
fi
if [ "$BOOTMODE" = true ];
then
	mkdir -p /sdcard/bromite
	ui_print "- Downloading extra files please be patient..."
	V=$(curl -k -L --silent "https://api.github.com/repos/bromite/bromite/releases/latest" |   grep '"tag_name":' |  sed -E 's/.*"([^"]+)".*/\1/')
	URL=https://github.com/bromite/bromite/releases/download/${V}/${ARCH}_SystemWebView.apk
	if [ -f /sdcard/bromite/webview.apk ] ;
	then
		if [ "$(cat $VERSIONFILE|tr -d '.')" -lt "$(echo ${V}|tr -d '.')" ];
		then
			curl -k -L -o /sdcard/bromite/webview.apk $URL
			echo "${V}" > $VERSIONFILE;
		fi;
	else
	# If the file doesn't exist, let's attempt a download anyway
		curl -k -L -o /sdcard/bromite/webview.apk $URL
		echo "${V}" > $VERSIONFILE;
	fi
	ui_print "- Extracting webview files..."
	if [ ! -f /sdcard/bromite/webview.apk ];
	then
		# File wasn't found and all attempts to download failed
		ui_print "Sorry! A problem occurred."
		ui_print "No capable apk was found, the files failed to download, or both!"
		ui_print "Check your internet and try again"
		abort;
	fi
	cp_ch ${SDCARD}/bromite/webview.apk $MODPATH/system/app/webview/webview.apk
# If we're runnning under TWRP, try to copy the apk, else we need to download it so abort
# Unnecessary. mmt-ex doesn't allow TWRP installs. Probably shoudl remove this but it breaks stuff so it stays...
fi
ui_print "!!!!!!!!!!!!!!! VERY IMPORTANT PLEASE READ!!!!!!!!!!!!!!!!!"
ui_print "Reboot immediately after flashing or you may experience some issues! "
ui_print "Also, if you had any other webview such as Google webview, you may want to re-enable it but beware conflicts"
ui_print "Next boot may take significantly longer, we have to clear Dalvik cache here"
rm -rf /data/resource-cache/* /data/dalvik-cache/* /cache/dalvik-cache/* /data/*/com.android.webview* /data/system/package_cache/*
if [ -d /product/overlay ];
then
        mkdir -p $MODPATH/system/product/overlay
        cp_ch $MODPATH/common/WebviewOverlay.apk $MODPATH/system/product/overlay;
elif [ -d /vendor/overlay ]
then
	mkdir -p $MODPATH/system/vendor/overlay
	cp_ch $MODPATH/common/WebviewOverlay.apk $MODPATH/system/vendor/overlay;
elif [ -d /system/overlay ]
then
	mkdir -p $MODPATH/system/overlay
	cp_ch $MODPATH/common/WebviewOverlay.apk $MODPATH/system/overlay;
fi
if [ "${API}" == "29" ];
then
    ui_print "Android 10 detected" 
fi
mkdir -p $MODPATH/apk 
cp_ch /sdcard/bromite/webview.apk $MODPATH/apk 
rm -f $MODPATH/system/app/placeholder 
mkdir -p /storage/emulated/0/bromite/logs 
# Damn you Zackptg5
# cp -f /storage/emulated/0/Download/${MODID}-debug.log /sdcard/bromite/logs 
# rm -f /storage/eumlated/0/Download/${MODID}-debug.log
rm -f $MODPATH/*.md 
ui_print "\n\nEnjoy a more private and faster webview, done systemlessly" 
ui_print "Don't forget my links:"
ui_print "Social platforms: https://t.me/inlmagisk, https://t.me/bromitewebview, https://discord.gg/gTnDxQ6"
ui_print "Donate at: https://paypal.me/linuxandria or https://www.patreon.com/linuxandria_xda"
