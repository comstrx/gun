
map_init () {

    local name="${1:-}" decl=""

    [[ "${name}" =~ ^[a-zA-Z_][a-zA-Z0-9_]*$ ]] || return 1

    if ! declare -p "${name}" >/dev/null 2>&1; then
        declare -g -A "${name}=()"
        return 0
    fi

    decl="$(declare -p "${name}" 2>/dev/null)" || return 1

    [[ "${decl}" =~ ^declare\ -[a-zA-Z]*A[a-zA-Z]*[[:space:]] ]]

}
map_len () {

    local name="${1:-}"
    map_init "${name}" || return 1

    local -n ref="${name}"
    printf '%s\n' "${#ref[@]}"

}
map_has () {

    local name="${1:-}" key="${2-}"

    map_init "${name}" || return 1
    [[ -n "${key}" ]] || return 1

    local -n ref="${name}"
    [[ -n "${ref[$key]+x}" ]]

}
map_get () {

    local name="${1:-}" key="${2-}" def="${3-}"

    map_init "${name}" || return 1

    if [[ -z "${key}" ]]; then
        printf '%s' "${def}"
        return 0
    fi

    local -n ref="${name}"

    if [[ -n "${ref[$key]+x}" ]]; then printf '%s' "${ref[$key]}"
    else printf '%s' "${def}"
    fi

}
map_set () {

    local name="${1:-}" key="${2-}" value="${3-}"

    map_init "${name}" || return 1
    [[ -n "${key}" ]] || return 1

    local -n ref="${name}"
    ref["${key}"]="${value}"

}
map_set_once () {

    local name="${1:-}" key="${2-}" value="${3-}"

    map_init "${name}" || return 1
    [[ -n "${key}" ]] || return 1

    local -n ref="${name}"

    [[ -n "${ref[$key]+x}" ]] && return 0
    ref["${key}"]="${value}"

}
map_del () {

    local name="${1:-}" key="${2-}"

    map_init "${name}" || return 1
    [[ -n "${key}" ]] || return 1

    local -n ref="${name}"
    unset 'ref[$key]'

}
map_concat () {

    local dst_name="${1:-}" src_name="${2:-}" key=""

    map_init "${dst_name}" || return 1
    map_init "${src_name}" || return 1

    local -n dst="${dst_name}"
    local -n src="${src_name}"

    for key in "${!src[@]}"; do
        dst["${key}"]="${src[$key]}"
    done

}
map_copy () {

    local dst_name="${1:-}" src_name="${2:-}" key=""

    map_init "${dst_name}" || return 1
    map_init "${src_name}" || return 1

    local -n dst="${dst_name}"
    local -n src="${src_name}"

    dst=()

    for key in "${!src[@]}"; do
        dst["${key}"]="${src[$key]}"
    done

}
map_clear () {

    local name="${1:-}"

    map_init "${name}" || return 1

    local -n ref="${name}"
    ref=()

}
map_keys0 () {

    local name="${1:-}"

    map_init "${name}" || return 1

    local -n ref="${name}"
    (( ${#ref[@]} > 0 )) || return 0

    printf '%s\0' "${!ref[@]}" | LC_ALL=C sort -z

}
map_values0 () {

    local name="${1:-}" key=""

    map_init "${name}" || return 1

    while IFS= read -r -d '' key; do
        printf '%s\0' "$(map_get "${name}" "${key}")"
    done < <(map_keys0 "${name}")

}
map_items0 () {

    local name="${1:-}" key=""

    map_init "${name}" || return 1

    while IFS= read -r -d '' key; do
        printf '%s\0%s\0' "${key}" "$(map_get "${name}" "${key}")"
    done < <(map_keys0 "${name}")

}
map_keys () {

    local name="${1:-}" key=""

    map_init "${name}" || return 1

    while IFS= read -r -d '' key; do
        printf '%s\n' "${key}"
    done < <(map_keys0 "${name}")

}
map_values () {

    local name="${1:-}" key=""

    map_init "${name}" || return 1

    while IFS= read -r -d '' key; do
        printf '%s\n' "$(map_get "${name}" "${key}")"
    done < <(map_keys0 "${name}")

}
map_items () {

    local name="${1:-}" key=""

    map_init "${name}" || return 1

    while IFS= read -r -d '' key; do
        printf '%s\t%s\n' "${key}" "$(map_get "${name}" "${key}")"
    done < <(map_keys0 "${name}")

}
