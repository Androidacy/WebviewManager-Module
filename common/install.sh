# Here we set up the internal storage location
# shellcheck shell=dash

$BOOTMODE && SDCARD=/storage/emulated/0 || SDCARD=/sdcard
mkdir "$MODPATH"/logs
VERSIONFILE='/sdcard/bromite/version'
if test "$ARCH" = "x86_64" ;
then
	alias aapt='$MODPATH/common/tools/aapt64' ;
elif test "$ARCH" = "x86" ;
then
	alias aapt='$MODPATH/common/tools/aaptx86' ;
else
	alias aapt='$MODPATH/common/tools/aapt' ;
fi
alias sign='"$MODPATH"/common/tools/zipsigner'
alias curl='"$MODPATH"/common/tools/curl-${ARCH32}'
chmod -R 0755 "$MODPATH"/common/tools
# Thanks SKittles9832 for the code I shamelessly copied :)
VEN=/system/vendor
[ -L /system/vendor ] && VEN=/vendor
if [ -f $VEN/build.prop ]; then BUILDS="/system/build.prop $VEN/build.prop"; else BUILDS="/system/build.prop"; fi
# MIUI screws with our overlay and no one wants to tell me how to fix it
MIUI=$(grep "ro.miui.ui.version.*" $BUILDS)
if [ "$MIUI" ]; then
  ui_print " MIUI is not supported, unless someone tells me how"
  abort " Aborting..."
fi
if  test "$API" -eq 30 ;
then
	ui_print "Android 11 is not supported!"
	abort "Aborting...";
fi
ui_print "- $ARCH SDK $API system detected, selecting the appropriate files"
# Set up version check
mkdir -p /sdcard/bromite
if [ ! -f /sdcard/bromite/version ];
then
	mktouch $VERSIONFILE
	echo "0" > $VERSIONFILE;
fi
# Handle version upgrades
rm -rf /sdcard/bromite/webview.apk
download_webview () {
	ui_print "- Downloading extra files please be patient..."
	V=$(curl -k -L --silent "https://api.github.com/repos/bromite/bromite/releases/latest" |   grep '"tag_name":' |  sed -E 's/.*"([^"]+)".*/\1/')
	echo "$V" > "$VERSIONFILE"
	URL="https://github.com/bromite/bromite/releases/download/${V}/${ARCH}_SystemWebView.apk"
	if [ -f /sdcard/bromite/"${ARCH}"_SystemWebView.apk ] ;
	then
	# Only re-download if it's an upgrade
		if [ "$(< "$VERSIONFILE" tr -d '.')" -lt "$(echo "$V" | tr -d '.')" ];
		then
			curl -k -L -o /sdcard/bromite/"${ARCH}"_SystemWebView.apk "$URL"
		fi
	else
		# If the file doesn't exist, let's attempt a download anyway
		curl -k -L -o /sdcard/bromite/"${ARCH}"_SystemWebView.apk "$URL" ;
	fi
}
verify_webview () {
	ui_print "Verifying files..."
	curl -L -k -o "$TMPDIR"/"$ARCH"_SystemWebView.apk.sha256.txt https://github.com/bromite/bromite/releases/download/"$V"/brm_"$V".sha256.txt
	cd /sdcard/bromite || return
	grep "$ARCH"_SystemWebView.apk "$TMPDIR"/"$ARCH"_SystemWebView.apk.sha256.txt > /sdcard/bromite/"$ARCH"_SystemWebView.apk.sha256.txt 
	sha256sum -sc /sdcard/bromite/"$ARCH"_SystemWebview.apk.sha256.txt 
	if test $? -ne 0 ;
	then
		ui_print "Verification failed, retrying download"
		rm -f /sdcard/bromite/"${ARCH}"_SystemWebView.apk
		download_webview
		verify_webview ;
	else
	ui_print "Verified successfully. Proceeding..."
	fi
	cd - || return >/dev/null
}
ping -c 1 -q github.com > /dev/null
if test $? -eq 0 ;
then
	download_webview
	verify_webview ;
elif test ! -f /sdcard/bromite/"${ARCH}"_SystemWebView.apk ;
then
	# File wasn't found and all attempts to download failed
	ui_print "Sorry! A problem occurred."
	ui_print "No capable apk was found, the files failed to download, or both!"
	ui_print "Check your internet and try again"
	abort ;
fi
# Try to determine existing webview install
ui_print "- Extracting downloaded file"
unset APKPATH
paths=$(cmd package dump com.android.webview | grep codePath); APKPATH=${paths##*=}
[ -z "${APKPATH}" ] && paths=$(cmd package dump com.google.android.webview | grep codePath); APKPATH=${paths##*=}
[ -z "${APKPATH}" ] && paths=$(cmd package dump com.android.webview | grep codePath); APKPATH=${paths##*=}
[ -z "${APKPATH}" ] && APKPATH="/system/app/webview"
cp_ch ${SDCARD}/bromite/"${ARCH}"_SystemWebView.apk "$MODPATH"$APKPATH/webview.apk
touch "$MODPATH"$APKPATH/.replace
cp "$MODPATH"$APKPATH/webview.apk "$TMPDIR"/webview.zip 
mkdir "$TMPDIR"/webview -p
unzip -d "$TMPDIR"/webview "$TMPDIR"/webview.zip > /dev/null
cp -rf "$TMPDIR"/webview/lib "$MODPATH"$APKPATH/
mv "$MODPATH"$APKPATH/lib/arm64-v8a "$MODPATH"$APKPATH/lib/arm64
mv "$MODPATH"$APKPATH/lib/armeabi-v7a "$MODPATH"$APKPATH/lib/arm
rm -rf "$TMPDIR"/webview "$TMPDIR"/webview.apk
ui_print "!!!!!!!!!!!!!!! VERY IMPORTANT PLEASE READ!!!!!!!!!!!!!!!!!"
ui_print "Reboot immediately after flashing or you may experience some issues! "
ui_print "Also, if you had any other webview such as Google webview, you may want to re-enable it"
UI_PRINT "but beware conflicts"
ui_print "Next boot may take significantly longer, we have to clear Dalvik cache here"
if test"${API}" == "29" ;
then
    ui_print "Android 10 detected"
		aapt p -f -v -M "$MODPATH"/common/overlay10/AndroidManifest.xml \
                -I /system/framework/framework-res.apk -S "$MODPATH"/common/overlay10/res \
                -F "$MODPATH"/unsigned.apk > "$MODPATH"/logs/aapt.log
else
	ui_print "Android version less than 10 detected"
	aapt p -f -v -M "$MODPATH"/common/overlay9/AndroidManifest.xml \
							-I /system/framework/framework-res.apk -S "$MODPATH"/common/overlay9/res \
							-F "$MODPATH"/unsigned.apk > "$MODPATH"/logs/aapt.log
fi
if [ -s "$MODPATH"/unsigned.apk ]; then
	sign "$MODPATH"/unsigned.apk "$MODPATH"/signed.apk
	cp -rf "$MODPATH"/signed.apk "$MODPATH"/common/WebviewOverlay.apk
	rm -rf "$MODPATH"/signed.apk "$MODPATH"/unsigned.apk
else
	ui_print "Overlay creation has failed! Some ROMs have this issue"
	ui_print "Compatibility cannot be gauraunteed, contact me on telegram to try to fix!"
fi
if [ -d /product/overlay ];
then
      mkdir -p "$MODPATH"/system/product/overlay
			cp_ch "$MODPATH"/common/WebviewOverlay.apk "$MODPATH"/system/product/overlay;
			echo "/product/overlay" > "$MODPATH"/overlay;
elif [ -d /vendor/overlay ]
then
	mkdir -p "$MODPATH"/system/vendor/overlay
	cp_ch "$MODPATH"/common/WebviewOverlay.apk "$MODPATH"/system/vendor/overlay;
	echo "/vendor/overlay" > "$MODPATH"/overlay;
elif [ -d /system/overlay ]
then
	mkdir -p "$MODPATH"/system/overlay
	cp_ch "$MODPATH"/common/WebviewOverlay.apk "$MODPATH"/system/overlay;
	echo "/system/overlay" > "$MODPATH"/overlay;
fi
ui_print "- Cleaning up..."
mkdir -p "$MODPATH"/apk
cp_ch /sdcard/bromite/"${ARCH}"_SystemWebView.apk "$MODPATH"/apk
rm -f "$MODPATH"/system/app/placeholder
mkdir -p /sdcard/bromite/logs
rm -f "$MODPATH"/*.md
ui_print "- Backing up important stuffs"
mkdir -p "$MODPATH"/backup/
cp /data/system/overlays.xml "$MODPATH"/backup/
ui_print "  
  / _ )  ____ ___   __ _   (_) / /_ ___                 
 / _  | / __// _ \ /  ' \ / / / __// -_)                
/____/ /_/   \___//_/_/_//_/  \__/ \__/                 
                                                        
   ____              __                __               
  / __/  __ __  ___ / /_ ___   __ _   / / ___   ___  ___
 _\ \   / // / (_-</ __// -_) /  ' \ / / / -_) (_-< (_-<
/___/   \_, / /___/\__/ \__/ /_/_/_//_/  \__/ /___//___/
       /___/                                            
  _      __        __          _                        
 | | /| / / ___   / /  _  __  (_) ___  _    __          
 | |/ |/ / / -_) / _ \| |/ / / / / -_)| |/|/ /          
 |__/|__/  \__/ /_.__/|___/ /_/  \__/ |__,__/           
                                                        "
ui_print "Enjoy a more private and faster webview, done systemlessly"
ui_print "Don't forget my links:"
ui_print "Social platforms:"
ui_print " https://t.me/alexiadev, https://discord.gg/gTnDxQ6"
ui_print "Donate at:"
ui_print " https://paypal.me/linuxandria"
ui_print " https://www.patreon.com/linuxandria_xda"
rm -rf /data/resource-cache/* /data/dalvik-cache/* /cache/dalvik-cache/* /data/*/com.android.webview* /data/system/package_cache/*
# Breaks, I mean, fixes up the service script
sed -i s/webview.apk/"$ARCH"_SystemWebView.apk/ig "$MODPATH"/service.sh

