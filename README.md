# Microsoft Lifecam Auto Focus Fix

This repository provides a simple method to resolve the notorious continuous auto focussing issue that is present on the Microsoft Lifecam (and related cameras).

The amazing "fix"... simply disable the auto focus feature. 

As much as this doesn't sound like a fix (and sounds more like avoiding the problem), it seems to be the best way to get a usable camera that doesn't cause the image to go blurry even 10 or so seconds.

The Microsoft Lifecams are UVC compliant cameras and therefore the dynamic controls can be interfaced via the UVC driver. This can be done with a tool such as `uvcdynctrl`.

## Requirements

- Debian based distribution (this approach can be adapted to others, but I have not tested it)
- `uvcdynctrl` installed - (`apt install uvcdynctrl`)

## Install

1. Work out the product ID of the camera using `lsusb`. For example:
    ```bash
    $ lsusb                
    ...
    Bus 003 Device 056: ID 045e:075d Microsoft Corp. LifeCam Cinema
    ...
    ```
    The product ID for the above camera is `075d`. If you have multiple cameras connected, you may need to disconnect them and run `lsusb` again to isolate the camera you want to disable auto focus for.
2. Run the install script, passing the product ID obtained from the previous step. For example:
    ```bash
    # Replace '075d' with the product ID you obtained in step 1
    $ ./install.sh 075d
    ```

### Install Details

The install script will essentially copy source files in this repo to `/opt` on your machine and setup a udev rule to disable the auto focus every time the camera is connected. The udev rule is necessary as the camera does not persist the setting of disabling the auto focus control.

## Useful Links

- https://wiki.archlinux.org/title/Udev#List_attributes_of_a_device
- https://linux.die.net/man/7/udev
- https://www.bot-thoughts.com/2013/01/lifecam-hd-6000-autofocus-fix-raspberry.html
