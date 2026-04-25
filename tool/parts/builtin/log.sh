# shellcheck disable=SC2030,SC2031

log::is_tty () {

    [[ -t 1 ]]

}
log::is_err_tty () {

    [[ -t 2 ]]

}
log::is_verbose () {

    [[ "${VERBOSE:-0}" == "1" || "${LOG_VERBOSE:-0}" == "1" ]]

}
log::is_quiet () {

    [[ "${QUIET:-0}" == "1" || "${LOG_QUIET:-0}" == "1" ]]

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
        trace)                printf '0' ;;
        debug)                printf '1' ;;
        info)                 printf '2' ;;
        ok|success|done|step) printf '2' ;;
        warn|warning)         printf '3' ;;
        err*|fail|fatal)      printf '4' ;;
        off|quiet|silent)     printf '9' ;;
        *)                    printf '2' ;;
    esac

}
log::enabled () {

    local level="${1:-info}" want=0 have=0

    if log::is_quiet; then
        case "${level}" in
            err*|fail|fatal) ;;
            *) return 1 ;;
        esac
    fi

    want="$(log::level_num "${level}")"
    have="$(log::level_num "${LOG_LEVEL:-info}")"

    (( want >= have ))

}

log::plain () {

    ( export NO_COLOR=1 LOG_COLOR=never; "$@" )

}
log::verbose () {

    ( export VERBOSE=1 LOG_VERBOSE=1; "$@" )

}
log::quiet () {

    ( export QUIET=1 LOG_QUIET=1; "$@" )

}
log::no_color () {

    ( export NO_COLOR=1 LOG_COLOR=never; "$@" )

}

log::color () {

    local code="${1:-}" text="${2-}"

    if ! log::supports_color || [[ -z "${code}" ]]; then printf '%s' "${text}"
    else printf '\033[%sm%s\033[0m' "${code}" "${text}"
    fi

}
log::strip () {

    sed -E $'s/\x1B\\[[0-9;]*[A-Za-z]//g'

}
log::timestamp () {

    date '+%Y-%m-%d %H:%M:%S' 2>/dev/null || printf ''

}
log::symbol () {

    local name="${1:-}"

    if log::supports_unicode && [[ "${LOG_EMOJIS:-0}" == "1" ]]; then

        case "${name}" in
            info)            printf 'ℹ ' ;;
            ok|success|done) printf '✅' ;;
            warn|warning)    printf '⚠️' ;;
            err*|fail|fatal) printf '❌' ;;
            debug)           printf '🐞' ;;
            trace)           printf '🔎' ;;
            step)            printf '🚀' ;;
            item)            printf '•' ;;
            *)               printf '%s' "${name}" ;;
        esac

    else

        case "${name}" in
            info)            printf 'i' ;;
            ok|success|done) printf '+' ;;
            warn|warning)    printf '!' ;;
            err*|fail|fatal) printf 'x' ;;
            debug)           printf '*' ;;
            trace)           printf '.' ;;
            step)            printf '>' ;;
            item)            printf '-' ;;
            *)               printf '%s' "${name}" ;;
        esac

    fi

}
log::emit () {

    local stream="${1:-2}" level="${2:-info}" color="${3:-}" symbol="${4:-}" msg="${5-}"
    local tag="" ts="" icon=""

    log::enabled "${level}" || return 0

    [[ "${LOG_TIMESTAMP:-0}" == "1" || "${LOG_TIME:-0}" == "1" ]] && ts="[$(log::timestamp)] "
    [[ "${LOG_SYMBOLS:-0}" == "1" ]] && icon="$(log::symbol "${symbol}") "
    [[ "${LOG_FLAGS:-1}" == "1" ]] && tag="[${level^^}] "

    if ! log::supports_color; then printf '%s%s%s%s\n' "${ts}" "${tag}" "${icon}" "${msg}" >&"${stream}"
    else printf '\033[2;37m%s\033[0m\033[%sm%s\033[0m%s%s\n' "${ts}" "${color}" "${tag}" "${icon}" "${msg}" >&"${stream}"
    fi

}

log::raw () {

    log::is_quiet && { cat >/dev/null; return 0; }
    cat

}
log::ln () {

    printf '\n'

}
log::print () {

    log::is_quiet && return 0
    printf '%s' "$*"

}
log::eprint () {

    printf '%s' "$*" >&2

}
log::green () {

    printf '%s' "$(log::color "92" "$*")"

}
log::blue () {

    printf '%s' "$(log::color "94" "$*")"

}
log::yellow () {

    printf '%s' "$(log::color "93" "$*")"

}
log::gray () {

    printf '%s' "$(log::color "2;37" "$*")"

}

log::println () {

    log::is_quiet && return 0
    printf '%s\n' "$*"

}
log::eprintln () {

    printf '%s\n' "$*" >&2

}
log::greenln () {

    printf '%s\n' "$(log::color "92" "$*")"

}
log::blueln () {

    printf '%s\n' "$(log::color "94" "$*")"

}
log::yellowln () {

    printf '%s\n' "$(log::color "93" "$*")"

}
log::grayln () {

    printf '%s\n' "$(log::color "2;37" "$*")"

}

log::info () {

    log::emit 2 "info" "96" "info" "$*"

}
log::ok () {

    log::emit 2 "ok" "92" "ok" "$*"

}
log::done () {

    log::emit 2 "done" "92" "done" "$*"

}
log::success () {

    log::ok "$@"

}
log::warn () {

    log::emit 2 "warn" "93" "warn" "$*"

}
log::error () {

    log::emit 2 "err" "1;91" "error" "$*"

}
log::debug () {

    if [[ "${DEBUG:-0}" == "1" ]]; then
        LOG_LEVEL=debug log::emit 2 "debug" "95" "debug" "$*"
        return 0
    fi

    [[ "${LOG_LEVEL:-}" == "debug" || "${LOG_LEVEL:-}" == "trace" ]] || return 0
    log::emit 2 "debug" "95" "debug" "$*"

}
log::trace () {

    if [[ "${TRACE:-0}" == "1" ]]; then
        LOG_LEVEL=trace log::emit 2 "trace" "37" "trace" "$*"
        return 0
    fi

    [[ "${LOG_LEVEL:-}" == "trace" ]] || return 0
    log::emit 2 "trace" "90" "trace" "$*"

}
log::step () {

    log::emit 2 "step" "94" "step" "$*"

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

log::hr () {

    local char="${1:--}" width="${2:-60}" line=""

    log::is_quiet && return 0

    [[ "${width}" =~ ^[0-9]+$ ]] || width=60
    (( width > 0 )) || width=60

    printf -v line '%*s' "${width}" ''

    line="${line// /${char:0:1}}"
    printf '%s\n' "${line}" >&2

}
log::pair () {

    local key="${1:-}" value="${2-}" width="${3:-18}"

    log::is_quiet && return 0
    [[ "${width}" =~ ^[0-9]+$ ]] || width=18

    if log::supports_color; then printf '%-*s : \033[37m%s\033[0m\n' "${width}" "${key}" "${value}" >&2
    else printf '%-*s : %s\n' "${width}" "${key}" "${value}" >&2
    fi

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
log::quote () {

    local line=""
    log::is_quiet && return 0

    while IFS= read -r line || [[ -n "${line}" ]]; do

        if log::supports_color; then printf '\033[90m│\033[0m %s\n' "${line}" >&2
        else printf '| %s\n' "${line}" >&2
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

log::title () {

    local msg="$*" width=0 line="" mark="*"

    log::is_quiet && return 0
    width=$(( ${#msg} + 2 ))

    printf -v line '%*s' "${width}" ''
    line="${line// /=}"

    log::supports_unicode && mark="▸"

    if log::supports_color; then
        printf '\n\033[1;96m%s\033[0m \033[1;97m%s\033[0m\n' "${mark}" "${msg}" >&2
        printf '\033[2;37m%s\033[0m\n' "${line}" >&2
    else
        printf '\n%s %s\n%s\n' "${mark}" "${msg}" "${line}" >&2
    fi

}
log::section () {

    local msg="$*"
    log::is_quiet && return 0

    if log::supports_color; then printf '\n\033[1;96m== %s ==\033[0m\n' "${msg}" >&2
    else printf '\n== %s ==\n' "${msg}" >&2
    fi

}
log::subsection () {

    local msg="$*"
    log::is_quiet && return 0

    if log::supports_color; then printf '\n\033[1;94m-- %s --\033[0m\n' "${msg}" >&2
    else printf '\n-- %s --\n' "${msg}" >&2
    fi

}
log::table () {

    local key="" value="" width="${1:-18}"

    shift || true
    [[ "${width}" =~ ^[0-9]+$ ]] || width=18

    while (( $# > 0 )); do

        key="${1:-}"
        value="${2-}"

        log::pair "${key}" "${value}" "${width}"

        if (( $# >= 2 )); then shift 2
        else shift
        fi

    done

}
log::status () {

    local status="${1:-}" msg="${2-}"

    case "${status}" in
        done)         log::done "${msg}" ;;
        ok|success)   log::ok "${msg}" ;;
        warn|warning) log::warn "${msg}" ;;
        err*|fail)    log::error "${msg}" ;;
        debug)        log::debug "${msg}" ;;
        trace)        log::trace "${msg}" ;;
        step)         log::step "${msg}" ;;
        info|"")      log::info "${msg}" ;;
        *)            log::info "${status} ${msg}" ;;
    esac

}

log::cmd () {

    local arg="" out="$" quoted=""

    log::is_quiet && return 0

    for arg in "$@"; do

        if [[ -z "${arg}" ]]; then quoted="''"
        elif [[ "${arg}" =~ ^[A-Za-z0-9_./:=@%+-]+$ ]]; then quoted="${arg}"
        elif [[ "${arg}" != *"'"* ]]; then quoted="'${arg}'"
        else printf -v quoted '%q' "${arg}"
        fi

        out+=" ${quoted}"

    done

    if log::supports_color; then printf '\033[2;37m%s\033[0m\n' "${out}" >&2
    else printf '%s\n' "${out}" >&2
    fi

}
log::run () {

    log::cmd "$@"
    "$@"

}
log::try () {

    local code=0

    log::cmd "$@"

    "$@"
    code=$?

    if (( code == 0 )); then
        log::ok "Command succeeded"
        return 0
    fi

    log::error "Command failed with exit code ${code}"
    return "${code}"

}

log::tty_save () {

    [[ -t 0 ]] || return 1

    command -v stty >/dev/null 2>&1 || return 1
    LOG_TTY_STATE="$(stty -g 2>/dev/null)" || return 1

}
log::tty_lock () {

    [[ -t 0 ]] || return 1

    command -v stty >/dev/null 2>&1 || return 1
    stty -echo -icanon min 0 time 0 2>/dev/null || return 1

}
log::tty_restore () {

    [[ -t 0 ]] || return 0
    [[ -n "${LOG_TTY_STATE:-}" ]] || return 0

    command -v stty >/dev/null 2>&1 || return 0
    stty "${LOG_TTY_STATE}" 2>/dev/null || true

    unset LOG_TTY_STATE

}
log::spinner () {

    local msg="${1:-Loading}" pid="" frame="" tmp="" code=0 i=0 locked=0
    local color="${LOG_SPINNER_COLOR:-96}" lock="${LOG_SPINNER_LOCK:-1}" line="${LOG_SPINNER_LINE:-0}"
    local interval="${LOG_SPINNER_INTERVAL:-0.08}"

    shift || true
    local -a frames=()

    [[ "${1:-}" == "--" ]] && { shift || true; }
    [[ "${interval}" =~ ^[0-9]+([.][0-9]+)?$ ]] || interval="0.08"

    (( $# == 0 )) && { log::error "spinner command or callback is required"; return 1; }
    log::is_quiet && { "$@"; return $?; }

    tmp="$(mktemp 2>/dev/null || printf '/tmp/log-spinner-%s-%s.log' "$$" "${RANDOM:-0}")"

    if log::supports_unicode; then frames=( '⠋' '⠙' '⠹' '⠸' '⠼' '⠴' '⠦' '⠧' '⠇' '⠏' )
    else frames=( "|" "/" "-" "\\" )
    fi

    [[ "${line}" == "1" ]] && printf '\n' >&2
    [[ "${lock}" == "1" ]] && log::tty_save && log::tty_lock && locked=1

    "$@" >"${tmp}" 2>&1 &
    pid=$!

    while kill -0 "${pid}" 2>/dev/null; do

        frame="${frames[$(( i % ${#frames[@]} ))]}"

        if log::supports_color; then printf '\r\033[%sm%s\033[0m %s' "${color}" "${frame}" "${msg}" >&2
        else printf '\r%s %s' "${frame}" "${msg}" >&2
        fi

        i=$(( i + 1 ))
        sleep "${interval}"

    done

    wait "${pid}"
    code=$?

    printf '\r\033[K' >&2
    (( locked == 1 )) && log::tty_restore

    if (( code == 0 )); then
        log::ok "${msg}"
    else
        log::error "${msg}"
        [[ -s "${tmp}" ]] && log::quote < "${tmp}"
    fi

    rm -f "${tmp}" 2>/dev/null || true
    [[ "${line}" == "1" ]] && printf '\n' >&2

    return "${code}"

}
log::progress () {

    local current="${1:-0}" total="${2:-100}" msg="${3:-Progress}" width="${4:-30}"
    local bar="" rest="" key="" locked=0 final=0 pct=0 filled=0 empty=0
    local color="${LOG_PROGRESS_COLOR:-92}" lock="${LOG_PROGRESS_LOCK:-1}" line="${LOG_PROGRESS_LINE:-0}"

    log::is_quiet && return 0

    case "${current,,}" in
        done*|complete*|finish*|stop*|end|ok) current="${total}"; final=1 ;;
    esac

    key="${msg}:${total}:${width}"

    [[ "${current}" == "0" || "${current}" == "1" ]] && unset LOG_PROGRESS_DONE_KEY
    (( final == 1 )) && [[ "${LOG_PROGRESS_DONE_KEY:-}" == "${key}" ]] && return 0

    [[ "${total}" =~ ^[0-9]+$ ]] || total=100
    [[ "${width}" =~ ^[0-9]+$ ]] || width=30
    [[ "${current}" =~ ^[0-9]+$ ]] || current=0

    (( total > 0 )) || total=100
    (( width > 0 )) || width=30
    (( current > total )) && current="${total}"

    [[ "${lock}" == "1" && ( "${current}" == "0" || "${current}" == "1" ) ]] && log::tty_save && log::tty_lock && locked=1
    [[ "${line}" == "1" && ( "${current}" == "0" || "${current}" == "1" ) ]] && printf '\n' >&2

    pct=$(( current * 100 / total ))
    filled=$(( current * width / total ))
    empty=$(( width - filled ))

    printf -v bar '%*s' "${filled}" ''
    bar="${bar// /█}"

    printf -v rest '%*s' "${empty}" ''
    rest="${rest// /░}"

    if ! log::supports_unicode; then
        bar="${bar//█/#}"
        rest="${rest//░/-}"
    fi

    if log::supports_color; then printf '\r%s \033[%sm[%s%s]\033[0m %s%%' "${msg}" "${color}" "${bar}" "${rest}" "${pct}" >&2
    else printf '\r%s [%s%s] %s%%' "${msg}" "${bar}" "${rest}" "${pct}" >&2
    fi

    if (( current >= total )); then

        printf '\n' >&2
        LOG_PROGRESS_DONE_KEY="${key}"

        [[ "${line}" == "1" ]] && printf '\n' >&2
        [[ "${lock}" == "1" ]] && log::tty_restore

    fi

}
