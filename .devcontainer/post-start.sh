#!/usr/bin/env bash

# Author: Michael Devine
# Company: Circumjovial, LLC
# Copyright (c): 2026
# License: MIT License
# Web: www.circumjovial.com
# Version: 0.1

# This script ensures that the workspace path is set, and if not, 
# emits an error. Then it cals the fix-device-permissions.sh to 
# make sure ST-Link device permissions are correct. 

set -euo pipefail

workspace_dir="${1:?workspace path required}"

bash "$workspace_dir/.devcontainer/fix-device-permissions.sh"