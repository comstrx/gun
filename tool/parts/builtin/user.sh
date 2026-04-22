
sys::__has () {

    command -v "${1:-}" >/dev/null 2>&1

}

sys::gid () {

    local v=""

    if sys::__has id; then
        v="$(id -g 2>/dev/null || true)"
        [[ "${v}" =~ ^[0-9]+$ ]] && { printf '%s\n' "${v}"; return 0; }
    fi

    return 1

}
sys::gname () {

    local v="" name=""

    if sys::is_windows; then

        name="$(sys::uname 2>/dev/null || true)"
        [[ -n "${name}" ]] || return 1

        v="$(sys::ugroup "${name}" 2>/dev/null || true)"
        [[ -n "${v}" ]] && { printf '%s\n' "${v}"; return 0; }

        return 1

    fi
    if sys::__has id; then
        v="$(id -gn 2>/dev/null || true)"
        [[ -n "${v}" ]] && { printf '%s\n' "${v}"; return 0; }
    fi

    return 1

}
sys::gexists () {

    local name="${1:-}" cmd=""

    [[ -n "${name}" ]] || return 1

    if sys::is_windows; then

        if sys::__has powershell.exe; then

            # shellcheck disable=SC2016
            cmd='param([string]$GroupName); $ErrorActionPreference = "Stop"; if (Get-Command Get-LocalGroup -ErrorAction SilentlyContinue) { Get-LocalGroup -Name $GroupName | Out-Null; exit 0 }; exit 1'

            if powershell.exe -NoProfile -NonInteractive -Command "${cmd}" "${name}" >/dev/null 2>&1; then
                return 0
            fi

        fi
        if sys::__has net.exe; then
            net.exe localgroup "${name}" >/dev/null 2>&1
            return
        fi

        return 1

    fi
    if sys::__has getent; then
        getent group "${name}" >/dev/null 2>&1
        return
    fi
    if sys::is_macos && sys::__has dscl; then
        dscl . -read "/Groups/${name}" >/dev/null 2>&1
        return
    fi

    return 1

}
sys::uid () {

    local v=""

    if sys::__has id; then

        v="$(id -u 2>/dev/null || true)"
        [[ "${v}" =~ ^[0-9]+$ ]] && { printf '%s\n' "${v}"; return 0; }

    fi
    if sys::is_windows; then

        v="${UID:-}"
        [[ "${v}" =~ ^[0-9]+$ ]] && { printf '%s\n' "${v}"; return 0; }

    fi

    return 1

}
sys::uname () {

    local v=""

    if sys::__has id; then

        v="$(id -un 2>/dev/null || true)"
        [[ -n "${v}" ]] && { printf '%s\n' "${v}"; return 0; }

    fi

    v="${USER:-${LOGNAME:-${USERNAME:-}}}"
    [[ -n "${v}" ]] && { printf '%s\n' "${v}"; return 0; }

    if sys::is_windows && sys::__has whoami.exe; then

        v="$(whoami.exe 2>/dev/null | tr -d '\r' | head -n 1 || true)"
        v="${v##*\\}"
        [[ -n "${v}" ]] && { printf '%s\n' "${v}"; return 0; }

    fi
    if sys::__has whoami; then

        v="$(whoami 2>/dev/null || true)"
        v="${v##*\\}"

        [[ -n "${v}" ]] && { printf '%s\n' "${v}"; return 0; }

    fi

    return 1

}
sys::uhome () {

    local v="" name="" dscl_v=""

    v="${HOME:-}"
    [[ -n "${v}" ]] && { printf '%s\n' "${v}"; return 0; }

    name="$(sys::uname 2>/dev/null || true)"
    [[ -n "${name}" ]] || return 1

    if sys::__has getent; then

        v="$(getent passwd "${name}" 2>/dev/null | awk -F: 'NR==1 {print $6}' | head -n 1)"
        [[ -n "${v}" ]] && { printf '%s\n' "${v}"; return 0; }

    fi
    if sys::is_macos && sys::__has dscl; then

        dscl_v="$(dscl . -read "/Users/${name}" NFSHomeDirectory 2>/dev/null | awk 'NR==1 {print $2}' | head -n 1)"
        [[ -n "${dscl_v}" ]] && { printf '%s\n' "${dscl_v}"; return 0; }

    fi
    if sys::is_windows; then

        v="${USERPROFILE:-}"
        [[ -n "${v}" ]] && { printf '%s\n' "${v}"; return 0; }

        if [[ -n "${HOMEDRIVE:-}" || -n "${HOMEPATH:-}" ]]; then

            printf '%s\n' "${HOMEDRIVE:-}${HOMEPATH:-}"
            return 0

        fi

    fi

    return 1

}
sys::ushell () {

    local v="" name="" dscl_v=""

    v="${SHELL:-}"
    [[ -n "${v}" ]] && { printf '%s\n' "${v}"; return 0; }

    name="$(sys::uname 2>/dev/null || true)"
    [[ -n "${name}" ]] || return 1

    if sys::__has getent; then

        v="$(getent passwd "${name}" 2>/dev/null | awk -F: 'NR==1 {print $7}' | head -n 1)"
        [[ -n "${v}" ]] && { printf '%s\n' "${v}"; return 0; }

    fi
    if sys::is_macos && sys::__has dscl; then

        dscl_v="$(dscl . -read "/Users/${name}" UserShell 2>/dev/null | awk 'NR==1 {print $2}' | head -n 1)"
        [[ -n "${dscl_v}" ]] && { printf '%s\n' "${dscl_v}"; return 0; }

    fi
    if sys::is_windows; then

        if [[ -n "${COMSPEC:-}" ]]; then
            printf '%s\n' "${COMSPEC}"
            return 0
        fi
        if sys::__has powershell.exe; then
            printf '%s\n' "powershell.exe"
            return 0
        fi

    fi

    return 1

}
sys::uexists () {

    local name="${1:-}"
    [[ -n "${name}" ]] || return 1

    if sys::__has id; then
        id -u "${name}" >/dev/null 2>&1
        return
    fi
    if sys::__has getent; then
        getent passwd "${name}" >/dev/null 2>&1
        return
    fi
    if sys::is_macos && sys::__has dscl; then
        dscl . -read "/Users/${name}" >/dev/null 2>&1
        return
    fi
    if sys::is_windows && sys::__has net.exe; then
        net.exe user "${name}" >/dev/null 2>&1
        return
    fi

    return 1

}
sys::ugroup () {

    local name="${1:-}" v="" dscl_v=""

    if [[ -z "${name}" ]]; then

        if sys::__has id; then
            v="$(id -gn 2>/dev/null || true)"
            [[ -n "${v}" ]] && { printf '%s\n' "${v}"; return 0; }
        fi

        name="$(sys::uname 2>/dev/null || true)"

    fi
    if [[ -z "${name}" ]]; then

        return 1

    fi
    if sys::__has id; then

        v="$(id -gn "${name}" 2>/dev/null || true)"
        [[ -n "${v}" ]] && { printf '%s\n' "${v}"; return 0; }

    fi
    if sys::__has getent; then

        v="$(getent passwd "${name}" 2>/dev/null | awk -F: 'NR==1 {print $4}' | head -n 1)"

        if [[ "${v}" =~ ^[0-9]+$ ]] && sys::__has getent; then
            v="$(getent group "${v}" 2>/dev/null | awk -F: 'NR==1 {print $1}' | head -n 1)"
            [[ -n "${v}" ]] && { printf '%s\n' "${v}"; return 0; }
        fi

    fi
    if sys::is_macos && sys::__has dscl; then

        dscl_v="$(dscl . -read "/Users/${name}" PrimaryGroupID 2>/dev/null | awk 'NR==1 {print $2}' | head -n 1)"

        if [[ "${dscl_v}" =~ ^[0-9]+$ ]]; then
            v="$(dscl . -search /Groups PrimaryGroupID "${dscl_v}" 2>/dev/null | awk 'NR==1 {print $1}' | head -n 1)"
            [[ -n "${v}" ]] && { printf '%s\n' "${v}"; return 0; }
        fi

    fi

    return 1

}
sys::ugroups () {

    local name="${1:-}" v="" primary="" out="" current=""

    [[ -n "${name}" ]] || name="$(sys::uname 2>/dev/null || true)"
    [[ -n "${name}" ]] || return 1

    current="$(sys::uname 2>/dev/null || true)"

    if sys::__has id; then

        v="$(id -Gn "${name}" 2>/dev/null || true)"
        [[ -n "${v}" ]] && { printf '%s\n' "${v}"; return 0; }

    fi
    if sys::__has getent; then

        primary="$(sys::ugroup "${name}" 2>/dev/null || true)"

        v="$(getent group 2>/dev/null | awk -F: -v user="${name}" '
            {
                n = split($4, a, ",")
                for (i = 1; i <= n; i++) {
                    if (a[i] == user) {
                        print $1
                    }
                }
            }
        ' | paste -sd' ' - 2>/dev/null || true)"

        if [[ -n "${primary}" && -n "${v}" ]]; then

            case " ${v} " in
                *" ${primary} "*) printf '%s\n' "${v}" ;;
                *) printf '%s\n' "${primary} ${v}" ;;
            esac

            return 0

        fi

        [[ -n "${primary}" ]] && { printf '%s\n' "${primary}"; return 0; }
        [[ -n "${v}" ]] && { printf '%s\n' "${v}"; return 0; }

    fi
    if sys::is_macos && sys::__has dscl; then

        primary="$(sys::ugroup "${name}" 2>/dev/null || true)"
        v="$(dscl . -search /Groups GroupMembership "${name}" 2>/dev/null | awk '{print $1}' | paste -sd' ' - 2>/dev/null || true)"

        if [[ -n "${primary}" && -n "${v}" ]]; then

            case " ${v} " in
                *" ${primary} "*) printf '%s\n' "${v}" ;;
                *) printf '%s\n' "${primary} ${v}" ;;
            esac

            return 0

        fi

        [[ -n "${primary}" ]] && { printf '%s\n' "${primary}"; return 0; }
        [[ -n "${v}" ]] && { printf '%s\n' "${v}"; return 0; }

    fi
    if sys::is_windows; then

        if [[ -z "${current}" || "${name}" == "${current}" ]]; then

            if sys::__has whoami.exe; then

                out="$(
                    whoami.exe /groups 2>/dev/null | tr -d '\r' | awk '
                        BEGIN { started = 0 }
                        /^[[:space:]]*GROUP INFORMATION[[:space:]]*$/ { started = 1; next }
                        started && /^[= -]+$/ { next }
                        started && NF {
                            line = $0
                            sub(/^[[:space:]]+/, "", line)
                            sub(/[[:space:]]+Mandatory group.*$/, "", line)
                            sub(/[[:space:]]+Enabled group.*$/, "", line)
                            sub(/[[:space:]]+Group used for deny only.*$/, "", line)
                            sub(/[[:space:]]+Deny only.*$/, "", line)
                            sub(/[[:space:]]+Well-known group.*$/, "", line)
                            sub(/[[:space:]]+Owner group.*$/, "", line)
                            if (line != "") print line
                        }
                    ' | paste -sd' ' - 2>/dev/null || true
                )"

                [[ -n "${out}" ]] && { printf '%s\n' "${out}"; return 0; }

            fi
            if sys::__has net.exe; then

                primary="$(sys::ugroup "${name}" 2>/dev/null || true)"
                [[ -n "${primary}" ]] && { printf '%s\n' "${primary}"; return 0; }

            fi

        fi

    fi

    return 1

}

sys::groups () {

    local v=""

    if sys::is_windows; then

        if sys::__has powershell.exe; then

            # shellcheck disable=SC2016
            v="$(
                powershell.exe -NoProfile -NonInteractive -Command '$ErrorActionPreference = "Stop"; if (Get-Command Get-LocalGroup -ErrorAction SilentlyContinue) { Get-LocalGroup | ForEach-Object { $_.Name }; exit 0 }; exit 1'
                exit "${PIPESTATUS[0]:-1}"
            )" && { [[ -n "${v}" ]] && printf '%s\n' "${v}"; return 0; }

        fi
        if sys::__has net.exe; then

            v="$(
                net.exe localgroup 2>/dev/null | tr -d '\r' | awk '
                    BEGIN { in_items = 0 }
                    /^-+$/ {
                        if (!in_items) { in_items = 1; next }
                        else { exit }
                    }
                    in_items {
                        line = $0
                        sub(/^\*/, "", line)
                        sub(/^[[:space:]]+/, "", line)
                        sub(/[[:space:]]+$/, "", line)
                        if (line != "") {
                            print line
                        }
                    }
                ' | awk 'NF && !seen[$0]++'
                exit "${PIPESTATUS[0]:-1}"
            )" && { [[ -n "${v}" ]] && printf '%s\n' "${v}"; return 0; }

        fi

        return 1

    fi
    if sys::__has getent; then

        v="$(getent group 2>/dev/null | awk -F: 'NF { print $1 }' || true)"
        [[ -n "${v}" ]] && { printf '%s\n' "${v}"; return 0; }

    fi
    if sys::is_macos && sys::__has dscl; then

        v="$(dscl . -list /Groups 2>/dev/null || true)"
        [[ -n "${v}" ]] && { printf '%s\n' "${v}"; return 0; }

    fi
    if [[ -r /etc/group ]]; then

        v="$(awk -F: 'NF { print $1 }' /etc/group 2>/dev/null || true)"
        [[ -n "${v}" ]] && { printf '%s\n' "${v}"; return 0; }

    fi

    return 1

}
sys::users () {

    local gname="${1:-}" v="" gid="" members="" line=""

    if sys::is_windows; then

        if [[ -n "${gname}" ]]; then

            if sys::__has powershell.exe; then

                # shellcheck disable=SC2016
                v="$(
                    SYS_USERS_GROUP_NAME="${gname}" powershell.exe -NoProfile -NonInteractive -Command '$ErrorActionPreference = "Stop"; $group = [Environment]::GetEnvironmentVariable("SYS_USERS_GROUP_NAME"); if ([string]::IsNullOrWhiteSpace($group)) { exit 1 }; if (-not (Get-Command Get-LocalGroupMember -ErrorAction SilentlyContinue)) { exit 1 }; Get-LocalGroupMember -Group $group -ErrorAction Stop | Where-Object { -not $_.PSObject.Properties["ObjectClass"] -or $_.ObjectClass -eq "User" } | ForEach-Object { $name = [string]$_.Name; if ($name -match "\\\\") { $name = $name.Split("\\")[-1] }; if (-not [string]::IsNullOrWhiteSpace($name)) { $name } } | Select-Object -Unique'
                    exit "${PIPESTATUS[0]:-1}"
                )" && { [[ -n "${v}" ]] && printf '%s\n' "${v}"; return 0; }

            fi
            if sys::__has net.exe; then

                v="$(
                    net.exe localgroup "${gname}" 2>/dev/null | tr -d '\r' | awk '
                        BEGIN { in_members = 0 }
                        /^-+$/ { if (!in_members) { in_members = 1; next } else { exit } }
                        in_members {
                            if ($0 !~ /The command completed successfully\./ && $0 !~ /^[[:space:]]*$/) {
                                sub(/^[[:space:]]+/, "", $0)
                                print
                            }
                        }
                    ' | awk 'NF && !seen[$0]++'
                    exit "${PIPESTATUS[0]:-1}"
                )" && { [[ -n "${v}" ]] && printf '%s\n' "${v}"; return 0; }

            fi

            return 1

        fi
        if sys::__has powershell.exe; then

            # shellcheck disable=SC2016
            v="$(
                powershell.exe -NoProfile -NonInteractive -Command '$ErrorActionPreference = "Stop"; if (Get-Command Get-LocalUser -ErrorAction SilentlyContinue) { Get-LocalUser | ForEach-Object { $_.Name }; exit 0 }; exit 1'
                exit "${PIPESTATUS[0]:-1}"
            )" && { [[ -n "${v}" ]] && printf '%s\n' "${v}"; return 0; }


        fi
        if sys::__has net.exe; then

            v="$(
                net.exe user 2>/dev/null | tr -d '\r' | awk '
                    BEGIN { in_items = 0 }
                    /^-+$/ {
                        if (!in_items) { in_items = 1; next }
                        else { exit }
                    }
                    in_items {
                        for (i = 1; i <= NF; i++) {
                            print $i
                        }
                    }
                ' | awk 'NF && !seen[$0]++'
                exit "${PIPESTATUS[0]:-1}"
            )" && { [[ -n "${v}" ]] && printf '%s\n' "${v}"; return 0; }

        fi

        return 1

    fi
    if [[ -n "${gname}" ]]; then

        if sys::__has getent; then

            line="$(getent group "${gname}" 2>/dev/null | head -n 1 || true)"

            if [[ -n "${line}" ]]; then

                gid="$(printf '%s\n' "${line}" | awk -F: 'NR==1 { print $3 }')"
                members="$(printf '%s\n' "${line}" | awk -F: 'NR==1 { print $4 }')"

                v="$(
                    {
                        [[ "${gid}" =~ ^[0-9]+$ ]] && getent passwd 2>/dev/null | awk -F: -v gid="${gid}" '$4 == gid { print $1 }'
                        printf '%s\n' "${members}" | tr ',' '\n'
                    } | awk 'NF && !seen[$0]++'
                )"

                [[ -n "${v}" ]] && printf '%s\n' "${v}"
                return 0

            fi

        fi
        if sys::is_macos && sys::__has dscl; then

            gid="$(dscl . -read "/Groups/${gname}" PrimaryGroupID 2>/dev/null | awk 'NR==1 { print $2 }' | head -n 1)"
            members="$(dscl . -read "/Groups/${gname}" GroupMembership 2>/dev/null | sed -n 's/^GroupMembership:[[:space:]]*//p' | head -n 1)"

            if [[ -n "${gid}" || -n "${members}" ]]; then

                v="$(
                    {
                        [[ "${gid}" =~ ^[0-9]+$ ]] && dscl . -list /Users PrimaryGroupID 2>/dev/null | awk -v gid="${gid}" '$2 == gid { print $1 }'
                        printf '%s\n' "${members}" | tr ' ' '\n'
                    } | awk 'NF && !seen[$0]++'
                )"

                [[ -n "${v}" ]] && printf '%s\n' "${v}"
                return 0

            fi

        fi
        if [[ -r /etc/group && -r /etc/passwd ]]; then

            line="$(awk -F: -v name="${gname}" '$1 == name { print; exit }' /etc/group 2>/dev/null || true)"

            if [[ -n "${line}" ]]; then

                gid="$(printf '%s\n' "${line}" | awk -F: 'NR==1 { print $3 }')"
                members="$(printf '%s\n' "${line}" | awk -F: 'NR==1 { print $4 }')"

                v="$(
                    {
                        [[ "${gid}" =~ ^[0-9]+$ ]] && awk -F: -v gid="${gid}" '$4 == gid { print $1 }' /etc/passwd 2>/dev/null
                        printf '%s\n' "${members}" | tr ',' '\n'
                    } | awk 'NF && !seen[$0]++'
                )"

                [[ -n "${v}" ]] && printf '%s\n' "${v}"
                return 0

            fi

        fi

        return 1

    fi
    if sys::__has getent; then

        v="$(getent passwd 2>/dev/null | awk -F: 'NF { print $1 }' || true)"
        [[ -n "${v}" ]] && { printf '%s\n' "${v}"; return 0; }

    fi
    if sys::is_macos && sys::__has dscl; then

        v="$(dscl . -list /Users 2>/dev/null || true)"
        [[ -n "${v}" ]] && { printf '%s\n' "${v}"; return 0; }

    fi
    if [[ -r /etc/passwd ]]; then

        v="$(awk -F: 'NF { print $1 }' /etc/passwd 2>/dev/null || true)"
        [[ -n "${v}" ]] && { printf '%s\n' "${v}"; return 0; }

    fi

    return 1

}
sys::ingroup () {

    local group="${1:-}" user="${2:-}" line="" current=""

    [[ -n "${group}" ]] || return 1
    [[ -n "${user}"  ]] || user="$(sys::uname 2>/dev/null || true)"
    [[ -n "${user}"  ]] || return 1

    while IFS= read -r line || [[ -n "${line}" ]]; do
        [[ "${line}" == "${user}" ]] && return 0
    done < <(sys::users "${group}" 2>/dev/null || true)

    return 1

}
sys::addgroup () {

    local name="${1:-}"

    [[ -n "${name}" ]] || return 1
    sys::gexists "${name}" && return 0

    if sys::is_linux; then

        if sys::__has groupadd; then
            groupadd "${name}" >/dev/null 2>&1
            return
        fi

        return 1

    fi
    if sys::is_macos; then

        if sys::__has dseditgroup; then
            dseditgroup -o create "${name}" >/dev/null 2>&1
            return
        fi

        return 1

    fi
    if sys::is_windows; then

        if sys::__has net.exe; then
            net.exe localgroup "${name}" /add >/dev/null 2>&1
            return
        fi

        return 1

    fi

    return 1

}
sys::adduser () {

    local name="${1:-}" group="${2:-}"

    [[ -n "${name}" ]] || return 1

    if ! sys::uexists "${name}"; then

        if sys::is_linux; then

            if sys::__has useradd; then

                if [[ -n "${group}" ]]; then
                    sys::gexists "${group}" || sys::addgroup "${group}" || return 1
                    useradd -m -g "${group}" "${name}" >/dev/null 2>&1 || return 1
                else
                    useradd -m "${name}" >/dev/null 2>&1 || return 1
                fi

                return 0

            fi

        elif sys::is_macos; then

            if sys::__has sysadminctl; then sysadminctl -addUser "${name}" >/dev/null 2>&1 || return 1
            else return 1
            fi

        elif sys::is_windows; then

            if sys::__has net.exe; then net.exe user "${name}" /add >/dev/null 2>&1 || return 1
            else return 1
            fi

        else

            return 1

        fi

    fi

    [[ -n "${group}" ]] || return 0

    sys::gexists "${group}" || sys::addgroup "${group}" || return 1
    sys::ingroup "${group}" "${name}" && return 0

    if sys::is_linux; then

        if sys::__has usermod; then
            usermod -aG "${group}" "${name}" >/dev/null 2>&1
            return
        fi

        return 1

    fi
    if sys::is_macos; then

        if sys::__has dseditgroup; then
            dseditgroup -o edit -a "${name}" -t user "${group}" >/dev/null 2>&1
            return
        fi

        return 1

    fi
    if sys::is_windows; then

        if sys::__has net.exe; then
            net.exe localgroup "${group}" "${name}" /add >/dev/null 2>&1
            return
        fi

        return 1

    fi

    return 1

}
