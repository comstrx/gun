
trim () {

    local s="${1-}"

    s="${s#"${s%%[![:space:]]*}"}"
    s="${s%"${s##*[![:space:]]}"}"

    printf '%s' "${s}"

}
lower () {

    printf '%s' "${1-}" | tr '[:upper:]' '[:lower:]'

}
upper () {

    printf '%s' "${1-}" | tr '[:lower:]' '[:upper:]'

}
title () {

    local s="${1-}" buf="" word=""

    for word in ${s}; do
        [[ -n "${buf}" ]] && buf+=' '
        buf+="$(capitalize "${word}")"
    done

    printf '%s' "${buf}"

}
capitalize () {

    local s="${1-}"

    [[ -n "${s}" ]] || return 0
    printf '%s%s' "${s:0:1^^}" "${s:1}"

}
repeat () {

    local s="${1-}" n="${2:-0}" i=0
    [[ "${n}" =~ ^[0-9]+$ ]] || return 1

    for (( i=0; i<n; i++ )); do
        printf '%s' "${s}"
    done

}
before () {

    local s="${1-}" x="${2-}"

    [[ -n "${x}" && "${s}" == *"${x}"* ]] || { printf '%s' "${s}"; return 0; }
    printf '%s' "${s%%"${x}"*}"

}
after () {

    local s="${1-}" x="${2-}"

    [[ -n "${x}" && "${s}" == *"${x}"* ]] || return 1
    printf '%s' "${s#*"${x}"}"

}
join_by () {

    local sep="${1-}" buf="" x=""
    shift || true

    for x in "$@"; do

        if [[ -z "${buf}" ]]; then buf="${x}"
        else buf="${buf}${sep}${x}"
        fi

    done

    printf '%s' "${buf}"

}
contains () {

    local s="${1-}" part="${2-}"
    [[ "${s}" == *"${part}"* ]]

}
starts_with () {

    local s="${1-}" prefix="${2-}"
    [[ "${s}" == "${prefix}"* ]]

}
ends_with () {

    local s="${1-}" suffix="${2-}"
    [[ "${s}" == *"${suffix}" ]]

}
is_email () {

    [[ "${1:-}" =~ ^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$ ]]

}
is_url () {

    [[ "${1:-}" =~ ^https?://[^[:space:]]+$ ]]

}
