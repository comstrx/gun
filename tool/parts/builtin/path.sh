# shellcheck shell=bash

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

    [[ "${p}" =~ ^[A-Za-z]:([^\\/].*)?$ ]] && return 1

    if sys::has cygpath; then
        v="$(cygpath -u -- "${p}" 2>/dev/null || true)"
        [[ -n "${v}" ]] && { printf '%s' "${v}"; return 0; }
    fi

    p="${p//\\//}"

    if [[ "${p}" =~ ^([A-Za-z]):/(.*)$ ]]; then

        letter="${BASH_REMATCH[1]}"
        letter="${letter,,}"

        if sys::is_wsl; then printf '/mnt/%s' "${letter}"
        else printf '/%s' "${letter}"
        fi

        [[ -n "${BASH_REMATCH[2]}" ]] && printf '/%s' "${BASH_REMATCH[2]}"
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
    if sys::is_windows && [[ "${p}" =~ ^/([A-Za-z])(/.*)?$ ]]; then

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

    if sys::has cygpath; then

        v="$(cygpath -w -- "${p}" 2>/dev/null || true)"
        [[ -n "${v}" ]] && { printf '%s' "${v}"; return 0; }

    fi

    printf '%s' "${p//\//\\}"

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

        if [[ "${prefix}" == */ ]]; then printf '%s' "${prefix}"
        elif [[ -n "${prefix}" ]]; then printf '%s' "${prefix}"
        else printf '%s' "."
        fi

        return 0

    fi

    head="$( IFS='/'; printf '%s' "${out[*]}" )"

    if [[ -n "${prefix}" ]]; then printf '%s%s' "${prefix}" "${head}"
    else printf '%s' "${head}"
    fi

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
path::resolve () {

    local p="${1:-}" parent="" base="" v=""

    path::valid "${p}" || return 1

    if sys::has realpath; then

        v="$(realpath -m -- "${p}" 2>/dev/null)" || true
        [[ -n "${v}" ]] && { printf '%s' "${v}"; return 0; }

        v="$(realpath -- "${p}" 2>/dev/null)" || true
        [[ -n "${v}" ]] && { printf '%s' "${v}"; return 0; }

    fi
    if sys::has readlink; then

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
path::abs () {

    local p="${1:-}"

    path::valid "${p}" || return 1

    if path::is_abs "${p}"; then path::norm "${p}"
    else path::norm "$(pwd 2>/dev/null || printf '.')/${p}"
    fi

}
path::rel () {

    local target="${1:-}" base="${2:-}" t_abs="" b_abs="" common=0 v="" target_drive="" base_drive="" td="" bd="" i=0 max=0 up=0

    local -a tparts=()
    local -a bparts=()

    path::valid "${target}" || return 1
    [[ -n "${base}" ]] || base="$(pwd 2>/dev/null || printf '.')"

    target_drive="${target:0:1}"
    base_drive="${base:0:1}"

    if [[ "${target:1:1}" == ":" && "${base:1:1}" == ":" && "${target_drive,,}" != "${base_drive,,}" ]]; then
        printf '%s' "${target//\\//}"
        return 0
    fi

    t_abs="$(path::abs "${target}")" || return 1
    b_abs="$(path::abs "${base}")" || return 1

    t_abs="${t_abs//\\//}"
    b_abs="${b_abs//\\//}"

    td="${t_abs:0:1}"
    bd="${b_abs:0:1}"

    if [[ "${t_abs}" =~ ^[A-Za-z]: && "${b_abs}" =~ ^[A-Za-z]: && "${td,,}" != "${bd,,}" ]]; then
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
path::drive () {

    local p="${1:-}"

    [[ "${p}" =~ ^([A-Za-z]):.* ]] || return 1
    printf '%s:' "${BASH_REMATCH[1]}"

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

    if sys::has getent; then home="$(getent passwd "${user}" 2>/dev/null | awk -F: 'NR==1 {print $6}')"
    elif sys::is_macos && sys::has dscl; then home="$(dscl . -read "/Users/${user}" NFSHomeDirectory 2>/dev/null | awk 'NR==1 {print $2}')"
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

    local first="" cur="" prefix="" cur_prefix="" p="" head="" i=0
    local -a a=()
    local -a b=()
    local -a out=()

    (( $# > 0 )) || return 1

    first="$(path::abs "${1}")" || return 1
    shift || true

    p="${first//\\//}"

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

    [[ -z "${p}" ]] || IFS='/' read -r -a a <<< "${p}"

    for cur in "$@"; do

        cur="$(path::abs "${cur}")" || return 1
        p="${cur//\\//}"
        cur_prefix=""

        if [[ "${p}" =~ ^([A-Za-z]:)(/?)(.*)$ ]]; then
            cur_prefix="${BASH_REMATCH[1]}${BASH_REMATCH[2]}"
            p="${BASH_REMATCH[3]}"
        elif [[ "${p}" == //* ]]; then
            p="${p#//}"
            head="${p%%/*}"
            p="${p#"${head}"}"
            p="${p#/}"
            cur_prefix="//${head}/"
        elif [[ "${p}" == /* ]]; then
            cur_prefix="/"
            p="${p#/}"
        fi

        [[ "${prefix,,}" == "${cur_prefix,,}" ]] || return 1

        b=()
        [[ -z "${p}" ]] || IFS='/' read -r -a b <<< "${p}"

        out=()
        i=0

        while (( i < ${#a[@]} && i < ${#b[@]} )); do
            [[ "${a[$i]}" == "${b[$i]}" ]] || break
            out+=( "${a[$i]}" )
            i=$(( i + 1 ))
        done

        a=( "${out[@]}" )

    done

    if (( ${#a[@]} == 0 )); then
        [[ -n "${prefix}" ]] && printf '%s' "${prefix}" || printf '.'
    elif [[ -n "${prefix}" ]]; then
        printf '%s%s' "${prefix}" "$( IFS='/'; printf '%s' "${a[*]}" )"
    else
        printf '%s' "$( IFS='/'; printf '%s' "${a[*]}" )"
    fi

}
path::dirname () {

    local p="${1:-}" dir="" drive="" rest=""

    path::valid "${p}" || return 1
    p="${p//\\//}"

    if [[ "${p}" =~ ^([A-Za-z]:)(.*)$ ]]; then

        drive="${BASH_REMATCH[1]}"
        rest="${BASH_REMATCH[2]}"

        [[ -n "${rest}" ]] || { printf '%s' "${drive}"; return 0; }
        [[ "${rest}" == */* ]] || { printf '%s' "${drive}"; return 0; }

        dir="${rest%/*}"
        [[ -n "${dir}" ]] || dir="/"

        printf '%s%s' "${drive}" "${dir}"
        return 0

    fi

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

    local path_base="" lead="" rest=""

    path_base="$(path::basename "${1:-}")" || return 1

    lead="${path_base%%[!.]*}"
    rest="${path_base#"${lead}"}"

    [[ "${rest}" == *.* ]] && { printf '%s' "${path_base%.*}"; return 0; }
    printf '%s' "${path_base}"

}
path::ext () {

    local path_base="" lead="" rest=""

    path_base="$(path::basename "${1:-}")" || return 1

    lead="${path_base%%[!.]*}"
    rest="${path_base#"${lead}"}"

    [[ "${rest}" == *.* ]] && { printf '%s' "${path_base##*.}"; return 0; }
    printf ''

}
path::dotext () {

    local path_base="" lead="" rest=""

    path_base="$(path::basename "${1:-}")" || return 1

    lead="${path_base%%[!.]*}"
    rest="${path_base#"${lead}"}"

    [[ "${rest}" == *.* ]] && { printf '.%s' "${path_base##*.}"; return 0; }
    printf ''

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
path::chmod () {

    local p="${1:-}" mode="${2:-}"

    path::valid "${p}" || return 1
    sys::has chmod || return 1

    [[ -n "${mode}" ]] || return 1
    [[ -e "${p}" || -L "${p}" ]] || return 1

    case "${mode}" in
        [0-7][0-7][0-7]|[0-7][0-7][0-7][0-7]|u+*|u-*|u=*|g+*|g-*|g=*|o+*|o-*|o=*|a+*|a-*|a=*|+*|-*)
            chmod -- "${mode}" "${p}" 2>/dev/null && return 0
            chmod "${mode}" "${p}" 2>/dev/null && return 0
        ;;
        *)
            return 1
        ;;
    esac

    return 1

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

    if [[ -f "${p}" ]] && sys::has stat; then

        v="$(stat -c '%s' -- "${p}" 2>/dev/null || true)"
        [[ "${v}" =~ ^[0-9]+$ ]] && { printf '%s\n' "${v}"; return 0; }

        v="$(stat -f '%z' -- "${p}" 2>/dev/null || true)"
        [[ "${v}" =~ ^[0-9]+$ ]] && { printf '%s\n' "${v}"; return 0; }

    fi
    if sys::has wc && [[ -f "${p}" ]]; then

        v="$(wc -c < "${p}" 2>/dev/null | tr -d '[:space:]' || true)"
        [[ "${v}" =~ ^[0-9]+$ ]] && { printf '%s\n' "${v}"; return 0; }

    fi
    if [[ -d "${p}" ]] && sys::has du; then

        v="$(du -sk -- "${p}" 2>/dev/null | awk 'NR==1 {print $1}' | head -n 1)"
        [[ "${v}" =~ ^[0-9]+$ ]] && { printf '%s\n' "$(( v * 1024 ))"; return 0; }

    fi

    return 1

}
path::mtime () {

    local p="${1:-}" v=""

    path::valid "${p}" || return 1
    sys::has stat || return 1

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
    sys::has stat || return 1

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
    sys::has stat || return 1

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
    sys::has stat || return 1

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
    sys::has stat || return 1

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
    sys::has stat || return 1

    [[ -e "${p}" || -L "${p}" ]] || return 1

    v="$(stat -c '%a' "${p}" 2>/dev/null || true)"
    [[ "${v}" =~ ^[0-7]{3,4}$ ]] && { printf '%s\n' "${v}"; return 0; }

    v="$(stat -f '%p' "${p}" 2>/dev/null || true)"
    [[ "${v}" =~ ^[0-7]+$ ]] && { printf '%s\n' "${v: -4}"; return 0; }

    return 1

}
path::inode () {

    local p="${1:-}" v=""

    path::valid "${p}" || return 1
    sys::has stat || return 1

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

    if ( sys::is_linux || sys::is_wsl ) && sys::has xdg-user-dir; then

        v="$(xdg-user-dir DESKTOP 2>/dev/null || true)"
        [[ -n "${v}" ]] && { printf '%s\n' "${v}"; return 0; }

    fi

    printf '%s/Desktop\n' "${home%/}"

}
path::downloads_dir () {

    local v="" home=""

    home="$(path::home_dir 2>/dev/null || true)"
    [[ -n "${home}" ]] || return 1

    if ( sys::is_linux || sys::is_wsl ) && sys::has xdg-user-dir; then

        v="$(xdg-user-dir DOWNLOAD 2>/dev/null || true)"
        [[ -n "${v}" ]] && { printf '%s\n' "${v}"; return 0; }

    fi

    printf '%s/Downloads\n' "${home%/}"

}
path::documents_dir () {

    local v="" home=""

    home="$(path::home_dir 2>/dev/null || true)"
    [[ -n "${home}" ]] || return 1

    if ( sys::is_linux || sys::is_wsl ) && sys::has xdg-user-dir; then

        v="$(xdg-user-dir DOCUMENTS 2>/dev/null || true)"
        [[ -n "${v}" ]] && { printf '%s\n' "${v}"; return 0; }

    fi

    printf '%s/Documents\n' "${home%/}"

}
path::pictures_dir () {

    local v="" home=""

    home="$(path::home_dir 2>/dev/null || true)"
    [[ -n "${home}" ]] || return 1

    if ( sys::is_linux || sys::is_wsl ) && sys::has xdg-user-dir; then

        v="$(xdg-user-dir PICTURES 2>/dev/null || true)"
        [[ -n "${v}" ]] && { printf '%s\n' "${v}"; return 0; }

    fi

    printf '%s/Pictures\n' "${home%/}"

}
path::music_dir () {

    local v="" home=""

    home="$(path::home_dir 2>/dev/null || true)"
    [[ -n "${home}" ]] || return 1

    if ( sys::is_linux || sys::is_wsl ) && sys::has xdg-user-dir; then

        v="$(xdg-user-dir MUSIC 2>/dev/null || true)"
        [[ -n "${v}" ]] && { printf '%s\n' "${v}"; return 0; }

    fi

    printf '%s/Music\n' "${home%/}"

}
path::videos_dir () {

    local v="" home=""

    home="$(path::home_dir 2>/dev/null || true)"
    [[ -n "${home}" ]] || return 1

    if ( sys::is_linux || sys::is_wsl ) && sys::has xdg-user-dir; then

        v="$(xdg-user-dir VIDEOS 2>/dev/null || true)"
        [[ -n "${v}" ]] && { printf '%s\n' "${v}"; return 0; }

    fi

    printf '%s/Videos\n' "${home%/}"

}
path::public_dir () {

    local v="" home=""

    home="$(path::home_dir 2>/dev/null || true)"
    [[ -n "${home}" ]] || return 1

    if ( sys::is_linux || sys::is_wsl ) && sys::has xdg-user-dir; then

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

    if ( sys::is_linux || sys::is_wsl ) && sys::has xdg-user-dir; then

        v="$(xdg-user-dir TEMPLATES 2>/dev/null || true)"
        [[ -n "${v}" ]] && { printf '%s\n' "${v}"; return 0; }

    fi

    printf '%s/Templates\n' "${home%/}"

}

path::make () {

    local p="${1:-}" mode="${2:-}"

    path::valid "${p}" || return 1

    [[ -d "${p}" && -z "${mode}" ]] && return 0
    [[ -d "${p}" ]] && { chmod "${mode}" "${p}" 2>/dev/null || return 1; return 0; }
    [[ -e "${p}" || -L "${p}" ]] && return 1

    mkdir -p -- "${p}" 2>/dev/null || mkdir -p "${p}" 2>/dev/null || return 1
    [[ -n "${mode}" ]] && { chmod "${mode}" "${p}" 2>/dev/null || return 1; }

    return 0

}
path::touch () {

    local p="${1:-}" parent=""

    path::valid "${p}" || return 1

    parent="$(path::dirname "${p}")"
    [[ -d "${parent}" ]] || mkdir -p -- "${parent}" 2>/dev/null || return 1

    sys::has touch && touch -- "${p}" 2>/dev/null && return 0
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
path::clear () {

    local p="${1:-}" entry=""

    path::exists "${p}" || return 1
    path::is_root "${p}" && return 1

    [[ -d "${p}" || -f "${p}" ]] || return 1

    if [[ -f "${p}" ]]; then

        : > "${p}" 2>/dev/null || return 1

    else

        for entry in "${p%/}"/* "${p%/}"/.[!.]* "${p%/}"/..?*; do

            [[ -e "${entry}" || -L "${entry}" ]] || continue
            rm -rf -- "${entry}" 2>/dev/null || rm -rf "${entry}" 2>/dev/null || return 1

        done

    fi

    return 0

}
path::rename () {

    local from="${1:-}" to="${2:-}"

    path::valid "${from}" || return 1
    path::valid "${to}" || return 1

    [[ -e "${from}" || -L "${from}" ]] || return 1
    sys::has mv || return 1

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
    sys::has cp || return 1

    parent="$(path::dirname "${to}")"
    [[ -d "${parent}" ]] || mkdir -p -- "${parent}" 2>/dev/null || return 1

    if [[ -d "${from}" && ! -L "${from}" ]]; then cp -a -- "${from}" "${to}" 2>/dev/null || cp -R -p -- "${from}" "${to}" 2>/dev/null
    else cp -P -p -f -- "${from}" "${to}" 2>/dev/null || cp -p -f -- "${from}" "${to}" 2>/dev/null || cp -f -- "${from}" "${to}" 2>/dev/null
    fi

}
path::link () {

    local from="${1:-}" to="${2:-}"

    path::valid "${from}" || return 1
    path::valid "${to}" || return 1

    [[ -e "${from}" ]] || return 1
    sys::has ln || return 1

    ln -f -- "${from}" "${to}" 2>/dev/null

}
path::symlink () {

    local from="${1:-}" to="${2:-}" parent="" winfrom="" winto=""

    path::valid "${from}" || return 1
    path::valid "${to}" || return 1

    parent="$(path::dirname "${to}")"
    [[ -d "${parent}" ]] || mkdir -p -- "${parent}" 2>/dev/null || return 1

    if sys::has ln; then

        ln -sfn -- "${from}" "${to}" 2>/dev/null && return 0
        ln -sf -- "${from}" "${to}" 2>/dev/null && return 0

    fi
    if sys::is_windows && sys::has cmd.exe; then

        winfrom="${from}"
        winto="${to}"

        if sys::has cygpath; then
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

    if sys::has readlink; then

        v="$(readlink -- "${p}" 2>/dev/null || true)"
        [[ -n "${v}" ]] && { printf '%s' "${v}"; return 0; }

    fi
    if sys::has stat; then

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

    if sys::has mktemp; then

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

    ( set -C; : > "${v}" ) 2>/dev/null || return 1

    printf '%s' "${v}"

}
path::mktemp_dir () {

    local prefix="${1:-tmp}" tmp="" name="" v=""

    tmp="$(path::tmp_dir 2>/dev/null || true)"
    [[ -n "${tmp}" ]] || return 1

    if sys::has mktemp; then

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
path::archive () {

    local src="" archive_out="" format="" arg="" parent="" name="" out_parent="" pat="" lower=""

    local -a exclude=()
    local -a positional=()
    local -a args=()
    local -a fallback=()

    for arg in "$@"; do

        case "${arg}" in
            --exclude=*) exclude+=( "${arg#--exclude=}" ) ;;
            --format=*)  format="${arg#--format=}" ;;
            --) ;;
            -*) return 1 ;;
            *) positional+=( "${arg}" ) ;;
        esac

    done

    src="${positional[0]:-}"
    archive_out="${positional[1]:-}"

    path::exists "${src}" || return 1

    if [[ -n "${format}" ]]; then

        case "${format,,}" in
            zip|rar|7z|tar) format="${format,,}" ;;
            tgz|gz|tar.gz) format="tar.gz" ;;
            txz|xz|tar.xz) format="tar.xz" ;;
            tbz2|bz2|tar.bz2) format="tar.bz2" ;;
            tzst|zst|tar.zst) format="tar.zst" ;;
            *) return 1 ;;
        esac

    fi
    if [[ -z "${archive_out}" ]]; then

        [[ -n "${format}" ]] || format="tar.gz"
        archive_out="${src%/}.${format#.}"

    fi
    if [[ -n "${format}" ]]; then

        archive_out="${archive_out%.tar.zst}"
        archive_out="${archive_out%.tar.gz}"
        archive_out="${archive_out%.tar.xz}"
        archive_out="${archive_out%.tar.bz2}"
        archive_out="${archive_out%.tgz}"
        archive_out="${archive_out%.txz}"
        archive_out="${archive_out%.tbz2}"
        archive_out="${archive_out%.tzst}"
        archive_out="${archive_out%.tar}"
        archive_out="${archive_out%.zip}"
        archive_out="${archive_out%.rar}"
        archive_out="${archive_out%.7z}"
        archive_out="${archive_out}.${format#.}"

    fi

    path::valid "${archive_out}" || return 1

    case "${archive_out}" in
        /*|[A-Za-z]:*) ;;
        *) archive_out="${PWD}/${archive_out#./}" ;;
    esac

    parent="$(path::dirname "${src}")" || return 1
    name="$(path::basename "${src}")" || return 1
    out_parent="$(path::dirname "${archive_out}")" || return 1

    [[ -n "${parent}" && -n "${name}" ]] || return 1
    mkdir -p -- "${out_parent}" 2>/dev/null || mkdir -p "${out_parent}" 2>/dev/null || return 1

    lower="${archive_out,,}"

    case "${lower}" in
        *.tar.gz|*.tgz)

            sys::has tar || return 1
            args=( -czf "${archive_out}" )

            for pat in "${exclude[@]}"; do
                [[ -n "${pat}" ]] && args+=( "--exclude=${pat}" )
            done

            args+=( -C "${parent}" "${name}" )
            tar "${args[@]}" 2>/dev/null

        ;;
        *.tar.bz2|*.tbz2)

            sys::has tar || return 1
            args=( -cjf "${archive_out}" )

            for pat in "${exclude[@]}"; do
                [[ -n "${pat}" ]] && args+=( "--exclude=${pat}" )
            done

            args+=( -C "${parent}" "${name}" )
            tar "${args[@]}" 2>/dev/null

        ;;
        *.tar.xz|*.txz)

            sys::has tar || return 1
            args=( -cJf "${archive_out}" )

            for pat in "${exclude[@]}"; do
                [[ -n "${pat}" ]] && args+=( "--exclude=${pat}" )
            done

            args+=( -C "${parent}" "${name}" )
            tar "${args[@]}" 2>/dev/null

        ;;
        *.tar.zst|*.tzst)

            sys::has tar || return 1

            args=( --zstd -cf "${archive_out}" )

            for pat in "${exclude[@]}"; do
                [[ -n "${pat}" ]] && args+=( "--exclude=${pat}" )
            done

            args+=( -C "${parent}" "${name}" )

            tar "${args[@]}" 2>/dev/null && { printf '%s\n' "${archive_out}"; return 0; }

            sys::has zstd || return 1

            fallback=( -cf - )

            for pat in "${exclude[@]}"; do
                [[ -n "${pat}" ]] && fallback+=( "--exclude=${pat}" )
            done

            fallback+=( -C "${parent}" "${name}" )

            (
                set -o pipefail
                tar "${fallback[@]}" 2>/dev/null | zstd -T0 -q -o "${archive_out}" >/dev/null 2>&1
            )

        ;;
        *.tar)

            sys::has tar || return 1
            args=( -cf "${archive_out}" )

            for pat in "${exclude[@]}"; do
                [[ -n "${pat}" ]] && args+=( "--exclude=${pat}" )
            done

            args+=( -C "${parent}" "${name}" )
            tar "${args[@]}" 2>/dev/null

        ;;
        *.zip)

            if sys::has zip; then

                args=( -qr "${archive_out}" "${name}" )

                if (( ${#exclude[@]} > 0 )); then

                    args+=( -x )

                    for pat in "${exclude[@]}"; do
                        [[ -n "${pat}" ]] && args+=( "${pat}" )
                    done

                fi

                (
                    builtin cd -- "${parent}" 2>/dev/null || exit 1
                    zip "${args[@]}" >/dev/null 2>&1
                ) || return 1

                printf '%s\n' "${archive_out}"
                return 0

            fi
            if sys::has 7z; then

                args=( a -tzip -bd -y "${archive_out}" "${name}" )

                for pat in "${exclude[@]}"; do
                    [[ -n "${pat}" ]] && args+=( "-xr!${pat}" )
                done

                (
                    builtin cd -- "${parent}" 2>/dev/null || exit 1
                    7z "${args[@]}" >/dev/null 2>&1
                ) || return 1

                printf '%s\n' "${archive_out}"
                return 0

            fi

            return 1

        ;;
        *.rar)

            sys::has rar || return 1

            args=( a -idq -r )

            for pat in "${exclude[@]}"; do
                [[ -n "${pat}" ]] && args+=( "-x${pat}" )
            done

            args+=( "${archive_out}" "${name}" )

            (
                builtin cd -- "${parent}" 2>/dev/null || exit 1
                rar "${args[@]}" >/dev/null 2>&1
            )

        ;;
        *.7z)

            sys::has 7z || return 1

            args=( a -bd -y "${archive_out}" "${name}" )

            for pat in "${exclude[@]}"; do
                [[ -n "${pat}" ]] && args+=( "-xr!${pat}" )
            done

            (
                builtin cd -- "${parent}" 2>/dev/null || exit 1
                7z "${args[@]}" >/dev/null 2>&1
            )

        ;;
        *)
            return 1
        ;;
    esac || return 1

    printf '%s\n' "${archive_out}"

}
path::backup () {

    local src="${1:-}" backup_out="" stamp="" name=""

    path::exists "${src}" || return 1
    shift || true

    if (( $# > 0 )) && [[ "${1:-}" != --* ]]; then
        backup_out="${1:-}"
        shift || true
    fi

    stamp="$(date +%Y%m%d-%H%M%S 2>/dev/null)" || return 1
    name="$(path::basename "${src}")" || return 1

    [[ -n "${backup_out}" ]] || backup_out="${name}.backup.${stamp}.tar.gz"

    path::archive "${src}" "${backup_out}" "$@"

}
path::strip () {

    local target="${1:-}" n="${2:-1}" tmp_new="" tmp_old="" parent=""

    path::exists "${target}" || return 1
    path::is_dir "${target}" || return 1
    path::is_root "${target}" && return 1

    sys::has tar || return 1
    sys::has mktemp || return 1
    sys::has mv || return 1

    [[ "${n}" =~ ^[0-9]+$ ]] || return 1
    (( n > 0 )) || return 0

    target="${target%/}"
    parent="$(path::dirname "${target}")" || return 1

    tmp_new="$(mktemp -d -- "${parent%/}/.strip.new.XXXXXXXX" 2>/dev/null ||
        mktemp -d "${parent%/}/.strip.new.XXXXXXXX" 2>/dev/null)" ||
        return 1

    tmp_old="$(mktemp -d -- "${parent%/}/.strip.old.XXXXXXXX" 2>/dev/null ||
        mktemp -d "${parent%/}/.strip.old.XXXXXXXX" 2>/dev/null)" ||
        { rm -rf -- "${tmp_new}" 2>/dev/null; return 1; }

    rmdir -- "${tmp_old}" 2>/dev/null || { rm -rf -- "${tmp_new}" "${tmp_old}" 2>/dev/null; return 1; }

    if ! (
        set -o pipefail
        tar -C "${target}" -cf - . 2>/dev/null | tar -C "${tmp_new}" --strip-components="$(( n + 1 ))" -xpf - 2>/dev/null
    ); then
        rm -rf -- "${tmp_new}" "${tmp_old}" 2>/dev/null
        return 1
    fi

    if ! mv -- "${target}" "${tmp_old}" 2>/dev/null; then
        rm -rf -- "${tmp_new}" "${tmp_old}" 2>/dev/null
        return 1
    fi
    if ! mv -- "${tmp_new}" "${target}" 2>/dev/null; then
        mv -- "${tmp_old}" "${target}" 2>/dev/null
        rm -rf -- "${tmp_new}" "${tmp_old}" 2>/dev/null
        return 1
    fi

    rm -rf -- "${tmp_old}" 2>/dev/null
    return 0

}
path::extract () {

    local archive="" to="" strip=0 arg="" base="" parent="" pat="" lower=""

    local -a exclude=()
    local -a positional=()
    local -a args=()
    local -a fallback=()

    for arg in "$@"; do

        case "${arg}" in
            --exclude=*) exclude+=( "${arg#--exclude=}" ) ;;
            --strip=*)   strip="${arg#--strip=}" ;;
            --) ;;
            -*) return 1 ;;
            *) positional+=( "${arg}" ) ;;
        esac

    done

    archive="${positional[0]:-}"
    to="${positional[1]:-}"

    [[ -n "${archive}" && -f "${archive}" ]] || return 1
    [[ "${strip}" =~ ^[0-9]+$ ]] || return 1

    if [[ -z "${to}" ]]; then

        base="$(path::basename "${archive}")" || return 1

        case "${base,,}" in
            *.tar.gz|*.tar.bz2|*.tar.xz|*.tar.zst)
                base="${base%.*}"
                base="${base%.*}"
            ;;
            *.tgz|*.tbz2|*.txz|*.tzst|*.tar|*.zip|*.rar|*.7z)
                base="${base%.*}"
            ;;
        esac

        parent="$(path::dirname "${archive}")" || return 1

        if [[ "${parent}" == "." ]]; then to="${base}"
        else to="${parent}/${base}"
        fi

    fi

    path::valid "${to}" || return 1
    mkdir -p -- "${to}" 2>/dev/null || mkdir -p "${to}" 2>/dev/null || return 1

    lower="${archive,,}"

    case "${lower}" in
        *.tar.gz|*.tgz)

            sys::has tar || return 1
            args=( -xzf "${archive}" )

            for pat in "${exclude[@]}"; do
                [[ -n "${pat}" ]] && args+=( "--exclude=${pat}" )
            done

            (( strip > 0 )) && args+=( "--strip-components=${strip}" )
            tar "${args[@]}" -C "${to}" 2>/dev/null

        ;;
        *.tar.bz2|*.tbz2)

            sys::has tar || return 1
            args=( -xjf "${archive}" )

            for pat in "${exclude[@]}"; do
                [[ -n "${pat}" ]] && args+=( "--exclude=${pat}" )
            done

            (( strip > 0 )) && args+=( "--strip-components=${strip}" )
            tar "${args[@]}" -C "${to}" 2>/dev/null

        ;;
        *.tar.xz|*.txz)

            sys::has tar || return 1
            args=( -xJf "${archive}" )

            for pat in "${exclude[@]}"; do
                [[ -n "${pat}" ]] && args+=( "--exclude=${pat}" )
            done

            (( strip > 0 )) && args+=( "--strip-components=${strip}" )
            tar "${args[@]}" -C "${to}" 2>/dev/null

        ;;
        *.tar.zst|*.tzst)

            sys::has tar || return 1
            args=( --zstd -xf "${archive}" )

            for pat in "${exclude[@]}"; do
                [[ -n "${pat}" ]] && args+=( "--exclude=${pat}" )
            done

            (( strip > 0 )) && args+=( "--strip-components=${strip}" )
            tar "${args[@]}" -C "${to}" 2>/dev/null && { printf '%s\n' "${to}"; return 0; }

            sys::has zstd || return 1
            fallback=( -xf - )

            for pat in "${exclude[@]}"; do
                [[ -n "${pat}" ]] && fallback+=( "--exclude=${pat}" )
            done

            (( strip > 0 )) && fallback+=( "--strip-components=${strip}" )

            (
                set -o pipefail
                zstd -dc -- "${archive}" 2>/dev/null | tar "${fallback[@]}" -C "${to}" 2>/dev/null
            )

        ;;
        *.tar)

            sys::has tar || return 1
            args=( -xf "${archive}" )

            for pat in "${exclude[@]}"; do
                [[ -n "${pat}" ]] && args+=( "--exclude=${pat}" )
            done

            (( strip > 0 )) && args+=( "--strip-components=${strip}" )
            tar "${args[@]}" -C "${to}" 2>/dev/null

        ;;
        *.zip)

            if sys::has unzip; then

                args=( -qo "${archive}" -d "${to}" )

                if (( ${#exclude[@]} > 0 )); then

                    args+=( -x )

                    for pat in "${exclude[@]}"; do
                        [[ -n "${pat}" ]] && args+=( "${pat}" )
                    done

                fi

                unzip "${args[@]}" 2>/dev/null || return 1
                (( strip > 0 )) && { path::strip "${to}" "${strip}" 2>/dev/null || return 1; }

                printf '%s\n' "${to}";
                return 0

            fi
            if sys::has 7z; then

                args=( x -bd -y "-o${to}" "${archive}" )

                for pat in "${exclude[@]}"; do
                    [[ -n "${pat}" ]] && args+=( "-xr!${pat}" )
                done

                7z "${args[@]}" >/dev/null 2>&1 || return 1
                (( strip > 0 )) && { path::strip "${to}" "${strip}" 2>/dev/null || return 1; }

                printf '%s\n' "${to}";
                return 0

            fi
            if sys::has bsdtar; then

                bsdtar -xf "${archive}" -C "${to}" 2>/dev/null || return 1
                (( strip > 0 )) && { path::strip "${to}" "${strip}" 2>/dev/null || return 1; }

                printf '%s\n' "${to}";
                return 0

            fi

            return 1

        ;;
        *.rar)

            if sys::has unrar; then

                args=( x -idq -y )

                for pat in "${exclude[@]}"; do
                    [[ -n "${pat}" ]] && args+=( "-x${pat}" )
                done

                args+=( "${archive}" "${to}/" )

                unrar "${args[@]}" >/dev/null 2>&1 || return 1
                (( strip > 0 )) && { path::strip "${to}" "${strip}" 2>/dev/null || return 1; }

                printf '%s\n' "${to}";
                return 0

            fi
            if sys::has 7z; then

                args=( x -bd -y "-o${to}" "${archive}" )

                for pat in "${exclude[@]}"; do
                    [[ -n "${pat}" ]] && args+=( "-xr!${pat}" )
                done

                7z "${args[@]}" >/dev/null 2>&1 || return 1
                (( strip > 0 )) && { path::strip "${to}" "${strip}" 2>/dev/null || return 1; }

                printf '%s\n' "${to}";
                return 0

            fi

            return 1

        ;;
        *.7z)

            sys::has 7z || return 1
            args=( x -bd -y "-o${to}" "${archive}" )

            for pat in "${exclude[@]}"; do
                [[ -n "${pat}" ]] && args+=( "-xr!${pat}" )
            done

            7z "${args[@]}" >/dev/null 2>&1 || return 1
            (( strip > 0 )) && { path::strip "${to}" "${strip}" 2>/dev/null || return 1; }

            printf '%s\n' "${to}";
            return 0

        ;;
        *)
            return 1
        ;;
    esac || return 1

    printf '%s\n' "${to}"

}
path::sync () {

    local from="${1:-}" to="${2:-}" parent=""

    path::exists "${from}" || return 1
    path::valid "${to}" || return 1
    path::is_root "${to}" && return 1

    [[ "${from%/}" != "${to%/}" ]] || return 1

    if [[ -d "${from}" && ! -L "${from}" ]]; then

        if sys::has rsync; then

            mkdir -p -- "${to}" 2>/dev/null || mkdir -p "${to}" 2>/dev/null || return 1

            rsync -a --delete -- "${from%/}/" "${to%/}/" >/dev/null 2>&1 ||
            rsync -a --delete "${from%/}/" "${to%/}/" >/dev/null 2>&1

            return

        fi

        path::remove "${to}" || return 1
        path::copy "${from}" "${to}"
        return

    fi

    parent="$(path::dirname "${to}")" || return 1
    mkdir -p -- "${parent}" 2>/dev/null || mkdir -p "${parent}" 2>/dev/null || return 1

    path::copy "${from}" "${to}"

}
path::watch () {

    local p="${1:-}" interval="${2:-1}" callback="${3:-}" once="${4:-0}" on_error="${5:-abort}" prev="" cur="" stat_kind="" _
    local -a recurse=()

    path::valid "${p}" || return 1

    [[ "${interval}" =~ ^[0-9]+([.][0-9]+)?$ ]] && [[ ! "${interval}" =~ ^0+([.]0+)?$ ]] || interval=1

    case "${once}" in
        1|true|yes|on|once) once=1 ;;
        *) once=0 ;;
    esac
    case "${on_error}" in
        abort|continue) ;;
        *) on_error="abort" ;;
    esac

    if sys::has inotifywait; then

        while :; do

            if [[ ! -e "${p}" && ! -L "${p}" ]]; then
                sleep "${interval}" 2>/dev/null || return 1
                continue
            fi

            recurse=()
            [[ -d "${p}" && ! -L "${p}" ]] && recurse=( -r )

            if (( once == 1 )); then

                inotifywait "${recurse[@]}" -q -e close_write,create,delete,move,attrib -- "${p}" >/dev/null 2>&1 || {
                    sleep "${interval}" 2>/dev/null || return 1
                    continue
                }

                if [[ -n "${callback}" ]]; then "${callback}" "${p}" || return 1
                else printf '%s\n' "${p}"
                fi

                return 0

            fi

            while IFS= read -r _; do

                if [[ -n "${callback}" ]]; then "${callback}" "${p}" || { [[ "${on_error}" == "continue" ]] || return 1; }
                else printf '%s\n' "${p}"
                fi

            done < <(inotifywait -m "${recurse[@]}" -q -e close_write,create,delete,move,attrib -- "${p}" 2>/dev/null)

            sleep "${interval}" 2>/dev/null || return 1

        done

    fi
    if sys::has fswatch; then

        while :; do

            if [[ ! -e "${p}" && ! -L "${p}" ]]; then
                sleep "${interval}" 2>/dev/null || return 1
                continue
            fi
            if (( once == 1 )); then

                fswatch -1 \
                    --event Created \
                    --event Updated \
                    --event Removed \
                    --event Renamed \
                    --event MovedFrom \
                    --event MovedTo \
                    --event AttributeModified \
                    -- "${p}" >/dev/null 2>&1 || {
                    sleep "${interval}" 2>/dev/null || return 1
                    continue
                }

                if [[ -n "${callback}" ]]; then "${callback}" "${p}" || return 1
                else printf '%s\n' "${p}"
                fi

                return 0

            fi

            while IFS= read -r _; do

                if [[ -n "${callback}" ]]; then "${callback}" "${p}" || { [[ "${on_error}" == "continue" ]] || return 1; }
                else printf '%s\n' "${p}"
                fi

            done < <(
                fswatch \
                    --event Created \
                    --event Updated \
                    --event Removed \
                    --event Renamed \
                    --event MovedFrom \
                    --event MovedTo \
                    --event AttributeModified \
                    -- "${p}" 2>/dev/null
            )

            sleep "${interval}" 2>/dev/null || return 1

        done

    fi
    if sys::has stat; then

        if stat -c '%s' -- /dev/null >/dev/null 2>&1; then stat_kind="gnu"
        elif stat -f '%z' -- /dev/null >/dev/null 2>&1; then stat_kind="bsd"
        else stat_kind=""
        fi

    fi

    while :; do

        if [[ -d "${p}" && ! -L "${p}" ]]; then

            if sys::has find && [[ "${stat_kind}" == "gnu" ]]; then
                cur="$(
                    {
                        stat -c '%n|%s|%Y|%F' -- "${p}" 2>/dev/null
                        find "${p}" -mindepth 1 -printf '%p|%s|%T@|%y\n' 2>/dev/null
                    } | LC_ALL=C sort 2>/dev/null
                )"

            elif sys::has find && [[ "${stat_kind}" == "bsd" ]]; then
                cur="$(
                    {
                        stat -f '%N|%z|%m|%HT' -- "${p}" 2>/dev/null
                        find "${p}" -mindepth 1 -print0 2>/dev/null |
                            xargs -0 stat -f '%N|%z|%m|%HT' 2>/dev/null
                    } | LC_ALL=C sort 2>/dev/null
                )"

            elif sys::has find; then
                cur="$(
                    {
                        printf '%s\n' "${p}"
                        find "${p}" -mindepth 1 -print 2>/dev/null
                    } | LC_ALL=C sort 2>/dev/null
                )"

            else
                cur="$(LC_ALL=C ls -laR "${p}" 2>/dev/null || true)"
            fi

        else

            if [[ -e "${p}" || -L "${p}" ]]; then
                case "${stat_kind}" in
                    gnu) cur="$(stat -c '%n|%s|%Y|%F' -- "${p}" 2>/dev/null || printf '%s\n' "${p}")" ;;
                    bsd) cur="$(stat -f '%N|%z|%m|%HT' -- "${p}" 2>/dev/null || printf '%s\n' "${p}")" ;;
                    *)   cur="$(LC_ALL=C ls -la "${p}" 2>/dev/null || printf '%s\n' "${p}")" ;;
                esac
            else
                cur="__missing__:${p}"
            fi

        fi

        if [[ "${cur}" != "${prev}" ]]; then

            if [[ -n "${prev}" ]]; then

                if [[ -n "${callback}" ]]; then "${callback}" "${p}" || { [[ "${on_error}" == "continue" ]] || return 1; }
                else printf '%s\n' "${p}"
                fi

                (( once == 1 )) && return 0

            fi

            prev="${cur}"

        fi

        sleep "${interval}" 2>/dev/null || return 1

    done

}
