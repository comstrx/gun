
match_use () {

    local line="${1:-}" file=""

    line="${line%$'\r'}"
    [[ "${line}" =~ ^[[:space:]]*use[[:space:]]+([A-Za-z_][A-Za-z0-9_.-]*(::[A-Za-z_][A-Za-z0-9_.-]*)*)[[:space:]]*([#].*)?$ ]] || return 1

    file="${BASH_REMATCH[1]}"
    [[ "${file}" != *..* ]] || return 1
    [[ "${file}" != *--* ]] || return 1
    [[ "${file}" != *.-* ]] || return 1
    [[ "${file}" != *-. ]] || return 1

    printf '%s\n' "${file}"

}
match_test () {

    local file="${1:-}" line="" fn="" mark=0 probe=""

    if [[ ! -f "${file}" ]]; then
        printf '[ERR]: file not found: %s\n' "${file}" >&2
        return 1
    fi

    while IFS= read -r line || [[ -n "${line}" ]]; do

        line="${line%$'\r'}"
        probe="${line}"
        probe="${probe//[[:space:]]/}"
        probe="${probe,,}"

        if [[ "${probe}" =~ ^(##?|#\#)@?(\[\[test\]\]|\[test\]|test)$ ]]; then

            mark=1
            continue

        fi
        if [[ "${line}" =~ ^[[:space:]]*(function[[:space:]]+)?([A-Za-z_][A-Za-z0-9_]*)[[:space:]]*\(\)[[:space:]]*\{ ]]; then

            fn="${BASH_REMATCH[2]}"

            if (( mark )) || [[ "${fn}" == test_* ]]; then
                printf '%s\n' "${fn}"
            fi

            mark=0
            continue

        fi

        [[ "${line}" =~ ^[[:space:]]*$ ]] && continue
        mark=0

    done < "${file}" || { printf '[ERR]: unable to load file: %s\n' "${file}" >&2; return 1; }

}

load_source () {

    local mod="${1:-}" path="" file=""

    if [[ -z "${mod}" ]]; then
        printf '[ERR]: missing module name\n' >&2
        return 1
    fi

    path="${ENTRY_FILE%/*}/${mod//::/\/}"
    file="${path%.sh}.sh"

    [[ -f "${file}" ]] || file="${path%.sh}/mod.sh"

    if [[ ! -f "${file}" ]]; then
        printf '[ERR]: module not found: %s\n' "${mod}" >&2
        return 1
    fi

    printf '%s\n' "${file}"

}
verify_entry () {

    local file="${1:-}" line=""

    if [[ ! -f "${file}" ]]; then
        printf '[ERR]: entry file not found: %s\n' "${file}" >&2
        return 1
    fi

    while IFS= read -r line || [[ -n "${line}" ]]; do

        line="${line%$'\r'}"
        [[ "${line}" =~ ^[[:space:]]*(function[[:space:]]+)?main[[:space:]]*\(\)[[:space:]]*\{[[:space:]]*([#].*)?$ ]] && return 0

    done < "${file}" || { printf '[ERR]: unable to read file: %s\n' "${file}" >&2; return 1; }

    printf '[ERR]: missing main function in: %s\n' "${file}" >&2
    return 1

}

extract_mods () {

    local file="${1:-}" entry="${2:-}" line="" mod="" dep=""

    if [[ ! -f "${file}" ]]; then
        printf '[ERR]: file not found: %s\n' "${file}" >&2
        return 1
    fi

    [[ -n "${APP_MODS["${file}"]:-}" ]] && return 0
    APP_MODS["${file}"]="loaded"

    while IFS= read -r line || [[ -n "${line}" ]]; do

        line="${line%$'\r'}"

        mod="$(match_use "${line}")" || continue
        dep="$(load_source "${mod}")" || return 1

        extract_mods "${dep}" || return 1

    done < "${file}" || { printf '[ERR]: unable to read file: %s\n' "${file}" >&2; return 1; }

    [[ "${file}" == "${entry}" ]] || APP_SRCS+=( "${file}" )

}
extract_tests () {

    local file="" fn=""
    local -A seen=() loaded=()

    for file in "$@"; do

        [[ -f "${file}" ]] || continue
        [[ -z "${loaded[${file}]:-}" ]] || continue

        loaded["${file}"]=1

        while IFS= read -r fn || [[ -n "${fn}" ]]; do

            [[ -n "${fn}" ]] || continue
            [[ -z "${seen[${fn}]:-}" ]] || continue

            seen["${fn}"]=1
            APP_TESTS+=( "${fn}" )

        done < <(fetch_tests "${file}") || return 1

    done

}
extract () {

    APP_MODS=()
    APP_SRCS=()
    APP_TESTS=()

    if [[ -f "${ENTRY_FILE}" ]]; then
        printf '[ERR]: invalid entry file: %s\n' "${ENTRY_FILE}" >&2
        return 1
    fi

    verify_entry  "${ENTRY_FILE}"                  || return 1
    extract_mods  "${ENTRY_FILE}" "${ENTRY_FILE}"  || return 1
    extract_tests "${APP_SRCS[@]}" "${ENTRY_FILE}" || return 1

}
