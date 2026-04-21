
list_init () {

    local name="${1:-}" decl=""

    [[ "${name}" =~ ^[a-zA-Z_][a-zA-Z0-9_]*$ ]] || return 1

    if ! declare -p "${name}" >/dev/null 2>&1; then
        declare -g -a "${name}=()"
        return 0
    fi

    decl="$(declare -p "${name}" 2>/dev/null)" || return 1

    [[ "${decl}" =~ ^declare\ -[a-zA-Z]*a[a-zA-Z]*[[:space:]] ]]

}
list_len () {

    local name="${1:-}"

    list_init "${name}" || return 1

    local -n ref="${name}"
    printf '%s\n' "${#ref[@]}"

}
list_add () {

    local name="${1:-}"

    list_init "${name}" || return 1
    shift || true

    local -n ref="${name}"
    ref+=( "$@" )

}
list_pop () {

    local name="${1:-}" target="${2-}" last="" value=""

    list_init "${name}" || return 1

    local -n ref="${name}"
    (( ${#ref[@]} > 0 )) || return 1

    last=$(( ${#ref[@]} - 1 ))
    value="${ref[$last]}"
    unset 'ref[$last]'

    if [[ -n "${target}" ]]; then printf -v "${target}" '%s' "${value}"
    else printf '%s' "${value}"
    fi

}
list_shift () {

    local name="${1:-}" target="${2-}" value=""

    list_init "${name}" || return 1

    local -n ref="${name}"
    (( ${#ref[@]} > 0 )) || return 1

    value="${ref[0]}"
    ref=( "${ref[@]:1}" )

    if [[ -n "${target}" ]]; then printf -v "${target}" '%s' "${value}"
    else printf '%s' "${value}"
    fi

}
list_unshift () {

    local name="${1:-}"

    list_init "${name}" || return 1
    shift || true

    local -n ref="${name}"
    ref=( "$@" "${ref[@]}" )

}
list_get () {

    local name="${1:-}" index="${2-}" def="${3-}"

    list_init "${name}" || return 1
    [[ "${index}" =~ ^[0-9]+$ ]] || { printf '%s' "${def}"; return 0; }

    local -n ref="${name}"

    if [[ -n "${ref[$index]+x}" ]]; then printf '%s' "${ref[$index]}"
    else printf '%s' "${def}"
    fi

}
list_set () {

    local name="${1:-}" index="${2-}" value="${3-}" len=0

    list_init "${name}" || return 1
    [[ "${index}" =~ ^[0-9]+$ ]] || return 1

    local -n ref="${name}"
    len="${#ref[@]}"

    (( index <= len )) || return 1

    ref["${index}"]="${value}"

}
list_concat () {

    local name="${1:-}" other="${2:-}"

    list_init "${name}"  || return 1
    list_init "${other}" || return 1

    local -n ref="${name}"
    local -n src="${other}"

    ref+=( "${src[@]}" )

}
list_unique () {

    local name="${1:-}" x=""
    local -A seen=()
    local -a src=()
    local -a out=()

    list_init "${name}" || return 1

    local -n ref="${name}"
    src=( "${ref[@]}" )

    for x in "${src[@]}"; do

        [[ -v "seen[$x]" ]] && continue
        seen["$x"]=1
        out+=( "${x}" )

    done

    ref=( "${out[@]}" )

}
list_clear () {

    local name="${1:-}"

    list_init "${name}" || return 1

    local -n ref="${name}"
    ref=()

}
