
# env::has, set, get, del, list

use () {

    local mod="${1:-}" root="" path="" file=""

    [[ -n "${mod}" ]] || return 1
    [[ -z "${root}" && -n "${ENTRY_FILE:-}" ]] && root="$(dirname "${ENTRY_FILE}")"
    [[ -z "${root}" && -n "${SOURCE_DIR:-}" ]] && root="${SOURCE_DIR}"
    [[ -z "${root}" && -n "${ROOT_DIR:-}" ]] && root="${ROOT_DIR}/src"
    [[ -z "${root}" ]] && root="${PWD}"

    path="${mod//::/\/}"
    file="${root%/}/${path}.sh"

    [[ -f "${file}" ]] || file="${root%/}/${path}/mod.sh"
    [[ -f "${file}" ]] || return 1

    [[ -z "${__BUILTIN_USE_MAP__+x}" ]] && { declare -gA __BUILTIN_USE_MAP__=(); }
    [[ -n "${__BUILTIN_USE_MAP__[$file]+x}" ]] && return 0
    __BUILTIN_USE_MAP__["$file"]=1

    source "${file}"

}
has_env () {

    local key="${1:-}"

    [[ -n "${key}" ]] || return 1
    [[ "${key}" =~ ^[a-zA-Z_][a-zA-Z0-9_]*$ ]] || return 1

    [[ -n "${!key+x}" ]]

}
get_env () {

    local key="${1:-}" def="${2-}"

    [[ -n "${key}" ]] || { printf '%s' "${def}"; return 0; }

    [[ "${key}" =~ ^[a-zA-Z_][a-zA-Z0-9_]*$ ]] || { printf '%s' "${def}"; return 0; }

    if [[ -n "${!key+x}" ]]; then printf '%s' "${!key}"
    else printf '%s' "${def}"
    fi

}
set_env () {

    local key="${1:-}" value="${2-}"

    [[ -n "${key}" ]] || return 1
    [[ "${key}" =~ ^[a-zA-Z_][a-zA-Z0-9_]*$ ]] || return 1

    declare -gx "${key}=${value}"

}
