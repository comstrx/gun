# shellcheck shell=bash
# shellcheck disable=SC1090,SC2178

# ======>> Numeric <<======

int () {

    local v="${1-}"

    case "${v}" in
        "" ) printf '%s' "0" ;;
        true|TRUE|True|yes|YES|Yes|y|Y) printf '%s' "1" ;;
        false|FALSE|False|no|NO|No|n|N) printf '%s' "0" ;;
        *)
            if [[ "${v}" =~ ^[+-]?[0-9]+$ ]]; then
                printf '%s' "${v}"
                return 0
            fi
            if [[ "${v}" =~ ^[+-]?[0-9]*\.[0-9]+$ ]]; then
                printf '%s' "${v%%.*}"
                return 0
            fi

            printf '%s' "0"
        ;;
    esac

}
float () {

    local v="${1-}"

    case "${v}" in
        "" ) printf '%s' "0.0" ;;
        true|TRUE|True|yes|YES|Yes|y|Y) printf '%s' "1.0" ;;
        false|FALSE|False|no|NO|No|n|N) printf '%s' "0.0" ;;
        *)
            if [[ "${v}" =~ ^[+-]?[0-9]+$ ]]; then
                printf '%s.0' "${v}"
                return 0
            fi
            if [[ "${v}" =~ ^[+-]?([0-9]+([.][0-9]+)?|[.][0-9]+)$ ]]; then
                printf '%s' "${v}"
                return 0
            fi

            printf '%s' "0.0"
        ;;
    esac

}
abs () {

    local v=""
    v="$(int "${1-}")" || return 1

    if [[ "${v}" == -* ]]; then printf '%s' "${v#-}"
    else printf '%s' "${v#+}"
    fi

}
bool () {

    local v="${1-}"

    case "${v,,}" in
        1|true|yes|y|on) printf '%s' "1" ;;
        *)               printf '%s' "0" ;;
    esac

}
char () {

    local v="${1:-}"

    if (( ${#v} == 1 )); then
        printf '%s' "${v}"
        return 0
    fi

    printf '%s' ""

}
is_int () {

    [[ "${1:-}" =~ ^-?[0-9]+$ ]]

}
is_uint () {

    [[ "${1:-}" =~ ^[0-9]+$ ]]

}
is_float () {

    [[ "${1:-}" =~ ^[+-]?([0-9]+([.][0-9]+)?|[.][0-9]+)$ ]]

}
is_bool () {

    case "${1,,}" in
        1|0|true|false|yes|no|y|n) return 0 ;;
        *) return 1 ;;
    esac

}
is_true () {

    case "${1,,}" in
        1|true|yes|y|on) return 0 ;;
        *) return 1 ;;
    esac

}
is_char () {

    local v="${1-}"
    (( ${#v} == 1 ))

}

# ======>> String <<======

trim () {

    local s="${1-}"

    s="${s#"${s%%[![:space:]]*}"}"
    s="${s%"${s##*[![:space:]]}"}"

    printf '%s' "${s}"

}
lower () {

    printf '%s' "${1-}" | tr '[:upper:]' '[:lower:]'

}
upper () {

    printf '%s' "${1-}" | tr '[:lower:]' '[:upper:]'

}
title () {

    local s="${1-}" buf="" word=""

    for word in ${s}; do
        [[ -n "${buf}" ]] && buf+=' '
        buf+="$(capitalize "${word}")"
    done

    printf '%s' "${buf}"

}
capitalize () {

    local s="${1-}"

    [[ -n "${s}" ]] || return 0
    printf '%s%s' "${s:0:1^^}" "${s:1}"

}
repeat () {

    local s="${1-}" n="${2:-0}" i=0
    [[ "${n}" =~ ^[0-9]+$ ]] || return 1

    for (( i=0; i<n; i++ )); do
        printf '%s' "${s}"
    done

}
before () {

    local s="${1-}" x="${2-}"

    [[ -n "${x}" && "${s}" == *"${x}"* ]] || { printf '%s' "${s}"; return 0; }
    printf '%s' "${s%%"${x}"*}"

}
after () {

    local s="${1-}" x="${2-}"

    [[ -n "${x}" && "${s}" == *"${x}"* ]] || return 1
    printf '%s' "${s#*"${x}"}"

}
join_by () {

    local sep="${1-}" buf="" x=""
    shift || true

    for x in "$@"; do

        if [[ -z "${buf}" ]]; then buf="${x}"
        else buf="${buf}${sep}${x}"
        fi

    done

    printf '%s' "${buf}"

}
contains () {

    local s="${1-}" part="${2-}"
    [[ "${s}" == *"${part}"* ]]

}
starts_with () {

    local s="${1-}" prefix="${2-}"
    [[ "${s}" == "${prefix}"* ]]

}
ends_with () {

    local s="${1-}" suffix="${2-}"
    [[ "${s}" == *"${suffix}" ]]

}
is_email () {

    [[ "${1:-}" =~ ^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$ ]]

}
is_url () {

    [[ "${1:-}" =~ ^https?://[^[:space:]]+$ ]]

}

# ======>> List <<======

list_len () {

    local name="${1:-}"
    [[ -n "${name}" ]] || return 1

    declare -n ref="${name}"
    printf '%s\n' "${#ref[@]}"

}
list_add () {

    local name="${1:-}"
    [[ -n "${name}" ]] || return 1
    shift || true

    declare -n ref="${name}"
    ref+=( "$@" )

}
list_pop () {

    local name="${1:-}" out="${2-}" i="" last="" value=""
    [[ -n "${name}" ]] || return 1

    declare -n ref="${name}"

    (( ${#ref[@]} > 0 )) || return 1

    for i in "${!ref[@]}"; do
        [[ -z "${last}" || "${i}" -gt "${last}" ]] && last="${i}"
    done

    [[ -n "${last}" ]] || return 1

    value="${ref[$last]}"
    unset 'ref[$last]'

    if [[ -n "${out}" ]]; then printf -v "${out}" '%s' "${value}"
    else printf '%s' "${value}"
    fi

}
list_shift () {

    local name="${1:-}" out="${2-}"
    [[ -n "${name}" ]] || return 1

    declare -n ref="${name}"
    (( ${#ref[@]} > 0 )) || return 1

    local value="${ref[0]}"
    ref=( "${ref[@]:1}" )

    if [[ -n "${out}" ]]; then printf -v "${out}" '%s' "${value}"
    else printf '%s' "${value}"
    fi

}
list_unshift () {

    local name="${1:-}"

    [[ -n "${name}" ]] || return 1
    shift || true

    declare -n ref="${name}"
    ref=( "$@" "${ref[@]}" )

}
list_get () {

    local name="${1:-}" index="${2-}" def="${3-}"

    [[ -n "${name}" ]] || return 1
    [[ "${index}" =~ ^[0-9]+$ ]] || { printf '%s' "${def}"; return 0; }

    declare -n ref="${name}"

    if [[ -n "${ref[$index]+x}" ]]; then printf '%s' "${ref[$index]}"
    else printf '%s' "${def}"
    fi

}
list_set () {

    local name="${1:-}" index="${2-}" value="${3-}"

    [[ -n "${name}" ]] || return 1
    [[ "${index}" =~ ^[0-9]+$ ]] || return 1

    declare -n ref="${name}"
    ref["${index}"]="${value}"

}
list_concat () {

    local name="${1:-}" other="${2:-}"
    [[ -n "${name}" && -n "${other}" ]] || return 1

    declare -n ref="${name}"
    declare -n src="${other}"

    ref+=( "${src[@]}" )

}
list_unique () {

    local name="${1:-}"
    [[ -n "${name}" ]] || return 1

    declare -n ref="${name}"

    local x=""
    local -A seen=()
    local -a out=()

    for x in "${ref[@]}"; do

        [[ -n "${seen[$x]+x}" ]] && continue

        seen["$x"]=1
        out+=( "${x}" )

    done

    ref=( "${out[@]}" )

}
list_clear () {

    local name="${1:-}"
    [[ -n "${name}" ]] || return 1

    declare -n ref="${name}"
    ref=()

}

# ======>> Dict <<======

map_keys () {

    local name="${1:-}" k=""
    [[ -n "${name}" ]] || return 1

    declare -n ref="${name}"

    for k in "${!ref[@]}"; do
        printf '%s\n' "${k}"
    done

}
map_values () {

    local name="${1:-}" k=""
    [[ -n "${name}" ]] || return 1

    declare -n ref="${name}"

    for k in "${!ref[@]}"; do
        printf '%s\n' "${ref[$k]}"
    done

}
map_has () {

    local name="${1:-}" key="${2-}"
    [[ -n "${name}" && -n "${key}" ]] || return 1

    declare -n ref="${name}"
    [[ -n "${ref[$key]+x}" ]]

}
map_get () {

    local name="${1:-}" key="${2-}" def="${3-}"
    [[ -n "${name}" ]] || return 1

    declare -n ref="${name}"

    if [[ -n "${ref[$key]+x}" ]]; then printf '%s' "${ref[$key]}"
    else printf '%s' "${def}"
    fi

}
map_set () {

    local name="${1:-}" key="${2-}" value="${3-}"
    [[ -n "${name}" && -n "${key}" ]] || return 1

    declare -n ref="${name}"
    ref["${key}"]="${value}"

}
map_del () {

    local name="${1:-}" key="${2-}"
    [[ -n "${name}" && -n "${key}" ]] || return 1

    declare -n ref="${name}"
    unset 'ref[$key]'

}
map_len () {

    local name="${1:-}"
    [[ -n "${name}" ]] || return 1

    declare -n ref="${name}"
    printf '%s\n' "${#ref[@]}"

}
map_clear () {

    local name="${1:-}"
    [[ -n "${name}" ]] || return 1

    declare -n ref="${name}"
    ref=()

}

# ======>> Stdout <<======

log () {

    local IFS=' '

    (( $# )) || { printf '\n' >&2; return 0; }
    printf '%s\n' "$*" >&2

}
print () {

    local IFS=' '

    (( $# )) || { printf '\n'; return 0; }
    printf '%s\n' "$*"

}
eprint () {

    local IFS=' '

    (( $# )) || { printf '\n' >&2; return 0; }
    printf '%s\n' "$*" >&2

}
info () {

    local tag="💥"
    local IFS=' '

    (( $# )) || { printf '%s\n' "${tag}" >&2; return 0; }
    printf '%s %s\n' "${tag}" "$*" >&2

}
warn () {

    local tag="⚠️"
    local IFS=' '

    (( $# )) || { printf '%s\n' "${tag}" >&2; return 0; }
    printf '%s %s\n' "${tag}" "$*" >&2

}
error () {

    local tag="❌"
    local IFS=' '

    (( $# )) || { printf '%s\n' "${tag}" >&2; return 0; }
    printf '%s %s\n' "${tag}" "$*" >&2

}
success () {

    local tag="✅"
    local IFS=' '

    (( $# )) || { printf '%s\n' "${tag}" >&2; return 0; }
    printf '%s %s\n' "${tag}" "$*" >&2

}
die () {

    local msg="${1-}" code="${2:-1}"

    [[ "${code}" =~ ^[0-9]+$ ]] || code=1
    [[ -n "${msg}" ]] && error "${msg}"

    if [[ "${-}" == *i* ]]; then
        return "${code}"
    fi

    exit "${code}"

}

# ======>> Stdin <<======

input () {

    local prompt="${1-}" def="${2-}" line="" rc=0
    local tty="/dev/tty"

    if [[ -r "${tty}" && -w "${tty}" ]]; then
        [[ -n "${prompt}" ]] && printf '%s' "${prompt}" > "${tty}"
        IFS= read -r line < "${tty}" || rc=$?
    else
        [[ -n "${prompt}" ]] && printf '%s' "${prompt}" >&2
        IFS= read -r line || rc=$?
    fi

    if (( rc != 0 )); then
        [[ -n "${def}" ]] && { printf '%s' "${def}"; return 0; }
        return "${rc}"
    fi

    [[ -z "${line}" && -n "${def}" ]] && line="${def}"
    printf '%s' "${line}"

}
input_bool () {

    local prompt="${1-}" def="${2-}" tries="${3:-3}" v="" i=0

    [[ "${tries}" =~ ^[0-9]+$ ]] || tries=3
    (( tries > 0 )) || tries=3

    for (( i=0; i<tries; i++ )); do

        v="$(input "${prompt}" "${def}")" || return $?

        case "${v,,}" in
            1|true|yes|y|on)  printf '1'; return 0 ;;
            0|false|no|n|off) printf '0'; return 0 ;;
        esac

        eprint "Invalid bool. Use: y/n, yes/no, on/off, 1/0, true/false"

    done

    die "Too many invalid attempts"

}
input_int () {

    local prompt="${1-}" def="${2-}" tries="${3:-3}" v="" i=0

    [[ "${tries}" =~ ^[0-9]+$ ]] || tries=3
    (( tries > 0 )) || tries=3

    for (( i=0; i<tries; i++ )); do

        v="$(input "${prompt}" "${def}")" || return $?

        [[ "${v}" =~ ^-?[0-9]+$ ]] && { printf '%s' "${v}"; return 0; }
        eprint "Invalid int. Example: 0, 12, -7"

    done

    die "Too many invalid attempts"

}
input_uint () {

    local prompt="${1-}" def="${2-}" tries="${3:-3}" v="" i=0

    [[ "${tries}" =~ ^[0-9]+$ ]] || tries=3
    (( tries > 0 )) || tries=3

    for (( i=0; i<tries; i++ )); do

        v="$(input "${prompt}" "${def}")" || return $?

        [[ "${v}" =~ ^[0-9]+$ ]] && { printf '%s' "${v}"; return 0; }
        eprint "Invalid uint. Example: 0, 12, 7"

    done

    die "Too many invalid attempts"

}
input_float () {

    local prompt="${1-}" def="${2-}" tries="${3:-3}" v="" i=0

    [[ "${tries}" =~ ^[0-9]+$ ]] || tries=3
    (( tries > 0 )) || tries=3

    for (( i=0; i<tries; i++ )); do

        v="$(input "${prompt}" "${def}")" || return $?

        [[ "${v}" =~ ^[+-]?([0-9]+([.][0-9]+)?|[.][0-9]+)$ ]] && { printf '%s' "${v}"; return 0; }
        eprint "Invalid float. Example: 0, 12.5, -7, .3"

    done

    die "Too many invalid attempts"

}
input_char () {

    local prompt="${1-}" def="${2-}" tries="${3:-3}" v="" i=0

    [[ "${tries}" =~ ^[0-9]+$ ]] || tries=3
    (( tries > 0 )) || tries=3

    for (( i=0; i<tries; i++ )); do

        v="$(input "${prompt}" "${def}")" || return $?

        (( ${#v} == 1 )) && { printf '%s' "${v}"; return 0; }
        eprint "Invalid char. Example: a"

    done

    die "Too many invalid attempts"

}
input_path () {

    local prompt="${1-}" def="${2-}" mode="${3:-any}" tries="${4:-3}"
    local p="" i=0

    [[ "${tries}" =~ ^[0-9]+$ ]] || tries=3
    (( tries > 0 )) || tries=3

    case "${mode}" in
        any|exists|file|dir) ;;
        *) die "Invalid mode '${mode}'" ;;
    esac

    for (( i=0; i<tries; i++ )); do

        p="$(input "${prompt}" "${def}")" || return $?

        [[ -n "${p}" ]] || { eprint "Path is required"; continue; }

        case "${mode}" in
            any)    printf '%s' "${p}"; return 0 ;;
            exists) [[ -e "${p}" ]] && { printf '%s' "${p}"; return 0; } ;;
            file)   [[ -f "${p}" ]] && { printf '%s' "${p}"; return 0; } ;;
            dir)    [[ -d "${p}" ]] && { printf '%s' "${p}"; return 0; } ;;
        esac

        eprint "Invalid path for mode '${mode}': ${p}"

    done

    die "Too many invalid attempts"

}
input_password () {

    local prompt="${1-}" line="" rc=0
    local tty="/dev/tty"

    [[ -r "${tty}" && -w "${tty}" ]] || die "No /dev/tty"
    [[ -n "${prompt}" ]] && printf '%s' "${prompt}" > "${tty}"

    IFS= read -r -s line < "${tty}" || rc=$?
    printf '\n' > "${tty}"

    (( rc == 0 )) || return "${rc}"
    printf '%s' "${line}"

}
choose () {

    local prompt="${1:-Choose:}" pick="" i=0 attempt=0
    shift || true

    local -a items=( "$@" )
    (( ${#items[@]} )) || die "Missing items"

    eprint "${prompt}"

    for (( i=0; i<${#items[@]}; i++ )); do
        eprint "  $(( i + 1 ))) ${items[$i]}"
    done

    for (( attempt=0; attempt<3; attempt++ )); do

        pick="$(input "Enter number [1-${#items[@]}]: ")" || return $?

        [[ "${pick}" =~ ^[0-9]+$ ]] || { eprint "Invalid number"; continue; }
        (( pick >= 1 && pick <= ${#items[@]} )) || { eprint "Out of range"; continue; }

        printf '%s' "${items[$(( pick - 1 ))]}"
        return 0

    done

    die "Too many invalid attempts"

}
confirm () {

    local msg="${1:-Continue?}" def="${2:-N}" tries="${3:-3}" ans="" i=0
    local hint="[y/N]: "

    [[ "${tries}" =~ ^[0-9]+$ ]] || tries=3
    (( tries > 0 )) || tries=3

    case "${def,,}" in
        1|true|y|yes|on) hint="[Y/n]: " ;;
    esac

    for (( i=0; i<tries; i++ )); do

        ans="$(input "${msg} ${hint}" "${def}")" || return $?

        case "${ans,,}" in
            1|true|y|yes|on)  return 0 ;;
            0|false|n|no|off) return 1 ;;
        esac

        eprint "Invalid choice. Use: y/n, yes/no, on/off, 1/0, true/false"

    done

    die "Too many invalid attempts"

}

# ======>> Env <<======

use () {

    local mod="${1:-}" root="" path="" file=""

    [[ -n "${mod}" ]] || return 1
    [[ -z "${root}" && -n "${ENTRY_FILE:-}" ]] && root="$(dirname "${ENTRY_FILE}")"
    [[ -z "${root}" && -n "${SOURCE_DIR:-}" ]] && root="${SOURCE_DIR}"
    [[ -z "${root}" && -n "${ROOT_DIR:-}" ]] && root="${ROOT_DIR}/src"
    [[ -z "${root}" ]] && root="${PWD}"

    path="${mod//::/\/}"
    file="${root%/}/${path}.sh"

    [[ -f "${file}" ]] || file="${root%/}/${path}/mod.sh"
    [[ -f "${file}" ]] || return 1

    [[ -z "${__BUILTIN_USE_MAP__+x}" ]] && { declare -gA __BUILTIN_USE_MAP__=(); }
    [[ -n "${__BUILTIN_USE_MAP__[$file]+x}" ]] && return 0
    __BUILTIN_USE_MAP__["$file"]=1

    source "${file}"

}
has_env () {

    local key="${1:-}"

    [[ -n "${key}" ]] || return 1
    [[ "${key}" =~ ^[a-zA-Z_][a-zA-Z0-9_]*$ ]] || return 1
    [[ -n "${!key+x}" ]]

}
get_env () {

    local key="${1:-}" def="${2-}"

    [[ -n "${key}" ]] || { printf '%s' "${def}"; return 0; }
    [[ "${key}" =~ ^[a-zA-Z_][a-zA-Z0-9_]*$ ]] || { printf '%s' "${def}"; return 0; }

    if [[ -n "${!key+x}" ]]; then printf '%s' "${!key}"
    else printf '%s' "${def}"
    fi

}
set_env () {

    local key="${1:-}" value="${2-}"

    [[ -n "${key}" ]] || return 1
    [[ "${key}" =~ ^[a-zA-Z_][a-zA-Z0-9_]*$ ]] || return 1

    declare -gx "${key}=${value}"

}

# ======>> Process <<======

run () {

    (( $# )) || return 0
    "$@"

}
run_ok () {

    (( $# )) || return 1
    "$@" >/dev/null 2>&1

}
has () {

    [[ -n "${1:-}" ]] || return 1
    command -v -- "${1:-}" >/dev/null 2>&1

}
need () {

    local cmd="${1:-}"

    has "${cmd}" && return 0
    die "Missing command: ${cmd}"

}
has_any () {

    local x=""
    (( $# )) || return 1

    for x in "$@"; do
        has "${x}" && return 0
    done

    return 1

}
need_any () {

    local x=""
    (( $# )) || die "need_any: missing commands"

    for x in "$@"; do
        has "${x}" && return 0
    done

    die "Missing command from: $*"

}
has_all () {

    local x=""
    (( $# )) || return 1

    for x in "$@"; do
        has "${x}" || return 1
    done

    return 0

}
need_all () {

    local x="" miss=0
    (( $# )) || die "need_all: missing commands"

    for x in "$@"; do
        has "${x}" || { error "Missing command: ${x}"; miss=1; }
    done

    (( miss == 0 )) || die "Missing required commands"

}

# ======>> System <<======

is_linux () {

    [[ "${OSTYPE:-}" == linux* ]]

}
is_wsl () {

    is_linux || return 1

    [[ -n "${WSL_DISTRO_NAME:-}" || -n "${WSL_INTEROP:-}" ]] && return 0
    [[ -r /proc/sys/kernel/osrelease ]] && grep -qi 'microsoft' /proc/sys/kernel/osrelease && return 0

    [[ -r /proc/version ]] && grep -qi 'microsoft' /proc/version

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
is_gitbash () {

    [[ "${OSTYPE:-}" == msys* || "${MSYSTEM:-}" == MINGW* ]] || return 1
    [[ -n "${GitInstallRoot:-}" ]]

}
is_msys () {

    [[ "${OSTYPE:-}" == msys* || "${MSYSTEM:-}" == MINGW* || "${MSYSTEM:-}" == MSYS ]]

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

# ======>> Dir <<======

ssh_dir () {

    local home=""
    home="$(home_dir)" || return 1

    printf '%s\n' "${home}/.ssh"

}
bin_dir () {

    local home=""
    home="$(home_dir)" || return 1

    if is_windows; then
        printf '%s\n' "${home}/bin"
        return 0
    fi
    if [[ -n "${XDG_BIN_HOME:-}" ]]; then
        printf '%s\n' "${XDG_BIN_HOME%/}"
        return 0
    fi

    printf '%s\n' "${home}/.local/bin"

}
home_dir () {

    if [[ -n "${HOME:-}" ]]; then
        printf '%s\n' "${HOME}"
        return 0
    fi
    if is_windows && [[ -n "${USERPROFILE:-}" ]]; then
        printf '%s\n' "${USERPROFILE}"
        return 0
    fi

    return 1

}
tmp_dir () {

    if [[ -n "${TMPDIR:-}" ]]; then

        printf '%s\n' "${TMPDIR%/}"
        return 0

    fi
    if is_windows; then

        if [[ -n "${TMP:-}" ]]; then
            printf '%s\n' "${TMP%/}"
            return 0
        fi
        if [[ -n "${TEMP:-}" ]]; then
            printf '%s\n' "${TEMP%/}"
            return 0
        fi

    fi

    printf '%s\n' "/tmp"

}
config_dir () {

    local home=""
    home="$(home_dir)" || return 1

    if is_macos; then

        printf '%s\n' "${home}/Library/Application Support"
        return 0

    fi
    if is_windows; then

        if [[ -n "${APPDATA:-}" ]]; then
            printf '%s\n' "${APPDATA%/}"
            return 0
        fi

        printf '%s\n' "${home}/AppData/Roaming"
        return 0

    fi
    if [[ -n "${XDG_CONFIG_HOME:-}" ]]; then

        printf '%s\n' "${XDG_CONFIG_HOME%/}"
        return 0

    fi

    printf '%s\n' "${home}/.config"

}
cache_dir () {

    local home=""
    home="$(home_dir)" || return 1

    if is_macos; then

        printf '%s\n' "${home}/Library/Caches"
        return 0

    fi
    if is_windows; then

        if [[ -n "${LOCALAPPDATA:-}" ]]; then
            printf '%s\n' "${LOCALAPPDATA%/}"
            return 0
        fi

        printf '%s\n' "${home}/AppData/Local"
        return 0

    fi
    if [[ -n "${XDG_CACHE_HOME:-}" ]]; then

        printf '%s\n' "${XDG_CACHE_HOME%/}"
        return 0

    fi

    printf '%s\n' "${home}/.cache"

}
data_dir () {

    local home=""
    home="$(home_dir)" || return 1

    if is_macos; then

        printf '%s\n' "${home}/Library/Application Support"
        return 0

    fi
    if is_windows; then

        if [[ -n "${LOCALAPPDATA:-}" ]]; then

            printf '%s\n' "${LOCALAPPDATA%/}"
            return 0

        fi

        printf '%s\n' "${home}/AppData/Local"
        return 0

    fi
    if [[ -n "${XDG_DATA_HOME:-}" ]]; then

        printf '%s\n' "${XDG_DATA_HOME%/}"
        return 0

    fi

    printf '%s\n' "${home}/.local/share"

}
state_dir () {

    local home=""
    home="$(home_dir)" || return 1

    if is_macos; then

        printf '%s\n' "${home}/Library/Application Support"
        return 0

    fi
    if is_windows; then

        if [[ -n "${LOCALAPPDATA:-}" ]]; then
            printf '%s\n' "${LOCALAPPDATA%/}"
            return 0
        fi

        printf '%s\n' "${home}/AppData/Local"
        return 0

    fi
    if [[ -n "${XDG_STATE_HOME:-}" ]]; then

        printf '%s\n' "${XDG_STATE_HOME%/}"
        return 0

    fi

    printf '%s\n' "${home}/.local/state"

}
runtime_dir () {

    if [[ -n "${XDG_RUNTIME_DIR:-}" ]]; then
        printf '%s\n' "${XDG_RUNTIME_DIR%/}"
        return 0
    fi
    if is_windows; then
        tmp_dir
        return 0
    fi

    printf '%s\n' "/tmp"

}
desktop_dir () {

    local home=""
    home="$(home_dir)" || return 1

    printf '%s\n' "${home}/Desktop"

}
download_dir () {

    local home=""
    home="$(home_dir)" || return 1

    printf '%s\n' "${home}/Downloads"

}
documents_dir () {

    local home=""
    home="$(home_dir)" || return 1

    printf '%s\n' "${home}/Documents"

}

# ======>> File <<======

copy () {

    local src="${1:-}" dest="${2:-}"
    [[ -n "${src}" && -n "${dest}" ]] || return 1

    command cp -R -- "${src}" "${dest}"

}
move () {

    local src="${1:-}" dest="${2:-}"
    [[ -n "${src}" && -n "${dest}" ]] || return 1

    command mv -- "${src}" "${dest}"

}
remove () {

    (( $# )) || return 1
    command rm -rf -- "$@"

}
link () {

    local src="${1:-}" dest="${2:-}" dir=""
    [[ -n "${src}" && -n "${dest}" ]] || return 1

    dir="$(dir_name "${dest}")" || return 1
    command mkdir -p -- "${dir}" || return 1

    command ln -s -- "${src}" "${dest}"

}

is_path () {

    [[ -e "${1:-}" ]]

}
is_dir () {

    [[ -d "${1:-}" ]]

}
is_file () {

    [[ -f "${1:-}" ]]

}
is_link () {

    [[ -L "${1:-}" ]]

}
is_exec () {

    [[ -x "${1:-}" ]]

}
is_socket () {

    [[ -S "${1:-}" ]]

}
is_pipe () {

    [[ -p "${1:-}" ]]

}
is_block () {

    [[ -b "${1:-}" ]]

}

base_name () {

    local path="${1:-}"
    path="${path%/}"

    [[ -n "${path}" ]] || return 1
    [[ -n "${path}" ]] || path="/"

    if [[ "${path}" == "/" ]]; then
        printf '%s\n' "/"
        return 0
    fi

    printf '%s\n' "${path##*/}"

}
dir_name () {

    local path="${1:-}"
    path="${path%/}"

    [[ -n "${path}" ]] || return 1
    [[ -n "${path}" ]] || path="/"

    if [[ "${path}" != */* ]]; then
        printf '%s\n' "."
        return 0
    fi

    path="${path%/*}"
    [[ -n "${path}" ]] || path="/"

    printf '%s\n' "${path}"

}
parent_name () {

    local path="${1:-}" dir=""
    [[ -n "${path}" ]] || return 1

    dir="$(dir_name "${path}")" || return 1
    base_name "${dir}"

}
join_path () {

    local path="" part=""

    for part in "$@"; do

        [[ -n "${part}" ]] || continue

        if [[ -z "${path}" ]]; then

            if [[ "${part}" == "/" ]]; then path="/"
            else path="${part%/}"
            fi

        else

            if [[ "${path}" == "/" ]]; then path="/${part#/}"
            else path="${path%/}/${part#/}"
            fi

        fi

    done

    printf '%s' "${path}"

}

new_dir () {

    local path="${1:-}"
    [[ -n "${path}" ]] || return 1

    command mkdir -p -- "${path}"

}
new_file () {

    local path="${1:-}" dir=""
    [[ -n "${path}" ]] || return 1

    dir="$(dir_name "${path}")" || return 1
    command mkdir -p -- "${dir}" || return 1

    : > "${path}"

}
read_file () {

    local path="${1:-}"
    [[ -f "${path}" ]] || return 1

    cat -- "${path}"

}
write_file () {

    local path="${1:-}" data="${2-}" dir=""
    [[ -n "${path}" ]] || return 1

    dir="$(dir_name "${path}")" || return 1
    command mkdir -p -- "${dir}" || return 1

    printf '%s' "${data}" > "${path}"

}
append_file () {

    local path="${1:-}" data="${2-}" dir=""
    [[ -n "${path}" ]] || return 1

    dir="$(dir_name "${path}")" || return 1
    command mkdir -p -- "${dir}" || return 1

    printf '%s' "${data}" >> "${path}"

}

file_name () {

    local path="${1:-}" base=""
    base="${path##*/}"

    [[ -n "${path}" ]] || return 1
    [[ -n "${base}" && "${base}" != "/" ]] || return 1

    if [[ "${base}" == .* && "${base#*.}" != *.* ]]; then
        printf '%s\n' "${base}"
        return 0
    fi

    printf '%s\n' "${base%.*}"

}
file_ext () {

    local path="${1:-}" base=""
    base="${path##*/}"

    [[ -n "${path}" ]] || return 1
    [[ "${base}" == *.* ]] || return 1
    [[ "${base}" != .* ]] || { [[ "${base#*.}" == *.* ]] || return 1; }

    printf '%s\n' "${base##*.}"

}
file_size () {

    local path="${1:-}"
    [[ -f "${path}" ]] || return 1

    wc -c < "${path}" | tr -d '[:space:]'

}
file_lines () {

    local path="${1:-}"
    [[ -f "${path}" ]] || return 1

    wc -l < "${path}" | tr -d '[:space:]'

}

has_line () {

    local file="${1:-}" line="${2-}"

    [[ -f "${file}" && -n "${line}" ]] || return 1
    grep -Fqx -- "${line}" "${file}" 2>/dev/null

}
need_line () {

    local file="${1:-}" line="${2-}"

    has_line "${file}" "${line}" && return 0
    die "Missing line in file: ${file}"

}
line_position () {

    local file="${1:-}" line="${2-}" out=""

    [[ -f "${file}" && -n "${line}" ]] || return 1

    out="$(grep -n -F -x -- "${line}" "${file}" 2>/dev/null | head -n 1)" || return 1
    [[ -n "${out}" ]] || return 1

    printf '%s\n' "${out%%:*}"

}
add_line () {

    local file="${1:-}" line="${2-}"

    [[ -n "${file}" && -n "${line}" ]] || return 1

    if [[ ! -e "${file}" ]]; then
        printf '%s\n' "${line}" > "${file}" || return 1
        return 0
    fi

    printf '%s\n' "${line}" >> "${file}"

}
ensure_line () {

    local file="${1:-}" line="${2-}"

    [[ -n "${file}" && -n "${line}" ]] || return 1

    has_line "${file}" "${line}" && return 0
    add_line "${file}" "${line}"

}
remove_line () {

    local file="${1:-}" line="${2-}" tmp="" x="" removed=0

    [[ -f "${file}" && -n "${line}" ]] || return 1
    tmp="$(mktemp "${TMPDIR:-/tmp}/remove_line.XXXXXX")" || return 1

    while IFS= read -r x || [[ -n "${x}" ]]; do

        if [[ "${x}" == "${line}" ]]; then
            removed=1
            continue
        fi

        printf '%s\n' "${x}" >> "${tmp}" || { rm -f -- "${tmp}"; return 1; }

    done < "${file}"

    (( removed )) || { rm -f -- "${tmp}"; return 1; }
    command mv -- "${tmp}" "${file}"

}
replace_line () {

    local file="${1:-}" old="${2-}" new="${3-}" tmp="" done=0 x=""

    [[ -f "${file}" && -n "${old}" ]] || return 1
    tmp="$(mktemp "${TMPDIR:-/tmp}/replace_line.XXXXXX")" || return 1

    while IFS= read -r x || [[ -n "${x}" ]]; do

        if (( ! done )) && [[ "${x}" == "${old}" ]]; then
            printf '%s\n' "${new}" >> "${tmp}" || { rm -f -- "${tmp}"; return 1; }
            done=1
            continue
        fi

        printf '%s\n' "${x}" >> "${tmp}" || { rm -f -- "${tmp}"; return 1; }

    done < "${file}"

    (( done )) || { rm -f -- "${tmp}"; return 1; }
    command mv -- "${tmp}" "${file}"

}
replace_all_lines () {

    local file="${1:-}" old="${2-}" new="${3-}" tmp="" x="" done=0

    [[ -f "${file}" && -n "${old}" ]] || return 1
    tmp="$(mktemp "${TMPDIR:-/tmp}/replace_all_lines.XXXXXX")" || return 1

    while IFS= read -r x || [[ -n "${x}" ]]; do

        if [[ "${x}" == "${old}" ]]; then
            printf '%s\n' "${new}" >> "${tmp}" || { rm -f -- "${tmp}"; return 1; }
            done=1
            continue
        fi

        printf '%s\n' "${x}" >> "${tmp}" || { rm -f -- "${tmp}"; return 1; }

    done < "${file}"

    (( done )) || { rm -f -- "${tmp}"; return 1; }
    command mv -- "${tmp}" "${file}"

}

# ======>> Lifecycle <<======

run_hooks () {

    local name="${1:-}" fn="" i=0
    [[ -n "${name}" ]] || return 1

    declare -n ref="${name}"

    for (( i=${#ref[@]}-1; i>=0; i-- )); do

        fn="${ref[$i]}"
        [[ -n "${fn}" ]] || continue

        if declare -F -- "${fn}" >/dev/null 2>&1; then "${fn}" || true
        else bash -c "${fn}" || true
        fi

    done

}
on_exit () {

    [[ -v __ON_EXIT_HOOKS__ ]] || declare -ag __ON_EXIT_HOOKS__=()

    local fn="${1:-}"
    [[ -n "${fn}" ]] || return 1

    __ON_EXIT_HOOKS__+=( "${fn}" )
    trap 'run_hooks __ON_EXIT_HOOKS__' EXIT

}
on_err () {

    [[ -v __ON_ERR_HOOKS__ ]] || declare -ag __ON_ERR_HOOKS__=()

    local fn="${1:-}"
    [[ -n "${fn}" ]] || return 1

    __ON_ERR_HOOKS__+=( "${fn}" )
    trap 'run_hooks __ON_ERR_HOOKS__' ERR

}
on_int () {

    [[ -v __ON_INT_HOOKS__ ]] || declare -ag __ON_INT_HOOKS__=()

    local fn="${1:-}"
    [[ -n "${fn}" ]] || return 1

    __ON_INT_HOOKS__+=( "${fn}" )
    trap 'run_hooks __ON_INT_HOOKS__' INT

}
on_term () {

    [[ -v __ON_TERM_HOOKS__ ]] || declare -ag __ON_TERM_HOOKS__=()

    local fn="${1:-}"
    [[ -n "${fn}" ]] || return 1

    __ON_TERM_HOOKS__+=( "${fn}" )
    trap 'run_hooks __ON_TERM_HOOKS__' TERM

}
on_hook () {

    on_exit "$@"
    on_err  "$@"
    on_int  "$@"
    on_term "$@"

}
cleanup_tmps () {

    [[ -v __TMP_FILES__ ]] || return 0

    local file=""

    for file in "${__TMP_FILES__[@]}"; do
        [[ -n "${file:-}" && ( -e "${file}" || -L "${file}" ) ]] || continue
        rm -rf -- "${file}" 2>/dev/null || true
    done

    __TMP_FILES__=()

}
tmp_file () {

    [[ -v __TMP_FILES__  ]] || declare -ag __TMP_FILES__=()
    [[ -v __TMP_HOOKED__ ]] || declare -g  __TMP_HOOKED__=0

    local ref="${1:-}" path="${2:-/tmp}" __mktmp_file__=""

    [[ -n "${ref}" ]] || die "Missing output variable name"
    [[ -d "${path}" ]] || { path="$(dirname -- "${path}")" || die "Failed to detect dirname of: ${path}"; }

    __mktmp_file__="$(mktemp "${path}/.out.tmp.XXXXXX")" || die "Failed to create temp file in dir: ${path}"
    __TMP_FILES__+=( "${__mktmp_file__}" )

    if (( ! __TMP_HOOKED__ )); then
        on_hook cleanup_tmps
        __TMP_HOOKED__=1
    fi
    if [[ -z "${ref}" ]]; then
        printf '%s\n' "${__mktmp_file__}"
        return 0
    fi

    local -n out_ref="${ref}"
    out_ref="${__mktmp_file__}"

}
assert () {

    local msg="${1:-assert failed}"
    shift || true

    (( $# )) || { error "${msg}"; return 1; }

    "$@" && return 0

    error "${msg}"
    return 1

}
assert_eq () {

    local want="${1-}" got="${2-}" msg="${3:-}"

    [[ -n "${msg}" ]] || msg="assert_eq failed: expected '${want}', got '${got}'"
    [[ "${want}" == "${got}" ]] && return 0

    error "${msg}"
    return 1

}
assert_ne () {

    local left="${1-}" right="${2-}" msg="${3:-}"

    [[ -n "${msg}" ]] || msg="assert_ne failed: both are '${left}'"
    [[ "${left}" != "${right}" ]] && return 0

    error "${msg}"
    return 1

}

# ======>> Arg <<======

get () {

    local long="${1:-}" short="${2:-}" position="${3:-}" def="${4-}" ref="${5-}"
    local x="" next="" alt="" out="" found=0 i=0 pos=0
    shift 5 || true

    [[ -z "${long}"  || "${long}"  == --* ]] || long=""
    [[ -z "${short}" || "${short}" == -?  ]] || short=""
    [[ "${position}" =~ ^[1-9][0-9]*$ ]] || position=0
    [[ -n "${long}" ]] && alt="-${long#--}"

    local -a rest=()

    for (( i=1; i<=$#; i++ )); do

        x="${!i}"

        if [[ "${x}" == "--" ]]; then

            for (( ; i<=$#; i++ )); do
                rest+=( "${!i}" )
            done

            break

        fi

        if (( ! found )) && [[ -n "${long}" && "${x}" == "${long}"=* ]]; then
            out="${x#*=}"
            found=1
            continue
        fi

        if (( ! found )) && [[ -n "${alt}" && "${x}" == "${alt}"=* ]]; then
            out="${x#*=}"
            found=1
            continue
        fi

        if (( ! found )) && {
            { [[ -n "${long}"  && "${x}" == "${long}"  ]]; } || \
            { [[ -n "${short}" && "${x}" == "${short}" ]]; } || \
            { [[ -n "${alt}"   && "${x}" == "${alt}"   ]]; }
        }; then

            if (( i < $# )); then

                next="${!(( i + 1 ))}"

                if [[ "${next}" == "--" ]]; then
                    out="true"
                    found=1
                    continue
                fi

                if [[ "${next}" =~ ^[+-]?([0-9]+([.][0-9]+)?|[.][0-9]+)$ ]]; then
                    out="${next}"
                    found=1
                    (( i++ ))
                    continue
                fi

                if [[ "${next}" != --* && "${next}" != -?* ]]; then
                    out="${next}"
                    found=1
                    (( i++ ))
                    continue
                fi

            fi

            out="true"
            found=1
            continue

        fi

        pos=$(( pos + 1 ))

        if (( ! found && position > 0 && pos == position )); then

            if [[ "${x}" != --* && "${x}" != -?* ]] || [[ "${x}" =~ ^[+-]?([0-9]+([.][0-9]+)?|[.][0-9]+)$ ]]; then
                out="${x}"
                found=1
                continue
            fi

        fi

        rest+=( "${x}" )

    done

    if [[ -n "${ref}" ]]; then
        declare -n ref_out="${ref}"
        ref_out=( "${rest[@]}" )
    fi

    (( found )) && printf '%s' "${out}" || printf '%s' "${def}"

}
get_bool () {

    local long="${1:-}" short="${2:-}" ref="${3:-}"
    shift 3 || true

    local v=""
    v="$(get "${long}" "${short}" 0 0 "${ref}" "$@")" || return 1

    case "${v,,}" in
        1|true|yes|y|on) printf '%s' 1 ;;
        *)               printf '%s' 0 ;;
    esac

}
get_flag () {

    local long="${1:-}" short="${2:-}" def="${3:-}" ref="${4:-}"
    shift 4 || true

    get "${long}" "${short}" 0 "${def}" "${ref}" "$@"

}
get_position () {

    local position="${1:-}" def="${2:-}" ref="${3:-}"
    shift 3 || true

    get "" "" "${position}" "${def}" "${ref}" "$@"

}
has_flag () {

    local long="${1:-}" short="${2:-}" ref="${3:-}" v=""
    shift 3 || true

    v="$(get "${long}" "${short}" 0 "__MISSING_9A7F1C__" "${ref}" "$@")" || return 1
    [[ "${v}" != "__MISSING_9A7F1C__" ]]

}
has_value () {

    local long="${1:-}" short="${2:-}" position="${3:-0}" ref="${4:-}" v=""
    shift 4 || true

    v="$(get "${long}" "${short}" "${position}" "__MISSING_9A7F1C__" "${ref}" "$@")" || return 1
    [[ "${v}" != "__MISSING_9A7F1C__" ]]

}
need_flag () {

    local long="${1:-}" short="${2:-}" def="${3-}" ref="${4:-}" v=""
    shift 4 || true

    v="$(get_flag "${long}" "${short}" "__GET_MISSING_9A7F1C__" "${ref}" "$@")" || return 1
    [[ "${v}" != "__GET_MISSING_9A7F1C__" ]] && { printf '%s' "${v}"; return 0; }

    if [[ -n "${long}" && -n "${short}" ]]; then die "Missing required flag: ${long} | ${short}"
    elif [[ -n "${long}" ]]; then die "Missing required flag: ${long}"
    elif [[ -n "${short}" ]]; then die "Missing required flag: ${short}"
    fi

    die "${def:-Missing required flag}"

}
