#!/bin/bash

# Title: Androidacy API shell client
# Description: Provides an interface to the Androidacy API
# License: AOSL
# Version: 2.0.1
# Author: Androidacy or it's partners

# JSON parser
parseJSON() {
    echo "$1" | sed 's/[{}]/''/g' | awk -v k="text" '{n=split($0,a,","); for (i=1; i<=n; i++) print a[i]}' | sed 's/\"\:\"/\|/g' | sed 's/[\,]/ /g' | sed 's/\"//g' | grep -w "$2" | cut -d"|" -f2
}

# Initiliaze the API
initClient() {
    log 'INFO' "Initializing API with paramaters: $1, $2"
    if test "$#" -ne 2; then
        echo "Illegal number of parameters passed. Expected two, got $#"
        abort
    else
        export API_URL='https://api2.androidacy.com'
        if test "$1" = 'fm'; then
            export API_FN="FontManager"
        elif test "$1" = 'wvm'; then
            export API_FN="WebviewManager"
        fi
        export API_V=$2
        export API_APP=$1
        buildClient
        initTokens
        export __API_INIT_DONE=true
    fi
}

# Build client requests
buildClient() {
    log 'INFO' "Building client and exporting variables"
    android=$(resetprop ro.system.build.version.release || resetprop ro.build.version.release)
    device=$(resetprop ro.product.model | sed 's#\n#%20#g' || resetprop ro.product.device | sed 's#\n#%20#g' || resetprop ro.product.vendor.device | sed 's#\n#%20#g' || resetprop ro.product.system.model | sed 's#\n#%20#g' || resetprop ro.product.vendor.model | sed 's#\n#%20#g' || resetprop ro.product.name | sed 's#\n#%20#g')
    lang=$(resetprop persist.sys.locale | sed 's#\n#%20#g' || resetprop ro.product.locale | sed 's#\n#%20#g')
    export API_UA="Mozilla/5.0 (Linux; Android $android; $device) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/92.0.4515.131 Mobile Safari/537.36"
    export API_LANG=$lang
}

# Tokens init
initTokens() {
    log 'INFO' "Starting tokens initialization"
    if test -f /sdcard/androidacy.json; then
        API_TOKEN=$(parseJSON "$(cat /sdcard/androidacy.json)" 'token')
    else
        log 'WARN' "Couldn't find API credentials. If this is a first run, this warning can be safely ignored."
        wget --no-check-certificate -qU "$API_UA" --header "Accept-Language: $API_LANG" "https://www.androidacy.com/credentials/get" -O /sdcard/androidacy.json
        API_TOKEN=$(parseJSON "$(cat /sdcard/androidacy.json)" 'token')
        sleep 1
    fi
    log 'INFO' "Exporting token"
    export API_TOKEN
    validateTokens "$API_TOKEN"
}

# Check that we have a valid token
validateTokens() {
    log 'INFO' "Starting tokens validation"
    if test "$#" -ne 1; then
        log 'ERROR' 'Caught error in validateTokens: wrong arguments passed'
        echo "Illegal number of parameters passed. Expected one, got $#"
        abort
    else
        API_LVL=$(wget --no-check-certificate -qU "$API_UA" --header "X-Androidacy-Token: $API_TOKEN" --header "Accept-Language: $API_LANG" "$API_URL/tokens/validate" -O -)
        if test $? -ne 0; then
            log 'WARN' "Got invalid response when trying to validate token!"
            # Restart process on validation failure
            rm -f '/sdcard/androidacy.json'
            sleep 1
            initTokens
        else
            # Pass the appropriate API access level back to the caller
            export API_LVL
        fi
    fi
    if test "$API_LVL" -lt 2; then
        echo '- Looks like your using a free or guest token'
        echo '- For info on faster downloads and supporting development, see https://www.androidacy.com/donate/'
        export sleep=1
        export API_URL='https://api.androidacy.com'
    else
        export sleep=1
        export API_URL='https://api2.androidacy.com'
    fi
}

# Handle and decode file list JSON
getList() {
    log 'INFO' "getList called with parameter: $1"
    if test "$#" -ne 1; then
        log 'ERROR' 'Caught error in getList: wrong arguments passed'
        echo "Illegal number of parameters passed. Expected one, got $#"
        abort
    else
        if ! $__API_INIT_DONE; then
            log 'ERROR' 'Make sure you initialize the api client via initClient before trying to call API methods'
            echo "Tried to call getList without first initializing the API client!"
            abort
        fi
        local app=$API_APP
        local cat=$1
        if test "$app" = 'beta' && test API_LVL -lt 4; then
            echo "Error! Access denied for beta."
            abort
        fi
        response=$(wget --no-check-certificate -qU "$API_UA" --header "X-Androidacy-Token: $API_TOKEN" --header "Accept-Language: $API_LANG" "$API_URL/downloads/list?app=$app&category=$cat" -O -)
        if test $? -ne 0; then
            log 'ERROR' "Couldn't contact API. Is it offline or blocked?"
            echo "API request failed! Assuming API is down and aborting!"
            abort
        fi
        sleep $sleep
        # shellcheck disable=SC2001
        parsedList=$(echo "$response" | sed 's/[^a-zA-Z0-9]/ /g')
        response="$parsedList"
    fi
}

# Handle file downloads
downloadFile() {
    log 'INFO' "downloadFile called with parameters: $1 $2 $3 $4"
    if test "$#" -ne 4; then
        log 'ERROR' 'Caught error in downloadFile: wrong arguments passed'
        echo "Illegal number of parameters passed. Expected four, got $#"
        abort
        if ! $__API_INIT_DONE; then
            log 'ERROR' 'Make sure you initialize the api client via initClient before trying to call API methods'
            echo "Tried to call downloadFile without first initializing the API client!"
            abort
        fi
    else
        local cat=$1
        local file=$2
        local format=$3
        local location=$4
        local app=$API_APP
        if test "$API_LVL" -lt 2; then
            local endpoint='downloads/free'
        else
            local endpoint='downloads/paid'
        fi
        wget --no-check-certificate -qU "$API_UA" --header "X-Androidacy-Token: $API_TOKEN" --header "Accept-Language: $API_LANG" "$API_URL/$endpoint?app=$app&category=$cat&request=$file&format=$format" -O "$location"
        if test $? -ne 0; then
            log 'ERROR' "Couldn't contact API. Is it offline or blocked?"
            echo "API request failed! Assuming API is down and aborting!"
            abort
        fi
      sleep $sleep
    fi
}

# Handle uptdates checking
updateChecker() {
    log 'INFO' "updateChecker called with parameter: $1"
    if test "$#" -ne 1; then
        log 'ERROR' 'Caught error in updateChecker: wrong arguments passed'
        echo "Illegal number of parameters passed. Expected one, got $#"
        abort
        if ! $__API_INIT_DONE; then
            log 'ERROR' 'Make sure you initialize the api client via initClient before trying to call API methods'
            echo "Tried to call updateChecker without first initializing the API client!"
            abort
        fi
    else
        local cat=$1
        local app=$API_APP
        response=$(wget --no-check-certificate -qU "$API_UA" --header "X-Androidacy-Token: $API_TOKEN" --header "Accept-Language: $API_LANG" "$API_URL/downloads/updates?app=$app&category=$cat" -O -)
        sleep $sleep
        # shellcheck disable=SC2001
        response=$(parseJSON "$response" "version")
    fi
}

# Handle checksums
getChecksum() {
    log 'INFO' "getChecksum called with parameters: $1 $2 $3"
    if test "$#" -ne 3; then
        log 'ERROR' 'Caught error in getChecksum: wrong arguments passed'
        echo "Illegal number of parameters passed. Expected three, got $#"
        abort
        if ! $__API_INIT_DONE; then
            log 'ERROR' 'Make sure you initialize the api client via initClient before trying to call API methods'
            echo "Tried to call getChecksum without first initializing the API client!"
            abort
        fi
    else
        local cat=$1
        local file=$2
        local format=$3
        local app=$API_APP
        res=$(wget --no-check-certificate -qU "$API_UA" --header "X-Androidacy-Token: $API_TOKEN" --header "Accept-Language: $API_LANG" "$API_URL/checksum/get?app=$app&category=$cat&request=$file&format=$format" -O -)
        if test $? -ne 0; then
            log 'ERROR' "Couldn't contact API. Is it offline or blocked?"
            echo "API request failed! Assuming API is down and aborting!"
            abort
        fi
        sleep $sleep
        response=$(parseJSON "$res" 'checksum')
    fi
}
