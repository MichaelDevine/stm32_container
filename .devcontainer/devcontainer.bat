REM Author: Michael Devine
REM Company: Circumjovial, LLC
REM Copyright (c): 2026
REM License: MIT License
REM Web: www.circumjovial.com
REM Version: 0.1

@echo off
setlocal enabledelayedexpansion

REM Local initialization script for things that devcontainer.json can't do.
REM 1. Find, Bind, and Attach ST-Link debugger using usbipd
REM 2. Prepare Unix path to device to be used in devcontainer.json

echo devcontainer.bat runs on host to bridge USB devices
echo to the dev container:
echo Binding ST-Link Debuggers...
echo.

REM Clear the device path value so that we don't pick up a stale value if 
REM the search below fails.
setx USB_STLINK_DEVICE_PATH ""

REM Parent path for a USB device on Ubuntu 24.04
set UNIX_STYLE_DEVICE=/dev/bus/usb

REM Get list of USB devices, filter for ST-Link, extract BUSID, and 
REM bind and attach with usbipd
for /f "tokens=1" %%i in ('usbipd list ^| findstr /C:"ST-Link"') do (
    set "value=%%i"
    REM Check if string is short (BUSID) not long (GUID)
    REM HACK! If position 10 is empty, string is less than 10 chars
    REM TODO Distinguish between "already connected" and real errors
    if "!value:~10,1!"=="" (
        echo !value! | findstr "[0-9]-[0-9]" >nul && (
            echo Binding BUSID: !value!
            usbipd bind -b !value! 2>nul || echo   ^(already bound or error^)
            echo Attaching BUSID: !value!
            usbipd attach -w -b !value! 2>nul || echo   ^(already attached or error^)

            REM Turn the Windows port info into Unix device path
            set UNIX_STYLE_DEVICE=!UNIX_STYLE_DEVICE!/00!value:-=/00!
            set TMP_DEVICE_PATH=!TMP_DEVICE_PATH!/!UNIX_STYLE_DEVICE!
            echo USB Path: !UNIX_STYLE_DEVICE!

            REM Save the device path in the registry, it will
            REM be picked up in the devcontainer.json file.
            setx USB_STLINK_DEVICE_PATH !UNIX_STYLE_DEVICE!

            goto :afterLoop
        )
    )
)
 :afterLoop

echo.