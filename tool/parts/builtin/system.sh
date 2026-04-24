
sys::has () {

    command -v "${1:-}" >/dev/null 2>&1

}
sys::is_linux () {

    local s=""

    if sys::has uname; then
        s="$(uname -s 2>/dev/null || true)"
    fi

    [[ "${s}" == "Linux" ]] && return 0
    [[ "${OSTYPE:-}" == linux* ]]

}
sys::is_macos () {

    local s=""

    if sys::has uname; then
        s="$(uname -s 2>/dev/null || true)"
    fi

    [[ "${s}" == "Darwin" ]] && return 0
    [[ "${OSTYPE:-}" == darwin* ]]

}
sys::is_wsl () {

    local r="" lower=""

    sys::is_linux || return 1
    [[ -n "${WSL_DISTRO_NAME:-}" || -n "${WSL_INTEROP:-}" ]] && return 0

    if [[ -r /proc/sys/kernel/osrelease ]]; then

        IFS= read -r r < /proc/sys/kernel/osrelease || true
        lower="$(printf '%s' "${r}" | tr '[:upper:]' '[:lower:]')"

        [[ "${lower}" == *microsoft* ]] && return 0

    fi
    if [[ -r /proc/version ]]; then

        IFS= read -r r < /proc/version || true
        lower="$(printf '%s' "${r}" | tr '[:upper:]' '[:lower:]')"

        [[ "${lower}" == *microsoft* ]] && return 0

    fi

    return 1

}
sys::is_unix () {

    sys::is_linux || sys::is_macos

}

sys::is_cygwin () {

    local s=""

    [[ "${OSTYPE:-}" == cygwin* ]] && return 0

    if sys::has uname; then
        s="$(uname -s 2>/dev/null || true)"
    fi

    [[ "${s}" == CYGWIN* ]]

}
sys::is_msys () {

    local m="${MSYSTEM:-}" s=""

    [[ "${OSTYPE:-}" == msys* ]] && return 0

    if sys::has uname; then
        s="$(uname -s 2>/dev/null || true)"
        [[ "${s}" == MSYS* || "${s}" == MINGW* ]] && return 0
    fi

    case "${m}" in
        MSYS|MINGW*|UCRT*|CLANG*) return 0 ;;
        *) return 1 ;;
    esac

}
sys::is_gitbash () {

    sys::is_msys || return 1

    [[ -n "${GitInstallRoot:-}" ]] && return 0
    [[ "${OSTYPE:-}" == msys* && "${MSYSTEM:-}" == MINGW* && -n "${WINDIR:-}" ]] && return 0

    case "${TERM_PROGRAM:-}" in
        mintty)
            [[ "${MSYSTEM:-}" == MINGW* && -z "${MSYS2_PATH_TYPE:-}" ]]
            return
        ;;
    esac

    return 1

}
sys::is_windows () {

    sys::is_wsl && return 1

    sys::is_msys   && return 0
    sys::is_cygwin && return 0

    [[ "${OSTYPE:-}" == win32* || "${OSTYPE:-}" == msys* || "${OSTYPE:-}" == cygwin* ]] && return 0
    [[ -n "${WINDIR:-}" || -n "${SystemRoot:-}" || -n "${COMSPEC:-}" ]] || return 1

    sys::is_linux && return 1
    sys::is_macos && return 1

    return 0

}
sys::is_posix () {

    sys::is_linux || sys::is_macos || sys::is_wsl || sys::is_msys || sys::is_cygwin

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
sys::is_ci () {

    sys::ci_name >/dev/null 2>&1

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
        [[ -z "${SSH_CONNECTION:-}" && -z "${SSH_CLIENT:-}" && -z "${SSH_TTY:-}" && -z "${CI:-}" ]]
        return
    fi
    if sys::is_windows; then

        sys::is_ci && return 1
        [[ -n "${SSH_CONNECTION:-}" || -n "${SSH_CLIENT:-}" || -n "${SSH_TTY:-}" ]] && return 1

        if sys::has powershell.exe; then
            powershell.exe -NoProfile -NonInteractive -Command "[Environment]::UserInteractive" 2>/dev/null | tr -d '\r' | grep -qi '^True$'
            return
        fi

        [[ -n "${WINDIR:-}" || -n "${SystemRoot:-}" ]]
        return

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
    return 0

}
sys::is_container () {

    local r="" lower=""

    [[ -f "/.dockerenv" ]] && return 0
    [[ -f "/run/.containerenv" ]] && return 0

    if [[ -r "/run/systemd/container" ]]; then

        IFS= read -r r < /run/systemd/container || true
        [[ -n "${r}" ]] && return 0

    fi
    if [[ -r /proc/1/cgroup ]]; then

        while IFS= read -r r || [[ -n "${r}" ]]; do

            lower="$(printf '%s' "${r}" | tr '[:upper:]' '[:lower:]')"

            [[ "${lower}" == *docker* ]]     && return 0
            [[ "${lower}" == *kubepods* ]]   && return 0
            [[ "${lower}" == *containerd* ]] && return 0
            [[ "${lower}" == *podman* ]]     && return 0
            [[ "${lower}" == *lxc* ]]        && return 0

        done < /proc/1/cgroup

    fi
    if [[ -r /proc/1/environ ]]; then

        while IFS= read -r -d '' r; do
            [[ "${r}" == container=* ]] && return 0
        done < /proc/1/environ

    fi

    return 1

}

sys::is_root () {

    local v="" cmd=""

    if sys::is_windows; then

        if sys::has net.exe && net.exe session >/dev/null 2>&1; then
            return 0
        fi
        if sys::has powershell.exe; then

            cmd="[bool](([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator))"
            powershell.exe -NoProfile -NonInteractive -Command "${cmd}" 2>/dev/null | tr -d '\r' | grep -qi '^True$'

            return

        fi

        return 1

    fi
    if sys::has id; then

        v="$(id -u 2>/dev/null || true)"
        [[ "${v}" == "0" ]]
        return

    fi

    return 1

}
sys::is_admin () {

    local v="" x=""

    sys::is_root    && return 0
    sys::is_windows && return 1

    if sys::has id; then

        v="$(id -Gn 2>/dev/null || true)"

        for x in ${v}; do
            [[ "${x}" == "sudo"  ]] && return 0
            [[ "${x}" == "wheel" ]] && return 0
            [[ "${x}" == "admin" ]] && return 0
        done

    fi
    if sys::has groups; then

        v="$(groups 2>/dev/null || true)"

        for x in ${v}; do
            [[ "${x}" == "sudo"  ]] && return 0
            [[ "${x}" == "wheel" ]] && return 0
            [[ "${x}" == "admin" ]] && return 0
        done

    fi

    return 1

}
sys::can_sudo () {

    sys::is_windows && return 1
    sys::is_root    && return 0

    sys::has sudo || return 1
    sudo -n true >/dev/null 2>&1

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

                [[ -n "${id}" ]] && break

            done < "${file}"

            [[ -n "${id}" ]] && break

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

        if [[ -n "${runtime}" && "${runtime}" != "unknown" ]]; then
            printf '%s\n' "${runtime}"
            return 0
        fi

        printf '%s\n' "windows"
        return 0

    fi

    printf '%s\n' "unknown"
    return 1

}
sys::manager () {

    if sys::is_linux; then

        sys::has apt-get      && { printf '%s\n' "apt";     return 0; }
        sys::has apk          && { printf '%s\n' "apk";     return 0; }
        sys::has dnf          && { printf '%s\n' "dnf";     return 0; }
        sys::has yum          && { printf '%s\n' "yum";     return 0; }
        sys::has pacman       && { printf '%s\n' "pacman";  return 0; }
        sys::has zypper       && { printf '%s\n' "zypper";  return 0; }
        sys::has xbps-install && { printf '%s\n' "xbps";    return 0; }
        sys::has nix          && { printf '%s\n' "nix";     return 0; }

        printf '%s\n' "unknown"
        return 1

    fi
    if sys::is_macos; then

        sys::has brew && { printf '%s\n' "brew"; return 0; }
        sys::has port && { printf '%s\n' "port"; return 0; }

        printf '%s\n' "unknown"
        return 1

    fi
    if sys::is_windows; then

        if ( sys::is_msys || sys::is_gitbash ) && sys::has pacman; then
            printf '%s\n' "pacman"
            return 0
        fi

        sys::has winget && { printf '%s\n' "winget"; return 0; }
        sys::has choco  && { printf '%s\n' "choco";  return 0; }
        sys::has scoop  && { printf '%s\n' "scoop";  return 0; }
        sys::has pacman && { printf '%s\n' "pacman"; return 0; }

        printf '%s\n' "unknown"
        return 1

    fi

    printf '%s\n' "unknown"
    return 1

}
sys::arch () {

    local v="" lower=""

    sys::has uname && v="$(uname -m 2>/dev/null || true)"

    [[ -n "${v}" ]] || v="${PROCESSOR_ARCHITECTURE:-${HOSTTYPE:-}}"
    [[ -n "${v}" ]] || v="unknown"

    lower="$(printf '%s' "${v}" | tr '[:upper:]' '[:lower:]')"

    case "${lower}" in
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

    local target="${1:-}" type="${2:-auto}" v=""

    [[ -z "${target}" || "${target}" == *$'\n'* || "${target}" == *$'\r'* ]] && return 1

    if [[ "${type}" == "app" ]]; then

        shift 2 || true

        if sys::has "${target}"; then
            "${target}" "$@" >/dev/null 2>&1 &
            sys::has disown && disown
            return 0
        fi
        if sys::has "${target}.exe"; then
            "${target}.exe" "$@" >/dev/null 2>&1 &
            sys::has disown && disown
            return 0
        fi

        return 1

    fi
    if [[ "${type}" == "auto" && -e "${target}" ]]; then

        type="path"

    fi

    if [[ "${type}" == "auto" || "${type}" == "url" ]]; then

        case "${target}" in
            www.*) target="https://${target}" ;;
            http://*|https://*|ftp://*|ftps://*|file://*|mailto:*|ssh://*) ;;
            localhost|localhost:*|localhost/*) target="http://${target}" ;;
            *)
                if [[ "${target}" =~ ^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+(:[0-9]+)?([/?#].*)?$ ]]; then target="http://${target}"
                elif [[ "${target}" =~ ^[A-Za-z0-9._-]+\.[A-Za-z0-9._-]+(:[0-9]+)?([/?#].*)?$ ]]; then target="https://${target}"
                else return 1
                fi
            ;;
        esac

        type="url"

    elif [[ "${type}" == "path" ]]; then

        [[ -e "${target}" ]] || return 1

    else

        return 1

    fi

    if sys::is_macos && sys::has open; then
        open "${target}" >/dev/null 2>&1
        return
    fi
    if sys::is_windows; then

        if [[ "${type}" == "path" ]] && sys::has cygpath; then
            v="$(cygpath -aw "${target}" 2>/dev/null || true)"
            [[ -n "${v}" ]] && target="${v}"
        fi
        if sys::has explorer.exe; then
            explorer.exe "${target}" >/dev/null 2>&1
            return
        fi
        if sys::has cmd.exe; then
            cmd.exe /C start "" "${target}" >/dev/null 2>&1
            return
        fi

        return 1

    fi
    if sys::has xdg-open; then
        xdg-open "${target}" >/dev/null 2>&1
        return
    fi

    return 1

}

sys::disk_total () {

    local path="${1:-.}" v=""

    [[ -n "${path}" ]] || path='.'
    [[ -e "${path}" ]] || return 1

    if sys::has df; then
        v="$(df -Pk "${path}" 2>/dev/null | awk 'NR==2 {print $2}' | head -n 1)"
        [[ "${v}" =~ ^[0-9]+$ ]] && { printf '%s\n' "$(( v * 1024 ))"; return 0; }
    fi

    return 1

}
sys::disk_free () {

    local path="${1:-.}" v=""

    [[ -n "${path}" ]] || path='.'
    [[ -e "${path}" ]] || return 1

    if sys::has df; then
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

    if sys::has du; then
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

        if sys::has powershell.exe; then
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

        if sys::has vm_stat && sys::has sysctl; then

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

        if sys::has powershell.exe; then
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

    [[ "${total}" =~ ^[0-9]+$ ]] || return 1
    [[ "${free}" =~ ^[0-9]+$ ]] || return 1
    [[ "${used}" =~ ^[0-9]+$ ]] || return 1
    [[ "${percent}" =~ ^[0-9]+$ ]] || return 1

    printf '%s\n' "total=${total}" "free=${free}" "used=${used}" "percent=${percent}"

}
