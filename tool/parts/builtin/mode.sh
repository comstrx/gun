
mode::get () {

    local path="${1:-}" winpath="" out="" user="" owner="" other="" v=""

    [[ -n "${path}" ]] || return 1
    [[ -e "${path}" || -L "${path}" ]] || return 1

    if sys::is_windows && sys::has icacls.exe; then

        winpath="${path}"
        sys::has cygpath && winpath="$(cygpath -aw "${path}" 2>/dev/null || printf '%s' "${path}")"

        user="${USERNAME:-}"
        [[ -n "${user}" ]] || user="$(sys::uname 2>/dev/null || true)"

        out="$(icacls.exe "${winpath}" 2>/dev/null | tr -d '\r' || true)"

        if [[ -n "${out}" && -n "${user}" ]]; then

            owner=0
            other=0

            if printf '%s\n' "${out}" | grep -Ei "\\\\?${user}:.*\(F\)" >/dev/null 2>&1; then owner=7
            elif printf '%s\n' "${out}" | grep -Ei "\\\\?${user}:.*\(RX\)" >/dev/null 2>&1; then owner=5
            elif printf '%s\n' "${out}" | grep -Ei "\\\\?${user}:.*\(R,W\)|\\\\?${user}:.*\(W,R\)|\\\\?${user}:.*\(M\)" >/dev/null 2>&1; then owner=6
            elif printf '%s\n' "${out}" | grep -Ei "\\\\?${user}:.*\(R\)" >/dev/null 2>&1; then owner=4
            fi

            if printf '%s\n' "${out}" | grep -Ei "(Users|Everyone|Authenticated Users):.*\(F\)" >/dev/null 2>&1; then other=7
            elif printf '%s\n' "${out}" | grep -Ei "(Users|Everyone|Authenticated Users):.*\(RX\)" >/dev/null 2>&1; then other=5
            elif printf '%s\n' "${out}" | grep -Ei "(Users|Everyone|Authenticated Users):.*\(R,W\)|(Users|Everyone|Authenticated Users):.*\(W,R\)|(Users|Everyone|Authenticated Users):.*\(M\)" >/dev/null 2>&1; then other=6
            elif printf '%s\n' "${out}" | grep -Ei "(Users|Everyone|Authenticated Users):.*\(R\)" >/dev/null 2>&1; then other=4
            fi

            if (( owner > 0 )); then
                printf '%s%s%s\n' "${owner}" "${other}" "${other}"
                return 0
            fi

        fi

    fi

    sys::has stat || return 1

    v="$(stat -c '%a' "${path}" 2>/dev/null || true)"
    [[ "${v}" =~ ^[0-7]+$ ]] && { printf '%s\n' "${v}"; return 0; }

    v="$(stat -f '%Lp' "${path}" 2>/dev/null || true)"
    [[ "${v}" =~ ^[0-7]+$ ]] && { printf '%s\n' "${v}"; return 0; }

    return 1

}
mode::set () {

    local path="${1:-}" mode="${2:-}" winpath="" user=""

    [[ -n "${path}" && -n "${mode}" ]] || return 1
    [[ -e "${path}" || -L "${path}" ]] || return 1
    [[ "${mode}" != *$'\n'* && "${mode}" != *$'\r'* ]] || return 1

    if sys::is_windows && sys::has icacls.exe; then

        winpath="${path}"
        sys::has cygpath && winpath="$(cygpath -aw "${path}" 2>/dev/null || printf '%s' "${path}")"

        user="${USERNAME:-}"
        [[ -n "${user}" ]] || user="$(sys::uname 2>/dev/null || true)"
        [[ -n "${user}" ]] || return 1

        case "${mode}" in

            600)
                icacls.exe "${winpath}" /inheritance:r >/dev/null 2>&1 || return 1
                icacls.exe "${winpath}" /remove:g "*S-1-1-0" "*S-1-5-11" "*S-1-5-32-545" >/dev/null 2>&1 || true
                icacls.exe "${winpath}" /grant:r "${user}:(R,W)" "*S-1-5-18:(F)" "*S-1-5-32-544:(F)" >/dev/null 2>&1 || return 1
                sys::has chmod && chmod 600 "${path}" >/dev/null 2>&1 || true
                return 0
            ;;

            644)
                icacls.exe "${winpath}" /inheritance:e >/dev/null 2>&1 || true
                icacls.exe "${winpath}" /grant:r "${user}:(R,W)" "*S-1-5-32-545:(R)" >/dev/null 2>&1 || return 1
                sys::has chmod && chmod 644 "${path}" >/dev/null 2>&1 || true
                return 0
            ;;

            700)
                icacls.exe "${winpath}" /inheritance:r >/dev/null 2>&1 || return 1
                icacls.exe "${winpath}" /remove:g "*S-1-1-0" "*S-1-5-11" "*S-1-5-32-545" >/dev/null 2>&1 || true
                icacls.exe "${winpath}" /grant:r "${user}:(F)" "*S-1-5-18:(F)" "*S-1-5-32-544:(F)" >/dev/null 2>&1 || return 1
                sys::has chmod && chmod 700 "${path}" >/dev/null 2>&1 || true
                return 0
            ;;

            755)
                icacls.exe "${winpath}" /inheritance:e >/dev/null 2>&1 || true
                icacls.exe "${winpath}" /grant:r "${user}:(F)" "*S-1-5-32-545:(RX)" >/dev/null 2>&1 || return 1
                sys::has chmod && chmod 755 "${path}" >/dev/null 2>&1 || true
                return 0
            ;;

        esac

    fi

    sys::has chmod || return 1
    chmod "${mode}" "${path}" >/dev/null 2>&1

}
mode::add () {

    local path="${1:-}" mode="${2:-}"

    [[ -n "${path}" && -n "${mode}" ]] || return 1
    [[ -e "${path}" || -L "${path}" ]] || return 1
    [[ "${mode}" != *$'\n'* && "${mode}" != *$'\r'* ]] || return 1

    sys::has chmod || return 1

    case "${mode}" in
        +*) chmod "${mode}" "${path}" >/dev/null 2>&1 ;;
        *)  chmod "+${mode}" "${path}" >/dev/null 2>&1 ;;
    esac

}
mode::del () {

    local path="${1:-}" mode="${2:-}"

    [[ -n "${path}" && -n "${mode}" ]] || return 1
    [[ -e "${path}" || -L "${path}" ]] || return 1
    [[ "${mode}" != *$'\n'* && "${mode}" != *$'\r'* ]] || return 1

    sys::has chmod || return 1

    case "${mode}" in
        -*) chmod "${mode}" "${path}" >/dev/null 2>&1 ;;
        *)  chmod "-${mode}" "${path}" >/dev/null 2>&1 ;;
    esac

}

mode::read () {

    local path="${1:-}" who="${2:-u}" winpath="" user=""

    [[ -n "${path}" && -n "${who}" ]] || return 1
    [[ -e "${path}" || -L "${path}" ]] || return 1
    [[ "${who}" != *$'\n'* && "${who}" != *$'\r'* ]] || return 1

    if sys::is_windows && sys::has icacls.exe; then

        winpath="${path}"
        sys::has cygpath && winpath="$(cygpath -aw "${path}" 2>/dev/null || printf '%s' "${path}")"

        user="${USERNAME:-}"
        [[ -n "${user}" ]] || user="$(sys::uname 2>/dev/null || true)"
        [[ -n "${user}" ]] || return 1

        case "${who}" in
            *a*|*g*|*o*) icacls.exe "${winpath}" /grant "*S-1-5-32-545:(R)" >/dev/null 2>&1 || return 1 ;;
            *)           icacls.exe "${winpath}" /grant "${user}:(R)" >/dev/null 2>&1 || return 1 ;;
        esac

        sys::has chmod && chmod "${who}+r" "${path}" >/dev/null 2>&1 || true
        return 0

    fi

    sys::has chmod || return 1
    chmod "${who}+r" "${path}" >/dev/null 2>&1

}
mode::write () {

    local path="${1:-}" who="${2:-u}" winpath="" user=""

    [[ -n "${path}" && -n "${who}" ]] || return 1
    [[ -e "${path}" || -L "${path}" ]] || return 1
    [[ "${who}" != *$'\n'* && "${who}" != *$'\r'* ]] || return 1

    if sys::is_windows && sys::has icacls.exe; then

        winpath="${path}"
        sys::has cygpath && winpath="$(cygpath -aw "${path}" 2>/dev/null || printf '%s' "${path}")"

        user="${USERNAME:-}"
        [[ -n "${user}" ]] || user="$(sys::uname 2>/dev/null || true)"
        [[ -n "${user}" ]] || return 1

        case "${who}" in
            *a*|*g*|*o*) icacls.exe "${winpath}" /grant "*S-1-5-32-545:(W)" >/dev/null 2>&1 || return 1 ;;
            *)           icacls.exe "${winpath}" /grant "${user}:(W)" >/dev/null 2>&1 || return 1 ;;
        esac

        sys::has chmod && chmod "${who}+w" "${path}" >/dev/null 2>&1 || true
        return 0

    fi

    sys::has chmod || return 1
    chmod "${who}+w" "${path}" >/dev/null 2>&1

}
mode::exec () {

    local path="${1:-}" who="${2:-u}" winpath="" user=""

    [[ -n "${path}" && -n "${who}" ]] || return 1
    [[ -e "${path}" || -L "${path}" ]] || return 1
    [[ "${who}" != *$'\n'* && "${who}" != *$'\r'* ]] || return 1

    if sys::is_windows && sys::has icacls.exe; then

        winpath="${path}"
        sys::has cygpath && winpath="$(cygpath -aw "${path}" 2>/dev/null || printf '%s' "${path}")"

        user="${USERNAME:-}"
        [[ -n "${user}" ]] || user="$(sys::uname 2>/dev/null || true)"
        [[ -n "${user}" ]] || return 1

        case "${who}" in
            *a*|*g*|*o*) icacls.exe "${winpath}" /grant "*S-1-5-32-545:(RX)" >/dev/null 2>&1 || return 1 ;;
            *)           icacls.exe "${winpath}" /grant "${user}:(RX)" >/dev/null 2>&1 || return 1 ;;
        esac

        sys::has chmod && chmod "${who}+x" "${path}" >/dev/null 2>&1 || true
        return 0

    fi

    sys::has chmod || return 1
    chmod "${who}+x" "${path}" >/dev/null 2>&1

}
mode::owner () {

    local path="${1:-}" user="${2:-}" winpath="" v=""

    [[ -n "${path}" ]] || return 1
    [[ -e "${path}" || -L "${path}" ]] || return 1

    if [[ -n "${user}" ]]; then

        [[ "${user}" != *$'\n'* && "${user}" != *$'\r'* ]] || return 1

        if sys::is_windows && sys::has icacls.exe; then

            winpath="${path}"
            sys::has cygpath && winpath="$(cygpath -aw "${path}" 2>/dev/null || printf '%s' "${path}")"

            icacls.exe "${winpath}" /setowner "${user}" >/dev/null 2>&1 || return 1
            return 0

        fi

        sys::has chown || return 1
        chown "${user}" "${path}" >/dev/null 2>&1
        return

    fi

    sys::has stat || return 1

    v="$(stat -c '%U' "${path}" 2>/dev/null || true)"
    [[ -n "${v}" && "${v}" != *$'\n'* && "${v}" != "UNKNOWN" ]] && { printf '%s\n' "${v}"; return 0; }

    v="$(stat -f '%Su' "${path}" 2>/dev/null || true)"
    [[ -n "${v}" && "${v}" != *$'\n'* && "${v}" != "  File:"* ]] && { printf '%s\n' "${v}"; return 0; }

    return 1

}
mode::group () {

    local path="${1:-}" group="${2:-}" winpath="" v=""

    [[ -n "${path}" ]] || return 1
    [[ -e "${path}" || -L "${path}" ]] || return 1

    if [[ -n "${group}" ]]; then

        [[ "${group}" != *$'\n'* && "${group}" != *$'\r'* ]] || return 1

        if sys::is_windows && sys::has icacls.exe; then

            winpath="${path}"
            sys::has cygpath && winpath="$(cygpath -aw "${path}" 2>/dev/null || printf '%s' "${path}")"

            icacls.exe "${winpath}" /grant "${group}:(RX)" >/dev/null 2>&1 || return 1
            return 0

        fi

        sys::has chgrp || return 1
        chgrp "${group}" "${path}" >/dev/null 2>&1
        return

    fi

    sys::has stat || return 1

    v="$(stat -c '%G' "${path}" 2>/dev/null || true)"
    [[ -n "${v}" && "${v}" != *$'\n'* && "${v}" != "UNKNOWN" ]] && { printf '%s\n' "${v}"; return 0; }

    v="$(stat -f '%Sg' "${path}" 2>/dev/null || true)"
    [[ -n "${v}" && "${v}" != *$'\n'* && "${v}" != "  File:"* ]] && { printf '%s\n' "${v}"; return 0; }

    return 1

}

mode::private () {

    local path="${1:-}"

    [[ -n "${path}" ]] || return 1
    [[ -e "${path}" || -L "${path}" ]] || return 1

    if [[ -d "${path}" && ! -L "${path}" ]]; then
        mode::set "${path}" 700
        return
    fi

    mode::set "${path}" 600

}
mode::public () {

    local path="${1:-}"

    [[ -n "${path}" ]] || return 1
    [[ -e "${path}" || -L "${path}" ]] || return 1

    if [[ -d "${path}" && ! -L "${path}" ]]; then
        mode::set "${path}" 755
        return
    fi

    mode::set "${path}" 644

}
mode::lock () {

    local path="${1:-}" who="${2:-u}" winpath="" user=""

    [[ -n "${path}" && -n "${who}" ]] || return 1
    [[ -e "${path}" || -L "${path}" ]] || return 1
    [[ "${who}" != *$'\n'* && "${who}" != *$'\r'* ]] || return 1

    if sys::is_windows && sys::has icacls.exe; then

        winpath="${path}"
        sys::has cygpath && winpath="$(cygpath -aw "${path}" 2>/dev/null || printf '%s' "${path}")"

        user="${USERNAME:-}"
        [[ -n "${user}" ]] || user="$(sys::uname 2>/dev/null || true)"
        [[ -n "${user}" ]] || return 1

        case "${who}" in
            *a*|*g*|*o*) icacls.exe "${winpath}" /deny "*S-1-5-32-545:(W)" >/dev/null 2>&1 || return 1 ;;
            *)           icacls.exe "${winpath}" /deny "${user}:(W)" >/dev/null 2>&1 || return 1 ;;
        esac

        sys::has chmod && chmod "${who}-w" "${path}" >/dev/null 2>&1 || true
        return 0

    fi

    sys::has chmod || return 1
    chmod "${who}-w" "${path}" >/dev/null 2>&1

}
mode::unlock () {

    local path="${1:-}" who="${2:-u}" winpath="" user=""

    [[ -n "${path}" && -n "${who}" ]] || return 1
    [[ -e "${path}" || -L "${path}" ]] || return 1
    [[ "${who}" != *$'\n'* && "${who}" != *$'\r'* ]] || return 1

    if sys::is_windows && sys::has icacls.exe; then

        winpath="${path}"
        sys::has cygpath && winpath="$(cygpath -aw "${path}" 2>/dev/null || printf '%s' "${path}")"

        user="${USERNAME:-}"
        [[ -n "${user}" ]] || user="$(sys::uname 2>/dev/null || true)"
        [[ -n "${user}" ]] || return 1

        case "${who}" in
            *a*|*g*|*o*)
                icacls.exe "${winpath}" /remove:d "*S-1-5-32-545" >/dev/null 2>&1 || true
                icacls.exe "${winpath}" /grant "*S-1-5-32-545:(W)" >/dev/null 2>&1 || return 1
            ;;
            *)
                icacls.exe "${winpath}" /remove:d "${user}" >/dev/null 2>&1 || true
                icacls.exe "${winpath}" /grant "${user}:(W)" >/dev/null 2>&1 || return 1
            ;;
        esac

        sys::has chmod && chmod "${who}+w" "${path}" >/dev/null 2>&1 || true
        return 0

    fi

    sys::has chmod || return 1
    chmod "${who}+w" "${path}" >/dev/null 2>&1

}

mode::readable () {

    local path="${1:-}"

    [[ -n "${path}" ]] || return 1
    [[ -r "${path}" ]]

}
mode::writable () {

    local path="${1:-}"

    [[ -n "${path}" ]] || return 1
    [[ -w "${path}" ]]

}
mode::executable () {

    local path="${1:-}"

    [[ -n "${path}" ]] || return 1
    [[ -x "${path}" ]]

}
mode::owned () {

    local path="${1:-}" user="${2:-}" owner=""

    [[ -n "${path}" ]] || return 1
    [[ -e "${path}" || -L "${path}" ]] || return 1

    [[ -n "${user}" ]] || user="$(sys::uname 2>/dev/null || true)"
    [[ -n "${user}" ]] || return 1

    owner="$(mode::owner "${path}" 2>/dev/null || true)"
    [[ "${owner}" == "${user}" ]]

}
mode::same () {

    local a="${1:-}" b="${2:-}" am="" bm=""

    [[ -n "${a}" && -n "${b}" ]] || return 1
    [[ -e "${a}" || -L "${a}" ]] || return 1
    [[ -e "${b}" || -L "${b}" ]] || return 1

    am="$(mode::get "${a}" 2>/dev/null || true)"
    bm="$(mode::get "${b}" 2>/dev/null || true)"

    [[ -n "${am}" && "${am}" == "${bm}" ]]

}

mode::ensure () {

    local path="${1:-}" mode="${2:-}" current=""

    [[ -n "${path}" && -n "${mode}" ]] || return 1
    [[ -e "${path}" || -L "${path}" ]] || return 1
    [[ "${mode}" != *$'\n'* && "${mode}" != *$'\r'* ]] || return 1

    current="$(mode::get "${path}" 2>/dev/null || true)"
    [[ "${current}" == "${mode}" ]] && return 0

    mode::set "${path}" "${mode}"

}
mode::info () {

    local path="${1:-}" mode="" owner="" group=""

    [[ -n "${path}" ]] || return 1
    [[ -e "${path}" || -L "${path}" ]] || return 1

    mode="$(mode::get   "${path}" 2>/dev/null || true)"
    owner="$(mode::owner "${path}" 2>/dev/null || true)"
    group="$(mode::group "${path}" 2>/dev/null || true)"

    [[ -n "${mode}"  ]] || mode="unknown"
    [[ -n "${owner}" ]] || owner="unknown"
    [[ -n "${group}" ]] || group="unknown"

    printf '%s\n' "path=${path}" "mode=${mode}" "owner=${owner}" "group=${group}"

}
