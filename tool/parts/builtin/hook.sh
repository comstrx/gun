
run_hooks () {

    local name="${1:-}" fn="" i=0
    [[ -n "${name}" ]] || return 1

    declare -n ref="${name}"

    for (( i=${#ref[@]}-1; i>=0; i-- )); do

        fn="${ref[$i]}"
        [[ -n "${fn}" ]] || continue

        if declare -F -- "${fn}" >/dev/null 2>&1; then "${fn}" || true
        else bash -c "${fn}" || true
        fi

    done

}

on_exit () {

    [[ -v __ON_EXIT_HOOKS__ ]] || declare -ag __ON_EXIT_HOOKS__=()

    local fn="${1:-}"
    [[ -n "${fn}" ]] || return 1

    __ON_EXIT_HOOKS__+=( "${fn}" )
    trap 'run_hooks __ON_EXIT_HOOKS__' EXIT

}
on_err () {

    [[ -v __ON_ERR_HOOKS__ ]] || declare -ag __ON_ERR_HOOKS__=()

    local fn="${1:-}"
    [[ -n "${fn}" ]] || return 1

    __ON_ERR_HOOKS__+=( "${fn}" )
    trap 'run_hooks __ON_ERR_HOOKS__' ERR

}
on_int () {

    [[ -v __ON_INT_HOOKS__ ]] || declare -ag __ON_INT_HOOKS__=()

    local fn="${1:-}"
    [[ -n "${fn}" ]] || return 1

    __ON_INT_HOOKS__+=( "${fn}" )
    trap 'run_hooks __ON_INT_HOOKS__' INT

}
on_term () {

    [[ -v __ON_TERM_HOOKS__ ]] || declare -ag __ON_TERM_HOOKS__=()

    local fn="${1:-}"
    [[ -n "${fn}" ]] || return 1

    __ON_TERM_HOOKS__+=( "${fn}" )
    trap 'run_hooks __ON_TERM_HOOKS__' TERM

}
on_hook () {

    on_exit "$@"
    on_err  "$@"
    on_int  "$@"
    on_term "$@"

}

cleanup_tmps () {

    [[ -v __TMP_FILES__ ]] || return 0

    local file=""

    for file in "${__TMP_FILES__[@]}"; do
        [[ -n "${file:-}" && ( -e "${file}" || -L "${file}" ) ]] || continue
        rm -rf -- "${file}" 2>/dev/null || true
    done

    __TMP_FILES__=()

}
tmp_file () {

    [[ -v __TMP_FILES__  ]] || declare -ag __TMP_FILES__=()
    [[ -v __TMP_HOOKED__ ]] || declare -g  __TMP_HOOKED__=0

    local ref_name="${1:-}" path="${2:-/tmp}" __mktmp_file__=""

    if [[ ! -d "${path}" ]]; then
        path="$(dirname -- "${path}")" || die "Failed to detect dirname of: ${path}"
    fi

    __mktmp_file__="$(mktemp "${path}/.out.tmp.XXXXXX")" || die "Failed to create temp file in dir: ${path}"
    __TMP_FILES__+=( "${__mktmp_file__}" )

    if (( ! __TMP_HOOKED__ )); then
        on_hook cleanup_tmps
        __TMP_HOOKED__=1
    fi
    if [[ -z "${ref_name}" ]]; then
        printf '%s\n' "${__mktmp_file__}"
        return 0
    fi

    local -n out_ref="${ref_name}"
    out_ref="${__mktmp_file__}"

}
