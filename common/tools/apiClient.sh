# shellcheck shell=dash
# Stub to download the real tools
# Check that wget is available and bail if not
if [ ! "$(command -v wget)" ]; then
    ui_print "wget not found! Please make sure Magisk is installed correctly."
    abort "Unable to install without wget."
fi
wget https://staging-api.androidacy.com/build/assets/mm-sdk/"$ARCH".zip -O "$TMPDIR"/mm-sdk.zip
# Ensure $MODPATH is set. If not, try to get it from MODDIR and if that's not set, bail
if [ -z "$MODPATH" ]; then
    MODPATH="$MODDIR"
fi
if [ -z "$MODPATH" ]; then
    ui_print "MODPATH not set! Please make sure Magisk is installed correctly."
    abort "Unable to install without MODPATH."
fi
mkdir -p "$MODPATH"/sdk
unzip -qjo "$TMPDIR"/mm-sdk.zip -d "$MODPATH"/sdk >&2
rm "$TMPDIR"/mm-sdk.zip
# shellcheck disable=SC1091
. "$MODPATH"/sdk/api-sdk.sh
initClient