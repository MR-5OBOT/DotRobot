#!/usr/bin/env bash
set -euo pipefail

source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/lib.sh"

# On Wayland, GTK3/GTK4 read theme settings from xdg-desktop-portal, which
# serves the org.gnome.desktop.interface dconf keys. Those override
# ~/.config/gtk-3.0/settings.ini entirely: with dconf unset the portal answers
# with the schema default (Adwaita) and settings.ini is never consulted.
# GTK_THEME and XCURSOR_THEME in hypr/lua_configs/env.lua force the theme and
# cursor past that, but no such variable exists for the icon theme -- so the
# icon theme only applies once these keys are in dconf. Seed them from
# settings.ini so a fresh install matches without running nwg-look by hand.
SETTINGS_INI="${DOTFILES_DIR}/.config/gtk-3.0/settings.ini"
SCHEMA="org.gnome.desktop.interface"

gsettings_cmd=(gsettings)

ini_value() {
  local key="$1"

  sed -nE "s/^[[:space:]]*${key}[[:space:]]*=[[:space:]]*(.*[^[:space:]])[[:space:]]*$/\1/p" \
    "${SETTINGS_INI}" | tail -1
}

set_key() {
  local key="$1"
  local value="$2"

  [[ -n "${value}" ]] || { warn "No value for ${key} in settings.ini, leaving it"; return 0; }

  local current
  current="$("${gsettings_cmd[@]}" get "${SCHEMA}" "${key}")"
  if [[ "${current}" == "'${value}'" || "${current}" == "${value}" ]]; then
    log "${key} already ${value}"
    return 0
  fi

  "${gsettings_cmd[@]}" set "${SCHEMA}" "${key}" "${value}"
  log "Set ${key} = ${value}"
}

check_installed() {
  local kind="$1"
  local name="$2"
  local dir

  for dir in "${HOME}/.${kind}" "${XDG_DATA_HOME:-${HOME}/.local/share}/${kind}" "/usr/share/${kind}"; do
    [[ -d "${dir}/${name}" ]] && return 0
  done

  warn "${name} is not in ~/.${kind}, ~/.local/share/${kind} or /usr/share/${kind}; run scripts/install-themes.sh"
}

main() {
  [[ -f "${SETTINGS_INI}" ]] || die "Missing ${SETTINGS_INI}"
  command -v gsettings >/dev/null 2>&1 || die "gsettings is not installed (glib2)."

  # A fresh install runs from a bare TTY with no session bus; dconf needs one.
  if [[ -z "${DBUS_SESSION_BUS_ADDRESS:-}" ]]; then
    command -v dbus-run-session >/dev/null 2>&1 || die "No session bus and dbus-run-session is missing."
    log "No session bus, writing dconf through dbus-run-session"
    gsettings_cmd=(dbus-run-session -- gsettings)
  fi

  # gsettings-desktop-schemas arrives with xdg-desktop-portal-gtk; without it
  # every get/set below would fail with a bare "No such schema".
  local schemas
  schemas="$("${gsettings_cmd[@]}" list-schemas 2>/dev/null || true)"
  grep -qx "${SCHEMA}" <<<"${schemas}" || die "${SCHEMA} is missing; install gsettings-desktop-schemas."

  local gtk_theme icon_theme cursor_theme cursor_size font_name prefer_dark
  gtk_theme="$(ini_value gtk-theme-name)"
  icon_theme="$(ini_value gtk-icon-theme-name)"
  cursor_theme="$(ini_value gtk-cursor-theme-name)"
  cursor_size="$(ini_value gtk-cursor-theme-size)"
  font_name="$(ini_value gtk-font-name)"
  prefer_dark="$(ini_value gtk-application-prefer-dark-theme)"

  check_installed themes "${gtk_theme}"
  check_installed icons "${icon_theme}"
  check_installed icons "${cursor_theme}"

  set_key gtk-theme "${gtk_theme}"
  set_key icon-theme "${icon_theme}"
  set_key cursor-theme "${cursor_theme}"
  set_key font-name "${font_name}"
  set_key cursor-size "${cursor_size}"

  if [[ "${prefer_dark}" == "1" ]]; then
    set_key color-scheme prefer-dark
  else
    set_key color-scheme default
  fi

  log "GTK theme settings seeded into dconf"
}

main "$@"
