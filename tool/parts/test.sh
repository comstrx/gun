
__test_resolve__ () {

    local want="${1:-}"

    [[ -n "${want}" ]] || return 1
    [[ -n "${__APP_TEST_MAP__[${want}]:-}" ]] || return 1

    printf '%s\n' "${__APP_TEST_MAP__[${want}]}"

}
__test_run__ () {

    local fn="" rc=0 pass=0 fail=0
    local -a tests=( "$@" )

    for fn in "${tests[@]}"; do

        printf '==> %s\n' "${fn}"

        if "${fn}" 2>/dev/null; then
            printf '[PASS]: %s\n' "${fn}"
            (( ++pass ))
        else
            printf '[FAIL]: %s\n' "${fn}" >&2
            (( ++fail ))
            rc=1
        fi

        printf '\n'

    done

    printf '[INFO]: total=%s pass=%s fail=%s\n' "${#tests[@]}" "${pass}" "${fail}"
    return "${rc}"

}
__test__ () {

    local target="" resolved=""

    if (( $# == 0 )); then
        __test_run__ "${__APP_TESTS_LIST__[@]}"
        return $?
    fi

    target="${1:-}"
    shift || true

    if ! resolved="$(__test_resolve__ "${target}" 2>/dev/null)"; then
        printf '[FAIL]: test not found: %s\n' "${target}" >&2
        printf '[INFO]: total=1 pass=0 fail=1\n' >&2
        return 1
    fi

    printf '==> %s\n' "${resolved}"

    if "${resolved}" "$@" 2>/dev/null; then
        printf '[PASS]: %s\n\n' "${resolved}"
        printf '[INFO]: total=1 pass=1 fail=0\n'
        return 0
    fi

    printf '[FAIL]: %s\n\n' "${resolved}" >&2
    printf '[INFO]: total=1 pass=0 fail=1\n' >&2
    return 1

}
__tests__ () {

    local fn=""

    for fn in "${__APP_TESTS_LIST__[@]}"; do
        printf '%s\n' "${fn}"
    done

}
