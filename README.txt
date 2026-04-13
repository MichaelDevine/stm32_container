Author: Michael Devine
Company: Circumjovial, LLC
Copyright (c): 2026
License: MIT License
Web: www.circumjovial.com
Version: 0.1

!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!IMPORTANT!!!!!!!!!!!!!!!!!!!!!!!
There are currently two issues in this that prevent it from working on most systems. I am 
working on fixing these. 
1. The ST-Link device does not necessarily enumerate to the same hub and port as it does on
Windows, even if it's the only device on the hub. 
2. The device has to have already been bound using usbipd, which requires elevated privileges,
for the script to work. My own bindings were persisted, hence I did not notice this. 

This repository contains config files and scripts that make it seemless to create and launch
a VS Code Dev Container with everything needed to build, debug, and connect with terminal, to
an stm32 ST-Link connected device. You can use this as a reference to see how to do it, or
adapt it to your environment. The scripts automatically find your ST-Link device and 
automatically set up the permissions and passthrough for the tools inside the container to 
connect to your device via ST-Link and serial. Most importantly, it doesn't run privileged, 
ensuring secure containerization. The USB permission passed through only allows access to the 
ST-Link device, no others, and the serial permission is just for any /dev/ttyASM* devices. 

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
7. Open the git repo folder with VS Code. If "Reopen in Container" doesn't pop up, 
   find it and run it with CTRL-SHIFT-P
8. Follow the prompts, make sure you say yes to additional installs which will pop
   up in the lower right or is accessible from the notifications icon also in the lower
   right. Thpse are the installs for VS Code plugins inside the container.
9. After everything finishes, your device should show up in the "STM32CUBE DEVICES" tab
   on the lower left and Serial Monitor should have /dev/ttyASM0 as a choice. 
