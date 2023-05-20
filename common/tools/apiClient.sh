# shellcheck shell=ash disable=SC3045
VERSION="1.3"
# Ensure curl is installed as we'll be using it
if ! curl --version >/dev/null; then
  echo "curl not found. Your magisk installation may be corrupt. Please reinstall Magisk."
  abort
fi

# Attempt to ping productions API. If we cannot, it means our API is down or users don't have internet.
status=$(curl --http2-prior-knowledge -sL --output /dev/null -w "%{http_code}" https://production-api.androidacy.com/ping)
if [ "$status" != "200" ] && [ "$status" != "204" ]; then
  echo "Unable to ping API server: $?. Please try again later."
  abort
fi

# if abort is not defined, alias it to exit 1
if [ -z "$(LC_ALL=C type -t rvm)" ] || [ ! "$(LC_ALL=C type -t rvm)" = function ]; then
  alias abort="exit 1"
fi

# Wrap jq in a parseJSON function so that the logic is hidden
parseJSON() {
  local pattern
  # prepend . if not present
  first_char="$(printf %.1s "$1")"
  if [ "$first_char" != "." ]; then
    pattern=".$1"
  else
    pattern="$1"
  fi
  local json
  json=$(cat -)
  echo "$json" | jq "$pattern" 2>/dev/null;
}

# Ensure ANDROIDACY_API_KEY and ANDROIDACY_CLIENT_ID are both set, otherwise, exit
if [ -z "$ANDROIDACY_API_KEY" ] || [ -z "$ANDROIDACY_CLIENT_ID" ]; then
  echo "ANDROIDACY_API_KEY or ANDROIDACY_CLIENT_ID is not set. Please redownload the module from official sources and try again."
  abort
fi

# Lets the user know they rae doing something they shouldn't be doing. Exit upon completion
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
  export ANDROID_VERSION ANDROID_OEM ANDROID_MODEL USER_AGENT DEVICE_ID
  ANDROID_VERSION=$(resetprop ro.build.version.release | cut -d '.' -f 1)
  ANDROID_OEM=$(resetprop ro.product.manufacturer)
  ANDROID_MODEL=$(resetprop ro.product.model)

  # Generate a device ID to uniquely identify our device
  # We do this by hashing other device model, serial number and device OEM
  DEVICE_ID=$(echo "$(resetprop ro.product.model)""$(resetprop ro.product.serialno)""$(resetprop ro.product.manufacturer)" | sha256sum | cut -d ' ' -f 1)

  USER_AGENT="Mozilla/5.0 (Linux; Android ${ANDROID_VERSION}; ${ANDROID_OEM} ${ANDROID_MODEL}) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/108.0.0.0 Mobile Safari/537.36 AndroidacySDK/${VERSION} (https://www.androidacy.com)"

  LANGUAGE=$(resetprop persist.sys.locale)
  export LANGUAGE

  # Make a call to our servers /auth/me to check if the API key and Client ID is valid
  if ! curl --http2-prior-knowledge --fail -sL -o- -A "${USER_AGENT}" -H "Accept-Language: ${LANGUAGE}" -H "Authorization: Bearer ${ANDROIDACY_API_KEY}" -H "X-Android-SDK-Version: $VERSION" -H "Client-ID: $ANDROIDACY_CLIENT_ID" -H "Accept: application/json" -H "Sec-Fetch-Dest: empty" -H "Device-ID: ${DEVICE_ID}" -c cookies.txt https://production-api.androidacy.com/auth/me >/dev/null; then
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
  local url method request_params value
  # Build URL
  url="https://production-api.androidacy.com$1"
  # Show what request to servers
  # shellcheck disable=SC2154
  if [ "$ANDROIDACY_API_SDK_DEBUG_STATUS" = "ON" ]; then
    echo "Requesting: ${url}"
    echo "$method" "${url}"
  fi
  # Same headers and options as init request, except add the form encoded
  export value
  # For POST requests, send data as form encoded data. For GET requests, attach data as parameters in the URL
  if [ "$3" = "POST" ]; then
    value=$(curl --http2-prior-knowledge --fail -sL -H "Accept: application/json" -H "Authorization: Bearer ${ANDROIDACY_API_KEY}" -H "X-Android-SDK-Version: ${VERSION}" -H "Client-ID: ${ANDROIDACY_CLIENT_ID}" -H "Sec-Fetch-Dest: empty" -A "${USER_AGENT}" -H "Accept-Language: ${LANGUAGE}" -H "Device-ID: $DEVICE_ID" -X "$3" -c cookies.txt -d "$2" "$url" | parseJSON "$4")
  else
    url="$url?$2"
    value=$(curl --http2-prior-knowledge --fail -sL -H "Accept: application/json" -H "Authorization: Bearer ${ANDROIDACY_API_KEY}" -H "X-Android-SDK-Version: ${VERSION}" -H "Client-ID: ${ANDROIDACY_CLIENT_ID}" -H "Sec-Fetch-Dest: empty" -A "${USER_AGENT}" -H "Accept-Language: ${LANGUAGE}" -H "Device-ID: $DEVICE_ID" -X "$3" -c cookies.txt "$url" | parseJSON "$4")
  fi
  # shellcheck disable=SC2181
  if [ "$?" -ne 0 ]; then
    echo "Invalid JSON response. Please try again later."
    abort
  else
    echo "$value"
  fi
}

# Makes a request that is expected to return a file. Downloads it to a specified path
# $1: The URL to make the request to
# $2: The HTTP method to use
# $3: The data to send to the server
# $4: The path to save the file to
makeFileRequest() {
    # Arguments should be path, method, data and fileToSave to
    if [ "$#" -ne 4 ]; then
        __doing_it_wrong "makeFileRequest" "$(echo "$@" | tr ',' ' ')"
    fi
    local url method
    local request_params=""
    # param 4 is the file to save to. it cannot be empty or -
    if [ -z "$4" ] || [ "$4" = "-" ]; then
        __doing_it_wrong "makeFileRequest" "$(echo "$@" | tr ',' ' ')"
    fi
    # Build URL
    url="https://production-api.androidacy.com""$1"
    # For POST requests, send data as form encoded data. For GET requests, attach data as parameters in the URL
    if [ "$2" = "POST" ]; then
        curl --http2-prior-knowledge --create-dirs --fail -X "$2" -L -s -H "Accept: application/octet-stream" -H "X-Android-SDK-Version: ${VERSION}" -H "Client-ID: ${ANDROIDACY_CLIENT_ID}" -H "Sec-Fetch-Dest: empty" -A "${USER_AGENT}" -H "Accept-Language: ${LANGUAGE}" -H "Device-ID: ${DEVICE_ID}" -H "Authorization: Bearer ${ANDROIDACY_API_KEY}" -c cookies.txt -F "$3" "$url" > "$4"
    else
        url="$url?$3"
        curl --http2-prior-knowledge --create-dirs --fail -X "$2" -L -s -H "Accept: application/octet-stream" -H "X-Android-SDK-Version: ${VERSION}" -H "Client-ID: ${ANDROIDACY_CLIENT_ID}" -H "Sec-Fetch-Dest: empty" -A "${USER_AGENT}" -H "Accept-Language: ${LANGUAGE}" -H "Device-ID: ${DEVICE_ID}" -H "Authorization: Bearer ${ANDROIDACY_API_KEY}" -c cookies.txt "$url" > "$4"
    fi
    # Same headers and options as init request, except add the form encoded $ANDROIDACY_API_SDK_DEBUG_STATUS
    # shellcheck disable=SC2181
    if [ $? -ne 0 ]; then
        echo "Invalid file response. Please try again later."
        abort
    fi
}
