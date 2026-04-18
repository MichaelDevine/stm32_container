# STM32 Dev Container

Author: Michael Devine  
Company: Circumjovial, LLC  
License: MIT License  
Version: 0.1

This repository contains a VS Code Dev Container setup for STM32 development on a WIndows 11 host with an ST-Link debugger 
attached through `usbipd` and Docker Desktop. A key feature of the setup is that the Docker container is NOT run "privileged" 
so that host security is not compromised. 

## Overview

The container installs the minimum necessary for basic STM32 development. Users can add additional plugins
to the devcontainer.json file and additional apt-installed packages to the Dockerfile.

The current implementation uses the minimum practical way to get an ST-Link device shared through to the container without
the container running provileged. This is accomplished by enabling enabling access only to the USB bus on which 
the ST-Link device is found. Sharing just the port the device is on is not possible because it is not known which port it
will be enumerated on each time the Docker container starts. 

## Requirements

This repository is currently designed around Windows 11 with Docker Desktop, WSL 2, VS Code, and `usbipd`.

Install:

1. WSL 2 and Docker Desktop  
   <https://learn.microsoft.com/en-us/windows/wsl/install>
   Be sure to enable the "Use the WSL 2 based engine" setting.
2. VS Code
   <https://code.visualstudio.com/>
3. The VS Code Dev Containers extension
4. `usbipd-win`
   <https://github.com/dorssel/usbipd-win/releases>
5. Put the ".devcontainer" directory from this repo into the top level directory of your 
   VS Code project.

## Usage

1. Connect the STM32 board to a USB port.
2. Open this repository in VS Code on Windows.
3. Hit CTRL-SHIFT P, and find and run Build and Reopen in Container.
4. The first time the device is bound, usbipd needs to run elevated. YOu will be prompted for this. 
5. Ignore a warning about the container possibly not being able to open because referenced directories don't exist on the host.
   They will exist in the container. 
5. Allow the extension installs that VS Code prompts for. If you miss the prompt, click the notificaitons icon (the bell)
   in the lower right to see the notification to allow the installs.
6. After the container starts, verify that the STM32Cube Devices and Boards view shows the debugger and Serial Terminal can 
   connect to the serial device. 

In future runs, just "reopen in contianer" and it will open quiickly. If you change any of the files in the .devcontainer 
directory, however, you will have to rebuild.