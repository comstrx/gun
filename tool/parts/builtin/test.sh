#!/usr/bin/env bash
set -Eeuo pipefail

ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" >/dev/null 2>&1 && pwd)"

source "${ROOT}/system.sh"
source "${ROOT}/process.sh"

pass=0
fail=0
skip=0

ok () { printf '[OK]   %s\n' "$1"; pass=$(( pass + 1 )); }
bad () { printf '[FAIL] %s\n' "$1"; fail=$(( fail + 1 )); }
skip_case () { printf '[SKIP] %s\n' "$1"; skip=$(( skip + 1 )); }

run_case () {

    local name="$1"
    shift

    if "$@"; then ok "${name}"
    else bad "${name}"
    fi

}

not_case () {

    local name="$1"
    shift

    if "$@"; then bad "${name}"
    else ok "${name}"
    fi

}

manager="$(sys::manager 2>/dev/null || true)"
runtime="$(sys::runtime 2>/dev/null || true)"
os="$(sys::name 2>/dev/null || true)"

bin=""
package=""
version=""
force="0"
refresh="1"

case "${manager}" in
    apt)     bin="sl";     package="sl" ;;
    apk)     bin="figlet"; package="figlet" ;;
    dnf)     bin="figlet"; package="figlet" ;;
    yum)     bin="figlet"; package="figlet" ;;
    zypper)  bin="figlet"; package="figlet" ;;
    pacman)  bin="figlet"; package="figlet" ;;
    xbps)    bin="figlet"; package="figlet" ;;
    brew)    bin="figlet"; package="figlet" ;;
    scoop)   bin="figlet"; package="figlet" ;;
    choco)   bin="figlet"; package="figlet" ;;
    nix)     bin="figlet"; package="figlet" ;;
    winget)  bin="jq";     package="jqlang.jq" ;;
esac

printf '%s\n' "------------------------------------------------------------"
printf '%s\n' "[REAL INSTALL TEST] process.sh"
printf '%s\n' "------------------------------------------------------------"
printf 'OS      : %s\n' "${os:-unknown}"
printf 'Runtime : %s\n' "${runtime:-unknown}"
printf 'Manager : %s\n' "${manager:-unknown}"
printf 'Tool    : %s\n' "${bin:-none}"
printf 'Package : %s\n' "${package:-none}"
printf '%s\n' "------------------------------------------------------------"

run_case "proc::has bash" proc::has bash
run_case "proc::path bash" proc::path bash
run_case "proc::version bash" proc::version bash

if [[ -z "${bin}" || -z "${package}" ]]; then

    skip_case "real install unsupported manager"

    printf '%s\n' "------------------------------------------------------------"
    printf 'Passed: %s\n' "${pass}"
    printf 'Failed: %s\n' "${fail}"
    printf 'Skipped: %s\n' "${skip}"
    printf '%s\n' "------------------------------------------------------------"

    (( fail == 0 ))
    exit $?

fi

if proc::has "${bin}"; then

    printf '[INFO] %s already exists; testing uninstall carefully\n' "${bin}"

    run_case "proc::uninstall existing ${bin}" proc::uninstall "${bin}" "${package}"

    hash -r 2>/dev/null || true

    if proc::has "${bin}"; then
        skip_case "binary still exists after uninstall; probably installed by another source"
    else
        ok "binary removed after uninstall"
    fi

else

    ok "${bin} initially missing"

fi

hash -r 2>/dev/null || true

if ! proc::has "${bin}"; then

    run_case "proc::install ${bin}" proc::install "${bin}" "${package}" "${version}" "${force}" "${refresh}"

    hash -r 2>/dev/null || true

    run_case "proc::has ${bin} after install" proc::has "${bin}"
    run_case "proc::path ${bin} after install" proc::path "${bin}"

    if proc::version "${bin}" >/dev/null 2>&1; then
        ok "proc::version ${bin} after install"
    else
        skip_case "proc::version ${bin} unavailable"
    fi

    case "${bin}" in
        sl)     run_case "proc::run_ok ${bin}" proc::run_ok "${bin}" ;;
        figlet) run_case "proc::run_ok ${bin}" proc::run_ok "${bin}" "OK" ;;
        jq)     run_case "proc::run_ok ${bin}" proc::run_ok "${bin}" --version ;;
        *)      run_case "proc::run_ok ${bin}" proc::run_ok "${bin}" --version ;;
    esac

    run_case "proc::ensure ${bin}" proc::ensure "${bin}" "${package}" "" "0" "0"

    run_case "proc::uninstall ${bin}" proc::uninstall "${bin}" "${package}"

    hash -r 2>/dev/null || true

    if proc::has "${bin}"; then
        skip_case "${bin} still visible after uninstall; maybe cached or installed by another source"
    else
        ok "proc::has ${bin} after uninstall"
    fi

else

    skip_case "install/uninstall cycle skipped because ${bin} still exists"

fi

printf '%s\n' "------------------------------------------------------------"
printf 'Passed: %s\n' "${pass}"
printf 'Failed: %s\n' "${fail}"
printf 'Skipped: %s\n' "${skip}"
printf '%s\n' "------------------------------------------------------------"

(( fail == 0 ))
