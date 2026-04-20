
map_keys () {

    local name="${1:-}" k=""
    [[ -n "${name}" ]] || return 1

    local -n ref="${name}"

    for k in "${!ref[@]}"; do
        printf '%s\n' "${k}"
    done

}
map_values () {

    local name="${1:-}" k=""
    [[ -n "${name}" ]] || return 1

    local -n ref="${name}"

    for k in "${!ref[@]}"; do
        printf '%s\n' "${ref[$k]}"
    done

}
map_has () {

    local name="${1:-}" key="${2-}"
    [[ -n "${name}" && -n "${key}" ]] || return 1

    local -n ref="${name}"
    [[ -n "${ref[$key]+x}" ]]

}
map_get () {

    local name="${1:-}" key="${2-}" def="${3-}"
    [[ -n "${name}" ]] || return 1

    local -n ref="${name}"

    if [[ -n "${ref[$key]+x}" ]]; then printf '%s' "${ref[$key]}"
    else printf '%s' "${def}"
    fi

}
map_set () {

    local name="${1:-}" key="${2-}" value="${3-}"
    [[ -n "${name}" && -n "${key}" ]] || return 1

    local -n ref="${name}"
    ref["${key}"]="${value}"

}
map_del () {

    local name="${1:-}" key="${2-}"
    [[ -n "${name}" && -n "${key}" ]] || return 1

    local -n ref="${name}"
    unset 'ref[$key]'

}
map_len () {

    local name="${1:-}"
    [[ -n "${name}" ]] || return 1

    local -n ref="${name}"
    printf '%s\n' "${#ref[@]}"

}
map_clear () {

    local name="${1:-}"
    [[ -n "${name}" ]] || return 1

    local -n ref="${name}"
    ref=()

}
