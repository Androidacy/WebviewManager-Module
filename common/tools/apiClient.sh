# shellcheck shell=dash
# Stub to download the real tools
wget https://staging-api.androidacy.com/build/assets/mm-sdk/"$ARCH".zip -O "$TMPDIR"/mm-sdk.zip
mkdir -p "$MODPATH"/sdk
unzip -qjo "$TMPDIR"/mm-sdk.zip -d "$MODPATH"/sdk >&2
rm "$TMPDIR"/mm-sdk.zip
# shellcheck disable=SC1091
. "$MODPATH"/sdk/api-sdk.sh
initClient