
dir::has () {

    command -v "${1:-}" >/dev/null 2>&1

}
dir::valid () {

    local p="${1:-}"

    [[ -n "${p}" ]] || return 1
    [[ "${p}" != *$'\n'* && "${p}" != *$'\r'* ]] || return 1

    return 0

}
dir::exists () {

    local p="${1:-}"

    dir::valid "${p}" || return 1
    [[ -d "${p}" ]]

}
dir::missing () {

    local p="${1:-}"

    dir::valid "${p}" || return 1
    [[ ! -d "${p}" ]]

}
dir::empty () {

    local p="${1:-}" entry=""

    dir::valid "${p}" || return 1
    [[ -d "${p}" ]] || return 1

    for entry in "${p%/}"/* "${p%/}"/.[!.]* "${p%/}"/..?*; do
        [[ -e "${entry}" || -L "${entry}" ]] && return 1
    done

    return 0

}

dir::filled () {

    dir::empty "${1:-}" && return 1
    [[ -d "${1:-}" ]]

}
dir::is_root () {

    local p="${1:-}"

    dir::valid "${p}" || return 1

    [[ "${p}" == "/" ]] && return 0
    [[ "${p}" == "\\" ]] && return 0
    [[ "${p}" =~ ^[A-Za-z]:[\\/]?$ ]] && return 0

    return 1

}
dir::is_link () {

    local p="${1:-}"

    dir::valid "${p}" || return 1
    [[ -L "${p}" && -d "${p}" ]]

}
dir::readable () {

    local p="${1:-}"

    dir::valid "${p}" || return 1
    [[ -d "${p}" && -r "${p}" ]]

}
dir::writable () {

    local p="${1:-}"

    dir::valid "${p}" || return 1
    [[ -d "${p}" && -w "${p}" ]]

}
dir::executable () {

    local p="${1:-}"

    dir::valid "${p}" || return 1
    [[ -d "${p}" && -x "${p}" ]]

}

dir::cd () {

    local p="${1:-}"

    dir::exists "${p}" || return 1
    builtin cd -- "${p}" 2>/dev/null

}
dir::pushd () {

    local p="${1:-}"

    dir::exists "${p}" || return 1
    pushd -- "${p}" >/dev/null 2>&1

}
dir::popd () {

    popd >/dev/null 2>&1

}
dir::with () {

    local p="${1:-}"

    dir::exists "${p}" || return 1
    shift || true

    (( $# > 0 )) || return 1
    ( builtin cd -- "${p}" 2>/dev/null || exit 1; "$@" )

}
dir::size () {

    local p="${1:-}" v=""

    dir::exists "${p}" || return 1
    dir::has du || return 1

    v="$(du -sk -- "${p}" 2>/dev/null | awk 'NR==1 {print $1}' | head -n 1)"
    [[ "${v}" =~ ^[0-9]+$ ]] && { printf '%s\n' "$(( v * 1024 ))"; return 0; }

    v="$(du -sk "${p}" 2>/dev/null | awk 'NR==1 {print $1}' | head -n 1)"
    [[ "${v}" =~ ^[0-9]+$ ]] && { printf '%s\n' "$(( v * 1024 ))"; return 0; }

    return 1

}
dir::depth () {

    local p="${1:-}" current="" max=0 d=0 base_d=""

    dir::exists "${p}" || return 1
    dir::has find || return 1

    while IFS= read -r current; do

        d="${current//[^\/]//}"
        d="${#d}"

        (( d > max )) && max="${d}"

    done < <(find "${p}" -type d 2>/dev/null)

    base_d="${p//[^\/]//}"
    printf '%s\n' "$(( max - ${#base_d} ))"

}
dir::dirname () {

    local p="${1:-}" dir=""

    dir::valid "${p}" || return 1
    p="${p//\\//}"

    [[ "${p}" != */* ]] && { printf '.'; return 0; }

    dir="${p%/*}"
    [[ -n "${dir}" ]] || dir="/"

    printf '%s' "${dir}"

}
dir::basename () {

    local p="${1:-}"

    dir::valid "${p}" || return 1
    p="${p//\\//}"

    while [[ "${p}" == */ && ${#p} -gt 1 ]]; do
        p="${p%/}"
    done

    printf '%s' "${p##*/}"

}

dir::ensure () {

    local p="${1:-}" mode="${2:-}"

    dir::valid "${p}" || return 1

    [[ -d "${p}" && -z "${mode}" ]] && return 0
    [[ -d "${p}" ]] && { chmod "${mode}" "${p}" 2>/dev/null || return 1; return 0; }
    [[ -e "${p}" || -L "${p}" ]] && return 1

    mkdir -p -- "${p}" 2>/dev/null || mkdir -p "${p}" 2>/dev/null || return 1
    [[ -n "${mode}" ]] && { chmod "${mode}" "${p}" 2>/dev/null || return 1; }

    return 0

}
dir::remove () {

    local p="${1:-}"

    dir::valid "${p}" || return 1
    dir::is_root "${p}" && return 1

    [[ -d "${p}" || -L "${p}" ]] || return 0
    [[ -L "${p}" ]] && { rm -f -- "${p}" 2>/dev/null || rm -f "${p}" 2>/dev/null; return; }

    rm -rf -- "${p}" 2>/dev/null || rm -rf "${p}" 2>/dev/null

}
dir::clear () {

    local p="${1:-}" entry=""

    dir::exists "${p}" || return 1
    dir::is_root "${p}" && return 1

    for entry in "${p%/}"/* "${p%/}"/.[!.]* "${p%/}"/..?*; do

        [[ -e "${entry}" || -L "${entry}" ]] || continue
        rm -rf -- "${entry}" 2>/dev/null || rm -rf "${entry}" 2>/dev/null || return 1

    done

    return 0

}
dir::copy () {

    local from="${1:-}" to="${2:-}" parent=""

    dir::valid "${to}" || return 1
    dir::exists "${from}" || return 1
    dir::has cp || return 1

    parent="$(dir::dirname "${to}")" || return 1
    [[ -d "${parent}" ]] || dir::ensure "${parent}" || return 1

    if [[ -d "${to}" ]]; then cp -R -- "${from%/}/." "${to%/}/" 2>/dev/null || cp -R "${from%/}/." "${to%/}/" 2>/dev/null
    else cp -R -- "${from}" "${to}" 2>/dev/null || cp -R "${from}" "${to}" 2>/dev/null
    fi

}
dir::move () {

    local from="${1:-}" to="${2:-}" parent=""

    dir::valid "${to}" || return 1
    dir::exists "${from}" || return 1
    dir::is_root "${from}" && return 1

    dir::has mv || return 1

    parent="$(dir::dirname "${to}")" || return 1
    [[ -d "${parent}" ]] || dir::ensure "${parent}" || return 1

    mv -f -- "${from}" "${to}" 2>/dev/null || mv -f "${from}" "${to}" 2>/dev/null

}
dir::rename () {

    dir::move "$@"

}

dir::glob () {

    local p="${1:-}" pattern="${2:-*}" old_nullglob="" old_dotglob="" entry="" base=""
    local -a matches=()

    dir::exists "${p}" || return 1
    [[ -n "${pattern}" ]] || return 1

    old_nullglob="$(shopt -p nullglob)"
    old_dotglob="$(shopt -p dotglob)"

    shopt -s nullglob
    case "${pattern}" in .*) shopt -s dotglob ;; esac

    for entry in "${p%/}"/${pattern}; do

        [[ -e "${entry}" || -L "${entry}" ]] || continue
        base="$(dir::basename "${entry}")" || return 1

        [[ -n "${base}" ]] && matches+=( "${base}" )

    done

    eval "${old_nullglob}"
    eval "${old_dotglob}"

    (( ${#matches[@]} > 0 )) || return 0

    if dir::has sort; then printf '%s\n' "${matches[@]}" | LC_ALL=C sort
    else printf '%s\n' "${matches[@]}"
    fi

}
dir::in_glob () {

    local p="${1:-}" pattern="${2:-}" old_nullglob="" old_dotglob="" entry="" found=1

    dir::exists "${p}" || return 1
    [[ -n "${pattern}" ]] || return 1

    old_nullglob="$(shopt -p nullglob)"
    old_dotglob="$(shopt -p dotglob)"

    shopt -s nullglob
    case "${pattern}" in .*) shopt -s dotglob ;; esac

    for entry in "${p%/}"/${pattern}; do
        [[ -e "${entry}" || -L "${entry}" ]] && { found=0; break; }
    done

    eval "${old_nullglob}"
    eval "${old_dotglob}"

    return "${found}"

}
dir::find () {

    local p="${1:-}" name="${2:-*}" type="${3:-any}" depth="${4:-}" find_type=""

    dir::exists "${p}" || return 1
    dir::has find || return 1

    [[ -n "${depth}" && ! "${depth}" =~ ^[0-9]+$ ]] && return 1

    case "${type}" in
        ""|any) find_type="" ;;
        file)   find_type="-type f" ;;
        dir)    find_type="-type d" ;;
        link)   find_type="-type l" ;;
        *)      return 1 ;;
    esac

    if [[ -n "${depth}" ]]; then find "${p}" -mindepth 1 -maxdepth "${depth}" ${find_type} -name "${name}" 2>/dev/null
    else find "${p}" -mindepth 1 ${find_type} -name "${name}" 2>/dev/null
    fi

}
dir::find_files () {

    dir::find "${1:-}" "${2:-*}" file "${3:-}"

}
dir::find_dirs () {

    dir::find "${1:-}" "${2:-*}" dir "${3:-}"

}
dir::find_links () {

    dir::find "${1:-}" "${2:-*}" link "${3:-}"

}
dir::walk () {

    local p="${1:-}"

    dir::exists "${p}" || return 1
    dir::has find || return 1

    find "${p}" -mindepth 1 2>/dev/null

}
dir::walk_files () {

    local p="${1:-}"

    dir::exists "${p}" || return 1
    dir::has find || return 1

    find "${p}" -mindepth 1 -type f 2>/dev/null

}
dir::walk_dirs () {

    local p="${1:-}"

    dir::exists "${p}" || return 1
    dir::has find || return 1

    find "${p}" -mindepth 1 -type d 2>/dev/null

}
dir::walk_links () {

    local p="${1:-}"

    dir::exists "${p}" || return 1
    dir::has find || return 1

    find "${p}" -mindepth 1 -type l 2>/dev/null

}

dir::list () {

    local p="${1:-}" sort="${2:-name}" entry="" base=""
    local -a names=()

    dir::exists "${p}" || return 1

    for entry in "${p%/}"/* "${p%/}"/.[!.]* "${p%/}"/..?*; do

        [[ -e "${entry}" || -L "${entry}" ]] || continue
        base="$(dir::basename "${entry}")" || return 1

        [[ -n "${base}" ]] && names+=( "${base}" )

    done

    (( ${#names[@]} > 0 )) || return 0

    case "${sort}" in
        name|"")
            if dir::has sort; then printf '%s\n' "${names[@]}" | LC_ALL=C sort
            else printf '%s\n' "${names[@]}"
            fi
        ;;
        none)
            printf '%s\n' "${names[@]}"
        ;;
        reverse|desc)
            if dir::has sort; then printf '%s\n' "${names[@]}" | LC_ALL=C sort -r
            else printf '%s\n' "${names[@]}"
            fi
        ;;
        *)
            return 1
        ;;
    esac

}
dir::list_paths () {

    local p="${1:-}" name=""

    dir::exists "${p}" || return 1

    while IFS= read -r name; do
        printf '%s/%s\n' "${p%/}" "${name}"
    done < <(dir::list "${p}")

}
dir::list_files () {

    local p="${1:-}" entry="" base=""
    local -a names=()

    dir::exists "${p}" || return 1

    for entry in "${p%/}"/* "${p%/}"/.[!.]* "${p%/}"/..?*; do

        [[ -f "${entry}" && ! -L "${entry}" ]] || continue
        base="$(dir::basename "${entry}")" || return 1

        [[ -n "${base}" ]] && names+=( "${base}" )

    done

    (( ${#names[@]} > 0 )) || return 0

    if dir::has sort; then printf '%s\n' "${names[@]}" | LC_ALL=C sort
    else printf '%s\n' "${names[@]}"
    fi

}
dir::list_dirs () {

    local p="${1:-}" entry="" base=""
    local -a names=()

    dir::exists "${p}" || return 1

    for entry in "${p%/}"/* "${p%/}"/.[!.]* "${p%/}"/..?*; do

        [[ -d "${entry}" && ! -L "${entry}" ]] || continue
        base="$(dir::basename "${entry}")" || return 1

        [[ -n "${base}" ]] && names+=( "${base}" )

    done

    (( ${#names[@]} > 0 )) || return 0

    if dir::has sort; then printf '%s\n' "${names[@]}" | LC_ALL=C sort
    else printf '%s\n' "${names[@]}"
    fi

}
dir::list_links () {

    local p="${1:-}" entry="" base=""
    local -a names=()

    dir::exists "${p}" || return 1

    for entry in "${p%/}"/* "${p%/}"/.[!.]* "${p%/}"/..?*; do

        [[ -L "${entry}" ]] || continue
        base="$(dir::basename "${entry}")" || return 1

        [[ -n "${base}" ]] && names+=( "${base}" )

    done

    (( ${#names[@]} > 0 )) || return 0

    if dir::has sort; then printf '%s\n' "${names[@]}" | LC_ALL=C sort
    else printf '%s\n' "${names[@]}"
    fi

}
dir::list_hidden () {

    local p="${1:-}" entry="" base=""
    local -a names=()

    dir::exists "${p}" || return 1

    for entry in "${p%/}"/.[!.]* "${p%/}"/..?*; do

        [[ -e "${entry}" || -L "${entry}" ]] || continue
        base="$(dir::basename "${entry}")" || return 1

        [[ -n "${base}" ]] && names+=( "${base}" )

    done

    (( ${#names[@]} > 0 )) || return 0

    if dir::has sort; then printf '%s\n' "${names[@]}" | LC_ALL=C sort
    else printf '%s\n' "${names[@]}"
    fi

}

dir::count () {

    local p="${1:-}" entry="" n=0

    dir::exists "${p}" || return 1

    for entry in "${p%/}"/* "${p%/}"/.[!.]* "${p%/}"/..?*; do

        [[ -e "${entry}" || -L "${entry}" ]] || continue
        n=$(( n + 1 ))

    done

    printf '%s\n' "${n}"

}
dir::count_files () {

    local p="${1:-}" entry="" n=0

    dir::exists "${p}" || return 1

    for entry in "${p%/}"/* "${p%/}"/.[!.]* "${p%/}"/..?*; do

        [[ -f "${entry}" && ! -L "${entry}" ]] || continue
        n=$(( n + 1 ))

    done

    printf '%s\n' "${n}"

}
dir::count_dirs () {

    local p="${1:-}" entry="" n=0

    dir::exists "${p}" || return 1

    for entry in "${p%/}"/* "${p%/}"/.[!.]* "${p%/}"/..?*; do

        [[ -d "${entry}" && ! -L "${entry}" ]] || continue
        n=$(( n + 1 ))

    done

    printf '%s\n' "${n}"

}
dir::count_links () {

    local p="${1:-}" entry="" n=0

    dir::exists "${p}" || return 1

    for entry in "${p%/}"/* "${p%/}"/.[!.]* "${p%/}"/..?*; do

        [[ -L "${entry}" ]] || continue
        n=$(( n + 1 ))

    done

    printf '%s\n' "${n}"

}
dir::count_hidden () {

    local p="${1:-}" entry="" n=0

    dir::exists "${p}" || return 1

    for entry in "${p%/}"/.[!.]* "${p%/}"/..?*; do

        [[ -L "${entry}" ]] || continue
        n=$(( n + 1 ))

    done

    printf '%s\n' "${n}"

}
dir::count_recursive () {

    local p="${1:-}" n=0

    dir::exists "${p}" || return 1

    if dir::has find; then
        n="$(find "${p}" -mindepth 1 2>/dev/null | wc -l | tr -d '[:space:]')"
        [[ "${n}" =~ ^[0-9]+$ ]] && { printf '%s\n' "${n}"; return 0; }
    fi

    while IFS= read -r _; do
        n=$(( n + 1 ))
    done < <(dir::walk "${p}")

    printf '%s\n' "${n}"

}

dir::contains () {

    local parent="${1:-}" name="${2:-}"

    dir::exists "${parent}" || return 1
    [[ -n "${name}" ]] || return 1

    [[ -e "${parent%/}/${name}" || -L "${parent%/}/${name}" ]]

}
dir::contains_file () {

    local parent="${1:-}" name="${2:-}"

    dir::exists "${parent}" || return 1
    [[ -n "${name}" ]] || return 1

    [[ -f "${parent%/}/${name}" ]]

}
dir::contains_dir () {

    local parent="${1:-}" name="${2:-}"

    dir::exists "${parent}" || return 1
    [[ -n "${name}" ]] || return 1

    [[ -d "${parent%/}/${name}" ]]

}
dir::contains_link () {

    local parent="${1:-}" name="${2:-}"

    dir::exists "${parent}" || return 1
    [[ -n "${name}" ]] || return 1

    [[ -L "${parent%/}/${name}" ]]

}
dir::contains_hidden () {

    local parent="${1:-}" name="${2:-}"

    dir::exists "${parent}" || return 1
    [[ -n "${name}" ]] || return 1

    [[ "${name}" == .* ]] || name=".${name}"
    [[ "${name}" != "." && "${name}" != ".." ]] || return 1

    [[ -e "${parent%/}/${name}" || -L "${parent%/}/${name}" ]]

}

dir::chain () {

    local cur=""

    (( $# > 0 )) || return 1

    for cur in "$@"; do
        dir::ensure "${cur}" || return 1
    done

}
dir::touch () {

    local p="${1:-}" name="" entry=""

    dir::exists "${p}" || return 1
    shift || true

    (( $# > 0 )) || return 1

    for name in "$@"; do

        [[ -n "${name}" ]] || return 1

        entry="${p%/}/${name}"
        : > "${entry}" 2>/dev/null || touch -- "${entry}" 2>/dev/null || touch "${entry}" 2>/dev/null || return 1

    done

}
dir::sync () {

    local from="${1:-}" to="${2:-}"

    dir::exists "${from}" || return 1
    dir::valid "${to}" || return 1
    dir::is_root "${to}" && return 1

    [[ "${from%/}" != "${to%/}" ]] || return 1

    if dir::has rsync; then

        dir::ensure "${to}" || return 1

        rsync -a --delete -- "${from%/}/" "${to%/}/" >/dev/null 2>&1 ||
        rsync -a --delete "${from%/}/" "${to%/}/" >/dev/null 2>&1

        return

    fi

    dir::remove "${to}" || return 1
    dir::copy "${from}" "${to}"

}
dir::watch () {

    local p="${1:-}" interval="${2:-1}" prev="" cur=""

    dir::exists "${p}" || return 1
    [[ "${interval}" =~ ^[0-9]+([.][0-9]+)?$ ]] || interval=1

    while :; do

        if dir::has sha1sum; then cur="$(dir::walk "${p}" 2>/dev/null | sha1sum 2>/dev/null | awk '{print $1}')"
        elif dir::has shasum; then cur="$(dir::walk "${p}" 2>/dev/null | shasum 2>/dev/null | awk '{print $1}')"
        else cur="$(dir::walk "${p}" 2>/dev/null)"
        fi

        if [[ "${cur}" != "${prev}" ]]; then
            [[ -n "${prev}" ]] && return 0
            prev="${cur}"
        fi

        sleep "${interval}" 2>/dev/null || return 1

    done

}
