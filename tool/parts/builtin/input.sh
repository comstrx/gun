# shellcheck disable=SC2034

input::is_tty () {

    [[ -t 0 ]]

}
input::is_pipe () {

    [[ ! -t 0 ]]

}

input::get () {

    local prompt="${1:-}" def="${2-}" line="" rc=0 tty="/dev/tty" fd=""

    if [[ -e "${tty}" ]] && exec {fd}<>"${tty}" 2>/dev/null; then

        [[ -n "${prompt}" ]] && printf '%s' "${prompt}" >&"${fd}"

        if IFS= read -r -u "${fd}" line; then rc=0
        else rc=$?
        fi

        exec {fd}<&- 2>/dev/null || true

    else
        [[ -n "${prompt}" ]] && printf '%s' "${prompt}" >&2
        IFS= read -r line || rc=$?
    fi

    if (( rc != 0 )); then
        [[ $# -ge 2 ]] && { printf '%s' "${def}"; return 0; }
        return "${rc}"
    fi

    [[ -z "${line}" && $# -ge 2 ]] && line="${def}"
    printf '%s' "${line}"

}
input::read () {

    cat

}
input::lines () {

    local target="${1:-}" line="" decl=""
    local -a out=()

    [[ "${target}" =~ ^[A-Za-z_][A-Za-z0-9_]*$ ]] || return 1

    if declare -p "${target}" >/dev/null 2>&1; then
        decl="$(declare -p "${target}" 2>/dev/null)" || return 1
        [[ "${decl}" =~ ^declare\ -[a-zA-Z]*a[a-zA-Z]*[[:space:]] ]] || return 1
    fi

    while IFS= read -r line || [[ -n "${line}" ]]; do
        out+=( "${line}" )
    done

    declare -g -a "${target}=()"
    local -n ref="${target}"

    ref=( "${out[@]}" )

}

input::password () {

    local prompt="${1:-}" line="" rc=0 tty="/dev/tty"

    [[ -r "${tty}" && -w "${tty}" ]] || return 1
    [[ -n "${prompt}" ]] && printf '%s' "${prompt}" > "${tty}"

    IFS= read -r -s line < "${tty}" || rc=$?
    printf '\n' > "${tty}"

    (( rc == 0 )) || return "${rc}"
    printf '%s' "${line}"

}
input::confirm () {

    local msg="${1:-Continue?}" def="${2:-N}" tries="${3:-3}" ans="" hint="[y/N]: " i=0

    [[ "${tries}" =~ ^[0-9]+$ ]] || tries=3
    (( tries > 0 )) || tries=3

    case "${def,,}" in
        1|true|y|yes|on) hint="[Y/n]: " ;;
        0|false|n|no|off) def="N" ;;
        *) def="N" ;;
    esac

    for (( i=0; i<tries; i++ )); do

        ans="$(input::get "${msg} ${hint}" "${def}")" || return $?

        case "${ans,,}" in
            1|true|y|yes|on)  return 0 ;;
            0|false|n|no|off) return 1 ;;
        esac

        printf '%s\n' "Invalid choice. Use: y/n, yes/no, on/off, 1/0, true/false" >&2

    done

    return 1

}
input::select () {

    local prompt="${1:-Choose:}" tries="${2:-3}" pick="" i=0 attempt=0
    shift 2 || true

    local -a items=( "$@" )

    [[ "${tries}" =~ ^[0-9]+$ ]] || tries=3

    (( tries > 0 )) || tries=3
    (( ${#items[@]} > 0 )) || return 1

    printf '%s\n' "${prompt}" >&2

    for (( i=0; i<${#items[@]}; i++ )); do
        printf '  %s) %s\n' "$(( i + 1 ))" "${items[$i]}" >&2
    done

    for (( attempt=0; attempt<tries; attempt++ )); do

        pick="$(input::uint "Enter number [1-${#items[@]}]: ")" || return $?

        if (( pick >= 1 && pick <= ${#items[@]} )); then
            printf '%s' "${items[$(( pick - 1 ))]}"
            return 0
        fi

        printf '%s\n' "Out of range" >&2

    done

    return 1

}
input::required () {

    local prompt="${1:-}" def="${2:-}" tries="${3:-3}" v="" i=0

    [[ "${tries}" =~ ^[0-9]+$ ]] || tries=3
    (( tries > 0 )) || tries=3

    for (( i=0; i<tries; i++ )); do

        if [[ $# -ge 2 ]]; then v="$(input::get "${prompt}" "${def}")" || return $?
        else v="$(input::get "${prompt}")" || return $?
        fi

        [[ -n "${v}" ]] && { printf '%s' "${v}"; return 0; }
        printf '%s\n' "Value is required" >&2

    done

    return 1

}
input::match () {

    local prompt="${1:-}" pattern="${2:-}" def="${3:-}" tries="${4:-3}" v="" i=0

    [[ -n "${pattern}" ]] || return 1

    [[ "${tries}" =~ ^[0-9]+$ ]] || tries=3
    (( tries > 0 )) || tries=3

    for (( i=0; i<tries; i++ )); do

        if [[ $# -ge 3 ]]; then v="$(input::get "${prompt}" "${def}")" || return $?
        else v="$(input::get "${prompt}")" || return $?
        fi

        [[ "${v}" =~ ${pattern} ]] && { printf '%s' "${v}"; return 0; }
        printf '%s\n' "Invalid value" >&2

    done

    return 1

}

input::int () {

    local prompt="${1:-}" def="${2:-}" tries="${3:-3}" v="" i=0

    [[ "${tries}" =~ ^[0-9]+$ ]] || tries=3
    (( tries > 0 )) || tries=3

    for (( i=0; i<tries; i++ )); do

        if [[ $# -ge 2 ]]; then v="$(input::get "${prompt}" "${def}")" || return $?
        else v="$(input::get "${prompt}")" || return $?
        fi

        [[ "${v}" =~ ^-?[0-9]+$ ]] && { printf '%s' "${v}"; return 0; }
        printf '%s\n' "Invalid int. Example: 0, 12, -7" >&2

    done

    return 1

}
input::uint () {

    local prompt="${1:-}" def="${2:-}" tries="${3:-3}" v="" i=0

    [[ "${tries}" =~ ^[0-9]+$ ]] || tries=3
    (( tries > 0 )) || tries=3

    for (( i=0; i<tries; i++ )); do

        if [[ $# -ge 2 ]]; then v="$(input::get "${prompt}" "${def}")" || return $?
        else v="$(input::get "${prompt}")" || return $?
        fi

        [[ "${v}" =~ ^[0-9]+$ ]] && { printf '%s' "${v}"; return 0; }
        printf '%s\n' "Invalid uint. Example: 0, 12, 7" >&2

    done

    return 1

}
input::float () {

    local prompt="${1:-}" def="${2:-}" tries="${3:-3}" v="" i=0

    [[ "${tries}" =~ ^[0-9]+$ ]] || tries=3
    (( tries > 0 )) || tries=3

    for (( i=0; i<tries; i++ )); do

        if [[ $# -ge 2 ]]; then v="$(input::get "${prompt}" "${def}")" || return $?
        else v="$(input::get "${prompt}")" || return $?
        fi

        [[ "${v}" =~ ^[+-]?([0-9]+([.][0-9]+)?|[.][0-9]+|[0-9]+[.])$ ]] && {
            printf '%s' "${v}"
            return 0
        }

        printf '%s\n' "Invalid float. Example: 0, 12.5, -7, .3" >&2

    done

    return 1

}
input::number () {

    input::float "$@"

}
input::bool () {

    local prompt="${1:-}" def="${2:-}" tries="${3:-3}" v="" i=0

    [[ "${tries}" =~ ^[0-9]+$ ]] || tries=3
    (( tries > 0 )) || tries=3

    for (( i=0; i<tries; i++ )); do

        if [[ $# -ge 2 ]]; then v="$(input::get "${prompt}" "${def}")" || return $?
        else v="$(input::get "${prompt}")" || return $?
        fi

        case "${v,,}" in
            1|true|yes|y|on)  printf '1'; return 0 ;;
            0|false|no|n|off) printf '0'; return 0 ;;
        esac

        printf '%s\n' "Invalid bool. Use: y/n, yes/no, on/off, 1/0, true/false" >&2

    done

    return 1

}
input::char () {

    local prompt="${1:-}" def="${2:-}" tries="${3:-3}" v="" i=0

    [[ "${tries}" =~ ^[0-9]+$ ]] || tries=3
    (( tries > 0 )) || tries=3

    for (( i=0; i<tries; i++ )); do

        if [[ $# -ge 2 ]]; then v="$(input::get "${prompt}" "${def}")" || return $?
        else v="$(input::get "${prompt}")" || return $?
        fi

        (( ${#v} == 1 )) && { printf '%s' "${v}"; return 0; }
        printf '%s\n' "Invalid char. Example: a" >&2

    done

    return 1

}

input::path () {

    local prompt="${1:-}" def="${2:-}" mode="${3:-any}" tries="${4:-3}" p="" i=0 has_def=0

    (( $# >= 2 )) && has_def=1

    [[ "${tries}" =~ ^[0-9]+$ ]] || tries=3
    (( tries > 0 )) || tries=3

    case "${mode}" in
        any|exists|file|dir|readable|writable|executable) ;;
        *) return 1 ;;
    esac

    for (( i=0; i<tries; i++ )); do

        if (( has_def )); then p="$(input::get "${prompt}" "${def}")" || return $?
        else p="$(input::get "${prompt}")" || return $?
        fi

        [[ -n "${p}" ]] || { printf '%s\n' "Path is required" >&2; continue; }

        case "${mode}" in
            any)        printf '%s' "${p}"; return 0 ;;
            exists)     [[ -e "${p}" ]] && { printf '%s' "${p}"; return 0; } ;;
            file)       [[ -f "${p}" ]] && { printf '%s' "${p}"; return 0; } ;;
            dir)        [[ -d "${p}" ]] && { printf '%s' "${p}"; return 0; } ;;
            readable)   [[ -r "${p}" ]] && { printf '%s' "${p}"; return 0; } ;;
            writable)   [[ -w "${p}" ]] && { printf '%s' "${p}"; return 0; } ;;
            executable) [[ -x "${p}" ]] && { printf '%s' "${p}"; return 0; } ;;
        esac

        printf 'Invalid path for mode %s: %s\n' "${mode}" "${p}" >&2

    done

    return 1

}
input::file () {

    input::path "${1:-}" "${2:-}" "file" "${3:-3}"

}
input::dir () {

    input::path "${1:-}" "${2:-}" "dir" "${3:-3}"

}
