
merge_parts () {

    local file="${ROOT_DIR}/../${1:-}.sh"

    verify_file "${file}" || return 1

    if ! cat "${file}"; then
        printf '[ERR]: unable to cat file: %s\n' "${file}">&2
        return 1
    fi

}
merge_mods () {

    local path="" line="" printed=0

    for path in "${APP_SRCS[@]}" "${ENTRY_FILE}"; do

        printed=0

        verify_file "${path}" || return 1

        while IFS= read -r line || [[ -n "${line}" ]]; do

            match_use "${line}" >/dev/null && continue

            if (( ! printed )); then
                printf '__file_marker__ %q\n' "${path}"
                printed=1
            fi

            printf '%s\n' "${line%$'\r'}"

        done < "${path}" || { printf '[ERR]: unable to read file: %s\n' "${path}" >&2; return 1; }

        (( ! printed )) || printf '\n'

    done

}
merge_tests () {

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
merge () {

    merge_parts head    || return 1
    merge_parts builtin || return 1
    merge_mods          || return 1
    merge_tests         || return 1
    merge_parts test    || return 1
    merge_parts trace   || return 1
    merge_parts tail    || return 1

}
