# shellcheck shell=dash
# shellcheck disable=SC1091
# Pretty banner!
mkdir "$MODPATH"/logs
TRY_COUNT=0
VERSIONFILE='/sdcard/WebviewSwitcher/version'
alias aapt='"$MODPATH"/common/tools/aapt-"$ARCH"'
alias sign='"$MODPATH"/common/tools/zipsigner'
chmod -R 0755 "$MODPATH"/common/tools
setup_certs () {
	mkdir -p "$MODPATH"/system/etc/security
    if [ -f "/system/etc/security/ca-certificates.crt" ]; then
      cp -f /system/etc/security/ca-certificates.crt "$MODPATH"/ca-certificates.crt
    else
      for i in /system/etc/security/cacerts*/*.0; do
        sed -n "/BEGIN CERTIFICATE/,/END CERTIFICATE/p" "$i" >> "$MODPATH"/ca-certificates.crt
      done
    fi
	SEC=true
}
dl () {
	if ! $SEC
	then
		setup_certs
	fi
    "$MODPATH"/common/tools/aria2c-"$ARCH" -x 5 --async-dns  --check-certificate=false --ca-certificate="$MODPATH"/ca-certificates.crt --quiet "$@"
}
# Set up working directory
# Handle version upgrades
if test -f /sdcard/bromite
then
	ui_print "- Major version upgrade! Performing migration!"
	rm -rf /sdcard/bromite
fi
if test ! -d /sdcard/WebviewSwitcher
then
	mkdir -p /sdcard/WebviewSwitcher
fi
# Thanks SKittles9832 for the code I shamelessly copied :)
VEN=/system/vendor
[ -L /system/vendor ] && VEN=/vendor
if [ -f $VEN/build.prop ]
then
	export BUILDS="/system/build.prop $VEN/build.prop"
else
BUILDS="/system/build.prop"
fi
ui_print "- $ARCH SDK $API system detected, selecting the appropriate files"
set_config () {
	ui_print "- Setting configs..."
	ui_print "- Make sure if you want/need a custom setup to edit config.txt and reflash"
	if test -f /sdcard/WebviewSwitcher/config.txt
	then
		. /sdcard/WebviewSwitcher/config.txt
		if test $? -ne 0
		then
			ui_print "- Invalid config file! Using defaults"
			cp "$MODPATH"/config.txt /sdcard/WebviewSwitcher
			. /sdcard/WebviewSwitcher/config.txt
		fi
	else
		ui_print "- No config found, using defaults"
		cp "$MODPATH"/config.txt /sdcard/WebviewSwitcher
		. /sdcard/WebviewSwitcher/config.txt
	fi
	if "$UNGOOGLED"
	then
		ui_print "- Ungoogled chrome selected"
		BROMITE=false
		VANILLA=false
	fi
	if "$VANILLA"
	then
		ui_print "- Vanilla chromium selected"
		UNGOOGLED=false
		BROMITE=false
	fi
	if "$BROMITE"
	then
		ui_print "- Bromite selected"
		UNGOOGLED=false
		VANILLA=false
	else
		ui_print "- No valid choice selected, falling back to Bromite"
		BROMITE=true
		UNGOOGLED=false
		VANILLA=false
	fi
}
test_connection() {
  ui_print "- Testing internet connectivity"
  (ping -q -c 3 -W 1 bing.com >/dev/null 2>&1) && return 0 || return 1
}
check_version () {
# Set up version check
if [ ! -f /sdcard/WebviewSwitcher/version ];
then
	mktouch $VERSIONFILE
	echo "0" > $VERSIONFILE;
fi
	test_connection
	if test ${?} -eq "0" ;
	then
		if "$UNGOOGLED"
		then
			ui_print "- Checking for version upgrade...."
			VERSION2="$(wget -qO- "https://api.github.com/repos/ungoogled-software/ungoogled-chromium-android/releases/latest" | grep '"tag_name":' |  sed -E 's/.*"([^"]+)".*/\1/'    )"
		elif "$VANILLA"
		then
			ui_print "- Checking for version upgrade...."
			VERSION2="$(wget -qO- "https://api.github.com/repos/bromite/chromium/releases/latest" | grep '"tag_name":' |  sed -E 's/.*"([^"]+)".*/\1/'    )"
		else
			ui_print "- Checking for version upgrade...."
			VERSION2="$(wget -qO- "https://api.github.com/repos/bromite/bromite/releases/latest" | grep '"tag_name":' |  sed -E 's/.*"([^"]+)".*/\1/'    )"
		fi
	fi
}
it_failed () {
	# File wasn't found and all attempts to download failed
	if test ${TRY_COUNT} -ge "5" ;
	then
		ui_print " !!! WARNING !!!"
		ui_print " The installer detected a loop condition"
		ui_print " Under normal usage this should NEVER happen!"
		ui_print " This could mean you edited config.txt incorrectly, or there's something very wrong"
		ui_print " Like unstable internet, corrupt installer or files, etc"
		ui_print " !!! WARNING !!!"
	else
		ui_print " !!! WARNING !!!"
		ui_print " No capable apk was found, the files failed to download, or both!"
		ui_print " Check your internet and try again"
		ui_print " For offiline installs save the apk in /sdcard/WebviewSwitcher, set OFFLINE=true in config.txt, and retry"
		ui_print " !!! WARNING !!!"
	fi
	ui_print " Aborting!"
	abort 
}
set_url () {
	if $VANILLA
	then
		URL="https://github.com/bromite/chromium"
	elif $UNGOOGLED
	then
		URL="https://github.com/ungoogled-software/ungoogled-chromium-android"
	else
		URL="https://github.com/bromite/bromite" 
	fi
}
download_webview () {
	set_url
	check_version
	if test -z "$URL2"
	then
		URL2="$URL/releases/download/${VERSION2}/"
	fi
	if test -f /sdcard/WebviewSwitcher/"${ARCH}"_SystemWebView.apk
	then
		if $VANILLA
		then
			if [ "$(< "$VERSIONFILE" tr -d '.')" -lt "$(echo "$VERSION2" | tr -d '.')" ]
			then
				ui_print "- Downloading extra files please be patient..."
				dl "${URL2}${ARCH}_SystemWebView.apk" -d /sdcard/WebviewSwitcher/
				echo "$VERSION2" > "$VERSIONFILE"
			else
				ui_print "- Not a version upgrade! Using existing apk"
			fi
		elif $BROMITE
		then
			if [ "$(< "$VERSIONFILE" tr -d '.')" -lt "$(echo "$VERSION2" | tr -d '.')" ]
			then
				ui_print "- Downloading extra files please be patient..."
				dl "${URL2}${ARCH}_SystemWebView.apk" -d /sdcard/WebviewSwitcher/
				echo "$VERSION2" > "$VERSIONFILE"
			else
				ui_print "- Not a version upgrade! Using existing apk"
			fi
		elif $UNGOOGLED
		then
			if [ "$(< "$VERSIONFILE" tr -d '.')" -lt  "$(echo "$VERSION2" | tr -d '.')" ]
					then
                    	ui_print "- Downloading extra files please be patient..."
		        		dl "${URL2}SystemWebView.apk_${ARCH}.apk" -d /sdcard/WebviewSwitcher/
						mv /sdcard/WebviewSwitcher/SystemWebView_"${ARCH}".apk /sdcard/WebviewSwitcher/"${ARCH}"_SystemWebView.apk
						echo "$VERSION2" > "$VERSIONFILE"
				 fi
		fi
	fi
	if test ! -f /sdcard/WebviewSwitcher/"${ARCH}"_SystemWebView.apk
	then
		if $UNGOOGLED
			    then
                    	ui_print "- Downloading extra files please be patient..."
		        		dl "${URL2}SystemWebView.apk_${ARCH}.apk" -d /sdcard/WebviewSwitcher/
						mv /sdcard/WebviewSwitcher/SystemWebView_"${ARCH}".apk /sdcard/WebviewSwitcher/"${ARCH}"_SystemWebView.apk
						echo "$VERSION2" > "$VERSIONFILE"
		    else
			# If the file doesn't exist, let's attempt a download anyway
			dl "${URL2}${ARCH}_SystemWebView.apk" -d /sdcard/WebviewSwitcher/
			mv /sdcard/WebviewSwitcher/SystemWebview_"${ARCH}".apk /sdcard/WebviewSwitcher/"${ARCH}"_SystemWebView.apk
			echo "$VERSION2" > "$VERSIONFILE"
		fi
	fi
}
download_browser () {
	set_url
	check_version
	if test -z "$URL2"
	then
		URL2="$URL/releases/download/${VERSION2}/"
	fi
	if test -f /sdcard/WebviewSwitcher/"${ARCH}"_ChromePublic.apk
	then
		if $VANILLA
		then
			if [ "$(< "$VERSIONFILE" tr -d '.')" -lt "$(echo "$VERSION2" | tr -d '.')" ]
			then
				ui_print "- Downloading extra files please be patient..."
				dl "${URL2}${ARCH}_ChromePublic.apk" -d /sdcard/WebviewSwitcher/
				echo "$VERSION2" > "$VERSIONFILE"
			else
				ui_print "- Not a version upgrade! Using existing apk"
			fi
		elif $BROMITE
		then
			if [ "$(< "$VERSIONFILE" tr -d '.')" -lt "$(echo "$VERSION2" | tr -d '.')" ]
			then
				ui_print "- Downloading extra files please be patient..."
				dl "${URL2}${ARCH}_ChromePublic.apk" -d /sdcard/WebviewSwitcher/
				echo "$VERSION2" > "$VERSIONFILE"
			else
				ui_print "- Not a version upgrade! Using existing apk"
			fi
		elif $UNGOOGLED
		then
			if [ "$(< "$VERSIONFILE" tr -d '.')" -lt  "$(echo "$VERSION2" | tr -d '.')" ]
					then
                    	ui_print "- Downloading extra files please be patient..."
		        		dl "${URL2}ChromeModernPublic.apk_${ARCH}.apk" -d /sdcard/WebviewSwitcher/
						mv /sdcard/WebviewSwitcher/ChromeModernPublic_"${ARCH}".apk /sdcard/WebviewSwitcher/"${ARCH}"_ChromePublic.apk
						echo "$VERSION2" > "$VERSIONFILE"
				 fi
		fi
	fi
	if test ! -f /sdcard/WebviewSwitcher/"${ARCH}"_ChromePublic.apk
	then
		if $UNGOOGLED
			    then
                    	ui_print "- Downloading extra files please be patient..."
		        		dl "${URL2}ChromeModernPublic_${ARCH}.apk" -d /sdcard/WebviewSwitcher/
						mv /sdcard/WebviewSwitcher/ChromeModernPublic_"${ARCH}".apk /sdcard/WebviewSwitcher/"${ARCH}"_ChromePublic.apk
						echo "$VERSION2" > "$VERSIONFILE"
		    else
			# If the file doesn't exist, let's attempt a download anyway
			dl "${URL2}${ARCH}_ChromePublic.apk" -d /sdcard/WebviewSwitcher/
			# mv /sdcard/WebviewSwitcher/SystemWebview_${ARCH}.apk /sdcard/WebviewSwitcher/${ARCH}_SystemWebView.apk
			echo "$VERSION2" > "$VERSIONFILE"
		fi
	fi
}
verify_webview () {
	ui_print " Verifying files..."
	if $VANILLA
	then
		wget -qO  "$TMPDIR"/"$ARCH"_SystemWebView.apk.sha256.txt "$URL"/releases/download/"$VERSION2"/chr_"$VERSION2".sha256.txt
		cd /sdcard/WebviewSwitcher || return
		grep "$ARCH"_SystemWebView.apk "$TMPDIR"/"$ARCH"_SystemWebView.apk.sha256.txt > /sdcard/WebviewSwitcher/"$ARCH"_SystemWebView.apk.sha256.txt 
		sha256sum -sc /sdcard/WebviewSwitcher/"$ARCH"_SystemWebview.apk.sha256.txt 
		if test $? -ne 0 ;
		then
			ui_print " Verification failed, retrying download"
			rm -f /sdcard/WebviewSwitcher/"${ARCH}"_SystemWebView.apk
			TRY_COUNT=$((TRY_COUNT + 1))
			if test ${TRY_COUNT} -ge 5;
			then
				it_failed ;
			else
				download_start
				verify_webview ;
		fi
	else
	ui_print " Verified successfully. Proceeding..."
	cd - || return
	fi
	elif $UNGOOGLED
		then
			ui_print "- Verifying Ungoogled Chromium is not implemented!"
	else
		wget -qO "$TMPDIR"/"$ARCH"_SystemWebView.apk.sha256.txt "$URL"/releases/download/"$VERSION2"/brm_"$VERSION2".sha256.txt
		cd /sdcard/WebviewSwitcher || return
		grep "$ARCH"_SystemWebView.apk "$TMPDIR"/"$ARCH"_SystemWebView.apk.sha256.txt > /sdcard/WebviewSwitcher/"$ARCH"_SystemWebView.apk.sha256.txt 
		sha256sum -sc /sdcard/WebviewSwitcher/"$ARCH"_SystemWebview.apk.sha256.txt 
		if test $? -ne 0 ;
		then
			ui_print " Verification failed, retrying download"
			rm -f /sdcard/WebviewSwitcher/"${ARCH}"_SystemWebView.apk
			TRY_COUNT=$((TRY_COUNT + 1))
			if test ${TRY_COUNT} -ge 3 ;
			then
				it_failed ;
			else
				download_webview
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
OLP=/system/product/overlay
elif [ -d /vendor/overlay ]
then
OLP=/system/vendor/overlay
elif [ -d /system/overlay ]
then
OLP=/system/overlay
fi
mkdir -p "$MODPATH""$OLP"
cp_ch "$MODPATH"/common/WebviewOverlay.apk "$MODPATH""$OLP";
echo "$OLP" > "$MODPATH"/overlay;

}
set_path() {
	unset APKPATH
	paths=$(cmd package dump com.android.webview | grep codePath); APKPATH=${paths##*=}
	[ -z "${APKPATH}" ] && paths=$(cmd package dump com.google.android.webview | grep codePath); APKPATH=${paths##*=}
	[ -z "${APKPATH}" ] && APKPATH="/system/app/webview"
	paths=$(cmd package dump com.android.chrome | grep codePath); APKPATH2=${paths##*=}
	[ -z "${APKPATH2}" ] && APKPATH2="/system/app/Chrome"
}
extract_apk () {
	ui_print "- Installing Webview"
	cp_ch /data/media/0/WebviewSwitcher/"${ARCH}"_SystemWebView.apk "$MODPATH"$APKPATH/webview.apk
	cp_ch /data/media/0/WebviewSwitcher/"${ARCH}"_SystemWebView.apk "$MODPATH"/apk/webview.apk
	touch "$MODPATH"$APKPATH/.replace
	cp "$MODPATH"$APKPATH/webview.apk "$TMPDIR"/webview.zip 
	mkdir "$TMPDIR"/webview -p	
	unzip -d "$TMPDIR"/webview "$TMPDIR"/webview.zip > /dev/null
	cp -rf "$TMPDIR"/webview/lib "$MODPATH"$APKPATH/
	mv "$MODPATH"$APKPATH/lib/arm64-v8a "$MODPATH"$APKPATH/lib/arm64
	mv "$MODPATH"$APKPATH/lib/armeabi-v7a "$MODPATH"$APKPATH/lib/arm
	rm -rf "$TMPDIR"/webview "$TMPDIR"/webview.zip
  if "$BROWSER"
  then
	ui_print "- Installing Browser"
    mkdir -p "$MODPATH"$APKPATH2
    touch "$MODPATH"$APKPATH2/.replace
    cp_ch /data/media/0/WebviewSwitcher/"${ARCH}"_ChromePublic.apk "$MODPATH"$APKPATH2/Chrome.apk
	cp_ch /data/media/0/WebviewSwitcher/"${ARCH}"_ChromePublic.apk "$MODPATH"/apk/browser.apk
  	touch "$MODPATH"$APKPATH2/.replace
  	cp_ch "$MODPATH"/system/app/Chrome/Chrome.apk "$TMPDIR"/browser.zip 
  	mkdir -p "$TMPDIR"/browser
  	unzip -d "$TMPDIR"/browser "$TMPDIR"/browser.zip > /dev/null
	cp -rf "$TMPDIR"/browser/lib "$MODPATH"$APKPATH2
  	mv "$MODPATH"/system/app/Chrome/lib/arm64-v8a "$MODPATH"$APKPATH2/lib/arm64
  	mv "$MODPATH"$APKPATH/lib/armeabi-v7a "$MODPATH"$APKPATH2/lib/arm
  	rm -rf "$TMPDIR"/browser "$TMPDIR"/browser.zip
  fi

}
online_install() {
	ui_print "- Awesome, you have internet"
	set_url
	download_webview
	if $BROWSER
	then
            download_browser
    fi
	verify_webview
	set_path
	extract_apk 
	create_overlay ;
}
offline_install() {
if test ! -f /sdcard/WebviewSwitcher/"${ARCH}"_SystemWebView.apk ;
then
	it_failed ;
else
	ui_print "- Checksum verification not implemented for offline install"
fi
	ui_print "- Proceeding with offline method"
	set_path 
	extract_apk
	create_overlay ;
}
do_install () {
  set_config
  	if $OFFLINE
	then
		offline_install 
		do_cleanup ;
	fi
	if test ! "$BOOTMODE"
	then
		ui_print "- Detected recovery install! Falling back to offline install!"
		ui_print "- Please note you may encounter issues with this method"
		recovery_actions
		offline_install
		recovery_cleanup
		do_cleanup ;
	fi
	test_connection
	if test $? -ne 0 ;
	then
		ui_print "- No internet detcted, attempting offline install"
		offline_install 
		do_cleanup ;
	else
		if test ${TRY_COUNT} -ge 5 
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
	cp_ch /sdcard/WebviewSwitcher/"${ARCH}"_SystemWebView.apk "$MODPATH"/apk
	rm -f "$MODPATH"/system/app/placeholder
	mkdir -p /sdcard/WebviewSwitcher/logs
	rm -f "$MODPATH"/*.md
	ui_print "- Backing up important stuffs to module directory"
	mkdir -p "$MODPATH"/backup/
	cp /data/system/overlays.xml "$MODPATH"/backup/
	clean_dalvik
}
if test ${TRY_COUNT} -ge "5" ;
then
	it_failed ;
else
	do_install 
	do_cleanup ;
fi
ui_print "  VERY IMPORTANT PLEASE READ"
ui_print " Reboot immediately after flashing or you may experience some issues! "
ui_print " Also, if you had any other webview such as Google webview, it's gone"
ui_print " You can reinstall but beware conflicts"
ui_print " Next boot may take significantly longer, we have to clear Dalvik cache here"
sleep 1
ui_print " Enjoy a more private and faster webview, done systemlessly"
ui_print " Don't forget my links:"
sleep 0.5
ui_print " Social platforms:"
ui_print "	https://t.me/unixandria_dev, https://discord.gg/gTnDxQ6"
sleep 0.5
ui_print " Donate at:"
ui_print "	https://paypal.me/linuxandria"
ui_print "	https://www.patreon.com/linuxandria_xda"
ui_print " Website is at https://www.linuxandria.com"
ui_print " You can support me by checking out my site with adblock disabled."
sleep 0.5
ui_print "- All commands ran successfully please reboot"
ui_print " "

