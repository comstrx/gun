#!/usr/bin/env bash
set -u

source "$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" 2>/dev/null && pwd -P)/system.sh"

print_value () {

    local name="${1:-}" out="" rc=0
    shift || true

    if ! declare -F "${name}" >/dev/null 2>&1; then
        printf '%s = <missing>\n' "${name}"
        return 0
    fi

    out="$("${name}" "$@" 2>/dev/null)"
    rc=$?

    if [[ "${rc}" == "0" ]]; then
        if [[ -n "${out}" ]]; then
            printf '%s = %s\n' "${name}" "${out}"
        else
            printf '%s = true\n' "${name}"
        fi
    else
        if [[ -n "${out}" ]]; then
            printf '%s = %s\n' "${name}" "${out}"
        else
            printf '%s = false\n' "${name}"
        fi
    fi

}

current_user="$(sys::uname 2>/dev/null || true)"
current_group="$(sys::ugroup 2>/dev/null || true)"

[[ -n "${current_group}" ]] || current_group="$(sys::gname 2>/dev/null || true)"
[[ -n "${current_user}"  ]] || current_user="${USER:-}"
[[ -n "${current_group}" ]] || current_group="${GROUP:-}"

print_value sys::is_linux
print_value sys::is_macos
print_value sys::is_wsl
print_value sys::is_cygwin
print_value sys::is_msys
print_value sys::is_gitbash
print_value sys::is_unix
print_value sys::is_posix
print_value sys::is_windows
print_value sys::ci_name
print_value sys::is_ci
print_value sys::is_ci_pull
print_value sys::is_ci_push
print_value sys::is_ci_tag
print_value sys::is_gui
print_value sys::is_terminal
print_value sys::is_interactive
print_value sys::is_headless
print_value sys::is_container
print_value sys::name
print_value sys::family
print_value sys::runtime
print_value sys::distro
print_value sys::manager
print_value sys::arch
print_value sys::disk_total .
print_value sys::disk_free .
print_value sys::disk_used .
print_value sys::disk_percent .
print_value sys::disk_size .
print_value sys::disk_info .
print_value sys::mem_total
print_value sys::mem_free
print_value sys::mem_used
print_value sys::mem_percent
print_value sys::mem_info
print_value sys::gid
print_value sys::gname
print_value sys::gexists "${current_group}"
print_value sys::uid
print_value sys::uname
print_value sys::uhome
print_value sys::ushell
print_value sys::uexists "${current_user}"
print_value sys::ugroup
print_value sys::ugroups "${current_user}"
print_value sys::users   "${current_group}"
print_value sys::users
print_value sys::groups
print_value sys::ingroup  "${current_group}" "${current_user}"
print_value sys::is_root
print_value sys::is_admin

sys::addgroup "gun_test_group_01"
sys::adduser "gun_test_user_01"
sys::adduser "gun_test_user_02" "gun_test_group_01"

print_value sys::uexists "gun_test_user_01"
print_value sys::uexists "gun_test_user_02"
print_value sys::gexists "gun_test_group_01"
print_value sys::ingroup "gun_test_group_01" "gun_test_user_02"
print_value sys::ingroup "gun_test_group_01" "gun_test_user_01"

sudo userdel -r "gun_test_user_04" 2>/dev/null || true
sudo groupdel "gun_test_group_04" 2>/dev/null || true

print_value sys::uexists "gun_test_user_01"
print_value sys::uexists "gun_test_user_02"
print_value sys::gexists "gun_test_group_01"
print_value sys::ingroup "gun_test_group_01" "gun_test_user_02"
print_value sys::ingroup "gun_test_group_01" "gun_test_user_01"
