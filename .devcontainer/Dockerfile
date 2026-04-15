# Author: Michael Devine
# Company: Circumjovial, LLC
# Copyright (c): 2026
# License: MIT License
# Web: www.circumjovial.com
# Version: 0.1

# Base image with Ubuntu
FROM ubuntu:24.04

# Avoid interactive prompts during install
ENV DEBIAN_FRONTEND=noninteractive

# Install dependencies
RUN apt-get update && apt-get install -y \
    build-essential=12.10ubuntu1 \
    cmake=3.28.3-1build7 \
    git=1:2.43.0-1ubuntu7.3 \
    wget=1.21.4-1ubuntu4.1 \
    unzip=6.0-28ubuntu4.1 \
    openocd=0.12.0-1build2 \
    ninja-build=1.11.1-2 \
    sudo=1.9.15p5-3ubuntu5.24.04.2 \
    linux-tools-virtual-hwe-24.04=6.17.0-20.20~24.04.1 \
    usbutils=1:017-3build1 \
    libusb-1.0-0=2:1.0.27-1 \
    udev=255.4-1ubuntu8.15 \
    nano=7.2-2ubuntu0.1 \
    && rm -rf /var/lib/apt/lists/*

# This creates a script that will dynamically find and launch STM32_Programmer_CLI
# which at this time is installed in a verisoned location which could change.
# STM32_Programmer_CLI is installed by the STMicro plugin. 
RUN cat <<'EOF' >/usr/local/bin/STM32_Programmer_CLI
#!/usr/bin/env bash
set -euo pipefail

shopt -s nullglob
matches=(/home/vscode/.local/share/stm32cube/bundles/programmer/*/bin/STM32_Programmer_CLI)

if [ "${#matches[@]}" -eq 0 ]; then
    printf 'STM32_Programmer_CLI is not installed yet. Allow the STM32 extension to finish installing the programmer bundle.\n' >&2
    exit 127
fi

latest_cli=$(printf '%s\n' "${matches[@]}" | sort -V | tail -n 1)
exec "$latest_cli" "$@"
EOF
RUN chmod 755 /usr/local/bin/STM32_Programmer_CLI

# This is an example toolchain setup. Change it to yours here. 
# Install ARM GCC toolchain (14.2.Rel1)
RUN wget https://developer.arm.com/-/media/Files/downloads/gnu/14.2.rel1/binrel/arm-gnu-toolchain-14.2.rel1-x86_64-arm-none-eabi.tar.xz
RUN tar -xf arm-gnu-toolchain-14.2.rel1-x86_64-arm-none-eabi.tar.xz -C /opt
RUN rm arm-gnu-toolchain-14.2.rel1-x86_64-arm-none-eabi.tar.xz

# Add toolchain to PATH
ENV PATH="/opt/arm-gnu-toolchain-14.2.rel1-x86_64-arm-none-eabi/bin:${PATH}"
ENV ARM_GCC_PATH="/opt/arm-gnu-toolchain-14.2.rel1-x86_64-arm-none-eabi/bin"

# Create non-root user for VS Code
RUN useradd -m -s /bin/bash vscode && echo "vscode:vscode" | chpasswd && adduser vscode sudo
RUN usermod -a -G plugdev vscode
RUN usermod -a -G dialout vscode

# Paths in bash after Dev Containers sets it up are long. This makes the prompt in 
# bash more reasonable.
RUN cat <<'EOF' >> /home/vscode/.bashrc
PS1='\W\\$ '
EOF
RUN chown vscode:vscode /home/vscode/.bashrc

# (Optional) Ensure the user is not prompted for a password when using sudo. The container
# is NOT running privileged, so this introduces minimal risk to the host
RUN echo "vscode ALL=(ALL) NOPASSWD: ALL" >> /etc/sudoers

# UDEV rules are not sufficient for passed-through device nodes in this container, but keep
# them in place for environments where udev is actively managing the device inside the image.
RUN echo "SUBSYSTEM==\"usb\", ATTRS{idVendor}==\"0483\", MODE=\"0666\"" >> /etc/udev/rules.d/99-stm32-usb.rules
RUN echo "KERNEL==\"ttyACM[0-9]*\", MODE=\"0666\"" >> /etc/udev/rules.d/99-stm32-usb.rules

USER vscode
WORKDIR /workspaces
