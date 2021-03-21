# shellcheck shell=dash
# shellcheck disable=SC1091
# shellcheck disable=SC1090
TRY_COUNT=0
VF=0
OLD_WEBVIEW=0
OLD_BROWSER=0
AVER=$(resetprop ro.build.version.release)
ui_print "- Android ${AVER}, API level ${API}, arch ${ARCH} device detected"
mkdir "$MODPATH"/logs/
VERSIONFILE="$EXT_DATA/version.txt"
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
# TODO: Reevaluate used sepolicy
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
check_config() {
	if test "$CV" -ne 5; then
		ui_print "- Invalid config version! Using defaults"
		cp "$MODPATH"/config.txt "$EXT_DATA"
		. "$EXT_DATA"/config.txt
	fi
	if test "$INSTALL" -ne 0 && test "$INSTALL" -ne 1 && test "$INSTALL" -ne 2; then
		ui_print "- Invalid config value for INSTALL! Using defaults"
		cp "$MODPATH"/config.txt "$EXT_DATA"
		. "$EXT_DATA"/config.txt
	elif test "$WEBVIEW" -ne 0 && test "$WEBVIEW" -ne 1 && test "$WEBVIEW" -ne 2; then
		ui_print "- Invalid config value for INSTALL! Using defaults"
		cp "$MODPATH"/config.txt "$EXT_DATA"
		. "$EXT_DATA"/config.txt
	elif test "$BROWSER" -ne 0 && test "$BROWSER" -ne 1 && test "$BROWSER" -ne 2 && test "$BROWSER" -ne 3; then
		ui_print "- Invalid config value for INSTALL! Using defaults"
		cp "$MODPATH"/config.txt "$EXT_DATA"
		. "$EXT_DATA"/config.txt
	fi
}
set_config() {
	ui_print "- Setting configs..."
	if test -f "$EXT_DATA"/config.txt; then
		. "$EXT_DATA"/config.txt
		if test $? -ne 0; then
			ui_print "- Invalid config file! Using defaults"
			cp "$MODPATH"/config.txt "$EXT_DATA"
			. "$EXT_DATA"/config.txt
		else
			check_config
		fi
	else
		ui_print "- No config found, using defaults"
		ui_print "     -> Only install bromite webview"
		ui_print "- Make sure if you want/need a custom setup to edit config.txt"
		cp "$MODPATH"/config.txt "$EXT_DATA"
		. "$EXT_DATA"/config.txt
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
	if test ! -f "$EXT_DATA"/version.txt; then
		echo "OLD_BROWSER=0" >"$VERSIONFILE"
		echo "OLD_WEBVIEW=0" >>"$VERSIONFILE"
		. "$EXT_DATA"/version.txt
	else
		. "$EXT_DATA"/version.txt
		if test $? -ne 0; then
			echo "OLD_BROWSER=0" >"$VERSIONFILE"
			echo "OLD_WEBVIEW=0" >>"$VERSIONFILE"
			. "$EXT_DATA"/version.txt
		fi
	fi
}
download_webview() {
	old_version
	if test "$WEBVIEW" -eq 0; then
		do_bromite_webview
	elif test "$WEBVIEW" -eq 1; then
		do_vanilla_webview
	else
		do_ungoogled_webview
	fi
	if test "$VF" -eq 1; then
		ui_print "- Downloading ${NAME} webview, please be patient..."
		dl $DL_URL"$WEBVIEW_VER""$WEBVIEW_FILE" -o "$EXT_DATA"/apks/"$NAME"Webview.apk
		sed -i "/OLD_WEBVIEW/d" "$VERSIONFILE"
		echo "OLD_WEBVIEW=$(echo "$WEBVIEW_VER" | sed 's/[^0-9]*//g')" >>"$VERSIONFILE"
	fi
	if test -f "$EXT_DATA"/apks/"$NAME"Webview.apk; then
		if test "$OLD_WEBVIEW" -lt "$(echo "$WEBVIEW_VER" | sed 's/[^0-9]*//g' | tr -d '.')"; then
			ui_print "- Downloading update for ${NAME} webview, please be patient..."
			dl $DL_URL"$WEBVIEW_VER""$WEBVIEW_FILE" -o "$EXT_DATA"/apks/"$NAME"Webview.apk
			sed -i "/OLD_WEBVIEW/d" "$VERSIONFILE"
			echo "OLD_WEBVIEW=$(echo "$WEBVIEW_VER" | sed 's/[^0-9]*//g')" >>"$VERSIONFILE"
		else
			ui_print "- Not a version upgrade! Using existing ${NAME} webview apk"
		fi
	else
		ui_print "- No existing apk found for ${NAME} webview!"
		ui_print "- Downloading ${NAME} webview, please be patient..."
		dl $DL_URL"$WEBVIEW_VER""$WEBVIEW_FILE" -o "$EXT_DATA"/apks/"$NAME"Webview.apk
		sed -i "/OLD_WEBVIEW/d" "$VERSIONFILE"
		echo "OLD_WEBVIEW=$(echo "$WEBVIEW_VER" | sed 's/[^0-9]*//g')" >>"$VERSIONFILE"
	fi
	verify_webview
}
download_browser() {
	old_version
	if test "$BROWSER" -eq 0; then
		do_bromite_browser
	elif test "$BROWSER" -eq 1; then
		do_vanilla_browser
	else
		do_ungoogled_browser
	fi
	if test -f "$EXT_DATA"/apks/"$NAME"Browser.apk; then
		if test "$OLD_BROWSER" -lt "$(echo "$BROWSER_VER" | sed 's/[^0-9]*//g' | tr -d '.')"; then
			ui_print "- Downloading update for ${NAME} browser, please be patient..."
			dl $DL_URL"$BROWSER_VER""$BROWSER_FILE" -o "$EXT_DATA"/apks/"$NAME"Browser.apk
			sed -i "/OLD_BROWSER/d" "$VERSIONFILE"
			echo "OLD_BROWSER=$(echo "$BROWSER_VER" | sed 's/[^0-9]*//g')" >>"$VERSIONFILE"
		else
			ui_print "- Not a version upgrade! Using existing ${NAME} browser apk"
		fi
	else
		ui_print "- No existing apk found for ${NAME} browser!"
		ui_print "- Downloading ${NAME} browser, please be patient..."
		dl $DL_URL"$BROWSER_VER""$BROWSER_FILE" -o "$EXT_DATA"/apks/"$NAME"Browser.apk
		sed -i "/OLD_BROWSER/d" "$VERSIONFILE"
		echo "OLD_BROWSER=$(echo "$BROWSER_VER" | sed 's/[^0-9]*//g')" >>"$VERSIONFILE"
	fi
	extract_browser
}
verify_webview() {
	ui_print " Verifying ${NAME} webview files..."
	if test $SUM_PRE != "not_implemented"; then
		cd "$EXT_DATA"/apks || return
		wget -qO "$ARCH"_SystemWebView.apk.sha256.txt.tmp ${DL_URL}"${WEBVIEW_VER}"/${SUM_PRE}_"${WEBVIEW_VER}".sha256.txt
		grep "$ARCH"_SystemWebView.apk "$ARCH"_SystemWebView.apk.sha256.txt.tmp >"$NAME"Webview.apk.sha256.txt
		rm -fr "$ARCH"_SystemWebView.apk.sha256.txt.tmp
		sed -i s/"$ARCH"_SystemWebView.apk/${NAME}Webview.apk/gi "$NAME"Webview.apk.sha256.txt
		sha256sum -sc "$NAME"Webview.apk.sha256.txt >/dev/null
		if test $? -ne 0; then
			ui_print "- Verification failed, retrying download"
			rm -f "$EXT_DATA"/apks/*webview*.apk
			TRY_COUNT=$((TRY_COUNT + 1))
			VF=1
			if test ${TRY_COUNT} -ge 3; then
				it_failed
			else
				cd "$TMPDIR" || return
				download_webview
			fi
		else
			ui_print " Verified successfully. Proceeding..."
			VF=0
			extract_webview
		fi
	else
		ui_print "- ${NAME} cannot be verified, as they don't publish sha256sums."
	fi
	cd "$TMPDIR" || return
}
create_overlay() {
	cd "$TMPDIR" || return
	ui_print "- Fixing system webview whitelist"
	if test "${API}" -ge "29"; then
		aapt p -f -v -M "$MODPATH"/common/overlay10/AndroidManifest.xml -I /system/framework/framework-res.apk -S "$MODPATH"/common/overlay10/res -F "$MODPATH"/unsigned.apk >"$MODPATH"/logs/aapt.log
	else
		aapt p -f -v -M "$MODPATH"/common/overlay9/AndroidManifest.xml -I /system/framework/framework-res.apk -S "$MODPATH"/common/overlay9/res -F "$MODPATH"/unsigned.apk >"$MODPATH"/logs/aapt.log
	fi
	if test -f "$MODPATH"/unsigned.apk; then
		sign "$MODPATH"/unsigned.apk "$MODPATH"/signed.apk
		cp -rf "$MODPATH"/signed.apk "$MODPATH"/common/WebviewOverlay.apk
		rm -rf "$MODPATH"/signed.apk "$MODPATH"/unsigned.apk
	else
		ui_print "- Overlay creation has failed! Poorly developed ROMs have this issue"
		ui_print "- Compatibility is unlikely, please report this to your ROM developer."
		ui_print "- Some ROMs need a patch to fix this."
	fi
	cp -f "$MODPATH"/logs/aapt.log "$EXT_DATA"/logs
	if [ -d /system_ext/overlay ]; then
		OLP=/system/system_ext/overlay
	elif [ -d /product/overlay ]; then
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
	paths=$(cmd package dump com.android.webview | grep codePath)
	A=${paths##*=}
	unset paths
	if test -z "$A"; then
		A=$(find /system /vendor /product /system_ext -type d 2>/dev/null | grep -i webview | grep -iv library | grep -iv stub | grep -iv google)
	fi
	if test -z "$A"; then
		A=$(find /system /vendor /product /system_ext -type d 2>/dev/null | grep -i webview | grep -iv library | grep -i stub | grep -iv google)
	fi
	paths=$(cmd package dump com.google.android.webview | grep codePath)
	B=${paths##*=}
	unset paths
	if test -z "$B"; then
		B=$(find /system /vendor /product /system_ext -type d 2>/dev/null | grep -i google | grep -i webview | grep -iv library | grep -iv stub | grep -iv overlay)
	fi
	if test -z "$B"; then
		B=$(find /system /vendor /product /system_ext -type d 2>/dev/null | grep -i google | grep -i webview | grep -iv library | grep -i stub | grep -iv overlay)
	fi
	WPATH="/system/app/webview"
	G=$(find /system /vendor /product /system_ext -type d 2>/dev/null | grep -i google | grep -i webview | grep -iv library | grep -iv stub | grep -i overlay)
	paths=$(cmd package dump com.android.chrome | grep codePath)
	C=${paths##*=}
	if test -z "$C"; then
		C=$(find /system /vendor /product /system_ext -type d 2>/dev/null | grep -i chrome | grep -iv library | grep -iv stub)
	fi
	if test -z "$F"; then
		F=$(find /system /vendor /product /system_ext -type d 2>/dev/null | grep -i chrome | grep -iv library | grep -i stub)
	fi
	unset paths
	paths=$(cmd package dump com.android.browser | grep codePath)
	D=${paths##*=}
	unset paths
	paths=$(cmd package dump org.lineageos.jelly | grep codePath)
	E=${paths##*=}
	BPATH="/system/app/browser"
}
extract_webview() {
	ui_print "- Installing ${NAME} Webview"
	if test ! -z "$A"; then
		mktouch "$MODPATH""$A"/.replace
	fi
	if test ! -z "$B"; then
		mktouch "$MODPATH""$B"/.replace
	fi
	if test ! -z "$G"; then
		mktouch "$MODPATH""$G"/.replace
	fi
	cp_ch "$EXT_DATA"/apks/"$NAME"Webview.apk "$MODPATH"$WPATH/webview.apk || cp_ch "$EXT_DATA"/apks/webview.apk "$MODPATH"$WPATH/webview.apk
	touch "$MODPATH"$WPATH/.replace
	cp "$MODPATH"$WPATH/webview.apk "$TMPDIR"/webview.zip
	mkdir "$TMPDIR"/webview -p
	unzip -d "$TMPDIR"/webview "$TMPDIR"/webview.zip >/dev/null
	cp -rf "$TMPDIR"/webview/lib "$MODPATH"$WPATH/
	mv "$MODPATH"$WPATH/lib/arm64-v8a "$MODPATH"$WPATH/lib/arm64
	mv "$MODPATH"$WPATH/lib/armeabi-v7a "$MODPATH"$WPATH/lib/arm
	rm -rf "$TMPDIR"/webview "$TMPDIR"/webview.zip
	create_overlay
}
extract_browser() {
	ui_print "- Installing ${NAME} Browser"
	if test ! -z "$C"; then
		mktouch "$MODPATH""$C"/.replace
	fi
	if test ! -z "$D"; then
		mktouch "$MODPATH""$D"/.replace
	fi
	if test ! -z "$E"; then
		mktouch "$MODPATH""$E"/.replace
	fi
	if test ! -z "$F"; then
		mktouch "$MODPATH""$F"/.replace
	fi
	mkdir -p "$MODPATH"$BPATH
	touch "$MODPATH"$BPATH/.replace
	cp_ch "$EXT_DATA"/apks/"$NAME"Browser.apk "$MODPATH"$BPATH/browser.apk || cp_ch "$EXT_DATA"/apks/browser.apk "$MODPATH"$BPATH/browser.apk
	touch "$MODPATH"$BPATH/.replace
	cp_ch "$MODPATH"$BPATH/browser.apk "$TMPDIR"/browser.zip
	mkdir -p "$TMPDIR"/browser
	unzip -d "$TMPDIR"/browser "$TMPDIR"/browser.zip >/dev/null
	cp -rf "$TMPDIR"/browser/lib "$MODPATH"$BPATH
	mv "$MODPATH"$BPATH/lib/arm64-v8a "$MODPATH"$BPATH/lib/arm64
	mv "$MODPATH""$BPATH"/lib/armeabi-v7a "$MODPATH"$BPATH/lib/arm
	rm -rf "$TMPDIR"/browser "$TMPDIR"/browser.zip
}
online_install() {
	ui_print "- Awesome, you have internet"
	set_path
	if test "$INSTALL" -eq 0; then
		ui_print "     -> Webview install selected"
		download_webview
	elif test "$INSTALL" -eq 1; then
		ui_print '     -> Browser install selected'
		download_browser
	elif test "$INSTALL" -eq 2; then
		ui_print "     -> Both webview and browser install selected"
		download_browser
		download_webview
	fi
}
offline_install() {
	set_path
	if test ! -f "$EXT_DATA"/apks/webview.apk; then
		ui_print "- No webview.apk found!"
	else
		ui_print "- Webview.apk found! Using it."
		extract_webview
	fi
	if test ! -f "$EXT_DATA"/apks/browser.apk; then
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
	rm -f "$MODPATH"/*.md
	ui_print "- Backing up important stuffs to module directory"
	mkdir -p "$MODPATH"/backup/
	cp /data/system/overlays.xml "$MODPATH"/backup/
	cp -rf "$MODPATH"/product/* "$MODPATH"/system/product
	cp -rf "$MODPATH"/system_ext/* "$MODPATH"/system/system_ext
	rm -fr "$MODPATH"/product "$MODPATH"/system_ext
	clean_dalvik
}
if test ${TRY_COUNT} -ge "3"; then
	it_failed
else
	do_install
fi
ui_print " "
ui_print "ℹℹℹℹℹℹℹℹℹℹℹℹℹℹℹℹℹℹℹℹℹℹℹℹℹℹℹℹℹℹℹℹℹℹℹℹℹℹℹℹℹℹℹℹℹℹℹℹℹℹℹℹℹℹℹℹℹℹℹℹℹℹℹℹℹℹℹℹℹℹℹℹℹℹℹℹℹℹℹ"
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
ui_print "-> Install apparently succeeded, please reboot ASAP"
ui_print " "
ui_print "ℹℹℹℹℹℹℹℹℹℹℹℹℹℹℹℹℹℹℹℹℹℹℹℹℹℹℹℹℹℹℹℹℹℹℹℹℹℹℹℹℹℹℹℹℹℹℹℹℹℹℹℹℹℹℹℹℹℹℹℹℹℹℹℹℹℹℹℹℹℹℹℹℹℹℹℹℹℹℹ"
ui_print " "
