# shellcheck shell=dash
# shellcheck disable=SC1091
# shellcheck disable=SC1090
mkdir "$MODPATH"/logs
TRY_COUNT=0
detect_ext_data () {
	touch /sdcard/.rw && rm /sdcard/.rw && EXT_DATA="/sdcard"
	if test -z ${EXT_DATA}
	then
		touch /storage/emulated/0/.rw && rm /storage/emulated/0/.rw && EXT_DATA="/storage/emulated/0"
	fi
	if test -z ${EXT_DATA}
	then
		touch /data/media/0/.rw && rm /data/media/0/.rw && EXT_DATA="/data/media/0"
	fi
	if test -z ${EXT_DATA}
	then
		ui_print " Data check failed, bailing out!"
		it_failed
	fi
}
detect_ext_data
VERSIONFILE="${EXT_DATA}/WebviewSwitcher/version.txt"
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
	SEC="true"
}
dl () {
	if ! $SEC
	then
		setup_certs
	fi
    "$MODPATH"/common/tools/aria2c-"$ARCH" -x 16 -s 16 --async-dns --file-allocation=none --check-certificate=false --ca-certificate="$MODPATH"/ca-certificates.crt --quiet "$@"
}
if test -f ${EXT_DATA}/bromite
then
	ui_print "- Major version upgrade! Performing migration!"
	rm -rf ${EXT_DATA}/bromite
fi
if test ! -d ${EXT_DATA}/WebviewSwitcher
then
	mkdir -p ${EXT_DATA}/WebviewSwitcher
fi
# magiskpolicy --live "allow system_server untrusted_app_25_devpts chr_file { read write }"
magiskpolicy --live "allow system_server sdcardfs file { read write }"
magiskpolicy --live "allow zygote adb_data_file file getattr"
VEN=/system/vendor
[ -L /system/vendor ] && VEN=/vendor
if [ -f $VEN/build.prop ]
then
	export BUILDS="/system/build.prop $VEN/build.prop"
else
BUILDS="/system/build.prop"
fi
ui_print "- $ARCH SDK $API system detected, selecting the appropriate files"
check_config () {
	$BROWSER && $WEBVIEW 
	if test $? -eq 127
	then
		ui_print "- Invalid config - syntax error! Using defaults" 
		cp "$MODPATH"/config.txt ${EXT_DATA}/WebviewSwitcher
		. ${EXT_DATA}/WebviewSwitcher/config.txt
	fi
	if ! $BROWSER && ! $WEBVIEW
	then
		ui_print "- Invalid config - neither WEBVIEW nor BROWSER is set to true! Using defaults" 
		cp "$MODPATH"/config.txt ${EXT_DATA}/WebviewSwitcher
		. ${EXT_DATA}/WebviewSwitcher/config.txt
	elif test -z "$WHICH"
	then
		ui_print "- Invalid config value for WHICH! Using defaults"
		cp "$MODPATH"/config.txt ${EXT_DATA}/WebviewSwitcher
		. ${EXT_DATA}/WebviewSwitcher/config.txt
	elif test "$WHICH" -ne 0 && test "$WHICH" -ne 1 && test "$WHICH" -ne 2 && test "$WHICH" -ne 3
	then
		ui_print "- Invalid config value for WHICH! Using defaults"
		cp "$MODPATH"/config.txt ${EXT_DATA}/WebviewSwitcher
		. ${EXT_DATA}/WebviewSwitcher/config.txt
	fi
}
set_config () {
	ui_print "- Setting configs..."
	if test -f ${EXT_DATA}/WebviewSwitcher/config.txt
	then
		. ${EXT_DATA}/WebviewSwitcher/config.txt
		if test $? -ne 0
		then
			ui_print "- Invalid config file! Using defaults"
			cp "$MODPATH"/config.txt ${EXT_DATA}/WebviewSwitcher
			. ${EXT_DATA}/WebviewSwitcher/config.txt
		else
			check_config
		fi
	else
		ui_print "- No config found, using defaults"
		ui_print "- Make sure if you want/need a custom setup to edit config.txt"
		cp "$MODPATH"/config.txt ${EXT_DATA}/WebviewSwitcher
		. ${EXT_DATA}/WebviewSwitcher/config.txt
	fi
}
test_connection() {
  ui_print "- Testing internet connectivity"
  (ping -q -c 2 -W 1 www.androidacy.com >/dev/null 2>&1) && return 0 || return 1
}
do_ungoogled () {
	NAME="Ungoogled-Chromium"
	SUM_PRE="not_implemented"
	if "$EXTENSIONS"
	then
		BROWSER_VER="$(wget -qO- https://api.github.com/repos/ungoogled-software/ungoogled-chromium-android/releases | grep -v webview | grep extensions | grep '"tag_name"' | head -1|  sed -E 's/.*"([^"]+)".*/\1/')"
	else
		BROWSER_VER="$(wget -qO- https://api.github.com/repos/ungoogled-software/ungoogled-chromium-android/releases | grep -v webview | grep -v extensions | grep '"tag_name"' | head -1|  sed -E 's/.*"([^"]+)".*/\1/' )"
	fi
	BROWSER_FILE="/ChromeModernPublic_${ARCH}.apk"
	WEBVIEW_FILE="/SystemWebView_${ARCH}.apk"
	WEBVIEW_VER="$(wget -qO- https://api.github.com/repos/ungoogled-software/ungoogled-chromium-android/releases | grep webview | grep '"tag_name"' | head -1|  sed -E 's/.*"([^"]+)".*/\1/')"
	DL_URL="https://github.com/ungoogled-software/ungoogled-chromium-android/releases/download/"
}
do_vanilla () {
	NAME="Chromium"
	SUM_PRE="chrm"
	WEBVIEW_VER="$(wget -qO- https://api.github.com/repos/bromite/chromium/releases/latest | grep '"tag_name":' | sed -E 's/.*"([^"]+)".*/\1/')"
	BROWSER_VER="$(wget -qO- https://api.github.com/repos/bromite/chromium/releases/latest | grep '"tag_name":' | sed -E 's/.*"([^"]+)".*/\1/')"
	BROWSER_FILE="/${ARCH}_ChromePublic.apk"
	WEBVIEW_FILE="/${ARCH}_SystemWebView.apk"
	DL_URL="https://github.com/bromite/chromium/releases/download/"
}
do_bromite () {
	NAME="Bromite"
	SUM_PRE="brm"
	WEBVIEW_VER="$(wget -qO- https://api.github.com/repos/bromite/bromite/releases/latest | grep '"tag_name":' | sed -E 's/.*"([^"]+)".*/\1/')"
	BROWSER_VER="$(wget -qO- https://api.github.com/repos/bromite/bromite/releases/latest | grep '"tag_name":' | sed -E 's/.*"([^"]+)".*/\1/')"
	BROWSER_FILE="/${ARCH}_ChromePublic.apk"
	WEBVIEW_FILE="/${ARCH}_SystemWebView.apk"
	DL_URL="https://github.com/bromite/bromite/releases/download/" 
}
old_version () {
	ui_print "- Checking whether this is a new install...."
	if test ! -f ${EXT_DATA}/WebviewSwitcher/version.txt
	then
		echo "OLD_BROWSER=0" > $VERSIONFILE
		echo "OLD_WEBVIEW=0" >> $VERSIONFILE
		. ${EXT_DATA}/WebviewSwitcher/version.txt
	else
		. ${EXT_DATA}/WebviewSwitcher/version.txt
		if $? -ne 0
		then
			echo "OLD_BROWSER=0" > $VERSIONFILE
			echo "OLD_WEBVIEW=0" >> $VERSIONFILE
			. ${EXT_DATA}/WebviewSwitcher/version.txt
		fi
	fi
}
it_failed () {
	# File wasn't found and all attempts to download failed
		ui_print " "
		ui_print "⚠⚠⚠⚠⚠⚠⚠⚠⚠⚠⚠⚠⚠⚠⚠⚠⚠⚠⚠⚠⚠⚠⚠⚠⚠⚠"
		ui_print " "
		ui_print " Uh-oh, the installer encountered an issue!"
		ui_print " It's probably one of these reasons:"
		ui_print "	 1) Installer is corrupt"
		ui_print "	 2) You didn't follow instructions"
		ui_print "	 3) You have an unstable internet connection"
		ui_print "	 4) Your ROM is broken"
		ui_print "	 5) There's a *tiny* chance we screwed up"
		ui_print " Please fix any issues and retry."
		ui_print " If you feel this is a bug or need assistance, head to our telegram"
		mv ${EXT_DATA}/WebviewSwitcher/logs ${EXT_DATA}
		rm -rf ${EXT_DATA}/WebviewSwitcher/*
		mv ${EXT_DATA}/logs ${EXT_DATA}/WebviewSwitcher/
		ui_print " "
		ui_print "⚠⚠⚠⚠⚠⚠⚠⚠⚠⚠⚠⚠⚠⚠⚠⚠⚠⚠⚠⚠⚠⚠⚠⚠⚠⚠"
		ui_print " "
		abort
}
download_webview () {
	if test -f ${EXT_DATA}/WebviewSwitcher/webview_"$NAME".apk
	then
		if test "$OLD_WEBVIEW" -lt "$(echo "$WEBVIEW_VER"|sed 's/[^0-9]*//g')"
		then
			ui_print "- Downloading update for ${NAME} webview, please be patient..."
			dl $DL_URL"$WEBVIEW_VER""$WEBVIEW_FILE" -o "$EXT_DATA"/WebviewSwitcher/webview_"$NAME".apk
			sed -i "/OLD_WEBVIEW/d" "$VERSIONFILE"
			echo "OLD_WEBVIEW=$(echo "$WEBVIEW_VER"|sed 's/[^0-9]*//g')" >> "$VERSIONFILE"
			verify_webview
		else
			ui_print "- Not a version upgrade! Using existing ${NAME} webview apk"
		fi
	else
		ui_print "- No existing apk found for ${NAME} webview!"
		ui_print "- Downloading ${NAME} webview, please be patient..."
		dl $DL_URL"$WEBVIEW_VER""$WEBVIEW_FILE" -o "$EXT_DATA"/WebviewSwitcher/webview_"$NAME".apk 
		sed -i "/OLD_WEBVIEW/d" "$VERSIONFILE"
		echo "OLD_WEBVIEW=$(echo "$WEBVIEW_VER"|sed 's/[^0-9]*//g')" >> "$VERSIONFILE"
		verify_webview
	fi
	
}
download_browser () {
	if test -f ${EXT_DATA}/WebviewSwitcher/browser_"$NAME".apk
	then
		if test "$OLD_BROWSER" -lt "$(echo "$BROWSER_VER"|sed 's/[^0-9]*//g')"
		then
			ui_print "- Downloading update for ${NAME} browser, please be patient..."
			dl $DL_URL"$BROWSER_VER""$BROWSER_FILE" -o "$EXT_DATA"/WebviewSwitcher/browser_"$NAME".apk
			sed -i "/OLD_BROWSER/d" "$VERSIONFILE"
			echo "OLD_BROWSER=$(echo "$BROWSER_VER"|sed 's/[^0-9]*//g')" >> "$VERSIONFILE"
		else
			ui_print "- Not a version upgrade! Using existing ${NAME} browser apk"
		fi
	else
		ui_print "- No existing apk found for ${NAME} browser!"
		ui_print "- Downloading ${NAME} browser, please be patient..."
		dl $DL_URL"$BROWSER_VER""$BROWSER_FILE" -o "$EXT_DATA"/WebviewSwitcher/browser_"$NAME".apk
		sed -i "/OLD_BROWSER/d" "$VERSIONFILE"
		echo "OLD_BROWSER=$(echo "$BROWSER_VER"|sed 's/[^0-9]*//g')" >> "$VERSIONFILE"
	fi
}
verify_webview () {
	ui_print " Verifying files..."
	if test $SUM_PRE != "not_implemented"
	then
		cd "${EXT_DATA}"/WebviewSwitcher
		wget -qO "$ARCH"_SystemWebView.apk.sha256.txt ${DL_URL}"${WEBVIEW_VER}"/${SUM_PRE}_"${WEBVIEW_VER}".sha256.txt
		cp ${EXT_DATA}/WebviewSwitcher/webview_"$NAME".apk "${ARCH}"_SystemWebView.apk
		grep "$ARCH"_SystemWebView.apk "$ARCH"_SystemWebView.apk.sha256.txt > webview_"$NAME".apk.sha256.txt
		rm "$ARCH"_SystemWebView.apk.sha256.txt
		sed "s|${ARCH}_SystemWebView|webview|" webview_"$NAME".apk.sha256.txt
		sha256sum -sc webview_"$NAME".apk.sha256.txt 
		if test $? -ne 0
		then
			ui_print " Verification failed, retrying download"
			rm -f ${EXT_DATA}/WebviewSwitcher/*webview*.apk
			TRY_COUNT=$((TRY_COUNT + 1))
			if test ${TRY_COUNT} -ge 3;
			then
				it_failed
			else
				cd  "$TMPDIR"
				download_webview
			fi
		else
			ui_print " Verified successfully. Proceeding..."
		fi
	else
		ui_print "- ${NAME} cannot be verified, as they don't publish sha256sums."
	fi
	cd "$TMPDIR"
}
create_overlay () {
	cd "$TMPDIR"
	if test  "${API}" -ge "29" ;
	then
	    ui_print "- Android 10 or later detected"
		aapt p -f -v -M "$MODPATH"/common/overlay10/AndroidManifest.xml \
    	            -I /system/framework/framework-res.apk -S "$MODPATH"/common/overlay10/res \
    	            -F "$MODPATH"/unsigned.apk > "$MODPATH"/logs/aapt.log
	else
		ui_print "- Android version less than 10 detected"
		aapt p -f -v -M "$MODPATH"/common/overlay9/AndroidManifest.xml \
								-I /system/framework/framework-res.apk -S "$MODPATH"/common/overlay9/res \
								-F "$MODPATH"/unsigned.apk > "$MODPATH"/logs/aapt.log
	fi
	if [ -s "$MODPATH"/unsigned.apk ]; then
		sign "$MODPATH"/unsigned.apk "$MODPATH"/signed.apk
		cp -rf "$MODPATH"/signed.apk "$MODPATH"/common/WebviewOverlay.apk
		rm -rf "$MODPATH"/signed.apk "$MODPATH"/unsigned.apk
	else
		ui_print " Overlay creation has failed! Poorly developed ROMs have this issue"
		ui_print " Compatibility is unlikely, please report this to your ROM developer"
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
	echo "$OLP" > "$MODPATH"/overlay.txt;
}
set_path() {
	unset APKPATH
	paths=$(cmd package dump com.android.webview | grep codePath); APKPATH=${paths##*=}
	[ -z "${APKPATH}" ] && paths=$(cmd package dump com.google.android.webview | grep codePath); APKPATH=${paths##*=}
	[ -z "${APKPATH}" ] && APKPATH="/system/app/webview"
	paths=$(cmd package dump com.android.chrome | grep codePath); APKPATH2=${paths##*=}
	[ -z "${APKPATH2}" ] && paths=$(cmd package dump com.android.browser | grep codePath); APKPATH2=${paths##*=}
	[ -z "${APKPATH2}" ] && APKPATH2="/system/app/Chrome"
}
extract_apk () {
	if "$WEBVIEW"
	then
		ui_print "- Installing ${NAME} Webview"
		cp_ch ${EXT_DATA}/WebviewSwitcher/webview_"$NAME".apk "$MODPATH"$APKPATH/webview.apk
		touch "$MODPATH"$APKPATH/.replace
		cp "$MODPATH"$APKPATH/webview.apk "$TMPDIR"/webview.zip
		mkdir "$TMPDIR"/webview -p
		unzip -d "$TMPDIR"/webview "$TMPDIR"/webview.zip > /dev/null
		cp -rf "$TMPDIR"/webview/lib "$MODPATH"$APKPATH/
		mv "$MODPATH"$APKPATH/lib/arm64-v8a "$MODPATH"$APKPATH/lib/arm64
		mv "$MODPATH"$APKPATH/lib/armeabi-v7a "$MODPATH"$APKPATH/lib/arm
		rm -rf "$TMPDIR"/webview "$TMPDIR"/webview.zip
	fi
	if "$BROWSER"
	then
		ui_print "- Installing ${NAME} Browser"
		mkdir -p "$MODPATH"$APKPATH2
		touch "$MODPATH"$APKPATH2/.replace
		cp_ch ${EXT_DATA}/WebviewSwitcher/browser_"$NAME".apk "$MODPATH"$APKPATH2/browser.apk
		touch "$MODPATH"$APKPATH2/.replace
		cp_ch "$MODPATH"$APKPATH2/browser.apk "$TMPDIR"/browser.zip
		mkdir -p "$TMPDIR"/browser
		unzip -d "$TMPDIR"/browser "$TMPDIR"/browser.zip > /dev/null
		cp -rf "$TMPDIR"/browser/lib "$MODPATH"$APKPATH2
		mv "$MODPATH"/system/app/Chrome/lib/arm64-v8a "$MODPATH"$APKPATH2/lib/arm64
		mv "$MODPATH"$APKPATH/lib/armeabi-v7a "$MODPATH"$APKPATH2/lib/arm
		rm -rf "$TMPDIR"/browser "$TMPDIR"/browser.zip
	fi
	mv "$MODPATH"/product "$MODPATH"/system/product
}
online_install() {
	ui_print "- Awesome, you have internet"
	old_version
	if "$WEBVIEW"
	then
		download_webview
	fi
	if "$BROWSER"
	then
        download_browser
	fi
	set_path
	extract_apk
	create_overlay
}
offline_install() {
	if "$WEBVIEW"
	then
		if test ! -f ${EXT_DATA}/WebviewSwitcher/webview_"$NAME".apk
		then
			it_failed
		fi
	fi
	if "$BROWSER"
	then
		if test ! -f ${EXT_DATA}/WebviewSwitcher/browser_"$NAME".apk
		then
			it_failed
		fi
	fi
	set_path
	extract_apk
	create_overlay ;
}
do_install () {
	set_config
	if test "$WHICH" -eq 0
	then
		do_bromite
	elif test "$WHICH" -eq 1
	then
		do_vanilla
	elif test "$WHICH" -eq 2
	then
		do_ungoogled
	elif test "$WHICH" -eq 3
	then
		EXTENSIONS="true"
		do_ungoogled
	else
		do_bromite
	fi
	if ! "$BOOTMODE"
	then
		ui_print "- Detected recovery install! Proceeding with reduced featureset"
		recovery_actions
		offline_install
		recovery_cleanup
	elif "$OFFLINE"
	then
		ui_print " Offline install selected! Proceeding..."
		offline_install
	else
		test_connection
		if test $? -ne 0
		then
			ui_print "- No internet detcted, falling back to offline install!"
			offline_install
		else
			if test ${TRY_COUNT} -ge 3
			then
				it_failed
			else
				online_install
			fi
		fi
	fi
	do_cleanup
}
clean_dalvik () {
	# Removes dalvik cache to re-register our overlay and webview
	ui_print "Dalvik cache will be cleared next boot"
	ui_print "Expect longer boot time"
}
do_cleanup () {
	ui_print "- Cleaning up..."
	rm -f "$MODPATH"/system/app/placeholder
	mkdir -p ${EXT_DATA}/WebviewSwitcher/logs
	rm -f "$MODPATH"/*.md
	ui_print "- Backing up important stuffs to module directory"
	mkdir -p "$MODPATH"/backup/
	cp /data/system/overlays.xml "$MODPATH"/backup/
	clean_dalvik
}
if test ${TRY_COUNT} -ge "5"
then
	it_failed
else
	do_install
fi
ui_print " "
ui_print "ℹℹℹℹℹℹℹℹℹℹℹℹℹℹℹℹℹℹℹℹℹℹℹℹℹℹℹℹℹℹℹℹℹℹℹℹℹℹℹℹℹℹℹℹℹℹℹℹℹℹℹℹℹℹℹℹℹℹℹℹℹℹℹℹℹℹℹℹℹℹℹ"
ui_print " "
ui_print " Some OEM/Google things were remvoed during install, to avoid conflicts"
ui_print " You can reinstall them, but do not request support if you do"
ui_print " Enjoy a more private and faster webview, done systemlessly"
ui_print " "
sleep 0.6
ui_print " WebviewSwitcher - An Androidacy Project"
sleep 0.7
ui_print " Social platforms at:"
ui_print " https://t.me/androidacy_announce, https://discord.gg/gTnDxQ6"
sleep 1
ui_print " Donate at https://www.androidacy.com/donate/"
ui_print " Website and blog is at https://www.androidacy.com"
sleep 3
ui_print "- Install apparently succeeded, please reboot ASAP"
ui_print " "
ui_print "ℹℹℹℹℹℹℹℹℹℹℹℹℹℹℹℹℹℹℹℹℹℹℹℹℹℹℹℹℹℹℹℹℹℹℹℹℹℹℹℹℹℹℹℹℹℹℹℹℹℹℹℹℹℹℹℹℹℹℹℹℹℹℹℹℹℹℹℹℹℹℹ"
ui_print " "