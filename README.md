# STM32 Dev Container

Author: Michael Devine  
Company: Circumjovial, LLC  
License: MIT License  
Version: 0.1

This repository contains a VS Code Dev Container setup for STM32 development with an ST-Link debugger attached through `usbipd` and Docker Desktop.

## Overview

The container is set up to provide:

- ARM GCC toolchain
- CMake and Ninja
- OpenOCD
- STM32 VS Code extensions
- Serial access through `/dev/ttyACM0`
- ST-Link access from inside the container without running the container as `--privileged`

The current design is intended to survive ST-Link re-enumeration on the same Linux USB bus, where the usbfs path may change from `/dev/bus/usb/001/004` to `/dev/bus/usb/001/005`, and so on.

## How It Works

### Host-side setup

Before the container starts, VS Code runs [`.devcontainer/devcontainer.bat`](.devcontainer/devcontainer.bat) on the host.

That script:

1. Finds a supported ST-Link device using `usbipd list`
2. Binds and attaches it with `usbipd`
3. Derives the Linux usbfs bus directory for the attached device
4. Saves that path to the host environment variable `USB_STLINK_BUS_DIR`

The current script supports these ST-Link hardware IDs:

- `0483:3744`
- `0483:3748`
- `0483:374B`
- `0483:3752`
- `0483:374E`
- `0483:374F`
- `0483:3753`
- `0483:3757`

### Container-side setup

The dev container definition in [`.devcontainer/devcontainer.json`](.devcontainer/devcontainer.json):

- bind-mounts the workspace
- bind-mounts the detected usbfs bus directory from `USB_STLINK_BUS_DIR`
- passes through `/dev/ttyACM0`
- adds the Docker device cgroup rule `c 189:* rw` for USB character devices
- runs [`.devcontainer/fix-device-permissions.sh`](.devcontainer/fix-device-permissions.sh) after startup

The startup permission-fix script is needed because Docker-passed device nodes can appear inside the container as `root:root` with permissions that prevent the `vscode` user from opening the ST-Link, even though `lsusb` can still see it.

## Why The Permission Fix Exists

The image contains `udev` rules for STM32 USB and `ttyACM` devices in [`.devcontainer/Dockerfile`](.devcontainer/Dockerfile), but those rules are not sufficient on their own for Docker-passed device nodes.

In practice:

- the ST-Link may appear inside the container with restrictive ownership and mode
- the STM32 VS Code extension can then see the USB bus but fail to open the probe
- ST tooling reports the debugger as unusable until permissions are corrected

The post-start script repairs ownership and mode for:

- ST USB device nodes, using group `plugdev`
- `/dev/ttyACM*`, using group `dialout`

## Why The USB Path Changes

The trailing number in a path like `/dev/bus/usb/001/004` is the Linux USB `DEVNUM` assigned during enumeration.

That number is chosen by the Linux USB stack, not by Docker. In this setup the numbering happens on the Linux side of the Docker Desktop or WSL `usbipd` path under `vhci_hcd`. Rebinding or reattaching the ST-Link can cause the same debugger to reappear as:

- `/dev/bus/usb/001/004`
- `/dev/bus/usb/001/005`
- `/dev/bus/usb/001/006`

The current workaround avoids hardcoding that trailing device number.

## Scope Of USB Access

This setup exposes usbfs character device nodes needed by libusb-based tools such as ST-Link utilities. It does **not** grant general-purpose drive mounting from inside the container.

Important distinction:

- ST-Link access uses character devices such as `/dev/bus/usb/001/004`
- USB storage devices typically appear as block devices such as `/dev/sdX`
- the container is not run with `--privileged`
- the container is not granted `CAP_SYS_ADMIN`

So this configuration is for debugger and serial access, not for mounting arbitrary USB filesystems.

## Requirements

This repository is currently designed around Windows 11 with Docker Desktop, WSL 2, VS Code, and `usbipd`.

Install:

1. WSL 2 and Docker Desktop  
   <https://learn.microsoft.com/en-us/windows/wsl/install>
   Be sure to enable the "Use the WSL 2 based engine" setting.
2. VS Code  
   <https://code.visualstudio.com/>
3. The VS Code Dev Containers and Container Tools extensions
4. `usbipd-win`  
   <https://github.com/dorssel/usbipd-win/releases>

## Usage On Windows 11

1. Connect the STM32 board to a USB port.
2. Open this repository in VS Code on Windows.
3. Reopen the folder in the dev container.
4. Allow the extension and tool installs that VS Code prompts for.
5. Wait for the host initialization script to bind and attach the supported ST-Link.
6. After the container starts, verify that the STM32Cube Devices and Boards view shows the debugger.

From then on, you should generally be able to reopen the folder and continue working without manually redoing the full setup.

## Useful Verification Commands

Run these inside the container:

```bash
lsusb
ls -l /dev/bus/usb/*/*
lsusb -v -d 0483:374b | head -n 20
/home/vscode/.local/share/stm32cube/bundles/programmer/2.22.0+st.1/bin/STM32_Programmer_CLI -l stlink
```

If permissions are correct, `STM32_Programmer_CLI -l stlink` should list the connected probe.

## Troubleshooting

### The ST-Link shows up in `lsusb` but not in the STM32Cube Devices view

Check whether the user can actually open the device:

```bash
lsusb -v -d 0483:374b | head -n 20
```

If you see `Couldn't open device`, the issue is usually device-node permissions, not missing USB visibility.

### The debugger path changed from `004` to `005`

That is expected Linux USB re-enumeration behavior. The current setup is intended to tolerate that on the same detected bus directory.

### The serial device path changes from `/dev/ttyACM0`

That remains a separate issue. The current dev container still maps `/dev/ttyACM0` explicitly.

## Repository Files

- [`.devcontainer/devcontainer.json`](.devcontainer/devcontainer.json): Dev container definition
- [`.devcontainer/devcontainer.bat`](.devcontainer/devcontainer.bat): Host-side `usbipd` discovery and attach script
- [`.devcontainer/fix-device-permissions.sh`](.devcontainer/fix-device-permissions.sh): Container-side permission repair
- [`.devcontainer/Dockerfile`](.devcontainer/Dockerfile): Image definition
- [`SESSION-2026-04-13.md`](SESSION-2026-04-13.md): Session notes for the USB permission and re-enumeration work