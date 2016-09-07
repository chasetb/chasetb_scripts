#!/bin/bash

# This script downloads and installs the latest Backblaze software for compatible Macs

# Get credential variables

itUsername="$4"
itPassword="$5"

# Determine OS version
osvers=$(sw_vers -productVersion | awk -F. '{print $2}')

# Specify the complete address of the Backblaze installer
# disk image

fileURL="https://secure.backblaze.com/mac/install_backblaze.dmg"

# Specify name of downloaded disk image

bz_dmg="/private/tmp/backblaze.dmg"

myCurl () { /usr/bin/curl -k --retry 3 --silent --show-error "$@"; }

if [[ ${osvers} -lt 6 ]]; then
    echo "Backblaze is not available for Mac OS X 10.5.8 or below."
fi

if [[ ${osvers} -ge 6 ]]; then

    # Download the latest Backblaze software disk image

    myCurl $fileURL -o "$bz_dmg"

    # Specify a /tmp/backblaze.XXXX mountpoint for the disk image

    TMPMOUNT=$(/usr/bin/mktemp -d /private/tmp/backblaze.XXXX)

    # Mount the latest Backblaze disk image to /tmp/backblaze.XXXX mountpoint

    hdiutil attach "$bz_dmg" -mountpoint "$TMPMOUNT" -nobrowse -noverify -noautoopen

    install_app="$TMPMOUNT/Backblaze Installer.app"
    binary_path="$install_app/Contents/MacOS/bzinstall_mate"

    InstallBackblaze (){
        "${binary_path}" -nogui bzdiy -signin "$itUsername" "$itPassword"
    }

    # Before installation on Mac OS X 10.7.x and later, the app's
    # developer certificate is checked to see if it has been signed by
    # Backblaze's developer certificate. Once the certificate check has been
    # passed, the package is then installed.

    if [[ ${binary_path} != "" ]]; then
        if [[ ${osvers} -ge 7 ]]; then
            signature_check=$(codesign -dvvv --entitlements - "$install_app" 2>&1 | awk '/Developer ID Application/ { print $NF }')
            if [[ ${signature_check} = "Backblaze" ]]; then
                # Install Backblaze from the installer package stored inside the disk image
                if InstallBackblaze | /usr/bin/egrep '1001'; then
                    echo "Backblaze was successfully installed."
                else
                    echo "Backblaze install failed."
                    exit 1
                fi
            fi

        # On Mac OS X 10.6.x, the developer certificate check is not an
        # available option, so the package is just installed.

        elif [[ ${osvers} -eq 6 ]]; then
            # Install Backblaze from the installer package stored inside the disk image
            if InstallBackblaze | /usr/bin/egrep '1001'; then
                echo "Backblaze was successfully installed."
            else
                echo "Backblaze install failed."
                exit 1
            fi
        fi
    fi

    # Clean-up

    # Unmount the Backblaze disk image from /tmp/backblaze.XXXX

    /usr/bin/hdiutil detach -force "$TMPMOUNT"

    # Remove the /tmp/backblaze.XXXX mountpoint

    /bin/rm -Rf "$TMPMOUNT"

    # Remove the downloaded disk image

    /bin/rm -Rf "$bz_dmg"
fi

exit 0