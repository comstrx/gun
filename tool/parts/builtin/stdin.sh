
input () {

    local prompt="${1-}" def="${2-}" line="" rc=0
    local tty="/dev/tty"

    if [[ -r "${tty}" && -w "${tty}" ]]; then
        [[ -n "${prompt}" ]] && printf '%s' "${prompt}" > "${tty}"
        IFS= read -r line < "${tty}" || rc=$?
    else
        [[ -n "${prompt}" ]] && printf '%s' "${prompt}" >&2
        IFS= read -r line || rc=$?
    fi

    if (( rc != 0 )); then
        [[ -n "${def}" ]] && { printf '%s' "${def}"; return 0; }
        return "${rc}"
    fi

    [[ -z "${line}" && -n "${def}" ]] && line="${def}"
    printf '%s' "${line}"

}
input_bool () {

    local prompt="${1-}" def="${2-}" tries="${3:-3}" v="" i=0

    [[ "${tries}" =~ ^[0-9]+$ ]] || tries=3
    (( tries > 0 )) || tries=3

    for (( i=0; i<tries; i++ )); do

        v="$(input "${prompt}" "${def}")" || return $?

        case "${v,,}" in
            1|true|yes|y|on)  printf '1'; return 0 ;;
            0|false|no|n|off) printf '0'; return 0 ;;
        esac

        eprint "Invalid bool. Use: y/n, yes/no, on/off, 1/0, true/false"

    done

    die "Too many invalid attempts"

}
input_int () {

    local prompt="${1-}" def="${2-}" tries="${3:-3}" v="" i=0

    [[ "${tries}" =~ ^[0-9]+$ ]] || tries=3
    (( tries > 0 )) || tries=3

    for (( i=0; i<tries; i++ )); do

        v="$(input "${prompt}" "${def}")" || return $?

        [[ "${v}" =~ ^-?[0-9]+$ ]] && { printf '%s' "${v}"; return 0; }
        eprint "Invalid int. Example: 0, 12, -7"

    done

    die "Too many invalid attempts"

}
input_uint () {

    local prompt="${1-}" def="${2-}" tries="${3:-3}" v="" i=0

    [[ "${tries}" =~ ^[0-9]+$ ]] || tries=3
    (( tries > 0 )) || tries=3

    for (( i=0; i<tries; i++ )); do

        v="$(input "${prompt}" "${def}")" || return $?

        [[ "${v}" =~ ^[0-9]+$ ]] && { printf '%s' "${v}"; return 0; }
        eprint "Invalid uint. Example: 0, 12, 7"

    done

    die "Too many invalid attempts"

}
input_float () {

    local prompt="${1-}" def="${2-}" tries="${3:-3}" v="" i=0

    [[ "${tries}" =~ ^[0-9]+$ ]] || tries=3
    (( tries > 0 )) || tries=3

    for (( i=0; i<tries; i++ )); do

        v="$(input "${prompt}" "${def}")" || return $?

        [[ "${v}" =~ ^[+-]?([0-9]+([.][0-9]+)?|[.][0-9]+)$ ]] && { printf '%s' "${v}"; return 0; }
        eprint "Invalid float. Example: 0, 12.5, -7, .3"

    done

    die "Too many invalid attempts"

}
input_char () {

    local prompt="${1-}" def="${2-}" tries="${3:-3}" v="" i=0

    [[ "${tries}" =~ ^[0-9]+$ ]] || tries=3
    (( tries > 0 )) || tries=3

    for (( i=0; i<tries; i++ )); do

        v="$(input "${prompt}" "${def}")" || return $?

        (( ${#v} == 1 )) && { printf '%s' "${v}"; return 0; }
        eprint "Invalid char. Example: a"

    done

    die "Too many invalid attempts"

}
input_path () {

    local prompt="${1-}" def="${2-}" mode="${3:-any}" tries="${4:-3}"
    local p="" i=0

    [[ "${tries}" =~ ^[0-9]+$ ]] || tries=3
    (( tries > 0 )) || tries=3

    case "${mode}" in
        any|exists|file|dir) ;;
        *) die "Invalid mode '${mode}'" ;;
    esac

    for (( i=0; i<tries; i++ )); do

        p="$(input "${prompt}" "${def}")" || return $?

        [[ -n "${p}" ]] || { eprint "Path is required"; continue; }

        case "${mode}" in
            any)    printf '%s' "${p}"; return 0 ;;
            exists) [[ -e "${p}" ]] && { printf '%s' "${p}"; return 0; } ;;
            file)   [[ -f "${p}" ]] && { printf '%s' "${p}"; return 0; } ;;
            dir)    [[ -d "${p}" ]] && { printf '%s' "${p}"; return 0; } ;;
        esac

        eprint "Invalid path for mode '${mode}': ${p}"

    done

    die "Too many invalid attempts"

}
input_password () {

    local prompt="${1-}" line="" rc=0
    local tty="/dev/tty"

    [[ -r "${tty}" && -w "${tty}" ]] || die "No /dev/tty"
    [[ -n "${prompt}" ]] && printf '%s' "${prompt}" > "${tty}"

    IFS= read -r -s line < "${tty}" || rc=$?
    printf '\n' > "${tty}"

    (( rc == 0 )) || return "${rc}"
    printf '%s' "${line}"

}
choose () {

    local prompt="${1:-Choose:}" pick="" i=0 attempt=0
    shift || true

    local -a items=( "$@" )
    (( ${#items[@]} )) || die "Missing items"

    eprint "${prompt}"

    for (( i=0; i<${#items[@]}; i++ )); do
        eprint "  $(( i + 1 ))) ${items[$i]}"
    done

    for (( attempt=0; attempt<3; attempt++ )); do

        pick="$(input "Enter number [1-${#items[@]}]: ")" || return $?

        [[ "${pick}" =~ ^[0-9]+$ ]] || { eprint "Invalid number"; continue; }
        (( pick >= 1 && pick <= ${#items[@]} )) || { eprint "Out of range"; continue; }

        printf '%s' "${items[$(( pick - 1 ))]}"
        return 0

    done

    die "Too many invalid attempts"

}
confirm () {

    local msg="${1:-Continue?}" def="${2:-N}" tries="${3:-3}" ans="" i=0
    local hint="[y/N]: "

    [[ "${tries}" =~ ^[0-9]+$ ]] || tries=3
    (( tries > 0 )) || tries=3

    case "${def,,}" in
        1|true|y|yes|on) hint="[Y/n]: " ;;
    esac

    for (( i=0; i<tries; i++ )); do

        ans="$(input "${msg} ${hint}" "${def}")" || return $?

        case "${ans,,}" in
            1|true|y|yes|on)  return 0 ;;
            0|false|n|no|off) return 1 ;;
        esac

        eprint "Invalid choice. Use: y/n, yes/no, on/off, 1/0, true/false"

    done

    die "Too many invalid attempts"

}
