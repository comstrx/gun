
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
