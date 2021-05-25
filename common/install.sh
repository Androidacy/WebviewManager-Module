# shellcheck shell=dash
# shellcheck disable=SC1091,SC1090,SC2139,SC3010
TRY_COUNT=1
VF=0
OLD_WEBVIEW=0
OLD_BROWSER=0
VERIFY=true
ui_print "ⓘ Your device is a $D with android $A, sdk$API, with an $ARCH cpu"
VERSIONFILE="$EXT_DATA/version.txt"
VEN=/system/vendor
[ -L /system/vendor ] && VEN=/vendor
if [ -f $VEN/build.prop ]; then
	export BUILDS="/system/build.prop $VEN/build.prop"
else
	BUILDS="/system/build.prop"
fi
check_config() {
	if [[ "$CV" -ne 6 ]]; then
		ui_print "⚠ Wrong config version! Using defaults"
		cp "$MODPATH"/config.txt "$EXT_DATA"
		. "$EXT_DATA"/config.txt
	fi
	overrid_conf() {
		cp "$MODPATH"/config.txt "$EXT_DATA"
		vol_sel
	}
	if [[ $FORCE_CONFIG -ne 0 ]] && [[ $FORCE_CONFIG -ne 1 ]]; then
		ui_print "⚠ Invalid config value for FORCE_CONFIG!"
		overrid_conf
	elif [[ $OFFLINE -ne 0 ]] && [[ $OFFLINE -ne 1 ]]; then
		ui_print "⚠ Invalid config value for OFFLINE!"
		overrid_conf
	elif [[ $INSTALL -ne 0 ]] && [[ $INSTALL -ne 1 ]] && [[ $INSTALL -ne 2 ]]; then
		ui_print "⚠ Invalid config value for INSTALL!"
		overrid_conf
	elif [[ $WEBVIEW -ne 0 ]] && [[ $WEBVIEW -ne 1 ]] && [[ $WEBVIEW -ne 2 ]]; then
		ui_print "⚠ Invalid config value for WEBIEW!"
		overrid_conf
	elif [[ $BROWSER -ne 0 ]] && [[ $BROWSER -ne 1 ]] && [[ $BROWSER -ne 2 ]] && [[ $BROWSER -ne 3 ]]; then
		ui_print "⚠ Invalid config value for BROWSER!"
		overrid_conf
	fi
}
vol_sel() {
	ui_print "ⓘ Starting config mode...."
	ui_print "ⓘ To use config.txt, set FORCE_CONFIG=1 in config.txt and edit as necessary."
	ui_print "ⓘ Volume up to accept the current choice, and down to move to next option"
	sleep 2
	ui_print "-> Do you wnat to install only webview?"
	unset INSTALL
	if chooseport; then
		INSTALL=0
	fi
	if [[ -z $INSTALL ]]; then
		ui_print "-> How about only browser?"
		if chooseport; then
			INSTALL=1
		fi
	fi
	if [[ -z $INSTALL ]]; then
		ui_print "-> How about both browser and webview?"
		if chooseport; then
			INSTALL=2
		fi
	fi
	if [[ -z $INSTALL ]]; then
		ui_print "-> No valid choice, Using just webview"
		INSTALL=0
	fi
	sel_web() {
		unset WEBVIEW
		ui_print "-> Please choose your webview."
		ui_print "  1. Bromite"
		if chooseport; then
			WEBVIEW=0
		fi
		if [[ -z $WEBVIEW ]]; then
			ui_print "  2. Chromium"
			if chooseport; then
				WEBVIEW=1
			fi
		fi
		if [[ -z $WEBVIEW ]]; then
			ui_print "  3. Ungoogled Chromium"
			if chooseport; then
				WEBVIEW=2
			fi
		fi
		if [[ -z $WEBVIEW ]]; then
			ui_print "-> No valid choice, using bromite"
			WEBVIEW=0
		fi
	}
	sel_browser() {
		unset BROWSER
		ui_print "-> Please choose your browser."
		ui_print "  1. Bromite"
		if chooseport; then
			WEBVIEW=0
		fi
		if [[ -z $BROWSER ]]; then
			ui_print "  2. Chromium"
			if chooseport; then
				BROWSER=1
			fi
		fi
		if [[ -z $BROWSER ]]; then
			ui_print "  3. Ungoogled Chromium"
			if chooseport; then
				BROWSER=2
			fi
		fi
		if [[ -z $BROWSER ]]; then
			ui_print "  4. Ungoogled Chromium (extensions support version)?"
			if chooseport; then
				BROWSER=3
			fi
		fi
		if [[ -z $BROWSER ]]; then
			ui_print "-> No valid choice, using bromite"
			BROWSER=0
		fi
	}
	if [[ "$INSTALL" -eq 0 ]]; then
		sel_web
	fi
	if [[ "$INSTALL" -eq 2 ]]; then
		sel_web
		sel_browser
	fi
	if [[ "$INSTALL" -eq 1 ]]; then
		sel_browser
	fi
	ui_print "ⓘ Config complete! Proceeding."
}
set_config() {
	ui_print "ⓘ Setting configs..."
	if [[ ! -f "$EXT_DATA"/config.txt ]]; then
		cp "$MODPATH"/config.txt "$EXT_DATA"
		vol_sel
	else
		FORCE_CONFIG=0
		. "$EXT_DATA"/config.txt
		if [[ "$FORCE_CONFIG" -eq 1 ]]; then
			check_config
		else
			cp "$MODPATH"/config.txt "$EXT_DATA"
			vol_sel
		fi
	fi
}
do_ungoogled_webview() {
	NAME="Ungoogled-Chromium"
	DIR='ugc-w'
	W_VER=$(get_v)
}
do_ungoogled_browser() {
	NAME="Ungoogled-Chromium"
	DIR='ugc-b'
	B_VER=$(get_v)
	if [[ $BROWSER -eq 3 ]]; then
		DIR='ugc-e'
		B_VER=$(get_v)
	fi
}
do_vanilla_webview() {
	NAME="Chromium"
	DIR=chrm
	W_VER=$(get_v)
}
do_vanilla_browser() {
	NAME="Chromium"
	DIR=chrm
	B_VER=$(get_v)
}
do_bromite_webview() {
	NAME="Bromite"
	DIR=brm
	W_VER=$(get_v)
}
do_bromite_browser() {
	NAME="Bromite"
	DIR=brm
	B_VER=$(get_v)
}
old_version() {
	ui_print "ⓘ Checking whether this is a new install...."
	if [[ ! -f $EXT_DATA/version.txt ]]; then
		echo "OLD_BROWSER=0" >"$VERSIONFILE"
		echo "OLD_WEBVIEW=0" >>"$VERSIONFILE"
		. "$EXT_DATA"/version.txt
	else
		if ! . "$EXT_DATA"/version.txt; then
			echo "OLD_BROWSER=0" >"$VERSIONFILE"
			echo "OLD_WEBVIEW=0" >>"$VERSIONFILE"
			. "$EXT_DATA"/version.txt
		fi
	fi
}
download_webview() {
	cd "$TMPDIR" || return
	if [[ $WEBVIEW -eq 0 ]]; then
		do_bromite_webview
	elif [[ $WEBVIEW -eq 1 ]]; then
		do_vanilla_webview
	else
		do_ungoogled_webview
	fi
	if [[ "$VF" -eq 1 ]]; then
		ui_print "ⓘ Redownloading ${NAME} webview, attempt number ${TRY_COUNT}, please be patient..."
		dl "&s=$DIR&w=webview&ft=apk" "${EXT_DATA}/apks/${NAME}Webview.apk" "download"
		sed -i "/OLD_WEBVIEW/d" "$VERSIONFILE"
		echo "OLD_WEBVIEW=$(echo "$W_VER" | sed 's/[^0-9]*//g')" >>"$VERSIONFILE"
	else
		old_version
	fi
	if [[ -f $EXT_DATA/apks/"$NAME"Webview.apk ]]; then
		if [[ $OLD_WEBVIEW -lt "$(echo "$W_VER" | sed 's/[^0-9]*//g' | tr -d '.')" ]]; then
			ui_print "ⓘ Downloading update for ${NAME} webview, please be patient..."
			dl "&s=$DIR&w=webview&ft=apk" "${EXT_DATA}/apks/${NAME}Webview.apk" "download"
			sed -i "/OLD_WEBVIEW/d" "$VERSIONFILE"
			echo "OLD_WEBVIEW=$(echo "$W_VER" | sed 's/[^0-9]*//g')" >>"$VERSIONFILE"
		else
			ui_print "☑ Not a version upgrade! Using existing ${NAME} webview apk"
		fi
	else
		ui_print "ⓘ No existing apk found for ${NAME} webview!"
		ui_print "ⓘ Downloading ${NAME} webview, please be patient..."
		dl "&s=$DIR&w=webview&ft=apk" "${EXT_DATA}/apks/${NAME}Webview.apk" "download"
		sed -i "/OLD_WEBVIEW/d" "$VERSIONFILE"
		echo "OLD_WEBVIEW=$(echo "$W_VER" | sed 's/[^0-9]*//g')" >>"$VERSIONFILE"
	fi
	verify_w
}
download_browser() {
	cd "$TMPDIR" || return
	if [[ $BROWSER -eq 0 ]]; then
		do_bromite_browser
	elif [[ $BROWSER -eq 1 ]]; then
		do_vanilla_browser
	else
		do_ungoogled_browser
	fi
	if [[ "$VF" -eq 1 ]]; then
		ui_print "ⓘ Redownloading ${NAME} browser, please be patient..."
		dl "&s=$DIR&w=browser&ft=apk" "${EXT_DATA}/apks/${NAME}Browser.apk" "download"
		sed -i "/OLD_BROWSER/d" "$VERSIONFILE"
		echo "OLD_BROWSER=$(echo "$B_VER" | sed 's/[^0-9]*//g')" >>"$VERSIONFILE"
	else
		old_version
	fi
	if [[ -f $EXT_DATA/apks/"$NAME"Browser.apk ]]; then
		if [[ $OLD_BROWSER -lt "$(echo "$B_VER" | sed 's/[^0-9]*//g' | tr -d '.')" ]]; then
			ui_print "ⓘ Downloading update for ${NAME} browser, please be patient..."
			dl "&s=$DIR&w=browser&ft=apk" "${EXT_DATA}/apks/${NAME}Browser.apk" "download"
			sed -i "/OLD_BROWSER/d" "$VERSIONFILE"
			echo "OLD_BROWSER=$(echo "$B_VER" | sed 's/[^0-9]*//g')" >>"$VERSIONFILE"
		else
			ui_print "☑ Not a version upgrade! Using existing ${NAME} browser apk"
		fi
	else
		ui_print "ⓘ No existing apk found for ${NAME} browser!"
		ui_print "ⓘ Downloading ${NAME} browser, please be patient..."
		dl "&s=$DIR&w=browser&ft=apk" "${EXT_DATA}/apks/${NAME}Browser.apk" "download"
		sed -i "/OLD_BROWSER/d" "$VERSIONFILE"
		echo "OLD_BROWSER=$(echo "$B_VER" | sed 's/[^0-9]*//g')" >>"$VERSIONFILE"
	fi
	verify_b
}
verify_w() {
	ui_print "ⓘ Verifying ${NAME} webview files..."
	if $VERIFY; then
		cd "$EXT_DATA"/apks || return
		O_S=$(md5sum "$NAME"Webview.apk | sed "s/\ $NAME.*//" | tr -d '[:space:]')
		T_S=$(dl "&s=$DIR&w=webview&ft=apk" '-' verify | tr -d '[:space:]')
		if [ "$T_S" != "$O_S" ]; then
			ui_print "⚠ Verification failed, retrying download"
			rm -f "$EXT_DATA"/apks/*Webview.apk
			TRY_COUNT=$((TRY_COUNT + 1))
			VF=1
			if [[ ${TRY_COUNT} -gt 3 ]]; then
				it_failed
			else
				cd "$TMPDIR" || return
				download_webview
			fi
		else
			ui_print "☑ Verified successfully. Proceeding..."
			VF=0
			rm -fr -- *"$ARCH"*.apk
			extract_webview
		fi
	else
		ui_print "⚠ ${NAME} cannot be verified, as they don't publish sha256sums."
	fi
	cd "$TMPDIR" || return
}
verify_b() {
	ui_print "ⓘ Verifying ${NAME} browser files..."
	if $VERIFY; then
		cd "$EXT_DATA"/apks || return
		O_S=$(md5sum "$NAME"Browser.apk | sed "s/\ $NAME.*//" | tr -d '[:space:]')
		T_S=$(dl "&s=$DIR&w=browser&ft=apk" '-' verify | tr -d '[:space:]')
		if [ "$T_S" != "$O_S" ]; then
			ui_print "⚠ Verification failed, retrying download"
			rm -f "$EXT_DATA"/apks/*Browser.apk
			TRY_COUNT=$((TRY_COUNT + 1))
			VF=1
			if [[ ${TRY_COUNT} -gt 3 ]]; then
				it_failed
			else
				cd "$TMPDIR" || return
				download_browser
			fi
		else
			ui_print "☑ Verified successfully. Proceeding..."
			VF=0
			rm -fr -- *"$ARCH"*.apk
			extract_browser
		fi
	else
		ui_print "⚠ ${NAME} cannot be verified, as they don't publish sha256sums."
		extract_browser
	fi
	cd "$TMPDIR" || return
}
create_overlay() {
	cd "$TMPDIR" || return
	ui_print "ⓘ Fixing system webview whitelist"
	if [[ "${API}" -ge "29" ]]; then
		aapt p -f -v -M "$MODPATH"/common/overlay10/AndroidManifest.xml -I /system/framework/framework-res.apk -S "$MODPATH"/common/overlay10/res -F "$MODPATH"/unsigned.apk >"$MODPATH"/logs/aapt.log
	else
		aapt p -f -v -M "$MODPATH"/common/overlay9/AndroidManifest.xml -I /system/framework/framework-res.apk -S "$MODPATH"/common/overlay9/res -F "$MODPATH"/unsigned.apk >"$MODPATH"/logs/aapt.log
	fi
	if [[ -f "$MODPATH"/unsigned.apk ]]; then
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
		if [[ -n "$i" ]]; then
			mktouch "$MODPATH""$i"/.replace
		fi
	done
	if [[ "${API}" -lt "29" ]]; then
		for i in "$J" "$F" "$C"; do
			if [[ -n "$i" ]]; then
				mktouch "$MODPATH""$i"/.replace
			fi
		done
	fi
	mktouch "$MODPATH"$WPATH/.replace
	cp_ch "$EXT_DATA"/apks/"$NAME"Webview.apk "$MODPATH"$WPATH/webview.apk || cp_ch "$EXT_DATA"/apks/webview.apk "$MODPATH"$WPATH/webview.apk
	cp "$MODPATH"$WPATH/webview.apk "$TMPDIR"/webview.zip
	mkdir -p "$TMPDIR"/webview "$MODPATH"$WPATH/lib/arm64 "$MODPATH"$WPATH/lib/arm
	unzip -d "$TMPDIR"/webview "$TMPDIR"/webview.zip >/dev/null
	cp -rf "$TMPDIR"/webview/lib/arm64-v8a/* "$MODPATH"$WPATH/lib/arm64
	cp -rf "$TMPDIR"/webview/lib/armeabi-v7a/* "$MODPATH"$WPATH/lib/arm
	rm -rf "$TMPDIR"/webview "$TMPDIR"/webview.zip
	create_overlay
}
extract_browser() {
	BPATH="/system/app/${NAME}Browser"
	ui_print "ⓘ Installing ${NAME} Browser"
	for i in "$J" "$F" "$C" "$E" "$D"; do
		if [[ -n "$i" ]]; then
			mktouch "$MODPATH""$i"/.replace
		fi
	done
	mktouch "$MODPATH""$BPATH"/.replace
	cp_ch "$EXT_DATA"/apks/"$NAME"Browser.apk "$MODPATH"$BPATH/browser.apk || cp_ch "$EXT_DATA"/apks/browser.apk "$MODPATH"$BPATH/browser.apk
	cp_ch "$MODPATH"$BPATH/browser.apk "$TMPDIR"/browser.zip
	mkdir -p "$TMPDIR"/browser "$MODPATH"$BPATH/lib/arm64 "$MODPATH"$BPATH/lib/arm
	unzip -d "$TMPDIR"/browser "$TMPDIR"/browser.zip >/dev/null
	cp -rf "$TMPDIR"/browser/lib/arm64-v8a/* "$MODPATH"$BPATH/lib/arm64
	cp -rf "$TMPDIR"/browser/lib/armeabi-v7a/* "$MODPATH"$BPATH/lib/arm
	rm -rf "$TMPDIR"/browser "$TMPDIR"/browser.zip
}
online_install() {
	ui_print "☑ Awesome, you have internet"
	set_path
	if [[ $INSTALL -eq 0 ]]; then
		download_webview
	elif [[ $INSTALL -eq 1 ]]; then
		download_browser
	elif [[ $INSTALL -eq 2 ]]; then
		download_webview
		download_browser
	fi
}
offline_install() {
	set_path
	for file in "$EXT_DATA"/apks/*browser.apk; do
		if [ -e "$file" ]; then
			ui_print "ⓘ Browser apk found! Using it"
			OFFLN_BRS=true
			extract_browser
			break
		else
			ui_print "⚠ No browser apk found!"
			break
		fi
	done
	for file in "$EXT_DATA"/apks/*webview.apk; do
		if [ -e "$file" ]; then
			ui_print "ⓘ Webview apk found! Using it"
			OFFLN_WV=true
			extract_webview
			break
		else
			ui_print "⚠ No webview apk found!"
			break
		fi
	done
	if [[ -z $OFFLN_BRS ]] && [[ -z $OFFLN_WV ]]; then
		ui_print "⚠ Required files for offline install not found!"
		it_failed
	fi
}
do_install() {
	set_config
	if ! "$BOOTMODE"; then
		ui_print "ⓘ Detected recovery install! Aborting!"
		it_failed 1
	elif [[ $FORCE_CONFIG -eq 1 ]]; then
		if [[ $OFFLINE -eq 1 ]]; then
			ui_print "⚠ Offline install selected! Proceeding..."
			offline_install
		fi
	else
		if ! $INTERNET; then
			ui_print "⚠ Uh-oh, we can't contact the API."
			ui_print "⚠ Make sure api.androidacy.com isn't blocked, that you have internet. and re-run the installer."
			ui_print "⚠ Falling back to offline mode for now."
			offline_install
		else
			if [[ ${TRY_COUNT} -gt 3 ]]; then
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
	if [[ -d "$MODPATH"/product ]]; then
		if [[ -d "$MODPATH"/system/product ]]; then
			cp -rf "$MODPATH"/product/* "$MODPATH"/system/product/
			rm -fr "$MODPATH"/product/
		else
			mv "$MODPATH"/product/ "$MODPATH"/system/
		fi
	fi
	if [[ -d "$MODPATH"/system_ext ]]; then
		if [[ -d "$MODPATH"/system/systen_ext ]]; then
			cp -rf "$MODPATH"/system_ext/ "$MODPATH"/system/
			rm -fr "$MODPATH"/system_ext/
		else
			mv "$MODPATH"/system_ext/ "$MODPATH"/system/
		fi
	fi
	rm -fr "$MODPATH"/config.txt
	clean_dalvik
}
if [[ ${TRY_COUNT} -ge "3" ]]; then
	it_failed
else
	do_install
fi
ui_print ' '
ui_print "ⓘ Some stock apps have been systemlessly  debloated during install"
sleep 0.15
ui_print "ⓘ Anything debloated is known to cause conflicts"
sleep 0.15
ui_print "ⓘ Such as Chrome, Google WebView, etc"
sleep 0.15
ui_print "ⓘ It is recommended not to reinstall them"
sleep 0.15
ui_print " "
sleep 0.15
ui_print "			Webview Manager | By Androidacy"
ui_print ' '
$INTERNET && curl -s -d "$P&i=1" "$U"/ping >/dev/null
ui_print "☑ Donate at https://www.androidacy.com/donate/"
sleep 0.15
ui_print "☑ Website, how to get support and blog is at https://www.androidacy.com"
sleep 0.15
ui_print "☑ Install apparently succeeded, please reboot ASAP"
sleep 0.15
ui_print " "
