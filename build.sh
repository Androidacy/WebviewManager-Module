# shellcheck shell=dash
# Build Script for Androidacy Modules.
MODULE_NAME=$(grep "name=" "${PWD}"/module.prop | cut -d "=" -f 2 | sed -e 's/\ /_/')
MODULE_VERSION=$(grep "version=" "${PWD}"/module.prop | cut -d "=" -f 2)
MODULE_VERSIONCODE=$(grep "versionCode=" "${PWD}"/module.prop | cut -d "=" -f 2)
zip -r7 "$MODULE_NAME-$MODULE_VERSION-$MODULE_VERSIONCODE.zip" . -x '.git*'