Author: Michael Devine
Company: Circumjovial, LLC
Copyright (c): 2026
License: MIT License
Web: www.circumjovial.com
Version: 0.1

On Windows 11:

1. Install WSL 2 and Docker Desktop on Windows
2. Install VS Code on Windows
3. Install the Dev Containers and Container Tools plugins from Microsoft
4. Install usbipd on windows, add to path
5. Connect the board to a USB port
6. Edit Dockerfile, launch.json, and c_cpp_properties.json to reference your 
   toolchain and board. 
7. Open the repo folder with VS Code. If "Reopen in Container" doesn't pop up, 
   find it and run it with CTRL-SHIFT-P
8. Follow the prompts, make sure you say yes to additional installs which will pop
   up in the lower right or is accessible from the notifications icon also in the lower
   right. 
9. After everything finishes, your device should show up in the "STM32CUBE DEVICES" tab
   on the lower left and Serial Monitor should have /dev/ttyASM0 as a choice. 