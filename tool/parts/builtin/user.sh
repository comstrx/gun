
sys::__uint () {

    [[ "${1:-}" =~ ^[0-9]+$ ]]

}
sys::__passwd_line () {

    local want="${1:-}" name="" uid="" gid="" line=""

    if [[ -z "${want}" ]]; then
        if sys::__has id; then
            want="$(id -un 2>/dev/null || true)"
        fi
    fi

    [[ -n "${want}" ]] || return 1

    if sys::is_macos && sys::__has dscl; then

        if sys::__uint "${want}"; then
            name="$(dscl . -search /Users UniqueID "${want}" 2>/dev/null | awk 'NR == 1 { print $1; exit }')"
        else
            name="${want}"
        fi

        [[ -n "${name}" ]] || return 1

        uid="$(dscl . -read "/Users/${name}" UniqueID 2>/dev/null | awk '$1 == "UniqueID:" { print $2; exit }')"
        gid="$(dscl . -read "/Users/${name}" PrimaryGroupID 2>/dev/null | awk '$1 == "PrimaryGroupID:" { print $2; exit }')"

        [[ "${uid}" =~ ^[0-9]+$ ]] || return 1
        [[ "${gid}" =~ ^[0-9]+$ ]] || return 1

        printf '%s:x:%s:%s:::\n' "${name}" "${uid}" "${gid}"
        return 0

    fi
    if sys::__has getent; then
        line="$(getent passwd "${want}" 2>/dev/null | awk 'NR == 1 { print; exit }')"
        [[ -n "${line}" ]] && { printf '%s\n' "${line}"; return 0; }
    fi

    [[ -r /etc/passwd ]] || return 1

    if sys::__uint "${want}"; then
        awk -F: -v want="${want}" '$3 == want { print; exit }' /etc/passwd
        return
    fi

    awk -F: -v want="${want}" '$1 == want { print; exit }' /etc/passwd

}
sys::__group_line () {

    local want="${1:-}" name="" gid="" members="" line=""

    if [[ -z "${want}" ]]; then
        if sys::__has id; then
            want="$(id -gn 2>/dev/null || true)"
        fi
    fi

    [[ -n "${want}" ]] || return 1

    if sys::is_macos && sys::__has dscl; then

        if sys::__uint "${want}"; then
            name="$(dscl . -search /Groups PrimaryGroupID "${want}" 2>/dev/null | awk 'NR == 1 { print $1; exit }')"
        else
            name="${want}"
        fi

        [[ -n "${name}" ]] || return 1

        gid="$(dscl . -read "/Groups/${name}" PrimaryGroupID 2>/dev/null | awk '$1 == "PrimaryGroupID:" { print $2; exit }')"
        [[ "${gid}" =~ ^[0-9]+$ ]] || return 1

        members="$(
            dscl . -read "/Groups/${name}" GroupMembership 2>/dev/null \
            | sed -n 's/^GroupMembership:[[:space:]]*//p' \
            | awk 'NR == 1 { print; exit }'
        )"

        members="${members// /,}"

        printf '%s:*:%s:%s\n' "${name}" "${gid}" "${members}"
        return 0

    fi
    if sys::__has getent; then
        line="$(getent group "${want}" 2>/dev/null | awk 'NR == 1 { print; exit }')"
        [[ -n "${line}" ]] && { printf '%s\n' "${line}"; return 0; }
    fi

    [[ -r /etc/group ]] || return 1

    if sys::__uint "${want}"; then
        awk -F: -v want="${want}" '$3 == want { print; exit }' /etc/group
        return
    fi

    awk -F: -v want="${want}" '$1 == want { print; exit }' /etc/group

}

sys::uid () {

    local want="${1:-}" line="" v=""

    if [[ -z "${want}" ]] && sys::__has id; then
        v="$(id -u 2>/dev/null || true)"
        [[ "${v}" =~ ^[0-9]+$ ]] && { printf '%s\n' "${v}"; return 0; }
    fi

    line="$(sys::__passwd_line "${want}" 2>/dev/null || true)"
    [[ -n "${line}" ]] || return 1

    v="$(printf '%s\n' "${line}" | awk -F: 'NR == 1 { print $3; exit }')"
    [[ "${v}" =~ ^[0-9]+$ ]] || return 1

    printf '%s\n' "${v}"

}
sys::uname () {

    local want="${1:-}" line="" v=""

    if [[ -z "${want}" ]] && sys::__has id; then
        v="$(id -un 2>/dev/null || true)"
        [[ -n "${v}" ]] && { printf '%s\n' "${v}"; return 0; }
    fi

    line="$(sys::__passwd_line "${want}" 2>/dev/null || true)"
    [[ -n "${line}" ]] || return 1

    v="$(printf '%s\n' "${line}" | awk -F: 'NR == 1 { print $1; exit }')"
    [[ -n "${v}" ]] || return 1

    printf '%s\n' "${v}"

}
sys::uexists () {

    [[ -n "${1:-}" ]] || return 1
    sys::__passwd_line "${1}" >/dev/null 2>&1

}
sys::ugroup () {

    local want="${1:-}" line="" gid=""

    if [[ -z "${want}" ]] && sys::__has id; then
        want="$(id -un 2>/dev/null || true)"
    fi

    [[ -n "${want}" ]] || return 1

    line="$(sys::__passwd_line "${want}" 2>/dev/null || true)"
    [[ -n "${line}" ]] || return 1

    gid="$(printf '%s\n' "${line}" | awk -F: 'NR == 1 { print $4; exit }')"
    [[ "${gid}" =~ ^[0-9]+$ ]] || return 1

    sys::gname "${gid}"

}
sys::gid () {

    local want="${1:-}" line="" v=""

    if [[ -z "${want}" ]] && sys::__has id; then
        v="$(id -g 2>/dev/null || true)"
        [[ "${v}" =~ ^[0-9]+$ ]] && { printf '%s\n' "${v}"; return 0; }
    fi

    line="$(sys::__group_line "${want}" 2>/dev/null || true)"
    [[ -n "${line}" ]] || return 1

    v="$(printf '%s\n' "${line}" | awk -F: 'NR == 1 { print $3; exit }')"
    [[ "${v}" =~ ^[0-9]+$ ]] || return 1

    printf '%s\n' "${v}"

}
sys::gname () {

    local want="${1:-}" line="" v=""

    if [[ -z "${want}" ]] && sys::__has id; then
        v="$(id -gn 2>/dev/null || true)"
        [[ -n "${v}" ]] && { printf '%s\n' "${v}"; return 0; }
    fi

    line="$(sys::__group_line "${want}" 2>/dev/null || true)"
    [[ -n "${line}" ]] || return 1

    v="$(printf '%s\n' "${line}" | awk -F: 'NR == 1 { print $1; exit }')"
    [[ -n "${v}" ]] || return 1

    printf '%s\n' "${v}"

}
sys::gexists () {

    [[ -n "${1:-}" ]] || return 1
    sys::__group_line "${1}" >/dev/null 2>&1

}
sys::gusers () {

    local want="${1:-}" line="" group="" gid="" members=""

    [[ -n "${want}" ]] || return 1

    line="$(sys::__group_line "${want}" 2>/dev/null || true)"
    [[ -n "${line}" ]] || return 1

    group="$(printf '%s\n' "${line}" | awk -F: 'NR == 1 { print $1; exit }')"
    gid="$(printf '%s\n' "${line}" | awk -F: 'NR == 1 { print $3; exit }')"
    members="$(printf '%s\n' "${line}" | awk -F: 'NR == 1 { print $4; exit }')"

    [[ -n "${group}" ]] || return 1
    [[ "${gid}" =~ ^[0-9]+$ ]] || return 1

    {
        if sys::is_macos && sys::__has dscl; then
            dscl . -list /Users PrimaryGroupID 2>/dev/null | awk -v gid="${gid}" '$2 == gid { print $1 }'
        elif sys::__has getent; then
            getent passwd 2>/dev/null | awk -F: -v gid="${gid}" '$4 == gid { print $1 }'
        elif [[ -r /etc/passwd ]]; then
            awk -F: -v gid="${gid}" '$4 == gid { print $1 }' /etc/passwd
        fi

        if [[ -n "${members}" ]]; then
            printf '%s\n' "${members}" | tr ',' '\n'
        fi
    } | awk 'NF && !seen[$0]++'

}
sys::users () {

    if sys::is_macos && sys::__has dscl; then
        dscl . -list /Users UniqueID 2>/dev/null | awk '$2 ~ /^[0-9]+$/ { print $1 }'
        return
    fi
    if sys::__has getent; then
        getent passwd 2>/dev/null | awk -F: 'NF { print $1 }'
        return
    fi

    [[ -r /etc/passwd ]] || return 1
    awk -F: 'NF { print $1 }' /etc/passwd

}
sys::groups () {

    local want="${1:-}" v=""

    if [[ -n "${want}" ]] && sys::__uint "${want}"; then
        want="$(sys::uname "${want}" 2>/dev/null || true)"
    fi

    if [[ -n "${want}" ]]; then
        v="$(id -Gn "${want}" 2>/dev/null || true)"
    else
        v="$(id -Gn 2>/dev/null || true)"
    fi

    [[ -n "${v}" ]] || return 1

    printf '%s\n' "${v}" | tr ' ' '\n' | awk 'NF && !seen[$0]++'

}


sys::__uint () {

    [[ "${1:-}" =~ ^[0-9]+$ ]]

}
sys::__require_root () {

    sys::is_root

}
sys::__default_shell () {

    if sys::is_macos && [[ -x /bin/zsh ]]; then
        printf '%s\n' "/bin/zsh"
        return 0
    fi
    if [[ -x /bin/bash ]]; then
        printf '%s\n' "/bin/bash"
        return 0
    fi
    if [[ -x /bin/sh ]]; then
        printf '%s\n' "/bin/sh"
        return 0
    fi

    return 1

}
sys::__next_uid () {

    if sys::is_macos && sys::__has dscl; then
        dscl . -list /Users UniqueID 2>/dev/null \
        | awk '$2 ~ /^[0-9]+$/ && $2 >= 500 { if ( $2 > max ) max = $2 } END { if ( max < 500 ) max = 500; print max + 1 }'
        return
    fi

    return 1

}
sys::__next_gid () {

    if sys::is_macos && sys::__has dscl; then
        dscl . -list /Groups PrimaryGroupID 2>/dev/null \
        | awk '$2 ~ /^[0-9]+$/ && $2 >= 500 { if ( $2 > max ) max = $2 } END { if ( max < 500 ) max = 500; print max + 1 }'
        return
    fi

    return 1

}
sys::__passwd_line () {

    local want="${1:-}" name="" uid="" gid="" line=""

    if [[ -z "${want}" ]] && sys::__has id; then
        want="$(id -un 2>/dev/null || true)"
    fi

    [[ -n "${want}" ]] || return 1

    if sys::is_macos && sys::__has dscl; then

        if sys::__uint "${want}"; then
            name="$(dscl . -search /Users UniqueID "${want}" 2>/dev/null | awk 'NR == 1 { print $1; exit }')"
        else
            name="${want}"
        fi

        [[ -n "${name}" ]] || return 1

        uid="$(dscl . -read "/Users/${name}" UniqueID 2>/dev/null | awk '$1 == "UniqueID:" { print $2; exit }')"
        gid="$(dscl . -read "/Users/${name}" PrimaryGroupID 2>/dev/null | awk '$1 == "PrimaryGroupID:" { print $2; exit }')"

        [[ "${uid}" =~ ^[0-9]+$ ]] || return 1
        [[ "${gid}" =~ ^[0-9]+$ ]] || return 1

        printf '%s:x:%s:%s:::\n' "${name}" "${uid}" "${gid}"
        return 0

    fi

    if sys::__has getent; then
        line="$(getent passwd "${want}" 2>/dev/null | awk 'NR == 1 { print; exit }')"
        [[ -n "${line}" ]] && { printf '%s\n' "${line}"; return 0; }
    fi

    [[ -r /etc/passwd ]] || return 1

    if sys::__uint "${want}"; then
        awk -F: -v want="${want}" '$3 == want { print; exit }' /etc/passwd
        return
    fi

    awk -F: -v want="${want}" '$1 == want { print; exit }' /etc/passwd

}
sys::__group_line () {

    local want="${1:-}" name="" gid="" members="" line=""

    if [[ -z "${want}" ]] && sys::__has id; then
        want="$(id -gn 2>/dev/null || true)"
    fi

    [[ -n "${want}" ]] || return 1

    if sys::is_macos && sys::__has dscl; then

        if sys::__uint "${want}"; then
            name="$(dscl . -search /Groups PrimaryGroupID "${want}" 2>/dev/null | awk 'NR == 1 { print $1; exit }')"
        else
            name="${want}"
        fi

        [[ -n "${name}" ]] || return 1

        gid="$(dscl . -read "/Groups/${name}" PrimaryGroupID 2>/dev/null | awk '$1 == "PrimaryGroupID:" { print $2; exit }')"
        [[ "${gid}" =~ ^[0-9]+$ ]] || return 1

        members="$(
            dscl . -read "/Groups/${name}" GroupMembership 2>/dev/null \
            | sed -n 's/^GroupMembership:[[:space:]]*//p' \
            | awk 'NR == 1 { print; exit }'
        )"

        members="${members// /,}"

        printf '%s:*:%s:%s\n' "${name}" "${gid}" "${members}"
        return 0

    fi

    if sys::__has getent; then
        line="$(getent group "${want}" 2>/dev/null | awk 'NR == 1 { print; exit }')"
        [[ -n "${line}" ]] && { printf '%s\n' "${line}"; return 0; }
    fi

    [[ -r /etc/group ]] || return 1

    if sys::__uint "${want}"; then
        awk -F: -v want="${want}" '$3 == want { print; exit }' /etc/group
        return
    fi

    awk -F: -v want="${want}" '$1 == want { print; exit }' /etc/group

}
sys::__passwd_field () {

    local want="${1:-}" idx="${2:-}" line="" v=""

    [[ "${idx}" =~ ^[1-7]$ ]] || return 1

    line="$(sys::__passwd_line "${want}" 2>/dev/null || true)"
    [[ -n "${line}" ]] || return 1

    v="$(printf '%s\n' "${line}" | awk -F: -v idx="${idx}" 'NR == 1 { print $idx; exit }')"
    [[ -n "${v}" ]] || return 1

    printf '%s\n' "${v}"

}
sys::__user_name () {

    local want="${1:-}" v=""

    if [[ -z "${want}" ]] && sys::__has id; then
        want="$(id -un 2>/dev/null || true)"
    fi

    [[ -n "${want}" ]] || return 1

    if sys::__uint "${want}"; then
        v="$(sys::__passwd_field "${want}" 1 2>/dev/null || true)"
        [[ -n "${v}" ]] || return 1
        printf '%s\n' "${v}"
        return 0
    fi

    printf '%s\n' "${want}"

}
sys::__group_name () {

    local want="${1:-}" line="" v=""

    if [[ -z "${want}" ]] && sys::__has id; then
        want="$(id -gn 2>/dev/null || true)"
    fi

    [[ -n "${want}" ]] || return 1

    if sys::__uint "${want}"; then
        line="$(sys::__group_line "${want}" 2>/dev/null || true)"
        [[ -n "${line}" ]] || return 1
        v="$(printf '%s\n' "${line}" | awk -F: 'NR == 1 { print $1; exit }')"
        [[ -n "${v}" ]] || return 1
        printf '%s\n' "${v}"
        return 0
    fi

    printf '%s\n' "${want}"

}

sys::add_group () {

    local group="${1:-}" gid="${2:-}" path=""

    [[ -n "${group}" ]] || return 1
    sys::__require_root || return 1

    sys::__group_line "${group}" >/dev/null 2>&1 && return 0

    if sys::is_macos; then

        [[ -n "${gid}" ]] || gid="$(sys::__next_gid 2>/dev/null || true)"
        [[ "${gid}" =~ ^[0-9]+$ ]] || return 1

        path="/Groups/${group}"

        dscl . -create "${path}" >/dev/null 2>&1                                    || return 1
        dscl . -create "${path}" PrimaryGroupID "${gid}" >/dev/null 2>&1           || { dscl . -delete "${path}" >/dev/null 2>&1 || true; return 1; }
        dscl . -create "${path}" Password "*" >/dev/null 2>&1                       || { dscl . -delete "${path}" >/dev/null 2>&1 || true; return 1; }

        return 0

    fi

    if sys::__has groupadd; then

        if [[ -n "${gid}" ]]; then
            groupadd -g "${gid}" "${group}"
            return
        fi

        groupadd "${group}"
        return

    fi
    if sys::__has addgroup; then

        if [[ -n "${gid}" ]]; then
            addgroup -g "${gid}" "${group}"
            return
        fi

        addgroup "${group}"
        return

    fi

    return 1

}
sys::del_group () {

    local group="${1:-}" name=""

    [[ -n "${group}" ]] || return 1
    sys::__require_root || return 1

    name="$(sys::__group_name "${group}" 2>/dev/null || true)"
    [[ -n "${name}" ]] || return 0

    if sys::is_macos; then

        if sys::__has dseditgroup; then
            dseditgroup -o delete "${name}" >/dev/null 2>&1
            return
        fi

        dscl . -delete "/Groups/${name}" >/dev/null 2>&1
        return

    fi

    if sys::__has groupdel; then
        groupdel "${name}"
        return
    fi
    if sys::__has delgroup; then
        delgroup "${name}"
        return
    fi

    return 1

}
sys::add_user () {

    local user="${1:-}" group="${2:-}" uid="" gid="" shell="" home="" path=""

    [[ -n "${user}" ]] || return 1
    sys::__require_root || return 1

    sys::__passwd_line "${user}" >/dev/null 2>&1 && return 0

    [[ -n "${group}" ]] || group="${user}"
    sys::__group_line "${group}" >/dev/null 2>&1 || sys::add_group "${group}" || return 1

    shell="$(sys::__default_shell 2>/dev/null || true)"
    [[ -n "${shell}" ]] || return 1

    if sys::is_macos; then

        uid="$(sys::__next_uid 2>/dev/null || true)"
        gid="$(printf '%s\n' "$(sys::__group_line "${group}" 2>/dev/null || true)" | awk -F: 'NR == 1 { print $3; exit }')"
        home="/Users/${user}"
        path="/Users/${user}"

        [[ "${uid}" =~ ^[0-9]+$ ]] || return 1
        [[ "${gid}" =~ ^[0-9]+$ ]] || return 1

        dscl . -create "${path}" >/dev/null 2>&1                                   || return 1
        dscl . -create "${path}" UniqueID "${uid}" >/dev/null 2>&1                 || { dscl . -delete "${path}" >/dev/null 2>&1 || true; return 1; }
        dscl . -create "${path}" PrimaryGroupID "${gid}" >/dev/null 2>&1           || { dscl . -delete "${path}" >/dev/null 2>&1 || true; return 1; }
        dscl . -create "${path}" NFSHomeDirectory "${home}" >/dev/null 2>&1        || { dscl . -delete "${path}" >/dev/null 2>&1 || true; return 1; }
        dscl . -create "${path}" UserShell "${shell}" >/dev/null 2>&1              || { dscl . -delete "${path}" >/dev/null 2>&1 || true; return 1; }
        dscl . -create "${path}" RealName "${user}" >/dev/null 2>&1                || { dscl . -delete "${path}" >/dev/null 2>&1 || true; return 1; }

        if sys::__has createhomedir; then
            createhomedir -c -u "${user}" >/dev/null 2>&1 || true
        else
            mkdir -p "${home}" >/dev/null 2>&1 || true
        fi

        return 0

    fi

    if sys::__has useradd; then
        useradd -m -g "${group}" -s "${shell}" "${user}"
        return
    fi
    if sys::__has adduser; then
        adduser -D -G "${group}" -s "${shell}" "${user}"
        return
    fi

    return 1

}
sys::del_user () {

    local user="${1:-}" name=""

    [[ -n "${user}" ]] || return 1
    sys::__require_root || return 1

    name="$(sys::__user_name "${user}" 2>/dev/null || true)"
    [[ -n "${name}" ]] || return 0

    if sys::is_macos; then

        if sys::__has sysadminctl; then
            sysadminctl -deleteUser "${name}" >/dev/null 2>&1
            return
        fi

        dscl . -delete "/Users/${name}" >/dev/null 2>&1
        return

    fi

    if sys::__has userdel; then
        userdel -r "${name}"
        return
    fi
    if sys::__has deluser; then
        deluser --remove-home "${name}" 2>/dev/null || deluser "${name}"
        return
    fi

    return 1

}
sys::user_home () {

    local want="${1:-}" user="" v=""

    user="$(sys::__user_name "${want}" 2>/dev/null || true)"
    [[ -n "${user}" ]] || return 1

    if sys::is_macos && sys::__has dscl; then
        v="$(dscl . -read "/Users/${user}" NFSHomeDirectory 2>/dev/null | awk '$1 == "NFSHomeDirectory:" { print $2; exit }')"
        [[ -n "${v}" ]] || return 1
        printf '%s\n' "${v}"
        return 0
    fi

    sys::__passwd_field "${user}" 6

}
sys::user_shell () {

    local want="${1:-}" user="" v=""

    user="$(sys::__user_name "${want}" 2>/dev/null || true)"
    [[ -n "${user}" ]] || return 1

    if sys::is_macos && sys::__has dscl; then
        v="$(dscl . -read "/Users/${user}" UserShell 2>/dev/null | awk '$1 == "UserShell:" { print $2; exit }')"
        [[ -n "${v}" ]] || return 1
        printf '%s\n' "${v}"
        return 0
    fi

    sys::__passwd_field "${user}" 7

}
sys::user_gecos () {

    local want="${1:-}" user="" v=""

    user="$(sys::__user_name "${want}" 2>/dev/null || true)"
    [[ -n "${user}" ]] || return 1

    if sys::is_macos && sys::__has dscl; then
        v="$(dscl . -read "/Users/${user}" RealName 2>/dev/null | sed -n 's/^RealName:[[:space:]]*//p' | head -n 1)"
        [[ -n "${v}" ]] || return 1
        printf '%s\n' "${v}"
        return 0
    fi

    sys::__passwd_field "${user}" 5

}
