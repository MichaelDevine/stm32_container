#!/usr/bin/env bash

set -euo pipefail

target_user="${SUDO_USER:-${USER:-vscode}}"

log_warning() {
    printf 'Warning: %s\n' "$*" >&2
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
    done < <(lsusb | awk '$6 ~ /^0483:/ {gsub(":", "", $4); print "/dev/bus/usb/" $2 "/" $4}')
else
    log_warning "lsusb is unavailable; skipping ST-LINK USB permission checks."
fi

for tty_path in /dev/ttyACM*; do
    [ -e "$tty_path" ] || continue
    fix_device "$tty_path" dialout
done