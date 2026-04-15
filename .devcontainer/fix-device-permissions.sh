#!/usr/bin/env bash

set -euo pipefail

install_stm32_programmer_path() {
    local programmer_path
    local programmer_dir
    local bashrc_line

    programmer_path=$(find /home/vscode -type f -name 'STM32_Programmer_CLI' 2>/dev/null | sort -V | tail -n 1)

    if [ -z "${programmer_path:-}" ]; then
        printf 'STM32_Programmer_CLI was not found under /home/vscode.\n' >&2
        return 0
    fi

    programmer_dir=$(dirname "$programmer_path")
    bashrc_line="export PATH=\"$programmer_dir:\$PATH\""

    touch /home/vscode/.bashrc

    if ! grep -Fqx "$bashrc_line" /home/vscode/.bashrc; then
        printf '\n%s\n' "$bashrc_line" >>/home/vscode/.bashrc
    fi

    chown vscode:vscode /home/vscode/.bashrc
}

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

install_stm32_programmer_path