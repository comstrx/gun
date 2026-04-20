
is_linux () {

    [[ "${OSTYPE:-}" == linux* ]]

}
is_macos () {

    [[ "${OSTYPE:-}" == darwin* ]]

}
is_windows () {

    is_wsl && return 1

    [[ "${OSTYPE:-}" == msys* || "${OSTYPE:-}" == cygwin* || "${OSTYPE:-}" == win32* ]] && return 0
    [[ -n "${WINDIR:-}" ]] && ! is_linux && return 0

    return 1

}

is_unix () {

    is_linux || is_macos

}
is_wsl () {

    is_linux || return 1

    [[ -n "${WSL_DISTRO_NAME:-}" || -n "${WSL_INTEROP:-}" ]] && return 0
    [[ -r /proc/sys/kernel/osrelease ]] && grep -qi 'microsoft' /proc/sys/kernel/osrelease && return 0

    [[ -r /proc/version ]] && grep -qi 'microsoft' /proc/version

}
is_msys () {

    [[ "${OSTYPE:-}" == msys* || "${MSYSTEM:-}" == MINGW* || "${MSYSTEM:-}" == MSYS ]]

}
is_gitbash () {

    [[ "${OSTYPE:-}" == msys* || "${MSYSTEM:-}" == MINGW* ]] || return 1
    [[ -n "${GitInstallRoot:-}" || "${TERM_PROGRAM:-}" == "mintty" ]]

}

is_ci () {

    [[ -n "${CI:-}" ]] && return 0
    [[ -n "${GITHUB_ACTIONS:-}" ]] && return 0
    [[ -n "${GITLAB_CI:-}" ]] && return 0
    [[ -n "${JENKINS_URL:-}" ]] && return 0
    [[ -n "${BUILDKITE:-}" ]] && return 0
    [[ -n "${CIRCLECI:-}" ]] && return 0
    [[ -n "${TRAVIS:-}" ]] && return 0
    [[ -n "${APPVEYOR:-}" ]] && return 0
    [[ -n "${TF_BUILD:-}" ]] && return 0
    [[ -n "${BITBUCKET_BUILD_NUMBER:-}" ]] && return 0
    [[ -n "${TEAMCITY_VERSION:-}" ]] && return 0

    return 1

}
is_ci_pull () {

    [[ "${GITHUB_EVENT_NAME:-}" == "pull_request" || "${GITHUB_EVENT_NAME:-}" == "pull_request_target" ]] && return 0
    [[ -n "${CI_MERGE_REQUEST_IID:-}" ]] && return 0
    [[ -n "${BITBUCKET_PR_ID:-}" ]] && return 0
    [[ -n "${SYSTEM_PULLREQUEST_PULLREQUESTID:-}" ]] && return 0

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
is_gui () {

    if is_linux; then
        [[ -n "${DISPLAY:-}" || -n "${WAYLAND_DISPLAY:-}" ]]
        return
    fi

    is_macos && return 0
    is_windows && return 0

    return 1

}
is_terminal () {

    [[ -t 0 || -t 1 || -t 2 ]]

}
is_container () {

    [[ -f "/.dockerenv" ]] && return 0
    [[ -f "/run/.containerenv" ]] && return 0
    [[ -r "/run/systemd/container" ]] && return 0

    [[ -r /proc/1/cgroup ]] && grep -Eiq '/(docker|kubepods|containerd|podman|lxc)(/|$)' /proc/1/cgroup && return 0
    [[ -r /proc/1/environ ]] && tr '\0' '\n' < /proc/1/environ 2>/dev/null | grep -iq '^container=' && return 0

    return 1

}
is_headless () {

    if is_linux; then
        [[ -z "${DISPLAY:-}" && -z "${WAYLAND_DISPLAY:-}" ]]
        return
    fi

    return 1

}
is_interactive () {

    [[ "${-}" == *i* ]]

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

}
os_family () {

    if is_windows; then
        printf '%s\n' "windows"
        return 0
    fi

    printf '%s\n' "unix"

}
os_distro () {

    if is_linux; then

        if [[ -r /etc/os-release ]]; then

            local id=""
            id="$(sed -n 's/^ID=//p' /etc/os-release | head -n 1)"
            id="${id%\"}"
            id="${id#\"}"

            [[ -n "${id}" ]] && { printf '%s\n' "${id}"; return 0; }

        fi

    fi
    if is_macos; then

        printf '%s\n' "macos"
        return 0

    fi
    if is_windows; then

        if is_gitbash; then printf '%s\n' "gitbash"
        elif is_msys; then printf '%s\n' "msys2"
        else printf '%s\n' "windows"
        fi

        return 0

    fi

    printf '%s\n' "unknown"

}
os_manager () {

    if is_linux; then

        if has apt-get;      then printf '%s\n' "apt";     return 0; fi
        if has apk;          then printf '%s\n' "apk";     return 0; fi
        if has dnf;          then printf '%s\n' "dnf";     return 0; fi
        if has yum;          then printf '%s\n' "yum";     return 0; fi
        if has pacman;       then printf '%s\n' "pacman";  return 0; fi
        if has zypper;       then printf '%s\n' "zypper";  return 0; fi
        if has nix;          then printf '%s\n' "nix";     return 0; fi
        if has xbps-install; then printf '%s\n' "xbps";    return 0; fi
        if has snap;         then printf '%s\n' "snap";    return 0; fi
        if has flatpak;      then printf '%s\n' "flatpak"; return 0; fi

    fi
    if is_macos; then

        if has brew; then printf '%s\n' "brew"; return 0; fi

    fi
    if is_windows; then

        if has pacman; then printf '%s\n' "pacman"; return 0; fi
        if has winget; then printf '%s\n' "winget"; return 0; fi
        if has choco;  then printf '%s\n' "choco";  return 0; fi
        if has scoop;  then printf '%s\n' "scoop";  return 0; fi

    fi

    printf '%s\n' "unknown"
    return 1

}
os_arch () {

    local v=""

    if has uname; then
        v="$(uname -m 2>/dev/null || true)"
        [[ -n "${v}" ]] && { printf '%s\n' "${v}"; return 0; }
    fi

    v="${PROCESSOR_ARCHITECTURE:-${HOSTTYPE:-}}"
    [[ -n "${v}" ]] && { printf '%s\n' "${v}"; return 0; }

    printf '%s\n' "unknown"
    return 1

}
