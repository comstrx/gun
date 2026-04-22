
sys::is_linux () {

    local s=""

    if has uname; then
        s="$(uname -s 2>/dev/null || true)"
    fi

    [[ "${s}" == "Linux" ]] && return 0
    [[ "${OSTYPE:-}" == linux* ]]

}
sys::is_macos () {

    local s=""

    if has uname; then
        s="$(uname -s 2>/dev/null || true)"
    fi

    [[ "${s}" == "Darwin" ]] && return 0
    [[ "${OSTYPE:-}" == darwin* ]]

}
sys::is_wsl () {

    local r=""

    sys::is_linux || return 1

    [[ -n "${WSL_DISTRO_NAME:-}" || -n "${WSL_INTEROP:-}" ]] && return 0

    if [[ -r /proc/sys/kernel/osrelease ]]; then

        IFS= read -r r < /proc/sys/kernel/osrelease || true
        [[ "${r,,}" == *"microsoft"* ]] && return 0

    fi
    if [[ -r /proc/version ]]; then

        IFS= read -r r < /proc/version || true
        [[ "${r,,}" == *"microsoft"* ]] && return 0

    fi

    return 1

}
sys::is_cygwin () {

    [[ "${OSTYPE:-}" == cygwin* ]]

}
sys::is_msys () {

    local m="${MSYSTEM:-}"

    [[ "${OSTYPE:-}" == msys* ]] && return 0

    case "${m}" in
        MSYS|MINGW*|UCRT*|CLANG*) return 0 ;;
        *) return 1 ;;
    esac

}
sys::is_gitbash () {

    sys::is_msys || return 1

    [[ -n "${GitInstallRoot:-}" ]] && return 0

    case "${TERM_PROGRAM:-}" in
        mintty) return 0 ;;
    esac

    [[ -n "${MINGW_PREFIX:-}" && -z "${MSYS2_PATH_TYPE:-}" ]] && return 0

    return 1

}
sys::is_windows () {

    sys::is_wsl && return 1

    sys::is_msys   && return 0
    sys::is_cygwin && return 0

    [[ -n "${WINDIR:-}" || -n "${SystemRoot:-}" ]] || return 1

    sys::is_linux && return 1
    sys::is_macos && return 1

    return 0

}
sys::is_unix () {

    sys::is_linux || sys::is_macos

}
sys::is_posix () {

    sys::is_linux || sys::is_macos || sys::is_wsl || sys::is_msys || sys::is_cygwin

}

sys::is_ci () {

    [[ -n "${CI:-}" ]]                       && return 0
    [[ -n "${GITHUB_ACTIONS:-}" ]]           && return 0
    [[ -n "${GITLAB_CI:-}" ]]                && return 0
    [[ -n "${JENKINS_URL:-}" ]]              && return 0
    [[ -n "${BUILDKITE:-}" ]]                && return 0
    [[ -n "${CIRCLECI:-}" ]]                 && return 0
    [[ -n "${TRAVIS:-}" ]]                   && return 0
    [[ -n "${APPVEYOR:-}" ]]                 && return 0
    [[ -n "${TF_BUILD:-}" ]]                 && return 0
    [[ -n "${BITBUCKET_BUILD_NUMBER:-}" ]]   && return 0
    [[ -n "${TEAMCITY_VERSION:-}" ]]         && return 0
    [[ -n "${DRONE:-}" ]]                    && return 0
    [[ -n "${SEMAPHORE:-}" ]]                && return 0
    [[ -n "${CODEBUILD_BUILD_ID:-}" ]]       && return 0

    return 1

}
sys::ci_name () {

    [[ -n "${GITHUB_ACTIONS:-}" ]]         && { printf '%s\n' "github";    return 0; }
    [[ -n "${GITLAB_CI:-}" ]]              && { printf '%s\n' "gitlab";    return 0; }
    [[ -n "${JENKINS_URL:-}" ]]            && { printf '%s\n' "jenkins";   return 0; }
    [[ -n "${BUILDKITE:-}" ]]              && { printf '%s\n' "buildkite"; return 0; }
    [[ -n "${CIRCLECI:-}" ]]               && { printf '%s\n' "circleci";  return 0; }
    [[ -n "${TRAVIS:-}" ]]                 && { printf '%s\n' "travis";    return 0; }
    [[ -n "${APPVEYOR:-}" ]]               && { printf '%s\n' "appveyor";  return 0; }
    [[ -n "${TF_BUILD:-}" ]]               && { printf '%s\n' "azure";     return 0; }
    [[ -n "${BITBUCKET_BUILD_NUMBER:-}" ]] && { printf '%s\n' "bitbucket"; return 0; }
    [[ -n "${TEAMCITY_VERSION:-}" ]]       && { printf '%s\n' "teamcity";  return 0; }
    [[ -n "${DRONE:-}" ]]                  && { printf '%s\n' "drone";     return 0; }
    [[ -n "${SEMAPHORE:-}" ]]              && { printf '%s\n' "semaphore"; return 0; }
    [[ -n "${CODEBUILD_BUILD_ID:-}" ]]     && { printf '%s\n' "codebuild"; return 0; }
    [[ -n "${CI:-}" ]]                     && { printf '%s\n' "generic";   return 0; }

    printf '%s\n' "none"
    return 1

}
sys::is_ci_pull () {

    [[ "${GITHUB_EVENT_NAME:-}" == "pull_request" || "${GITHUB_EVENT_NAME:-}" == "pull_request_target" ]] && return 0
    [[ -n "${CI_MERGE_REQUEST_IID:-}" ]] && return 0
    [[ -n "${BITBUCKET_PR_ID:-}" ]] && return 0
    [[ -n "${SYSTEM_PULLREQUEST_PULLREQUESTID:-}" ]] && return 0
    [[ "${BUILD_REASON:-}" == "PullRequest" ]]  && return 0

    return 1

}
sys::is_ci_push () {

    sys::is_ci || return 1
    sys::is_ci_pull && return 1

    [[ "${GITHUB_EVENT_NAME:-}" == "push" ]] && return 0
    [[ "${CI_PIPELINE_SOURCE:-}" == "push" ]] && return 0
    [[ -n "${BITBUCKET_COMMIT:-}" && -z "${BITBUCKET_PR_ID:-}" ]] && return 0
    [[ "${BUILD_REASON:-}" == "IndividualCI" || "${BUILD_REASON:-}" == "BatchedCI" ]] && return 0

    return 1

}
sys::is_ci_tag () {

    [[ -n "${GITHUB_REF_TYPE:-}" && "${GITHUB_REF_TYPE:-}" == "tag" ]] && return 0
    [[ -n "${CI_COMMIT_TAG:-}" ]] && return 0
    [[ -n "${BITBUCKET_TAG:-}" ]] && return 0
    [[ "${BUILD_SOURCEBRANCH:-}" == refs/tags/* ]] && return 0

    return 1

}

sys::is_gui () {

    if sys::is_linux; then
        [[ -n "${DISPLAY:-}" || -n "${WAYLAND_DISPLAY:-}" ]]
        return
    fi
    if sys::is_macos; then
        [[ -z "${SSH_CONNECTION:-}" && -z "${SSH_CLIENT:-}" && -z "${SSH_TTY:-}" ]]
        return
    fi
    if sys::is_windows; then
        sys::is_ci && return 1
        return 0
    fi

    return 1

}
sys::is_terminal () {

    [[ -t 0 || -t 1 || -t 2 ]]

}
sys::is_interactive () {

    [[ "${-}" == *i* ]]

}
sys::is_headless () {

    sys::is_gui && return 1

    if sys::is_linux; then
        [[ -z "${DISPLAY:-}" && -z "${WAYLAND_DISPLAY:-}" ]]
        return
    fi
    if sys::is_macos || sys::is_windows; then
        [[ -n "${SSH_CONNECTION:-}" || -n "${SSH_CLIENT:-}" || -n "${SSH_TTY:-}" || -n "${CI:-}" ]]
        return
    fi

    return 1

}
sys::is_container () {

    local r=""

    [[ -f "/.dockerenv" ]] && return 0
    [[ -f "/run/.containerenv" ]] && return 0

    if [[ -r "/run/systemd/container" ]]; then

        IFS= read -r r < /run/systemd/container || true
        [[ -n "${r}" ]] && return 0

    fi
    if [[ -r /proc/1/cgroup ]]; then

        while IFS= read -r r || [[ -n "${r}" ]]; do
            [[ "${r,,}" == *"docker"* ]]     && return 0
            [[ "${r,,}" == *"kubepods"* ]]   && return 0
            [[ "${r,,}" == *"containerd"* ]] && return 0
            [[ "${r,,}" == *"podman"* ]]     && return 0
            [[ "${r,,}" == *"lxc"* ]]        && return 0
        done < /proc/1/cgroup

    fi
    if [[ -r /proc/1/environ ]]; then

        while IFS= read -r -d '' r; do
            [[ "${r}" == container=* ]] && return 0
        done < /proc/1/environ

    fi

    return 1

}

sys::name () {

    if sys::is_linux; then
        printf '%s\n' "linux"
        return 0
    fi
    if sys::is_macos; then
        printf '%s\n' "macos"
        return 0
    fi
    if sys::is_windows; then
        printf '%s\n' "windows"
        return 0
    fi

    printf '%s\n' "unknown"
    return 1

}
sys::family () {

    if sys::is_windows; then
        printf '%s\n' "windows"
        return 0
    fi
    if sys::is_linux || sys::is_macos; then
        printf '%s\n' "unix"
        return 0
    fi

    printf '%s\n' "unknown"
    return 1

}
sys::runtime () {

    if sys::is_wsl; then
        printf '%s\n' "wsl"
        return 0
    fi
    if sys::is_gitbash; then
        printf '%s\n' "gitbash"
        return 0
    fi
    if sys::is_msys; then
        printf '%s\n' "msys2"
        return 0
    fi
    if sys::is_cygwin; then
        printf '%s\n' "cygwin"
        return 0
    fi
    if sys::is_linux; then
        printf '%s\n' "linux"
        return 0
    fi
    if sys::is_macos; then
        printf '%s\n' "macos"
        return 0
    fi
    if sys::is_windows; then
        printf '%s\n' "windows"
        return 0
    fi

    printf '%s\n' "unknown"
    return 1

}
sys::distro () {

    local id="" runtime="" line="" file=""

    if sys::is_linux; then

        for file in /etc/os-release /usr/lib/os-release; do

            [[ -r "${file}" ]] || continue

            while IFS= read -r line || [[ -n "${line}" ]]; do

                [[ "${line}" == "ID="* ]] || continue

                line="${line#*=}"
                line="${line%\"}"
                line="${line#\"}"

                id="${line}"

            done < "${file}"

        done

        if [[ -n "${id}" ]]; then
            printf '%s\n' "${id}"
            return 0
        fi

        printf '%s\n' "linux"
        return 0

    fi
    if sys::is_macos; then

        printf '%s\n' "macos"
        return 0

    fi
    if sys::is_windows; then

        runtime="$(sys::runtime 2>/dev/null || true)"
        
        if [[ -n "${runtime}" ]]; then
            printf '%s\n' "${runtime}"
            return 0
        fi

    fi

    printf '%s\n' "unknown"
    return 1

}
sys::manager () {

    if sys::is_linux; then

        has apt-get      && { printf '%s\n' "apt";     return 0; }
        has apk          && { printf '%s\n' "apk";     return 0; }
        has dnf          && { printf '%s\n' "dnf";     return 0; }
        has yum          && { printf '%s\n' "yum";     return 0; }
        has pacman       && { printf '%s\n' "pacman";  return 0; }
        has zypper       && { printf '%s\n' "zypper";  return 0; }
        has xbps-install && { printf '%s\n' "xbps";    return 0; }
        has nix          && { printf '%s\n' "nix";     return 0; }

        printf '%s\n' "unknown"
        return 1

    fi
    if sys::is_macos; then

        has brew && { printf '%s\n' "brew"; return 0; }
        has port && { printf '%s\n' "port"; return 0; }

        printf '%s\n' "unknown"
        return 1

    fi
    if sys::is_windows; then

        if ( sys::is_msys || sys::is_gitbash ) && has pacman; then
            printf '%s\n' "pacman"
            return 0
        fi

        has winget && { printf '%s\n' "winget"; return 0; }
        has choco  && { printf '%s\n' "choco";  return 0; }
        has scoop  && { printf '%s\n' "scoop";  return 0; }
        has pacman && { printf '%s\n' "pacman"; return 0; }

        printf '%s\n' "unknown"
        return 1

    fi

    printf '%s\n' "unknown"
    return 1

}
sys::arch () {

    local v=""

    has uname && v="$(uname -m 2>/dev/null || true)"

    [[ -n "${v}" ]] || v="${PROCESSOR_ARCHITECTURE:-${HOSTTYPE:-}}"
    [[ -n "${v}" ]] || v="unknown"

    case "${v,,}" in
        x86_64|amd64)             printf '%s\n' "x64" ;;
        x86|i386|i486|i586|i686)  printf '%s\n' "x86" ;;
        aarch64|arm64)            printf '%s\n' "arm64" ;;
        armv7l|armv7|armhf)       printf '%s\n' "armv7" ;;
        armv6l|armv6)             printf '%s\n' "armv6" ;;
        arm)                      printf '%s\n' "arm" ;;
        ppc64le)                  printf '%s\n' "ppc64le" ;;
        ppc64)                    printf '%s\n' "ppc64" ;;
        s390x)                    printf '%s\n' "s390x" ;;
        riscv64)                  printf '%s\n' "riscv64" ;;
        *)                        printf '%s\n' "${v}" ;;
    esac

}
sys::open () {

    local target="${1:-}" scheme="" rest="" hostport="" host="" suffix=""
    shift || true

    [[ -n "${target}" ]] || return 1

    if [[ -e "${target}" ]]; then

        if [[ "${OSTYPE:-}" == darwin* ]]; then
            open "${target}" >/dev/null 2>&1
            return
        fi
        if has explorer.exe; then
            explorer.exe "${target}" >/dev/null 2>&1
            return
        fi
        if has powershell.exe; then
            powershell.exe -NoProfile -Command "Start-Process -LiteralPath '${target}'" >/dev/null 2>&1
            return
        fi
        if has cmd.exe; then
            cmd.exe /C start "" "${target}" >/dev/null 2>&1
            return
        fi
        if has xdg-open; then
            xdg-open "${target}" >/dev/null 2>&1
            return
        fi

        return 1

    fi

    case "${target}" in
        http://*|https://*|www.*|localhost|localhost:*|[0-9]*.[0-9]*.[0-9]*.[0-9]*) ;;
        *)
            if has "${target}"; then
                "${target}" "$@" >/dev/null 2>&1 &
                disown || true
                return 0
            fi
            return 1
        ;;
    esac

    [[ "${target}" == *"://"* ]] || target="https://${target}"

    scheme="${target%%://*}"
    rest="${target#*://}"
    hostport="${rest%%[/?#]*}"
    suffix="${rest#${hostport}}"

    [[ "${suffix}" == "${rest}" ]] && suffix=""

    host="${hostport%%:*}"

    if [[ "${scheme}" == http || "${scheme}" == https ]]; then

        if [[ "${host}" != *.* && "${host}" != localhost && ! "${host}" =~ ^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
            host="${host}.com"
            hostport="${host}${hostport#"${hostport%%:*}"}"
        fi

        host="${hostport%%:*}"

        if [[ "${host}" != www.* && "${host}" != localhost && ! "${host}" =~ ^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
            hostport="www.${host}${hostport#"${host}"}"
        fi

    fi

    target="${scheme}://${hostport}${suffix}"

    if [[ "${OSTYPE:-}" == darwin* ]]; then
        open "${target}" >/dev/null 2>&1
        return
    fi
    if [[ "${OSTYPE:-}" == msys* || "${OSTYPE:-}" == cygwin* || -n "${WINDIR:-}" || -n "${SystemRoot:-}" ]]; then

        if has powershell.exe; then
            powershell.exe -NoProfile -Command "Start-Process '${target}'" >/dev/null 2>&1
            return
        fi
        if has cmd.exe; then
            cmd.exe /C start "" "${target}" >/dev/null 2>&1
            return
        fi

    fi
    if has xdg-open; then
        xdg-open "${target}" >/dev/null 2>&1
        return
    fi

    return 1

}

sys::disk_total () {

    local path="${1:-.}" v=""

    [[ -n "${path}" ]] || path='.'
    [[ -e "${path}" ]] || return 1

    if has df; then
        v="$(df -Pk "${path}" 2>/dev/null | awk 'NR==2 {print $2}' | head -n 1)"
        [[ "${v}" =~ ^[0-9]+$ ]] && { printf '%s\n' "$(( v * 1024 ))"; return 0; }
    fi

    return 1

}
sys::disk_free () {

    local path="${1:-.}" v=""

    [[ -n "${path}" ]] || path='.'
    [[ -e "${path}" ]] || return 1

    if has df; then
        v="$(df -Pk "${path}" 2>/dev/null | awk 'NR==2 {print $4}' | head -n 1)"
        [[ "${v}" =~ ^[0-9]+$ ]] && { printf '%s\n' "$(( v * 1024 ))"; return 0; }
    fi

    return 1

}
sys::disk_used () {

    local path="${1:-.}" total="" free=""

    total="$(sys::disk_total "${path}" 2>/dev/null || true)"
    free="$(sys::disk_free "${path}" 2>/dev/null || true)"

    [[ "${total}" =~ ^[0-9]+$ ]] || return 1
    [[ "${free}" =~ ^[0-9]+$ ]] || return 1
    (( free <= total )) || free="${total}"

    printf '%s\n' "$(( total - free ))"

}
sys::disk_percent () {

    local path="${1:-.}" total="" used=""

    total="$(sys::disk_total "${path}" 2>/dev/null || true)"
    used="$(sys::disk_used "${path}" 2>/dev/null || true)"

    [[ "${total}" =~ ^[0-9]+$ ]] || return 1
    [[ "${used}" =~ ^[0-9]+$ ]] || return 1
    (( total > 0 )) || return 1

    printf '%s\n' "$(( used * 100 / total ))"

}
sys::disk_size () {

    local path="${1:-}" v=""

    [[ -n "${path}" ]] || return 1
    [[ -e "${path}" ]] || return 1

    if has du; then
        v="$(du -sk "${path}" 2>/dev/null | awk 'NR==1 {print $1}' | head -n 1)"
        [[ "${v}" =~ ^[0-9]+$ ]] && { printf '%s\n' "$(( v * 1024 ))"; return 0; }
    fi

    return 1

}
sys::disk_info () {

    local path="${1:-.}" total="" free="" used="" percent=""

    total="$(sys::disk_total "${path}" 2>/dev/null || true)"
    free="$(sys::disk_free "${path}" 2>/dev/null || true)"
    used="$(sys::disk_used "${path}" 2>/dev/null || true)"
    percent="$(sys::disk_percent "${path}" 2>/dev/null || true)"

    [[ "${total}" =~ ^[0-9]+$ ]] || return 1
    [[ "${free}" =~ ^[0-9]+$ ]] || return 1
    [[ "${used}" =~ ^[0-9]+$ ]] || return 1
    [[ "${percent}" =~ ^[0-9]+$ ]] || return 1

    printf '%s\n' "path=${path}" "total=${total}" "free=${free}" "used=${used}" "percent=${percent}"

}

sys::mem_total () {

    local v=""

    if sys::is_linux; then

        if [[ -r /proc/meminfo ]]; then
            v="$(sed -n 's/^MemTotal:[[:space:]]*\([0-9][0-9]*\)[[:space:]]*kB$/\1/p' /proc/meminfo | head -n 1)"
            [[ -n "${v}" ]] && { printf '%s\n' "$(( v * 1024 ))"; return 0; }
        fi

    fi
    if sys::is_macos; then

        v="$(sysctl -n hw.memsize 2>/dev/null || true)"
        [[ "${v}" =~ ^[0-9]+$ ]] && { printf '%s\n' "${v}"; return 0; }

    fi
    if sys::is_windows; then

        if has powershell.exe; then
            v="$(powershell.exe -NoProfile -Command "[int64](Get-CimInstance Win32_ComputerSystem).TotalPhysicalMemory" 2>/dev/null | tr -d '\r')"
            [[ "${v}" =~ ^[0-9]+$ ]] && { printf '%s\n' "${v}"; return 0; }
        fi

    fi

    return 1

}
sys::mem_free () {

    local v="" a="" b="" c=""

    if sys::is_linux; then

        if [[ -r /proc/meminfo ]]; then
            v="$(sed -n 's/^MemAvailable:[[:space:]]*\([0-9][0-9]*\)[[:space:]]*kB$/\1/p' /proc/meminfo | head -n 1)"
            [[ -n "${v}" ]] && { printf '%s\n' "$(( v * 1024 ))"; return 0; }

            a="$(sed -n 's/^MemFree:[[:space:]]*\([0-9][0-9]*\)[[:space:]]*kB$/\1/p' /proc/meminfo | head -n 1)"
            b="$(sed -n 's/^Buffers:[[:space:]]*\([0-9][0-9]*\)[[:space:]]*kB$/\1/p' /proc/meminfo | head -n 1)"
            c="$(sed -n 's/^Cached:[[:space:]]*\([0-9][0-9]*\)[[:space:]]*kB$/\1/p' /proc/meminfo | head -n 1)"

            [[ "${a}" =~ ^[0-9]+$ ]] || a=0
            [[ "${b}" =~ ^[0-9]+$ ]] || b=0
            [[ "${c}" =~ ^[0-9]+$ ]] || c=0

            printf '%s\n' "$(( ( a + b + c ) * 1024 ))"
            return 0
        fi

    fi
    if sys::is_macos; then

        if has vm_stat && has sysctl; then

            local page_size="" free_pages="" inactive_pages="" speculative_pages=""

            page_size="$(sysctl -n hw.pagesize 2>/dev/null || true)"
            free_pages="$(vm_stat 2>/dev/null | sed -n 's/^Pages free:[[:space:]]*\([0-9][0-9]*\)\.$/\1/p' | head -n 1)"
            inactive_pages="$(vm_stat 2>/dev/null | sed -n 's/^Pages inactive:[[:space:]]*\([0-9][0-9]*\)\.$/\1/p' | head -n 1)"
            speculative_pages="$(vm_stat 2>/dev/null | sed -n 's/^Pages speculative:[[:space:]]*\([0-9][0-9]*\)\.$/\1/p' | head -n 1)"

            [[ "${page_size}" =~ ^[0-9]+$ ]] || page_size=4096
            [[ "${free_pages}" =~ ^[0-9]+$ ]] || free_pages=0
            [[ "${inactive_pages}" =~ ^[0-9]+$ ]] || inactive_pages=0
            [[ "${speculative_pages}" =~ ^[0-9]+$ ]] || speculative_pages=0

            printf '%s\n' "$(( ( free_pages + inactive_pages + speculative_pages ) * page_size ))"
            return 0

        fi

    fi
    if sys::is_windows; then

        if has powershell.exe; then
            v="$(powershell.exe -NoProfile -Command "[int64]((Get-CimInstance Win32_OperatingSystem).FreePhysicalMemory * 1024)" 2>/dev/null | tr -d '\r')"
            [[ "${v}" =~ ^[0-9]+$ ]] && { printf '%s\n' "${v}"; return 0; }
        fi

    fi

    return 1

}
sys::mem_used () {

    local total="" free=""

    total="$(sys::mem_total 2>/dev/null || true)"
    free="$(sys::mem_free 2>/dev/null || true)"

    [[ "${total}" =~ ^[0-9]+$ ]] || return 1
    [[ "${free}" =~ ^[0-9]+$ ]] || return 1
    (( free <= total )) || free="${total}"

    printf '%s\n' "$(( total - free ))"

}
sys::mem_percent () {

    local total="" used=""

    total="$(sys::mem_total 2>/dev/null || true)"
    used="$(sys::mem_used 2>/dev/null || true)"

    [[ "${total}" =~ ^[0-9]+$ ]] || return 1
    [[ "${used}" =~ ^[0-9]+$ ]] || return 1
    (( total > 0 )) || return 1

    printf '%s\n' "$(( used * 100 / total ))"

}
sys::mem_info () {

    local total="" free="" used="" percent=""

    total="$(sys::mem_total 2>/dev/null || true)"
    free="$(sys::mem_free 2>/dev/null || true)"
    used="$(sys::mem_used 2>/dev/null || true)"
    percent="$(sys::mem_percent 2>/dev/null || true)"

    [[ -n "${total}" ]] || return 1
    [[ -n "${free}" ]] || return 1
    [[ -n "${used}" ]] || return 1
    [[ -n "${percent}" ]] || return 1

    printf '%s\n' "total=${total}" "free=${free}" "used=${used}" "percent=${percent}"

}

# Here

sys::user_name () {

    local v=""

    v="${USER:-${LOGNAME:-}}"
    [[ -n "${v}" ]] && { printf '%s\n' "${v}"; return 0; }

    if has id; then
        v="$(id -un 2>/dev/null || true)"
        [[ -n "${v}" ]] && { printf '%s\n' "${v}"; return 0; }
    fi

    return 1

}
sys::user_id () {

    local v=""

    if has id; then
        v="$(id -u 2>/dev/null || true)"
        [[ "${v}" =~ ^[0-9]+$ ]] && { printf '%s\n' "${v}"; return 0; }
    fi

    return 1

}
sys::user_gid () {

    local v=""

    if has id; then
        v="$(id -g 2>/dev/null || true)"
        [[ "${v}" =~ ^[0-9]+$ ]] && { printf '%s\n' "${v}"; return 0; }
    fi

    return 1

}
sys::user_home () {

    local v=""

    v="${HOME:-}"
    [[ -n "${v}" ]] && { printf '%s\n' "${v}"; return 0; }

    if has getent; then
        v="$(getent passwd "$(sys::user_name 2>/dev/null || true)" 2>/dev/null | awk -F: 'NR==1 {print $6}' | head -n 1)"
        [[ -n "${v}" ]] && { printf '%s\n' "${v}"; return 0; }
    fi

    return 1

}
sys::user_shell () {

    local v="" name=""

    v="${SHELL:-}"
    [[ -n "${v}" ]] && { printf '%s\n' "${v}"; return 0; }

    name="$(sys::user_name 2>/dev/null || true)"
    [[ -n "${name}" ]] || return 1

    if has getent; then
        v="$(getent passwd "${name}" 2>/dev/null | awk -F: 'NR==1 {print $7}' | head -n 1)"
        [[ -n "${v}" ]] && { printf '%s\n' "${v}"; return 0; }
    fi

    return 1

}
sys::user_is_root () {

    local v=""
    v="$(sys::user_id 2>/dev/null || true)"
    [[ "${v}" == "0" ]]

}
sys::user_is_admin () {

    sys::user_is_root && return 0

    if sys::is_windows; then
        [[ -n "${USERNAME:-}" ]] || return 1

        if has net.exe; then
            net.exe user "${USERNAME}" 2>/dev/null | tr -d '\r' | grep -qi 'Administrators'
            return
        fi

        return 1
    fi

    sys::user_in_group sudo && return 0
    sys::user_in_group wheel && return 0
    sys::user_in_group admin

}
sys::user_exists () {

    local name="${1:-}"

    [[ -n "${name}" ]] || return 1

    if has id; then
        id -u "${name}" >/dev/null 2>&1
        return
    fi

    if has getent; then
        getent passwd "${name}" >/dev/null 2>&1
        return
    fi

    return 1

}
sys::user_groups () {

    local name="${1:-}" v=""

    if [[ -z "${name}" ]]; then
        name="$(sys::user_name 2>/dev/null || true)"
    fi

    [[ -n "${name}" ]] || return 1

    if has id; then
        v="$(id -nG "${name}" 2>/dev/null || true)"
        [[ -n "${v}" ]] && { printf '%s\n' "${v}"; return 0; }
    fi

    return 1

}
sys::user_in_group () {

    local group="${1:-}" user="${2:-}" x=""

    [[ -n "${group}" ]] || return 1

    if [[ -z "${user}" ]]; then
        user="$(sys::user_name 2>/dev/null || true)"
    fi

    [[ -n "${user}" ]] || return 1

    for x in $(sys::user_groups "${user}" 2>/dev/null || true); do
        [[ "${x}" == "${group}" ]] && return 0
    done

    return 1

}

sys::group_name () {

    local v=""

    if has id; then
        v="$(id -gn 2>/dev/null || true)"
        [[ -n "${v}" ]] && { printf '%s\n' "${v}"; return 0; }
    fi

    return 1

}
sys::group_id () {

    local v=""

    if has id; then
        v="$(id -g 2>/dev/null || true)"
        [[ "${v}" =~ ^[0-9]+$ ]] && { printf '%s\n' "${v}"; return 0; }
    fi

    return 1

}
sys::group_exists () {

    local name="${1:-}"

    [[ -n "${name}" ]] || return 1

    if has getent; then
        getent group "${name}" >/dev/null 2>&1
        return
    fi

    return 1

}
sys::group_users () {

    local name="${1:-}" v=""

    [[ -n "${name}" ]] || return 1

    if has getent; then
        v="$(getent group "${name}" 2>/dev/null | awk -F: 'NR==1 {print $4}' | head -n 1)"
        [[ -n "${v}" ]] && { printf '%s\n' "${v}"; return 0; }
    fi

    return 1

}

sys::group_add () {

    local name="${1:-}"

    [[ -n "${name}" ]] || return 1
    sys::group_exists "${name}" && return 0

    if sys::is_linux; then

        if has groupadd; then
            groupadd "${name}" >/dev/null 2>&1
            return
        fi

        return 1

    fi
    if sys::is_macos; then

        if has dseditgroup; then
            dseditgroup -o create "${name}" >/dev/null 2>&1
            return
        fi

        return 1

    fi
    if sys::is_windows; then

        if has net.exe; then
            net.exe localgroup "${name}" /add >/dev/null 2>&1
            return
        fi

        return 1

    fi

    return 1

}
sys::user_add () {

    local name="${1:-}"

    [[ -n "${name}" ]] || return 1
    sys::user_exists "${name}" && return 0

    if sys::is_linux; then

        if has useradd; then
            useradd -m "${name}" >/dev/null 2>&1
            return
        fi

        return 1

    fi
    if sys::is_macos; then

        if has sysadminctl; then
            sysadminctl -addUser "${name}" >/dev/null 2>&1
            return
        fi

        return 1

    fi
    if sys::is_windows; then

        if has net.exe; then
            net.exe user "${name}" /add >/dev/null 2>&1
            return
        fi

        return 1

    fi

    return 1

}
sys::user_add_group () {

    local user="${1:-}" group="${2:-}"

    [[ -n "${user}" ]] || return 1
    [[ -n "${group}" ]] || return 1

    sys::user_exists "${user}" || return 1
    sys::group_exists "${group}" || sys::group_add "${group}" || return 1
    sys::user_in_group "${group}" "${user}" && return 0

    if sys::is_linux; then

        if has usermod; then
            usermod -aG "${group}" "${user}" >/dev/null 2>&1
            return
        fi

        return 1

    fi
    if sys::is_macos; then

        if has dseditgroup; then
            dseditgroup -o edit -a "${user}" -t user "${group}" >/dev/null 2>&1
            return
        fi

        return 1

    fi
    if sys::is_windows; then

        if has net.exe; then
            net.exe localgroup "${group}" "${user}" /add >/dev/null 2>&1
            return
        fi

        return 1

    fi

    return 1

}
