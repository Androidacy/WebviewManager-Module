# shellcheck shell=dash

#######################################
## WebView Manager Global Settings   ##
## You probably don't want to edit it #
## directly!                         ##
##                                   ##
## Instead, use the easy install mode #
## with volume keys (optional)        #
#######################################

# Do not touch this unless instructed by support
export ANDROIDACY_API_SDK_DEBUG_STATUS="OFF"

# false for any of these variables will disable the feature
# Choose your webview. Options are bromite, chromium, mulch, or attempt to use browser
export WEBVIEW_CONFIG="false"
# Choose your browser. Options are chromium, brave, bromite, kiwi
export BROWSER_CONFIG="false"
# Master switch to use this file. Unless this is set to true, all values set above will not be used
# Export this automatically when running this script
export USE_CUSTOM_CONFIG=false