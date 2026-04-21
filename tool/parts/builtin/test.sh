#!/usr/bin/env bash
set -Eeuo pipefail

BUILTIN_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" 2>/dev/null && pwd -P)"

source "${BUILTIN_DIR}/stdout.sh"
source "${BUILTIN_DIR}/process.sh"
source "${BUILTIN_DIR}/platform.sh"

__test_total=0
__test_pass=0

pass () {

    local name="${1:-}"

    (( ++__test_total ))
    (( ++__test_pass ))
    success "PASS: ${name}"

}
fail () {

    local name="${1:-}" msg="${2-}"

    (( ++__test_total ))
    error "FAIL: ${name}"
    [[ -n "${msg}" ]] && eprint "  ${msg}"
    return 1

}
expect_eq () {

    local name="${1:-}" got="${2-}" want="${3-}"

    (( ++__test_total ))

    if [[ "${got}" == "${want}" ]]; then
        (( ++__test_pass ))
        success "PASS: ${name}"
        return 0
    fi

    error "FAIL: ${name}"
    eprint "  got : [${got}]"
    eprint "  want: [${want}]"
    return 1

}
expect_in () {

    local name="${1:-}" got="${2-}"
    shift 2 || true

    local x=""

    (( ++__test_total ))

    for x in "$@"; do
        if [[ "${got}" == "${x}" ]]; then
            (( ++__test_pass ))
            success "PASS: ${name}"
            return 0
        fi
    done

    error "FAIL: ${name}"
    eprint "  got : [${got}]"
    eprint "  expected one of: [$*]"
    return 1

}
expect_ok () {

    local name="${1:-}"
    shift || true

    (( ++__test_total ))

    if "$@"; then
        (( ++__test_pass ))
        success "PASS: ${name}"
        return 0
    fi

    error "FAIL: ${name}"
    return 1

}
expect_fail () {

    local name="${1:-}"
    shift || true

    (( ++__test_total ))

    if "$@"; then
        error "FAIL: ${name}"
        return 1
    fi

    (( ++__test_pass ))
    success "PASS: ${name}"
    return 0

}
expect_true () {

    local name="${1:-}"
    shift || true

    (( ++__test_total ))

    if eval "$*"; then
        (( ++__test_pass ))
        success "PASS: ${name}"
        return 0
    fi

    error "FAIL: ${name}"
    eprint "  expr: $*"
    return 1

}
expect_false () {

    local name="${1:-}"
    shift || true

    (( ++__test_total ))

    if eval "$*"; then
        error "FAIL: ${name}"
        eprint "  expr unexpectedly true: $*"
        return 1
    fi

    (( ++__test_pass ))
    success "PASS: ${name}"
    return 0

}

snapshot_platform () {

    local v=""

    is_linux       && v=true || v=false; eprint "  is_linux      : ${v}"
    is_macos       && v=true || v=false; eprint "  is_macos      : ${v}"
    is_windows     && v=true || v=false; eprint "  is_windows    : ${v}"
    is_wsl         && v=true || v=false; eprint "  is_wsl        : ${v}"
    is_msys        && v=true || v=false; eprint "  is_msys       : ${v}"
    is_gitbash     && v=true || v=false; eprint "  is_gitbash    : ${v}"
    is_cygwin      && v=true || v=false; eprint "  is_cygwin     : ${v}"
    is_unix        && v=true || v=false; eprint "  is_unix       : ${v}"
    is_posix       && v=true || v=false; eprint "  is_posix      : ${v}"
    is_ci          && v=true || v=false; eprint "  is_ci         : ${v}"
    is_ci_pull     && v=true || v=false; eprint "  is_ci_pull    : ${v}"
    is_ci_push     && v=true || v=false; eprint "  is_ci_push    : ${v}"
    is_ci_tag      && v=true || v=false; eprint "  is_ci_tag     : ${v}"
    is_terminal    && v=true || v=false; eprint "  is_terminal   : ${v}"
    is_interactive && v=true || v=false; eprint "  is_interactive: ${v}"
    is_gui         && v=true || v=false; eprint "  is_gui        : ${v}"
    is_headless    && v=true || v=false; eprint "  is_headless   : ${v}"
    is_container   && v=true || v=false; eprint "  is_container  : ${v}"

    eprint "  os_name       : $(os_name || true)"
    eprint "  os_family     : $(os_family || true)"
    eprint "  os_runtime    : $(os_runtime || true)"
    eprint "  os_distro     : $(os_distro || true)"
    eprint "  os_manager    : $(os_manager || true)"
    eprint "  os_arch       : $(os_arch || true)"
    eprint "  ci_name       : $(ci_name || true)"

}

test_runtime_values () {

    local name="" family="" runtime="" distro="" manager="" arch="" ci=""

    name="$(os_name || true)"
    family="$(os_family || true)"
    runtime="$(os_runtime || true)"
    distro="$(os_distro || true)"
    manager="$(os_manager || true)"
    arch="$(os_arch || true)"
    ci="$(ci_name || true)"

    expect_in "os_name valid"    "${name}"    linux macos windows unknown
    expect_in "os_family valid"  "${family}"  unix windows unknown
    expect_in "os_runtime valid" "${runtime}" linux macos windows wsl gitbash msys2 cygwin unknown
    expect_true "os_distro non-empty" '[[ -n "${distro}" ]]'
    expect_in "os_manager valid" "${manager:-unknown}" apt apk dnf yum pacman zypper xbps nix brew port winget choco scoop unknown
    expect_true "os_arch non-empty" '[[ -n "${arch}" ]]'
    expect_in "ci_name valid" "${ci}" github gitlab jenkins buildkite circleci travis appveyor azure bitbucket teamcity drone semaphore codebuild generic none

}
test_primary_os_contract () {

    local n=0

    is_linux   && (( ++n ))
    is_macos   && (( ++n ))
    is_windows && (( ++n ))

    (( n <= 1 )) || die "multiple primary os detectors returned true"

    pass "single primary os detector"

    if is_linux && ! is_wsl; then
        expect_eq "linux os_name"   "$(os_name)"   "linux"
        expect_eq "linux os_family" "$(os_family)" "unix"
    fi

    if is_wsl; then
        expect_ok   "wsl implies linux" is_linux
        expect_fail "wsl not windows"   is_windows
        expect_eq   "wsl os_name"       "$(os_name)"    "linux"
        expect_eq   "wsl os_family"     "$(os_family)"  "unix"
        expect_eq   "wsl runtime"       "$(os_runtime)" "wsl"
    fi

    if is_macos; then
        expect_eq "macos os_name"    "$(os_name)"    "macos"
        expect_eq "macos os_family"  "$(os_family)"  "unix"
        expect_eq "macos runtime"    "$(os_runtime)" "macos"
    fi

    if is_windows && ! is_msys && ! is_gitbash && ! is_cygwin && ! is_wsl; then
        expect_eq "windows os_name"   "$(os_name)"    "windows"
        expect_eq "windows family"    "$(os_family)"  "windows"
        expect_eq "windows runtime"   "$(os_runtime)" "windows"
    fi

}
test_runtime_contract () {

    local n=0

    is_wsl     && (( ++n ))
    is_gitbash && (( ++n ))
    is_msys    && (( ++n ))
    is_cygwin  && (( ++n ))

    if is_gitbash; then
        (( n <= 2 )) || die "gitbash runtime conflict"
        expect_ok "gitbash implies msys" is_msys
        expect_ok "gitbash implies windows" is_windows
        expect_eq "gitbash runtime value" "$(os_runtime)" "gitbash"
    else
        (( n <= 1 )) || die "multiple runtime detectors returned true"
    fi

    if is_msys && ! is_gitbash; then
        expect_ok "msys implies windows" is_windows
        expect_eq "msys runtime value" "$(os_runtime)" "msys2"
    fi

    if is_cygwin; then
        expect_ok "cygwin implies windows" is_windows
        expect_eq "cygwin runtime value" "$(os_runtime)" "cygwin"
    fi

    pass "runtime detector consistency"

}
test_posix_unix_contract () {

    if is_linux || is_macos; then
        expect_ok "unix relation" is_unix
    fi

    if is_windows; then
        expect_fail "windows not unix" is_unix
    fi

    if is_linux || is_macos || is_wsl || is_msys || is_cygwin; then
        expect_ok "posix relation" is_posix
    fi

}
test_ci_contract () {

    local name=""
    name="$(ci_name || true)"

    if is_ci; then
        expect_false "ci => ci_name not none" '[[ "$(ci_name)" == "none" ]]'
    else
        expect_in "not ci => ci_name okay" "${name}" none generic
    fi

    if is_ci_pull; then
        expect_ok   "ci_pull implies ci" is_ci
        expect_fail "ci_pull excludes ci_push" is_ci_push
    fi

    if is_ci_push; then
        expect_ok   "ci_push implies ci" is_ci
        expect_fail "ci_push excludes ci_pull" is_ci_pull
    fi

}
test_gui_headless_contract () {

    if is_gui; then
        expect_fail "gui excludes headless" is_headless
    fi

    if is_headless; then
        expect_fail "headless excludes gui" is_gui
    fi

    if is_linux && [[ -n "${DISPLAY:-}" || -n "${WAYLAND_DISPLAY:-}" ]]; then
        expect_ok "linux display => gui" is_gui
    fi

    if is_linux && [[ -z "${DISPLAY:-}" && -z "${WAYLAND_DISPLAY:-}" ]]; then
        expect_ok "linux no display => headless" is_headless
    fi

}
test_manager_contract () {

    local manager=""
    manager="$(os_manager || true)"

    if is_linux; then
        expect_in "linux manager family" "${manager:-unknown}" apt apk dnf yum pacman zypper xbps nix unknown
    fi

    if is_macos; then
        expect_in "macos manager family" "${manager:-unknown}" brew port unknown
    fi

    if is_windows; then
        expect_in "windows manager family" "${manager:-unknown}" pacman winget choco scoop unknown
    fi

}
test_arch_contract () {

    local arch=""
    arch="$(os_arch || true)"

    expect_in "arch normalized" "${arch}" x64 x86 arm64 armv7 armv6 arm ppc64le ppc64 s390x riscv64 unknown "${arch}"

}
test_mock_ci_matrix () {

    (
        unset GITLAB_CI JENKINS_URL BUILDKITE CIRCLECI TRAVIS APPVEYOR TF_BUILD
        unset BITBUCKET_BUILD_NUMBER TEAMCITY_VERSION DRONE SEMAPHORE CODEBUILD_BUILD_ID
        export GITHUB_ACTIONS=true
        export GITHUB_EVENT_NAME=pull_request
        export CI=true

        expect_ok "mock github ci" is_ci
        expect_eq "mock github ci_name" "$(ci_name)" "github"
        expect_ok "mock github pull" is_ci_pull
        expect_fail "mock github not push" is_ci_push
    )

    (
        unset GITHUB_ACTIONS JENKINS_URL BUILDKITE CIRCLECI TRAVIS APPVEYOR TF_BUILD
        unset BITBUCKET_BUILD_NUMBER TEAMCITY_VERSION DRONE SEMAPHORE CODEBUILD_BUILD_ID
        export GITLAB_CI=true
        export CI=true
        export CI_PIPELINE_SOURCE=push
        unset CI_MERGE_REQUEST_IID

        expect_ok "mock gitlab ci" is_ci
        expect_eq "mock gitlab ci_name" "$(ci_name)" "gitlab"
        expect_ok "mock gitlab push" is_ci_push
        expect_fail "mock gitlab not pull" is_ci_pull
    )

    (
        unset GITHUB_ACTIONS GITLAB_CI JENKINS_URL BUILDKITE CIRCLECI TRAVIS APPVEYOR TF_BUILD
        unset BITBUCKET_BUILD_NUMBER TEAMCITY_VERSION DRONE SEMAPHORE CODEBUILD_BUILD_ID
        export CI=true
        export GITHUB_REF_TYPE=tag

        expect_ok "mock ci tag" is_ci_tag
    )

}
test_mock_runtime_matrix () {

    (
        uname () { printf '%s\n' "Linux"; }
        export -f uname
        export OSTYPE=linux-gnu
        unset WSL_DISTRO_NAME WSL_INTEROP WINDIR SystemRoot MSYSTEM GitInstallRoot TERM_PROGRAM MINGW_PREFIX MSYS2_PATH_TYPE
        expect_ok "mock linux" is_linux
        expect_fail "mock linux not macos" is_macos
    )

    (
        uname () { printf '%s\n' "Darwin"; }
        export -f uname
        export OSTYPE=darwin23
        unset WSL_DISTRO_NAME WSL_INTEROP WINDIR SystemRoot MSYSTEM GitInstallRoot TERM_PROGRAM MINGW_PREFIX MSYS2_PATH_TYPE
        expect_ok "mock macos" is_macos
        expect_fail "mock macos not linux" is_linux
    )

    (
        uname () { printf '%s\n' "MINGW64_NT"; }
        export -f uname

        export OSTYPE=msys
        export MSYSTEM=MINGW64
        export GitInstallRoot='C:\Program Files\Git'

        unset WSL_DISTRO_NAME WSL_INTEROP WINDIR SystemRoot TERM_PROGRAM MINGW_PREFIX MSYS2_PATH_TYPE

        expect_ok "mock gitbash => msys" is_msys
        expect_ok "mock gitbash" is_gitbash
        expect_ok "mock gitbash => windows" is_windows
    )

    (
        uname () { printf '%s\n' "MSYS_NT"; }
        export -f uname

        export OSTYPE=msys
        export MSYSTEM=MSYS
        unset GitInstallRoot
        export TERM_PROGRAM=
        export MSYS2_PATH_TYPE=inherit

        unset WSL_DISTRO_NAME WSL_INTEROP WINDIR SystemRoot

        expect_ok "mock msys" is_msys
        expect_fail "mock msys not gitbash" is_gitbash
        expect_ok "mock msys => windows" is_windows
    )

    (
        uname () { printf '%s\n' "CYGWIN_NT"; }
        export -f uname

        export OSTYPE=cygwin
        unset WSL_DISTRO_NAME WSL_INTEROP MSYSTEM GitInstallRoot WINDIR SystemRoot

        expect_ok "mock cygwin" is_cygwin
        expect_ok "mock cygwin => windows" is_windows
    )

}
test_mock_arch_matrix () {

    (
        uname () { printf '%s\n' "x86_64"; }
        export -f uname
        expect_eq "mock arch x86_64" "$(os_arch)" "x64"
    )

    (
        uname () { printf '%s\n' "amd64"; }
        export -f uname
        expect_eq "mock arch amd64" "$(os_arch)" "x64"
    )

    (
        uname () { printf '%s\n' "aarch64"; }
        export -f uname
        expect_eq "mock arch aarch64" "$(os_arch)" "arm64"
    )

    (
        uname () { printf '%s\n' "armv7l"; }
        export -f uname
        expect_eq "mock arch armv7l" "$(os_arch)" "armv7"
    )

    (
        uname () { printf '%s\n' "riscv64"; }
        export -f uname
        expect_eq "mock arch riscv64" "$(os_arch)" "riscv64"
    )

}
test_stress_loop () {

    local i=0

    for (( i=0; i<20; i++ )); do
        is_linux       >/dev/null 2>&1 || true
        is_macos       >/dev/null 2>&1 || true
        is_windows     >/dev/null 2>&1 || true
        is_wsl         >/dev/null 2>&1 || true
        is_msys        >/dev/null 2>&1 || true
        is_gitbash     >/dev/null 2>&1 || true
        is_cygwin      >/dev/null 2>&1 || true
        is_unix        >/dev/null 2>&1 || true
        is_posix       >/dev/null 2>&1 || true
        is_ci          >/dev/null 2>&1 || true
        is_ci_pull     >/dev/null 2>&1 || true
        is_ci_push     >/dev/null 2>&1 || true
        is_ci_tag      >/dev/null 2>&1 || true
        is_gui         >/dev/null 2>&1 || true
        is_headless    >/dev/null 2>&1 || true
        is_terminal    >/dev/null 2>&1 || true
        is_interactive >/dev/null 2>&1 || true
        is_container   >/dev/null 2>&1 || true
        os_name        >/dev/null 2>&1 || true
        os_family      >/dev/null 2>&1 || true
        os_runtime     >/dev/null 2>&1 || true
        os_distro      >/dev/null 2>&1 || true
        os_manager     >/dev/null 2>&1 || true
        os_arch        >/dev/null 2>&1 || true
        ci_name        >/dev/null 2>&1 || true
    done

    pass "stress loop"

}

main () {

    eprint "platform snapshot:"
    snapshot_platform

    test_runtime_values
    test_primary_os_contract
    test_runtime_contract
    test_posix_unix_contract
    test_ci_contract
    test_gui_headless_contract
    test_manager_contract
    test_arch_contract
    test_mock_ci_matrix
    test_mock_runtime_matrix
    test_mock_arch_matrix
    test_stress_loop

    print ""
    success "platform brutal tests passed: ${__test_pass}/${__test_total}"

}

main "$@"
