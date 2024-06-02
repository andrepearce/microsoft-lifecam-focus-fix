#!/bin/bash -e
#
# A utility to determine if the auto focus is enabled on a Microsoft Lifecam
#
# Arguments:
#   CameraProductId - this can be found using lsusb. Refer to the README.md
#
# Usage:
# ./get-cam-focus-status.sh CameraProductId


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

# Find supported cameras
logger "Searching for supported Camera with Product ID: $camProductId"

# Loop through video devices
declare -A supportedDevices
for i in /dev/video*; do
    currentProductId=$(udevadm info -a --name=$i | sed -n -e '/{idProduct}/s/.*=="\(.*\)"/\1/p' | head -n 1)
    if [ "$currentProductId" == "$camProductId" ]; then
        focusAutoCtl=$(uvcdynctrl -d $i -c 2>/dev/null | sed -n -e '/Focus.*Auto/s/^[[:space:]]*//p')
        if [ -n "$focusAutoCtl" ]; then
            logger "Found a supported camera at $i"
            supportedDevices[$i]="$focusAutoCtl"
        fi
    fi
done

if [ ${#supportedDevices[@]} -eq 0 ]; then
    logger "No supported cameras found with product ID: $camProductId" "error"
    exit 1
fi

# Display the auto focus status for each camera
for device in "${!supportedDevices[@]}"; do
    focusStatus=$(uvcdynctrl -d $device --get="${supportedDevices[$device]}" 2>/dev/null)
    if [ $focusStatus -eq 1 ]; then
        logger "Auto focus for device $device is enabled" "warning"
    else
        logger "Auto focus for device $device is disabled" "success"
    fi
done
exit 0
