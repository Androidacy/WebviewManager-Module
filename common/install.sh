# shellcheck shell=dash
mkdir "$MODPATH"/logs
TRY_COUNT=0
VERSIONFILE='/sdcard/bromite/version'
alias aapt='"$MODPATH"/common/tools/aapt-"$ARCH"'
alias sign='"$MODPATH"/common/tools/zipsigner'
alias ping='$MODPATH/common/tools/busybox-$ARCH-selinux ping'
alias wget='$MODPATH/common/tools/busybox-$ARCH-selinux wget'
chmod -R 0755 "$MODPATH"/common/tools
if test ! -d /sdcard/bromite ;
then
	mkdir -p /sdcard/bromite ;
fi
# Thanks SKittles9832 for the code I shamelessly copied :)
VEN=/system/vendor
[ -L /system/vendor ] && VEN=/vendor
if [ -f $VEN/build.prop ]; then export BUILDS="/system/build.prop $VEN/build.prop"; else BUILDS="/system/build.prop"; fi
ui_print "- $ARCH SDK $API system detected, selecting the appropriate files"
get_config () {
	. "$MODPATH"/config.txt
}
test_connection() {
  ui_print "- Testing internet connectivity"
  (ping -4 -q -c 1 -W 1 bing.com >/dev/null 2>&1) && return 0 || return 1
}
check_version () {
# Set up version check
if [ ! -f /sdcard/bromite/version ];
then
	mktouch $VERSIONFILE
	echo "0" > $VERSIONFILE;
fi
	test_connection
	if test ${?} -eq "0" ;
	then
		if test "$UNGOOGLED" == "1"
		then
			ui_print "- Version check for ungoogled-chromium not implemented, downloading the version set in the module"
		elif test "$VANILLA" == "1"
		then
			VERSION="$(wget -qO- "https://api.github.com/repos/bromite/chromium/releases/latest" |   grep '"tag_name":' |  sed -E 's/.*"([^"]+)".*/\1/')"
			echo "$VERSION" > $VERSIONFILE
		else
			VERSION="$(wget -qO- "https://api.github.com/repos/bromite/bromite/releases/latest" |   grep '"tag_name":' |  sed -E 's/.*"([^"]+)".*/\1/')"
			echo "$VERSION" > $VERSIONFILE
		fi
	else
		VERSION="$(cat $VERSIONFILE)"
	fi
}
# Handle version upgrades
rm -rf /sdcard/bromite/webview.apk
it_failed () {
	# File wasn't found and all attempts to download failed
	ui_print " Uh-oh a problem occurred."
	if test ${TRY_COUNT} -ge "3" ;
	then
		ui_print " WARNING! Loop scenario detected!"
		ui_print " Under normal usage this should NEVER happen!"
	else
		ui_print " No capable apk was found, the files failed to download, or both!"
		ui_print " Check your internet and try again"
		ui_print " For offiline installs save the apk in /sdcard/bromite and retry"
	fi
	ui_print " Aborting!"
	abort 
}
set_url () {
	if "$VANILLA" == "1";
	then
		URL="https://github.com/bromite/chromium"
	elif "$UNGOOGLED" == "1"
	then
		if "$ARCH" == "arm64"
		then
			URL2="https://git.droidware.info/attachments/18caf284-8eb3-4385-83b8-57576d3c8951"
		elif "$ARCH" == "arm"
		then
			URL2="https://git.droidware.info/attachments/332e6f8a-4020-46b9-bb6d-75e888291bb2"
		elif "$ARCH" == "x86" or "x86_64"
		then
			URL2="https://git.droidware.info/attachments/479c91fa-7de1-4746-9292-46c2d0374dab"
		fi
	else
		URL="https://github.com/bromite/bromite"
	fi
}
download_start () {
	set_url
	check_version
	ui_print "- Downloading extra files please be patient..."
	if test -z $URL2
	then
		URL2="$URL/releases/download/${VERSION}/${ARCH}_"
	fi

	if [ -f /sdcard/bromite/"${ARCH}"_SystemWebView.apk ] ;
	then
		if test "$VANILLA" == "1" or "$BROMITE" == "1"
		then
			if [ "$(< "$VERSIONFILE" tr -d '.')" -lt "$(echo "$VERSION" | tr -d '.')" ];
			then
				wget -qO /sdcard/bromite/"${ARCH}"_SystemWebView.apk "${URL2}SystemWebView.apk"
			fi
		else
			wget -qO /sdcard/bromite/"${ARCH}"_SystemWebView.apk "${URL2}"
		fi
	else
		# If the file doesn't exist, let's attempt a download anyway
		wget -qO /sdcard/bromite/"${ARCH}"_SystemWebView.apk "$URL2" ;
	fi

	if test "$BROWSER" == "1"
	then
		wget -qO /sdcard/bromite/"$ARCH"_ChromePublic.apk "${URL2}ChromePublic.apk"
	fi
}
verify_webview () {
	ui_print " Verifying files..."
	if test "$VANILLA" == "1"
	then
		wget -qO "$TMPDIR"/"$ARCH"_SystemWebView.apk.sha256.txt "$URL"/releases/download/"$VERSION"/chr_"$VERSION".sha256.txt
		cd /sdcard/bromite || return
		grep "$ARCH"_SystemWebView.apk "$TMPDIR"/"$ARCH"_SystemWebView.apk.sha256.txt > /sdcard/bromite/"$ARCH"_SystemWebView.apk.sha256.txt 
		sha256sum -sc /sdcard/bromite/"$ARCH"_SystemWebview.apk.sha256.txt 
		if test $? -ne 0 ;
		then
			ui_print " Verification failed, retrying download"
			rm -f /sdcard/bromite/"${ARCH}"_SystemWebView.apk
			TRY_COUNT=$((TRY_COUNT + 1))
			if test ${TRY_COUNT} -ge 3 ;
			then
				it_failed ;
			else
				download_start
				verify_webview ;
		fi
	else
	ui_print " Verified successfully. Proceeding..."
	fi
	cd - || return >/dev/null
	elif test "$UNGOOGLED" == "1"
	then
		ui_print "- Verifying Ungoogled Chromium is not implemented!"
	else
		wget -qO "$TMPDIR"/"$ARCH"_SystemWebView.apk.sha256.txt "$URL"/releases/download/"$VERSION"/brm_"$VERSION".sha256.txt
		cd /sdcard/bromite || return
		grep "$ARCH"_SystemWebView.apk "$TMPDIR"/"$ARCH"_SystemWebView.apk.sha256.txt > /sdcard/bromite/"$ARCH"_SystemWebView.apk.sha256.txt 
		sha256sum -sc /sdcard/bromite/"$ARCH"_SystemWebview.apk.sha256.txt 
		if test $? -ne 0 ;
		then
			ui_print " Verification failed, retrying download"
			rm -f /sdcard/bromite/"${ARCH}"_SystemWebView.apk
			TRY_COUNT=$((TRY_COUNT + 1))
			if test ${TRY_COUNT} -ge 3 ;
			then
				it_failed ;
			else
				download_start
				verify_webview ;
		fi
		else
			ui_print " Verified successfully. Proceeding..."
		fi
		cd - || return >/dev/null
	fi
}
create_overlay () {
if test  "${API}" -ge "29" ;
then
    ui_print " Android 10 or later detected"
		aapt p -f -v -M "$MODPATH"/common/overlay10/AndroidManifest.xml \
                -I /system/framework/framework-res.apk -S "$MODPATH"/common/overlay10/res \
                -F "$MODPATH"/unsigned.apk > "$MODPATH"/logs/aapt.log
else
	ui_print " Android version less than 10 detected"
	aapt p -f -v -M "$MODPATH"/common/overlay9/AndroidManifest.xml \
							-I /system/framework/framework-res.apk -S "$MODPATH"/common/overlay9/res \
							-F "$MODPATH"/unsigned.apk > "$MODPATH"/logs/aapt.log
fi
if [ -s "$MODPATH"/unsigned.apk ]; then
	sign "$MODPATH"/unsigned.apk "$MODPATH"/signed.apk
	cp -rf "$MODPATH"/signed.apk "$MODPATH"/common/WebviewOverlay.apk
	rm -rf "$MODPATH"/signed.apk "$MODPATH"/unsigned.apk
else
	ui_print " Overlay creation has failed! Some ROMs have this issue"
	ui_print " Compatibility cannot be gauraunteed, contact me on telegram to try to fix!"
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
}
set_path() {
	unset APKPATH
	paths=$(cmd package dump com.android.webview | grep codePath); APKPATH=${paths##*=}
	[ -z "${APKPATH}" ] && paths=$(cmd package dump com.google.android.webview | grep codePath); APKPATH=${paths##*=}
	[ -z "${APKPATH}" ] && paths=$(cmd package dump com.android.webview | grep codePath); APKPATH=${paths##*=}
	[ -z "${APKPATH}" ] && APKPATH="/system/app/webview"
}
extract_apk () {
	ui_print "- Extracting downloaded file"
	cp_ch /data/media/0/bromite/"${ARCH}"_SystemWebView.apk "$MODPATH"$APKPATH/webview.apk
	touch "$MODPATH"$APKPATH/.replace
	cp "$MODPATH"$APKPATH/webview.apk "$TMPDIR"/webview.zip 
	mkdir "$TMPDIR"/webview -p	
	unzip -d "$TMPDIR"/webview "$TMPDIR"/webview.zip > /dev/null
	cp -rf "$TMPDIR"/webview/lib "$MODPATH"$APKPATH/
	mv "$MODPATH"$APKPATH/lib/arm64-v8a "$MODPATH"$APKPATH/lib/arm64
	mv "$MODPATH"$APKPATH/lib/armeabi-v7a "$MODPATH"$APKPATH/lib/arm
	rm -rf "$TMPDIR"/webview "$TMPDIR"/webview.apk
}
online_install() {
	ui_print "- Awesome, you have internet"
	set_url
	download_start
	verify_webview
	set_path
	extract_apk 
	create_overlay ;
}
offline_install() {
if test ! -f /sdcard/bromite/"${ARCH}"_SystemWebView.apk ;
then
	it_failed ;
else
	# File was found, lets go
	# Try to verify the file if we previously had a sha256
	if test -f /sdcard/bromite/"$ARCH"_SystemWebView.apk.sha256.txt ;
	then
		sha256sum -sc /sdcard/bromite/"$ARCH"_SystemWebview.apk.sha256.txt
		if test $? -ne 0 ;
		then
			it_failed ;
		fi
	fi
	ui_print "- No internet detected, proceeding with offline method"
	set_path 
	extract_apk
	create_overlay ;
fi
}
do_install () {
	if test ! "$BOOTMODE";
	then
		ui_print " - Detected recovery install! Falling back to offline install!"
		recovery_actions
		offline_install
		recovery_cleanup
		do_cleanup ;
	fi
	if test "$OFFLINE" == "1"
	then
		offline_install 
		do_cleanup ;
	fi
	test_connection
	if test $? -ne 0 ;
	then
		offline_install 
		do_cleanup ;
	else
		if test ${TRY_COUNT} -ge 3 ;
		then
			it_failed ;
		else
			online_install ;
		fi
	fi
}
clean_dalvik () {
	# Removes dalvik cache to re-register our overlay and webview
	rm -rf /data/resource-cache/* /data/dalvik-cache/* /cache/dalvik-cache/* /data/*/com.android.webview* /data/system/package_cache/*
}
do_cleanup () {
	ui_print "- Cleaning up..."
	mkdir -p "$MODPATH"/apk
	cp_ch /sdcard/bromite/"${ARCH}"_SystemWebView.apk "$MODPATH"/apk
	rm -f "$MODPATH"/system/app/placeholder
	mkdir -p /sdcard/bromite/logs
	rm -f "$MODPATH"/*.md
	ui_print "- Backing up important stuffs to module directory"
	mkdir -p "$MODPATH"/backup/
	cp /data/system/overlays.xml "$MODPATH"/backup/
	clean_dalvik
}

if test ${TRY_COUNT} -ge "3" ;
		then
			it_failed ;
		else
			do_install 
			do_cleanup ;
		fi
ui_print " !!!!!!!!!!!!!!! VERY IMPORTANT PLEASE READ !!!!!!!!!!!!!!!!!"
ui_print " Reboot immediately after flashing or you may experience some issues! "
ui_print " Also, if you had any other webview such as Google webview, you may re-enable"
ui_print " But beware conflicts"
ui_print " Next boot may take significantly longer, we have to clear Dalvik cache here"
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
ui_print " Enjoy a more private and faster webview, done systemlessly"
ui_print " Don't forget my links:"
ui_print " Social platforms:"
ui_print "  https://t.me/alexiadev, https://discord.gg/gTnDxQ6"
ui_print " Donate at:"
ui_print "  https://paypal.me/linuxandria"
ui_print "  https://www.patreon.com/linuxandria_xda"
# Breaks, I mean, fixes up the service script
sed -i s/webview.apk/"$ARCH"_SystemWebView.apk/ig "$MODPATH"/service.sh

ui_print "- All commands ran successfully please reboot"
ui_print " "

