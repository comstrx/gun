
use () {

    local mod="${1:-}" root="" path="" file="" dir="" base="" key="" loading="" last=0 code=0

    [[ -n "${mod}" ]] || return 1

    [[ -n "${ENTRY_FILE:-}" ]] && root="$(dirname -- "${ENTRY_FILE}")"

    [[ -z "${root}" && -n "${SOURCE_DIR:-}" ]] && root="${SOURCE_DIR}"
    [[ -z "${root}" && -n "${ROOT_DIR:-}" ]] && root="${ROOT_DIR}/src"
    [[ -z "${root}" ]] && root="${PWD}"

    path="${mod//::/\/}"

    case "${path}" in
        /*) file="${path}" ;;
        *)  file="${root%/}/${path}" ;;
    esac

    [[ "${file}" == *.sh ]] || file="${file}.sh"
    [[ -f "${file}" ]] || file="${root%/}/${path}/mod.sh"
    [[ -f "${file}" ]] || return 1

    dir="$(cd -- "$(dirname -- "${file}")" >/dev/null 2>&1 && pwd -P)" || return 1
    base="$(basename -- "${file}")"
    key="${dir}/${base}"

    declare -p __BUILTIN_USE_MAP__ >/dev/null 2>&1 || declare -gA __BUILTIN_USE_MAP__=()
    declare -p __BUILTIN_USE_STACK__ >/dev/null 2>&1 || declare -ga __BUILTIN_USE_STACK__=()

    [[ -n "${__BUILTIN_USE_MAP__[$key]+x}" ]] && return 0

    for loading in "${__BUILTIN_USE_STACK__[@]}"; do

        [[ "${loading}" == "${key}" ]] && return 1

    done

    __BUILTIN_USE_STACK__+=( "${key}" )

    # shellcheck source=/dev/null
    source "${key}"
    code=$?

    last=$(( ${#__BUILTIN_USE_STACK__[@]} - 1 ))

    (( last >= 0 )) && unset "__BUILTIN_USE_STACK__[${last}]"
    (( code == 0 )) || return "${code}"

    __BUILTIN_USE_MAP__["${key}"]=1

    return 0

}

not () {

    ! "$@"

}
default () {

    local v="${1-}" d="${2-}"

    if [[ -n "${v}" ]]; then printf '%s' "${v}"
    else printf '%s' "${d}"
    fi

}
coalesce () {

    local v=""

    for v in "$@"; do

        if [[ -n "${v}" ]]; then
            printf '%s' "${v}"
            return 0
        fi

    done

    return 1

}

assert_eq () {

    [[ "${1:-}" == "${2:-}" ]] && return 0
    return 1

}
assert_ne () {

    [[ "${1:-}" != "${2:-}" ]] && return 0
    return 1

}
