#!/usr/bin/env bash
set -Eeuo pipefail

BUILTIN_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" 2>/dev/null && pwd -P)"

source "${BUILTIN_DIR}/stdout.sh"
source "${BUILTIN_DIR}/process.sh"
source "${BUILTIN_DIR}/system.sh"

show_bool () {

    local name="${1:-}"
    shift || true

    if "$@"; then
        printf '%-24s %s\n' "${name}" "true"
    else
        printf '%-24s %s\n' "${name}" "false"
    fi

}
show_value () {

    local name="${1:-}" value="${2-}"
    printf '%-24s %s\n' "${name}" "${value}"

}
show_call () {

    local name="${1:-}"
    shift || true

    local value=""
    value="$("$@" 2>/dev/null || true)"
    printf '%-24s %s\n' "${name}" "${value}"

}

main () {

    printf '== system flags ==\n'
    show_bool "sys::is_linux"       sys::is_linux
    show_bool "sys::is_macos"       sys::is_macos
    show_bool "sys::is_windows"     sys::is_windows
    show_bool "sys::is_wsl"         sys::is_wsl
    show_bool "sys::is_msys"        sys::is_msys
    show_bool "sys::is_gitbash"     sys::is_gitbash
    show_bool "sys::is_cygwin"      sys::is_cygwin
    show_bool "sys::is_unix"        sys::is_unix
    show_bool "sys::is_posix"       sys::is_posix
    show_bool "sys::is_ci"          sys::is_ci
    show_bool "sys::is_ci_pull"     sys::is_ci_pull
    show_bool "sys::is_ci_push"     sys::is_ci_push
    show_bool "sys::is_ci_tag"      sys::is_ci_tag
    show_bool "sys::is_gui"         sys::is_gui
    show_bool "sys::is_terminal"    sys::is_terminal
    show_bool "sys::is_interactive" sys::is_interactive
    show_bool "sys::is_headless"    sys::is_headless
    show_bool "sys::is_container"   sys::is_container

    printf '\n== system values ==\n'
    show_call "sys::name"    sys::name
    show_call "sys::family"  sys::family
    show_call "sys::runtime" sys::runtime
    show_call "sys::distro"  sys::distro
    show_call "sys::manager" sys::manager
    show_call "sys::arch"    sys::arch
    show_call "sys::ci_name" sys::ci_name

    printf '\n== disk ==\n'
    show_call "sys::disk_total ."   sys::disk_total .
    show_call "sys::disk_free ."    sys::disk_free .
    show_call "sys::disk_used ."    sys::disk_used .
    show_call "sys::disk_percent ." sys::disk_percent .
    show_call "sys::disk_size ."    sys::disk_size .
    show_call "sys::disk_info ."    sys::disk_info .

    printf '\n== memory ==\n'
    show_call "sys::mem_total"   sys::mem_total
    show_call "sys::mem_free"    sys::mem_free
    show_call "sys::mem_used"    sys::mem_used
    show_call "sys::mem_percent" sys::mem_percent
    show_call "sys::mem_info"    sys::mem_info

}

main "$@"
