# shellcheck shell=ash
VERSION="1.1"

# Ensure wget is installed as we'll be using it
if ! which wget >/dev/null 2>&1; then
    echo "wget not found. Your magisk installation may be corrupt. Please uninstall and reinstall Magisk."
    exit 1
fi

# Attempt to ping productions API. If we cannot, it means our API is down or users don't have internet.
if ! wget -q --spider https://production-api.androidacy.com/ping; then
    echo "Unable to ping API server. Please try again later."
    exit 1
fi

# Next, download jq from production.
# jq is a tool for parsing JSON for a bash script.
wget --content-disposition https://production-api.androidacy.com/build/assets/mm-sdk/"${ARCH}".zip
# Unzip the file
unzip "${ARCH}".zip
# Clean up
rm jq.zip
# Alias the binary
# shellcheck disable=SC2139
alias jq=./jq-"${ARCH}"

# Wrap jq in a parseJSON function so that the logic is hidden
parseJSON() { jq "$1" 2>/dev/null; }

# Ensure ANDROIDACY_API_KEY and ANDROIDACY_CLIENT_ID are both set, otherwise, exit
if [ -z "$ANDROIDACY_API_KEY" ] || [ -z "$ANDROIDACY_CLIENT_ID" ]; then
    echo "ANDROIDACY_API_KEY or ANDROIDACY_CLIENT_ID is not set. Please redownload the module from official sources and try again."
    abort
fi

# Let's the user know they rae doing something they shoudn't be doing. Exit upon completion
__doing_it_wrong() {
    if [ -e "$1" ] && [ -e "$2" ]; then
        echo "☢️ Whoa there! In function $1, you passed $2 which isn't supported anymore. Please check if it can be removed or if you can substitute it with something else. Also, read the documentation for more information. ☢️"
    fi
    abort
}

# Initialization function.
# Sets the user agent based on the device and the module and version, and makes a call to our servers to verify the api key and client id is correct
initAPISDK() {
    # If any parameter is passed, show error message
    if [ "$#" -ge 1 ]; then
        __doing_it_wrong "initAPISDK" "$(echo "$@" | tr ',' ' ')"
    fi
    export ANDROID_VERSION, ANDROID_OEM, ANDROID_MODEL, USER_AGENT, DEVICE_ID
    ANDROID_VERSION=$(getprop ro.build.version.release | cut -d '.' -f 1)
    ANDROID_OEM=$(getprop ro.product.manufacturer)
    ANDROID_MODEL=$(getprop ro.product.model)

    # Generate a device ID to uniquely identify our device
    # We do this by hashing othe device model, serial number and device OEM
    DEVICE_ID=$(echo "$(getprop ro.product.model)""$(getprop ro.product.serial)""$(getprop ro.product.manufacturer)" | sha256sum | cut -d ' ' -f 1)

    USER_AGENT="Mozilla/5.0 (Linux; Android ${ANDROID_VERSION}; ${ANDROID_OEM} ${ANDROID_MODEL}) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/108.0.0.0 Mobile Safari/537.36 AndroidacySDK/${VERSION} (https://www.androidacy.com)"

    # Make a call to our servers /auth/me to check if the API key and Client ID is valid
    if ! wget -qO- --content-disposition --user-agent="${USER_AGENT}" --header="Authorization: Bearer ${ANDROIDACY_API_KEY}" --header="X-Android-SDK-Version: $VERSION" --header="X-Client-ID: $ANDROIDACY_CLIENT_ID" --header="Accept: application/json" --header="Sec-Fetch-Dest: empty" --header "Cookie: device_id=${DEVICE_ID}" --keep-session-cookies --save-cookies=cookies.txt https://production-api.androidacy.com/auth/me >/dev/null 2>&1; then
        echo "API Key or Client ID is invalid or exceeded usage limits. Please redownload the module from official sources and try again."
        abort
    fi
}

# Makes a request that is expected to return JSON and then tries to parse it and return in a format that can be used in other shell scripts
# $1: The URL to make the request to
# $2: The data to send to the server
# $3: The HTTP method to use
# $4: The JSON key to parse
makeJSONRequest() {
    # Arguments should be path with variables, data to send, method and key to get value of
    if [ "$#" -ne 4 ]; then
        __doing_it_wrong "makeJSONRequest" "$(echo "$@" | tr ',' ' ')"
    fi
    local url, method, request_params, value
    # Build URL
    url="https://production-api.androidacy.com""$1"
    # Show what request to servers
    # shellcheck disable=SC2154
    if [ "$ANDROIDACY_API_SDK_DEBUG_STATUS" = "ON" ]; then
        echo "Requesting: ${url}"
        echo "$method" "${url}"
    fi
    # For POST requests, send data as form encoded data. For GET requests, attach data as parameters in the URL
    if [ "$3" = "POST" ]; then
        request_params="--post-data $2"
    else
        request_params=""
        url="$url""?""$2"
    fi
    # Same headers and options as init request, except add the form encoded data
    export value
    value=$(wget -qO- --read-timeout=8 --content-disposition --header="Accept: application/json" --header="Content-Type: multipart/form-data" --header="Authorization: Bearer ""${ANDROIDACY_API_KEY}" --header="X-Android-SDK-Version: ${VERSION}" --header="X-Client-ID: ${ANDROIDACY_CLIENT_ID}" --header="Sec-Fetch-Dest: empty" --user-agent="${USER_AGENT}" --header="Cookie: device_id=$DEVICE_ID" --keep-session-cookies --save-cookies=cookies.txt "$request_params" "$url" | parseJSON "$4")
    # shellcheck disable=SC2181
    if [ "$?" -ne 0 ]; then
        echo "Invalid JSON response. Please try again later."
        abort
    fi
}

# Makes a request that is expected to return a file. Downloads it to a specified path
# $1: The URL to make the request to
# $2: The HTTP method to use
# $3: The data to send to the server
# $4: The path to save the file to
makeFileRequest() {
    # Arguments should be path, method, data and fileToSave to
    if [ "$#" -ne 3 ]; then
        __doing_it_wrong "makeFileRequest" "$(echo "$@" | tr ',' ' ')"
    fi
    local url method
    local request_params=""
    local headers=""
    # Build URL
    url="https://production-api.androidacy.com""$1"
    # For POST requests, send data as form encoded data. For GET requests, attach data as parameters in the URL
    if [ "$2" = "POST" ]; then
        request_params="--post-data $3"
    else
        request_params=""
        url="$url""?""$3"
    fi
    # Same headers and options as init request, except add the form encoded data
    wget -X "$2" --quiet --continue --content-disposition --header="Accept: application/octet-stream" --header="X-Android-SDK-Version: ""${VERSION}" --header="X-Client-ID: ""${ANDROIDACY_CLIENT_ID}" --header "Sec-Fetch-Dest: empty" --user-agent="${USER_AGENT}" --header="Cookie: device_id=""${DEVICE_ID}" --keep-session-cookies --save-cookies=cookies.txt "$headers" "$request_params" "$url" -O "$4"
    # shellcheck disable=SC2181
    if [ "$?" -ne 0 ]; then
        echo "Invalid file response. Please try again later."
        abort
    fi
}