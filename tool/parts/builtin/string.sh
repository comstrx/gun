
str::len () {

    local s="${1-}"
    printf '%s' "${#s}"

}
str::lower () {

    local s="${1-}"
    printf '%s' "${s,,}"

}
str::upper () {

    local s="${1-}"
    printf '%s' "${s^^}"

}
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
str::chomp () {

    local s="${1-}"

    s="${s%$'\n'}"
    s="${s%$'\r'}"

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
        return 0
    fi

    printf '%s' "${s:${start}}"

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

    local s="${1-}" sep="${2:- }" out="" x="" i=0 prev=1

    sep="${sep:0:1}"
    [[ -n "${sep}" ]] || sep=' '

    for (( i=0; i<${#s}; i++ )); do

        x="${s:i:1}"

        if [[ "${x}" =~ [[:space:]] ]]; then
            (( prev )) && continue
            out+="${sep}"
            prev=1
            continue
        fi

        out+="${x}"
        prev=0

    done

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
            out+="${sep}${x}"
        fi

    done

    printf '%s' "${out}"

}
str::wrap () {

    local s="${1-}" left="${2-}" right="${3-}"

    [[ -n "${right}" ]] || right="${left}"
    printf '%s%s%s' "${left}" "${s}" "${right}"

}
str::quote () {

    printf '%q' "${1-}"

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
    str::index "${s,,}" "${part,,}"

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
    str::last_index "${s,,}" "${part,,}"

}
str::find () {

    str::index "$@"

}
str::find_ci () {

    str::index_ci "$@"

}
str::contains () {

    local s="${1-}" part="${2-}"

    [[ -n "${part}" ]] || return 1
    [[ "${s}" == *"${part}"* ]]

}
str::contains_ci () {

    local s="${1-}" part="${2-}"

    [[ -n "${part}" ]] || return 1
    [[ "${s,,}" == *"${part,,}"* ]]

}
str::starts_with () {

    local s="${1-}" prefix="${2-}"

    [[ -n "${prefix}" ]] || return 1
    [[ "${s:0:${#prefix}}" == "${prefix}" ]]

}
str::starts_with_ci () {

    local s="${1-}" prefix="${2-}"

    [[ -n "${prefix}" ]] || return 1
    [[ "${s:0:${#prefix},,}" == "${prefix,,}" ]]

}
str::ends_with () {

    local s="${1-}" suffix="${2-}" start=0

    [[ -n "${suffix}" ]] || return 1
    (( ${#s} >= ${#suffix} )) || return 1

    start=$(( ${#s} - ${#suffix} ))
    [[ "${s:${start}}" == "${suffix}" ]]

}
str::ends_with_ci () {

    local s="${1-}" suffix="${2-}" start=0

    [[ -n "${suffix}" ]] || return 1
    (( ${#s} >= ${#suffix} )) || return 1

    start=$(( ${#s} - ${#suffix} ))
    [[ "${s:${start},,}" == "${suffix,,}" ]]

}
str::equals () {

    [[ "${1-}" == "${2-}" ]]

}
str::equals_ci () {

    local a="${1-}" b="${2-}"
    [[ "${a,,}" == "${b,,}" ]]

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

    local s="${1-}" from="${2-}" to="${3-}"

    [[ -n "${from}" ]] || { printf '%s' "${s}"; return 0; }
    printf '%s' "${s//"${from}"/${to}}"

}
str::replace_first () {

    local s="${1-}" from="${2-}" to="${3-}"

    [[ -n "${from}" ]] || { printf '%s' "${s}"; return 0; }
    printf '%s' "${s/"${from}"/${to}}"

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
    [[ "${s:${start}}" == "${suffix}" ]] || { printf '%s' "${s}"; return 0; }

    printf '%s' "${s:0:start}"

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
str::words () {

    local s="${1-}" i=0 x="" next="" out="" prev_kind="" kind=""
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

            out+="${x,,}"
            prev_kind="${kind}"
            continue

        fi

        [[ -n "${out}" ]] && words+=( "${out}" )
        out=""
        prev_kind=""

    done

    [[ -n "${out}" ]] && words+=( "${out}" )
    (( ${#words[@]} > 0 )) && printf '%s\n' "${words[@]}"

}
str::title () {

    local s="${1-}" x="" out=""

    while IFS= read -r x; do

        [[ -n "${x}" ]] || continue
        [[ -n "${out}" ]] && out+=' '
        out+="${x^}"

    done < <(str::words "${s}")

    printf '%s' "${out}"

}
str::camel () {

    local s="${1-}" x="" out="" first=1

    while IFS= read -r x; do

        [[ -n "${x}" ]] || continue

        if (( first )); then
            out+="${x}"
            first=0
        else
            out+="${x^}"
        fi

    done < <(str::words "${s}")

    printf '%s' "${out}"

}
str::pascal () {

    local s="${1-}" x="" out=""

    while IFS= read -r x; do

        [[ -n "${x}" ]] || continue
        out+="${x^}"

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
str::train () {

    local s="${1-}" x="" out=""

    while IFS= read -r x; do

        [[ -n "${x}" ]] || continue
        [[ -n "${out}" ]] && out+='-'
        out+="${x^}"

    done < <(str::words "${s}")

    printf '%s' "${out}"

}
str::constant () {

    local s="${1-}"
    printf '%s' "$(str::snake "${s}")" | tr '[:lower:]' '[:upper:]'

}
str::slug () {

    str::kebab "$@"

}
str::capitalize () {

    local s="${1-}"

    [[ -n "${s}" ]] || return 0
    printf '%s' "${s^}"

}
str::uncapitalize () {

    local s="${1-}"

    [[ -n "${s}" ]] || return 0
    printf '%s' "${s,}"

}
str::swapcase () {

    local s="${1-}" out="" x="" i=0

    for (( i=0; i<${#s}; i++ )); do

        x="${s:i:1}"

        if str::is_upper "${x}"; then
            out+="${x,,}"
        elif str::is_lower "${x}"; then
            out+="${x^^}"
        else
            out+="${x}"
        fi

    done

    printf '%s' "${out}"

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
str::lines () {

    local s="${1-}"

    [[ -n "${s}" ]] || return 0
    printf '%s\n' "${s}"

}
str::indent () {

    local s="${1-}" prefix="${2:-    }" line="" first=1

    while IFS= read -r line || [[ -n "${line}" ]]; do

        (( first )) || printf '\n'
        first=0
        printf '%s%s' "${prefix}" "${line}"

    done <<< "${s}"

}
str::dedent () {

    local s="${1-}" line="" min="" n=0 pad="" out="" first=1

    while IFS= read -r line || [[ -n "${line}" ]]; do

        [[ -z "${line//[[:space:]]/}" ]] && continue

        pad="${line%%[![:space:]]*}"
        n="${#pad}"

        [[ -z "${min}" || n -lt min ]] && min="${n}"

    done <<< "${s}"

    [[ -n "${min}" ]] || { printf '%s' "${s}"; return 0; }

    while IFS= read -r line || [[ -n "${line}" ]]; do

        (( first )) || out+=$'\n'
        first=0

        if [[ -z "${line//[[:space:]]/}" ]]; then
            out+="${line}"
        else
            out+="${line:${min}}"
        fi

    done <<< "${s}"

    printf '%s' "${out}"

}
str::is_empty () {

    [[ -z "${1-}" ]]

}
str::is_blank () {

    local s="${1-}"
    [[ -z "${s//[[:space:]]/}" ]]

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
str::is_char () {

    local s="${1-}"
    (( ${#s} == 1 ))

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
str::is_bool () {

    local s="${1-}"

    case "${s,,}" in
        1|0|true|false|yes|no|y|n|on|off) return 0 ;;
        *) return 1 ;;
    esac

}
str::is_email () {

    [[ "${1-}" =~ ^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+[.][A-Za-z]{2,}$ ]]

}
str::is_url () {

    [[ "${1-}" =~ ^https?://[^[:space:]]+$ ]]

}
str::is_slug () {

    [[ "${1-}" =~ ^[a-z0-9]+(-[a-z0-9]+)*$ ]]

}
str::is_identifier () {

    [[ "${1-}" =~ ^[A-Za-z_][A-Za-z0-9_]*$ ]]

}
str::bool () {

    local s="${1-}"

    case "${s,,}" in
        1|true|yes|y|on) printf 'true' ;;
        0|false|no|n|off) printf 'false' ;;
        *) return 1 ;;
    esac

}
str::escape_regex () {

    local s="${1-}"

    s="${s//\\/\\\\}"
    s="${s//./\\.}"
    s="${s//\*/\\*}"
    s="${s//+/\\+}"
    s="${s//\?/\\?}"
    s="${s//\[/\\[}"
    s="${s//\]/\\]}"
    s="${s//\^/\\^}"
    s="${s//\$/\\$}"
    s="${s//\(/\\(}"
    s="${s//\)/\\)}"
    s="${s//\{/\\{}"
    s="${s//\}/\\}}"
    s="${s//|/\\|}"

    printf '%s' "${s}"

}
str::escape_sed () {

    local s="${1-}"

    s="${s//\\/\\\\}"
    s="${s//&/\\&}"
    s="${s//\//\\/}"

    printf '%s' "${s}"

}
str::escape_json () {

    local s="${1-}" out="" x="" i=0 code=0

    for (( i=0; i<${#s}; i++ )); do

        x="${s:i:1}"

        case "${x}" in
            '"')   out="${out}\\\"" ;;
            "\\")  out="${out}\\\\" ;;
            $'\b') out="${out}\\b"  ;;
            $'\f') out="${out}\\f"  ;;
            $'\n') out="${out}\\n"  ;;
            $'\r') out="${out}\\r"  ;;
            $'\t') out="${out}\\t"  ;;
            *)
                printf -v code '%d' "'${x}"
                if (( code < 32 )); then
                    printf -v x '\\u%04x' "${code}"
                fi
                out+="${x}"
                ;;
        esac

    done

    printf '%s' "${out}"

}
str::json_quote () {

    printf '"%s"' "$(str::escape_json "${1-}")"

}
