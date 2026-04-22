#!/usr/bin/env bash
set -Eeuo pipefail

source "$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" 2>/dev/null && pwd -P)/system.sh"

print_line () {

    printf '%s\n' "------------------------------------------------------------"

}
print_title () {

    print_line
    printf '[TEST] %s\n' "${1:-}"
    print_line

}
print_bool () {

    local name="${1:-}"

    shift || true

    if "$@"; then
        printf '%-24s : true\n' "${name}"
    else
        printf '%-24s : false\n' "${name}"
    fi

}
print_value () {

    local name="${1:-}" value="${2:-}"

    printf '%-24s : %s\n' "${name}" "${value}"

}
print_call () {

    local name="${1:-}"

    shift || true

    local out="" rc=0

    out="$("$@" 2>/dev/null)" || rc=$?

    if [[ -n "${out}" ]]; then
        printf '%-24s : %s\n' "${name}" "${out}"
    else
        printf '%-24s : <empty> (rc=%s)\n' "${name}" "${rc}"
    fi

}
print_bool_call () {

    local name="${1:-}"

    shift || true

    if "$@" >/dev/null 2>&1; then
        printf '%-24s : true\n' "${name}"
    else
        printf '%-24s : false\n' "${name}"
    fi

}
print_open_result () {

    local name="${1:-}"

    shift || true

    if "$@" >/dev/null 2>&1; then
        printf '%-24s : ok\n' "${name}"
    else
        printf '%-24s : fail\n' "${name}"
    fi

}

test_detect () {

    print_title "detect"

    print_bool_call "sys::is_linux"       sys::is_linux
    print_bool_call "sys::is_macos"       sys::is_macos
    print_bool_call "sys::is_wsl"         sys::is_wsl
    print_bool_call "sys::is_unix"        sys::is_unix
    print_bool_call "sys::is_cygwin"      sys::is_cygwin
    print_bool_call "sys::is_msys"        sys::is_msys
    print_bool_call "sys::is_gitbash"     sys::is_gitbash
    print_bool_call "sys::is_windows"     sys::is_windows
    print_bool_call "sys::is_posix"       sys::is_posix
    print_bool_call "sys::is_gui"         sys::is_gui
    print_bool_call "sys::is_terminal"    sys::is_terminal
    print_bool_call "sys::is_interactive" sys::is_interactive
    print_bool_call "sys::is_headless"    sys::is_headless
    print_bool_call "sys::is_container"   sys::is_container
    print_bool_call "sys::is_root"        sys::is_root
    print_bool_call "sys::can_sudo"       sys::can_sudo

    printf '\n'

    print_call "sys::name"                sys::name
    print_call "sys::runtime"             sys::runtime
    print_call "sys::distro"              sys::distro
    print_call "sys::manager"             sys::manager
    print_call "sys::arch"                sys::arch

}
test_ci () {

    print_title "ci"

    print_call      "sys::ci_name"        sys::ci_name
    print_bool_call "sys::is_ci"          sys::is_ci
    print_bool_call "sys::is_ci_pull"     sys::is_ci_pull
    print_bool_call "sys::is_ci_push"     sys::is_ci_push
    print_bool_call "sys::is_ci_tag"      sys::is_ci_tag

}
test_has () {

    print_title "has"

    print_bool_call "sys::has bash"       sys::has bash
    print_bool_call "sys::has sh"         sys::has sh
    print_bool_call "sys::has uname"      sys::has uname
    print_bool_call "sys::has awk"        sys::has awk
    print_bool_call "sys::has sed"        sys::has sed
    print_bool_call "sys::has grep"       sys::has grep
    print_bool_call "sys::has df"         sys::has df
    print_bool_call "sys::has du"         sys::has du
    print_bool_call "sys::has xdg-open"   sys::has xdg-open
    print_bool_call "sys::has open"       sys::has open
    print_bool_call "sys::has powershell" sys::has powershell.exe

}
test_disk () {

    local path="${1:-.}"

    print_title "disk"

    print_value "path" "${path}"

    print_call "sys::disk_total"          sys::disk_total   "${path}"
    print_call "sys::disk_free"           sys::disk_free    "${path}"
    print_call "sys::disk_used"           sys::disk_used    "${path}"
    print_call "sys::disk_percent"        sys::disk_percent "${path}"
    print_call "sys::disk_size"           sys::disk_size    "${path}"
    print_call "sys::disk_info"           sys::disk_info    "${path}"

}
test_mem () {

    print_title "memory"

    print_call "sys::mem_total"           sys::mem_total
    print_call "sys::mem_free"            sys::mem_free
    print_call "sys::mem_used"            sys::mem_used
    print_call "sys::mem_percent"         sys::mem_percent
    print_call "sys::mem_info"            sys::mem_info

}
test_open_safe () {

    print_title "open-safe"

    print_open_result "sys::open . path"              sys::open "." path
    print_open_result "sys::open localhost"           sys::open "localhost" url
    print_open_result "sys::open example.com"         sys::open "example.com" url
    print_open_result "sys::open https://openai.com"  sys::open "https://openai.com" url

}
test_open_apps () {

    print_title "open-apps"

    print_open_result "sys::open bash app"            sys::open bash app --version
    print_open_result "sys::open sh app"              sys::open sh app -c 'exit 0'

}
test_env () {

    print_title "env"

    print_value "OSTYPE"               "${OSTYPE:-}"
    print_value "MSYSTEM"              "${MSYSTEM:-}"
    print_value "TERM_PROGRAM"         "${TERM_PROGRAM:-}"
    print_value "WSL_DISTRO_NAME"      "${WSL_DISTRO_NAME:-}"
    print_value "WSL_INTEROP"          "${WSL_INTEROP:-}"
    print_value "WINDIR"               "${WINDIR:-}"
    print_value "SystemRoot"           "${SystemRoot:-}"
    print_value "COMSPEC"              "${COMSPEC:-}"
    print_value "DISPLAY"              "${DISPLAY:-}"
    print_value "WAYLAND_DISPLAY"      "${WAYLAND_DISPLAY:-}"
    print_value "SSH_CONNECTION"       "${SSH_CONNECTION:-}"
    print_value "CI"                   "${CI:-}"
    print_value "GITHUB_ACTIONS"       "${GITHUB_ACTIONS:-}"
    print_value "GITLAB_CI"            "${GITLAB_CI:-}"
    print_value "GitInstallRoot"       "${GitInstallRoot:-}"
    print_value "MSYS2_PATH_TYPE"      "${MSYS2_PATH_TYPE:-}"

}
main () {

    local path="${1:-.}"

    print_title "system.sh integration test"

    test_env
    test_has
    test_detect
    test_ci
    test_disk "${path}"
    test_mem

    # printf '\n'
    # print_line
    # printf '[INFO] open tests may launch file manager, browser, or app.\n'
    # printf '[INFO] comment them out if you want silent runs only.\n'
    # print_line
    # printf '\n'
    # test_open_safe
    # test_open_apps

    printf '\n'
    print_line
    printf '[DONE] all tests finished\n'
    print_line

}

main "$@"
