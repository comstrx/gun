
sys::uid () {

    local v=""

    if sys::is_windows && sys::has powershell.exe; then

        v="$(powershell.exe -NoProfile -NonInteractive -Command "[Security.Principal.WindowsIdentity]::GetCurrent().User.Value.Split('-')[-1]" 2>/dev/null | tr -d '\r' || true)"
        [[ "${v}" =~ ^[0-9]+$ ]] && { printf '%s\n' "${v}"; return 0; }

    fi
    if sys::has id; then

        v="$(id -u 2>/dev/null || true)"
        [[ "${v}" =~ ^[0-9]+$ ]] && { printf '%s\n' "${v}"; return 0; }

    fi

    return 1

}
sys::uname () {

    local v=""

    if sys::has id; then

        v="$(id -un 2>/dev/null || true)"
        [[ -n "${v}" ]] && { printf '%s\n' "${v}"; return 0; }

    fi
    if sys::has whoami; then

        v="$(whoami 2>/dev/null || true)"
        v="${v##*\\}"
        [[ -n "${v}" ]] && { printf '%s\n' "${v}"; return 0; }

    fi

    v="${USER:-${USERNAME:-}}"
    [[ -n "${v}" ]] || return 1

    printf '%s\n' "${v}"

}
sys::uexists () {

    local user="${1:-}" group="${2:-}" current="" v="" x="" found=0

    [[ -n "${user}" ]] || return 1
    [[ "${user}" != *$'\n'* && "${user}" != *$'\r'* ]] || return 1

    current="$(sys::uname 2>/dev/null || true)"

    if [[ -n "${current}" && "${user}" == "${current}" ]]; then

        [[ -n "${group}" ]] || return 0
        [[ "${group}" != *$'\n'* && "${group}" != *$'\r'* ]] || return 1

        v="$(sys::groups "${user}" 2>/dev/null || true)"
        [[ -n "${v}" ]] || return 1

        while IFS= read -r x || [[ -n "${x}" ]]; do

            [[ "${x}" == "${group}" ]] && return 0

        done <<< "${v}"

        return 1

    fi

    if sys::is_linux || sys::is_wsl; then

        if sys::has getent; then

            getent passwd "${user}" >/dev/null 2>&1 || return 1

        elif [[ -r /etc/passwd ]]; then

            awk -F: -v u="${user}" '$1 == u { found = 1; exit } END { exit(found ? 0 : 1) }' /etc/passwd >/dev/null 2>&1 || return 1

        else

            return 1

        fi

    elif sys::is_macos; then

        sys::has dscl || return 1
        dscl . -read "/Users/${user}" >/dev/null 2>&1 || return 1

    elif sys::is_windows; then

        if sys::has powershell.exe; then

            # shellcheck disable=SC2016
            SYS_USER_QUERY="${user}" powershell.exe -NoProfile -NonInteractive -Command '
                try { Get-LocalUser -Name $env:SYS_USER_QUERY -ErrorAction Stop | Out-Null; exit 0 } catch { exit 1 }
            ' >/dev/null 2>&1 || return 1

        elif sys::has net.exe; then

            net.exe user "${user}" >/dev/null 2>&1 || return 1

        else

            return 1

        fi

    else

        return 1

    fi

    [[ -n "${group}" ]] || return 0
    [[ "${group}" != *$'\n'* && "${group}" != *$'\r'* ]] || return 1

    v="$(sys::groups "${user}" 2>/dev/null || true)"
    [[ -n "${v}" ]] || return 1

    while IFS= read -r x || [[ -n "${x}" ]]; do

        [[ "${x}" == "${group}" ]] && return 0

    done <<< "${v}"

    return 1

}

sys::uhome () {

    local user="" v=""

    [[ -n "${HOME:-}" ]] && { printf '%s\n' "${HOME}"; return 0; }

    user="$(sys::uname 2>/dev/null || true)"
    [[ -n "${user}" ]] || return 1

    if sys::is_linux || sys::is_wsl; then

        if sys::has getent; then

            v="$(getent passwd "${user}" 2>/dev/null | awk -F: 'NR == 1 { print $6 }')"
            [[ -n "${v}" ]] && { printf '%s\n' "${v}"; return 0; }

        fi

        [[ -r /etc/passwd ]] || return 1

        v="$(awk -F: -v u="${user}" '$1 == u { print $6; exit }' /etc/passwd 2>/dev/null)"
        [[ -n "${v}" ]] && { printf '%s\n' "${v}"; return 0; }

        return 1

    fi
    if sys::is_macos; then

        sys::has dscl || return 1

        v="$(dscl . -read "/Users/${user}" NFSHomeDirectory 2>/dev/null | awk '{print $2}' | head -n 1)"
        [[ -n "${v}" ]] && { printf '%s\n' "${v}"; return 0; }

        return 1

    fi
    if sys::is_windows; then

        v="${USERPROFILE:-}"
        [[ -n "${v}" ]] && { printf '%s\n' "${v}"; return 0; }

        if sys::has powershell.exe; then

            v="$(powershell.exe -NoProfile -NonInteractive -Command "[Environment]::GetFolderPath('UserProfile')" 2>/dev/null | tr -d '\r' || true)"
            [[ -n "${v}" ]] && { printf '%s\n' "${v}"; return 0; }

        fi

        return 1

    fi

    return 1

}
sys::ushell () {

    local user="" v=""

    [[ -n "${SHELL:-}" ]] && { printf '%s\n' "${SHELL}"; return 0; }

    user="$(sys::uname 2>/dev/null || true)"
    [[ -n "${user}" ]] || return 1

    if sys::is_linux || sys::is_wsl; then

        if sys::has getent; then

            v="$(getent passwd "${user}" 2>/dev/null | awk -F: 'NR == 1 { print $7 }')"
            [[ -n "${v}" ]] && { printf '%s\n' "${v}"; return 0; }

        fi

        [[ -r /etc/passwd ]] || return 1

        v="$(awk -F: -v u="${user}" '$1 == u { print $7; exit }' /etc/passwd 2>/dev/null)"
        [[ -n "${v}" ]] && { printf '%s\n' "${v}"; return 0; }

        return 1

    fi
    if sys::is_macos; then

        sys::has dscl || return 1

        v="$(dscl . -read "/Users/${user}" UserShell 2>/dev/null | awk '{print $2}' | head -n 1)"
        [[ -n "${v}" ]] && { printf '%s\n' "${v}"; return 0; }

        return 1

    fi
    if sys::is_windows; then

        [[ -n "${COMSPEC:-}" ]] && { printf '%s\n' "${COMSPEC}"; return 0; }

        if sys::has powershell.exe; then

            v="$(powershell.exe -NoProfile -NonInteractive -Command "(Get-Command powershell.exe).Source" 2>/dev/null | tr -d '\r' || true)"
            [[ -n "${v}" ]] && { printf '%s\n' "${v}"; return 0; }

        fi

        return 1

    fi

    return 1

}
sys::ugroup () {

    local user="${1:-}" current="" v=""

    current="$(sys::uname 2>/dev/null || true)"

    [[ -n "${user}" ]] || user="${current}"
    [[ -n "${user}" ]] || return 1
    [[ "${user}" != *$'\n'* && "${user}" != *$'\r'* ]] || return 1

    if sys::is_windows && sys::has powershell.exe; then

        # shellcheck disable=SC2016
        v="$(SYS_USER_QUERY="${user}" powershell.exe -NoProfile -NonInteractive -Command '
            $u = $env:SYS_USER_QUERY
            $first = $null
            $users = $null
            $admins = $null

            Get-LocalGroup | ForEach-Object {
                try {
                    $name = $_.Name
                    $hit  = Get-LocalGroupMember -Group $name -ErrorAction Stop | Where-Object { $_.Name -match "\\$u$" }

                    if ( $hit ) {
                        if ( $name -eq "Users" ) { $users = $name }
                        elseif ( $name -eq "Administrators" ) { $admins = $name }
                        elseif ( -not $first ) { $first = $name }
                    }
                } catch {}
            }

            if ( $users ) { $users; exit 0 }
            if ( $admins ) { $admins; exit 0 }
            if ( $first ) { $first; exit 0 }

            exit 1
        ' 2>/dev/null | tr -d '\r' | head -n 1 || true)"

        [[ -n "${v}" ]] && { printf '%s\n' "${v}"; return 0; }

    fi
    if sys::has id; then

        if [[ -n "${current}" && "${user}" == "${current}" ]]; then
            v="$(id -gn 2>/dev/null || true)"
        else
            v="$(id -gn "${user}" 2>/dev/null || true)"
        fi

        [[ -n "${v}" ]] && { printf '%s\n' "${v}"; return 0; }

    fi

    return 1

}

sys::gid () {

    local v="" g=""

    if sys::is_windows; then

        if sys::has powershell.exe; then

            # shellcheck disable=SC2016
            g="$(SYS_USER_QUERY="$(sys::uname 2>/dev/null || true)" powershell.exe -NoProfile -NonInteractive -Command '
                $u = $env:SYS_USER_QUERY
                $first = $null
                $users = $null
                $admins = $null

                Get-LocalGroup | ForEach-Object {
                    try {
                        $name = $_.Name
                        $hit  = Get-LocalGroupMember -Group $name -ErrorAction Stop | Where-Object { $_.Name -match "\\$u$" }

                        if ( $hit ) {
                            if ( $name -eq "Users" ) { $users = $name }
                            elseif ( $name -eq "Administrators" ) { $admins = $name }
                            elseif ( -not $first ) { $first = $name }
                        }
                    } catch {}
                }

                if ( $users ) { $users; exit 0 }
                if ( $admins ) { $admins; exit 0 }
                if ( $first ) { $first; exit 0 }

                exit 1
            ' 2>/dev/null | tr -d '\r' | head -n 1 || true)"

            if [[ -n "${g}" ]]; then

                # shellcheck disable=SC2016
                v="$(SYS_GROUP_QUERY="${g}" powershell.exe -NoProfile -NonInteractive -Command '
                    try {
                        $sid = ( Get-LocalGroup -Name $env:SYS_GROUP_QUERY -ErrorAction Stop ).SID.Value
                        $rid = $sid.Split( "-" )[ -1 ]
                        $rid
                        exit 0
                    } catch {
                        exit 1
                    }
                ' 2>/dev/null | tr -d '\r' || true)"

                [[ "${v}" =~ ^[0-9]+$ ]] && { printf '%s\n' "${v}"; return 0; }

            fi

        fi

    fi
    if sys::has id; then

        v="$(id -g 2>/dev/null || true)"
        [[ "${v}" =~ ^[0-9]+$ ]] && { printf '%s\n' "${v}"; return 0; }

    fi

    return 1

}
sys::gname () {

    local v=""

    if sys::is_windows; then

        v="$(sys::ugroup 2>/dev/null || true)"
        [[ -n "${v}" ]] && { printf '%s\n' "${v}"; return 0; }

    fi
    if sys::has id; then

        v="$(id -gn 2>/dev/null || true)"
        [[ -n "${v}" ]] && { printf '%s\n' "${v}"; return 0; }

    fi

    return 1

}
sys::gexists () {

    local group="${1:-}" found=0

    [[ -n "${group}" ]] || return 1
    [[ "${group}" != *$'\n'* && "${group}" != *$'\r'* ]] || return 1

    if sys::is_linux || sys::is_wsl; then

        if sys::has getent; then
            getent group "${group}" >/dev/null 2>&1 || return 1
        elif [[ -r /etc/group ]]; then
            awk -F: -v g="${group}" '$1 == g { found = 1; exit } END { exit(found ? 0 : 1) }' /etc/group >/dev/null 2>&1 || return 1
        else
            return 1
        fi

        return 0

    fi
    if sys::is_macos; then

        sys::has dscl || return 1
        dscl . -read "/Groups/${group}" >/dev/null 2>&1 || return 1
        return 0

    fi
    if sys::is_windows; then

        if sys::has powershell.exe; then

            # shellcheck disable=SC2016
            SYS_GROUP_QUERY="${group}" powershell.exe -NoProfile -NonInteractive -Command '
                try { Get-LocalGroup -Name $env:SYS_GROUP_QUERY -ErrorAction Stop | Out-Null; exit 0 } catch { exit 1 }
            ' >/dev/null 2>&1 || return 1

        elif sys::has net.exe; then

            net.exe localgroup "${group}" >/dev/null 2>&1 || return 1

        else

            return 1

        fi

        return 0

    fi

    return 1

}

sys::groups () {

    local user="${1:-}" current="" v="" x=""

    current="$(sys::uname 2>/dev/null || true)"

    if [[ -n "${user}" ]]; then

        [[ "${user}" != *$'\n'* && "${user}" != *$'\r'* ]] || return 1

        if sys::is_windows && sys::has powershell.exe; then

            # shellcheck disable=SC2016
            SYS_USER_QUERY="${user}" powershell.exe -NoProfile -NonInteractive -Command '
                $u = $env:SYS_USER_QUERY
                Get-LocalGroup | ForEach-Object {
                    try {
                        $name = $_.Name
                        $hit  = Get-LocalGroupMember -Group $name -ErrorAction Stop | Where-Object { $_.Name -match "\\$u$" }
                        if ( $hit ) { $name }
                    } catch {}
                }
            ' 2>/dev/null | tr -d '\r' | awk 'NF && !seen[$0]++ { print }'

            return

        fi
        if sys::has id; then

            if [[ -n "${current}" && "${user}" == "${current}" ]]; then v="$(id -Gn 2>/dev/null || true)"
            else v="$(id -Gn "${user}" 2>/dev/null || true)"
            fi

            [[ -n "${v}" ]] || return 1

            for x in ${v}; do
                printf '%s\n' "${x}"
            done | awk 'NF && !seen[$0]++ { print }'

            return 0

        fi

        return 1

    fi
    if sys::is_linux || sys::is_wsl; then

        if sys::has getent; then
            getent group 2>/dev/null | awk -F: '{print $1}' | awk 'NF && !seen[$0]++ { print }'
            return
        fi

        [[ -r /etc/group ]] || return 1
        awk -F: '{print $1}' /etc/group 2>/dev/null | awk 'NF && !seen[$0]++ { print }'

        return

    fi
    if sys::is_macos; then

        sys::has dscl || return 1
        dscl . -list /Groups 2>/dev/null | awk 'NF && !seen[$0]++ { print }'

        return

    fi
    if sys::is_windows; then

        if sys::has powershell.exe; then

            # shellcheck disable=SC2016
            v="$(SYS_USER_QUERY="${user}" powershell.exe -NoProfile -NonInteractive -Command '
                $u = $env:SYS_USER_QUERY
                Get-LocalGroup | ForEach-Object {
                    try {
                        $name = $_.Name
                        $hit  = Get-LocalGroupMember -Group $name -ErrorAction Stop | Where-Object { $_.Name -match "\\$u$" }
                        if ( $hit ) { $name }
                    } catch {}
                }
            ' 2>/dev/null | tr -d '\r' | awk 'NF && !seen[$0]++ { print }' || true)"

            [[ -n "${v}" ]] || return 1
            printf '%s\n' "${v}"

            return 0

        fi
        if sys::has net.exe; then

            net.exe localgroup 2>/dev/null | tr -d '\r' | awk '
                BEGIN { cap = 0 }
                /^---/ { cap = 1; next }
                /^The command completed successfully\./ { cap = 0 }
                cap {
                    line = $0
                    sub(/^[[:space:]]+/, "", line)
                    if ( line != "" ) print line
                }
            ' | awk 'NF && !seen[$0]++ { print }'

            return

        fi

        return 1

    fi

    return 1

}
sys::addgroup () {

    local group="${1:-}" gid=""

    [[ -n "${group}" ]] || return 1
    [[ "${group}" != *$'\n'* && "${group}" != *$'\r'* ]] || return 1

    sys::gexists "${group}" && return 0

    if sys::is_linux || sys::is_wsl; then

        if sys::has groupadd; then
            groupadd "${group}" >/dev/null 2>&1
            return
        fi
        if sys::has addgroup; then
            addgroup "${group}" >/dev/null 2>&1
            return
        fi

        return 1

    fi
    if sys::is_macos; then

        sys::has dscl || return 1

        gid="$(dscl . -list /Groups PrimaryGroupID 2>/dev/null | awk '
            $2 ~ /^[0-9]+$/ && $2 >= 500 {
                if ( $2 > max ) max = $2
            }
            END {
                if ( max < 500 ) max = 500
                print max + 1
            }
        ')"

        [[ "${gid}" =~ ^[0-9]+$ ]] || return 1

        dscl . -create "/Groups/${group}" >/dev/null 2>&1 || return 1
        dscl . -create "/Groups/${group}" PrimaryGroupID "${gid}" >/dev/null 2>&1 || return 1
        dscl . -create "/Groups/${group}" RealName "${group}" >/dev/null 2>&1 || true

        return 0

    fi
    if sys::is_windows; then

        if sys::has net.exe; then
            net.exe localgroup "${group}" /add >/dev/null 2>&1
            return
        fi
        if sys::has powershell.exe; then

            # shellcheck disable=SC2016
            SYS_GROUP_QUERY="${group}" powershell.exe -NoProfile -NonInteractive -Command '
                New-LocalGroup -Name $env:SYS_GROUP_QUERY | Out-Null
            ' >/dev/null 2>&1

            return

        fi

        return 1

    fi

    return 1

}
sys::delgroup () {

    local group="${1:-}" user="${2:-}"

    [[ -n "${group}" ]] || return 1
    [[ "${group}" != *$'\n'* && "${group}" != *$'\r'* ]] || return 1

    sys::gexists "${group}" || return 0

    if [[ -n "${user}" ]]; then

        [[ "${user}" != *$'\n'* && "${user}" != *$'\r'* ]] || return 1
        sys::uexists "${user}" "${group}" || return 1

    fi
    if sys::is_linux || sys::is_wsl; then

        if sys::has groupdel; then
            groupdel "${group}" >/dev/null 2>&1
            return
        fi
        if sys::has delgroup; then
            delgroup "${group}" >/dev/null 2>&1
            return
        fi

        return 1

    fi
    if sys::is_macos; then

        if sys::has dscl; then
            dscl . -delete "/Groups/${group}" >/dev/null 2>&1
            return
        fi

        return 1

    fi
    if sys::is_windows; then

        if sys::has net.exe; then
            net.exe localgroup "${group}" /delete >/dev/null 2>&1
            return
        fi
        if sys::has powershell.exe; then

            # shellcheck disable=SC2016
            SYS_GROUP_QUERY="${group}" powershell.exe -NoProfile -NonInteractive -Command '
                Remove-LocalGroup -Name $env:SYS_GROUP_QUERY
            ' >/dev/null 2>&1

            return

        fi

        return 1

    fi

    return 1

}

sys::users () {

    local group="${1:-}" user="" found=0

    if [[ -z "${group}" ]]; then

        if sys::is_linux || sys::is_wsl; then

            if sys::has getent; then

                getent passwd 2>/dev/null | awk -F: '{print $1}' | awk 'NF && !seen[$0]++ { print }'
                return

            fi

            [[ -r /etc/passwd ]] || return 1
            awk -F: '{print $1}' /etc/passwd 2>/dev/null | awk 'NF && !seen[$0]++ { print }'

            return

        fi
        if sys::is_macos; then

            sys::has dscl || return 1
            dscl . -list /Users 2>/dev/null | awk 'NF && !seen[$0]++ { print }'
            return

        fi
        if sys::is_windows; then

            if sys::has powershell.exe; then
                powershell.exe -NoProfile -NonInteractive -Command "Get-LocalUser | Select-Object -ExpandProperty Name" 2>/dev/null | tr -d '\r' | awk 'NF && !seen[$0]++ { print }'
                return
            fi
            if sys::has net.exe; then

                net.exe user 2>/dev/null | tr -d '\r' | awk '
                    BEGIN { cap = 0 }
                    /^---/ { cap = 1; next }
                    /^The command completed successfully\./ { cap = 0 }
                    cap {
                        for ( i = 1; i <= NF; i++ ) print $i
                    }
                ' | awk 'NF && !seen[$0]++ { print }'

                return

            fi

            return 1

        fi

        return 1

    fi

    [[ -n "${group}" ]] || return 1
    [[ "${group}" != *$'\n'* && "${group}" != *$'\r'* ]] || return 1

    sys::gexists "${group}" || return 1

    if sys::is_linux || sys::is_wsl; then

        while IFS=: read -r _user _x _uid _gid _rest || [[ -n "${_user:-}" ]]; do

            [[ -n "${_user:-}" ]] || continue

            if [[ "${_gid:-}" =~ ^[0-9]+$ ]]; then

                if sys::has getent; then
                    user="$(getent group "${_gid}" 2>/dev/null | awk -F: 'NR == 1 { print $1 }')"
                else
                    user="$(awk -F: -v g="${_gid}" '$3 == g { print $1; exit }' /etc/group 2>/dev/null)"
                fi

                if [[ "${user}" == "${group}" ]]; then

                    printf '%s\n' "${_user}"
                    found=1

                    continue

                fi

            fi
            if sys::groups "${_user}" 2>/dev/null | grep -Fqx -- "${group}"; then
                printf '%s\n' "${_user}"
                found=1
            fi

        done < <(
            if sys::has getent; then
                getent passwd 2>/dev/null
            else
                cat /etc/passwd 2>/dev/null
            fi
        )

    elif sys::is_macos; then

        while IFS= read -r user || [[ -n "${user}" ]]; do

            [[ -n "${user}" ]] || continue

            if [[ "$(sys::ugroup "${user}" 2>/dev/null || true)" == "${group}" ]]; then
                printf '%s\n' "${user}"
                found=1
                continue
            fi
            if sys::groups "${user}" 2>/dev/null | grep -Fqx -- "${group}"; then
                printf '%s\n' "${user}"
                found=1
            fi

        done < <(dscl . -list /Users 2>/dev/null)

    elif sys::is_windows; then

        while IFS= read -r user || [[ -n "${user}" ]]; do

            [[ -n "${user}" ]] || continue

            if sys::groups "${user}" 2>/dev/null | grep -Fqx -- "${group}"; then
                printf '%s\n' "${user}"
                found=1
            fi

        done < <(
            if sys::has powershell.exe; then
                powershell.exe -NoProfile -NonInteractive -Command "Get-LocalUser | Select-Object -ExpandProperty Name" 2>/dev/null | tr -d '\r'
            else
                net.exe user 2>/dev/null | tr -d '\r' | awk '
                    BEGIN { cap = 0 }
                    /^---/ { cap = 1; next }
                    /^The command completed successfully\./ { cap = 0 }
                    cap {
                        for ( i = 1; i <= NF; i++ ) print $i
                    }
                '
            fi
        )

    else

        return 1

    fi

    (( found )) || return 1

}
sys::adduser () {

    local user="${1:-}" group="${2:-}" uid="" gid="" home="" shell=""

    [[ -n "${user}" ]] || return 1
    [[ "${user}" != *$'\n'* && "${user}" != *$'\r'* ]] || return 1

    sys::uexists "${user}" && return 0

    [[ -n "${group}" ]] || group="$(sys::gname 2>/dev/null || true)"
    [[ -n "${group}" ]] || return 1
    [[ "${group}" != *$'\n'* && "${group}" != *$'\r'* ]] || return 1

    sys::gexists "${group}" || return 1

    if sys::is_linux || sys::is_wsl; then

        if sys::has useradd; then
            useradd -m -g "${group}" "${user}" >/dev/null 2>&1
            return
        fi
        if sys::has adduser; then
            adduser --disabled-password --gecos "" --ingroup "${group}" "${user}" >/dev/null 2>&1
            return
        fi

        return 1

    fi
    if sys::is_macos; then

        sys::has dscl || return 1

        uid="$(dscl . -list /Users UniqueID 2>/dev/null | awk '
            $2 ~ /^[0-9]+$/ && $2 >= 500 {
                if ( $2 > max ) max = $2
            }
            END {
                if ( max < 500 ) max = 500
                print max + 1
            }
        ')"

        [[ "${uid}" =~ ^[0-9]+$ ]] || return 1

        gid="$(dscacheutil -q group -a name "${group}" 2>/dev/null | awk '/gid:/ {print $2; exit}')"
        [[ "${gid}" =~ ^[0-9]+$ ]] || return 1

        home="/Users/${user}"
        shell="/bin/bash"

        dscl . -create "/Users/${user}" >/dev/null 2>&1 || return 1
        dscl . -create "/Users/${user}" UserShell "${shell}" >/dev/null 2>&1 || return 1
        dscl . -create "/Users/${user}" RealName "${user}" >/dev/null 2>&1 || true
        dscl . -create "/Users/${user}" UniqueID "${uid}" >/dev/null 2>&1 || return 1
        dscl . -create "/Users/${user}" PrimaryGroupID "${gid}" >/dev/null 2>&1 || return 1
        dscl . -create "/Users/${user}" NFSHomeDirectory "${home}" >/dev/null 2>&1 || return 1

        if sys::has createhomedir; then
            createhomedir -c -u "${user}" >/dev/null 2>&1 || true
        fi

        return 0

    fi
    if sys::is_windows; then

        if sys::has net.exe; then
            net.exe user "${user}" "" /add >/dev/null 2>&1 || return 1
            net.exe localgroup "${group}" "${user}" /add >/dev/null 2>&1 || true
            return 0
        fi
        if sys::has powershell.exe; then

            # shellcheck disable=SC2016
            SYS_USER_QUERY="${user}" SYS_GROUP_QUERY="${group}" powershell.exe -NoProfile -NonInteractive -Command '
                $p = ConvertTo-SecureString "" -AsPlainText -Force
                New-LocalUser -Name $env:SYS_USER_QUERY -Password $p | Out-Null
                try { Add-LocalGroupMember -Group $env:SYS_GROUP_QUERY -Member $env:SYS_USER_QUERY -ErrorAction Stop } catch {}
            ' >/dev/null 2>&1

            return

        fi

        return 1

    fi

    return 1

}
sys::deluser () {

    local user="${1:-}" group="${2:-}"

    [[ -n "${user}" ]] || return 1
    [[ "${user}" != *$'\n'* && "${user}" != *$'\r'* ]] || return 1

    sys::uexists "${user}" || return 0

    if [[ -n "${group}" ]]; then

        [[ "${group}" != *$'\n'* && "${group}" != *$'\r'* ]] || return 1
        sys::uexists "${user}" "${group}" || return 1

    fi
    if sys::is_linux || sys::is_wsl; then

        if sys::has userdel; then
            userdel "${user}" >/dev/null 2>&1
            return
        fi
        if sys::has deluser; then
            deluser "${user}" >/dev/null 2>&1
            return
        fi

        return 1

    fi
    if sys::is_macos; then

        if sys::has sysadminctl; then
            sysadminctl -deleteUser "${user}" >/dev/null 2>&1
            return
        fi
        if sys::has dscl; then
            dscl . -delete "/Users/${user}" >/dev/null 2>&1
            return
        fi

        return 1

    fi
    if sys::is_windows; then

        if sys::has net.exe; then
            net.exe user "${user}" /delete >/dev/null 2>&1
            return
        fi
        if sys::has powershell.exe; then

            # shellcheck disable=SC2016
            SYS_USER_QUERY="${user}" powershell.exe -NoProfile -NonInteractive -Command '
                Remove-LocalUser -Name $env:SYS_USER_QUERY
            ' >/dev/null 2>&1

            return

        fi

        return 1

    fi

    return 1

}
