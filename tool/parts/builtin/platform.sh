
__platform_has () {

    command -v -- "${1:-}" >/dev/null 2>&1

}
__platform_ostype () {

    printf '%s' "${OSTYPE:-}"

}
__platform_uname_s () {

    local v=""

    if __platform_has uname; then
        v="$(uname -s 2>/dev/null || true)"
        [[ -n "${v}" ]] && printf '%s' "${v}"
    fi

}
__platform_uname_r () {

    local v=""

    if __platform_has uname; then
        v="$(uname -r 2>/dev/null || true)"
        [[ -n "${v}" ]] && printf '%s' "${v}"
    fi

}
__platform_uname_m () {

    local v=""

    if __platform_has uname; then
        v="$(uname -m 2>/dev/null || true)"
        [[ -n "${v}" ]] && printf '%s' "${v}"
    fi

}
__platform_read_os_release () {

    local key="${1:-}" line="" file=""

    [[ -n "${key}" ]] || return 1

    for file in /etc/os-release /usr/lib/os-release; do

        [[ -r "${file}" ]] || continue

        while IFS= read -r line || [[ -n "${line}" ]]; do

            [[ "${line}" == "${key}="* ]] || continue

            line="${line#*=}"
            line="${line%\"}"
            line="${line#\"}"

            printf '%s' "${line}"
            return 0

        done < "${file}"

    done

    return 1

}
__platform_string_has_ci () {

    local s="${1-}" part="${2-}"

    [[ -n "${part}" ]] || return 1
    [[ "${s,,}" == *"${part,,}"* ]]

}
__platform_arch_normalize () {

    local v="${1-}"

    case "${v,,}" in
        x86_64|amd64)                    printf '%s\n' "x64" ;;
        x86|i386|i486|i586|i686)        printf '%s\n' "x86" ;;
        aarch64|arm64)                  printf '%s\n' "arm64" ;;
        armv7l|armv7|armhf)             printf '%s\n' "armv7" ;;
        armv6l|armv6)                   printf '%s\n' "armv6" ;;
        arm)                            printf '%s\n' "arm" ;;
        ppc64le)                        printf '%s\n' "ppc64le" ;;
        ppc64)                          printf '%s\n' "ppc64" ;;
        s390x)                          printf '%s\n' "s390x" ;;
        riscv64)                        printf '%s\n' "riscv64" ;;
        *)                              printf '%s\n' "${v:-unknown}" ;;
    esac

}

is_linux () {

    local s="" o=""

    s="$(__platform_uname_s)"
    [[ "${s}" == "Linux" ]] && return 0

    o="$(__platform_ostype)"
    [[ "${o}" == linux* ]]

}
is_macos () {

    local s="" o=""

    s="$(__platform_uname_s)"
    [[ "${s}" == "Darwin" ]] && return 0

    o="$(__platform_ostype)"
    [[ "${o}" == darwin* ]]

}
is_wsl () {

    local r=""

    is_linux || return 1

    [[ -n "${WSL_DISTRO_NAME:-}" || -n "${WSL_INTEROP:-}" ]] && return 0

    if [[ -r /proc/sys/kernel/osrelease ]]; then
        IFS= read -r r < /proc/sys/kernel/osrelease || true
        __platform_string_has_ci "${r}" "microsoft" && return 0
    fi

    if [[ -r /proc/version ]]; then
        IFS= read -r r < /proc/version || true
        __platform_string_has_ci "${r}" "microsoft" && return 0
    fi

    return 1

}
is_cygwin () {

    local o=""

    o="$(__platform_ostype)"
    [[ "${o}" == cygwin* ]]

}
is_msys () {

    local o="" m=""

    o="$(__platform_ostype)"
    m="${MSYSTEM:-}"

    [[ "${o}" == msys* ]] && return 0

    case "${m}" in
        MSYS|MINGW*|UCRT*|CLANG*) return 0 ;;
        *) return 1 ;;
    esac

}
is_gitbash () {

    is_msys || return 1

    [[ -n "${GitInstallRoot:-}" ]] && return 0

    case "${TERM_PROGRAM:-}" in
        mintty) return 0 ;;
    esac

    [[ -n "${MINGW_PREFIX:-}" && -z "${MSYS2_PATH_TYPE:-}" ]] && return 0

    return 1

}
is_windows () {

    is_wsl && return 1

    is_msys   && return 0
    is_cygwin && return 0

    [[ -n "${WINDIR:-}" || -n "${SystemRoot:-}" ]] || return 1
    is_linux && return 1
    is_macos && return 1

    return 0

}
is_unix () {

    is_linux || is_macos

}
is_posix_env () {

    is_linux || is_macos || is_wsl || is_msys || is_cygwin

}

is_ci () {

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
ci_name () {

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
is_ci_pull () {

    [[ "${GITHUB_EVENT_NAME:-}" == "pull_request" || "${GITHUB_EVENT_NAME:-}" == "pull_request_target" ]] && return 0
    [[ -n "${CI_MERGE_REQUEST_IID:-}" ]]        && return 0
    [[ -n "${BITBUCKET_PR_ID:-}" ]]             && return 0
    [[ -n "${SYSTEM_PULLREQUEST_PULLREQUESTID:-}" ]] && return 0
    [[ "${BUILD_REASON:-}" == "PullRequest" ]]  && return 0

    return 1

}
is_ci_push () {

    is_ci || return 1
    is_ci_pull && return 1

    [[ "${GITHUB_EVENT_NAME:-}" == "push" ]] && return 0
    [[ "${CI_PIPELINE_SOURCE:-}" == "push" ]] && return 0
    [[ -n "${BITBUCKET_COMMIT:-}" && -z "${BITBUCKET_PR_ID:-}" ]] && return 0
    [[ "${BUILD_REASON:-}" == "IndividualCI" || "${BUILD_REASON:-}" == "BatchedCI" ]] && return 0

    return 1

}
is_ci_tag () {

    [[ -n "${GITHUB_REF_TYPE:-}" && "${GITHUB_REF_TYPE:-}" == "tag" ]] && return 0
    [[ -n "${CI_COMMIT_TAG:-}" ]] && return 0
    [[ -n "${BITBUCKET_TAG:-}" ]] && return 0
    [[ "${BUILD_SOURCEBRANCH:-}" == refs/tags/* ]] && return 0

    return 1

}

is_terminal () {

    [[ -t 0 || -t 1 || -t 2 ]]

}
is_interactive () {

    [[ "${-}" == *i* ]]

}
is_gui () {

    if is_linux; then
        [[ -n "${DISPLAY:-}" || -n "${WAYLAND_DISPLAY:-}" ]]
        return
    fi

    if is_macos; then
        [[ -z "${SSH_CONNECTION:-}" && -z "${SSH_CLIENT:-}" && -z "${SSH_TTY:-}" ]]
        return
    fi

    if is_windows; then
        is_ci && return 1
        return 0
    fi

    return 1

}
is_headless () {

    is_gui && return 1

    if is_linux; then
        [[ -z "${DISPLAY:-}" && -z "${WAYLAND_DISPLAY:-}" ]]
        return
    fi

    if is_macos || is_windows; then
        [[ -n "${SSH_CONNECTION:-}" || -n "${SSH_CLIENT:-}" || -n "${SSH_TTY:-}" || -n "${CI:-}" ]]
        return
    fi

    return 1

}
is_container () {

    local r=""

    [[ -f "/.dockerenv" ]]          && return 0
    [[ -f "/run/.containerenv" ]]   && return 0

    if [[ -r "/run/systemd/container" ]]; then
        IFS= read -r r < /run/systemd/container || true
        [[ -n "${r}" ]] && return 0
    fi

    if [[ -r /proc/1/cgroup ]]; then
        while IFS= read -r r || [[ -n "${r}" ]]; do
            __platform_string_has_ci "${r}" "docker"     && return 0
            __platform_string_has_ci "${r}" "kubepods"   && return 0
            __platform_string_has_ci "${r}" "containerd" && return 0
            __platform_string_has_ci "${r}" "podman"     && return 0
            __platform_string_has_ci "${r}" "lxc"        && return 0
        done < /proc/1/cgroup
    fi

    if [[ -r /proc/1/environ ]]; then
        while IFS= read -r -d '' r; do
            [[ "${r}" == container=* ]] && return 0
        done < /proc/1/environ
    fi

    return 1

}

os_name () {

    if is_linux; then
        printf '%s\n' "linux"
        return 0
    fi

    if is_macos; then
        printf '%s\n' "macos"
        return 0
    fi

    if is_windows; then
        printf '%s\n' "windows"
        return 0
    fi

    printf '%s\n' "unknown"
    return 1

}
os_family () {

    if is_windows; then
        printf '%s\n' "windows"
        return 0
    fi

    if is_linux || is_macos; then
        printf '%s\n' "unix"
        return 0
    fi

    printf '%s\n' "unknown"
    return 1

}
os_runtime () {

    if is_wsl; then
        printf '%s\n' "wsl"
        return 0
    fi

    if is_gitbash; then
        printf '%s\n' "gitbash"
        return 0
    fi

    if is_msys; then
        printf '%s\n' "msys2"
        return 0
    fi

    if is_cygwin; then
        printf '%s\n' "cygwin"
        return 0
    fi

    if is_linux; then
        printf '%s\n' "linux"
        return 0
    fi

    if is_macos; then
        printf '%s\n' "macos"
        return 0
    fi

    if is_windows; then
        printf '%s\n' "windows"
        return 0
    fi

    printf '%s\n' "unknown"
    return 1

}
os_distro () {

    local id="" runtime=""

    if is_linux; then
        id="$(__platform_read_os_release ID || true)"
        [[ -n "${id}" ]] && { printf '%s\n' "${id}"; return 0; }
        printf '%s\n' "linux"
        return 0
    fi

    if is_macos; then
        printf '%s\n' "macos"
        return 0
    fi

    if is_windows; then
        runtime="$(os_runtime 2>/dev/null || true)"
        [[ -n "${runtime}" ]] && { printf '%s\n' "${runtime}"; return 0; }
    fi

    printf '%s\n' "unknown"
    return 1

}
os_manager () {

    local distro="" runtime=""

    if is_linux; then

        distro="$(os_distro 2>/dev/null || true)"

        case "${distro}" in
            ubuntu|debian|linuxmint|pop|elementary|kali|raspbian)
                __platform_has apt-get && { printf '%s\n' "apt"; return 0; }
                ;;
            alpine)
                __platform_has apk && { printf '%s\n' "apk"; return 0; }
                ;;
            fedora)
                __platform_has dnf && { printf '%s\n' "dnf"; return 0; }
                ;;
            rhel|centos|rocky|almalinux|ol)
                __platform_has dnf && { printf '%s\n' "dnf"; return 0; }
                __platform_has yum && { printf '%s\n' "yum"; return 0; }
                ;;
            arch|manjaro|endeavouros)
                __platform_has pacman && { printf '%s\n' "pacman"; return 0; }
                ;;
            opensuse*|sles)
                __platform_has zypper && { printf '%s\n' "zypper"; return 0; }
                ;;
            void)
                __platform_has xbps-install && { printf '%s\n' "xbps"; return 0; }
                ;;
            nixos)
                __platform_has nix && { printf '%s\n' "nix"; return 0; }
                ;;
        esac

        __platform_has apt-get      && { printf '%s\n' "apt";     return 0; }
        __platform_has apk          && { printf '%s\n' "apk";     return 0; }
        __platform_has dnf          && { printf '%s\n' "dnf";     return 0; }
        __platform_has yum          && { printf '%s\n' "yum";     return 0; }
        __platform_has pacman       && { printf '%s\n' "pacman";  return 0; }
        __platform_has zypper       && { printf '%s\n' "zypper";  return 0; }
        __platform_has xbps-install && { printf '%s\n' "xbps";    return 0; }
        __platform_has nix          && { printf '%s\n' "nix";     return 0; }

        printf '%s\n' "unknown"
        return 1

    fi

    if is_macos; then
        __platform_has brew && { printf '%s\n' "brew"; return 0; }
        __platform_has port && { printf '%s\n' "port"; return 0; }

        printf '%s\n' "unknown"
        return 1
    fi

    if is_windows; then

        runtime="$(os_runtime 2>/dev/null || true)"

        case "${runtime}" in
            gitbash|msys2)
                __platform_has pacman && { printf '%s\n' "pacman"; return 0; }
                ;;
        esac

        __platform_has winget && { printf '%s\n' "winget"; return 0; }
        __platform_has choco  && { printf '%s\n' "choco";  return 0; }
        __platform_has scoop  && { printf '%s\n' "scoop";  return 0; }
        __platform_has pacman && { printf '%s\n' "pacman"; return 0; }

        printf '%s\n' "unknown"
        return 1
    fi

    printf '%s\n' "unknown"
    return 1

}
os_arch () {

    local v=""

    v="$(__platform_uname_m)"
    [[ -n "${v}" ]] || v="${PROCESSOR_ARCHITECTURE:-${HOSTTYPE:-}}"
    [[ -n "${v}" ]] || v="unknown"

    __platform_arch_normalize "${v}"

}
