# shellcheck shell=bash

log::is_tty () {

    [[ -t 1 ]]

}
log::is_err_tty () {

    [[ -t 2 ]]

}
log::is_quiet () {

    [[ "${QUIET:-0}" == "1" || "${LOG_QUIET:-0}" == "1" ]]

}
log::is_verbose () {

    [[ "${VERBOSE:-0}" == "1" || "${LOG_VERBOSE:-0}" == "1" ]]

}

log::supports_color () {

    [[ -n "${NO_COLOR:-}" ]] && return 1
    [[ "${TERM:-}" == "dumb" ]] && return 1

    case "${LOG_COLOR:-auto}" in
        never|0|false|no|off) return 1 ;;
        always|1|true|yes|on) return 0 ;;
        auto|"") [[ -t 1 || -t 2 ]] ;;
        *) [[ -t 1 || -t 2 ]] ;;
    esac

}
log::supports_unicode () {

    case "${LOG_ASCII:-0}" in
        1|true|yes|on) return 1 ;;
    esac

    case "${LC_ALL:-${LC_CTYPE:-${LANG:-}}}" in
        *UTF-8*|*utf8*|*UTF8*) return 0 ;;
    esac

    return 1

}

log::level_num () {

    case "${1:-info}" in
        trace) printf '0' ;;
        debug) printf '1' ;;
        info)  printf '2' ;;
        ok|success|done|step) printf '2' ;;
        warn|warning) printf '3' ;;
        error|fail|fatal) printf '4' ;;
        off|quiet|silent) printf '9' ;;
        *) printf '2' ;;
    esac

}
log::enabled () {

    local level="${1:-info}" want=0 have=0

    log::is_quiet && {
        case "${level}" in
            error|fail|fatal) ;;
            *) return 1 ;;
        esac
    }

    want="$(log::level_num "${level}")"
    have="$(log::level_num "${LOG_LEVEL:-info}")"

    (( want >= have ))

}

log::color () {

    local code="${1:-}" text="${2-}"

    if log::supports_color && [[ -n "${code}" ]]; then
        printf '\033[%sm%s\033[0m' "${code}" "${text}"
    else
        printf '%s' "${text}"
    fi

}
log::strip () {

    sed -E $'s/\x1B\\[[0-9;]*[A-Za-z]//g'

}

log::symbol () {

    local name="${1:-}"

    if log::supports_unicode; then
        case "${name}" in
            info) printf 'ℹ' ;;
            ok|success|done) printf '✓' ;;
            warn|warning) printf '!' ;;
            error|fail|fatal) printf '✗' ;;
            debug) printf '•' ;;
            trace) printf '·' ;;
            step) printf '›' ;;
            item) printf '•' ;;
            *) printf '%s' "${name}" ;;
        esac
    else
        case "${name}" in
            info) printf 'i' ;;
            ok|success|done) printf '+' ;;
            warn|warning) printf '!' ;;
            error|fail|fatal) printf 'x' ;;
            debug) printf '*' ;;
            trace) printf '.' ;;
            step) printf '>' ;;
            item) printf '-' ;;
            *) printf '%s' "${name}" ;;
        esac
    fi

}

log::timestamp () {

    [[ "${LOG_TIME:-0}" == "1" || "${LOG_TIMESTAMP:-0}" == "1" ]] || return 0
    date '+%Y-%m-%d %H:%M:%S' 2>/dev/null || printf ''

}

log::emit () {

    local stream="${1:-2}" level="${2:-info}" color="${3:-}" symbol="${4:-}" msg="${5-}"
    local tag="" ts="" icon=""

    log::enabled "${level}" || return 0

    tag="[${level^^}]"
    icon="$(log::symbol "${symbol}")"
    ts="$(log::timestamp)"

    if [[ -n "${ts}" ]]; then
        if log::supports_color; then
            printf '\033[90m%s\033[0m ' "${ts}" >&"${stream}"
        else
            printf '%s ' "${ts}" >&"${stream}"
        fi
    fi

    if log::supports_color; then
        printf '\033[%sm%s\033[0m %s %s\n' "${color}" "${tag}" "${icon}" "${msg}" >&"${stream}"
    else
        printf '%s %s %s\n' "${tag}" "${icon}" "${msg}" >&"${stream}"
    fi

}

log::print () {

    log::is_quiet && return 0
    printf '%s' "$*"

}
log::line () {

    log::is_quiet && return 0
    printf '%s\n' "$*"

}
log::raw () {

    log::is_quiet && return 0
    cat

}
log::err () {

    printf '%s\n' "$*" >&2

}

log::info () {

    log::emit 2 "info" "36" "info" "$*"

}
log::ok () {

    log::emit 2 "ok" "32" "ok" "$*"

}
log::success () {

    log::ok "$@"

}
log::done () {

    log::emit 2 "done" "32" "done" "$*"

}
log::warn () {

    log::emit 2 "warn" "33" "warn" "$*"

}
log::warning () {

    log::warn "$@"

}
log::error () {

    log::emit 2 "error" "31" "error" "$*"

}
log::fail () {

    log::error "$@"

}
log::debug () {

    if [[ "${DEBUG:-0}" == "1" ]]; then
        LOG_LEVEL=debug log::emit 2 "debug" "35" "debug" "$*"
        return 0
    fi

    [[ "${LOG_LEVEL:-}" == "debug" || "${LOG_LEVEL:-}" == "trace" ]] || return 0
    log::emit 2 "debug" "35" "debug" "$*"

}
log::trace () {

    if [[ "${TRACE:-0}" == "1" ]]; then
        LOG_LEVEL=trace log::emit 2 "trace" "90" "trace" "$*"
        return 0
    fi

    [[ "${LOG_LEVEL:-}" == "trace" ]] || return 0
    log::emit 2 "trace" "90" "trace" "$*"

}
log::step () {

    log::emit 2 "step" "34" "step" "$*"

}

log::fatal () {

    local code=1

    if [[ "${1:-}" =~ ^[0-9]+$ ]]; then
        code="${1}"
        shift || true
    fi

    log::error "$*"
    return "${code}"

}
log::die () {

    local code=1

    if [[ "${1:-}" =~ ^[0-9]+$ ]]; then
        code="${1}"
        shift || true
    fi

    log::error "$*"
    exit "${code}"

}

log::title () {

    local msg="$*" width=0 line=""

    log::is_quiet && return 0

    width="${#msg}"
    printf -v line '%*s' "${width}" ''
    line="${line// /=}"

    if log::supports_color; then
        printf '\n\033[1;37m%s\033[0m\n' "${msg}" >&2
        printf '\033[90m%s\033[0m\n' "${line}" >&2
    else
        printf '\n%s\n%s\n' "${msg}" "${line}" >&2
    fi

}
log::section () {

    local msg="$*"

    log::is_quiet && return 0

    if log::supports_color; then
        printf '\n\033[1;36m== %s ==\033[0m\n' "${msg}" >&2
    else
        printf '\n== %s ==\n' "${msg}" >&2
    fi

}
log::subsection () {

    local msg="$*"

    log::is_quiet && return 0

    if log::supports_color; then
        printf '\n\033[1;34m-- %s --\033[0m\n' "${msg}" >&2
    else
        printf '\n-- %s --\n' "${msg}" >&2
    fi

}
log::hr () {

    local char="${1:--}" width="${2:-60}" line=""

    log::is_quiet && return 0

    [[ "${width}" =~ ^[0-9]+$ ]] || width=60
    (( width > 0 )) || width=60

    printf -v line '%*s' "${width}" ''
    line="${line// /${char:0:1}}"
    printf '%s\n' "${line}" >&2

}

log::kv () {

    local key="${1:-}" value="${2-}" width="${3:-18}"

    log::is_quiet && return 0
    [[ "${width}" =~ ^[0-9]+$ ]] || width=18

    if log::supports_color; then
        printf '\033[90m%-*s\033[0m : %s\n' "${width}" "${key}" "${value}" >&2
    else
        printf '%-*s : %s\n' "${width}" "${key}" "${value}" >&2
    fi

}
log::pair () {

    log::kv "$@"

}
log::list () {

    local item="" bullet=""

    log::is_quiet && return 0
    bullet="$(log::symbol item)"

    for item in "$@"; do
        printf '  %s %s\n' "${bullet}" "${item}" >&2
    done

}
log::item () {

    local bullet=""

    log::is_quiet && return 0
    bullet="$(log::symbol item)"

    printf '  %s %s\n' "${bullet}" "$*" >&2

}

log::cmd () {

    log::is_quiet && return 0

    if log::supports_color; then
        printf '\033[90m$ %s\033[0m\n' "$*" >&2
    else
        printf '$ %s\n' "$*" >&2
    fi

}
log::quote () {

    local line=""

    log::is_quiet && return 0

    while IFS= read -r line || [[ -n "${line}" ]]; do

        if log::supports_color; then
            printf '\033[90m│\033[0m %s\n' "${line}" >&2
        else
            printf '| %s\n' "${line}" >&2
        fi

    done

}
log::indent () {

    local n="${1:-2}" line="" pad=""

    [[ "${n}" =~ ^[0-9]+$ ]] || n=2
    printf -v pad '%*s' "${n}" ''

    while IFS= read -r line || [[ -n "${line}" ]]; do
        printf '%s%s\n' "${pad}" "${line}" >&2
    done

}

log::table () {

    local key="" value="" width="${1:-18}"

    shift || true
    [[ "${width}" =~ ^[0-9]+$ ]] || width=18

    while (( $# > 0 )); do

        key="${1:-}"
        value="${2-}"

        log::kv "${key}" "${value}" "${width}"

        if (( $# >= 2 )); then shift 2
        else shift
        fi

    done

}

log::status () {

    local status="${1:-}" msg="${2-}"

    case "${status}" in
        ok|success|done) log::ok "${msg}" ;;
        warn|warning) log::warn "${msg}" ;;
        error|fail) log::error "${msg}" ;;
        debug) log::debug "${msg}" ;;
        trace) log::trace "${msg}" ;;
        step) log::step "${msg}" ;;
        info|"") log::info "${msg}" ;;
        *) log::info "${status} ${msg}" ;;
    esac

}

log::run () {

    log::cmd "$*"
    "$@"

}
log::try () {

    local code=0

    log::cmd "$*"

    "$@"
    code=$?

    if (( code == 0 )); then
        log::ok "Command succeeded"
        return 0
    fi

    log::error "Command failed with exit code ${code}"
    return "${code}"

}

log::plain () {

    (
        # shellcheck disable=SC2030,SC2031
        export NO_COLOR=1
        # shellcheck disable=SC2030,SC2031
        export LOG_COLOR=never
        "$@"
    )

}
log::quiet () {

    (
        # shellcheck disable=SC2030,SC2031
        export QUIET=1
        # shellcheck disable=SC2030,SC2031
        export LOG_QUIET=1
        "$@"
    )

}
log::verbose () {

    (
        # shellcheck disable=SC2030,SC2031
        export VERBOSE=1
        # shellcheck disable=SC2030,SC2031
        export LOG_VERBOSE=1
        "$@"
    )

}
log::with_color () {

    (
        # shellcheck disable=SC2030,SC2031
        unset NO_COLOR
        # shellcheck disable=SC2030,SC2031
        export LOG_COLOR=always
        "$@"
    )

}
log::without_color () {

    (
        # shellcheck disable=SC2030,SC2031
        export NO_COLOR=1
        # shellcheck disable=SC2030,SC2031
        export LOG_COLOR=never
        "$@"
    )

}

