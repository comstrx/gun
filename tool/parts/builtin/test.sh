#!/usr/bin/env bash
set -Eeuo pipefail

SYS_TEST_SKIP_CODE=200
SYS_TEST_DESTRUCTIVE="${SYS_TEST_DESTRUCTIVE:-1}"

SYS_MODE='run'
SYS_SINGLE_TEST=''
SYS_FILE=''

if [[ "${1:-}" == '--single' ]]; then
    SYS_MODE='single'
    SYS_SINGLE_TEST="${2:-}"
    SYS_FILE="${3:-./system.sh}"
else
    SYS_FILE="${1:-./system.sh}"
fi

[[ -f "${SYS_FILE}" ]] || {
    printf '[ERR]: system file not found: %s\n' "${SYS_FILE}" >&2
    exit 1
}

# shellcheck disable=SC1090
source "${SYS_FILE}"

TEST_ROOT="$(mktemp -d "${TMPDIR:-/tmp}/system-extreme-test.XXXXXX")"
PASS_COUNT=0
FAIL_COUNT=0
SKIP_COUNT=0
TOTAL_COUNT=0

cleanup_root () {
    [[ -n "${TEST_ROOT:-}" && -d "${TEST_ROOT}" ]] && rm -rf "${TEST_ROOT}" 2>/dev/null || true
}
trap cleanup_root EXIT

fail_now () { printf '%s\n' "${1:-assertion failed}" >&2; return 1; }
skip_now () { printf '%s\n' "${1:-skipped}" >&2; return "${SYS_TEST_SKIP_CODE}"; }
assert_true () { local msg="${1:-expected success}"; shift || true; "$@" >/dev/null 2>&1 || fail_now "${msg}"; }
assert_false () { local msg="${1:-expected failure}"; shift || true; if "$@" >/dev/null 2>&1; then fail_now "${msg}"; return 1; fi; return 0; }
assert_eq () { local e="${1:-}" a="${2:-}" m="${3:-}"; [[ "${a}" == "${e}" ]] && return 0; [[ -n "${m}" ]] || m="expected [${e}] but got [${a}]"; fail_now "${m}"; }
assert_non_empty () { local v="${1:-}" m="${2:-value must not be empty}"; [[ -n "${v}" ]] || fail_now "${m}"; }
assert_regex () { local v="${1:-}" r="${2:-}" m="${3:-}"; [[ "${v}" =~ ${r} ]] && return 0; [[ -n "${m}" ]] || m="value [${v}] does not match [${r}]"; fail_now "${m}"; }
assert_num_le () { local l="${1:-}" r="${2:-}" m="${3:-}"; [[ "${l}" =~ ^[0-9]+$ && "${r}" =~ ^[0-9]+$ ]] || fail_now 'non numeric compare'; (( l <= r )) && return 0; [[ -n "${m}" ]] || m="expected ${l} <= ${r}"; fail_now "${m}"; }
assert_num_ge () { local l="${1:-}" r="${2:-}" m="${3:-}"; [[ "${l}" =~ ^[0-9]+$ && "${r}" =~ ^[0-9]+$ ]] || fail_now 'non numeric compare'; (( l >= r )) && return 0; [[ -n "${m}" ]] || m="expected ${l} >= ${r}"; fail_now "${m}"; }
assert_contains_line () { local n="${1:-}" h="${2:-}" m="${3:-}"; printf '%s\n' "${h}" | grep -Fx -- "${n}" >/dev/null 2>&1 && return 0; [[ -n "${m}" ]] || m="missing line [${n}]"; fail_now "${m}"; }
new_test_dir () { mktemp -d "${TEST_ROOT}/case.XXXXXX"; }
setup_mock_path () { local d=""; d="$(mktemp -d "${TEST_ROOT}/mock.XXXXXX")" || return 1; export MOCK_BIN="${d}"; export MOCK_LOG="${d}/calls.log"; : > "${MOCK_LOG}"; export PATH="${MOCK_BIN}:${PATH}"; }
make_mock () { local d="${1:-}" n="${2:-}"; shift 2 || true; [[ -n "${d}" && -n "${n}" ]] || return 1; cat > "${d}/${n}" || return 1; chmod +x "${d}/${n}" || return 1; }
get_info_value () { local k="${1:-}" i="${2:-}" l=""; while IFS= read -r l || [[ -n "${l}" ]]; do [[ "${l}" == "${k}="* ]] || continue; printf '%s\n' "${l#*=}"; return 0; done <<< "${i}"; return 1; }
random_token () { printf '%s%s' "$(date +%s 2>/dev/null || printf '%s' $$)" "$RANDOM"; }
list_has_exact () { printf '%s\n' "${2:-}" | grep -Fx -- "${1:-}" >/dev/null 2>&1; }
require_privileged_destructive () { [[ "${SYS_TEST_DESTRUCTIVE}" == '1' ]] || { skip_now 'destructive tests disabled'; return $?; }; sys::is_root || sys::is_admin || { skip_now 'requires root/admin'; return $?; }; }
cleanup_identity () {
    local user="${1:-}" group="${2:-}"
    if sys::is_linux; then
        [[ -n "${user}" ]] && sys::__has userdel && { userdel -r "${user}" >/dev/null 2>&1 || userdel "${user}" >/dev/null 2>&1 || true; }
        [[ -n "${group}" ]] && sys::__has groupdel && { groupdel "${group}" >/dev/null 2>&1 || true; }
        return 0
    fi
    if sys::is_macos; then
        [[ -n "${user}" ]] && { sys::__has sysadminctl && sysadminctl -deleteUser "${user}" >/dev/null 2>&1 || true; sys::__has dscl && dscl . -delete "/Users/${user}" >/dev/null 2>&1 || true; }
        [[ -n "${group}" ]] && sys::__has dseditgroup && dseditgroup -o delete "${group}" >/dev/null 2>&1 || true
        return 0
    fi
    if sys::is_windows; then
        [[ -n "${user}" ]] && sys::__has net.exe && net.exe user "${user}" /delete >/dev/null 2>&1 || true
        [[ -n "${group}" ]] && sys::__has net.exe && net.exe localgroup "${group}" /delete >/dev/null 2>&1 || true
        return 0
    fi
}

collect_tests () { declare -F | awk '{print $3}' | grep '^test_' | sort; }
run_test () {
    local fn="${1:-}" output="" rc=0
    TOTAL_COUNT=$(( TOTAL_COUNT + 1 ))
    set +e
    output="$(bash "$0" --single "${fn}" "${SYS_FILE}" 2>&1)"
    rc=$?
    set -e
    case "${rc}" in
        0) PASS_COUNT=$(( PASS_COUNT + 1 )); printf '[PASS]: %s\n' "${fn}" ;;
        "${SYS_TEST_SKIP_CODE}") SKIP_COUNT=$(( SKIP_COUNT + 1 )); printf '[SKIP]: %s' "${fn}"; [[ -n "${output}" ]] && printf ' - %s' "${output%%$'\n'*}"; printf '\n' ;;
        *) FAIL_COUNT=$(( FAIL_COUNT + 1 )); printf '[FAIL]: %s\n' "${fn}"; [[ -n "${output}" ]] && printf '%s\n' "${output}" ;;
    esac
}

# -----------------------------------------------------------------------------
# file and helpers
# -----------------------------------------------------------------------------

test_file_syntax_passes () { sys::__has bash || { skip_now 'bash required'; return $?; }; bash -n "${SYS_FILE}"; }
test_file_sources_in_clean_shell () { local q=""; q="$(printf '%q' "${SYS_FILE}")"; bash -lc "set -Eeuo pipefail; source ${q}; sys::name >/dev/null"; }
test_all_expected_functions_exist () {
    local fn=""
    local -a fns=(
        sys::__has sys::__lower sys::__open_target sys::__normalize_open_target
        sys::is_linux sys::is_macos sys::is_wsl sys::is_cygwin sys::is_msys sys::is_gitbash sys::is_unix sys::is_posix sys::is_windows
        sys::ci_name sys::is_ci sys::is_ci_pull sys::is_ci_push sys::is_ci_tag sys::is_gui sys::is_terminal sys::is_interactive sys::is_headless sys::is_container
        sys::name sys::family sys::runtime sys::distro sys::manager sys::arch sys::open
        sys::disk_total sys::disk_free sys::disk_used sys::disk_percent sys::disk_size sys::disk_info
        sys::mem_total sys::mem_free sys::mem_used sys::mem_percent sys::mem_info
        sys::gid sys::gname sys::gexists sys::uid sys::uname sys::uhome sys::ushell sys::uexists sys::ugroup sys::ugroups sys::groups sys::users sys::gusers sys::ingroup sys::addgroup sys::adduser sys::is_root sys::is_admin
    )
    for fn in "${fns[@]}"; do declare -F "${fn}" >/dev/null 2>&1 || fail_now "missing function: ${fn}"; done
}
test___has_detects_existing_and_missing_commands () { assert_true 'bash must exist' sys::__has bash; assert_false 'missing command must fail' sys::__has definitely_missing_cmd_928347; }
test___lower_handles_ascii_and_empty () { assert_eq 'hello-core_123' "$(sys::__lower 'Hello-CORE_123')"; assert_eq '' "$(sys::__lower '')"; }
test___normalize_open_target_normalizes_supported_inputs () {
    assert_eq 'https://www.example.com' "$(sys::__normalize_open_target 'www.example.com')"
    assert_eq 'https://example.com' "$(sys::__normalize_open_target 'example.com')"
    assert_eq 'http://127.0.0.1:8080' "$(sys::__normalize_open_target '127.0.0.1:8080')"
    assert_eq 'http://localhost:3000/path' "$(sys::__normalize_open_target 'localhost:3000/path')"
    assert_eq 'https://example.com/x' "$(sys::__normalize_open_target 'https://example.com/x')"
}
test___normalize_open_target_rejects_invalid_values () { assert_false 'empty target must fail' sys::__normalize_open_target ''; assert_false 'newline target must fail' sys::__normalize_open_target $'bad\nvalue'; assert_false 'plain token must fail' sys::__normalize_open_target 'not a url'; }

# -----------------------------------------------------------------------------
# mocked branch tests
# -----------------------------------------------------------------------------

test___open_target_linux_uses_xdg_open () {
    (
        setup_mock_path
        make_mock "${MOCK_BIN}" xdg-open <<'SH'
#!/usr/bin/env bash
printf 'xdg-open|%s\n' "$*" >> "${MOCK_LOG}"
SH
        sys::is_macos () { return 1; }
        sys::is_windows () { return 1; }
        sys::__open_target 'https://example.com' 'uri'
        assert_contains_line 'xdg-open|https://example.com' "$(cat "${MOCK_LOG}")"
    )
}
test___open_target_macos_uses_open () {
    (
        setup_mock_path
        make_mock "${MOCK_BIN}" open <<'SH'
#!/usr/bin/env bash
printf 'open|%s\n' "$*" >> "${MOCK_LOG}"
SH
        sys::is_macos () { return 0; }
        sys::is_windows () { return 1; }
        sys::__open_target '/tmp/file.txt' 'path'
        assert_contains_line 'open|/tmp/file.txt' "$(cat "${MOCK_LOG}")"
    )
}
test___open_target_windows_path_uses_cygpath_and_explorer () {
    (
        setup_mock_path
        make_mock "${MOCK_BIN}" cygpath <<'SH'
#!/usr/bin/env bash
printf 'cygpath|%s\n' "$*" >> "${MOCK_LOG}"
printf 'C:\\Temp\\file.txt\n'
SH
        make_mock "${MOCK_BIN}" explorer.exe <<'SH'
#!/usr/bin/env bash
printf 'explorer|%s\n' "$*" >> "${MOCK_LOG}"
SH
        sys::is_macos () { return 1; }
        sys::is_windows () { return 0; }
        sys::__open_target '/tmp/file.txt' 'path'
        assert_contains_line 'cygpath|-aw /tmp/file.txt' "$(cat "${MOCK_LOG}")"
        assert_contains_line 'explorer|C:\Temp\file.txt' "$(cat "${MOCK_LOG}")"
    )
}
test___open_target_windows_uri_falls_back_to_cmd_start () {
    (
        setup_mock_path
        make_mock "${MOCK_BIN}" cmd.exe <<'SH'
#!/usr/bin/env bash
printf 'cmd|%s\n' "$*" >> "${MOCK_LOG}"
SH
        sys::is_macos () { return 1; }
        sys::is_windows () { return 0; }
        sys::__open_target 'https://example.com' 'uri'
        assert_contains_line 'cmd|/C start  https://example.com' "$(cat "${MOCK_LOG}")"
    )
}
test_windows_groups_and_users_native_branches_via_mocks () {
    (
        setup_mock_path
        make_mock "${MOCK_BIN}" powershell.exe <<'SH'
#!/usr/bin/env bash
case "$*" in
    *Get-LocalGroupMember*) printf 'alice\nbob\n' ;;
    *Get-LocalUser*) printf 'alice\nbob\n' ;;
    *Get-LocalGroup*) printf 'Users\nAdministrators\n' ;;
    *) exit 1 ;;
esac
SH
        sys::is_windows () { return 0; }
        sys::is_linux () { return 1; }
        sys::is_macos () { return 1; }
        assert_contains_line 'Users' "$(sys::groups)"
        assert_contains_line 'alice' "$(sys::users)"
        assert_contains_line 'alice' "$(sys::users 'Users')"
        sys::ingroup 'Users' 'alice'
    )
}
test_windows_gexists_via_powershell_mock () {
    (
        setup_mock_path
        make_mock "${MOCK_BIN}" powershell.exe <<'SH'
#!/usr/bin/env bash
exit 0
SH
        sys::is_windows () { return 0; }
        sys::is_linux () { return 1; }
        sys::is_macos () { return 1; }
        sys::gexists 'Users'
    )
}

# -----------------------------------------------------------------------------
# platform and env
# -----------------------------------------------------------------------------

test_platform_detection_real_sanity () {
    assert_non_empty "$(sys::name 2>/dev/null || true)" 'name must not be empty'
    assert_non_empty "$(sys::family 2>/dev/null || true)" 'family must not be empty'
    assert_non_empty "$(sys::runtime 2>/dev/null || true)" 'runtime must not be empty'
    assert_non_empty "$(sys::arch 2>/dev/null || true)" 'arch must not be empty'
}
test_is_linux_detects_linux_via_uname () { ( setup_mock_path; make_mock "${MOCK_BIN}" uname <<'SH'
#!/usr/bin/env bash
printf 'Linux\n'
SH
OSTYPE=''; sys::is_linux ); }
test_is_macos_detects_darwin_via_uname () { ( setup_mock_path; make_mock "${MOCK_BIN}" uname <<'SH'
#!/usr/bin/env bash
printf 'Darwin\n'
SH
OSTYPE=''; sys::is_macos ); }
test_is_wsl_detects_env_and_rejects_windows () { ( WSL_DISTRO_NAME='Ubuntu'; sys::is_wsl; assert_false 'wsl must not be windows' sys::is_windows; ); }
test_is_msys_and_is_gitbash_detect_environment () { ( MSYSTEM='MINGW64'; GitInstallRoot='C:/Program Files/Git'; sys::is_msys; sys::is_gitbash; ); }
test_is_cygwin_detects_ostype () { ( OSTYPE='cygwin'; sys::is_cygwin; ); }
test_is_unix_and_is_posix_have_expected_relationship () { if sys::is_linux || sys::is_macos; then sys::is_unix; sys::is_posix; else sys::is_unix || true; sys::is_posix || true; fi; }
test_ci_name_and_is_ci_behavior () {
    local v=""
    (
        unset CI GITHUB_ACTIONS GITLAB_CI JENKINS_URL BUILDKITE CIRCLECI TRAVIS APPVEYOR TF_BUILD BITBUCKET_BUILD_NUMBER TEAMCITY_VERSION DRONE SEMAPHORE CODEBUILD_BUILD_ID
        v="$(sys::ci_name 2>/dev/null || true)"
        assert_eq 'none' "${v}"
        assert_false 'is_ci must be false outside CI' sys::is_ci
    )
    (
        GITHUB_ACTIONS='true'
        v="$(sys::ci_name)"
        assert_eq 'github' "${v}"
        sys::is_ci
    )
}
test_is_ci_pull_push_tag_flags () {
    ( GITHUB_ACTIONS='true'; GITHUB_EVENT_NAME='pull_request'; sys::is_ci_pull; assert_false 'pull request is not push' sys::is_ci_push; )
    ( GITHUB_ACTIONS='true'; GITHUB_EVENT_NAME='push'; sys::is_ci_push; assert_false 'push is not pull' sys::is_ci_pull; )
    ( GITHUB_REF_TYPE='tag'; sys::is_ci_tag; )
}
test_is_gui_terminal_interactive_headless_real_or_mocked () {
    sys::is_terminal || true
    sys::is_interactive || true
    sys::is_gui || true
    sys::is_headless || true
    ( sys::is_linux () { return 0; }; sys::is_macos () { return 1; }; sys::is_windows () { return 1; }; DISPLAY=':0'; unset WAYLAND_DISPLAY SSH_CONNECTION SSH_CLIENT SSH_TTY CI; sys::is_gui; assert_false 'gui session should not be headless' sys::is_headless; )
    ( sys::is_linux () { return 0; }; sys::is_macos () { return 1; }; sys::is_windows () { return 1; }; unset DISPLAY WAYLAND_DISPLAY; assert_false 'linux without display should not be gui' sys::is_gui; sys::is_headless; )
}
test_is_container_smoke () { sys::is_container || true; }
test_name_family_runtime_distro_manager_arch_values () {
    assert_non_empty "$(sys::name 2>/dev/null || true)"
    assert_non_empty "$(sys::family 2>/dev/null || true)"
    assert_non_empty "$(sys::runtime 2>/dev/null || true)"
    assert_non_empty "$(sys::arch 2>/dev/null || true)"
    sys::distro >/dev/null 2>&1 || true
    sys::manager >/dev/null 2>&1 || true
}
test_arch_normalizes_common_aliases () {
    ( setup_mock_path; make_mock "${MOCK_BIN}" uname <<'SH'
#!/usr/bin/env bash
printf 'x86_64\n'
SH
assert_eq 'x64' "$(sys::arch)" )
    ( setup_mock_path; make_mock "${MOCK_BIN}" uname <<'SH'
#!/usr/bin/env bash
printf 'aarch64\n'
SH
assert_eq 'arm64' "$(sys::arch)" )
}

# -----------------------------------------------------------------------------
# open wrapper
# -----------------------------------------------------------------------------

test_open_path_branch_calls_open_target_with_path_kind () {
    local dir="" file="" out=""
    dir="$(new_test_dir)"
    file="${dir}/sample.txt"
    printf 'x\n' > "${file}"
    (
        sys::__open_target () { printf '%s|%s\n' "$1" "$2"; }
        out="$(sys::open "${file}")"
        assert_eq "${file}|path" "${out}"
    )
}
test_open_uri_branch_normalizes_then_calls_open_target () { ( sys::__open_target () { printf '%s|%s\n' "$1" "$2"; }; assert_eq 'https://example.com|uri' "$(sys::open 'example.com')"; ); }
test_open_command_branch_executes_command_with_arguments () {
    local dir="" out=""
    dir="$(new_test_dir)"
    out="${dir}/args.txt"
    (
        setup_mock_path
        export SYS_OPEN_OUT="${out}"
        make_mock "${MOCK_BIN}" fake-open-cmd <<'SH'
#!/usr/bin/env bash
printf '%s\n' "$*" > "${SYS_OPEN_OUT}"
SH
        sys::open fake-open-cmd alpha beta
        sleep 0.1 2>/dev/null || true
        assert_eq 'alpha beta' "$(cat "${out}")"
    )
}
test_open_rejects_invalid_target () { assert_false 'invalid target must fail' sys::open $'bad\nvalue'; }

# -----------------------------------------------------------------------------
# disk / memory
# -----------------------------------------------------------------------------

test_disk_metrics_are_numeric_and_consistent () {
    local dir="" total="" free="" used="" percent="" info="" size=""
    dir="$(new_test_dir)"
    printf 'payload
' > "${dir}/sample.txt"
    total="$(sys::disk_total "${dir}")"
    free="$(sys::disk_free "${dir}")"
    used="$(sys::disk_used "${dir}")"
    percent="$(sys::disk_percent "${dir}")"
    info="$(sys::disk_info "${dir}")"
    size="$(sys::disk_size "${dir}")"
    assert_regex "${total}" '^[0-9]+$'
    assert_regex "${free}" '^[0-9]+$'
    assert_regex "${used}" '^[0-9]+$'
    assert_regex "${percent}" '^[0-9]+$'
    assert_regex "${size}" '^[0-9]+$'
    assert_eq "${used}" "$(( total - free ))" 'disk used must equal total minus free'
    assert_num_le "${used}" "${total}"
    assert_num_le "${percent}" 100
    assert_num_ge "${size}" 1
    assert_eq "${total}" "$(get_info_value total "${info}")"
    assert_eq "${free}" "$(get_info_value free "${info}")"
    assert_eq "${used}" "$(get_info_value used "${info}")"
}
test_disk_size_reports_for_temp_dir () {
    local dir="" size=""
    dir="$(new_test_dir)"
    dd if=/dev/zero of="${dir}/blob.bin" bs=1024 count=8 >/dev/null 2>&1 || printf 'xxxxxxxx' > "${dir}/blob.bin"
    size="$(sys::disk_size "${dir}")"
    assert_regex "${size}" '^[0-9]+$'
    assert_num_ge "${size}" 1
}
test_memory_metrics_are_numeric_and_consistent_when_supported () {
    local total="" free="" used="" percent="" info=""
    total="$(sys::mem_total 2>/dev/null || true)"
    free="$(sys::mem_free 2>/dev/null || true)"
    [[ -n "${total}" && -n "${free}" ]] || { skip_now 'memory backend unavailable'; return $?; }
    used="$(sys::mem_used)"
    percent="$(sys::mem_percent)"
    info="$(sys::mem_info)"
    assert_regex "${total}" '^[0-9]+$'
    assert_regex "${free}" '^[0-9]+$'
    assert_regex "${used}" '^[0-9]+$'
    assert_regex "${percent}" '^[0-9]+$'
    assert_num_le "${used}" "${total}"
    assert_num_le "${percent}" 100
    assert_eq "${total}" "$(get_info_value total "${info}")"
}

# -----------------------------------------------------------------------------
# identity / users / groups
# -----------------------------------------------------------------------------

test_identity_functions_return_sane_values () {
    local uid_v="" gid_v="" uname_v="" gname_v="" uhome_v="" ushell_v=""
    uid_v="$(sys::uid 2>/dev/null || true)"
    gid_v="$(sys::gid 2>/dev/null || true)"
    uname_v="$(sys::uname 2>/dev/null || true)"
    gname_v="$(sys::gname 2>/dev/null || true)"
    uhome_v="$(sys::uhome 2>/dev/null || true)"
    ushell_v="$(sys::ushell 2>/dev/null || true)"
    [[ -n "${uid_v}" ]] && assert_regex "${uid_v}" '^[0-9]+$'
    [[ -n "${gid_v}" ]] && assert_regex "${gid_v}" '^[0-9]+$'
    assert_non_empty "${uname_v}" 'uname must not be empty'
    [[ -n "${gname_v}" ]] || true
    assert_non_empty "${uhome_v}" 'uhome must not be empty'
    assert_non_empty "${ushell_v}" 'ushell must not be empty'
}
test_users_and_groups_list_all_visible_identities () {
    local users_v="" groups_v="" me="" mygroup=""
    users_v="$(sys::users 2>/dev/null || true)"
    groups_v="$(sys::groups 2>/dev/null || true)"
    me="$(sys::uname 2>/dev/null || true)"
    mygroup="$(sys::gname 2>/dev/null || true)"
    assert_non_empty "${users_v}" 'sys::users must not be empty'
    assert_non_empty "${groups_v}" 'sys::groups must not be empty'
    [[ -n "${me}" ]] && assert_contains_line "${me}" "${users_v}" 'current user must appear in users()'
    [[ -n "${mygroup}" ]] && assert_contains_line "${mygroup}" "${groups_v}" 'current group must appear in groups()'
}
test_uexists_and_gexists_for_current_identity () {
    local me="" group=""
    me="$(sys::uname)"
    group="$(sys::gname 2>/dev/null || true)"
    assert_true 'current user must exist' sys::uexists "${me}"
    [[ -n "${group}" ]] && assert_true 'current group must exist' sys::gexists "${group}"
}
test_ugroup_and_ugroups_and_ingroup_consistency () {
    local me="" primary="" groups_v=""
    me="$(sys::uname)"
    primary="$(sys::ugroup "${me}")"
    groups_v="$(sys::ugroups "${me}" 2>/dev/null || true)"
    assert_non_empty "${primary}" 'ugroup must not be empty'
    [[ -n "${groups_v}" ]] && printf '%s\n' "${groups_v}" | grep -w -- "${primary}" >/dev/null 2>&1 || fail_now 'ugroups must contain primary group'
    assert_true 'ingroup must succeed for primary group' sys::ingroup "${primary}" "${me}"
}
test_gusers_matches_users_group_filter () {
    local group="" a="" b=""
    group="$(sys::gname 2>/dev/null || true)"
    [[ -n "${group}" ]] || { skip_now 'current group unavailable'; return $?; }
    a="$(sys::gusers "${group}" 2>/dev/null || true)"
    b="$(sys::users "${group}" 2>/dev/null || true)"
    assert_eq "${b}" "${a}" 'gusers must mirror users(group)'
}
test_users_group_filter_contains_current_user_for_primary_group () {
    local me="" group="" members=""
    me="$(sys::uname)"
    group="$(sys::gname 2>/dev/null || true)"
    [[ -n "${group}" ]] || { skip_now 'current group unavailable'; return $?; }
    members="$(sys::users "${group}" 2>/dev/null || true)"
    assert_non_empty "${members}" 'users(group) must not be empty'
    assert_contains_line "${me}" "${members}" 'current user must be in users(primary-group)'
}
test_ugroup_default_matches_current_user_group () { assert_eq "$(sys::ugroup "$(sys::uname)")" "$(sys::ugroup)" 'ugroup() must match current user group'; }
test_gexists_negative_and_uexists_negative () { assert_false 'missing user must fail' sys::uexists "missing_user_$(random_token)"; assert_false 'missing group must fail' sys::gexists "missing_group_$(random_token)"; }

# -----------------------------------------------------------------------------
# privilege / destructive
# -----------------------------------------------------------------------------

test_is_root_and_is_admin_smoke () { sys::is_root || true; sys::is_admin || true; }
test_addgroup_and_adduser_real_destructive () {
    local token="" group="" user="" users_in_group=""
    require_privileged_destructive || return $?
    token="$(random_token)"
    group="sysgrp_${token}"
    user="sysusr_${token}"
    cleanup_identity "${user}" "${group}" || true
    sys::addgroup "${group}"
    assert_true 'new group must exist after addgroup' sys::gexists "${group}"
    list_has_exact "${group}" "$(sys::groups 2>/dev/null || true)" || fail_now 'new group must appear in groups()'
    sys::adduser "${user}" "${group}"
    assert_true 'new user must exist after adduser' sys::uexists "${user}"
    users_in_group="$(sys::users "${group}" 2>/dev/null || true)"
    assert_contains_line "${user}" "${users_in_group}" 'created user must appear in users(group)'
    assert_true 'ingroup must succeed for created user' sys::ingroup "${group}" "${user}"
    cleanup_identity "${user}" "${group}"
}

main () {
    local fn=""
    while IFS= read -r fn || [[ -n "${fn}" ]]; do
        run_test "${fn}"
    done < <(collect_tests)
    printf '\nTotal : %s\n' "${TOTAL_COUNT}"
    printf 'Pass  : %s\n' "${PASS_COUNT}"
    printf 'Skip  : %s\n' "${SKIP_COUNT}"
    printf 'Fail  : %s\n' "${FAIL_COUNT}"
    (( FAIL_COUNT == 0 ))
}

if [[ "${SYS_MODE}" == 'single' ]]; then
    "${SYS_SINGLE_TEST}"
else
    main
fi
