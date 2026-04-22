
# type::int,float,char,str,list,dict,is_xxx,type::of

int () {

    local v="${1:-}" m=""

    case "${v,,}" in
        "" ) printf '%s' "0"; return 0 ;;
        true|yes|y|on) printf '%s' "1"; return 0 ;;
        false|no|n|off) printf '%s' "0"; return 0 ;;
    esac

    if [[ "${v}" =~ ^[[:space:]]*([+-]?[0-9]+) ]]; then
        printf '%s' "${BASH_REMATCH[1]}"
        return 0
    fi
    if [[ "${v}" =~ ^[[:space:]]*([+-]?([0-9]*\.[0-9]+)) ]]; then

        m="${BASH_REMATCH[1]}"
        m="${m%%.*}"
        [[ "${m}" == "" || "${m}" == "+" || "${m}" == "-" ]] && m="0"

        printf '%s' "${m}"
        return 0

    fi

    printf '%s' "0"

}
float () {

    local v="${1:-}" m=""

    case "${v,,}" in
        "" ) printf '%s' "0.0"; return 0 ;;
        true|yes|y|on) printf '%s' "1.0"; return 0 ;;
        false|no|n|off) printf '%s' "0.0"; return 0 ;;
    esac

    if [[ "${v}" =~ ^[[:space:]]*([+-]?([0-9]+([.][0-9]+)?|[.][0-9]+)) ]]; then

        m="${BASH_REMATCH[1]}"

        if [[ "${m}" == .* ]]; then
            printf '0%s' "${m}"
            return 0
        fi
        if [[ "${m}" == +.* ]]; then
            printf '+0%s' "${m:1}"
            return 0
        fi
        if [[ "${m}" == -.* ]]; then
            printf -- '-0%s' "${m:1}"
            return 0
        fi

        [[ "${m}" == *.* ]] || m="${m}.0"

        printf '%s' "${m}"
        return 0

    fi

    printf '%s' "0.0"

}
abs () {

    local v=""
    v="$(int "${1:-}")" || return 1

    if [[ "${v}" == -* ]]; then printf '%s' "${v#-}"
    else printf '%s' "${v#+}"
    fi

}
char () {

    local v="${1:-}"
    [[ -n "${v}" ]] || return 0
    printf '%s' "${v:0:1}"

}
bool () {

    local v="${1:-}"

    case "${v,,}" in
        1|true|yes|y|on) printf '%s' "1" ;;
        *)               printf '%s' "0" ;;
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

    [[ "${v}" =~ ^[[:space:]]*[+-]?([0-9]+\.[0-9]+|[0-9]+|[.][0-9]+|[0-9]+[.])[[:space:]]*$ ]]

}
is_char () {

    local v="${1:-}"
    (( ${#v} == 1 ))

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
is_number () {

    is_float "$@"

}
