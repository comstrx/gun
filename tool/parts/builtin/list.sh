
list_len () {

    local name="${1:-}"
    [[ -n "${name}" ]] || return 1

    local -n ref="${name}"
    printf '%s\n' "${#ref[@]}"

}
list_add () {

    local name="${1:-}"
    [[ -n "${name}" ]] || return 1
    shift || true

    local -n ref="${name}"
    ref+=( "$@" )

}
list_pop () {

    local name="${1:-}" out="${2-}" i="" last="" value=""
    [[ -n "${name}" ]] || return 1

    local -n ref="${name}"

    (( ${#ref[@]} > 0 )) || return 1

    for i in "${!ref[@]}"; do
        [[ -z "${last}" || "${i}" -gt "${last}" ]] && last="${i}"
    done

    [[ -n "${last}" ]] || return 1

    value="${ref[$last]}"
    unset 'ref[$last]'

    if [[ -n "${out}" ]]; then printf -v "${out}" '%s' "${value}"
    else printf '%s' "${value}"
    fi

}
list_shift () {

    local name="${1:-}" out="${2-}"
    [[ -n "${name}" ]] || return 1

    local -n ref="${name}"
    (( ${#ref[@]} > 0 )) || return 1

    local value="${ref[0]}"
    ref=( "${ref[@]:1}" )

    if [[ -n "${out}" ]]; then printf -v "${out}" '%s' "${value}"
    else printf '%s' "${value}"
    fi

}
list_unshift () {

    local name="${1:-}"

    [[ -n "${name}" ]] || return 1
    shift || true

    local -n ref="${name}"
    ref=( "$@" "${ref[@]}" )

}
list_get () {

    local name="${1:-}" index="${2-}" def="${3-}"

    [[ -n "${name}" ]] || return 1
    [[ "${index}" =~ ^[0-9]+$ ]] || { printf '%s' "${def}"; return 0; }

    local -n ref="${name}"

    if [[ -n "${ref[$index]+x}" ]]; then printf '%s' "${ref[$index]}"
    else printf '%s' "${def}"
    fi

}
list_set () {

    local name="${1:-}" index="${2-}" value="${3-}"

    [[ -n "${name}" ]] || return 1
    [[ "${index}" =~ ^[0-9]+$ ]] || return 1

    local -n ref="${name}"
    ref["${index}"]="${value}"

}
list_concat () {

    local name="${1:-}" other="${2:-}"
    [[ -n "${name}" && -n "${other}" ]] || return 1

    local -n ref="${name}"
    local -n src="${other}"

    ref+=( "${src[@]}" )

}
list_unique () {

    local name="${1:-}"
    [[ -n "${name}" ]] || return 1

    local -n ref="${name}"

    local x=""
    local -A seen=()
    local -a out=()

    for x in "${ref[@]}"; do

        [[ -n "${seen[$x]+x}" ]] && continue

        seen["$x"]=1
        out+=( "${x}" )

    done

    ref=( "${out[@]}" )

}
list_clear () {

    local name="${1:-}"
    [[ -n "${name}" ]] || return 1

    local -n ref="${name}"
    ref=()

}
