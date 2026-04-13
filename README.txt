Author: Michael Devine
Company: Circumjovial, LLC
Copyright (c): 2026
License: MIT License
Web: www.circumjovial.com
Version: 0.1

This repository contains config files and scripts that make it seemless to create and launch
a VS Code Dev Container with everything needed to build, debug, and connect with terminal, to
an stm32 ST-Link connected device. You can use this as a reference to see how to do it, or
adapt it to your environment. The scripts automatically find your ST-Link device and 
automatically set up the permissions and passthrough for the tools inside the container to 
connect to your device via ST-Link and serial. The current dev container avoids 
`--privileged` and instead maps the current ST-Link USB node and `/dev/ttyACM0` 
explicitly after usbipd attach. The initialize script still limits usbipd attachment 
to supported ST-Link hardware IDs. 

Inside the container, the passed-through ST-Link USB node can still arrive as `root:root`
with mode `0664`, which prevents the `vscode` user from opening it even though `lsusb`
can still see it. The dev container now repairs ownership and mode at startup with
`.devcontainer/fix-device-permissions.sh`, because Docker-passed device nodes are not
reliably updated by the image's `udev` rules.

After you've done the steps below just once, from then on you just open the folder with VS Code
and you're developing in your container. No need to redo the passthrough every time. 

On Windows 11:

1. Install WSL 2 and Docker Desktop on Windows
   https://learn.microsoft.com/en-us/windows/wsl/install
2. Install VS Code on Windows
   https://code.visualstudio.com/
3. Install the Dev Containers and Container Tools plugins from Microsoft,
   in VS Code.
4. Install usbipd on Windows, add to path
   https://github.com/dorssel/usbipd-win/releases
5. Connect the board to a USB port
6. Edit Dockerfile, launch.json, and c_cpp_properties.json to reference your 
   toolchain and board. The environment will work without doing this if you 
   just want to see how it works. 
   The current `.devcontainer/devcontainer.json` hardcodes the ST-Link USB path 
   to `/dev/bus/usb/001/004`, so update that value if Docker Desktop exposes 
   your debugger on a different node.
7. Open the git repo folder with VS Code. If "Reopen in Container" doesn't pop up, 
   find it and run it with CTRL-SHIFT-P
8. Follow the prompts, make sure you say yes to additional installs which will pop
   up in the lower right or is accessible from the notifications icon also in the lower
   right. Thpse are the installs for VS Code plugins inside the container.
9. After everything finishes, your device should show up in the "STM32CUBE DEVICES" tab
   on the lower left and Serial Monitor should have /dev/ttyACM0 as a choice. 