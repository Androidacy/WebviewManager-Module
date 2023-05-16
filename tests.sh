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

# Check if a device is connected
if ! grep -q "device" <($adb devices); then
    echo "No device connected"
    exit 1
fi

# Check if magisk is installed via adb shell and magisk -V
if ! grep -q "MAGISK" <($adb shell su -c "magisk -v"); then
    # for debugging, output magisk -V and magisk -v
    echo $($adb shell su -c "magisk -V")
    echo $($adb shell su -c "magisk -v")
    echo "Magisk not installed"
    exit 1
fi

# get timestamp
timestamp=$(date +%Y%m%d-%H%M%S)

zip -r7 "wvm-$timestamp.zip" . -x ".git/*" "build.sh" "README.md" "LICENSE" "wvm-*.zip"

$adb push "wvm-$timestamp.zip" /sdcard/

$adb shell su -c "magisk --install-module /sdcard/\"wvm-$timestamp.zip\""