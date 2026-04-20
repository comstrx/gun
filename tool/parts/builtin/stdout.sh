
log () {

    local IFS=' '

    (( $# )) || { printf '\n' >&2; return 0; }
    printf '%s\n' "$*" >&2

}
print () {

    local IFS=' '

    (( $# )) || { printf '\n'; return 0; }
    printf '%s\n' "$*"

}
eprint () {

    local IFS=' '

    (( $# )) || { printf '\n' >&2; return 0; }
    printf '%s\n' "$*" >&2

}
info () {

    local tag="💥"
    local IFS=' '

    (( $# )) || { printf '%s\n' "${tag}" >&2; return 0; }
    printf '%s %s\n' "${tag}" "$*" >&2

}
warn () {

    local tag="⚠️"
    local IFS=' '

    (( $# )) || { printf '%s\n' "${tag}" >&2; return 0; }
    printf '%s %s\n' "${tag}" "$*" >&2

}
error () {

    local tag="❌"
    local IFS=' '

    (( $# )) || { printf '%s\n' "${tag}" >&2; return 0; }
    printf '%s %s\n' "${tag}" "$*" >&2

}
success () {

    local tag="✅"
    local IFS=' '

    (( $# )) || { printf '%s\n' "${tag}" >&2; return 0; }
    printf '%s %s\n' "${tag}" "$*" >&2

}
die () {

    local msg="${1-}" code="${2:-1}"

    [[ "${code}" =~ ^[0-9]+$ ]] || code=1
    [[ -n "${msg}" ]] && error "${msg}"

    if [[ "${-}" == *i* ]]; then
        return "${code}"
    fi

    exit "${code}"

}
