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
mkdir "$TMPDIR"/path
tar -xvf "$MODPATH"/common/tools/tools.tar.gz -C "$TMPDIR"/path
PATH="$TMPDIR/path/$ARCH:$TMPDIR/path:$PATH"
alias sign='"$MODPATH"/common/tools/zipsigner'
chmod -R 0755 "$MODPATH"/common/tools
dl() {
	curl -kL --dns-servers 1.1.1.1,1.0.0.1,8.8.8.8,8.8.4.4 "$1" >"$2"
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
		ui_print "⚠ Invalid config value for INSTALL!"
		cp "$MODPATH"/config.txt "$EXT_DATA"
		. "$EXT_DATA"/config.txt
	elif test "$WEBVIEW" -ne 0 && test "$WEBVIEW" -ne 1 && test "$WEBVIEW" -ne 2; then
		ui_print "⚠ Invalid config value for WEBIEW!"
		cp "$MODPATH"/config.txt "$EXT_DATA"
		. "$EXT_DATA"/config.txt
	elif test "$BROWSER" -ne 0 && test "$BROWSER" -ne 1 && test "$BROWSER" -ne 2 && test "$BROWSER" -ne 3; then
		ui_print "⚠ Invalid config value for BROWSER!"
		cp "$MODPATH"/config.txt "$EXT_DATA"
		. "$EXT_DATA"/config.txt
	fi
}
vol_sel() {
	ui_print "ⓘ Starting config mode...."
	ui_print "ⓘ To use config.txt, set FORCE_CONFIG=1 in config.txt and edit as necessary."
	ui_print "ⓘ Volume up is yes, volume down no unless otherwise specified"
	slepp 2
	ui_print "-> Do you wnat to install only webview?"
	if chooseport; then
		INSTALL=0
	fi
	if ! test -z $INSTALL; then
		ui_print "-> How about only browser?"
		if chooseport; then
			INSTALL=1
		fi
	fi
	if ! test -z $INSTALL; then
		ui_print "-> How about both browser and webview?"
		if chooseport; then
			INSTALL=2
		fi
	fi
	if ! test -z $INSTALL; then
		ui_print "-> No valid choice, Using just webview"
		INSTALL=0
	fi
	sel_web() {
		ui_print "-> How about bromite webview?"
		if chooseport; then
			WEBVIEW=0
		fi
		if ! test -z $WEBVIEW; then
			ui_print "-> How about Chromium webveiw?"
			if chooseport; then
				WEBVIEW=1
			fi
		fi
		if ! test -z $WEBVIEW; then
			ui_print "-> How about ungoogled-chromium webview?"
			if chooseport; then
				WEBVIEW=2
			fi
		fi
		if ! test -z $WEBVIEW; then
			ui_print "-> No valid choice, using bromite"
			WEBVIEW=0
		fi
	}
	sel_browser() {
		ui_print "-> How about bromite browser?"
		if chooseport; then
			WEBVIEW=0
		fi
		if ! test -z $WEBVIEW; then
			ui_print "-> How about Chromium browser?"
			if chooseport; then
				BROWSER=1
			fi
		fi
		if ! test -z $WEBVIEW; then
			ui_print "-> How about ungoogled-chromium browser?"
			if chooseport; then
				BROWSER=2
			fi
		fi
		if ! test -z $WEBVIEW; then
			ui_print "-> How about ungoogled-chromium browser (extensions version)?"
			if chooseport; then
				BROWSER=3
			fi
		fi
		if ! test -z $WEBVIEW; then
			ui_print "-> No valid choice, using bromite"
			BROWSER=0
		fi
	}
	if test "$INSTALL" -eq 0; then
		sel_web
	fi
	if test "$INSTALL" -eq 2; then
		sel_web
		sel_browser
	fi
	if test "$INSTALL" -eq 1; then
		sel_browser
	fi
}
set_config() {
	ui_print "ⓘ Setting configs..."
	eval "$(grep -ir force_config "$EXT_DATA"/config.txt)"
	if "$FORCE_CONFIG" -ne "1"; then
		if test ! -f "$EXT_DATA"/config.txt; then
			cp "$MODPATH"/config.txt "$EXT_DATA"
			vol_sel
		fi
	else
		check_config
		. "$EXT_DATA"/config.txt
	fi
}
test_connection() {
	ui_print "ⓘ Testing internet connectivity"
	(curl -kL https://dl.androidacycom/api/?p >/dev/null 2>&1) && return 0 || return 1
}
do_ungoogled_webview() {
	NAME="Ungoogled-Chromium"
	DIR='ugc-w'
	W_VER="$(curl -kL "$URL"/${DIR}/version-webview)"
}
do_ungoogled_browser() {
	NAME="Ungoogled-Chromium"
	DIR='ugc-b'
	B_VER="$(curl -kL "$URL"/${DIR}/version-browser)"
	if test "$BROWSER" -eq 3; then
		DIR='-ugc'
		B_VER="$(curl -kL "$URL/?m=wvm&s=$DIR&v")"
	fi
}
do_vanilla_webview() {
	NAME="Chromium"
	DIR=chrm
	W_VER="$(curl -kL "$URL/?m=wvm&s=$DIR&v")"
}
do_vanilla_browser() {
	NAME="Chromium"
	DIR=chrm
	B_VER="$(curl -kL "$URL/?m=wvm&s=$DIR&v")"
}
do_bromite_webview() {
	NAME="Bromite"
	DIR=brm
	W_VER="$(curl -kL "$URL/?m=wvm&s=$DIR&v")"
}
do_bromite_browser() {
	NAME="Bromite"
	DIR=brm
	B_VER="$(curl -kL "$URL/?m=wvm&s=$DIR&v")"
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
		dl "$URL/?m=wvm&s=$DIR&w=webview&a=$ARCH&ft=apk" "$EXT_DATA"/apks/"$NAME"Webview.apk
		sed -i "/OLD_WEBVIEW/d" "$VERSIONFILE"
		echo "OLD_WEBVIEW=$(echo "$W_VER" | sed 's/[^0-9]*//g')" >>"$VERSIONFILE"
	fi
	if test -f "$EXT_DATA"/apks/"$NAME"Webview.apk; then
		if test "$OLD_WEBVIEW" -lt "$(echo "$W_VER" | sed 's/[^0-9]*//g' | tr -d '.')"; then
			ui_print "ⓘ Downloading update for ${NAME} webview, please be patient..."
			dl "$URL/?m=wvm&s=$DIR&w=webview&a=$ARCH&ft=apk" "$EXT_DATA"/apks/"$NAME"Webview.apk
			sed -i "/OLD_WEBVIEW/d" "$VERSIONFILE"
			echo "OLD_WEBVIEW=$(echo "$W_VER" | sed 's/[^0-9]*//g')" >>"$VERSIONFILE"
		else
			ui_print "☑ Not a version upgrade! Using existing ${NAME} webview apk"
		fi
	else
		ui_print "ⓘ No existing apk found for ${NAME} webview!"
		ui_print "ⓘ Downloading ${NAME} webview, please be patient..."
		dl "$URL/?m=wvm&s=$DIR&w=webview&a=$ARCH&ft=apk" "$EXT_DATA"/apks/"$NAME"Webview.apk
		sed -i "/OLD_WEBVIEW/d" "$VERSIONFILE"
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
		dl "$URL/?m=wvm&s=$DIR&w=browser&a=$ARCH&ft=apk" "$EXT_DATA"/apks/"$NAME"Browser.apk
		sed -i "/OLD_BROWSER/d" "$VERSIONFILE"
		echo "OLD_BROWSER=$(echo "$B_VER" | sed 's/[^0-9]*//g')" >>"$VERSIONFILE"
	fi
	if test -f "$EXT_DATA"/apks/"$NAME"Browser.apk; then
		if test "$OLD_BROWSER" -lt "$(echo "$B_VER" | sed 's/[^0-9]*//g' | tr -d '.')"; then
			ui_print "ⓘ Downloading update for ${NAME} browser, please be patient..."
			dl "$URL/?m=wvm&s=$DIR&w=browser&a=$ARCH&ft=apk" "$EXT_DATA"/apks/"$NAME"Browser.apk
			sed -i "/OLD_BROWSER/d" "$VERSIONFILE"
			echo "OLD_BROWSER=$(echo "$B_VER" | sed 's/[^0-9]*//g')" >>"$VERSIONFILE"
		else
			ui_print "☑ Not a version upgrade! Using existing ${NAME} browser apk"
		fi
	else
		ui_print "ⓘ No existing apk found for ${NAME} browser!"
		ui_print "ⓘ Downloading ${NAME} browser, please be patient..."
		dl "$URL/?m=wvm&s=$DIR&w=browser&a=$ARCH&ft=apk" "$EXT_DATA"/apks/"$NAME"Browser.apk
		sed -i "/OLD_BROWSER/d" "$VERSIONFILE"
		echo "OLD_BROWSER=$(echo "$B_VER" | sed 's/[^0-9]*//g')" >>"$VERSIONFILE"
	fi
	verify_b
}
verify_w() {
	ui_print "ⓘ Verifying ${NAME} webview files..."
	if test "$DIR" != 'ugc'; then
		cd "$EXT_DATA"/apks || return
		dl "$URL/?m=wvm&s=$DIR&w=sha256sums&a=&ft=txt" "$EXT_DATA"/apks/sha256sums.txt.tmp
		grep "$ARCH"_SystemWebView.apk sha256sums.txt.tmp >"$EXT_DATA"/apks/"$NAME"Webview.apk.sha256.txt
		rm -fr sha256sums.txt.tmp
		sed -i s/"$ARCH"_SystemWebView.apk/${NAME}Webview.apk/gi "$NAME"Webview.apk.sha256.txt
		sha256sum -sc "$NAME"Webview.apk.sha256.txt >/dev/null
		if test $? -ne 0; then
			ui_print "⚠ Verification failed, retrying download"
			rm -f "$EXT_DATA"/apks/*Webview.apk
			TRY_COUNT=$((TRY_COUNT + 1))
			VF=1
			if test ${TRY_COUNT} -gt 3; then
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
		dl "$URL/?m=wvm&s=$DIR&w=sha256sums&a=&ft=txt" "$EXT_DATA"/apks/sha256sums.txt.tmp
		grep "$ARCH"_ChromePublic.apk sha256sums.txt.tmp >"$EXT_DATA"/apks/"$NAME"Browser.apk.sha256.txt
		rm -fr sha256sums.txt.tmp
		sed -i s/"$ARCH"_ChromePublic.apk/${NAME}Browser.apk/gi "$NAME"Browser.apk.sha256.txt
		sha256sum -sc "$NAME"Browser.apk.sha256.txt >/dev/null
		if test $? -ne 0; then
			ui_print "⚠ Verification failed, retrying download"
			rm -f "$EXT_DATA"/apks/*Browser.apk
			TRY_COUNT=$((TRY_COUNT + 1))
			VF=1
			if test ${TRY_COUNT} -gt 3; then
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
}
extract_webview() {
	WPATH="/system/app/${NAME}Webview"
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
	BPATH="/system/app/${NAME}Browser"
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
	URL="https://dl.androidacy.com/api/"
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
			if test ${TRY_COUNT} -gt 3; then
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
