#!/usr/bin/env bash
set -Eeuo pipefail

SYS_FILE="${1:-./system.sh}"
SYS_TEST_DESTRUCTIVE="${SYS_TEST_DESTRUCTIVE:-0}"
SYS_TEST_SKIP_CODE=200

[[ -f "${SYS_FILE}" ]] || {
    printf '[ERR]: system file not found: %s\n' "${SYS_FILE}" >&2
    exit 1
}

# shellcheck disable=SC1090
source "${SYS_FILE}"

TEST_ROOT="$(mktemp -d "${TMPDIR:-/tmp}/system-test.XXXXXX")"
PASS_COUNT=0
FAIL_COUNT=0
SKIP_COUNT=0
TOTAL_COUNT=0

cleanup () {

    [[ -n "${TEST_ROOT:-}" && -d "${TEST_ROOT}" ]] && rm -rf "${TEST_ROOT}" 2>/dev/null || true

}
trap cleanup EXIT

fail_now () {

    printf '%s\n' "${1:-assertion failed}" >&2
    return 1

}
skip_test () {

    printf '%s\n' "${1:-skipped}" >&2
    return "${SYS_TEST_SKIP_CODE}"

}

assert_true () {

    local msg="${1:-expected command to succeed}"
    shift || true

    "$@" >/dev/null 2>&1 || fail_now "${msg}"

}
assert_false () {

    local msg="${1:-expected command to fail}"
    shift || true

    if "$@" >/dev/null 2>&1; then
        fail_now "${msg}"
        return 1
    fi

    return 0

}
assert_eq () {

    local expected="${1:-}" actual="${2:-}" msg="${3:-}"

    [[ "${actual}" == "${expected}" ]] && return 0

    [[ -n "${msg}" ]] || msg="expected [${expected}] but got [${actual}]"
    fail_now "${msg}"

}
assert_non_empty () {

    local value="${1:-}" msg="${2:-value must not be empty}"

    [[ -n "${value}" ]] || fail_now "${msg}"

}
assert_regex () {

    local value="${1:-}" regex="${2:-}" msg="${3:-}"

    [[ "${value}" =~ ${regex} ]] && return 0

    [[ -n "${msg}" ]] || msg="value [${value}] does not match regex [${regex}]"
    fail_now "${msg}"

}
assert_num_ge () {

    local left="${1:-}" right="${2:-}" msg="${3:-}"

    [[ "${left}" =~ ^[0-9]+$ ]] || fail_now "left value is not numeric: ${left}"
    [[ "${right}" =~ ^[0-9]+$ ]] || fail_now "right value is not numeric: ${right}"
    (( left >= right )) && return 0

    [[ -n "${msg}" ]] || msg="expected ${left} >= ${right}"
    fail_now "${msg}"

}
assert_num_le () {

    local left="${1:-}" right="${2:-}" msg="${3:-}"

    [[ "${left}" =~ ^[0-9]+$ ]] || fail_now "left value is not numeric: ${left}"
    [[ "${right}" =~ ^[0-9]+$ ]] || fail_now "right value is not numeric: ${right}"
    (( left <= right )) && return 0

    [[ -n "${msg}" ]] || msg="expected ${left} <= ${right}"
    fail_now "${msg}"

}
assert_one_of () {

    local actual="${1:-}"
    shift || true

    local x=""

    for x in "$@"; do
        [[ "${actual}" == "${x}" ]] && return 0
    done

    fail_now "value [${actual}] is not in allowed set [$*]"

}

new_test_dir () {

    mktemp -d "${TEST_ROOT}/case.XXXXXX"

}
setup_mock_path () {

    local dir=""

    dir="$(mktemp -d "${TEST_ROOT}/mock.XXXXXX")" || return 1
    export MOCK_BIN="${dir}"
    export MOCK_LOG="${dir}/calls.log"
    : > "${MOCK_LOG}"
    export PATH="${MOCK_BIN}:${PATH}"

}
make_mock () {

    local dir="${1:-}" name="${2:-}"
    shift 2 || true

    [[ -n "${dir}" && -n "${name}" ]] || return 1

    cat > "${dir}/${name}" || return 1
    chmod +x "${dir}/${name}" || return 1

}
wait_for_non_empty () {

    local path="${1:-}" tries="${2:-100}" delay="${3:-0.02}" i=0

    while (( i < tries )); do
        [[ -s "${path}" ]] && return 0
        sleep "${delay}" 2>/dev/null || true
        i=$(( i + 1 ))
    done

    return 1

}
get_info_value () {

    local key="${1:-}" input="${2:-}" line=""

    while IFS= read -r line || [[ -n "${line}" ]]; do
        [[ "${line}" == "${key}="* ]] || continue
        printf '%s\n' "${line#*=}"
        return 0
    done <<< "${input}"

    return 1

}
collect_tests () {

    declare -F | awk '{print $3}' | grep '^test_' | sort

}
run_test () {

    local fn="${1:-}" output="" rc=0

    TOTAL_COUNT=$(( TOTAL_COUNT + 1 ))

    set +e
    output="$(${fn} 2>&1)"
    rc=$?
    set -e

    case "${rc}" in
        0)
            PASS_COUNT=$(( PASS_COUNT + 1 ))
            printf '[PASS]: %s\n' "${fn}"
        ;;
        "${SYS_TEST_SKIP_CODE}")
            SKIP_COUNT=$(( SKIP_COUNT + 1 ))
            printf '[SKIP]: %s' "${fn}"
            [[ -n "${output}" ]] && printf ' - %s' "${output%%$'\n'*}"
            printf '\n'
        ;;
        *)
            FAIL_COUNT=$(( FAIL_COUNT + 1 ))
            printf '[FAIL]: %s\n' "${fn}"
            [[ -n "${output}" ]] && printf '%s\n' "${output}"
        ;;
    esac

}

# -----------------------------------------------------------------------------
# File / load / surface checks
# -----------------------------------------------------------------------------

test_file_syntax_passes () {

    sys::__has bash || { skip_test 'bash is required for syntax test'; return $?; }
    bash -n "${SYS_FILE}"

}
test_file_sources_in_clean_shell () {

    local q=""

    sys::__has bash || { skip_test 'bash is required for source test'; return $?; }
    q="$(printf '%q' "${SYS_FILE}")"
    bash -lc "source ${q}; sys::name >/dev/null"

}
test_all_expected_functions_exist () {

    local fn=""
    local -a fns=(
        sys::__has sys::__lower sys::__open_target sys::__normalize_open_target
        sys::is_linux sys::is_macos sys::is_wsl sys::is_cygwin sys::is_msys sys::is_gitbash sys::is_windows
        sys::is_unix sys::is_posix sys::is_ci sys::ci_name sys::is_ci_pull sys::is_ci_push sys::is_ci_tag
        sys::is_gui sys::is_terminal sys::is_interactive sys::is_headless sys::is_container
        sys::name sys::family sys::runtime sys::distro sys::manager sys::arch sys::open
        sys::disk_total sys::disk_free sys::disk_used sys::disk_percent sys::disk_size sys::disk_info
        sys::mem_total sys::mem_free sys::mem_used sys::mem_percent sys::mem_info
        sys::gid sys::gname sys::gexists sys::gusers sys::uid sys::uname sys::uhome sys::ushell
        sys::uexists sys::ugroup sys::ugroups sys::uingroup sys::is_root sys::is_admin sys::add_group sys::add_user
    )

    for fn in "${fns[@]}"; do
        declare -F "${fn}" >/dev/null 2>&1 || return 1
    done

}

# -----------------------------------------------------------------------------
# Helpers
# -----------------------------------------------------------------------------

test___has_detects_existing_and_missing_commands () {

    assert_true 'sys::__has must detect bash' sys::__has bash
    assert_false 'sys::__has must reject nonsense command' sys::__has __definitely_not_a_real_command__

}
test___lower_lowercases_ascii_input () {

    assert_eq 'abc-xyz_123' "$(sys::__lower 'AbC-XYZ_123')" '__lower failed to lowercase ASCII input'

}
test___lower_handles_empty_input () {

    assert_eq '' "$(sys::__lower '')" '__lower must preserve empty input'

}

# -----------------------------------------------------------------------------
# Open target helpers
# -----------------------------------------------------------------------------

test___normalize_open_target_normalizes_supported_inputs () {

    assert_eq 'https://www.example.com' "$(sys::__normalize_open_target 'www.example.com')"
    assert_eq 'https://example.com' "$(sys::__normalize_open_target 'example.com')"
    assert_eq 'http://127.0.0.1:8080/path' "$(sys::__normalize_open_target '127.0.0.1:8080/path')"
    assert_eq 'http://localhost:3000/x' "$(sys::__normalize_open_target 'localhost:3000/x')"
    assert_eq 'https://example.com/x' "$(sys::__normalize_open_target 'https://example.com/x')"
    assert_eq 'mailto:test@example.com' "$(sys::__normalize_open_target 'mailto:test@example.com')"

}
test___normalize_open_target_rejects_invalid_values () {

    assert_false 'normalize must reject empty input' sys::__normalize_open_target ''
    assert_false 'normalize must reject multiline values' sys::__normalize_open_target $'bad\nvalue'
    assert_false 'normalize must reject arbitrary plain token' sys::__normalize_open_target 'not a uri or domain maybe'

}
test___open_target_macos_prefers_open () {

    setup_mock_path

    make_mock "${MOCK_BIN}" 'open' <<'SH'
#!/usr/bin/env bash
printf '%s\n' "$*" > "${MOCK_LOG}"
SH

    sys::is_macos () { return 0; }
    sys::is_windows () { return 1; }

    sys::__open_target 'https://example.com' 'uri'
    assert_eq 'https://example.com' "$(tr -d '\r\n' < "${MOCK_LOG}")"

}
test___open_target_windows_path_uses_cygpath_and_explorer () {

    setup_mock_path

    make_mock "${MOCK_BIN}" 'cygpath' <<'SH'
#!/usr/bin/env bash
printf 'C:\\Temp\\file.txt\n'
SH
    make_mock "${MOCK_BIN}" 'explorer.exe' <<'SH'
#!/usr/bin/env bash
printf '%s\n' "$*" > "${MOCK_LOG}"
SH

    sys::is_macos () { return 1; }
    sys::is_windows () { return 0; }

    sys::__open_target '/tmp/file.txt' 'path'
    assert_eq 'C:\Temp\file.txt' "$(tr -d '\r\n' < "${MOCK_LOG}")"

}
test___open_target_windows_uri_falls_back_to_cmd_start () {

    setup_mock_path

    make_mock "${MOCK_BIN}" 'cmd.exe' <<'SH'
#!/usr/bin/env bash
printf '%s\n' "$*" > "${MOCK_LOG}"
SH

    sys::is_macos () { return 1; }
    sys::is_windows () { return 0; }
    sys::__has () { [[ "${1:-}" == 'cmd.exe' ]]; }

    sys::__open_target 'https://example.com' 'uri'
    assert_regex "$(tr -d '\r\n' < "${MOCK_LOG}")" '^/C start  https://example\.com$' 'cmd fallback arguments are wrong'

}
test___open_target_linux_uses_xdg_open () {

    setup_mock_path

    make_mock "${MOCK_BIN}" 'xdg-open' <<'SH'
#!/usr/bin/env bash
printf '%s\n' "$*" > "${MOCK_LOG}"
SH

    sys::is_macos () { return 1; }
    sys::is_windows () { return 1; }

    sys::__open_target 'https://example.com' 'uri'
    assert_eq 'https://example.com' "$(tr -d '\r\n' < "${MOCK_LOG}")"

}

# -----------------------------------------------------------------------------
# Platform detection
# -----------------------------------------------------------------------------

test_is_linux_detects_linux_via_uname () {

    OSTYPE=''
    uname () { printf 'Linux\n'; }
    assert_true 'is_linux failed for uname=Linux' sys::is_linux

}
test_is_macos_detects_darwin_via_uname () {

    OSTYPE=''
    uname () { printf 'Darwin\n'; }
    assert_true 'is_macos failed for uname=Darwin' sys::is_macos

}
test_is_wsl_detects_env_fast_path () {

    WSL_DISTRO_NAME='Ubuntu'
    sys::is_linux () { return 0; }
    assert_true 'is_wsl failed for WSL_DISTRO_NAME' sys::is_wsl

}
test_is_cygwin_detects_uname () {

    OSTYPE=''
    uname () { printf 'CYGWIN_NT-10.0\n'; }
    assert_true 'is_cygwin failed for CYGWIN uname' sys::is_cygwin

}
test_is_msys_detects_msystem () {

    MSYSTEM='MINGW64'
    OSTYPE=''
    assert_true 'is_msys failed for MSYSTEM=MINGW64' sys::is_msys

}
test_is_gitbash_detects_git_install_root () {

    GitInstallRoot='C:\\Program Files\\Git'
    sys::is_msys () { return 0; }
    assert_true 'is_gitbash failed for GitInstallRoot' sys::is_gitbash

}
test_is_windows_rejects_wsl_and_accepts_native_env () {

    WINDIR='C:\\Windows'
    SystemRoot='C:\\Windows'
    COMSPEC='C:\\Windows\\System32\\cmd.exe'
    sys::is_wsl () { return 1; }
    sys::is_msys () { return 1; }
    sys::is_cygwin () { return 1; }
    sys::is_linux () { return 1; }
    sys::is_macos () { return 1; }
    assert_true 'is_windows failed for native windows env' sys::is_windows

}
test_is_windows_returns_false_for_wsl () {

    sys::is_wsl () { return 0; }
    assert_false 'is_windows must reject WSL' sys::is_windows

}
test_is_unix_and_is_posix_follow_expected_platform_sets () {

    sys::is_linux () { return 0; }
    sys::is_macos () { return 1; }
    assert_true 'is_unix must accept linux' sys::is_unix
    assert_true 'is_posix must accept linux' sys::is_posix

    sys::is_linux () { return 1; }
    sys::is_macos () { return 1; }
    sys::is_wsl () { return 0; }
    assert_false 'is_unix must reject WSL' sys::is_unix
    assert_true 'is_posix must accept WSL' sys::is_posix

}

# -----------------------------------------------------------------------------
# CI / GUI / terminal / host probes
# -----------------------------------------------------------------------------

test_ci_detection_and_names () {

    GITHUB_ACTIONS='true'
    GITHUB_EVENT_NAME='pull_request'
    assert_true 'is_ci failed under GITHUB_ACTIONS' sys::is_ci
    assert_eq 'github' "$(sys::ci_name 2>/dev/null || true)"
    assert_true 'is_ci_pull failed for GitHub PR' sys::is_ci_pull
    assert_false 'is_ci_push must be false during pull_request' sys::is_ci_push

    unset GITHUB_ACTIONS || true
    unset GITHUB_EVENT_NAME || true
    CI='true'
    CI_PIPELINE_SOURCE='push'
    assert_true 'is_ci_push failed for generic push pipeline' sys::is_ci_push
    assert_eq 'generic' "$(sys::ci_name 2>/dev/null || true)"

    unset CI || true
    unset CI_PIPELINE_SOURCE || true
    CI_COMMIT_TAG='v1.2.3'
    assert_true 'is_ci_tag failed for CI_COMMIT_TAG' sys::is_ci_tag

}
test_is_gui_and_headless_mocked_logic () {

    sys::is_linux () { return 0; }
    sys::is_macos () { return 1; }
    sys::is_windows () { return 1; }
    DISPLAY=':0'
    unset WAYLAND_DISPLAY || true
    assert_true 'is_gui failed for linux DISPLAY' sys::is_gui
    assert_false 'is_headless must be false for linux DISPLAY' sys::is_headless

    unset DISPLAY || true
    unset WAYLAND_DISPLAY || true
    assert_false 'is_gui must be false without display vars' sys::is_gui
    assert_true 'is_headless must be true without display vars' sys::is_headless

}
test_is_terminal_false_when_all_standard_fds_are_detached () {

    exec </dev/null >/dev/null 2>/dev/null
    assert_false 'is_terminal must be false with detached stdio' sys::is_terminal

}
test_is_interactive_false_in_test_shell () {

    assert_false 'is_interactive must be false in non-interactive shell' sys::is_interactive

}
test_is_interactive_true_in_spawned_interactive_bash () {

    local q="" out=""

    sys::__has bash || { skip_test 'bash is required for interactive probe'; return $?; }
    q="$(printf '%q' "${SYS_FILE}")"
    out="$(bash -ic "source ${q}; if sys::is_interactive; then printf yes; else printf no; fi" 2>/dev/null | tail -n 1)"
    assert_eq 'yes' "${out}" 'interactive bash probe failed'

}
test_is_container_smoke () {

    sys::is_container >/dev/null 2>&1 || true

}

# -----------------------------------------------------------------------------
# Identity / runtime / manager / arch
# -----------------------------------------------------------------------------

test_name_family_runtime_mocked () {

    sys::is_linux () { return 1; }
    sys::is_macos () { return 1; }
    sys::is_windows () { return 0; }
    sys::is_wsl () { return 1; }
    sys::is_gitbash () { return 1; }
    sys::is_msys () { return 1; }
    sys::is_cygwin () { return 1; }

    assert_eq 'windows' "$(sys::name 2>/dev/null || true)"
    assert_eq 'windows' "$(sys::family 2>/dev/null || true)"
    assert_eq 'windows' "$(sys::runtime 2>/dev/null || true)"

    sys::is_windows () { return 1; }
    sys::is_wsl () { return 0; }
    assert_eq 'unix' "$(sys::family 2>/dev/null || true)"
    assert_eq 'wsl' "$(sys::runtime 2>/dev/null || true)"

}
test_distro_real_or_mocked_windows_fallback () {

    local out=""

    out="$(sys::distro 2>/dev/null || true)"
    if [[ -n "${out}" ]]; then
        assert_non_empty "${out}" 'distro must not be empty'
        return 0
    fi

    sys::is_linux () { return 1; }
    sys::is_macos () { return 1; }
    sys::is_windows () { return 0; }
    sys::runtime () { printf 'gitbash\n'; }
    assert_eq 'gitbash' "$(sys::distro 2>/dev/null || true)"

}
test_manager_prefers_expected_priority_on_linux () {

    setup_mock_path

    make_mock "${MOCK_BIN}" 'apt-get' <<'SH'
#!/usr/bin/env bash
exit 0
SH
    make_mock "${MOCK_BIN}" 'dnf' <<'SH'
#!/usr/bin/env bash
exit 0
SH

    sys::is_linux () { return 0; }
    sys::is_macos () { return 1; }
    sys::is_windows () { return 1; }
    assert_eq 'apt' "$(sys::manager 2>/dev/null || true)"

}
test_arch_normalizes_common_aliases () {

    uname () { printf 'AMD64\n'; }
    assert_eq 'x64' "$(sys::arch 2>/dev/null || true)"

    uname () { printf 'aarch64\n'; }
    assert_eq 'arm64' "$(sys::arch 2>/dev/null || true)"

}
test_real_runtime_identity_values_are_sane () {

    local name="" family="" runtime="" arch="" manager="" distro=""

    name="$(sys::name 2>/dev/null || true)"
    family="$(sys::family 2>/dev/null || true)"
    runtime="$(sys::runtime 2>/dev/null || true)"
    arch="$(sys::arch 2>/dev/null || true)"
    manager="$(sys::manager 2>/dev/null || true)"
    distro="$(sys::distro 2>/dev/null || true)"

    assert_one_of "${name}" linux macos windows unknown
    assert_one_of "${family}" unix windows unknown
    assert_one_of "${runtime}" linux macos windows wsl gitbash msys2 cygwin unknown
    assert_non_empty "${arch}" 'arch must not be empty'
    assert_non_empty "${manager}" 'manager must print something'
    assert_non_empty "${distro}" 'distro must print something'

}

# -----------------------------------------------------------------------------
# sys::open end-to-end behavior
# -----------------------------------------------------------------------------

test_open_path_branch_calls_open_target_with_path_kind () {

    local dir="" file="" log=""

    dir="$(new_test_dir)"
    file="${dir}/x.txt"
    log="${dir}/log.txt"
    printf 'hello\n' > "${file}"

    sys::__open_target () {
        printf '%s|%s\n' "$1" "$2" > "${log}"
    }

    sys::open "${file}"
    assert_eq "${file}|path" "$(tr -d '\r\n' < "${log}")"

}
test_open_command_branch_executes_command_with_arguments () {

    setup_mock_path

    make_mock "${MOCK_BIN}" 'fake-opener' <<'SH'
#!/usr/bin/env bash
printf '%s\n' "$*" > "${MOCK_LOG}"
SH

    sys::open fake-opener alpha beta
    wait_for_non_empty "${MOCK_LOG}" 100 0.02
    assert_eq 'alpha beta' "$(tr -d '\r\n' < "${MOCK_LOG}")"

}
test_open_uri_branch_normalizes_then_calls_open_target () {

    local dir="" log=""

    dir="$(new_test_dir)"
    log="${dir}/log.txt"

    sys::__open_target () {
        printf '%s|%s\n' "$1" "$2" > "${log}"
    }

    sys::open 'example.com'
    assert_eq 'https://example.com|uri' "$(tr -d '\r\n' < "${log}")"

}
test_open_rejects_invalid_target () {

    assert_false 'open must reject multiline target' sys::open $'bad\nvalue'
    assert_false 'open must reject empty target' sys::open ''

}

# -----------------------------------------------------------------------------
# Disk and memory probes
# -----------------------------------------------------------------------------

test_disk_metrics_are_numeric_and_consistent () {

    local total="" free="" used="" percent="" info=""

    total="$(sys::disk_total '.' 2>/dev/null || true)"
    free="$(sys::disk_free '.' 2>/dev/null || true)"
    used="$(sys::disk_used '.' 2>/dev/null || true)"
    percent="$(sys::disk_percent '.' 2>/dev/null || true)"
    info="$(sys::disk_info '.' 2>/dev/null || true)"

    [[ "${total}" =~ ^[0-9]+$ ]] || { skip_test 'disk_total not supported on this host'; return $?; }
    [[ "${free}" =~ ^[0-9]+$ ]] || fail_now 'disk_free must be numeric'
    [[ "${used}" =~ ^[0-9]+$ ]] || fail_now 'disk_used must be numeric'
    [[ "${percent}" =~ ^[0-9]+$ ]] || fail_now 'disk_percent must be numeric'

    assert_num_ge "${total}" "${free}" 'disk_total must be >= disk_free'
    assert_num_ge "${total}" "${used}" 'disk_total must be >= disk_used'
    assert_num_le "${percent}" 100 'disk_percent must be <= 100'
    assert_eq '.' "$(get_info_value path "${info}")"
    assert_eq "${total}" "$(get_info_value total "${info}")"

}
test_disk_size_reports_for_temp_dir () {

    local dir="" file="" actual="" reported=""

    dir="$(new_test_dir)"
    file="${dir}/blob.bin"

    dd if=/dev/zero of="${file}" bs=1 count=8192 >/dev/null 2>&1 || printf '%8192s' '' > "${file}"

    reported="$(sys::disk_size "${dir}" 2>/dev/null || true)"
    actual="$(wc -c < "${file}" | tr -d '[:space:]')"

    [[ "${reported}" =~ ^[0-9]+$ ]] || { skip_test 'disk_size not supported on this host'; return $?; }
    assert_num_ge "${reported}" "${actual}" 'disk_size must be >= actual file size'

}
test_memory_metrics_are_numeric_and_consistent_when_supported () {

    local total="" free="" used="" percent="" info=""

    total="$(sys::mem_total 2>/dev/null || true)"
    free="$(sys::mem_free 2>/dev/null || true)"
    used="$(sys::mem_used 2>/dev/null || true)"
    percent="$(sys::mem_percent 2>/dev/null || true)"
    info="$(sys::mem_info 2>/dev/null || true)"

    [[ "${total}" =~ ^[0-9]+$ ]] || { skip_test 'mem_total not supported on this host'; return $?; }
    [[ "${free}" =~ ^[0-9]+$ ]] || fail_now 'mem_free must be numeric'
    [[ "${used}" =~ ^[0-9]+$ ]] || fail_now 'mem_used must be numeric'
    [[ "${percent}" =~ ^[0-9]+$ ]] || fail_now 'mem_percent must be numeric'

    assert_num_ge "${total}" "${free}" 'mem_total must be >= mem_free'
    assert_num_ge "${total}" "${used}" 'mem_total must be >= mem_used'
    assert_num_le "${percent}" 100 'mem_percent must be <= 100'
    assert_regex "$(get_info_value total "${info}")" '^[0-9]+$' 'mem_info total must be numeric'
    assert_regex "$(get_info_value free "${info}")" '^[0-9]+$' 'mem_info free must be numeric'
    assert_regex "$(get_info_value used "${info}")" '^[0-9]+$' 'mem_info used must be numeric'
    assert_regex "$(get_info_value percent "${info}")" '^[0-9]+$' 'mem_info percent must be numeric'

}

# -----------------------------------------------------------------------------
# Real identity smoke tests
# -----------------------------------------------------------------------------

test_identity_functions_return_sane_values () {

    local uid_v="" gid_v="" uname_v="" gname_v="" home="" shell=""

    uid_v="$(sys::uid 2>/dev/null || true)"
    gid_v="$(sys::gid 2>/dev/null || true)"
    uname_v="$(sys::uname 2>/dev/null || true)"
    gname_v="$(sys::gname 2>/dev/null || true)"
    home="$(sys::uhome 2>/dev/null || true)"
    shell="$(sys::ushell 2>/dev/null || true)"

    [[ -n "${uid_v}" ]] && [[ "${uid_v}" =~ ^[0-9]+$ ]] || { skip_test 'uid not available on this host'; return $?; }
    [[ -n "${gid_v}" ]] && [[ "${gid_v}" =~ ^[0-9]+$ ]] || fail_now 'gid must be numeric'
    assert_non_empty "${uname_v}" 'uname must not be empty'
    assert_non_empty "${gname_v}" 'gname must not be empty'
    assert_non_empty "${home}" 'uhome must not be empty'
    assert_non_empty "${shell}" 'ushell must not be empty'

}
test_user_group_existence_and_membership_smoke () {

    local user="" group="" groups=""

    user="$(sys::uname 2>/dev/null || true)"
    group="$(sys::ugroup "${user}" 2>/dev/null || true)"
    groups="$(sys::ugroups "${user}" 2>/dev/null || true)"

    [[ -n "${user}" ]] || { skip_test 'current user name unavailable'; return $?; }
    assert_true 'uexists must succeed for current user' sys::uexists "${user}"
    [[ -n "${group}" ]] || { skip_test 'current primary group unavailable'; return $?; }
    assert_true 'gexists must succeed for current primary group' sys::gexists "${group}"
    assert_non_empty "${groups}" 'ugroups must not be empty for current user'
    assert_true 'uingroup must succeed for current primary group' sys::uingroup "${group}" "${user}"

}

# -----------------------------------------------------------------------------
# Parser unit tests
# -----------------------------------------------------------------------------

test_gusers_parses_getent_group_members () {

    sys::__has () { [[ "${1:-}" == 'getent' ]]; }
    getent () {
        [[ "${1:-}" == 'group' && "${2:-}" == 'devs' ]] || return 1
        printf 'devs:x:1000:alice,bob,charlie\n'
    }

    assert_eq 'alice bob charlie' "$(sys::gusers devs 2>/dev/null || true)"

}
test_gusers_parses_windows_net_localgroup_output () {

    setup_mock_path

    make_mock "${MOCK_BIN}" 'net.exe' <<'SH'
#!/usr/bin/env bash
cat <<'OUT'
Alias name     devs
Comment        test group
-------------------------------------------------------------------------------
Alice
DOMAIN\Bob
The command completed successfully.
OUT
SH

    sys::is_windows () { return 0; }
    sys::is_macos () { return 1; }
    sys::__has () { [[ "${1:-}" == 'net.exe' ]]; }

    assert_eq 'Alice DOMAIN\Bob' "$(sys::gusers devs 2>/dev/null || true)"

}
test_ugroup_parses_getent_primary_group () {

    sys::__has () { [[ "${1:-}" == 'id' || "${1:-}" == 'getent' ]]; }
    id () { return 1; }
    getent () {
        if [[ "${1:-}" == 'passwd' && "${2:-}" == 'alice' ]]; then
            printf 'alice:x:1000:1001:Alice:/home/alice:/bin/bash\n'
            return 0
        fi
        if [[ "${1:-}" == 'group' && "${2:-}" == '1001' ]]; then
            printf 'engineers:x:1001:\n'
            return 0
        fi
        return 1
    }

    assert_eq 'engineers' "$(sys::ugroup alice 2>/dev/null || true)"

}
test_ugroups_parses_getent_supplemental_and_primary_groups () {

    sys::__has () { [[ "${1:-}" == 'id' || "${1:-}" == 'getent' ]]; }
    id () { return 1; }
    getent () {
        if [[ "${1:-}" == 'passwd' && "${2:-}" == 'alice' ]]; then
            printf 'alice:x:1000:1001:Alice:/home/alice:/bin/bash\n'
            return 0
        fi
        if [[ "${1:-}" == 'group' && "${2:-}" == '1001' ]]; then
            printf 'engineers:x:1001:\n'
            return 0
        fi
        if [[ "${1:-}" == 'group' && "$#" -eq 1 ]]; then
            cat <<'OUT'
engineers:x:1001:
wheel:x:10:alice
sudo:x:27:alice,bob
OUT
            return 0
        fi
        return 1
    }

    assert_eq 'engineers wheel sudo' "$(sys::ugroups alice 2>/dev/null || true)"

}
test_uingroup_matches_windows_localgroup_membership_case_insensitively () {

    setup_mock_path

    make_mock "${MOCK_BIN}" 'net.exe' <<'SH'
#!/usr/bin/env bash
cat <<'OUT'
Alias name     Developers
-------------------------------------------------------------------------------
DOMAIN\Alice
bob
The command completed successfully.
OUT
SH

    sys::is_windows () { return 0; }
    sys::__has () { [[ "${1:-}" == 'net.exe' ]]; }
    sys::uname () { printf 'Alice\n'; }

    assert_true 'uingroup must match DOMAIN\\Alice' sys::uingroup Developers Alice
    assert_true 'uingroup must match bob case-insensitively' sys::uingroup Developers BOB

}

# -----------------------------------------------------------------------------
# Privilege detection
# -----------------------------------------------------------------------------

test_is_root_unix_uses_id_u_zero () {

    sys::is_windows () { return 1; }
    sys::__has () { [[ "${1:-}" == 'id' ]]; }
    id () {
        [[ "${1:-}" == '-u' ]] || return 1
        printf '0\n'
    }

    assert_true 'is_root must succeed for id -u = 0' sys::is_root

}
test_is_root_windows_uses_powershell_when_net_session_unavailable () {

    setup_mock_path

    make_mock "${MOCK_BIN}" 'powershell.exe' <<'SH'
#!/usr/bin/env bash
printf 'True\r\n'
SH

    sys::is_windows () { return 0; }
    sys::__has () { [[ "${1:-}" == 'powershell.exe' ]]; }

    assert_true 'is_root must succeed for powershell admin=True' sys::is_root

}
test_is_admin_stops_unix_group_fallback_on_windows () {

    local dir="" flag=""

    dir="$(new_test_dir)"
    flag="${dir}/called"

    sys::is_root () { return 1; }
    sys::is_windows () { return 0; }
    sys::uingroup () {
        printf 'hit\n' > "${flag}"
        return 0
    }

    assert_false 'is_admin must return false on windows when is_root fails' sys::is_admin
    [[ ! -e "${flag}" ]] || fail_now 'is_admin must not call unix group fallback on windows'

}
test_is_admin_unix_uses_group_fallbacks () {

    sys::is_root () { return 1; }
    sys::is_windows () { return 1; }
    sys::uingroup () { [[ "${1:-}" == 'wheel' ]]; }

    assert_true 'is_admin must accept wheel membership' sys::is_admin

}

# -----------------------------------------------------------------------------
# Mutating operations with mocks
# -----------------------------------------------------------------------------

test_add_group_short_circuits_when_group_exists () {

    local dir="" flag=""

    dir="$(new_test_dir)"
    flag="${dir}/called"

    sys::gexists () { return 0; }
    sys::is_linux () { return 0; }
    sys::__has () { return 0; }
    groupadd () { printf 'hit\n' > "${flag}"; }

    sys::add_group existing
    [[ ! -e "${flag}" ]] || fail_now 'add_group must short-circuit when group exists'

}
test_add_group_linux_uses_groupadd () {

    local dir="" log=""

    dir="$(new_test_dir)"
    log="${dir}/log.txt"

    sys::gexists () { return 1; }
    sys::is_linux () { return 0; }
    sys::is_macos () { return 1; }
    sys::is_windows () { return 1; }
    sys::__has () { [[ "${1:-}" == 'groupadd' ]]; }
    groupadd () { printf '%s\n' "$*" > "${log}"; }

    sys::add_group devs
    assert_eq 'devs' "$(tr -d '\r\n' < "${log}")"

}
test_add_group_macos_uses_dseditgroup () {

    local dir="" log=""

    dir="$(new_test_dir)"
    log="${dir}/log.txt"

    sys::gexists () { return 1; }
    sys::is_linux () { return 1; }
    sys::is_macos () { return 0; }
    sys::is_windows () { return 1; }
    sys::__has () { [[ "${1:-}" == 'dseditgroup' ]]; }
    dseditgroup () { printf '%s\n' "$*" > "${log}"; }

    sys::add_group devs
    assert_eq '-o create devs' "$(tr -d '\r\n' < "${log}")"

}
test_add_group_windows_uses_net_localgroup_add () {

    setup_mock_path

    make_mock "${MOCK_BIN}" 'net.exe' <<'SH'
#!/usr/bin/env bash
printf '%s\n' "$*" > "${MOCK_LOG}"
SH

    sys::gexists () { return 1; }
    sys::is_linux () { return 1; }
    sys::is_macos () { return 1; }
    sys::is_windows () { return 0; }
    sys::__has () { [[ "${1:-}" == 'net.exe' ]]; }

    sys::add_group devs
    assert_eq 'localgroup devs /add' "$(tr -d '\r\n' < "${MOCK_LOG}")"

}
test_add_user_linux_creates_group_then_user () {

    local dir="" log=""

    dir="$(new_test_dir)"
    log="${dir}/log.txt"

    sys::uexists () { return 1; }
    sys::gexists () { return 1; }
    sys::add_group () { printf 'add_group %s\n' "$1" >> "${log}"; return 0; }
    sys::is_linux () { return 0; }
    sys::is_macos () { return 1; }
    sys::is_windows () { return 1; }
    sys::__has () { [[ "${1:-}" == 'useradd' ]]; }
    useradd () { printf 'useradd %s\n' "$*" >> "${log}"; }

    sys::add_user alice devs
    assert_eq $'add_group devs\nuseradd -m -g devs alice' "$(cat "${log}")"

}
test_add_user_linux_existing_user_adds_membership_only_when_needed () {

    local dir="" log=""

    dir="$(new_test_dir)"
    log="${dir}/log.txt"

    sys::uexists () { return 0; }
    sys::gexists () { return 0; }
    sys::uingroup () { return 1; }
    sys::is_linux () { return 0; }
    sys::is_macos () { return 1; }
    sys::is_windows () { return 1; }
    sys::__has () { [[ "${1:-}" == 'usermod' ]]; }
    usermod () { printf '%s\n' "$*" > "${log}"; }

    sys::add_user alice devs
    assert_eq '-aG devs alice' "$(tr -d '\r\n' < "${log}")"

}
test_add_user_linux_membership_short_circuits_when_already_present () {

    local dir="" flag=""

    dir="$(new_test_dir)"
    flag="${dir}/called"

    sys::uexists () { return 0; }
    sys::gexists () { return 0; }
    sys::uingroup () { return 0; }
    sys::is_linux () { return 0; }
    sys::is_macos () { return 1; }
    sys::is_windows () { return 1; }
    sys::__has () { return 0; }
    usermod () { printf 'hit\n' > "${flag}"; }

    sys::add_user alice devs
    [[ ! -e "${flag}" ]] || fail_now 'add_user must not call usermod when membership already exists'

}
test_add_user_macos_uses_sysadminctl_then_dseditgroup () {

    local dir="" log=""

    dir="$(new_test_dir)"
    log="${dir}/log.txt"

    sys::uexists () { return 1; }
    sys::gexists () { return 0; }
    sys::uingroup () { return 1; }
    sys::is_linux () { return 1; }
    sys::is_macos () { return 0; }
    sys::is_windows () { return 1; }
    sys::__has () { [[ "${1:-}" == 'sysadminctl' || "${1:-}" == 'dseditgroup' ]]; }
    sysadminctl () { printf 'sysadminctl %s\n' "$*" >> "${log}"; }
    dseditgroup () { printf 'dseditgroup %s\n' "$*" >> "${log}"; }

    sys::add_user alice devs
    assert_eq $'sysadminctl -addUser alice\ndseditgroup -o edit -a alice -t user devs' "$(cat "${log}")"

}
test_add_user_windows_uses_net_user_and_localgroup () {

    setup_mock_path

    make_mock "${MOCK_BIN}" 'net.exe' <<'SH'
#!/usr/bin/env bash
printf '%s\n' "$*" >> "${MOCK_LOG}"
SH

    sys::uexists () { return 1; }
    sys::gexists () { return 1; }
    sys::uingroup () { return 1; }
    sys::is_linux () { return 1; }
    sys::is_macos () { return 1; }
    sys::is_windows () { return 0; }
    sys::__has () { [[ "${1:-}" == 'net.exe' ]]; }

    sys::add_user alice devs
    assert_eq $'user alice /add\nlocalgroup devs /add\nlocalgroup devs alice /add' "$(cat "${MOCK_LOG}")"

}

# -----------------------------------------------------------------------------
# Optional destructive real-system test
# -----------------------------------------------------------------------------

test_destructive_real_add_group_and_add_user () {

    local suffix="" group="" user=""

    [[ "${SYS_TEST_DESTRUCTIVE}" == '1' ]] || { skip_test 'set SYS_TEST_DESTRUCTIVE=1 to enable destructive tests'; return $?; }

    if ! sys::is_root && ! sys::is_admin; then
        skip_test 'destructive test requires root/admin privileges'
        return $?
    fi

    suffix="$$$RANDOM"
    group="systg${suffix}"
    user="systu${suffix}"

    if sys::is_linux; then
        sys::__has userdel || { skip_test 'userdel is required for linux destructive cleanup'; return $?; }
        sys::__has groupdel || { skip_test 'groupdel is required for linux destructive cleanup'; return $?; }

        sys::add_group "${group}"
        assert_true 'group must exist after add_group' sys::gexists "${group}"
        sys::add_user "${user}" "${group}"
        assert_true 'user must exist after add_user' sys::uexists "${user}"
        assert_true 'user must belong to target group' sys::uingroup "${group}" "${user}"

        userdel -r "${user}" >/dev/null 2>&1 || userdel "${user}" >/dev/null 2>&1 || true
        groupdel "${group}" >/dev/null 2>&1 || true
        return 0
    fi

    if sys::is_macos; then
        sys::__has sysadminctl || { skip_test 'sysadminctl is required for macOS destructive cleanup'; return $?; }
        sys::__has dseditgroup || { skip_test 'dseditgroup is required for macOS destructive cleanup'; return $?; }

        sys::add_group "${group}"
        assert_true 'group must exist after add_group' sys::gexists "${group}"
        sys::add_user "${user}" "${group}"
        assert_true 'user must exist after add_user' sys::uexists "${user}"
        assert_true 'user must belong to target group' sys::uingroup "${group}" "${user}"

        sysadminctl -deleteUser "${user}" >/dev/null 2>&1 || true
        dseditgroup -o delete "${group}" >/dev/null 2>&1 || true
        return 0
    fi

    if sys::is_windows; then
        sys::__has net.exe || { skip_test 'net.exe is required for windows destructive cleanup'; return $?; }

        sys::add_group "${group}"
        assert_true 'group must exist after add_group' sys::gexists "${group}"
        sys::add_user "${user}" "${group}"
        assert_true 'user must exist after add_user' sys::uexists "${user}"
        assert_true 'user must belong to target group' sys::uingroup "${group}" "${user}"

        net.exe user "${user}" /delete >/dev/null 2>&1 || true
        net.exe localgroup "${group}" /delete >/dev/null 2>&1 || true
        return 0
    fi

    skip_test 'destructive test not implemented for this runtime'

}

main () {

    local fn=""

    while IFS= read -r fn; do
        run_test "${fn}"
    done < <(collect_tests)

    printf '\n'
    printf 'Total : %s\n' "${TOTAL_COUNT}"
    printf 'Pass  : %s\n' "${PASS_COUNT}"
    printf 'Skip  : %s\n' "${SKIP_COUNT}"
    printf 'Fail  : %s\n' "${FAIL_COUNT}"

    (( FAIL_COUNT == 0 ))

}

main "$@"
