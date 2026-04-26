# shellcheck shell=bash

path::has () {

    command -v "${1:-}" >/dev/null 2>&1

}
path::valid () {

    local p="${1:-}"

    [[ -n "${p}" ]] || return 1
    [[ "${p}" != *$'\n'* && "${p}" != *$'\r'* ]] || return 1

    return 0

}
path::exists () {

    local p="${1:-}"

    path::valid "${p}" || return 1
    [[ -e "${p}" || -L "${p}" ]]

}
path::missing () {

    local p="${1:-}"

    path::valid "${p}" || return 1
    [[ ! -e "${p}" && ! -L "${p}" ]]

}
path::empty () {

    local p="${1:-}" entry=""

    path::valid "${p}" || return 1
    [[ -e "${p}" || -L "${p}" ]] || return 1

    if [[ -d "${p}" ]]; then

        for entry in "${p}"/* "${p}"/.[!.]* "${p}"/..?*; do
            [[ -e "${entry}" || -L "${entry}" ]] && return 1
        done

        return 0

    fi

    [[ ! -s "${p}" ]]

}
path::filled () {

    path::empty "$@" && return 1
    [[ -e "${1:-}" || -L "${1:-}" ]]

}
path::is_abs () {

    local p="${1:-}"

    [[ -n "${p}" ]] || return 1

    [[ "${p}" == /* ]] && return 0
    [[ "${p}" == \\* ]] && return 0
    [[ "${p}" =~ ^[A-Za-z]:[\\/] ]] && return 0

    return 1

}
path::is_rel () {

    path::is_abs "${1:-}" && return 1
    [[ -n "${1:-}" ]] || return 1

    return 0

}
path::is_root () {

    local p="${1:-}"

    [[ -n "${p}" ]] || return 1

    [[ "${p}" == "/" ]] && return 0
    [[ "${p}" == "\\" ]] && return 0
    [[ "${p}" =~ ^[A-Za-z]:[\\/]?$ ]] && return 0

    return 1

}
path::is_unc () {

    local p="${1:-}"
    [[ "${p}" == //* || "${p}" == \\\\* ]]

}
path::has_drive () {

    local p="${1:-}"
    [[ "${p}" =~ ^[A-Za-z]: ]]

}

path::slashify () {

    local p="${1:-}"

    path::valid "${p}" || return 1
    printf '%s' "${p//\\//}"

}
path::posix () {

    local p="${1:-}" v="" letter=""

    path::valid "${p}" || return 1

    if path::has cygpath; then

        v="$(cygpath -u -- "${p}" 2>/dev/null || true)"
        [[ -n "${v}" ]] && { printf '%s' "${v}"; return 0; }

    fi

    p="${p//\\//}"

    if [[ "${p}" =~ ^([A-Za-z]):(/?)(.*)$ ]]; then

        letter="${BASH_REMATCH[1]}"
        letter="${letter,,}"

        if sys::is_wsl; then printf '/mnt/%s' "${letter}"
        else printf '/%s' "${letter}"
        fi

        [[ -n "${BASH_REMATCH[3]}" ]] && printf '/%s' "${BASH_REMATCH[3]}"
        return 0

    fi

    printf '%s' "${p}"

}
path::win () {

    local p="${1:-}" v="" letter="" rest=""

    path::valid "${p}" || return 1

    p="${p//\\//}"

    if [[ "${p}" =~ ^/mnt/([A-Za-z])(/.*)?$ ]]; then

        letter="${BASH_REMATCH[1]}"
        letter="${letter^^}"
        rest="${BASH_REMATCH[2]:-/}"
        rest="${rest//\//\\}"

        printf '%s:%s' "${letter}" "${rest}"
        return 0

    fi
    if [[ "${p}" =~ ^/([A-Za-z])(/.*)?$ ]]; then

        letter="${BASH_REMATCH[1]}"
        letter="${letter^^}"
        rest="${BASH_REMATCH[2]:-/}"
        rest="${rest//\//\\}"

        printf '%s:%s' "${letter}" "${rest}"
        return 0

    fi
    if [[ "${p}" =~ ^([A-Za-z]):(.*)$ ]]; then

        letter="${BASH_REMATCH[1]}"
        rest="${BASH_REMATCH[2]}"
        rest="${rest//\//\\}"

        printf '%s:%s' "${letter^^}" "${rest}"
        return 0

    fi
    if path::has cygpath; then

        v="$(cygpath -w -- "${p}" 2>/dev/null || true)"
        [[ -n "${v}" ]] && { printf '%s' "${v}"; return 0; }

    fi

    printf '%s' "${p//\//\\}"

}
path::join () {

    local acc="" seg="" sep="/" first=1

    (( $# > 0 )) || return 1

    for seg in "$@"; do

        [[ -n "${seg}" ]] || continue
        seg="${seg//\\//}"

        if (( first )); then acc="${seg}"; first=0
        elif path::is_abs "${seg}"; then acc="${seg}"
        elif [[ "${acc}" == */ || "${acc}" == *\\ ]]; then acc="${acc}${seg}"
        else acc="${acc}${sep}${seg}"
        fi

    done

    [[ -n "${acc}" ]] || acc="."
    path::norm "${acc}"

}
path::norm () {

    local p="${1:-}" prefix="" first="" head=""
    local -a parts=()
    local -a out=()

    path::valid "${p}" || return 1

    p="${p//\\//}"
    [[ "${p}" =~ ^/+$ ]] && { printf '/'; return 0; }

    if [[ "${p}" =~ ^([A-Za-z]:)(/?)(.*)$ ]]; then

        prefix="${BASH_REMATCH[1]}${BASH_REMATCH[2]}"
        p="${BASH_REMATCH[3]}"

    elif [[ "${p}" == //* ]]; then

        p="${p#//}"
        head="${p%%/*}"
        p="${p#"${head}"}"
        p="${p#/}"
        prefix="//${head}/"

    elif [[ "${p}" == /* ]]; then

        prefix="/"
        p="${p#/}"

    fi

    while [[ "${p}" == *//* ]]; do
        p="${p//\/\//\/}"
    done

    [[ -z "${p}" ]] || IFS='/' read -r -a parts <<< "${p}"

    for first in "${parts[@]}"; do

        case "${first}" in
            ""|.)
                continue
            ;;
            ..)
                if (( ${#out[@]} > 0 )) && [[ "${out[-1]}" != ".." ]]; then unset 'out[-1]'
                elif [[ -z "${prefix}" ]]; then out+=( ".." )
                fi
            ;;
            *)
                out+=( "${first}" )
            ;;
        esac

    done

    if (( ${#out[@]} == 0 )); then
        if [[ -n "${prefix}" ]]; then printf '%s' "${prefix%/}/"
        else printf '%s' "."
        fi
        return 0
    fi

    head="$( IFS='/'; printf '%s' "${out[*]}" )"

    if [[ -n "${prefix}" ]]; then printf '%s%s' "${prefix}" "${head}"
    else printf '%s' "${head}"
    fi

}
path::resolve () {

    local p="${1:-}" parent="" base="" v=""

    path::valid "${p}" || return 1

    if path::has realpath; then

        v="$(realpath -m -- "${p}" 2>/dev/null)" || true
        [[ -n "${v}" ]] && { printf '%s' "${v}"; return 0; }

        v="$(realpath -- "${p}" 2>/dev/null)" || true
        [[ -n "${v}" ]] && { printf '%s' "${v}"; return 0; }

    fi
    if path::has readlink; then

        v="$(readlink -f -- "${p}" 2>/dev/null)" || true
        [[ -n "${v}" ]] && { printf '%s' "${v}"; return 0; }

    fi

    if [[ -d "${p}" ]]; then
        v="$( cd -- "${p}" 2>/dev/null && pwd -P 2>/dev/null )" && { printf '%s' "${v}"; return 0; }
    fi

    parent="$(path::dirname "${p}")"
    base="$(path::basename "${p}")"

    if [[ -d "${parent}" ]]; then
        v="$( cd -- "${parent}" 2>/dev/null && pwd -P 2>/dev/null )" && {
            [[ -n "${base}" && "${base}" != "/" ]] && printf '%s/%s' "${v}" "${base}" || printf '%s' "${v}"
            return 0
        }
    fi

    path::abs "${p}"

}

path::cwd () {

    pwd 2>/dev/null

}
path::pwd () {

    pwd -P 2>/dev/null

}
path::drive () {

    local p="${1:-}"

    [[ "${p}" =~ ^([A-Za-z]):.* ]] || return 1
    printf '%s:' "${BASH_REMATCH[1]}"

}
path::abs () {

    local p="${1:-}"

    path::valid "${p}" || return 1

    if path::is_abs "${p}"; then path::norm "${p}"
    else path::norm "$(pwd 2>/dev/null || printf '.')/${p}"
    fi

}
path::rel () {

    local target="${1:-}" base="${2:-}" t_abs="" b_abs="" v=""
    local i=0 max=0 up=0 common=0
    local -a tparts=()
    local -a bparts=()

    path::valid "${target}" || return 1
    [[ -n "${base}" ]] || base="$(pwd 2>/dev/null || printf '.')"

    if [[ "${target}" == ?:* && "${base}" == ?:* && "${target:0:1,,}" != "${base:0:1,,}" ]]; then
        printf '%s' "${target//\\//}"
        return 0
    fi

    t_abs="$(path::abs "${target}")" || return 1
    b_abs="$(path::abs "${base}")" || return 1

    t_abs="${t_abs//\\//}"
    b_abs="${b_abs//\\//}"

    if [[ "${t_abs}" =~ ^[A-Za-z]: && "${b_abs}" =~ ^[A-Za-z]: && "${t_abs:0:1,,}" != "${b_abs:0:1,,}" ]]; then
        printf '%s' "${t_abs}"
        return 0
    fi

    IFS='/' read -r -a tparts <<< "${t_abs#/}"
    IFS='/' read -r -a bparts <<< "${b_abs#/}"

    max=${#tparts[@]}
    (( ${#bparts[@]} < max )) && max=${#bparts[@]}

    for (( i=0; i<max; i++ )); do
        [[ "${tparts[$i]}" == "${bparts[$i]}" ]] || break
        common=$(( i + 1 ))
    done

    up=$(( ${#bparts[@]} - common ))

    while (( up > 0 )); do
        v+="../"
        up=$(( up - 1 ))
    done

    for (( i=common; i<${#tparts[@]}; i++ )); do
        v+="${tparts[$i]}/"
    done

    v="${v%/}"
    [[ -n "${v}" ]] || v="."

    printf '%s' "${v}"

}
path::expand () {

    local p="${1:-}" home="" user="" head=""

    [[ -n "${p}" ]] || return 1

    head="${p:0:1}"
    [[ "${head}" == "~" ]] || { printf '%s' "${p}"; return 0; }

    if [[ "${p}" == "~" ]]; then

        home="${HOME:-}"
        [[ -n "${home}" ]] || home="$(sys::uhome 2>/dev/null || true)"
        [[ -n "${home}" ]] || return 1

        printf '%s' "${home}"
        return 0

    fi
    if [[ "${p:0:1}" == "~" && "${p:1:1}" == "/" ]]; then

        home="${HOME:-}"
        [[ -n "${home}" ]] || home="$(sys::uhome 2>/dev/null || true)"
        [[ -n "${home}" ]] || return 1

        printf '%s%s' "${home}" "${p:1}"
        return 0

    fi

    user="${p:1}"
    user="${user%%/*}"

    [[ -n "${user}" ]] || return 1
    [[ "${user}" =~ ^[A-Za-z0-9._-]+$ ]] || return 1

    if path::has getent; then home="$(getent passwd "${user}" 2>/dev/null | awk -F: 'NR==1 {print $6}')"
    elif sys::is_macos && path::has dscl; then home="$(dscl . -read "/Users/${user}" NFSHomeDirectory 2>/dev/null | awk 'NR==1 {print $2}')"
    else return 1
    fi

    [[ -n "${home}" ]] || return 1

    if [[ "${p}" == "~${user}" ]]; then printf '%s' "${home}"
    else printf '%s%s' "${home}" "${p:$(( 1 + ${#user} ))}"
    fi

}

path::parts () {

    local p="${1:-}" prefix="" head=""
    local -a parts=()

    path::valid "${p}" || return 1
    p="${p//\\//}"

    if [[ "${p}" =~ ^([A-Za-z]):(/?)(.*)$ ]]; then

        prefix="${BASH_REMATCH[1]}:${BASH_REMATCH[2]}"
        p="${BASH_REMATCH[3]}"

    elif [[ "${p}" == //* ]]; then

        p="${p#//}"
        head="${p%%/*}"
        p="${p#"${head}"}"
        p="${p#/}"
        prefix="//${head}/"

    elif [[ "${p}" == /* ]]; then

        prefix="/"
        p="${p#/}"

    fi

    [[ -n "${prefix}" ]] && printf '%s\n' "${prefix}"

    while [[ "${p}" == *//* ]]; do p="${p//\/\//\/}"; done

    [[ -z "${p}" ]] && return 0

    IFS='/' read -r -a parts <<< "${p}"

    for head in "${parts[@]}"; do
        [[ -n "${head}" ]] && printf '%s\n' "${head}"
    done

}
path::depth () {

    local p="${1:-}" n=0

    path::valid "${p}" || return 1

    while IFS= read -r _; do
        n=$(( n + 1 ))
    done < <(path::parts "${p}")

    printf '%s\n' "${n}"

}
path::common () {

    local first="" cur="" i=0
    local -a a=()
    local -a b=()
    local -a out=()

    (( $# > 0 )) || return 1

    first="$(path::abs "${1}")" || return 1
    shift || true

    IFS='/' read -r -a a <<< "${first#/}"

    for cur in "$@"; do

        cur="$(path::abs "${cur}")" || return 1
        IFS='/' read -r -a b <<< "${cur#/}"

        out=()
        i=0

        while (( i < ${#a[@]} && i < ${#b[@]} )); do
            [[ "${a[$i]}" == "${b[$i]}" ]] || break
            out+=( "${a[$i]}" )
            i=$(( i + 1 ))
        done

        a=( "${out[@]}" )

    done

    if (( ${#a[@]} == 0 )); then printf '/'
    else printf '/%s' "$( IFS='/'; printf '%s' "${a[*]}" )"
    fi

}
path::dirname () {

    local p="${1:-}" dir=""

    path::valid "${p}" || return 1
    p="${p//\\//}"

    if [[ "${p}" != */* ]]; then printf '.'; return 0; fi

    dir="${p%/*}"
    [[ -n "${dir}" ]] || dir="/"

    printf '%s' "${dir}"

}
path::basename () {

    local p="${1:-}"

    path::valid "${p}" || return 1
    p="${p//\\//}"

    while [[ "${p}" == */ && ${#p} -gt 1 ]]; do
        p="${p%/}"
    done

    printf '%s' "${p##*/}"

}
path::stem () {

    local path_base="" path_stem=""

    path_base="$(path::basename "${1:-}")" || return 1

    if [[ "${path_base}" != *.* || "${path_base}" == .* && "${path_base}" != *.*.* ]]; then printf '%s' "${path_base}"
    else path_stem="${path_base%.*}"; printf '%s' "${path_stem}"
    fi

}
path::ext () {

    local path_base=""

    path_base="$(path::basename "${1:-}")" || return 1

    if [[ "${path_base}" != *.* || "${path_base}" == .* && "${path_base}" != *.*.* ]]; then printf ''
    else printf '%s' "${path_base##*.}"
    fi

}
path::dotext () {

    local path_base=""

    path_base="$(path::basename "${1:-}")" || return 1

    if [[ "${path_base}" != *.* || "${path_base}" == .* && "${path_base}" != *.*.* ]]; then printf ''
    else printf '.%s' "${path_base##*.}"
    fi

}
path::chext () {

    local p="${1:-}" ext="${2:-}" dir="" stem=""

    path::valid "${p}" || return 1

    dir="$(path::dirname "${p}")"
    stem="$(path::stem "${p}")"

    [[ -n "${ext}" && "${ext}" != .* ]] && ext=".${ext}"

    if [[ "${dir}" == "." && "${p}" != ./* ]]; then printf '%s%s' "${stem}" "${ext}"
    else printf '%s/%s%s' "${dir%/}" "${stem}" "${ext}"
    fi

}
path::chname () {

    local p="${1:-}" name="${2:-}" dir=""

    path::valid "${p}" || return 1
    [[ -n "${name}" ]] || return 1

    dir="$(path::dirname "${p}")"

    if [[ "${dir}" == "." && "${p}" != ./* ]]; then printf '%s' "${name}"
    else printf '%s/%s' "${dir%/}" "${name}"
    fi

}
path::chstem () {

    local p="${1:-}" stem="${2:-}" dir="" ext=""

    path::valid "${p}" || return 1
    [[ -n "${stem}" ]] || return 1

    dir="$(path::dirname "${p}")"
    ext="$(path::dotext "${p}")"

    if [[ "${dir}" == "." && "${p}" != ./* ]]; then printf '%s%s' "${stem}" "${ext}"
    else printf '%s/%s%s' "${dir%/}" "${stem}" "${ext}"
    fi

}

path::is_same () {

    local pa="${1:-}" pb="${2:-}" x="" y=""

    path::valid "${pa}" || return 1
    path::valid "${pb}" || return 1

    [[ -e "${pa}" || -L "${pa}" ]] || return 1
    [[ -e "${pb}" || -L "${pb}" ]] || return 1

    [[ "${pa}" -ef "${pb}" ]] && return 0

    x="$(path::resolve "${pa}" 2>/dev/null || true)"
    y="$(path::resolve "${pb}" 2>/dev/null || true)"

    [[ -n "${x}" && -n "${y}" && "${x}" == "${y}" ]]

}
path::is_under () {

    local child="${1:-}" parent="${2:-}" x="" y=""

    path::valid "${child}" || return 1
    path::valid "${parent}" || return 1

    x="$(path::abs "${child}")" || return 1
    y="$(path::abs "${parent}")" || return 1

    x="${x%/}/"
    y="${y%/}/"

    [[ "${x}" == "${y}"* && "${x}" != "${y}" ]]

}
path::is_parent () {

    local parent="${1:-}" child="${2:-}"
    path::is_under "${child}" "${parent}"

}
path::is_file () {

    local p="${1:-}"

    path::valid "${p}" || return 1
    [[ -f "${p}" ]]

}
path::is_dir () {

    local p="${1:-}"

    path::valid "${p}" || return 1
    [[ -d "${p}" ]]

}
path::is_link () {

    local p="${1:-}"

    path::valid "${p}" || return 1
    [[ -L "${p}" ]]

}
path::is_pipe () {

    local p="${1:-}"

    path::valid "${p}" || return 1
    [[ -p "${p}" ]]

}
path::is_socket () {

    local p="${1:-}"

    path::valid "${p}" || return 1
    [[ -S "${p}" ]]

}
path::is_block () {

    local p="${1:-}"

    path::valid "${p}" || return 1
    [[ -b "${p}" ]]

}
path::is_char () {

    local p="${1:-}"

    path::valid "${p}" || return 1
    [[ -c "${p}" ]]

}
path::readable () {

    local p="${1:-}"

    path::valid "${p}" || return 1
    [[ -r "${p}" ]]

}
path::writable () {

    local p="${1:-}"

    path::valid "${p}" || return 1
    [[ -w "${p}" ]]

}
path::executable () {

    local p="${1:-}"

    path::valid "${p}" || return 1
    [[ -x "${p}" ]]

}

path::type () {

    local p="${1:-}"

    path::valid "${p}" || return 1

    [[ -L "${p}" ]] && { printf 'link';   return 0; }
    [[ -d "${p}" ]] && { printf 'dir';    return 0; }
    [[ -f "${p}" ]] && { printf 'file';   return 0; }
    [[ -p "${p}" ]] && { printf 'pipe';   return 0; }
    [[ -S "${p}" ]] && { printf 'socket'; return 0; }
    [[ -b "${p}" ]] && { printf 'block';  return 0; }
    [[ -c "${p}" ]] && { printf 'char';   return 0; }
    [[ -e "${p}" ]] && { printf 'other';  return 0; }

    return 1

}
path::size () {

    local p="${1:-}" v=""

    path::valid "${p}" || return 1
    [[ -e "${p}" || -L "${p}" ]] || return 1

    if [[ -f "${p}" ]] && path::has stat; then

        v="$(stat -c '%s' -- "${p}" 2>/dev/null || true)"
        [[ "${v}" =~ ^[0-9]+$ ]] && { printf '%s\n' "${v}"; return 0; }

        v="$(stat -f '%z' -- "${p}" 2>/dev/null || true)"
        [[ "${v}" =~ ^[0-9]+$ ]] && { printf '%s\n' "${v}"; return 0; }

    fi
    if path::has wc && [[ -f "${p}" ]]; then

        v="$(wc -c < "${p}" 2>/dev/null | tr -d '[:space:]' || true)"
        [[ "${v}" =~ ^[0-9]+$ ]] && { printf '%s\n' "${v}"; return 0; }

    fi
    if [[ -d "${p}" ]] && path::has du; then

        v="$(du -sk -- "${p}" 2>/dev/null | awk 'NR==1 {print $1}' | head -n 1)"
        [[ "${v}" =~ ^[0-9]+$ ]] && { printf '%s\n' "$(( v * 1024 ))"; return 0; }

    fi

    return 1

}
path::mtime () {

    local p="${1:-}" v=""

    path::valid "${p}" || return 1
    path::has stat || return 1

    [[ -e "${p}" || -L "${p}" ]] || return 1

    v="$(stat -c '%Y' -- "${p}" 2>/dev/null || true)"
    [[ "${v}" =~ ^[0-9]+$ ]] && { printf '%s\n' "${v}"; return 0; }

    v="$(stat -f '%m' -- "${p}" 2>/dev/null || true)"
    [[ "${v}" =~ ^[0-9]+$ ]] && { printf '%s\n' "${v}"; return 0; }

    return 1

}
path::atime () {

    local p="${1:-}" v=""

    path::valid "${p}" || return 1
    path::has stat || return 1

    [[ -e "${p}" || -L "${p}" ]] || return 1

    v="$(stat -c '%X' -- "${p}" 2>/dev/null || true)"
    [[ "${v}" =~ ^[0-9]+$ ]] && { printf '%s\n' "${v}"; return 0; }

    v="$(stat -f '%a' -- "${p}" 2>/dev/null || true)"
    [[ "${v}" =~ ^[0-9]+$ ]] && { printf '%s\n' "${v}"; return 0; }

    return 1

}
path::ctime () {

    local p="${1:-}" v=""

    path::valid "${p}" || return 1
    path::has stat || return 1

    [[ -e "${p}" || -L "${p}" ]] || return 1

    v="$(stat -c '%Z' -- "${p}" 2>/dev/null || true)"
    [[ "${v}" =~ ^[0-9]+$ ]] && { printf '%s\n' "${v}"; return 0; }

    v="$(stat -f '%c' -- "${p}" 2>/dev/null || true)"
    [[ "${v}" =~ ^[0-9]+$ ]] && { printf '%s\n' "${v}"; return 0; }

    return 1

}
path::age () {

    local p="${1:-}" m="" now=""

    m="$(path::mtime "${p}" 2>/dev/null || true)" || return 1
    [[ "${m}" =~ ^[0-9]+$ ]] || return 1

    now="$(date +%s 2>/dev/null || true)"
    [[ "${now}" =~ ^[0-9]+$ ]] || return 1

    (( now >= m )) || return 1
    printf '%s\n' "$(( now - m ))"

}
path::owner () {

    local p="${1:-}" v=""

    path::valid "${p}" || return 1
    path::has stat || return 1

    [[ -e "${p}" || -L "${p}" ]] || return 1

    v="$(stat -c '%U' -- "${p}" 2>/dev/null || true)"
    [[ -n "${v}" && "${v}" != "UNKNOWN" ]] && { printf '%s\n' "${v}"; return 0; }

    v="$(stat -f '%Su' -- "${p}" 2>/dev/null || true)"
    [[ -n "${v}" ]] && { printf '%s\n' "${v}"; return 0; }

    return 1

}
path::group () {

    local p="${1:-}" v=""

    path::valid "${p}" || return 1
    path::has stat || return 1

    [[ -e "${p}" || -L "${p}" ]] || return 1

    v="$(stat -c '%G' -- "${p}" 2>/dev/null || true)"
    [[ -n "${v}" && "${v}" != "UNKNOWN" ]] && { printf '%s\n' "${v}"; return 0; }

    v="$(stat -f '%Sg' -- "${p}" 2>/dev/null || true)"
    [[ -n "${v}" ]] && { printf '%s\n' "${v}"; return 0; }

    return 1

}
path::mode () {

    local p="${1:-}" v=""

    path::valid "${p}" || return 1
    path::has stat || return 1

    [[ -e "${p}" || -L "${p}" ]] || return 1

    v="$(stat -c '%a' -- "${p}" 2>/dev/null || true)"
    [[ "${v}" =~ ^[0-7]+$ ]] && { printf '%s\n' "${v}"; return 0; }

    v="$(stat -f '%Lp' "${p}" 2>/dev/null || true)"
    [[ "${v}" =~ ^[0-7]+$ ]] && { printf '%s\n' "${v: -4}"; return 0; }

    v="$(stat -f '%OLp' "${p}" 2>/dev/null || true)"
    [[ "${v}" =~ ^[0-7]+$ ]] && { printf '%s\n' "${v: -4}"; return 0; }

    return 1

}
path::inode () {

    local p="${1:-}" v=""

    path::valid "${p}" || return 1
    path::has stat || return 1

    [[ -e "${p}" || -L "${p}" ]] || return 1

    v="$(stat -c '%i' -- "${p}" 2>/dev/null || true)"
    [[ "${v}" =~ ^[0-9]+$ ]] && { printf '%s\n' "${v}"; return 0; }

    v="$(stat -f '%i' -- "${p}" 2>/dev/null || true)"
    [[ "${v}" =~ ^[0-9]+$ ]] && { printf '%s\n' "${v}"; return 0; }

    return 1

}

path::root () {

    local p="${1:-}" head=""

    [[ -n "${p}" ]] || { printf '/'; return 0; }

    path::valid "${p}" || return 1
    p="${p//\\//}"

    if [[ "${p}" =~ ^([A-Za-z]):(/?) ]]; then

        printf '%s:%s' "${BASH_REMATCH[1]}" "${BASH_REMATCH[2]:-/}"

    elif [[ "${p}" == //* ]]; then

        head="${p#//}"
        head="${head%%/*}"

        printf '//%s/' "${head}"

    elif [[ "${p}" == /* ]]; then

        printf '/'

    else

        return 1

    fi

}
path::script () {

    local p="${BASH_SOURCE[1]:-${BASH_SOURCE[0]:-$0}}" v=""

    [[ -n "${1:-}" ]] && p="${1}"
    [[ -n "${p}" ]] || return 1

    v="$(path::resolve "${p}" 2>/dev/null || true)"
    [[ -n "${v}" ]] && { printf '%s' "${v}"; return 0; }

    path::abs "${p}"

}
path::script_dir () {

    local p="" v=""

    if [[ -n "${1:-}" ]]; then p="${1}"
    else p="${BASH_SOURCE[1]:-${BASH_SOURCE[0]:-$0}}"
    fi

    [[ -n "${p}" ]] || return 1

    v="$(path::resolve "${p}" 2>/dev/null || true)"
    [[ -n "${v}" ]] || v="$(path::abs "${p}")" || return 1

    path::dirname "${v}"

}
path::home_dir () {

    local v=""

    v="${HOME:-}"
    [[ -n "${v}" ]] && { printf '%s\n' "${v}"; return 0; }

    v="$(sys::uhome 2>/dev/null || true)"
    [[ -n "${v}" ]] && { printf '%s\n' "${v}"; return 0; }

    v="${USERPROFILE:-}"
    [[ -n "${v}" ]] && { printf '%s\n' "${v}"; return 0; }

    return 1

}
path::tmp_dir () {

    local v=""

    for v in "${TMPDIR:-}" "${TMP:-}" "${TEMP:-}"; do

        if [[ -n "${v}" && -d "${v}" ]]; then
            printf '%s\n' "${v%/}"
            return 0
        fi

    done

    if sys::is_windows && [[ -n "${LOCALAPPDATA:-}" && -d "${LOCALAPPDATA}/Temp" ]]; then
        printf '%s\n' "${LOCALAPPDATA}/Temp"
        return 0
    fi

    [[ -d /tmp ]] && { printf '/tmp\n'; return 0; }
    [[ -d /var/tmp ]] && { printf '/var/tmp\n'; return 0; }

    v="$(path::home_dir 2>/dev/null || true)"
    [[ -n "${v}" && -d "${v}" ]] && { printf '%s/.tmp\n' "${v%/}"; return 0; }

    return 1

}
path::config_dir () {

    local v="" home=""

    home="$(path::home_dir 2>/dev/null || true)"

    if sys::is_linux || sys::is_wsl; then

        v="${XDG_CONFIG_HOME:-}"

        [[ -n "${v}" ]] && { printf '%s\n' "${v}"; return 0; }
        [[ -n "${home}" ]] && { printf '%s/.config\n' "${home%/}"; return 0; }

        return 1

    fi
    if sys::is_macos; then

        [[ -n "${home}" ]] && { printf '%s/Library/Application Support\n' "${home%/}"; return 0; }
        return 1

    fi
    if sys::is_windows; then

        v="${APPDATA:-}"

        [[ -n "${v}" ]] && { printf '%s\n' "${v}"; return 0; }
        [[ -n "${home}" ]] && { printf '%s/AppData/Roaming\n' "${home%/}"; return 0; }

        return 1

    fi

    [[ -n "${home}" ]] && { printf '%s/.config\n' "${home%/}"; return 0; }
    return 1

}
path::data_dir () {

    local v="" home=""

    home="$(path::home_dir 2>/dev/null || true)"

    if sys::is_linux || sys::is_wsl; then

        v="${XDG_DATA_HOME:-}"

        [[ -n "${v}" ]] && { printf '%s\n' "${v}"; return 0; }
        [[ -n "${home}" ]] && { printf '%s/.local/share\n' "${home%/}"; return 0; }

        return 1

    fi
    if sys::is_macos; then

        [[ -n "${home}" ]] && { printf '%s/Library/Application Support\n' "${home%/}"; return 0; }
        return 1

    fi
    if sys::is_windows; then

        v="${LOCALAPPDATA:-}"

        [[ -n "${v}" ]] && { printf '%s\n' "${v}"; return 0; }
        [[ -n "${home}" ]] && { printf '%s/AppData/Local\n' "${home%/}"; return 0; }

        return 1

    fi

    [[ -n "${home}" ]] && { printf '%s/.local/share\n' "${home%/}"; return 0; }
    return 1

}
path::cache_dir () {

    local v="" home=""

    home="$(path::home_dir 2>/dev/null || true)"

    if sys::is_linux || sys::is_wsl; then

        v="${XDG_CACHE_HOME:-}"

        [[ -n "${v}" ]] && { printf '%s\n' "${v}"; return 0; }
        [[ -n "${home}" ]] && { printf '%s/.cache\n' "${home%/}"; return 0; }

        return 1

    fi
    if sys::is_macos; then

        [[ -n "${home}" ]] && { printf '%s/Library/Caches\n' "${home%/}"; return 0; }
        return 1

    fi
    if sys::is_windows; then

        v="${LOCALAPPDATA:-}"

        [[ -n "${v}" ]] && { printf '%s/Cache\n' "${v%/}"; return 0; }
        [[ -n "${home}" ]] && { printf '%s/AppData/Local/Cache\n' "${home%/}"; return 0; }

        return 1

    fi

    [[ -n "${home}" ]] && { printf '%s/.cache\n' "${home%/}"; return 0; }
    return 1

}
path::state_dir () {

    local v="" home=""

    home="$(path::home_dir 2>/dev/null || true)"

    if sys::is_linux || sys::is_wsl; then

        v="${XDG_STATE_HOME:-}"

        [[ -n "${v}" ]] && { printf '%s\n' "${v}"; return 0; }
        [[ -n "${home}" ]] && { printf '%s/.local/state\n' "${home%/}"; return 0; }

        return 1

    fi
    if sys::is_macos; then

        [[ -n "${home}" ]] && { printf '%s/Library/Application Support\n' "${home%/}"; return 0; }
        return 1

    fi
    if sys::is_windows; then

        v="${LOCALAPPDATA:-}"

        [[ -n "${v}" ]] && { printf '%s\n' "${v}"; return 0; }
        [[ -n "${home}" ]] && { printf '%s/AppData/Local\n' "${home%/}"; return 0; }

        return 1

    fi

    [[ -n "${home}" ]] && { printf '%s/.local/state\n' "${home%/}"; return 0; }
    return 1

}
path::runtime_dir () {

    local v=""

    if sys::is_linux || sys::is_wsl; then

        v="${XDG_RUNTIME_DIR:-}"
        [[ -n "${v}" && -d "${v}" ]] && { printf '%s\n' "${v}"; return 0; }

    fi

    path::tmp_dir

}
path::log_dir () {

    local v="" home=""

    v="$(path::state_dir 2>/dev/null || true)"
    [[ -n "${v}" ]] || return 1

    if sys::is_linux || sys::is_wsl; then

        printf '%s/log\n' "${v%/}"

    elif sys::is_macos; then

        home="$(path::home_dir 2>/dev/null || true)"
        [[ -n "${home}" ]] || return 1

        printf '%s/Library/Logs\n' "${home%/}"

    else

        printf '%s/log\n' "${v%/}"

    fi

}
path::bin_dir () {

    local v="" home=""

    home="$(path::home_dir 2>/dev/null || true)"
    [[ -n "${home}" ]] || return 1

    if sys::is_linux || sys::is_wsl; then

        printf '%s/.local/bin\n' "${home%/}"

    elif sys::is_macos; then

        printf '%s/.local/bin\n' "${home%/}"

    elif sys::is_windows; then

        v="${LOCALAPPDATA:-}"

        if [[ -n "${v}" ]]; then printf '%s/Programs/bin\n' "${v%/}"
        else printf '%s/AppData/Local/Programs/bin\n' "${home%/}"
        fi

    else

        printf '%s/.local/bin\n' "${home%/}"

    fi

}
path::desktop_dir () {

    local v="" home=""

    home="$(path::home_dir 2>/dev/null || true)"
    [[ -n "${home}" ]] || return 1

    if ( sys::is_linux || sys::is_wsl ) && path::has xdg-user-dir; then

        v="$(xdg-user-dir DESKTOP 2>/dev/null || true)"
        [[ -n "${v}" ]] && { printf '%s\n' "${v}"; return 0; }

    fi

    printf '%s/Desktop\n' "${home%/}"

}
path::downloads_dir () {

    local v="" home=""

    home="$(path::home_dir 2>/dev/null || true)"
    [[ -n "${home}" ]] || return 1

    if ( sys::is_linux || sys::is_wsl ) && path::has xdg-user-dir; then

        v="$(xdg-user-dir DOWNLOAD 2>/dev/null || true)"
        [[ -n "${v}" ]] && { printf '%s\n' "${v}"; return 0; }

    fi

    printf '%s/Downloads\n' "${home%/}"

}
path::documents_dir () {

    local v="" home=""

    home="$(path::home_dir 2>/dev/null || true)"
    [[ -n "${home}" ]] || return 1

    if ( sys::is_linux || sys::is_wsl ) && path::has xdg-user-dir; then

        v="$(xdg-user-dir DOCUMENTS 2>/dev/null || true)"
        [[ -n "${v}" ]] && { printf '%s\n' "${v}"; return 0; }

    fi

    printf '%s/Documents\n' "${home%/}"

}
path::pictures_dir () {

    local v="" home=""

    home="$(path::home_dir 2>/dev/null || true)"
    [[ -n "${home}" ]] || return 1

    if ( sys::is_linux || sys::is_wsl ) && path::has xdg-user-dir; then

        v="$(xdg-user-dir PICTURES 2>/dev/null || true)"
        [[ -n "${v}" ]] && { printf '%s\n' "${v}"; return 0; }

    fi

    printf '%s/Pictures\n' "${home%/}"

}
path::music_dir () {

    local v="" home=""

    home="$(path::home_dir 2>/dev/null || true)"
    [[ -n "${home}" ]] || return 1

    if ( sys::is_linux || sys::is_wsl ) && path::has xdg-user-dir; then

        v="$(xdg-user-dir MUSIC 2>/dev/null || true)"
        [[ -n "${v}" ]] && { printf '%s\n' "${v}"; return 0; }

    fi

    printf '%s/Music\n' "${home%/}"

}
path::videos_dir () {

    local v="" home=""

    home="$(path::home_dir 2>/dev/null || true)"
    [[ -n "${home}" ]] || return 1

    if ( sys::is_linux || sys::is_wsl ) && path::has xdg-user-dir; then

        v="$(xdg-user-dir VIDEOS 2>/dev/null || true)"
        [[ -n "${v}" ]] && { printf '%s\n' "${v}"; return 0; }

    fi

    printf '%s/Videos\n' "${home%/}"

}
path::public_dir () {

    local v="" home=""

    home="$(path::home_dir 2>/dev/null || true)"
    [[ -n "${home}" ]] || return 1

    if ( sys::is_linux || sys::is_wsl ) && path::has xdg-user-dir; then

        v="$(xdg-user-dir PUBLICSHARE 2>/dev/null || true)"
        [[ -n "${v}" ]] && { printf '%s\n' "${v}"; return 0; }

    fi

    if sys::is_windows; then printf '%s/Public\n' "${PUBLIC:-${SystemDrive:-C:}/Users/Public}"
    else printf '%s/Public\n' "${home%/}"
    fi

}
path::templates_dir () {

    local v="" home=""

    home="$(path::home_dir 2>/dev/null || true)"
    [[ -n "${home}" ]] || return 1

    if ( sys::is_linux || sys::is_wsl ) && path::has xdg-user-dir; then

        v="$(xdg-user-dir TEMPLATES 2>/dev/null || true)"
        [[ -n "${v}" ]] && { printf '%s\n' "${v}"; return 0; }

    fi

    printf '%s/Templates\n' "${home%/}"

}

path::touch () {

    local p="${1:-}" parent=""

    path::valid "${p}" || return 1

    parent="$(path::dirname "${p}")"
    [[ -d "${parent}" ]] || mkdir -p -- "${parent}" 2>/dev/null || return 1

    path::has touch && touch -- "${p}" 2>/dev/null && return 0
    : > "${p}" 2>/dev/null

}
path::remove () {

    local p="${1:-}"

    path::valid "${p}" || return 1
    path::is_root "${p}" && return 1

    [[ -e "${p}" || -L "${p}" ]] || return 0

    if [[ -L "${p}" || -f "${p}" ]]; then
        rm -f -- "${p}" 2>/dev/null
        return
    fi
    if [[ -d "${p}" ]]; then
        rm -rf -- "${p}" 2>/dev/null
        return
    fi

    rm -f -- "${p}" 2>/dev/null

}
path::rename () {

    local from="${1:-}" to="${2:-}"

    path::valid "${from}" || return 1
    path::valid "${to}" || return 1

    [[ -e "${from}" || -L "${from}" ]] || return 1
    path::has mv || return 1

    mv -f -- "${from}" "${to}" 2>/dev/null

}
path::move () {

    path::rename "$@"

}
path::copy () {

    local from="${1:-}" to="${2:-}" parent=""

    path::valid "${from}" || return 1
    path::valid "${to}" || return 1

    [[ -e "${from}" || -L "${from}" ]] || return 1
    path::has cp || return 1

    parent="$(path::dirname "${to}")"
    [[ -d "${parent}" ]] || mkdir -p -- "${parent}" 2>/dev/null || return 1

    if [[ -d "${from}" ]]; then cp -R -- "${from}" "${to}" 2>/dev/null
    else cp -f -- "${from}" "${to}" 2>/dev/null
    fi

}
path::link () {

    local from="${1:-}" to="${2:-}"

    path::valid "${from}" || return 1
    path::valid "${to}" || return 1

    [[ -e "${from}" ]] || return 1
    path::has ln || return 1

    ln -f -- "${from}" "${to}" 2>/dev/null

}
path::symlink () {

    local from="${1:-}" to="${2:-}" parent="" winfrom="" winto=""

    path::valid "${from}" || return 1
    path::valid "${to}" || return 1

    parent="$(path::dirname "${to}")"
    [[ -d "${parent}" ]] || mkdir -p -- "${parent}" 2>/dev/null || return 1

    if path::has ln; then

        ln -sfn -- "${from}" "${to}" 2>/dev/null && return 0
        ln -sf -- "${from}" "${to}" 2>/dev/null && return 0

    fi
    if sys::is_windows && path::has cmd.exe; then

        winfrom="${from}"
        winto="${to}"

        if path::has cygpath; then
            winfrom="$(cygpath -aw -- "${from}" 2>/dev/null || printf '%s' "${from}")"
            winto="$(cygpath -aw -- "${to}" 2>/dev/null || printf '%s' "${to}")"
        else
            winfrom="$(path::win "${from}")"
            winto="$(path::win "${to}")"
        fi

        if [[ -d "${from}" ]]; then cmd.exe /C mklink /D "${winto}" "${winfrom}" >/dev/null 2>&1
        else cmd.exe /C mklink "${winto}" "${winfrom}" >/dev/null 2>&1
        fi

        return

    fi

    return 1

}
path::readlink () {

    local p="${1:-}" v=""

    path::valid "${p}" || return 1
    [[ -L "${p}" ]] || return 1

    if path::has readlink; then

        v="$(readlink -- "${p}" 2>/dev/null || true)"
        [[ -n "${v}" ]] && { printf '%s' "${v}"; return 0; }

    fi
    if path::has stat; then

        v="$(stat -c '%N' -- "${p}" 2>/dev/null || true)"
        [[ "${v}" =~ ' -> '\'(.*)\'$ ]] && { printf '%s' "${BASH_REMATCH[1]}"; return 0; }

        v="$(stat -f '%Y' -- "${p}" 2>/dev/null || true)"
        [[ -n "${v}" ]] && { printf '%s' "${v}"; return 0; }

    fi

    return 1

}

path::mktemp () {

    local prefix="${1:-tmp}" suffix="${2:-}" tmp="" name="" v=""

    tmp="$(path::tmp_dir 2>/dev/null || true)"
    [[ -n "${tmp}" ]] || return 1

    if path::has mktemp; then

        if [[ -n "${suffix}" ]]; then

            v="$(mktemp --suffix="${suffix}" "${tmp%/}/${prefix}.XXXXXXXX" 2>/dev/null || true)"
            [[ -n "${v}" ]] && { printf '%s' "${v}"; return 0; }

            v="$(mktemp -t "${prefix}.XXXXXXXX${suffix}" 2>/dev/null || true)"
            [[ -n "${v}" ]] && { printf '%s' "${v}"; return 0; }

        else

            v="$(mktemp "${tmp%/}/${prefix}.XXXXXXXX" 2>/dev/null || true)"
            [[ -n "${v}" ]] && { printf '%s' "${v}"; return 0; }

            v="$(mktemp -t "${prefix}.XXXXXXXX" 2>/dev/null || true)"
            [[ -n "${v}" ]] && { printf '%s' "${v}"; return 0; }

        fi

    fi

    name="${prefix}.$$.${RANDOM}${RANDOM}${suffix}"
    v="${tmp%/}/${name}"

    [[ -e "${v}" || -L "${v}" ]] && return 1
    : > "${v}" 2>/dev/null || return 1

    printf '%s' "${v}"

}
path::mktemp_dir () {

    local prefix="${1:-tmp}" tmp="" name="" v=""

    tmp="$(path::tmp_dir 2>/dev/null || true)"
    [[ -n "${tmp}" ]] || return 1

    if path::has mktemp; then

        v="$(mktemp -d "${tmp%/}/${prefix}.XXXXXXXX" 2>/dev/null || true)"
        [[ -n "${v}" ]] && { printf '%s' "${v}"; return 0; }

        v="$(mktemp -d -t "${prefix}.XXXXXXXX" 2>/dev/null || true)"
        [[ -n "${v}" ]] && { printf '%s' "${v}"; return 0; }

    fi

    name="${prefix}.$$.${RANDOM}${RANDOM}"
    v="${tmp%/}/${name}"

    [[ -e "${v}" || -L "${v}" ]] && return 1
    mkdir -- "${v}" 2>/dev/null || return 1

    printf '%s' "${v}"

}
path::which () {

    local bin="${1:-}" v=""

    [[ -n "${bin}" ]] || return 1
    [[ "${bin}" != *$'\n'* && "${bin}" != *$'\r'* ]] || return 1

    v="$(command -v -- "${bin}" 2>/dev/null || true)"
    [[ -n "${v}" ]] && { printf '%s' "${v}"; return 0; }

    return 1

}
path::which_all () {

    local bin="${1:-}" dir="" entry=""
    local -a dirs=()

    [[ -n "${bin}" ]] || return 1
    [[ "${bin}" != *$'\n'* && "${bin}" != *$'\r'* ]] || return 1

    IFS=":" read -r -a dirs <<< "${PATH:-}"

    for dir in "${dirs[@]}"; do

        [[ -n "${dir}" ]] || continue
        entry="${dir%/}/${bin}"

        [[ -f "${entry}" && -x "${entry}" ]] && printf '%s\n' "${entry}"

    done

}
