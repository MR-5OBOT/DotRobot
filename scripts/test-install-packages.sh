#!/usr/bin/env bash
set -euo pipefail

source "$(dirname "$0")/install-packages.sh"

[[ $(cpu_microcode_package GenuineIntel) == intel-ucode ]]
[[ $(cpu_microcode_package AuthenticAMD) == amd-ucode ]]
! cpu_microcode_package unknown
[[ $(gpu_video_package 0x8086) == intel-media-driver ]]
[[ $(gpu_video_package 0x1002) == mesa ]]
! gpu_video_package 0x10de
echo "install-packages hardware detection test passed"
