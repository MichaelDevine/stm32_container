@echo off
REM Author: Michael Devine
REM Company: Circumjovial, LLC
REM Copyright (c): 2026
REM License: MIT License
REM Web: www.circumjovial.com
REM Version: 0.1

setlocal enabledelayedexpansion

REM Local initialization script for things that devcontainer.json can't do.
REM Find, Bind, and Attach ST-Link debugger using usbipd and add environment
REM variables to the .env file for Docker to pick up.

set "HOST_PROJECT_NAME=%~1"

echo devcontainer.bat runs on host to bridge USB devices
echo to the dev container:
echo Binding ST-Link Debuggers...
echo.

set "SUPPORTED_STLINK_IDS=0483:3744 0483:3748 0483:374B 0483:3752 0483:374E 0483:374F 0483:3753 0483:3757"
set "STLINK_HARDWARE_ID="
set "SCRIPT_EXIT_CODE=0"
set "STLINK_BUSID="
set "STLINK_USB_BUS_NUMBER="
set "STLINK_USB_BUS_DIR="
set "UNSUPPORTED_STLINK_BUSID="
set "UNSUPPORTED_STLINK_HARDWARE_ID="

if not defined HOST_PROJECT_NAME (
    call :fail "HOST_PROJECT_NAME argument is required. Pass ${localWorkspaceFolderBasename} from devcontainer.json."
    goto :finish
)

echo Host project folder name: !HOST_PROJECT_NAME!

REM Find an ST-Link device, confirm its hardware ID is in the supported list,
REM and then bind/attach it with usbipd.
:findDevice
set "STLINK_BUSID="
set "STLINK_HARDWARE_ID="
set "STLINK_USB_BUS_NUMBER="
set "STLINK_USB_BUS_DIR="
set "UNSUPPORTED_STLINK_BUSID="
set "UNSUPPORTED_STLINK_HARDWARE_ID="

for /f "tokens=1,2" %%i in ('usbipd list ^| findstr /I /R /C:"^[0-9][0-9]*-[0-9][0-9]*" ^| findstr /I /C:"ST-Link" /C:"STLINK"') do (
    set "CANDIDATE_BUSID=%%i"
    set "CANDIDATE_HARDWARE_ID=%%j"
    call :is_supported_stlink_hardware_id !CANDIDATE_HARDWARE_ID!
    if not errorlevel 1 (
        set "STLINK_BUSID=!CANDIDATE_BUSID!"
        set "STLINK_HARDWARE_ID=!CANDIDATE_HARDWARE_ID!"
        goto :deviceFound
    )

    set "UNSUPPORTED_STLINK_BUSID=!CANDIDATE_BUSID!"
    set "UNSUPPORTED_STLINK_HARDWARE_ID=!CANDIDATE_HARDWARE_ID!"
)
if not defined STLINK_BUSID (
    if defined UNSUPPORTED_STLINK_HARDWARE_ID (
        call :fail "Found ST-Link BUSID !UNSUPPORTED_STLINK_BUSID! with unsupported hardware ID !UNSUPPORTED_STLINK_HARDWARE_ID!. Supported IDs: !SUPPORTED_STLINK_IDS!."
        goto :finish
    ) else (
        echo No supported ST-Link device was found.
        echo Connect the device, then press any key to try again.
        timeout /t -1 >nul
        echo.
        goto :findDevice
    )
)

:deviceFound
echo Inspecting ST-Link BUSID: !STLINK_BUSID!
echo   Hardware ID: !STLINK_HARDWARE_ID!
call :get_usbipd_state !STLINK_BUSID!
if errorlevel 1 (
    call :fail "Unable to determine the current usbipd state for BUSID !STLINK_BUSID!."
    goto :finish
)

echo   Current usbipd state: !USBIPD_DEVICE_STATE!

if /i "!USBIPD_DEVICE_STATE!"=="Not shared" (
    call :run_elevated_bind !STLINK_HARDWARE_ID! !STLINK_BUSID! Shared Attached
    if errorlevel 1 goto :finish

    call :get_usbipd_state !STLINK_BUSID!
    if errorlevel 1 (
        call :fail "Unable to verify the usbipd state for BUSID !STLINK_BUSID! after bind."
        goto :finish
    )

    echo   State after bind: !USBIPD_DEVICE_STATE!
) else (
    if /i "!USBIPD_DEVICE_STATE!"=="Shared" (
        echo   Bind step skipped because BUSID !STLINK_BUSID! is already shared.
    ) else (
        if /i "!USBIPD_DEVICE_STATE!"=="Attached" (
            echo   Bind step skipped because BUSID !STLINK_BUSID! is already attached.
        ) else (
            call :fail "Unexpected usbipd state for BUSID !STLINK_BUSID!: !USBIPD_DEVICE_STATE!."
            goto :finish
        )
    )
)

if /i "!USBIPD_DEVICE_STATE!"=="Attached" (
    echo   Attach step skipped because BUSID !STLINK_BUSID! is already attached.
) else (
    call :run_usbipd_step attach "usbipd attach -w -b !STLINK_BUSID!" !STLINK_BUSID! Attached
    if errorlevel 1 goto :finish

    call :get_usbipd_state !STLINK_BUSID!
    if errorlevel 1 (
        call :fail "Unable to verify the usbipd state for BUSID !STLINK_BUSID! after attach."
        goto :finish
    )

    echo   State after attach: !USBIPD_DEVICE_STATE!

    if /i not "!USBIPD_DEVICE_STATE!"=="Attached" (
        call :fail "BUSID !STLINK_BUSID! did not reach the Attached state. Current state: !USBIPD_DEVICE_STATE!."
        goto :finish
    )
)

for /f "tokens=1 delims=-" %%i in ("!STLINK_BUSID!") do set "STLINK_USB_BUS_NUMBER=%%i"
set "STLINK_USB_BUS_NUMBER=000!STLINK_USB_BUS_NUMBER!"
set "STLINK_USB_BUS_DIR=/dev/bus/usb/!STLINK_USB_BUS_NUMBER:~-3!"
echo   Writing compose environment to .env:
echo     HOST_PROJECT_NAME=!HOST_PROJECT_NAME!
echo     USB_STLINK_BUS_DIR=!STLINK_USB_BUS_DIR!
(
    echo HOST_PROJECT_NAME=!HOST_PROJECT_NAME!
    echo USB_STLINK_BUS_DIR=!STLINK_USB_BUS_DIR!
) > "%~dp0.env"

:finish

echo.

exit /b !SCRIPT_EXIT_CODE!

:run_usbipd_step
echo   Running: %~2
call %~2

set "USBIPD_LAST_EXIT_CODE=!ERRORLEVEL!"
if "!USBIPD_LAST_EXIT_CODE!"=="0" exit /b 0

call :get_usbipd_state %~3
if errorlevel 1 (
    call :fail "usbipd %~1 failed with exit code !USBIPD_LAST_EXIT_CODE!, and the state for BUSID %~3 could not be re-read."
    exit /b 1
)

if /i "!USBIPD_DEVICE_STATE!"=="%~4" (
    echo   Non-zero %~1 exit code ignored because BUSID %~3 is already %~4.
    exit /b 0
)

if not "%~5"=="" (
    if /i "!USBIPD_DEVICE_STATE!"=="%~5" (
        echo   Non-zero %~1 exit code ignored because BUSID %~3 is already %~5.
        exit /b 0
    )
)

call :fail "usbipd %~1 failed with exit code !USBIPD_LAST_EXIT_CODE! for BUSID %~3. Current state: !USBIPD_DEVICE_STATE!."
exit /b 1

:run_elevated_bind
echo   Running elevated bind: usbipd bind -i %~1
echo   Administrative approval may be required.
powershell -NoProfile -ExecutionPolicy Bypass -Command "try { $process = Start-Process -FilePath 'usbipd' -ArgumentList @('bind','-i','%~1') -Verb RunAs -Wait -PassThru; exit $process.ExitCode } catch { if ($_.Exception -and $_.Exception.NativeErrorCode -eq 1223) { exit 1223 } exit 1 }"

set "USBIPD_LAST_EXIT_CODE=!ERRORLEVEL!"
if "!USBIPD_LAST_EXIT_CODE!"=="0" exit /b 0

if "!USBIPD_LAST_EXIT_CODE!"=="1223" (
    call :fail "Binding hardware ID %~1 was canceled at the UAC prompt."
    exit /b 1
)

call :get_usbipd_state %~2
if errorlevel 1 (
    call :fail "usbipd bind failed with exit code !USBIPD_LAST_EXIT_CODE!, and the state for BUSID %~2 could not be re-read."
    exit /b 1
)

if /i "!USBIPD_DEVICE_STATE!"=="%~3" (
    echo   Non-zero bind exit code ignored because BUSID %~2 is already %~3.
    exit /b 0
)

if not "%~4"=="" (
    if /i "!USBIPD_DEVICE_STATE!"=="%~4" (
        echo   Non-zero bind exit code ignored because BUSID %~2 is already %~4.
        exit /b 0
    )
)

call :fail "usbipd bind failed with exit code !USBIPD_LAST_EXIT_CODE! for BUSID %~2. Current state: !USBIPD_DEVICE_STATE!."
exit /b 1

:is_supported_stlink_hardware_id
for %%i in (!SUPPORTED_STLINK_IDS!) do (
    if /i "%~1"=="%%i" exit /b 0
)

exit /b 1

:get_usbipd_state
set "USBIPD_DEVICE_STATE="
set "USBIPD_LIST_LINE="

for /f "delims=" %%L in ('usbipd list ^| findstr /R /C:"^%~1 "') do (
    set "USBIPD_LIST_LINE=%%L"
)

if not defined USBIPD_LIST_LINE exit /b 1

echo(!USBIPD_LIST_LINE! | findstr /I /C:"Not shared" >nul
if not errorlevel 1 (
    set "USBIPD_DEVICE_STATE=Not shared"
    exit /b 0
)

echo(!USBIPD_LIST_LINE! | findstr /I /C:"Attached" >nul
if not errorlevel 1 (
    set "USBIPD_DEVICE_STATE=Attached"
    exit /b 0
)

echo(!USBIPD_LIST_LINE! | findstr /I /C:"Shared" >nul
if not errorlevel 1 (
    set "USBIPD_DEVICE_STATE=Shared"
    exit /b 0
)

set "USBIPD_DEVICE_STATE=Unknown"
exit /b 0

:fail
echo ERROR: %~1
set "SCRIPT_EXIT_CODE=1"
exit /b 1
