# shellcheck shell=dash
# shellcheck disable=SC1091
# shellcheck disable=SC1090
TRY_COUNT=1
VF=0
OLD_WEBVIEW=0
OLD_BROWSER=0
AVER=$(resetprop ro.build.version.release)
ui_print "ⓘ Android ${AVER}, API level ${API}, arch ${ARCH} device detected"
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
VEN=/system/vendor
[ -L /system/vendor ] && VEN=/vendor
if [ -f $VEN/build.prop ]; then
	export BUILDS="/system/build.prop $VEN/build.prop"
else
	BUILDS="/system/build.prop"
fi
check_config() {
	if test "$CV" -ne 5; then
		ui_print "⚠ Wrong config version! Using defaults"
		cp "$MODPATH"/config.txt "$EXT_DATA"
		. "$EXT_DATA"/config.txt
	fi
	if test "$INSTALL" -ne 0 && test "$INSTALL" -ne 1 && test "$INSTALL" -ne 2; then
		ui_print "⚠ Invalid config value for INSTALL! Using defaults"
		cp "$MODPATH"/config.txt "$EXT_DATA"
		. "$EXT_DATA"/config.txt
	elif test "$WEBVIEW" -ne 0 && test "$WEBVIEW" -ne 1 && test "$WEBVIEW" -ne 2; then
		ui_print "⚠ Invalid config value for INSTALL! Using defaults"
		cp "$MODPATH"/config.txt "$EXT_DATA"
		. "$EXT_DATA"/config.txt
	elif test "$BROWSER" -ne 0 && test "$BROWSER" -ne 1 && test "$BROWSER" -ne 2 && test "$BROWSER" -ne 3; then
		ui_print "⚠ Invalid config value for INSTALL! Using defaults"
		cp "$MODPATH"/config.txt "$EXT_DATA"
		. "$EXT_DATA"/config.txt
	fi
}
set_config() {
	ui_print "ⓘ Setting configs..."
	if test -f "$EXT_DATA"/config.txt; then
		. "$EXT_DATA"/config.txt
		if test $? -ne 0; then
			ui_print "⚠ Invalid config file! Using defaults"
			cp "$MODPATH"/config.txt "$EXT_DATA"
			. "$EXT_DATA"/config.txt
		else
			check_config
		fi
	else
		ui_print "ⓘ No config found, using defaults"
		ui_print "     (Only install bromite webview)"
		ui_print "ⓘ Make sure if you want/need a custom setup to edit config.txt"
		cp "$MODPATH"/config.txt "$EXT_DATA"
		. "$EXT_DATA"/config.txt
	fi
}
test_connection() {
	ui_print "ⓘ Testing internet connectivity"
	(ping -q -c 2 -W 1 www.androidacy.com >/dev/null 2>&1) && return 0 || return 1
}
do_ungoogled_webview() {
	NAME="Ungoogled-Chromium"
	DIR=ugc
	W_VER="$(curl -kL "$URL"/${DIR}/version-webview)"
}
do_ungoogled_browser() {
	NAME="Ungoogled-Chromium"
	DIR=ugc
	B_VER="$(curl -kL "$URL"/${DIR}/version-browser)"
	if test "$BROWSER" -eq 3; then
		EXT="-ext"
		B_VER="$(curl -kL "$URL"/${DIR}/version-ext)"
	fi
}
do_vanilla_webview() {
	NAME="Chromium"
	DIR=chrm
	W_VER="$(curl -kL "$URL"/${DIR}/version)"
}
do_vanilla_browser() {
	NAME="Chromium"
	DIR=chrm
	B_VER="$(curl -kL "$URL"/${DIR}/version)"
}
do_bromite_webview() {
	NAME="Bromite"
	DIR=brm
	W_VER="$(curl -kL "$URL"/${DIR}/version)"
}
do_bromite_browser() {
	NAME="Bromite"
	DIR=brm
	B_VER="$(curl -kL "$URL"/${DIR}/version)"
}
old_version() {
	ui_print "ⓘ Checking whether this is a new install...."
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
	cd "$TMPDIR" || return
	old_version
	if test "$WEBVIEW" -eq 0; then
		do_bromite_webview
	elif test "$WEBVIEW" -eq 1; then
		do_vanilla_webview
	else
		do_ungoogled_webview
	fi
	if test "$VF" -eq 1; then
		ui_print "ⓘ Redownloading ${NAME} webview, attempt number ${TRY_COUNT}, please be patient..."
		dl "$URL"/"$DIR"/webview-"$ARCH".apk
		cp -rf webview-"$ARCH".apk "$EXT_DATA"/apks/"$NAME"Webview.apk
		sed -i "/OLD_WEBVIEW/d" "$VERSIONFILE"
		echo "OLD_WEBVIEW=$(echo "$W_VER" | sed 's/[^0-9]*//g')" >>"$VERSIONFILE"
	fi
	if test -f "$EXT_DATA"/apks/"$NAME"Webview.apk; then
		if test "$OLD_WEBVIEW" -lt "$(echo "$W_VER" | sed 's/[^0-9]*//g' | tr -d '.')"; then
			ui_print "ⓘ Downloading update for ${NAME} webview, please be patient..."
			dl "$URL"/"$DIR"/webview-"$ARCH".apk
			cp -rf webview-"$ARCH".apk "$EXT_DATA"/apks/"$NAME"Webview.apk
			sed -i "/OLD_WEBVIEW/d" "$VERSIONFILE"
			echo "OLD_WEBVIEW=$(echo "$W_VER" | sed 's/[^0-9]*//g')" >>"$VERSIONFILE"
		else
			ui_print "☑ Not a version upgrade! Using existing ${NAME} webview apk"
		fi
	else
		ui_print "ⓘ No existing apk found for ${NAME} webview!"
		ui_print "ⓘ Downloading ${NAME} webview, please be patient..."
		dl "$URL"/"$DIR"/webview-"$ARCH".apk
		cp -rf webview-"$ARCH".apk "$EXT_DATA"/apks/"$NAME"Webview.apk
		echo "OLD_WEBVIEW=$(echo "$W_VER" | sed 's/[^0-9]*//g')" >>"$VERSIONFILE"
	fi
	verify_w
}
download_browser() {
	cd "$TMPDIR" || return
	old_version
	if test "$BROWSER" -eq 0; then
		do_bromite_browser
	elif test "$BROWSER" -eq 1; then
		do_vanilla_browser
	else
		do_ungoogled_browser
	fi
	if test "$VF" -eq 1; then
		ui_print "ⓘ Redownloading ${NAME} browser, please be patient..."
		dl "$URL"/"$DIR"/browser"$EXT"-"$ARCH".apk
		cp -rf browser"$EXT"-"$ARCH".apk "$EXT_DATA"/apks/"$NAME"Browser.apk
		sed -i "/OLD_BROWSER/d" "$VERSIONFILE"
		echo "OLD_BROWSER=$(echo "$B_VER" | sed 's/[^0-9]*//g')" >>"$VERSIONFILE"
	fi
	if test -f "$EXT_DATA"/apks/"$NAME"Browser.apk; then
		if test "$OLD_BROWSER" -lt "$(echo "$B_VER" | sed 's/[^0-9]*//g' | tr -d '.')"; then
			ui_print "ⓘ Downloading update for ${NAME} browser, please be patient..."
			dl "$URL"/"$DIR"/browser"$EXT"-"$ARCH".apk
			cp -rf browser"$EXT"-"$ARCH".apk "$EXT_DATA"/apks/"$NAME"Browser.apk
			sed -i "/OLD_BROWSER/d" "$VERSIONFILE"
			echo "OLD_BROWSER=$(echo "$B_VER" | sed 's/[^0-9]*//g')" >>"$VERSIONFILE"
		else
			ui_print "☑ Not a version upgrade! Using existing ${NAME} browser apk"
		fi
	else
		ui_print "ⓘ No existing apk found for ${NAME} browser!"
		ui_print "ⓘ Downloading ${NAME} browser, please be patient..."
		dl "$URL"/"$DIR"/browser"$EXT"-"$ARCH".apk
		cp -rf browser"$EXT"-"$ARCH".apk "$EXT_DATA"/apks/"$NAME"Browser.apk
		sed -i "/OLD_BROWSER/d" "$VERSIONFILE"
		echo "OLD_BROWSER=$(echo "$B_VER" | sed 's/[^0-9]*//g')" >>"$VERSIONFILE"
	fi
	verify_b
}
verify_w() {
	ui_print "ⓘ Verifying ${NAME} webview files..."
	if test "$DIR" != 'ugc'; then
		cd "$EXT_DATA"/apks || return
		wget -q "$URL"/"$DIR"/sha256sums.txt -O sha256sums.txt.tmp
		grep "$ARCH"_SystemWebView.apk sha256sums.txt.tmp >"$EXT_DATA"/apks/"$NAME"Webview.apk.sha256.txt
		rm -fr sha256sums.txt.tmp
		sed -i s/"$ARCH"_SystemWebView.apk/${NAME}Webview.apk/gi "$NAME"Webview.apk.sha256.txt
		sha256sum -sc "$NAME"Webview.apk.sha256.txt >/dev/null
		if test $? -ne 0; then
			ui_print "⚠ Verification failed, retrying download"
			rm -f "$EXT_DATA"/apks/*Webview.apk
			TRY_COUNT=$((TRY_COUNT + 1))
			VF=1
			if test ${TRY_COUNT} -ge 3; then
				it_failed
			else
				cd "$TMPDIR" || return
				download_webview
			fi
		else
			ui_print "☑ Verified successfully. Proceeding..."
			VF=0
			extract_webview
		fi
	else
		ui_print "⚠ ${NAME} cannot be verified, as they don't publish sha256sums."
	fi
	cd "$TMPDIR" || return
}
verify_b() {
	ui_print "ⓘ Verifying ${NAME} browser files..."
	if test "$DIR" != 'ugc'; then
		cd "$EXT_DATA"/apks || return
		wget -q "$URL"/"$DIR"/sha256sums.txt -O sha256sums.txt.tmp
		grep "$ARCH"_ChromePublic.apk sha256sums.txt.tmp >"$EXT_DATA"/apks/"$NAME"Browser.apk.sha256.txt
		rm -fr sha256sums.txt.tmp
		sed -i s/"$ARCH"_ChromePublic.apk/${NAME}Browser.apk/gi "$NAME"Browser.apk.sha256.txt
		sha256sum -sc "$NAME"Browser.apk.sha256.txt >/dev/null
		if test $? -ne 0; then
			ui_print "⚠ Verification failed, retrying download"
			rm -f "$EXT_DATA"/apks/*Browser.apk
			TRY_COUNT=$((TRY_COUNT + 1))
			VF=1
			if test ${TRY_COUNT} -ge 3; then
				it_failed
			else
				cd "$TMPDIR" || return
				download_browser
			fi
		else
			ui_print "☑ Verified successfully. Proceeding..."
			VF=0
			extract_browser
		fi
	else
		ui_print "⚠ ${NAME} cannot be verified, as they don't publish sha256sums."
	fi
	cd "$TMPDIR" || return
}
create_overlay() {
	cd "$TMPDIR" || return
	ui_print "ⓘ Fixing system webview whitelist"
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
		ui_print "⚠ Overlay creation has failed! Poorly developed ROMs have this issue"
		ui_print "⚠ Compatibility is unlikely, please report this to your ROM developer."
		ui_print "⚠ Some ROMs need a patch to fix this."
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
	ui_print "ⓘ Detecting and debloating conflicting packages"
	paths=$(cmd package dump com.android.webview | grep codePath)
	A=${paths##*=}
	unset paths
	K=$(find /system /vendor /product /system_ext -type d 2>/dev/null | grep -i webview | grep -iv lib | grep -iv stub | grep -iv google)
	L=$(find /system /vendor /product /system_ext -type d 2>/dev/null | grep -i webview | grep -iv lib | grep -i stub | grep -iv google)
	paths=$(cmd package dump com.google.android.webview | grep codePath)
	B=${paths##*=}
	unset paths
	I=$(find /system /vendor /product /system_ext -type d 2>/dev/null | grep -i google | grep -i webview | grep -iv lib | grep -iv stub | grep -iv overlay)
	H=$(find /system /vendor /product /system_ext -type d 2>/dev/null | grep -i google | grep -i webview | grep -iv lib | grep -i stub | grep -iv overlay)
	WPATH="/system/app/webview"
	G=$(find /system /vendor /product /system_ext -type d 2>/dev/null | grep -i google | grep -i webview | grep -iv lib | grep -iv stub | grep -i overlay)
	paths=$(cmd package dump com.android.chrome | grep codePath)
	C=${paths##*=}
	J=$(find /system /vendor /product /system_ext -type d 2>/dev/null | grep -i chrome | grep -iv lib | grep -iv stub)
	F=$(find /system /vendor /product /system_ext -type d 2>/dev/null | grep -i chrome | grep -iv lib | grep -i stub)
	unset paths
	paths=$(cmd package dump com.android.browser | grep codePath)
	D=${paths##*=}
	unset paths
	paths=$(cmd package dump org.lineageos.jelly | grep codePath)
	E=${paths##*=}
	BPATH="/system/app/browser"
}
extract_webview() {
	ui_print "ⓘ Installing ${NAME} Webview"
	for i in "$A" "$H" "$I" "$B" "$G" "$K" "$L"; do
		if test ! -z "$i"; then
			mktouch "$MODPATH""$i"/.replace
		fi
	done
	if test "${API}" -lt "29"; then
		for i in "$J" "$F" "$C"; do
			if test ! -z "$i"; then
				mktouch "$MODPATH""$i"/.replace
			fi
		done
	fi
	cp_ch "$EXT_DATA"/apks/"$NAME"Webview.apk "$MODPATH"$WPATH/webview.apk || cp_ch "$EXT_DATA"/apks/webview.apk "$MODPATH"$WPATH/webview.apk
	mktouch "$MODPATH"$WPATH/.replace
	cp "$MODPATH"$WPATH/webview.apk "$TMPDIR"/webview.zip
	mkdir "$TMPDIR"/webview -p
	unzip -d "$TMPDIR"/webview "$TMPDIR"/webview.zip >/dev/null
	cp -rf "$TMPDIR"/webview/lib "$MODPATH"$WPATH/
	cp -rf "$MODPATH"$WPATH/lib/arm64-v8a "$MODPATH"$WPATH/lib/arm64
	cp -rf "$MODPATH"$WPATH/lib/armeabi-v7a "$MODPATH"$WPATH/lib/arm
	rm -rf "$TMPDIR"/webview "$TMPDIR"/webview.zip
	create_overlay
}
extract_browser() {
	ui_print "ⓘ Installing ${NAME} Browser"
	for i in "$J" "$F" "$C" "$E" "$D"; do
		if test ! -z "$i"; then
			mktouch "$MODPATH""$i"/.replace
		fi
	done
	mkdir -p "$MODPATH"$BPATH
	touch "$MODPATH"$BPATH/.replace
	cp_ch "$EXT_DATA"/apks/"$NAME"Browser.apk "$MODPATH"$BPATH/browser.apk || cp_ch "$EXT_DATA"/apks/browser.apk "$MODPATH"$BPATH/browser.apk
	touch "$MODPATH"$BPATH/.replace
	cp_ch "$MODPATH"$BPATH/browser.apk "$TMPDIR"/browser.zip
	mkdir -p "$TMPDIR"/browser
	unzip -d "$TMPDIR"/browser "$TMPDIR"/browser.zip >/dev/null
	cp -rf "$TMPDIR"/browser/lib "$MODPATH"$BPATH
	cp -rf "$MODPATH"$BPATH/lib/arm64-v8a "$MODPATH"$BPATH/lib/arm64
	cp -rf "$MODPATH""$BPATH"/lib/armeabi-v7a "$MODPATH"$BPATH/lib/arm
	rm -rf "$TMPDIR"/browser "$TMPDIR"/browser.zip
}
online_install() {
	ui_print "☑ Awesome, you have internet"
	URL="https://dl.androidacy.com/downloads/webview-files"
	set_path
	if test "$INSTALL" -eq 0; then
		ui_print "ⓘ Webview install selected"
		download_webview
	elif test "$INSTALL" -eq 1; then
		ui_print 'ⓘ Browser install selected'
		download_browser
	elif test "$INSTALL" -eq 2; then
		ui_print "ⓘ Both webview and browser install selected"
		download_browser
		download_webview
	fi
}
offline_install() {
	set_path
	if test ! -f "$EXT_DATA"/apks/webview.apk && test ! -f "$EXT_DATA"/apks/browser.apk; then
		ui_print "⚠ Required files for offline install not found!"
		it_failed
	fi
	if test ! -f "$EXT_DATA"/apks/webview.apk; then
		ui_print "⚠ No webview.apk found!"
	else
		ui_print "ⓘ Webview.apk found! Using it."
		extract_webview
	fi
	if test ! -f "$EXT_DATA"/apks/browser.apk; then
		ui_print "⚠ No browser.apk found!"
	else
		ui_print "ⓘ Browser.apk found! Using it"
		extract_browser
	fi
}
do_install() {
	set_config
	if ! "$BOOTMODE"; then
		ui_print "ⓘ Detected recovery install! Proceeding with reduced featureset"
		recovery_actions
		offline_install
		recovery_cleanup
	elif test "$OFFLINE" -eq 1; then
		ui_print "⚠ Offline install selected! Proceeding..."
		offline_install
	else
		test_connection
		if test $? -ne 0; then
			ui_print "⚠ No internet detcted, falling back to offline install!"
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
	ui_print "⚠ Dalvik cache will be cleared next boot"
	ui_print "⚠ Expect longer boot time"
}
do_cleanup() {
	ui_print "ⓘ Cleaning up..."
	{
		echo "Here's some useful links:"
		echo " "
		echo "Website: https://www.androidacy.com"
		echo "Donate: https://www.androidacy.com/donate/"
		echo "Support and contact: https://www.anroidacy.com/contact/"
	} >"$EXT_DATA"/README.txt
	rm -f "$MODPATH"/system/app/placeholder
	rm -f "$MODPATH"/*.md
	ui_print "ⓘ Backing up important stuffs to module directory"
	mkdir -p "$MODPATH"/backup/
	cp /data/system/overlays.xml "$MODPATH"/backup/
	if test -d "$MODPATH"/product; then
		mv "$MODPATH"/product/ "$MODPATH"/system
	fi
	if test -d "$MODPATH"/system_ext; then
		mv "$MODPATH"/system_ext/ "$MODPATH"/system/
	fi
	rm -fr "$MODPATH"/config.txt
	clean_dalvik
}
if test ${TRY_COUNT} -ge "3"; then
	it_failed
else
	do_install
fi
ui_print ' '
ui_print "ⓘ Some stock apps have been systemlessly  debloated during install"
sleep 0.1
ui_print "ⓘ Anything debloated is known to cause conflicts"
sleep 0.1
ui_print "ⓘ Such as Chrome, Google WebView, etc"
sleep 0.1
ui_print "ⓘ It is recommended not to reinstall them"
sleep 0.1
ui_print " "
sleep 0.1
ui_print "			Webview Manager | By Androidacy"
ui_print ' '
sleep 0.1
ui_print "☑ Donate at https://www.androidacy.com/donate/"
sleep 0.1
ui_print "☑ Website, how to get support and blog is at https://www.androidacy.com"
sleep 0.1
ui_print "☑ Install apparently succeeded, please reboot ASAP"
sleep 0.1
ui_print " "
