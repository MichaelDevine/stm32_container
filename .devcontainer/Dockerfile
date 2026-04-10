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
    libusb-1.0.0 \
    udev \
    nano \
    && rm -rf /var/lib/apt/lists/*

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
# (Optional) Ensure the user is not prompted for a password when using sudo
RUN echo "vscode ALL=(ALL) NOPASSWD: ALL" >> /etc/sudoers

# UDEV Rule to Allow USB to be accessed by debugger
RUN echo "SUBSYSTEM==\"usb\", ATTRS{idVendor}==\"0483\", MODE=\"0666\"" >> /etc/udev/rules.d/99-stm32-usb.rules
RUN echo "KERNEL==\"ttyACM[0-9]*\", MODE=\"0666\"" >> /etc/udev/rules.d/99-stm32-usb.rules

USER vscode
WORKDIR /workspace
