
test_meta () {

    local fn="" short=""
    local -A seen=()

    printf 'declare -ag __APP_TESTS_LIST__=(\n'

    for fn in "${APP_TESTS[@]}"; do
        printf '%q\n' "${fn}"
    done

    printf ')\n'

    printf 'declare -Ag __APP_TEST_MAP__=(\n'

    for fn in "${APP_TESTS[@]}"; do

        if [[ -z "${seen[${fn}]:-}" ]]; then

            seen["${fn}"]=1
            printf '[%q]=%q\n' "${fn}" "${fn}"

        fi
        if [[ "${fn}" == test_* && "${fn}" != test_ ]]; then

            short="${fn#test_}"

            if [[ -n "${short}" && -z "${seen[${short}]:-}" ]]; then
                seen["${short}"]=1
                printf '[%q]=%q\n' "${short}" "${fn}"
            fi

        fi

    done

    printf ')\n'

}
