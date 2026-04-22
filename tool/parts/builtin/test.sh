#!/usr/bin/env bash
set -Eeuo pipefail

source "$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" 2>/dev/null && pwd -P)/system.sh"
source "$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" 2>/dev/null && pwd -P)/user.sh"

declare -f sys::ugroup
declare -f sys::groups
declare -f sys::uexists
declare -f sys::gname

print_line () {

    printf '%s\n' "------------------------------------------------------------"

}
print_title () {

    print_line
    printf '[TEST] %s\n' "${1:-}"
    print_line

}
print_value () {

    local name="${1:-}" value="${2:-}"

    printf '%-28s : %s\n' "${name}" "${value}"

}
print_bool_call () {

    local name="${1:-}"

    shift || true

    if "$@" >/dev/null 2>&1; then
        printf '%-28s : true\n' "${name}"
    else
        printf '%-28s : false\n' "${name}"
    fi

}
print_call () {

    local name="${1:-}" out="" rc=0

    shift || true

    out="$("$@" 2>/dev/null)" || rc=$?

    if [[ -n "${out}" ]]; then
        printf '%-28s : %s\n' "${name}" "${out}"
    else
        printf '%-28s : <empty> (rc=%s)\n' "${name}" "${rc}"
    fi

}
print_block_call () {

    local name="${1:-}" out="" rc=0 first=1 line=""

    shift || true

    out="$("$@" 2>/dev/null)" || rc=$?

    if [[ -z "${out}" ]]; then
        printf '%-28s : <empty> (rc=%s)\n' "${name}" "${rc}"
        return
    fi

    while IFS= read -r line || [[ -n "${line}" ]]; do

        if (( first )); then
            printf '%-28s : %s\n' "${name}" "${line}"
            first=0
        else
            printf '%-28s   %s\n' "" "${line}"
        fi

    done <<< "${out}"

}
join_lines () {

    local first=1 line=""

    while IFS= read -r line || [[ -n "${line}" ]]; do

        [[ -n "${line}" ]] || continue

        if (( first )); then
            printf '%s' "${line}"
            first=0
        else
            printf ', %s' "${line}"
        fi

    done

    printf '\n'

}

test_env () {

    print_title "env"

    print_value "OSTYPE"               "${OSTYPE:-}"
    print_value "MSYSTEM"              "${MSYSTEM:-}"
    print_value "TERM_PROGRAM"         "${TERM_PROGRAM:-}"
    print_value "USER"                 "${USER:-}"
    print_value "USERNAME"             "${USERNAME:-}"
    print_value "HOME"                 "${HOME:-}"
    print_value "USERPROFILE"          "${USERPROFILE:-}"
    print_value "SHELL"                "${SHELL:-}"
    print_value "COMSPEC"              "${COMSPEC:-}"
    print_value "WSL_DISTRO_NAME"      "${WSL_DISTRO_NAME:-}"
    print_value "WSL_INTEROP"          "${WSL_INTEROP:-}"
    print_value "CI"                   "${CI:-}"
    print_value "GITHUB_ACTIONS"       "${GITHUB_ACTIONS:-}"

}
test_identity () {

    local user="" group=""

    print_title "identity"

    print_call      "sys::uid"         sys::uid
    print_call      "sys::uname"       sys::uname
    print_call      "sys::uhome"       sys::uhome
    print_call      "sys::ushell"      sys::ushell
    print_call      "sys::gid"         sys::gid
    print_call      "sys::gname"       sys::gname
    print_call      "sys::ugroup"      sys::ugroup

    user="$(sys::uname 2>/dev/null || true)"
    group="$(sys::ugroup 2>/dev/null || true)"

    printf '\n'

    print_bool_call "sys::uexists self"          sys::uexists "${user}"
    [[ -n "${group}" ]] && print_bool_call "sys::uexists self group" sys::uexists "${user}" "${group}"
    print_bool_call "sys::gexists self group"    sys::gexists "${group}"

}
test_lists () {

    local user="" group="" out=""

    print_title "lists"

    print_block_call "sys::groups"               sys::groups
    print_block_call "sys::users"                sys::users

    user="$(sys::uname 2>/dev/null || true)"
    group="$(sys::ugroup 2>/dev/null || true)"

    printf '\n'

    [[ -n "${user}"  ]] && print_block_call "sys::groups self"       sys::groups "${user}"
    [[ -n "${group}" ]] && print_block_call "sys::users self group"  sys::users  "${group}"

    printf '\n'

    out="$(sys::groups "${user}" 2>/dev/null | join_lines || true)"
    [[ -n "${out}" ]] && print_value "self groups joined" "${out}"

}
test_negative () {

    local fake_user="__user_test_missing__"
    local fake_group="__group_test_missing__"

    print_title "negative"

    print_bool_call "sys::uexists missing"       sys::uexists "${fake_user}"
    print_bool_call "sys::gexists missing"       sys::gexists "${fake_group}"
    print_block_call "sys::groups missing user"  sys::groups "${fake_user}"
    print_block_call "sys::users missing group"  sys::users  "${fake_group}"

}
test_cross_checks () {

    local user="" group="" groups_out="" users_out=""

    print_title "cross-checks"

    user="$(sys::uname 2>/dev/null || true)"
    group="$(sys::ugroup 2>/dev/null || true)"
    groups_out="$(sys::groups "${user}" 2>/dev/null || true)"
    users_out="$(sys::users "${group}" 2>/dev/null || true)"

    print_value "current user"  "${user}"
    print_value "current group" "${group}"

    if [[ -n "${user}" && -n "${group}" ]]; then

        if grep -Fqx -- "${group}" <<< "${groups_out}"; then
            print_value "group in user groups" "yes"
        else
            print_value "group in user groups" "no"
        fi

        if grep -Fqx -- "${user}" <<< "${users_out}"; then
            print_value "user in group users" "yes"
        else
            print_value "user in group users" "no"
        fi

    fi

}
test_mutation () {

    local run_mutation="${RUN_USER_MUTATION_TESTS:-0}"
    local test_user="${TEST_USER_NAME:-chatgpt_user_test}"
    local test_group="${TEST_GROUP_NAME:-chatgpt_group_test}"

    print_title "mutation"

    if [[ "${run_mutation}" != "1" ]]; then
        print_value "mutation tests" "skipped"
        print_value "hint" "RUN_USER_MUTATION_TESTS=1 to enable"
        return
    fi

    print_value "test user"  "${test_user}"
    print_value "test group" "${test_group}"

    printf '\n'

    print_bool_call "pre gexists"                sys::gexists "${test_group}"
    print_bool_call "pre uexists"                sys::uexists "${test_user}"

    printf '\n'

    if sys::addgroup "${test_group}" >/dev/null 2>&1; then
        print_value "sys::addgroup" "ok"
    else
        print_value "sys::addgroup" "fail"
    fi

    print_bool_call "post gexists"               sys::gexists "${test_group}"

    printf '\n'

    if sys::adduser "${test_user}" "${test_group}" >/dev/null 2>&1; then
        print_value "sys::adduser" "ok"
    else
        print_value "sys::adduser" "fail"
    fi

    print_bool_call "post uexists"               sys::uexists "${test_user}"
    print_bool_call "post uexists group"         sys::uexists "${test_user}" "${test_group}"
    print_block_call "post groups user"          sys::groups "${test_user}"
    print_block_call "post users group"          sys::users "${test_group}"

    printf '\n'

    if sys::deluser "${test_user}" "${test_group}" >/dev/null 2>&1; then
        print_value "sys::deluser" "ok"
    else
        print_value "sys::deluser" "fail"
    fi

    print_bool_call "after deluser exists"       sys::uexists "${test_user}"

    printf '\n'

    if sys::delgroup "${test_group}" "${test_user}" >/dev/null 2>&1; then
        print_value "sys::delgroup" "ok"
    else
        print_value "sys::delgroup" "fail"
    fi

    print_bool_call "after delgroup exists"      sys::gexists "${test_group}"

}
main () {

    print_title "user.sh integration test"

    test_env
    test_identity
    test_lists
    test_negative
    test_cross_checks
    test_mutation

    printf '\n'
    print_line
    printf '[DONE] all tests finished\n'
    print_line

}

main "$@"
