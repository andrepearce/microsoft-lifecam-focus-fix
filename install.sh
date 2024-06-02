#!/bin/bash -e
#
# Installs the Microsoft Lifecam Auto focus fix.
#
# Arguments:
#   CameraProductId - this can be found using lsusb. Refer to the README.md
#
# Usage:
# ./install.sh CameraProductId

# Globals
OPT_SOURCE_PATH=/opt/microsoft-lifecam-focus-fix
SET_UTIL_PATH=${OPT_SOURCE_PATH}/utils/set-cam-focus-status.sh
UDEV_RULE_PATH=/etc/udev/rules.d/80-disable-lifecam-auto-focus.rules

#######################################
# A helper method for display log messages.
# Arguments:
#   msg - A string message to display
#   msgType - A string of either "warning", "error" or "success"
#######################################
logger() {
    # Get arguments
    local msg=$1
    local msgType=$2  # Optional message type

    # ANSI colour escape codes
    local yellow='\033[1;33m'
    local red='\033[1;31m'
    local cyan='\033[1;36m'
    local normal='\033[0m'
    local green='\033[1;32m'

    # Determine message type
    case $msgType in
        warning)
            msgPrefix="${yellow}[WARNING]${normal}"
            ;;
        error)
            msgPrefix="${red}[ERROR]${normal}"
            ;;
        success)
            msgPrefix="${green}[SUCCESS]${normal}"
            ;;
        *)
            msgPrefix="${cyan}[INFO]${normal}"
            ;;
    esac

    # Output log message
    if [ "$msgPrefix" != "error" ]; then
        echo -e "$msgPrefix $msg"
    else
        >&2 echo -e "$msgPrefix $msg"
    fi
}

#######################################
# Displays usage instructions.
# Arguments:
#   None
#######################################
usage() {
    logger "Unexpected number of arguments" "error"
    echo "Usage: $(basename "$0") CameraProductId"
    exit 1
}


#######################################
# Main
#######################################

# Check usage and get arguments
expectedArgs=1
if [[ $# -ne $expectedArgs ]]
then
    usage
elif [[ $# -eq $expectedArgs ]]
then
    camProductId=$1
fi

if [ "$EUID" -ne 0 ]; then 
    logger "Run this script as root" "error"
    exit 1
fi

logger "Checking if specified camera is supported"
utils/get-cam-focus-status.sh $camProductId

logger "Removing any existing source files at $OPT_SOURCE_PATH"
rm -rf $OPT_SOURCE_PATH

logger "Copying source files to $OPT_SOURCE_PATH"
mkdir $OPT_SOURCE_PATH
cp -r ./* $OPT_SOURCE_PATH

logger "Attempting to apply udev rule $UDEV_RULE_PATH"
export CAM_PRODUCT_ID=$camProductId
export SET_UTIL_PATH
cat udev/80-disable-lifecam-auto-focus.rules.tmpl | envsubst > $UDEV_RULE_PATH
if [ $? -ne 0 ]; then
    logger "Failed to apply udev rule $UDEV_RULE_PATH" "error"
    exit 1
else
    logger "Applied udev rule $UDEV_RULE_PATH" "success"
fi
unset CAM_PRODUCT_ID SET_UTIL_PATH

logger "Force udev rule refresh and trigger (just in case)"
udevadm control --reload
if [ $? -ne 0 ]; then
    logger "Failed to force refresh udev rules" "error"
    exit 1
fi
udevadm trigger --property-match="ID_MODEL_ID"="$camProductId"
if [ $? -ne 0 ]; then
    logger "Failed to force trigger udev rule for ID_MODEL_ID=$camProductId" "error"
    exit 1
fi

logger "Installed Microsoft Lifecam auto focus fix" "success"
exit 0
