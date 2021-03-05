# shellcheck shell=dash
# shellcheck disable=SC1091
# shellcheck disable=SC1090
mkdir "$MODPATH"/logs
TRY_COUNT=0
detect_ext_data() {
	touch /sdcard/.rw && rm /sdcard/.rw && EXT_DATA="/sdcard"
	if test -z ${EXT_DATA}; then
		touch /storage/emulated/0/.rw && rm /storage/emulated/0/.rw && EXT_DATA="/storage/emulated/0"
	fi
	if test -z ${EXT_DATA}; then
		touch /data/media/0/.rw && rm /data/media/0/.rw && EXT_DATA="/data/media/0"
	fi
	if test -z ${EXT_DATA}; then
		ui_print "- Data check failed, bailing out!"
		it_failed
	fi
}
detect_ext_data
VERSIONFILE="${EXT_DATA}/WebviewManager/version.txt"
alias aapt='"$MODPATH"/common/tools/aapt-"$ARCH"'
alias sign='"$MODPATH"/common/tools/zipsigner'
chmod -R 0755 "$MODPATH"/common/tools
setup_certs() {
	mkdir -p "$MODPATH"/system/etc/security
	if [ -f "/system/etc/security/ca-certificates.crt" ]; then
		cp -f /system/etc/security/ca-certificates.crt "$MODPATH"/ca-certificates.crt
	else
		for i in /system/etc/security/cacerts*/*.0; do
			sed -n "/BEGIN CERTIFICATE/,/END CERTIFICATE/p" "$i" >>"$MODPATH"/ca-certificates.crt
		done
	fi
	SEC="true"
}
dl() {
	if ! $SEC; then
		setup_certs
	fi
	"$MODPATH"/common/tools/aria2c-"$ARCH" -x 16 -s 16 --async-dns --file-allocation=none --check-certificate=false --ca-certificate="$MODPATH"/ca-certificates.crt --quiet "$@"
}
if test -d ${EXT_DATA}/bromite; then
	ui_print "- Major version upgrade! Performing migration!"
	rm -rf ${EXT_DATA}/bromite
fi
if test -d ${EXT_DATA}/WebviewSwitcher; then
	ui_print "- Major version upgrade! Performing migration!"
	rm -rf ${EXT_DATA}/bromite
fi
if test ! -d ${EXT_DATA}/WebviewManager; then
	mkdir -p ${EXT_DATA}/WebviewManager
fi
# magiskpolicy --live "allow system_server untrusted_app_25_devpts chr_file { read write }"
magiskpolicy --live "allow system_server sdcardfs file { read write }"
magiskpolicy --live "allow zygote adb_data_file file getattr"
VEN=/system/vendor
[ -L /system/vendor ] && VEN=/vendor
if [ -f $VEN/build.prop ]; then
	export BUILDS="/system/build.prop $VEN/build.prop"
else
	BUILDS="/system/build.prop"
fi
ui_print "- $ARCH SDK $API system detected, selecting the appropriate files"
check_config() {
	if test "$CV" -ne 5; then
		ui_print "- Invalid config version! Using defaults"
		cp "$MODPATH"/config.txt ${EXT_DATA}/WebviewManager
		. ${EXT_DATA}/WebviewManager/config.txt
	fi
	if test "$INSTALL" -ne 0 && test "$INSTALL" -ne 1 && test "$INSTALL" -ne 2; then
		ui_print "- Invalid config value for INSTALL! Using defaults"
		cp "$MODPATH"/config.txt ${EXT_DATA}/WebviewManager
		. ${EXT_DATA}/WebviewManager/config.txt
	elif test "$WEBVIEW" -ne 0 && test "$WEBVIEW" -ne 1 && test "$WEBVIEW" -ne 2; then
		ui_print "- Invalid config value for INSTALL! Using defaults"
		cp "$MODPATH"/config.txt ${EXT_DATA}/WebviewManager
		. ${EXT_DATA}/WebviewManager/config.txt
	elif test "$BROWSER" -ne 0 && test "$BROWSER" -ne 1 && test "$BROWSER" -ne 2 && test "$BROWSER" -ne 3; then
		ui_print "- Invalid config value for INSTALL! Using defaults"
		cp "$MODPATH"/config.txt ${EXT_DATA}/WebviewManager
		. ${EXT_DATA}/WebviewManager/config.txt
	fi
}
set_config() {
	ui_print "- Setting configs..."
	if test -f ${EXT_DATA}/WebviewManager/config.txt; then
		. ${EXT_DATA}/WebviewManager/config.txt
		if test $? -ne 0; then
			ui_print "- Invalid config file! Using defaults"
			cp "$MODPATH"/config.txt ${EXT_DATA}/WebviewManager
			. ${EXT_DATA}/WebviewManager/config.txt
		else
			check_config
		fi
	else
		ui_print "- No config found, using defaults"
		ui_print "- Make sure if you want/need a custom setup to edit config.txt"
		cp "$MODPATH"/config.txt ${EXT_DATA}/WebviewManager
		. ${EXT_DATA}/WebviewManager/config.txt
	fi
	if test "$INSTALL" -eq 0; then
		ui_print "- Webview install selected"
		download_webview
		extract_webview
	elif test "$INSTALL" -eq 1; then
		ui_print '- Browser install selected'
		download_browser
		extract_browser
	elif test "$INSTALL" -eq 2; then
		ui_print "- Both webview and browser install selected"
		download_browser
		extract_browser
		download_webview
		extract_webview
	fi
}
test_connection() {
	ui_print "- Testing internet connectivity"
	(ping -q -c 2 -W 1 www.androidacy.com >/dev/null 2>&1) && return 0 || return 1
}
do_ungoogled_webview() {
	NAME="Ungoogled-Chromium"
	SUM_PRE="not_implemented"
	WEBVIEW_FILE="/SystemWebView_${ARCH}.apk"
	WEBVIEW_VER="$(wget -qO- https://api.github.com/repos/ungoogled-software/ungoogled-chromium-android/releases | grep webview | grep '"tag_name"' | head -1 | sed -E 's/.*"([^"]+)".*/\1/')"
	DL_URL="https://github.com/ungoogled-software/ungoogled-chromium-android/releases/download/"
}
do_ungoogled_browser() {
	NAME="Ungoogled-Chromium"
	SUM_PRE="not_implemented"
	if test "$BROWSER" -eq 3; then
		BROWSER_VER="$(wget -qO- https://api.github.com/repos/ungoogled-software/ungoogled-chromium-android/releases | grep -v webview | grep extensions | grep '"tag_name"' | head -1 | sed -E 's/.*"([^"]+)".*/\1/')"
	else
		BROWSER_VER="$(wget -qO- https://api.github.com/repos/ungoogled-software/ungoogled-chromium-android/releases | grep -v webview | grep -v extensions | grep '"tag_name"' | head -1 | sed -E 's/.*"([^"]+)".*/\1/')"
	fi
	BROWSER_FILE="/ChromeModernPublic_${ARCH}.apk"
	DL_URL="https://github.com/ungoogled-software/ungoogled-chromium-android/releases/download/"
}
do_vanilla_webview() {
	NAME="Chromium"
	SUM_PRE="chrm"
	WEBVIEW_VER="$(wget -qO- https://api.github.com/repos/bromite/chromium/releases/latest | grep '"tag_name":' | sed -E 's/.*"([^"]+)".*/\1/')"
	WEBVIEW_FILE="/${ARCH}_SystemWebView.apk"
	DL_URL="https://github.com/bromite/chromium/releases/download/"
}
do_vanilla_browser() {
	NAME="Chromium"
	SUM_PRE="chrm"
	BROWSER_VER="$(wget -qO- https://api.github.com/repos/bromite/chromium/releases/latest | grep '"tag_name":' | sed -E 's/.*"([^"]+)".*/\1/')"
	BROWSER_FILE="/${ARCH}_ChromePublic.apk"
	DL_URL="https://github.com/bromite/chromium/releases/download/"
}
do_bromite_webview() {
	NAME="Bromite"
	SUM_PRE="brm"
	WEBVIEW_VER="$(wget -qO- https://api.github.com/repos/bromite/bromite/releases/latest | grep '"tag_name":' | sed -E 's/.*"([^"]+)".*/\1/')"
	WEBVIEW_FILE="/${ARCH}_SystemWebView.apk"
	DL_URL="https://github.com/bromite/bromite/releases/download/"
}
do_bromite_browser() {
	NAME="Bromite"
	SUM_PRE="brm"
	BROWSER_VER="$(wget -qO- https://api.github.com/repos/bromite/bromite/releases/latest | grep '"tag_name":' | sed -E 's/.*"([^"]+)".*/\1/')"
	BROWSER_FILE="/${ARCH}_ChromePublic.apk"
	DL_URL="https://github.com/bromite/bromite/releases/download/"
}
old_version() {
	ui_print "- Checking whether this is a new install...."
	if test ! -f ${EXT_DATA}/WebviewManager/version.txt; then
		echo "OLD_BROWSER=0" >$VERSIONFILE
		echo "OLD_WEBVIEW=0" >>$VERSIONFILE
		. ${EXT_DATA}/WebviewManager/version.txt
	else
		. ${EXT_DATA}/WebviewManager/version.txt
		if $? -ne 0; then
			echo "OLD_BROWSER=0" >$VERSIONFILE
			echo "OLD_WEBVIEW=0" >>$VERSIONFILE
			. ${EXT_DATA}/WebviewManager/version.txt
		fi
	fi
}
it_failed() {
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
	mv ${EXT_DATA}/WebviewManager/logs ${EXT_DATA}
	rm -rf ${EXT_DATA}/WebviewManager/*
	mv ${EXT_DATA}/logs ${EXT_DATA}/WebviewManager/
	ui_print " "
	ui_print "⚠⚠⚠⚠⚠⚠⚠⚠⚠⚠⚠⚠⚠⚠⚠⚠⚠⚠⚠⚠⚠⚠⚠⚠⚠⚠"
	ui_print " "
	abort
}
download_webview() {
	if test "$WEBVIEW" -eq 0; then
		do_bromite_webview
	elif test "$WEBVIEW" -eq 1; then
		do_vanilla_webview
	else
		do_ungoogled_webview
	fi
	if test -f ${EXT_DATA}/WebviewManager/apks/"$NAME"Webview.apk; then
		if test "$OLD_WEBVIEW" -lt "$(echo "$WEBVIEW_VER" | sed 's/[^0-9]*//g')"; then
			ui_print "- Downloading update for ${NAME} webview, please be patient..."
			dl $DL_URL"$WEBVIEW_VER""$WEBVIEW_FILE" -o "$EXT_DATA"/WebviewManager/apks/"$NAME"Webview.apk
			sed -i "/OLD_WEBVIEW/d" "$VERSIONFILE"
			echo "OLD_WEBVIEW=$(echo "$WEBVIEW_VER" | sed 's/[^0-9]*//g')" >>"$VERSIONFILE"
			verify_webview
		else
			ui_print "- Not a version upgrade! Using existing ${NAME} webview apk"
		fi
	else
		ui_print "- No existing apk found for ${NAME} webview!"
		ui_print "- Downloading ${NAME} webview, please be patient..."
		dl $DL_URL"$WEBVIEW_VER""$WEBVIEW_FILE" -o "$EXT_DATA"/WebviewManager/apks/"$NAME"Webview.apk
		sed -i "/OLD_WEBVIEW/d" "$VERSIONFILE"
		echo "OLD_WEBVIEW=$(echo "$WEBVIEW_VER" | sed 's/[^0-9]*//g')" >>"$VERSIONFILE"
		verify_webview
	fi
}
download_browser() {
	if test "$BROWSER" -eq 0; then
		do_bromite_browser
	elif test "$BROWSER" -eq 1; then
		do_vanilla_browser
	else
		do_ungoogled_browser
	fi
	if test -f ${EXT_DATA}/WebviewManager/apks/"$NAME"Browser.apk; then
		if test "$OLD_BROWSER" -lt "$(echo "$BROWSER_VER" | sed 's/[^0-9]*//g')"; then
			ui_print "- Downloading update for ${NAME} browser, please be patient..."
			dl $DL_URL"$BROWSER_VER""$BROWSER_FILE" -o "$EXT_DATA"/WebviewManager/apks/"$NAME"Browser.apk
			sed -i "/OLD_BROWSER/d" "$VERSIONFILE"
			echo "OLD_BROWSER=$(echo "$BROWSER_VER" | sed 's/[^0-9]*//g')" >>"$VERSIONFILE"
		else
			ui_print "- Not a version upgrade! Using existing ${NAME} browser apk"
		fi
	else
		ui_print "- No existing apk found for ${NAME} browser!"
		ui_print "- Downloading ${NAME} browser, please be patient..."
		dl $DL_URL"$BROWSER_VER""$BROWSER_FILE" -o "$EXT_DATA"/WebviewManager/apks/"$NAME"Browser.apk
		sed -i "/OLD_BROWSER/d" "$VERSIONFILE"
		echo "OLD_BROWSER=$(echo "$BROWSER_VER" | sed 's/[^0-9]*//g')" >>"$VERSIONFILE"
	fi
}
verify_webview() {
	ui_print " Verifying ${NAME} webview files..."
	if test $SUM_PRE != "not_implemented"; then
		cd "${EXT_DATA}"/WebviewManager/apks || return
		wget -qO "$ARCH"_SystemWebView.apk.sha256.txt.tmp ${DL_URL}"${WEBVIEW_VER}"/${SUM_PRE}_"${WEBVIEW_VER}".sha256.txt
		cp ${EXT_DATA}/WebviewManager/apks/"$NAME"Webview.apk "${ARCH}"_SystemWebView.apk
		grep "$ARCH"_SystemWebView.apk "$ARCH"_SystemWebView.apk.sha256.txt.tmp >"$ARCH"_SystemWebView.apk.sha256.txt
		sed "s|${ARCH}_SystemWebView|webview|" webview_"$NAME".apk.sha256.txt
		sha256sum -sc webview_"$NAME".apk.sha256.txt
		if test $? -ne 0; then
			ui_print " Verification failed, retrying download"
			rm -f ${EXT_DATA}/WebviewManager/apks/*webview*.apk
			TRY_COUNT=$((TRY_COUNT + 1))
			if test ${TRY_COUNT} -ge 3; then
				it_failed
			else
				cd "$TMPDIR" || return
				download_webview
			fi
		else
			ui_print " Verified successfully. Proceeding..."
		fi
	else
		ui_print "- ${NAME} cannot be verified, as they don't publish sha256sums."
	fi
	rm "${ARCH}"_SystemWebView.apk* -f
	cd "$TMPDIR" || return
}
create_overlay() {
	cd "$TMPDIR" || return
	if test "${API}" -ge "29"; then
		ui_print "- Android 10 or later detected"
		aapt p -f -v -M "$MODPATH"/common/overlay10/AndroidManifest.xml \
			-I /system/framework/framework-res.apk -S "$MODPATH"/common/overlay10/res \
			-F "$MODPATH"/unsigned.apk >"$MODPATH"/logs/aapt.log
	else
		ui_print "- Android version less than 10 detected"
		aapt p -f -v -M "$MODPATH"/common/overlay9/AndroidManifest.xml \
			-I /system/framework/framework-res.apk -S "$MODPATH"/common/overlay9/res \
			-F "$MODPATH"/unsigned.apk >"$MODPATH"/logs/aapt.log
	fi
	if [ -s "$MODPATH"/unsigned.apk ]; then
		sign "$MODPATH"/unsigned.apk "$MODPATH"/signed.apk
		cp -rf "$MODPATH"/signed.apk "$MODPATH"/common/WebviewOverlay.apk
		rm -rf "$MODPATH"/signed.apk "$MODPATH"/unsigned.apk
	else
		ui_print " Overlay creation has failed! Poorly developed ROMs have this issue"
		ui_print " Compatibility is unlikely, please report this to your ROM developer"
	fi
	if [ -d /product/overlay ]; then
		OLP=/system/product/overlay
	elif [ -d /vendor/overlay ]; then
		OLP=/system/vendor/overlay
	elif [ -d /system/overlay ]; then
		OLP=/system/overlay
	fi
	mkdir -p "$MODPATH""$OLP"
	cp_ch "$MODPATH"/common/WebviewOverlay.apk "$MODPATH""$OLP"
	echo "$OLP" >"$MODPATH"/overlay.txt
}
set_path() {
	unset APKPATH
	paths=$(cmd package dump com.android.webview | grep codePath)
	APKPATH=${paths##*=}
	[ -z "${APKPATH}" ] && paths=$(cmd package dump com.google.android.webview | grep codePath)
	APKPATH=${paths##*=}
	[ -z "${APKPATH}" ] && APKPATH="/system/app/webview"
	paths=$(cmd package dump com.android.chrome | grep codePath)
	APKPATH2=${paths##*=}
	[ -z "${APKPATH2}" ] && paths=$(cmd package dump com.android.browser | grep codePath)
	APKPATH2=${paths##*=}
	[ -z "${APKPATH2}" ] && APKPATH2="/system/app/Chrome"
}
extract_webview() {
	ui_print "- Installing ${NAME} Webview"
	cp_ch ${EXT_DATA}/WebviewManager/apks/"$NAME"Webview.apk "$MODPATH"$APKPATH/webview.apk || cp_ch ${EXT_DATA}/WebviewManager/apks/webview.apk "$MODPATH"$APKPATH/webview.apk
	touch "$MODPATH"$APKPATH/.replace
	cp "$MODPATH"$APKPATH/webview.apk "$TMPDIR"/webview.zip
	mkdir "$TMPDIR"/webview -p
	unzip -d "$TMPDIR"/webview "$TMPDIR"/webview.zip >/dev/null
	cp -rf "$TMPDIR"/webview/lib "$MODPATH"$APKPATH/
	mv "$MODPATH"$APKPATH/lib/arm64-v8a "$MODPATH"$APKPATH/lib/arm64
	mv "$MODPATH"$APKPATH/lib/armeabi-v7a "$MODPATH"$APKPATH/lib/arm
	rm -rf "$TMPDIR"/webview "$TMPDIR"/webview.zip
	create_overlay
}
extract_browser() {
	ui_print "- Installing ${NAME} Browser"
	mkdir -p "$MODPATH"$APKPATH2
	touch "$MODPATH"$APKPATH2/.replace
	cp_ch ${EXT_DATA}/WebviewManager/apks/"$NAME"Browser.apk "$MODPATH"$APKPATH2/browser.apk || cp_ch ${EXT_DATA}/WebviewManager/apks/browser.apk "$MODPATH"$APKPATH2/browser.apk
	touch "$MODPATH"$APKPATH2/.replace
	cp_ch "$MODPATH"$APKPATH2/browser.apk "$TMPDIR"/browser.zip
	mkdir -p "$TMPDIR"/browser
	unzip -d "$TMPDIR"/browser "$TMPDIR"/browser.zip >/dev/null
	cp -rf "$TMPDIR"/browser/lib "$MODPATH"$APKPATH2
	mv "$MODPATH"/system/app/Chrome/lib/arm64-v8a "$MODPATH"$APKPATH2/lib/arm64
	mv "$MODPATH"$APKPATH/lib/armeabi-v7a "$MODPATH"$APKPATH2/lib/arm
	rm -rf "$TMPDIR"/browser "$TMPDIR"/browser.zip
	mv "$MODPATH"/product "$MODPATH"/system/product
}
online_install() {
	ui_print "- Awesome, you have internet"
	old_version
	set_path
	set_config
}
offline_install() {
	set_path
	if test ! -f ${EXT_DATA}/WebviewManager/apks/webview.apk; then
		ui_print "- No webview.apk found!"
	else
		ui_print "- Webview.apk found! Using it."
		extract_webview
	fi
	if test ! -f ${EXT_DATA}/WebviewManager/apks/browser.apk; then
		ui_print "- No browser.apk found!"
	else
		ui_print "- Browser.apk found! Using it"
		extract_browser
	fi
}
do_install() {
	set_config
	if ! "$BOOTMODE"; then
		ui_print "- Detected recovery install! Proceeding with reduced featureset"
		recovery_actions
		offline_install
		recovery_cleanup
	elif test "$OFFLINE" -eq 1; then
		ui_print " Offline install selected! Proceeding..."
		offline_install
	else
		test_connection
		if test $? -ne 0; then
			ui_print "- No internet detcted, falling back to offline install!"
			offline_install
		else
			if test ${TRY_COUNT} -ge 3; then
				it_failed
			else
				online_install
			fi
		fi
	fi
	do_cleanup
}
clean_dalvik() {
	# Removes dalvik cache to re-register our overlay and webview
	ui_print "Dalvik cache will be cleared next boot"
	ui_print "Expect longer boot time"
}
do_cleanup() {
	ui_print "- Cleaning up..."
	rm -f "$MODPATH"/system/app/placeholder
	mkdir -p ${EXT_DATA}/WebviewManager/logs
	rm -f "$MODPATH"/*.md
	ui_print "- Backing up important stuffs to module directory"
	mkdir -p "$MODPATH"/backup/
	cp /data/system/overlays.xml "$MODPATH"/backup/
	clean_dalvik
}
if test ${TRY_COUNT} -ge "5"; then
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
ui_print " WebviewManager - An Androidacy Project"
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
