#!/usr/bin/env bash

set -euo pipefail

workspace_dir="${1:?workspace path required}"

bash "$workspace_dir/.devcontainer/fix-device-permissions.sh"