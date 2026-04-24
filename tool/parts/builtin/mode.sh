
mode::get () {

    local path="${1:-}" v=""

    [[ -n "${path}" ]] || return 1
    [[ -e "${path}" || -L "${path}" ]] || return 1

    sys::has stat || return 1

    v="$(stat -c '%a' "${path}" 2>/dev/null || true)"
    [[ "${v}" =~ ^[0-7]+$ ]] && { printf '%s\n' "${v}"; return 0; }

    v="$(stat -f '%Lp' "${path}" 2>/dev/null || true)"
    [[ "${v}" =~ ^[0-7]+$ ]] && { printf '%s\n' "${v}"; return 0; }

    return 1

}
mode::set () {

    local path="${1:-}" mode="${2:-}"

    [[ -n "${path}" && -n "${mode}" ]] || return 1
    [[ -e "${path}" || -L "${path}" ]] || return 1

    [[ "${mode}" != *$'\n'* && "${mode}" != *$'\r'* ]] || return 1

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

    local path="${1:-}" who="${2:-u}"

    [[ -n "${path}" ]] || return 1
    [[ -n "${who}" ]] || return 1

    [[ -e "${path}" || -L "${path}" ]] || return 1
    [[ "${who}" != *$'\n'* && "${who}" != *$'\r'* ]] || return 1

    sys::has chmod || return 1
    chmod "${who}+r" "${path}" >/dev/null 2>&1

}
mode::write () {

    local path="${1:-}" who="${2:-u}"

    [[ -n "${path}" ]] || return 1
    [[ -n "${who}" ]] || return 1

    [[ -e "${path}" || -L "${path}" ]] || return 1
    [[ "${who}" != *$'\n'* && "${who}" != *$'\r'* ]] || return 1

    sys::has chmod || return 1
    chmod "${who}+w" "${path}" >/dev/null 2>&1

}
mode::exec () {

    local path="${1:-}" who="${2:-u}"

    [[ -n "${path}" ]] || return 1
    [[ -n "${who}" ]] || return 1

    [[ -e "${path}" || -L "${path}" ]] || return 1
    [[ "${who}" != *$'\n'* && "${who}" != *$'\r'* ]] || return 1

    sys::has chmod || return 1
    chmod "${who}+x" "${path}" >/dev/null 2>&1

}
mode::owner () {

    local path="${1:-}" user="${2:-}" v=""

    [[ -n "${path}" ]] || return 1
    [[ -e "${path}" || -L "${path}" ]] || return 1

    if [[ -n "${user}" ]]; then

        [[ "${user}" != *$'\n'* && "${user}" != *$'\r'* ]] || return 1

        sys::has chown || return 1
        chown "${user}" "${path}" >/dev/null 2>&1

        return

    fi

    sys::has stat || return 1

    v="$(stat -c '%U' "${path}" 2>/dev/null || true)"
    [[ -n "${v}" && "${v}" != "UNKNOWN" ]] && { printf '%s\n' "${v}"; return 0; }

    v="$(stat -f '%Su' "${path}" 2>/dev/null || true)"
    [[ -n "${v}" ]] && { printf '%s\n' "${v}"; return 0; }

    return 1

}
mode::group () {

    local path="${1:-}" group="${2:-}" v=""

    [[ -n "${path}" ]] || return 1
    [[ -e "${path}" || -L "${path}" ]] || return 1

    if [[ -n "${group}" ]]; then

        [[ "${group}" != *$'\n'* && "${group}" != *$'\r'* ]] || return 1

        sys::has chgrp || return 1
        chgrp "${group}" "${path}" >/dev/null 2>&1

        return

    fi

    sys::has stat || return 1

    v="$(stat -c '%G' "${path}" 2>/dev/null || true)"
    [[ -n "${v}" && "${v}" != "UNKNOWN" ]] && { printf '%s\n' "${v}"; return 0; }

    v="$(stat -f '%Sg' "${path}" 2>/dev/null || true)"
    [[ -n "${v}" ]] && { printf '%s\n' "${v}"; return 0; }

    return 1

}

mode::private () {

    local path="${1:-}"

    [[ -n "${path}" ]] || return 1
    [[ -e "${path}" || -L "${path}" ]] || return 1

    sys::has chmod || return 1

    if [[ -d "${path}" && ! -L "${path}" ]]; then
        chmod 700 "${path}" >/dev/null 2>&1
        return
    fi

    chmod 600 "${path}" >/dev/null 2>&1

}
mode::public () {

    local path="${1:-}"

    [[ -n "${path}" ]] || return 1
    [[ -e "${path}" || -L "${path}" ]] || return 1

    sys::has chmod || return 1

    if [[ -d "${path}" && ! -L "${path}" ]]; then
        chmod 755 "${path}" >/dev/null 2>&1
        return
    fi

    chmod 644 "${path}" >/dev/null 2>&1

}
mode::lock () {

    local path="${1:-}" who="${2:-a}"

    [[ -n "${path}" ]] || return 1
    [[ -e "${path}" || -L "${path}" ]] || return 1
    [[ -n "${who}" ]] || return 1
    [[ "${who}" != *$'\n'* && "${who}" != *$'\r'* ]] || return 1

    sys::has chmod || return 1
    chmod "${who}-w" "${path}" >/dev/null 2>&1

}
mode::unlock () {

    local path="${1:-}" who="${2:-u}"

    [[ -n "${path}" ]] || return 1
    [[ -e "${path}" || -L "${path}" ]] || return 1
    [[ -n "${who}" ]] || return 1
    [[ "${who}" != *$'\n'* && "${who}" != *$'\r'* ]] || return 1

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
