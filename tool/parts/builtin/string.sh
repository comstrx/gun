
str::ltrim () {

    local s="${1-}"

    s="${s#"${s%%[![:space:]]*}"}"
    printf '%s' "${s}"

}
str::rtrim () {

    local s="${1-}"

    s="${s%"${s##*[![:space:]]}"}"
    printf '%s' "${s}"

}
str::trim () {

    local s="${1-}"

    s="${s#"${s%%[![:space:]]*}"}"
    s="${s%"${s##*[![:space:]]}"}"

    printf '%s' "${s}"

}
str::repeat () {

    local s="${1-}" n="${2:-0}" i=0

    [[ "${n}" =~ ^[0-9]+$ ]] || return 1

    for (( i=0; i<n; i++ )); do
        printf '%s' "${s}"
    done

}
str::slice () {

    local s="${1-}" start="${2:-0}" count="${3-}"

    [[ "${start}" =~ ^-?[0-9]+$ ]] || return 1

    if [[ -n "${count}" ]]; then
        [[ "${count}" =~ ^[0-9]+$ ]] || return 1
        printf '%s' "${s:${start}:${count}}"
    else
        printf '%s' "${s:${start}}"
    fi

}
str::reverse () {

    local s="${1-}" out="" i=0

    for (( i=${#s}-1; i>=0; i-- )); do
        out+="${s:i:1}"
    done

    printf '%s' "${out}"

}
str::truncate () {

    local s="${1-}" max="${2:-0}" tail="${3:-...}"

    [[ "${max}" =~ ^[0-9]+$ ]] || return 1

    (( ${#s} <= max )) && { printf '%s' "${s}"; return 0; }
    (( max == 0 )) && return 0

    if (( ${#tail} >= max )); then
        printf '%s' "${tail:0:max}"
        return 0
    fi

    printf '%s%s' "${s:0:$(( max - ${#tail} ))}" "${tail}"

}
str::normalize () {

    local s="${1-}" sep="${2:-}" out="" x="" i=0 prev_sep=1

    sep="${sep:0:1}"
    [[ -n "${sep}" ]] || sep=' '

    for (( i=0; i<${#s}; i++ )); do

        x="${s:i:1}"

        if [[ "${x}" =~ [[:space:]] ]]; then

            (( prev_sep )) && continue

            out+="${sep}"
            prev_sep=1
            continue

        fi

        out+="${x}"
        prev_sep=0

    done

    [[ "${out}" == "${sep}"* ]] && out="${out#"${sep}"}"
    [[ "${out}" == *"${sep}" ]] && out="${out%"${sep}"}"

    printf '%s' "${out}"

}
str::pad_left () {

    local s="${1-}" width="${2:-0}" ch="${3:- }" need=0

    [[ "${width}" =~ ^[0-9]+$ ]] || return 1

    ch="${ch:0:1}"
    [[ -n "${ch}" ]] || ch=' '

    need=$(( width - ${#s} ))
    (( need > 0 )) || { printf '%s' "${s}"; return 0; }

    printf '%s%s' "$(str::repeat "${ch}" "${need}")" "${s}"

}
str::pad_right () {

    local s="${1-}" width="${2:-0}" ch="${3:- }" need=0

    [[ "${width}" =~ ^[0-9]+$ ]] || return 1

    ch="${ch:0:1}"
    [[ -n "${ch}" ]] || ch=' '

    need=$(( width - ${#s} ))
    (( need > 0 )) || { printf '%s' "${s}"; return 0; }

    printf '%s%s' "${s}" "$(str::repeat "${ch}" "${need}")"

}
str::join_by () {

    local sep="${1:-}" buf="" x=""
    shift || true

    for x in "$@"; do

        if [[ -z "${buf}" ]]; then buf="${x}"
        else buf="${buf}${sep}${x}"
        fi

    done

    printf '%s' "${buf}"

}
str::wrap () {

    local s="${1:-}" left="${2:-}" right="${3:-}"

    [[ -n "${right}" ]] || right="${left}"
    printf '%s%s%s' "${left}" "${s}" "${right}"

}

str::len () {

    printf '%s' "${#1}"

}
str::count () {

    local s="${1-}" part="${2-}" n=0 rest=""

    [[ -n "${part}" ]] || { printf '0'; return 0; }

    rest="${s}"

    while [[ "${rest}" == *"${part}"* ]]; do
        rest="${rest#*"${part}"}"
        (( n++ ))
    done

    printf '%s' "${n}"

}
str::lines_count () {

    local s="${1-}" n=0

    [[ -z "${s}" ]] && { printf '0'; return 0; }

    n="$(str::count "${s}" $'\n')" || return 1
    printf '%s' "$(( n + 1 ))"

}
str::index () {

    local s="${1-}" part="${2-}" prefix=""

    [[ -n "${part}" ]] || { printf '%s' "0"; return 0; }
    [[ "${s}" == *"${part}"* ]] || return 1

    prefix="${s%%"${part}"*}"
    printf '%s' "${#prefix}"

}
str::index_ci () {

    local s="${1-}" part="${2-}"
    str::index "${s,,}" "${part,,}"

}
str::last_index () {

    local s="${1-}" part="${2-}" suffix="" pos=0

    [[ -n "${part}" ]] || { printf '%s' "${#s}"; return 0; }
    [[ "${s}" == *"${part}"* ]] || return 1

    suffix="${s##*"${part}"}"
    pos=$(( ${#s} - ${#suffix} - ${#part} ))

    printf '%s' "${pos}"

}
str::last_index_ci () {

    local s="${1-}" part="${2-}"
    str::last_index "${s,,}" "${part,,}"

}
str::find () {

    local s="${1-}" part="${2-}" pos=""

    pos="$(str::index "${s}" "${part}")" || return 1
    printf '%s' "${pos}"

}
str::find_ci () {

    local s="${1-}" part="${2-}" pos=""

    pos="$(str::index_ci "${s}" "${part}")" || return 1
    printf '%s' "${pos}"

}

str::first_char () {

    local s="${1-}"

    [[ -n "${s}" ]] || return 0
    printf '%s' "${s:0:1}"

}
str::last_char () {

    local s="${1-}"

    [[ -n "${s}" ]] || return 0
    printf '%s' "${s: -1}"

}
str::before () {

    local s="${1-}" x="${2-}"

    [[ -n "${x}" && "${s}" == *"${x}"* ]] || { printf '%s' "${s}"; return 0; }
    printf '%s' "${s%%"${x}"*}"

}
str::after () {

    local s="${1-}" x="${2-}"

    [[ -n "${x}" && "${s}" == *"${x}"* ]] || return 1
    printf '%s' "${s#*"${x}"}"

}
str::before_last () {

    local s="${1-}" x="${2-}"

    [[ -n "${x}" && "${s}" == *"${x}"* ]] || { printf '%s' "${s}"; return 0; }
    printf '%s' "${s%"${x}"*}"

}
str::after_last () {

    local s="${1-}" x="${2-}"

    [[ -n "${x}" && "${s}" == *"${x}"* ]] || return 1
    printf '%s' "${s##*"${x}"}"

}
str::replace () {

    local s="${1-}" from="${2-}" to="${3-}"

    [[ -n "${from}" ]] || { printf '%s' "${s}"; return 0; }
    printf '%s' "${s//"${from}"/"${to}"}"

}
str::replace_first () {

    local s="${1-}" from="${2-}" to="${3-}"

    [[ -n "${from}" ]] || { printf '%s' "${s}"; return 0; }
    printf '%s' "${s/"${from}"/"${to}"}"

}
str::replace_last () {

    local s="${1-}" from="${2-}" to="${3-}"

    [[ -n "${from}" ]] || { printf '%s' "${s}"; return 0; }
    printf '%s' "${s/%"${from}"/"${to}"}"

}
str::remove () {

    str::replace "${1-}" "${2-}" ""

}
str::remove_first () {

    str::replace_first "${1-}" "${2-}" ""

}
str::remove_last () {

    str::replace_last "${1-}" "${2-}" ""

}
str::remove_prefix () {

    local s="${1-}" prefix="${2-}"

    [[ -n "${prefix}" && "${s}" == "${prefix}"* ]] || { printf '%s' "${s}"; return 0; }
    printf '%s' "${s#"${prefix}"}"

}
str::remove_suffix () {

    local s="${1-}" suffix="${2-}"

    [[ -n "${suffix}" && "${s}" == *"${suffix}" ]] || { printf '%s' "${s}"; return 0; }
    printf '%s' "${s%"${suffix}"}"

}

str::words () {

    local s="${1-}" i=0 x="" out="" prev=""
    local -a words=()

    [[ -n "${s}" ]] || return 0

    for (( i=0; i<${#s}; i++ )); do

        x="${s:i:1}"

        if [[ "${x}" =~ [A-Z] ]]; then

            if [[ -n "${out}" && "${prev}" =~ [a-z0-9] ]]; then
                words+=( "${out,,}" )
                out=""
            fi

            out+="${x,,}"
            prev="${x}"
            continue

        fi
        if [[ "${x}" =~ [a-z0-9] ]]; then

            out+="${x,,}"
            prev="${x}"
            continue

        fi

        [[ -n "${out}" ]] && words+=( "${out,,}" )

        out=""
        prev=""

    done

    [[ -n "${out}" ]] && words+=( "${out,,}" )

    printf '%s\n' "${words[@]}"

}
str::title () {

    local s="${1-}" x="" out="" first=""

    while IFS= read -r x; do

        [[ -n "${x}" ]] || continue
        [[ -n "${out}" ]] && out+=' '

        first="${x:0:1}"
        out+="${first^^}${x:1}"

    done < <(str::words "${s}")

    printf '%s' "${out}"

}
str::camel () {

    local s="${1-}" x="" out="" first_word=1 first=""

    while IFS= read -r x; do

        [[ -n "${x}" ]] || continue

        if (( first_word )); then

            out+="${x,,}"
            first_word=0

        else

            first="${x:0:1}"
            out+="${first^^}${x:1}"

        fi

    done < <(str::words "${s}")

    printf '%s' "${out}"

}
str::pascal () {

    local s="${1-}" x="" out="" first=""

    while IFS= read -r x; do

        [[ -n "${x}" ]] || continue

        first="${x:0:1}"
        out+="${first^^}${x:1}"

    done < <(str::words "${s}")

    printf '%s' "${out}"

}
str::train () {

    local s="${1-}" x="" out="" first=""

    while IFS= read -r x; do

        [[ -n "${x}" ]] || continue
        [[ -n "${out}" ]] && out+='-'

        first="${x:0:1}"
        out+="${first^^}${x:1}"

    done < <(str::words "${s}")

    printf '%s' "${out}"

}
str::kebab () {

    local s="${1-}" x="" out=""

    while IFS= read -r x; do

        [[ -n "${x}" ]] || continue
        [[ -n "${out}" ]] && out+='-'
        out+="${x}"

    done < <(str::words "${s}")

    printf '%s' "${out}"

}
str::snake () {

    local s="${1-}" x="" out=""

    while IFS= read -r x; do

        [[ -n "${x}" ]] || continue
        [[ -n "${out}" ]] && out+='_'
        out+="${x}"

    done < <(str::words "${s}")

    printf '%s' "${out}"

}
str::slug () {

    local s="${1-}" x="" out=""

    while IFS= read -r x; do

        [[ -n "${x}" ]] || continue
        x="${x,,}"
        x="${x//[^a-z0-9]/}"

        [[ -n "${x}" ]] || continue
        [[ -n "${out}" ]] && out+='-'
        out+="${x}"

    done < <(str::words "${s}")

    printf '%s' "${out}"

}
str::lower () {

    local s="${1-}"
    printf '%s' "${s,,}"

}
str::upper () {

    local s="${1-}"
    printf '%s' "${s^^}"

}
str::capitalize () {

    local s="${1-}" first=""
    [[ -n "${s}" ]] || return 0

    first="${s:0:1}"
    printf '%s%s' "${first^^}" "${s:1}"

}
str::uncapitalize () {

    local s="${1-}" first=""
    [[ -n "${s}" ]] || return 0

    first="${s:0:1}"
    printf '%s%s' "${first,,}" "${s:1}"

}
str::swapcase () {

    local s="${1-}" out="" x="" i=0

    for (( i=0; i<${#s}; i++ )); do

        x="${s:i:1}"

        if [[ "${x}" == "${x^^}" && "${x}" != "${x,,}" ]]; then out+="${x,,}"
        elif [[ "${x}" == "${x,,}" && "${x}" != "${x^^}" ]]; then out+="${x^^}"
        else out+="${x}"
        fi

    done

    printf '%s' "${out}"

}

str::contains () {

    local s="${1-}" part="${2-}"
    [[ "${s}" == *"${part}"* ]]

}
str::contains_ci () {

    local s="${1-}" part="${2-}"
    [[ "${s,,}" == *"${part,,}"* ]]

}
str::equals () {

    [[ "${1-}" == "${2-}" ]]

}
str::equals_ci () {

    local a="${1-}" b="${2-}"
    [[ "${a,,}" == "${b,,}" ]]

}
str::starts_with () {

    local s="${1-}" prefix="${2-}"
    [[ "${s}" == "${prefix}"* ]]

}
str::ends_with () {

    local s="${1-}" suffix="${2-}"
    [[ "${s}" == *"${suffix}" ]]

}
str::is_empty () {

    [[ -z "${1:-}" ]]

}
str::is_blank () {

    local s="${1:-}"
    [[ -z "${s//[[:space:]]/}" ]]

}

str::is_email () {

    [[ "${1:-}" =~ ^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$ ]]

}
str::is_url () {

    [[ "${1:-}" =~ ^https?://[^[:space:]]+$ ]]

}
str::is_int () {

    [[ "${1-}" =~ ^[+-]?[0-9]+$ ]]

}
str::is_uint () {

    [[ "${1-}" =~ ^[0-9]+$ ]]

}
str::is_float () {

    [[ "${1-}" =~ ^[+-]?([0-9]+([.][0-9]+)?|[.][0-9]+|[0-9]+[.])$ ]]

}
str::is_char () {

    local s="${1-}"
    (( ${#s} == 1 ))

}
str::is_bool () {

    local s="${1-}"

    case "${s,,}" in
        1|0|true|false|yes|no|y|n|on|off) return 0 ;;
        *) return 1 ;;
    esac

}
str::is_slug () {

    [[ "${1-}" =~ ^[a-z0-9]+(-[a-z0-9]+)*$ ]]

}
str::is_identifier () {

    [[ "${1-}" =~ ^[a-zA-Z_][a-zA-Z0-9_]*$ ]]

}
