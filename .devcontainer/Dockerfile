# Author: Michael Devine
# Company: Circumjovial, LLC
# Copyright (c): 2026
# License: MIT License
# Web: www.circumjovial.com
# Version: 0.1

# Base image with Ubuntu
FROM ubuntu:24.04

# Container user name, supplied by docker-compose from .env (written by devcontainer.bat).
ARG CONTAINER_USER=vscode
ENV CONTAINER_USER=${CONTAINER_USER}

# Avoid interactive prompts during install
ENV DEBIAN_FRONTEND=noninteractive

# Install dependencies
RUN apt-get update && apt-get install -y \
    build-essential \
    cmake \
    git \
    wget \
    unzip \
    openocd \
    ninja-build \
    sudo \
    linux-tools-virtual-hwe-24.04 \
    usbutils \
    libusb-1.0-0 \
    udev \
    nano \
    gperf \
    ccache dfu-util device-tree-compiler wget python3-dev python3-venv python3-tk \
    xz-utils file make gcc gcc-multilib g++-multilib libsdl2-dev libmagic1 \
    && rm -rf /var/lib/apt/lists/*

RUN cat <<'EOF' >/usr/local/bin/STM32_Programmer_CLI
#!/usr/bin/env bash
set -euo pipefail

shopt -s nullglob
matches=(/home/"$CONTAINER_USER"/.local/share/stm32cube/bundles/programmer/*/bin/STM32_Programmer_CLI)

if [ "${#matches[@]}" -eq 0 ]; then
    printf 'STM32_Programmer_CLI is not installed yet. Allow the STM32 extension to finish installing the programmer bundle.\n' >&2
    exit 127
fi

latest_cli=$(printf '%s\n' "${matches[@]}" | sort -V | tail -n 1)
exec "$latest_cli" "$@"
EOF
RUN chmod 755 /usr/local/bin/STM32_Programmer_CLI

# Install ARM GCC toolchain (14.2.Rel1)
#RUN wget https://developer.arm.com/-/media/Files/downloads/gnu/14.2.rel1/binrel/arm-gnu-toolchain-14.2.rel1-x86_64-arm-none-eabi.tar.xz
#RUN tar -xf arm-gnu-toolchain-14.2.rel1-x86_64-arm-none-eabi.tar.xz -C /opt
#RUN rm arm-gnu-toolchain-14.2.rel1-x86_64-arm-none-eabi.tar.xz

# TODO Add Zephyr-installed toolchain to PATH
#ENV PATH="/opt/arm-gnu-toolchain-14.2.rel1-x86_64-arm-none-eabi/bin:${PATH}"
#ENV ARM_GCC_PATH="/opt/arm-gnu-toolchain-14.2.rel1-x86_64-arm-none-eabi/bin"

# Create non-root user
RUN useradd -M -s /bin/bash "${CONTAINER_USER}" && \
    echo "${CONTAINER_USER}:${CONTAINER_USER}" | chpasswd && \
    adduser "${CONTAINER_USER}" sudo
RUN usermod -a -G plugdev "${CONTAINER_USER}"
RUN usermod -a -G dialout "${CONTAINER_USER}"
# (Optional) Ensure the user is not prompted for a password when using sudo
RUN echo "${CONTAINER_USER} ALL=(ALL) NOPASSWD: ALL" >> /etc/sudoers

RUN mkdir -p "/home/${CONTAINER_USER}" && \
    chown "${CONTAINER_USER}:${CONTAINER_USER}" "/home/${CONTAINER_USER}"

USER ${CONTAINER_USER}

# Do user-level Zephyr installs and setup
RUN mkdir -p "/home/${CONTAINER_USER}/zephyrproject" && \
    python3 -m venv "/home/${CONTAINER_USER}/zephyrproject/.venv" && \
    "/home/${CONTAINER_USER}/zephyrproject/.venv/bin/pip" install west && \
    "/home/${CONTAINER_USER}/zephyrproject/.venv/bin/west" init "/home/${CONTAINER_USER}/zephyrproject" --mr v4.3.0 && \
    cd "/home/${CONTAINER_USER}/zephyrproject" && \
    "/home/${CONTAINER_USER}/zephyrproject/.venv/bin/west" update && \
    "/home/${CONTAINER_USER}/zephyrproject/.venv/bin/west" zephyr-export && \
    "/home/${CONTAINER_USER}/zephyrproject/.venv/bin/west" packages pip --install && \
    cd "/home/${CONTAINER_USER}/zephyrproject/zephyr" && \
    "/home/${CONTAINER_USER}/zephyrproject/.venv/bin/west" sdk install -t arm-zephyr-eabi

USER root

# UDEV rules are not sufficient for passed-through device nodes in this container, but keep
# them in place for environments where udev is actively managing the device inside the image.
RUN echo "SUBSYSTEM==\"usb\", ATTRS{idVendor}==\"0483\", MODE=\"0666\"" >> /etc/udev/rules.d/99-stm32-usb.rules
RUN echo "KERNEL==\"ttyACM[0-9]*\", MODE=\"0666\"" >> /etc/udev/rules.d/99-stm32-usb.rules
RUN ln -s "/home/${CONTAINER_USER}/zephyrproject" /workspaces

USER ${CONTAINER_USER}
WORKDIR /home/${CONTAINER_USER}/zephyrproject
