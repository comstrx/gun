
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

    local s="${1-}" n="${2:-0}" out=""

    [[ "${n}" =~ ^[0-9]+$ ]] || return 1

    while (( n > 0 )); do

        (( n & 1 )) && out+="${s}"
        s+="${s}"
        n=$(( n >> 1 ))

    done

    printf '%s' "${out}"

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
str::pad_center () {

    local s="${1-}" width="${2:-0}" ch="${3:- }" need=0 left=0 right=0

    [[ "${width}" =~ ^[0-9]+$ ]] || return 1

    ch="${ch:0:1}"
    [[ -n "${ch}" ]] || ch=' '

    need=$(( width - ${#s} ))
    (( need > 0 )) || { printf '%s' "${s}"; return 0; }

    left=$(( need / 2 ))
    right=$(( need - left ))

    printf '%s%s%s' "$(str::repeat "${ch}" "${left}")" "${s}" "$(str::repeat "${ch}" "${right}")"

}
str::join_by () {

    local sep="${1-}" out="" x="" first=1
    shift || true

    for x in "$@"; do

        if (( first )); then
            out="${x}"
            first=0
        else
            out="${out}${sep}${x}"
        fi

    done

    printf '%s' "${out}"

}
str::wrap () {

    local s="${1-}" left="${2-}" right="${3-}"

    [[ -n "${right}" ]] || right="${left}"
    printf '%s%s%s' "${left}" "${s}" "${right}"

}

str::len () {

    local s="${1-}"
    printf '%s' "${#s}"

}
str::index () {

    local s="${1-}" part="${2-}" i=0 max=0 len=0

    [[ -n "${part}" ]] || { printf '0'; return 0; }

    len="${#part}"
    max=$(( ${#s} - len ))

    (( max >= 0 )) || return 1

    for (( i=0; i<=max; i++ )); do
        [[ "${s:i:len}" == "${part}" ]] && { printf '%s' "${i}"; return 0; }
    done

    return 1

}
str::index_ci () {

    local s="${1-}" part="${2-}"
    str::index "$(str::lower "${s}")" "$(str::lower "${part}")"

}
str::last_index () {

    local s="${1-}" part="${2-}" i=0 len=0

    [[ -n "${part}" ]] || { printf '%s' "${#s}"; return 0; }

    len="${#part}"
    (( ${#s} >= len )) || return 1

    for (( i=${#s}-len; i>=0; i-- )); do
        [[ "${s:i:len}" == "${part}" ]] && { printf '%s' "${i}"; return 0; }
    done

    return 1

}
str::last_index_ci () {

    local s="${1-}" part="${2-}"
    str::last_index "$(str::lower "${s}")" "$(str::lower "${part}")"

}
str::find () {

    str::index "$@"

}
str::find_ci () {

    str::index_ci "$@"

}
str::count () {

    local s="${1-}" part="${2-}" rest="" pos="" n=0 len=0

    [[ -n "${part}" ]] || { printf '0'; return 0; }

    rest="${s}"
    len="${#part}"

    while pos="$(str::index "${rest}" "${part}")"; do
        n=$(( n + 1 ))
        rest="${rest:$(( pos + len ))}"
    done

    printf '%s' "${n}"

}
str::lines_count () {

    local s="${1-}" n=0

    [[ -z "${s}" ]] && { printf '0'; return 0; }

    n="$(str::count "${s}" $'\n')" || return 1
    printf '%s' "$(( n + 1 ))"

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

    local s="${1-}" x="${2-}" pos=""

    [[ -n "${x}" ]] || { printf '%s' "${s}"; return 0; }
    pos="$(str::index "${s}" "${x}")" || { printf '%s' "${s}"; return 0; }

    printf '%s' "${s:0:pos}"

}
str::after () {

    local s="${1-}" x="${2-}" pos=""

    [[ -n "${x}" ]] || return 1
    pos="$(str::index "${s}" "${x}")" || return 1

    printf '%s' "${s:$(( pos + ${#x} ))}"

}
str::before_last () {

    local s="${1-}" x="${2-}" pos=""

    [[ -n "${x}" ]] || { printf '%s' "${s}"; return 0; }
    pos="$(str::last_index "${s}" "${x}")" || { printf '%s' "${s}"; return 0; }

    printf '%s' "${s:0:pos}"

}
str::after_last () {

    local s="${1-}" x="${2-}" pos=""

    [[ -n "${x}" ]] || return 1
    pos="$(str::last_index "${s}" "${x}")" || return 1

    printf '%s' "${s:$(( pos + ${#x} ))}"

}
str::between () {

    local s="${1-}" left="${2-}" right="${3-}" rest=""

    rest="$(str::after "${s}" "${left}")" || return 1
    str::before "${rest}" "${right}"

}
str::between_last () {

    local s="${1-}" left="${2-}" right="${3-}" rest=""

    rest="$(str::after_last "${s}" "${left}")" || return 1
    str::before_last "${rest}" "${right}"

}
str::replace () {

    local s="${1-}" from="${2-}" to="${3-}" rest="" out="" pos="" len=0

    [[ -n "${from}" ]] || { printf '%s' "${s}"; return 0; }

    rest="${s}"
    len="${#from}"

    while pos="$(str::index "${rest}" "${from}")"; do
        out+="${rest:0:pos}${to}"
        rest="${rest:$(( pos + len ))}"
    done

    printf '%s%s' "${out}" "${rest}"

}
str::replace_first () {

    local s="${1-}" from="${2-}" to="${3-}" pos=""

    [[ -n "${from}" ]] || { printf '%s' "${s}"; return 0; }
    pos="$(str::index "${s}" "${from}")" || { printf '%s' "${s}"; return 0; }

    printf '%s%s%s' "${s:0:pos}" "${to}" "${s:$(( pos + ${#from} ))}"

}
str::replace_last () {

    local s="${1-}" from="${2-}" to="${3-}" pos=""

    [[ -n "${from}" ]] || { printf '%s' "${s}"; return 0; }
    pos="$(str::last_index "${s}" "${from}")" || { printf '%s' "${s}"; return 0; }

    printf '%s%s%s' "${s:0:pos}" "${to}" "${s:$(( pos + ${#from} ))}"

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

    [[ -n "${prefix}" ]] || { printf '%s' "${s}"; return 0; }
    [[ "${s:0:${#prefix}}" == "${prefix}" ]] || { printf '%s' "${s}"; return 0; }

    printf '%s' "${s:${#prefix}}"

}
str::remove_suffix () {

    local s="${1-}" suffix="${2-}" start=0

    [[ -n "${suffix}" ]] || { printf '%s' "${s}"; return 0; }
    (( ${#s} >= ${#suffix} )) || { printf '%s' "${s}"; return 0; }

    start=$(( ${#s} - ${#suffix} ))
    [[ "${s:start}" == "${suffix}" ]] || { printf '%s' "${s}"; return 0; }

    printf '%s' "${s:0:start}"

}

str::words () {

    local s="${1-}" i=0 x="" next="" out="" prev_kind="" kind="" lx=""
    local -a words=()

    [[ -n "${s}" ]] || return 0

    for (( i=0; i<${#s}; i++ )); do

        x="${s:i:1}"
        next="${s:i+1:1}"

        if str::is_alnum "${x}"; then

            kind="lower"
            str::is_digit "${x}" && kind="digit"
            str::is_upper "${x}" && kind="upper"

            if [[ -n "${out}" ]]; then

                if [[ "${kind}" == "upper" && ( "${prev_kind}" == "lower" || "${prev_kind}" == "digit" ) ]]; then
                    words+=( "${out}" )
                    out=""
                elif [[ "${kind}" == "upper" && "${prev_kind}" == "upper" ]] && str::is_lower "${next}"; then
                    words+=( "${out}" )
                    out=""
                fi

            fi

            lx="$(str::lower "${x}")"
            out+="${lx}"
            prev_kind="${kind}"
            continue

        fi

        [[ -n "${out}" ]] && words+=( "${out}" )
        out=""
        prev_kind=""

    done

    [[ -n "${out}" ]] && words+=( "${out}" )
    ((${#words[@]} > 0)) && printf '%s\n' "${words[@]}"

}
str::title () {

    local s="${1-}" x="" out="" first=""

    while IFS= read -r x; do

        [[ -n "${x}" ]] || continue
        [[ -n "${out}" ]] && out+=' '

        first="$(str::upper "${x:0:1}")"
        out+="${first}${x:1}"

    done < <(str::words "${s}")

    printf '%s' "${out}"

}
str::camel () {

    local s="${1-}" x="" out="" first_word=1 first=""

    while IFS= read -r x; do

        [[ -n "${x}" ]] || continue

        if (( first_word )); then
            out+="${x}"
            first_word=0
        else
            first="$(str::upper "${x:0:1}")"
            out+="${first}${x:1}"
        fi

    done < <(str::words "${s}")

    printf '%s' "${out}"

}
str::pascal () {

    local s="${1-}" x="" out="" first=""

    while IFS= read -r x; do

        [[ -n "${x}" ]] || continue

        first="$(str::upper "${x:0:1}")"
        out+="${first}${x:1}"

    done < <(str::words "${s}")

    printf '%s' "${out}"

}
str::train () {

    local s="${1-}" x="" out="" first=""

    while IFS= read -r x; do

        [[ -n "${x}" ]] || continue
        [[ -n "${out}" ]] && out+='-'

        first="$(str::upper "${x:0:1}")"
        out+="${first}${x:1}"

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

    str::kebab "$@"

}
str::lower () {

    local s="${1-}"
    printf '%s' "${s}" | tr '[:upper:]' '[:lower:]'

}
str::upper () {

    local s="${1-}"
    printf '%s' "${s}" | tr '[:lower:]' '[:upper:]'

}
str::is_lower () {

    [[ "${1-}" =~ ^[a-z]$ ]]

}
str::is_upper () {

    [[ "${1-}" =~ ^[A-Z]$ ]]

}
str::is_alpha () {

    [[ "${1-}" =~ ^[A-Za-z]$ ]]

}
str::is_digit () {

    [[ "${1-}" =~ ^[0-9]$ ]]

}
str::is_alnum () {

    [[ "${1-}" =~ ^[A-Za-z0-9]$ ]]

}

str::capitalize () {

    local s="${1-}" first=""
    [[ -n "${s}" ]] || return 0

    first="$(str::upper "${s:0:1}")"
    printf '%s%s' "${first}" "${s:1}"

}
str::uncapitalize () {

    local s="${1-}" first=""
    [[ -n "${s}" ]] || return 0

    first="$(str::lower "${s:0:1}")"
    printf '%s%s' "${first}" "${s:1}"

}
str::swapcase () {

    local s="${1-}" out="" x="" i=0

    for (( i=0; i<${#s}; i++ )); do

        x="${s:i:1}"

        if str::is_upper "${x}"; then out+="$(str::lower "${x}")"
        elif str::is_lower "${x}"; then out+="$(str::upper "${x}")"
        else out+="${x}"
        fi

    done

    printf '%s' "${out}"

}

str::contains () {

    local s="${1-}" part="${2-}"

    [[ -n "${part}" ]] || return 1
    str::index "${s}" "${part}" >/dev/null

}
str::contains_ci () {

    local s="${1-}" part="${2-}"

    [[ -n "${part}" ]] || return 1
    str::index_ci "${s}" "${part}" >/dev/null

}
str::equals () {

    [[ "${1-}" == "${2-}" ]]

}
str::equals_ci () {

    local a="${1-}" b="${2-}"
    [[ "$(str::lower "${a}")" == "$(str::lower "${b}")" ]]

}
str::starts_with () {

    local s="${1-}" prefix="${2-}"

    [[ -n "${prefix}" ]] || return 1
    [[ "${s:0:${#prefix}}" == "${prefix}" ]]

}
str::ends_with () {

    local s="${1-}" suffix="${2-}" start=0

    [[ -n "${suffix}" ]] || return 1
    (( ${#s} >= ${#suffix} )) || return 1

    start=$(( ${#s} - ${#suffix} ))
    [[ "${s:start}" == "${suffix}" ]]

}
str::is_empty () {

    [[ -z "${1-}" ]]

}
str::is_blank () {

    local s="${1-}"
    [[ -z "${s//[[:space:]]/}" ]]

}

str::is_email () {

    [[ "${1-}" =~ ^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$ ]]

}
str::is_url () {

    [[ "${1-}" =~ ^https?://[^[:space:]]+$ ]]

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

    local s=""

    s="$(str::lower "${1-}")"

    case "${s}" in
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

str::chomp () {

    local s="${1-}"

    s="${s%$'\n'}"
    s="${s%$'\r'}"

    printf '%s' "${s}"

}
str::lines () {

    local s="${1-}"

    [[ -n "${s}" ]] || return 0
    printf '%s\n' "${s}"

}
str::split () {

    local s="${1-}" sep="${2-}" rest="" pos="" len=0

    [[ -n "${sep}" ]] || return 1

    rest="${s}"
    len="${#sep}"

    while pos="$(str::index "${rest}" "${sep}")"; do
        printf '%s\n' "${rest:0:pos}"
        rest="${rest:$(( pos + len ))}"
    done

    printf '%s\n' "${rest}"

}
str::ensure_prefix () {

    local s="${1-}" prefix="${2-}"

    [[ -n "${prefix}" ]] || { printf '%s' "${s}"; return 0; }
    str::starts_with "${s}" "${prefix}" && { printf '%s' "${s}"; return 0; }

    printf '%s%s' "${prefix}" "${s}"

}
str::ensure_suffix () {

    local s="${1-}" suffix="${2-}"

    [[ -n "${suffix}" ]] || { printf '%s' "${s}"; return 0; }
    str::ends_with "${s}" "${suffix}" && { printf '%s' "${s}"; return 0; }

    printf '%s%s' "${s}" "${suffix}"

}
str::quote () {

    printf '%q' "${1-}"

}
str::indent () {

    local s="${1-}" prefix="${2:-    }" line="" first=1

    while IFS= read -r line || [[ -n "${line}" ]]; do

        (( first )) || printf '\n'
        first=0
        printf '%s%s' "${prefix}" "${line}"

    done <<< "${s}"

}
