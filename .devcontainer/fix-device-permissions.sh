#!/usr/bin/env bash

set -euo pipefail

fix_device() {
    local path="$1"
    local group_name="$2"

    if [ ! -c "$path" ]; then
        return 0
    fi

    chgrp "$group_name" "$path"
    chmod 660 "$path"
}

# Docker passes device nodes into the container after image build, so udev rules in the
# image do not reliably update permissions for the mapped ST-LINK node.
while read -r usb_path; do
    [ -n "$usb_path" ] || continue
    fix_device "$usb_path" plugdev
done < <(lsusb | awk '$6 ~ /^0483:/ {gsub(":", "", $4); print "/dev/bus/usb/" $2 "/" $4}')

for tty_path in /dev/ttyACM*; do
    [ -e "$tty_path" ] || continue
    fix_device "$tty_path" dialout
done