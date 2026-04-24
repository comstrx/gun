
proc::has () {

    command -v "${1:-}" >/dev/null 2>&1

}
proc::die () {

    local msg="${1-}" code="${2:-1}"

    [[ "${code}" =~ ^[0-9]+$ ]] || code=1
    [[ -n "${msg}" ]] && printf '[ERR] %s\n' "${msg}"
    [[ "${-}" == *i* ]] && return "${code}"

    exit "${code}"

}

proc::has_any () {

    local x=""

    (( $# > 0 )) || return 1

    for x in "$@"; do
        proc::has "${x}" && return 0
    done

    return 1

}
proc::has_all () {

    local x=""

    (( $# > 0 )) || return 1

    for x in "$@"; do
        proc::has "${x}" || return 1
    done

    return 0

}

proc::need () {

    local bin="${1:-}"

    [[ -n "${bin}" ]] || return 1
    proc::has "${bin}" && return 0

    proc::die "need command: ${bin}"

}
proc::need_any () {

    local x=""

    (( $# > 0 )) || return 1

    for x in "$@"; do
        proc::has "${x}" && return 0
    done

    proc::die "need any of : $*"

}
proc::need_all () {

    local x=""

    (( $# > 0 )) || return 1

    for x in "$@"; do
        proc::has "${x}" || proc::die "need command: ${x}"
    done

    return 0

}

proc::run () {

    (( $# > 0 )) || return 1

    printf '+ ' >&2
    printf '%q ' "$@" >&2
    printf '\n' >&2

    "$@"

}
proc::run_ok () {

    (( $# > 0 )) || return 1
    "$@" >/dev/null 2>&1

}
proc::run_all () {

    local cmd=""

    (( $# > 0 )) || return 1

    for cmd in "$@"; do

        [[ -n "${cmd}" ]] || return 1

        printf '+ %s\n' "${cmd}" >&2
        "${BASH:-bash}" -lc "${cmd}" || return 1

    done

}
proc::run_all_ok () {

    local cmd=""

    (( $# > 0 )) || return 1

    for cmd in "$@"; do

        [[ -n "${cmd}" ]] || return 1
        "${BASH:-bash}" -lc "${cmd}" >/dev/null 2>&1 || return 1

    done

}

proc::refresh () {

    local manager="" sudo_cmd=""

    manager="$(sys::manager 2>/dev/null || true)"
    proc::has sudo && sudo -n true >/dev/null 2>&1 && sudo_cmd="sudo"

    case "${manager}" in
        apt)     ${sudo_cmd} apt-get update -y ;;
        apk)     ${sudo_cmd} apk update ;;
        dnf)     ${sudo_cmd} dnf makecache -y ;;
        yum)     ${sudo_cmd} yum makecache -y ;;
        zypper)  ${sudo_cmd} zypper --non-interactive refresh ;;
        pacman)  ${sudo_cmd} pacman -Sy --noconfirm ;;
        xbps)    ${sudo_cmd} xbps-install -S ;;
        nix)     nix flake update 2>/dev/null || nix-channel --update ;;
        brew)    brew update ;;
        scoop)   scoop update ;;
        choco)   choco upgrade chocolatey -y ;;
        winget)  winget source update ;;
        *)       return 1 ;;
    esac

}
proc::refresh_ok () {

    proc::refresh >/dev/null 2>&1

}

proc::install () {

    local bin="${1:-}" package="${2:-}" version="${3:-}" force="${4:-0}" refresh="${5:-0}"
    local manager="" current="" sudo_cmd=""

    [[ -n "${bin}" ]] || return 1
    [[ -n "${package}" ]] || package="${bin}"

    [[ "${bin}"     != *$'\n'* && "${bin}"     != *$'\r'* ]] || return 1
    [[ "${package}" != *$'\n'* && "${package}" != *$'\r'* ]] || return 1
    [[ "${version}" != *$'\n'* && "${version}" != *$'\r'* ]] || return 1
    [[ "${force}"   != *$'\n'* && "${force}"   != *$'\r'* ]] || return 1

    if proc::has "${bin}"; then

        [[ -n "${version}" ]] || return 0

        case "${force,,}" in
            1|true|yes|y|force|--force|-force|-f|-y|--yes)
                current="$(
                    "${bin}" --version 2>/dev/null ||
                    "${bin}" -V        2>/dev/null ||
                    "${bin}" -v        2>/dev/null ||
                    "${bin}" version   2>/dev/null || true
                )"

                printf '%s\n' "${current}" | grep -F -- "${version}" >/dev/null 2>&1 && return 0
                proc::uninstall "${bin}" "${package}" >/dev/null 2>&1 || true
            ;;
            *)
                return 0
            ;;
        esac

    fi

    manager="$(sys::manager 2>/dev/null || true)"
    proc::has sudo && sudo -n true >/dev/null 2>&1 && sudo_cmd="sudo"

    case "${refresh,,}" in
        1|true|yes|y|force|--force|-force|-f|-y|--yes) proc::refresh_ok ;;
    esac
    case "${manager,,}" in
        apt)
            if [[ -n "${version}" ]]; then ${sudo_cmd} apt-get install -y "${package}=${version}"
            else ${sudo_cmd} apt-get install -y "${package}"
            fi
        ;;
        apk)
            if [[ -n "${version}" ]]; then ${sudo_cmd} apk add "${package}=${version}"
            else ${sudo_cmd} apk add "${package}"
            fi
        ;;
        dnf)
            if [[ -n "${version}" ]]; then ${sudo_cmd} dnf install -y "${package}-${version}"
            else ${sudo_cmd} dnf install -y "${package}"
            fi
        ;;
        yum)
            if [[ -n "${version}" ]]; then ${sudo_cmd} yum install -y "${package}-${version}"
            else ${sudo_cmd} yum install -y "${package}"
            fi
        ;;
        zypper)
            if [[ -n "${version}" ]]; then ${sudo_cmd} zypper --non-interactive install "${package}=${version}"
            else ${sudo_cmd} zypper --non-interactive install "${package}"
            fi
        ;;
        pacman)
            if [[ -n "${version}" ]]; then ${sudo_cmd} pacman -U --noconfirm "${version}"
            else ${sudo_cmd} pacman -S --needed --noconfirm --noprogressbar "${package}"
            fi
        ;;
        xbps)
            if [[ -n "${version}" ]]; then ${sudo_cmd} xbps-install -Sy "${package}-${version}"
            else ${sudo_cmd} xbps-install -Sy "${package}"
            fi
        ;;
        rpm)
            if [[ -n "${version}" ]]; then ${sudo_cmd} rpm -Uvh --replacepkgs --replacefiles "${package}-${version%.rpm}.rpm"
            else ${sudo_cmd} rpm -Uvh --replacepkgs --replacefiles "${package}"
            fi
        ;;
        nix)
            if [[ -n "${version}" ]]; then nix profile install "nixpkgs/${version}#${package}"
            else nix profile install "nixpkgs#${package}"
            fi
        ;;
        brew)
            if [[ -n "${version}" ]]; then brew install "${package}@${version}"
            else brew install "${package}"
            fi
        ;;
        scoop)
            if [[ -n "${version}" ]]; then scoop install "${package}@${version}"
            else scoop install "${package}"
            fi
        ;;
        choco)
            if [[ -n "${version}" ]]; then choco install -y "${package}" "--version=${version}"
            else choco install -y "${package}"
            fi
        ;;
        winget)
            local -a winget_args=( --source winget --accept-package-agreements --accept-source-agreements --disable-interactivity )

            if [[ -n "${version}" ]]; then winget install -e --id "${package}" --version "${version}" "${winget_args[@]}"
            else winget install -e --id "${package}" "${winget_args[@]}"
            fi
        ;;
        *)
            return 1
        ;;
    esac

    proc::has "${bin}"

}
proc::uninstall () {

    local bin="${1:-}" package="${2:-}" manager="" sudo_cmd=""

    [[ -n "${bin}" ]] || return 1
    [[ -n "${package}" ]] || package="${bin}"

    [[ "${bin}"     != *$'\n'* && "${bin}"     != *$'\r'* ]] || return 1
    [[ "${package}" != *$'\n'* && "${package}" != *$'\r'* ]] || return 1

    manager="$(sys::manager 2>/dev/null || true)"
    proc::has sudo && sudo -n true >/dev/null 2>&1 && sudo_cmd="sudo"

    case "${manager}" in
        apt)     ${sudo_cmd} apt-get remove -y "${package}" ;;
        apk)     ${sudo_cmd} apk del "${package}" ;;
        dnf)     ${sudo_cmd} dnf remove -y "${package}" ;;
        yum)     ${sudo_cmd} yum remove -y "${package}" ;;
        zypper)  ${sudo_cmd} zypper --non-interactive remove "${package}" ;;
        pacman)  ${sudo_cmd} pacman -R --noconfirm "${package}" ;;
        xbps)    ${sudo_cmd} xbps-remove -Ry "${package}" ;;
        rpm)     ${sudo_cmd} rpm -e "${package}" ;;
        nix)     nix profile remove "${package}" 2>/dev/null || nix profile remove "nixpkgs#${package}" ;;
        brew)    brew uninstall "${package}" ;;
        scoop)   scoop uninstall "${package}" ;;
        choco)   choco uninstall -y "${package}" ;;
        winget)  winget uninstall -e --id "${package}" --source winget --disable-interactivity ;;
        *)       return 1 ;;
    esac

    return 0

}

proc::install_all () {

    local spec="" bin="" package="" version="" force="" refresh=""
    (( $# > 0 )) || return 1

    for spec in "$@"; do

        IFS=':' read -r bin package version force refresh <<< "${spec}"
        [[ -n "${bin}" ]] || return 1
        proc::install "${bin}" "${package:-${bin}}" "${version:-}" "${force:-0}" "${refresh:-0}" || return 1

    done

}
proc::uninstall_all () {

    local spec="" bin="" package=""
    (( $# > 0 )) || return 1

    for spec in "$@"; do

        IFS=':' read -r bin package _ <<< "${spec}"
        [[ -n "${bin}" ]] || return 1
        proc::uninstall "${bin}" "${package:-${bin}}" || return 1

    done

}

proc::ensure () {

    proc::install "$@"

}
proc::ensure_all () {

    proc::install_all "$@"

}

proc::path () {

    local bin="${1:-}" p="" ext="" dir=""
    local -a dirs=()

    [[ -n "${bin}" ]] || return 1
    [[ "${bin}" != *$'\n'* && "${bin}" != *$'\r'* ]] || return 1

    if [[ "${bin}" == */* || "${bin}" == *\\* ]]; then

        [[ -f "${bin}" && -x "${bin}" ]] || return 1

        if command -v realpath >/dev/null 2>&1; then
            realpath "${bin}" 2>/dev/null
            return
        fi
        if command -v readlink >/dev/null 2>&1; then
            readlink -f "${bin}" 2>/dev/null
            return
        fi

        printf '%s\n' "${bin}"
        return 0

    fi

    p="$(command -v "${bin}" 2>/dev/null || true)"
    [[ -n "${p}" && "${p}" != "${bin}" ]] && { printf '%s\n' "${p}"; return 0; }

    if sys::is_windows; then

        case "${bin}" in
            *.exe|*.cmd|*.bat|*.ps1) ;;
            *)
                for ext in exe cmd bat ps1; do
                    p="$(command -v "${bin}.${ext}" 2>/dev/null || true)"
                    [[ -n "${p}" && "${p}" != "${bin}.${ext}" ]] && { printf '%s\n' "${p}"; return 0; }
                done
            ;;
        esac

        IFS=';' read -r -a dirs <<< "${PATH:-}"
        (( ${#dirs[@]} <= 1 )) && IFS=':' read -r -a dirs <<< "${PATH:-}"

        for dir in "${dirs[@]}"; do

            [[ -n "${dir}" ]] || continue

            if [[ -f "${dir}/${bin}" && -x "${dir}/${bin}" ]]; then
                printf '%s\n' "${dir}/${bin}"
                return 0
            fi

            for ext in exe cmd bat ps1; do

                if [[ -f "${dir}/${bin}.${ext}" && -x "${dir}/${bin}.${ext}" ]]; then
                    printf '%s\n' "${dir}/${bin}.${ext}"
                    return 0
                fi

            done

        done

    fi

    return 1

}
proc::version () {

    local bin="${1:-}" exe="" arg="" out="" s="" v=""
    local major="" minor="" patch="" tail=""

    [[ -n "${bin}" ]] || return 1
    proc::has "${bin}" || return 1

    exe="$(command -v "${bin}" 2>/dev/null || printf '%s' "${bin}")"

    for arg in --version -v -V version; do

        out="$("${exe}" "${arg}" 2>&1 || true)"
        [[ -n "${out}" ]] || continue

        while IFS= read -r s; do

            [[ -n "${s}" ]] || continue

            if [[ "${s}" =~ ^([0-9]+)\.([0-9]+)(\.([0-9]+))?([.+-].*)?$ ]]; then

                major="${BASH_REMATCH[1]}"
                minor="${BASH_REMATCH[2]}"
                patch="${BASH_REMATCH[4]:-0}"
                tail="${BASH_REMATCH[5]:-}"

                v="${major}.${minor}.${patch}"

                if [[ -n "${tail}" ]]; then
                    tail="${tail#[.+-]}"
                    tail="$(printf '%s\n' "${tail}" | sed -E 's/[.+-]+/./g; s/^\.+//; s/\.+$//')"
                    [[ -n "${tail}" ]] && v="${v}-${tail}"
                fi

                printf '%s\n' "${v}"
                return 0

            fi

        done < <(
            printf '%s\n' "${out}" |
            LC_ALL=C grep -Eio '[0-9]+[.][0-9]+([.][0-9]+)?([.+-][0-9A-Za-z][0-9A-Za-z.+-]*)?' 2>/dev/null
        )

    done

    return 1

}
