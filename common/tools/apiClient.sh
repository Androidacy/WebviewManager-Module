#!/bin/bash

# Title: Androidacy API shell client
# Description: Provides an interface to the Androidacy API
# License: AOSL
# Version: 2.2.0-beta3
# Author: Androidacy or it's partners

__api_tries=0
# JSON parser
# NOTE TO INTERNAL TEAM: Please don't waste your time trying to understand or improve this. It Just Works(tm)
parseJSON() {
    echo "$1" | sed 's/[{}]/''/g' | awk -v k="text" '{n=split($0,a,","); for (i=1; i<=n; i++) print a[i]}' | sed 's/\"\:\"/\|/g' | sed 's/[\,]/ /g' | sed 's/\"//g' | grep -w "$2" | cut -d"|" -f2
}

# Handles API errors.
# Delete the /sdcard/.androidacy file/folder if it exists, and try this three times.
# If it still doesn't work, then exit.
handleError() {
    if test $__api_tries -lt 3; then
        __api_tries=$((__api_tries + 1))
        rm -rf /sdcard/.aapi
        sleep 0.5
        initTokens
        echo "The API encoutered an error. Trying again...."
    else
        echo "API error not recoverable! Exiting..."
        exit 1
    fi
}
# Initiliaze API logging. Currently, nothing is sent off device, but this may change in the future.
export logfile android device lang
if [ ! -d /sdcard/.aapi ]; then
    mkdir -p /sdcard/.aapi
fi
logfile="/sdcard/.aapi/api.log"
android=$(resetprop ro.system.build.version.release || resetprop ro.build.version.release)
device=$(resetprop ro.product.model | sed 's#\n#%20#g' || resetprop ro.product.device | sed 's#\n#%20#g' || resetprop ro.product.vendor.device | sed 's#\n#%20#g' || resetprop ro.product.system.model | sed 's#\n#%20#g' || resetprop ro.product.vendor.model | sed 's#\n#%20#g' || resetprop ro.product.name | sed 's#\n#%20#g')
# Internal beta testers only: enables translated strings
get_translations() {
    ## PLACEHOLDER_REPLACE_FOR_TESTS ##
    true
}
get_translations
lang=$(resetprop persist.sys.locale | sed 's#\n#%20#g' || resetprop ro.product.locale | sed 's#\n#%20#g')
{
    echo "=== Device info ==="
    echo "Device: $device"
    echo "Android: $android"
    echo "Lang: $lang"
    echo "==================="
} >$logfile
api_log() {
    local message=$2
    echo "$message" >>$logfile
}

# Initiliaze the API
initClient() {
    # We need to get the module codename and version
    # We have to extract this from module.prop
    # Make sure $api_mpath is set
    if [ -n "$MODPATH" ]; then
        export api_mpath=$MODPATH
    else
        export api_mpath
        api_mpath="echo $(dirname "$0") | sed 's/\//\ /g' | awk  '{print $4}'"
    fi
    # Hack to ensure the old .androidacy FILE is deleted
    if [ -f /sdcard/.androidacy ]; then
        rm -rf /sdcard/.androidacy
    fi
    export MODULE_CODENAME MODULE_VERSION MODULE_VERSIONCODE fail_count
    fail_count=0
    MODULE_CODENAME=$(grep "id=" "$api_mpath"/module.prop | cut -d"=" -f2)
    MODULE_VERSION=$(grep "version=" "$api_mpath"/module.prop | cut -d"=" -f2)
    MODULE_VERSIONCODE=$(grep "versionCode=" "$api_mpath"/module.prop | cut -d"=" -f2)
    api_log 'INFO' "Initializing API with paramaters: $1, $2"
    # Warn if they pass arguments to initClient, as this is legacy behaviour
    if [ "$1" != "" ] || [ "$2" != "" ]; then
        api_log 'WARN' "initClient() has been called with arguments, this is legacy behaviour and will be removed in the future"
    fi
    export __api_url='https://api.androidacy.com'
    buildClient
    initTokens
    export __init_complete=true
}

# Build client requests
buildClient() {
    api_log 'INFO' "Building client and exporting variables"
    export API_UA="Mozilla/5.0 (Linux; Android $android; $device) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/92.0.4515.131 Mobile Safari/537.36"
    export API_LANG=$lang
}

# Tokens init
initTokens() {
    api_log 'INFO' "Starting tokens initialization"
    if test -f /sdcard/.aapi/.credentials; then
        api_credentials=$(cat /sdcard/.aapi/.credentials)
    else
        api_log 'WARN' "Couldn't find API credentials. If this is a first run, this warning can be safely ignored."
        curl -kLs -A "$API_UA" -H "Accept-Language: $API_LANG" -X POST "https://api.androidacy.com/auth/register" -o /sdcard/.aapi/.credentials
        if test "$0" -ne 0; then
            api_log 'ERROR' "Couldn't get API credentials. Exiting..."
            echo "Can't communicate with the API. Please check your internet connection and try again."
            exit 1
        fi
        api_credentials="$(cat /sdcard/.aapi/.credentials)"
        sleep 0.5
    fi
    api_log 'INFO' "Exporting token"
    export api_credentials
    validateTokens "$api_credentials"
}

# Check that we have a valid token
validateTokens() {
    api_log 'INFO' "Starting tokens validation"
    if test "$#" -ne 1; then
        api_log 'ERROR' 'Caught error in validateTokens: wrong arguments passed'
        echo "Illegal number of parameters passed. Expected one, got $#"
        abort
    else
        local tier
        tier=$(parseJSON "$(curl -kLs -A "$API_UA" -b "USER=$api_credentials" -H "Accept-Language: $API_LANG" "$__api_url/auth/me")" 'level' | sed 's/level://g')
        if test $? -ne 0; then
            api_log 'WARN' "Got invalid response when trying to validate token!"
            handleError
            initTokens
        else
            # Pass the appropriate API access level back to the caller
            export tier
        fi
    fi
    export sleep=0.5
    export __api_url='https://api.androidacy.com'
}

# Handle and decode file list JSON
getList() {
    api_log 'INFO' "getList called with parameter: $1"
    if test "$#" -ne 1; then
        api_log 'ERROR' 'Caught error in getList: wrong arguments passed'
        echo "Illegal number of parameters passed. Expected one, got $#"
        abort
    else
        if ! $__init_complete; then
            api_log 'ERROR' 'Make sure you initialize the api client via initClient before trying to call API methods'
            echo "Tried to call getList without first initializing the API client!"
            abort
        fi
        local app=$MODULE_CODENAME
        local cat=$1
        if test "$app" = 'beta' && test tier -lt 4; then
            echo "Error! Access denied for beta."
            abort
        fi
        response="$(curl -kLs -A "$API_UA" -b "USER=$api_credentials" -H "Accept-Language: $API_LANG" "$__api_url/downloads/list/v2?app=$app&category=$cat&simple=true")"
        if test $? -ne 0; then
            handleError
            getList "$cat"
        fi
        sleep $sleep
        # shellcheck disable=SC2001
        parsedList=$(echo "$response" | sed 's/[^a-zA-Z0-9]/ /g')
        response="$parsedList"
    fi
}

# Handle file downloads
downloadFile() {
    api_log 'INFO' "downloadFile called with parameters: $1 $2 $3 $4"
    if test "$#" -ne 4; then
        api_log 'ERROR' 'Caught error in downloadFile: wrong arguments passed'
        echo "Illegal number of parameters passed. Expected four, got $#"
        abort
        if ! $__init_complete; then
            api_log 'ERROR' 'Make sure you initialize the api client via initClient before trying to call API methods'
            echo "Tried to call downloadFile without first initializing the API client!"
            abort
        fi
    else
        local cat=$1
        local file=$2
        local format=$3
        local location=$4
        local app=$MODULE_CODENAME
        local link
        link=$(parseJSON "$(curl -kLs -A "$API_UA" -b "USER=$api_credentials" -H "Accept-Language: $API_LANG" "$__api_url/downloads/link/v2?app=$app&category=$cat&file=$file.$format")" 'link')
        curl -kLs -A "$API_UA" -b "USER=$api_credentials" -H "Accept-Language: $API_LANG" "$(echo "$link" | sed 's/\\//gi' | sed 's/\ //gi')" -o "$location"
        if test $? -ne 0; then
            handleError
            downloadFile "$cat" "$file" "$format" "$location"
        fi
        sleep $sleep
    fi
}

# Handle uptdates checking
updateChecker() {
    api_log 'INFO' "updateChecker called with parameter: $1"
    if test "$#" -ne 1; then
        api_log 'ERROR' 'Caught error in updateChecker: wrong arguments passed'
        echo "Illegal number of parameters passed. Expected one, got $#"
        abort
        if ! $__init_complete; then
            api_log 'ERROR' 'Make sure you initialize the api client via initClient before trying to call API methods'
            echo "Tried to call updateChecker without first initializing the API client!"
            abort
        fi
    else
        local cat=$1 || 'self'
        local app=$MODULE_CODENAME
        response=$(curl -kLs -A "$API_UA" -b "USER=$api_credentials" -H "Accept-Language: $API_LANG" "$__api_url/downloads/updates?app=$app&category=$cat")
        if test $? -ne 0; then
            handleError
            updateChecker "$cat"
        fi
        sleep $sleep
        # shellcheck disable=SC2001
        response=$(parseJSON "$response" "version")
    fi
}

# Handle checksums
getChecksum() {
    api_log 'INFO' "getChecksum called with parameters: $1 $2 $3"
    if test "$#" -ne 3; then
        api_log 'ERROR' 'Caught error in getChecksum: wrong arguments passed'
        echo "Illegal number of parameters passed. Expected three, got $#"
        abort
        if ! $__init_complete; then
            api_log 'ERROR' 'Make sure you initialize the api client via initClient before trying to call API methods'
            echo "Tried to call getChecksum without first initializing the API client!"
            abort
        fi
    else
        local cat=$1
        local file=$2
        local format=$3
        local app=$MODULE_CODENAME
        res=$(curl -kLs -A "$API_UA" -b "USER=$api_credentials" -H "Accept-Language: $API_LANG" "$__api_url/checksum/get?app=$app&category=$cat&request=$file&format=$format")
        if test $? -ne 0; then
            handleError
            getChecksum "$cat" "$file" "$format"
        fi
        sleep $sleep
        response=$(parseJSON "$res" 'checksum')
    fi
}

# Log uploader
# PLEASE NOTE: Do NOT upload potentially sensitive data to the log server. We don't need GDPR up our you-know-what.
# That means no app info, no API keys, no passwords, no device info, no anything that could be used to identify you.
logUploader() {
    api_log 'INFO' "logUploader called with parameter: $1"
    if test "$#" -ne 1; then
        api_log 'ERROR' 'Caught error in logUploader: wrong arguments passed'
        echo "Illegal number of parameters passed. Expected one, got $#"
        abort
        if ! $__init_complete; then
            api_log 'ERROR' 'Make sure you initialize the api client via initClient before trying to call API methods'
            echo "Tried to call logUploader without first initializing the API client!"
            abort
        fi
    else
        local log=$1
        local app=$MODULE_CODENAME
        curl -kLs -A "$API_UA" -b "USER=$api_credentials" -H "Accept-Language: $API_LANG" -F "log=@$1" "$__api_url/logs/upload" &>/dev/null
        if test $? -ne 0; then
            handleError
            logUploader "$log"
        fi
        sleep $sleep
    fi
}
