
int () {

    local v="${1:-}" m=""

    case "${v,,}" in
        "") printf '0'; return 0 ;;
        true|yes|y|on) printf '1'; return 0 ;;
        false|no|n|off) printf '0'; return 0 ;;
    esac

    if [[ "${v}" =~ ^[[:space:]]*([+-]?[0-9]+) ]]; then
        printf '%s' "${BASH_REMATCH[1]}"
        return 0
    fi

    if [[ "${v}" =~ ^[[:space:]]*([+-]?([0-9]*[.][0-9]+|[0-9]+[.])) ]]; then

        m="${BASH_REMATCH[1]}"
        m="${m%%.*}"

        [[ "${m}" == "" || "${m}" == "+" || "${m}" == "-" ]] && m="0"

        printf '%s' "${m}"
        return 0

    fi

    printf '0'

}
uint () {

    local v=""
    v="$(int "${1:-}")"

    if [[ "${v}" == -* ]]; then printf '0'
    else printf '%s' "${v#+}"
    fi

}
float () {

    local v="${1:-}" m=""

    case "${v,,}" in
        "") printf '0.0'; return 0 ;;
        true|yes|y|on) printf '1.0'; return 0 ;;
        false|no|n|off) printf '0.0'; return 0 ;;
    esac

    if [[ "${v}" =~ ^[[:space:]]*([+-]?([0-9]+([.][0-9]*)?|[.][0-9]+)) ]]; then

        m="${BASH_REMATCH[1]}"

        case "${m}" in
            .*)  m="0${m}" ;;
            +.*) m="+0${m:1}" ;;
            -.*) m="-0${m:1}" ;;
        esac

        [[ "${m}" == *.* ]] || m="${m}.0"

        printf '%s' "${m}"
        return 0

    fi

    printf '0.0'

}
number () {

    float "$@"

}
abs () {

    local v=""
    v="$(int "${1:-}")"

    if [[ "${v}" == -* ]]; then printf '%s' "${v#-}"
    else printf '%s' "${v#+}"
    fi

}
char () {

    local v="${1:-}"

    [[ -n "${v}" ]] || return 0
    printf '%s' "${v:0:1}"

}
str () {

    printf '%s' "${1:-}"

}
bool () {

    local v="${1:-}"

    case "${v,,}" in
        1|true|yes|y|on) printf '1' ;;
        *) printf '0' ;;
    esac

}

is_int () {

    local v="${1:-}"

    case "${v,,}" in
        true|yes|y|on|false|no|n|off) return 0 ;;
    esac

    [[ "${v}" =~ ^[[:space:]]*[+-]?[0-9]+[[:space:]]*$ ]]

}
is_uint () {

    local v="${1:-}"

    case "${v,,}" in
        true|yes|y|on|false|no|n|off) return 0 ;;
    esac

    [[ "${v}" =~ ^[[:space:]]*\+?[0-9]+[[:space:]]*$ ]]

}
is_float () {

    local v="${1:-}"

    case "${v,,}" in
        true|yes|y|on|false|no|n|off) return 0 ;;
    esac

    [[ "${v}" =~ ^[[:space:]]*[+-]?([0-9]+([.][0-9]*)?|[.][0-9]+)[[:space:]]*$ ]]

}
is_number () {

    is_float "$@"

}
is_char () {

    local v="${1:-}"

    (( ${#v} == 1 ))

}
is_str () {

    local name="${1:-}" meta=""

    if [[ -n "${name}" ]] && declare -p "${name}" >/dev/null 2>&1; then

        meta="$(declare -p "${name}" 2>/dev/null || true)"

        case "${meta}" in
            declare\ -a*|declare\ -A*) return 1 ;;
            *) return 0 ;;
        esac

    fi

    return 0

}
is_bool () {

    local v="${1:-}"

    case "${v,,}" in
        1|0|true|false|yes|no|y|n|on|off) return 0 ;;
        *) return 1 ;;
    esac

}
is_true () {

    local v="${1:-}"

    case "${v,,}" in
        1|true|yes|y|on) return 0 ;;
        *) return 1 ;;
    esac

}
is_false () {

    ! is_true "$@"

}
is_list () {

    local name="${1:-}" meta=""

    [[ -n "${name}" ]] || return 1

    meta="$(declare -p "${name}" 2>/dev/null || true)"
    [[ "${meta}" == declare\ -a* ]]

}
is_map () {

    local name="${1:-}" meta=""

    [[ -n "${name}" ]] || return 1

    meta="$(declare -p "${name}" 2>/dev/null || true)"
    [[ "${meta}" == declare\ -A* ]]

}

typeof () {

    local v="${1:-}" meta=""

    if [[ -n "${v}" ]] && declare -p "${v}" >/dev/null 2>&1; then

        meta="$(declare -p "${v}" 2>/dev/null || true)"

        case "${meta}" in
            declare\ -a*) printf 'list'; return 0 ;;
            declare\ -A*) printf 'map'; return 0 ;;
        esac

        v="${!v}"

    fi

    if [[ -z "${v}" ]]; then printf 'empty'
    elif is_bool "${v}"; then printf 'bool'
    elif is_int "${v}"; then printf 'int'
    elif is_float "${v}"; then printf 'float'
    elif is_char "${v}"; then printf 'char'
    else printf 'str'
    fi

}
defined () {

    local v="${1:-}"
    [[ -v "${v}" ]]

}
filled () {

    local v="${1:-}"
    [[ -n "${v}" ]]

}
missed () {

    local v="${1:-}"
    [[ ! -v "${v}" ]]

}
empty () {

    local v="${1:-}"
    [[ -z "${v}" ]]

}
