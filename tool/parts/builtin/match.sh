
assert () {

    local msg="${1:-assert failed}"
    shift || true

    (( $# )) || { error "${msg}"; return 1; }

    "$@" && return 0

    error "${msg}"
    return 1

}
assert_eq () {

    local want="${1-}" got="${2-}" msg="${3:-}"

    [[ -n "${msg}" ]] || msg="assert_eq failed: expected '${want}', got '${got}'"
    [[ "${want}" == "${got}" ]] && return 0

    error "${msg}"
    return 1

}
assert_ne () {

    local left="${1-}" right="${2-}" msg="${3:-}"

    [[ -n "${msg}" ]] || msg="assert_ne failed: both are '${left}'"
    [[ "${left}" != "${right}" ]] && return 0

    error "${msg}"
    return 1

}
