
# proc::has, need, run, show, kill, chmod

has () {

    [[ -n "${1:-}" ]] || return 1
    command -v -- "${1:-}" >/dev/null 2>&1

}
has_any () {

    local x=""
    (( $# )) || return 1

    for x in "$@"; do
        has "${x}" && return 0
    done

    return 1

}
has_all () {

    local x=""
    (( $# )) || return 1

    for x in "$@"; do
        has "${x}" || return 1
    done

    return 0

}

need () {

    local cmd="${1:-}"

    has "${cmd}" && return 0
    die "Missing command: ${cmd}"

}
need_any () {

    local x=""
    (( $# )) || die "need_any: missing commands"

    for x in "$@"; do
        has "${x}" && return 0
    done

    die "Missing command from: $*"

}
need_all () {

    local x="" miss=0
    (( $# )) || die "need_all: missing commands"

    for x in "$@"; do

        has "${x}" || { error "Missing command: ${x}"; miss=1; }

    done

    (( miss == 0 )) || die "Missing required commands"

}

run () {

    (( $# )) || return 0
    "$@"

}
run_ok () {

    (( $# )) || return 1
    "$@" >/dev/null 2>&1

}
