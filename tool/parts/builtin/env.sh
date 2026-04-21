
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
