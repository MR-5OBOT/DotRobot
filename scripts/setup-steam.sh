#!/usr/bin/env bash
# setup-steam.sh - Steam + Proton from zero on Arch.
#
# Works out what this machine actually needs, prints the plan, and only
# then touches anything. Proton runs Windows games by translating D3D to
# Vulkan, so the 32-bit Vulkan stack is not optional - that is the part
# most "just install steam" instructions leave out.
#
# Safe to re-run: every step checks state first and changes nothing that
# is already correct. The only system file it edits is /etc/pacman.conf
# (to turn on [multilib]); it is backed up first and rolled back if the
# result does not parse.
#
#   ./setup-steam.sh              # detect, show the plan, ask, install
#   ./setup-steam.sh --dry-run    # detect and print the plan, change nothing
#   ./setup-steam.sh --check      # detect and verify what is already there
#   ./setup-steam.sh --extras     # also gamescope, mangohud, protontricks
#   ./setup-steam.sh --yes        # no prompts (for unattended runs)

set -uo pipefail

PACMAN_CONF=/etc/pacman.conf
BACKUP="${PACMAN_CONF}.dotrobot-steam.bak"
MIN_FREE_GB=20          # a single modern game can be bigger than this
STALE_DB_DAYS=7

DRY_RUN=no
CHECK_ONLY=no
WANT_EXTRAS=no
ASSUME_YES=no

if [[ -t 1 ]]; then
    R=$'\e[1;31m'; G=$'\e[1;32m'; Y=$'\e[1;33m'; B=$'\e[1;34m'; Z=$'\e[0m'
else
    R=''; G=''; Y=''; B=''; Z=''
fi
info() { printf '%s==>%s %s\n' "$B" "$Z" "$*"; }
ok()   { printf '%s  ok%s %s\n' "$G" "$Z" "$*"; }
warn() { printf '%s  !!%s %s\n' "$Y" "$Z" "$*"; }
die()  { printf '%s ERR%s %s\n' "$R" "$Z" "$*" >&2; exit 1; }

while [[ $# -gt 0 ]]; do
    case "$1" in
        --dry-run) DRY_RUN=yes ;;
        --check)   CHECK_ONLY=yes ;;
        --extras)  WANT_EXTRAS=yes ;;
        --yes|-y)  ASSUME_YES=yes ;;
        -h|--help) sed -n '2,18p' "$0" | sed 's/^# \?//'; exit 0 ;;
        *)         die "unknown argument: $1" ;;
    esac
    shift
done

GPU_LINES=()
GPU_VENDORS=()
PKGS=()
NOTES=()
NEED_MULTILIB=no
NEED_SYNC=no

have_pkg()  { pacman -Qq "$1" &>/dev/null; }
has_vendor() {
    local v
    for v in ${GPU_VENDORS[@]+"${GPU_VENDORS[@]}"}; do [[ "$v" == "$1" ]] && return 0; done
    return 1
}
add_vendor() { has_vendor "$1" || GPU_VENDORS+=("$1"); }

# Queue a package unless it is already installed. Names are deliberately not
# validated here: an unknown target makes pacman abort the whole transaction
# before it changes anything, which is the failure mode we want anyway.
want() {
    local p
    for p in "$@"; do
        have_pkg "$p" && continue
        PKGS+=("$p")
    done
}

confirm() {
    [[ "$ASSUME_YES" == yes ]] && return 0
    local reply
    read -rp "$(printf '%s==>%s %s [y/N] ' "$B" "$Z" "$1")" reply
    [[ "$reply" =~ ^[Yy] ]]
}

# ------------------------------------------------------------- 0. preflight
command -v pacman >/dev/null || die "this script targets Arch (pacman not found)"
[[ $EUID -eq 0 ]] && die "run as your normal user - Steam's library and prefixes are per-user"

# ---------------------------------------------------------------- 1. detect
info "Looking at the hardware"

if command -v lspci >/dev/null 2>&1; then
    while IFS= read -r line; do
        [[ -n "$line" ]] || continue
        GPU_LINES+=("$line")
        case "${line,,}" in
            *nvidia*)                                  add_vendor nvidia ;;
            *intel*)                                   add_vendor intel  ;;
            *"advanced micro devices"*|*"amd/ati"*)    add_vendor amd    ;;
        esac
    done < <(lspci -nn 2>/dev/null | grep -Ei 'vga compatible controller|3d controller|display controller')
fi

# Fallback for a box without pciutils - the PCI vendor id is in sysfs.
if [[ ${#GPU_VENDORS[@]} -eq 0 ]]; then
    for vfile in /sys/class/drm/card*/device/vendor; do
        [[ -r "$vfile" ]] || continue
        case "$(cat "$vfile" 2>/dev/null)" in
            0x8086) add_vendor intel  ;;
            0x1002) add_vendor amd    ;;
            0x10de) add_vendor nvidia ;;
        esac
    done
fi

if [[ ${#GPU_LINES[@]} -gt 0 ]]; then
    for line in "${GPU_LINES[@]}"; do ok "${line#*: }"; done
elif [[ ${#GPU_VENDORS[@]} -gt 0 ]]; then
    ok "GPU vendor(s) via sysfs: ${GPU_VENDORS[*]}"
else
    warn "no GPU detected - installing the base stack only, no Vulkan driver"
    warn "check 'lspci -nn | grep -Ei \"vga|3d\"' yourself before playing anything"
fi

# What NVIDIA is actually running matters: this script will never install or
# swap a kernel driver (that is a reboot-and-pray operation), only the 32-bit
# userspace halves of a driver that is already there.
nvidia_driver_kind() {
    if lsmod 2>/dev/null | grep -q '^nvidia '   || have_pkg nvidia-utils; then echo proprietary
    elif lsmod 2>/dev/null | grep -q '^nouveau '; then echo nouveau
    else echo none
    fi
}

# ------------------------------------------------------------ 2. build plan
info "Working out what is missing"

# Steam itself, udev rules for controllers, and the Vulkan loader in both
# word sizes. vulkan-tools gives us vulkaninfo, which the verify step uses.
want steam steam-devices
want vulkan-icd-loader lib32-vulkan-icd-loader
want vulkan-tools
want ttf-liberation                      # Proton titles that ship no fonts
want lib32-alsa-plugins lib32-libpulse   # 32-bit games that open audio directly

mesa_gpu=no
for v in ${GPU_VENDORS[@]+"${GPU_VENDORS[@]}"}; do
    case "$v" in
        intel) mesa_gpu=yes; want vulkan-intel  lib32-vulkan-intel  ;;
        amd)   mesa_gpu=yes; want vulkan-radeon lib32-vulkan-radeon ;;
        nvidia)
            case "$(nvidia_driver_kind)" in
                proprietary)
                    want lib32-nvidia-utils
                    NOTES+=("lib32-nvidia-utils is version-locked to nvidia-utils, so this may pull a driver upgrade - reboot afterwards if it does")
                    ;;
                nouveau)
                    mesa_gpu=yes; want vulkan-nouveau lib32-vulkan-nouveau
                    NOTES+=("nouveau is in use; expect poor gaming performance until the proprietary driver is installed")
                    ;;
                none)
                    warn "NVIDIA card with no driver loaded - skipping it"
                    warn "install the driver yourself (nvidia / nvidia-open + nvidia-utils), reboot, then re-run"
                    ;;
            esac
            ;;
    esac
done
[[ "$mesa_gpu" == yes ]] && want mesa lib32-mesa

if [[ "$WANT_EXTRAS" == yes ]]; then
    # gamescope earns its place under Hyprland: it gives a game its own
    # micro-compositor, so fullscreen and resolution changes stop rearranging
    # your real workspace.
    want gamescope mangohud lib32-mangohud protontricks
fi

# multilib: 32-bit repo, required for every lib32-* above. The repo's own
# packages/arch/pacman.conf template already enables it, so this only fires
# on a machine that never ran scripts/configure-pacman.sh.
multilib_enabled() { pacman-conf --repo-list 2>/dev/null | grep -qx multilib; }
if multilib_enabled; then
    ok "[multilib] already enabled"
else
    NEED_MULTILIB=yes
    NEED_SYNC=yes
    warn "[multilib] is off - no lib32-* package can be installed until it is on"
fi

# A stale database plus a fresh install is how a partial upgrade happens.
db=/var/lib/pacman/sync/core.db
if [[ -f "$db" ]]; then
    age=$(( ( $(date +%s) - $(stat -c %Y "$db") ) / 86400 ))
    (( age >= STALE_DB_DAYS )) && { NEED_SYNC=yes; warn "package databases are ${age} days old"; }
else
    NEED_SYNC=yes
fi

# --------------------------------------------------------- 3. sanity checks
avail_gb=$(df -BG --output=avail "$HOME" 2>/dev/null | tail -1 | tr -dc '0-9')
if [[ -n "$avail_gb" ]] && (( avail_gb < MIN_FREE_GB )); then
    warn "only ${avail_gb}G free on \$HOME - games are big, ${MIN_FREE_GB}G+ is a sane floor"
else
    ok "${avail_gb:-?}G free for the Steam library"
fi

if command -v flatpak >/dev/null 2>&1 && flatpak list --app 2>/dev/null | grep -q com.valvesoftware.Steam; then
    warn "a Flatpak Steam is already installed; a native one will sit alongside it"
    warn "two Steam installs do not share a library - pick one and remove the other later"
fi

if have_pkg steam; then
    ok "steam is already installed"
fi

# ----------------------------------------------------------------- 4. plan
printf '\n%sPlan%s\n' "$B" "$Z"
[[ "$NEED_MULTILIB" == yes ]] \
    && printf '  multilib   enable in %s (backup: %s)\n' "$PACMAN_CONF" "$BACKUP" \
    || printf '  multilib   already on, no change\n'
[[ "$NEED_SYNC" == yes ]] \
    && printf '  sync       full "pacman -Syu" first (never a bare -Sy)\n' \
    || printf '  sync       databases are fresh, no upgrade needed\n'
if [[ ${#PKGS[@]} -eq 0 ]]; then
    printf '  install    nothing - everything needed is already here\n\n'
else
    printf '  install    %d package(s):\n' "${#PKGS[@]}"
    printf '               %s\n' "${PKGS[@]}"
    printf '\n'
fi
for n in ${NOTES[@]+"${NOTES[@]}"}; do warn "$n"; done

[[ "$DRY_RUN" == yes ]] && info "--dry-run: nothing was changed"

# --------------------------------------------------------------- 5. install
if [[ "$DRY_RUN" == no && "$CHECK_ONLY" == no ]]; then
    if [[ ${#PKGS[@]} -gt 0 || "$NEED_MULTILIB" == yes ]]; then
        confirm "Apply this plan?" || die "nothing was changed"

        # ---- 5a. multilib, with a verified rollback
        if [[ "$NEED_MULTILIB" == yes ]]; then
            info "Enabling [multilib]"
            line=$(grep -n '^[[:space:]]*#\[multilib\][[:space:]]*$' "$PACMAN_CONF" | head -1 | cut -d: -f1)
            [[ -n "$line" ]] || die "no commented [multilib] section in $PACMAN_CONF - enable it by hand, I will not append blind"
            next=$((line + 1))
            sed -n "${next}p" "$PACMAN_CONF" | grep -qE '^[[:space:]]*#[[:space:]]*Include[[:space:]]*=' \
                || die "line ${next} of $PACMAN_CONF is not the expected '#Include' - enable [multilib] by hand"

            sudo cp -a "$PACMAN_CONF" "$BACKUP" || die "could not back up $PACMAN_CONF"
            sudo sed -i "${line}s/^[[:space:]]*#//; ${next}s/^[[:space:]]*#[[:space:]]*//" "$PACMAN_CONF" \
                || { sudo cp -a "$BACKUP" "$PACMAN_CONF"; die "edit failed, restored from $BACKUP"; }

            # Trust nothing: ask pacman whether it now sees the repo, and put
            # the old file back if it does not.
            if multilib_enabled; then
                ok "enabled (backup at $BACKUP)"
            else
                sudo cp -a "$BACKUP" "$PACMAN_CONF"
                die "pacman still does not see [multilib]; restored $PACMAN_CONF from backup"
            fi
        fi

        NOCONFIRM=()
        [[ "$ASSUME_YES" == yes ]] && NOCONFIRM=(--noconfirm)

        # ---- 5b. sync. -Syu, not -Sy: refreshing the databases and then
        # installing against a not-upgraded system is the classic Arch
        # partial-upgrade breakage.
        if [[ "$NEED_SYNC" == yes ]]; then
            info "Refreshing databases and upgrading the system (pacman -Syu)"
            sudo pacman -Syu ${NOCONFIRM[@]+"${NOCONFIRM[@]}"} \
                || die "upgrade failed - no Steam packages were installed"
        fi

        # ---- 5c. one transaction, so a bad target changes nothing. The
        # drivers are in the same call as steam, which also stops pacman
        # asking you to pick a lib32 Vulkan provider.
        if [[ ${#PKGS[@]} -gt 0 ]]; then
            info "Installing ${#PKGS[@]} package(s)"
            sudo pacman -S --needed ${NOCONFIRM[@]+"${NOCONFIRM[@]}"} "${PKGS[@]}" \
                || die "install failed - run 'pacman -S ${PKGS[*]}' by hand to see why"
            ok "installed"
        fi
    else
        ok "nothing to do"
    fi
fi

# ---------------------------------------------------------------- 6. verify
[[ "$DRY_RUN" == yes ]] && exit 0

info "Verifying the graphics stack"

if command -v vulkaninfo >/dev/null 2>&1; then
    devices=$(vulkaninfo --summary 2>/dev/null | sed -n 's/.*deviceName[[:space:]]*=[[:space:]]*//p')
    if [[ -n "$devices" ]]; then
        while IFS= read -r d; do ok "Vulkan (64-bit): $d"; done <<<"$devices"
    else
        warn "vulkaninfo reports no device - Proton will not run games in this state"
        warn "check 'vulkaninfo 2>&1 | head' and that the right driver package is installed"
    fi
else
    warn "vulkaninfo not available, skipping the 64-bit check"
fi

if [[ -e /usr/lib32/libvulkan.so.1 ]]; then
    ok "Vulkan loader (32-bit): /usr/lib32/libvulkan.so.1"
else
    warn "no 32-bit Vulkan loader - install lib32-vulkan-icd-loader"
fi

# Mesa ships ONE manifest per driver (/usr/share/vulkan/icd.d/intel_icd.json)
# and its library_path is relative - just "libvulkan_intel.so". The loader
# resolves that through the linker search path, so a 32-bit process finds
# /usr/lib32 and a 64-bit one /usr/lib from the very same file. There is no
# *.i686.json to look for; the driver .so under /usr/lib32 is the evidence.
# NVIDIA is the exception - it ships an arch-suffixed manifest instead.
drv32=()
for f in /usr/lib32/libvulkan_*.so /usr/share/vulkan/icd.d/*i686*.json; do
    [[ -e "$f" ]] && drv32+=("$(basename "$f")")
done
[[ -e /usr/lib32/libGLX_nvidia.so.0 ]] && drv32+=("libGLX_nvidia.so.0 (nvidia)")
if [[ ${#drv32[@]} -gt 0 ]]; then
    for d in "${drv32[@]}"; do ok "32-bit driver: $d"; done
else
    warn "no 32-bit Vulkan driver in /usr/lib32 - most Proton titles are 32-bit and will fail to start"
fi

command -v steam >/dev/null 2>&1 && ok "steam: $(command -v steam)" || warn "steam is not on PATH"

# ------------------------------------------------------------ 7. next steps
printf '\n%sNext%s\n' "$G" "$Z"
printf '  1. Launch steam once and log in (first run downloads its own runtime).\n'
printf '  2. Settings > Compatibility > enable Steam Play for all other titles.\n'
printf '  3. Check a game at https://protondb.com before buying it.\n'
printf '\n'
printf '  Launch options worth knowing:\n'
printf '    MANGOHUD=1 %%command%%                        # fps overlay\n'
printf '    gamescope -W 1920 -H 1080 -f -- %%command%%   # fullscreen that behaves under Hyprland\n'
printf '\n'
printf '  Games with kernel-level anti-cheat (Valorant, Fortnite, Destiny 2,\n'
printf '  PUBG, Apex) do not run on Linux at all - that is the publisher, not you.\n'
if has_vendor intel && ! has_vendor nvidia && ! has_vendor amd && [[ -d /sys/class/power_supply/BAT0 ]]; then
    printf '\n  Integrated graphics on battery throttle hard - play plugged in.\n'
fi
exit 0
