#!/usr/bin/env bash

# Author: Michael Devine
# Company: Circumjovial, LLC
# Copyright (c): 2026
# License: MIT License
# Web: www.circumjovial.com
# Version: 0.1

# This script ensures that the USB device permissions are set correctly.

set -euo pipefail

target_user="${SUDO_USER:-${USER:-${CONTAINER_USER:-}}}"

log_warning() {
    printf 'Warning: %s\n' "$*" >&2
}

usb_minor_from_bus_device() {
    local bus_num="$1"
    local device_num="$2"

    printf '%d' $(( (bus_num - 1) * 128 + (device_num - 1) ))
}

ensure_usb_device_node() {
    local bus_str="$1"
    local device_str="$2"
    local bus_num="$((10#$bus_str))"
    local device_num="$((10#$device_str))"
    local usb_dir="/dev/bus/usb/$bus_str"
    local usb_path="$usb_dir/$device_str"
    local minor

    if [ -c "$usb_path" ]; then
        printf '%s\n' "$usb_path"
        return 0
    fi

    mkdir -p "$usb_dir"

    minor="$(usb_minor_from_bus_device "$bus_num" "$device_num")"

    if ! mknod "$usb_path" c 189 "$minor"; then
        log_warning "Could not create USB device node $usb_path."
        return 1
    fi

    printf '%s\n' "$usb_path"
}

device_is_rw_for_user() {
    local path="$1"
    local user_name="$2"

    if ! id "$user_name" >/dev/null 2>&1; then
        return 1
    fi

    sudo -u "$user_name" test -r "$path" && sudo -u "$user_name" test -w "$path"
}

fix_device() {
    local path="$1"
    local group_name="$2"

    if [ ! -c "$path" ]; then
        return 0
    fi

    if device_is_rw_for_user "$path" "$target_user"; then
        return 0
    fi

    if ! chgrp "$group_name" "$path"; then
        log_warning "Could not change group on $path; leaving existing ownership in place."
    fi

    if ! chmod 660 "$path"; then
        log_warning "Could not change mode on $path; leaving existing permissions in place."
    fi

    if ! device_is_rw_for_user "$path" "$target_user"; then
        local owner_name
        local current_group
        local current_mode

        owner_name="$(stat -c '%U' "$path" 2>/dev/null || printf '?')"
        current_group="$(stat -c '%G' "$path" 2>/dev/null || printf '?')"
        current_mode="$(stat -c '%a' "$path" 2>/dev/null || printf '?')"

        log_warning "$target_user may still lack access to $path (owner=$owner_name group=$current_group mode=$current_mode)."
    fi
}

# Docker passes device nodes into the container after image build, so udev rules in the
# image do not reliably update permissions for the mapped ST-LINK node.
if command -v lsusb >/dev/null 2>&1; then
    while read -r usb_path; do
        [ -n "$usb_path" ] || continue
        fix_device "$usb_path" plugdev
    done < <(
        lsusb | awk '$6 ~ /^0483:/ {gsub(":", "", $4); print $2 " " $4}' |
        while read -r bus_str device_str; do
            [ -n "$bus_str" ] || continue
            [ -n "$device_str" ] || continue
            ensure_usb_device_node "$bus_str" "$device_str" || true
        done
    )
else
    log_warning "lsusb is unavailable; skipping ST-LINK USB permission checks."
fi

for tty_path in /dev/ttyACM*; do
    [ -e "$tty_path" ] || continue
    fix_device "$tty_path" dialout
done