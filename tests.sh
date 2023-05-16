#!/usr/bin/env bash

# Zips the current directory (excluding .git), checks if a device is connected, and copies the zip to the device. Then we use adb shell to run the magisk --install command on the device.
zip=$(which zip)
adb=$(which adb)

if [ -z "$zip" ]; then
    echo "zip not found"
    exit 1
fi
if [ -z "$adb" ]; then
    echo "adb not found"
    exit 1
fi

# Check if a device is connected. one device should be connected.
if ! grep -q "device" <($adb devices); then
    echo "No device connected. Please make sure test infrastructure is set up correctly. See androidacy/infra#test-device-setup"
    exit 1
fi
echo "Checks passed"
# Check if magisk is installed via adb shell and magisk -V
if ! grep -q "MAGISK" <($adb shell su -c "magisk -v"); then
    # for debugging, output magisk -V and magisk -v
    echo $($adb shell su -c "magisk -V")
    echo $($adb shell su -c "magisk -v")
    echo "Magisk not installed"
    exit 1
fi
echo "Magisk installed"
# get timestamp
timestamp=$(date +%Y%m%d-%H%M%S)
echo "Timestamp: $timestamp"
rm -f wvm-*.zip
echo "Removed old zip(s)"
zip -qr8 "wvm-$timestamp.zip" . -x ".git/*" "build.sh" "README.md" "LICENSE"
echo "Created zip"
$adb push "wvm-$timestamp.zip" /sdcard/
echo "Pushed zip to /sdcard/"
$adb shell su -c "magisk --install-module /sdcard/\"wvm-$timestamp.zip\""