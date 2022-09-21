# shellcheck shell=ash
# Stub to download the real tools
# Check that wget is available and bail if not
if [ ! "$(command -v wget)" ]; then
    ui_print "wget not found! Please make sure Magisk is installed correctly."
    abort "Unable to install without wget."
fi
if ! wget https://production-api.androidacy.com/build/assets/mm-sdk/"$ARCH".zip -O "$TMPDIR"/mm-sdk.zip; then
    ui_print "Failed to download the needed SDK modules. Please ensure nothing is blocking *.androidacy.com and you're connected to the internet."
    abort "Unable to install."
fi
# Verify the checksum against known good. Digest is downloaded from the server too. No remote execution risk, or at least this mitigates it unless we're being MITMed.
# But in that case, you've got much larger issues to worry about than a script.
if ! wget https://production-api.androidacy.com/build/assets/mm-sdk/"$ARCH".zip.digest -O "$TMPDIR"/mm-sdk.digest; then
    abort "Unable to continue without a digest file."
fi
existing_digest=$(sha256sum "$TMPDIR"/mm-sdk.zip | cut -d ' ' -f1)
if [ "$existing_digest" != "$(head -n 1 "$TMPDIR"/mm-sdk.digest)" ]; then
    ui_print "Downloaded file checksum verification failed. This is very unexpected."
    abort "The downloaded file $existing_digest did not match $(head -n 1 "$TMPDIR"/mm-sdk.digest)"
fi
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