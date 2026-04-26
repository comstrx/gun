
dir::has () {

    command -v "${1:-}" >/dev/null 2>&1

}
dir::die () {

    local msg="${1:-}" code="${2:-1}"

    [[ "${code}" =~ ^[0-9]+$ ]] || code=1
    [[ -n "${msg}" ]] && printf '[ERR] %s\n' "${msg}" >&2
    [[ "${-}" == *i* ]] && return "${code}"

    exit "${code}"

}
dir::valid () {

    local p="${1-}"

    [[ -n "${p}" ]] || return 1
    [[ "${p}" != *$'\n'* && "${p}" != *$'\r'* ]] || return 1

    return 0

}

dir::exists () {

    local p="${1-}"

    dir::valid "${p}" || return 1
    [[ -d "${p}" ]]

}
dir::missing () {

    local p="${1-}"

    dir::valid "${p}" || return 1
    [[ ! -d "${p}" ]]

}
dir::is_link () {

    local p="${1-}"

    dir::valid "${p}" || return 1
    [[ -L "${p}" && -d "${p}" ]]

}
dir::readable () {

    local p="${1-}"

    dir::valid "${p}" || return 1
    [[ -d "${p}" && -r "${p}" ]]

}
dir::writable () {

    local p="${1-}"

    dir::valid "${p}" || return 1
    [[ -d "${p}" && -w "${p}" ]]

}
dir::executable () {

    local p="${1-}"

    dir::valid "${p}" || return 1
    [[ -d "${p}" && -x "${p}" ]]

}
dir::traversable () {

    dir::executable "$@"

}

dir::is_empty () {

    local p="${1-}" entry=""

    dir::valid "${p}" || return 1
    [[ -d "${p}" ]] || return 1

    for entry in "${p}"/* "${p}"/.[!.]* "${p}"/..?*; do
        [[ -e "${entry}" || -L "${entry}" ]] && return 1
    done

    return 0

}
dir::is_filled () {

    dir::is_empty "${1-}" && return 1
    [[ -d "${1-}" ]]

}
dir::is_root () {

    local p="${1-}"

    dir::valid "${p}" || return 1
    [[ -d "${p}" ]] || return 1

    [[ "${p}" == "/" ]] && return 0
    [[ "${p}" =~ ^[A-Za-z]:[\\/]?$ ]] && return 0

    return 1

}

dir::make () {

    local p="${1-}" mode="${2:-}"

    dir::valid "${p}" || return 1

    if [[ -d "${p}" ]]; then
        [[ -n "${mode}" ]] && chmod -- "${mode}" "${p}" 2>/dev/null
        return 0
    fi
    if [[ -e "${p}" || -L "${p}" ]]; then
        return 1
    fi

    mkdir -p -- "${p}" 2>/dev/null || return 1

    if [[ -n "${mode}" ]]; then
        chmod -- "${mode}" "${p}" 2>/dev/null || return 1
    fi

    return 0

}
dir::ensure () {

    dir::make "$@"

}
dir::make_temp () {

    path::mktemp_dir "$@"

}

dir::remove () {

    local p="${1-}"

    dir::valid "${p}" || return 1

    [[ -d "${p}" || -L "${p}" ]] || return 0
    [[ -L "${p}" ]] && { rm -f -- "${p}" 2>/dev/null; return; }

    rm -rf -- "${p}" 2>/dev/null

}
dir::clear () {

    local p="${1-}" entry=""

    dir::valid "${p}" || return 1
    [[ -d "${p}" ]] || return 1

    for entry in "${p}"/* "${p}"/.[!.]* "${p}"/..?*; do
        [[ -e "${entry}" || -L "${entry}" ]] || continue
        rm -rf -- "${entry}" 2>/dev/null || return 1
    done

    return 0

}
dir::clean () {

    dir::clear "$@"

}

dir::copy () {

    local from="${1-}" to="${2-}" parent=""

    dir::valid "${from}" || return 1
    dir::valid "${to}" || return 1

    [[ -d "${from}" ]] || return 1
    sys::has cp || return 1

    parent="$(path::dir "${to}" 2>/dev/null || true)"
    [[ -n "${parent}" && -d "${parent}" ]] || mkdir -p -- "${parent}" 2>/dev/null || return 1

    if [[ -d "${to}" ]]; then cp -R -- "${from}/." "${to}/" 2>/dev/null
    else cp -R -- "${from}" "${to}" 2>/dev/null
    fi

}
dir::sync () {

    local from="${1-}" to="${2-}"

    dir::valid "${from}" || return 1
    dir::valid "${to}" || return 1

    [[ -d "${from}" ]] || return 1

    if sys::has rsync; then
        rsync -a --delete -- "${from%/}/" "${to%/}/" >/dev/null 2>&1
        return
    fi

    dir::remove "${to}" || return 1
    dir::copy "${from}" "${to}"

}
dir::move () {

    local from="${1-}" to="${2-}"

    dir::valid "${from}" || return 1
    dir::valid "${to}" || return 1

    [[ -d "${from}" ]] || return 1
    sys::has mv || return 1

    mv -f -- "${from}" "${to}" 2>/dev/null

}
dir::rename () {

    dir::move "$@"

}

dir::list () {

    local p="${1-}" sort="${2:-name}" entry="" base=""
    local -a names=()

    dir::valid "${p}" || return 1
    [[ -d "${p}" ]] || return 1

    for entry in "${p}"/* "${p}"/.[!.]* "${p}"/..?*; do
        [[ -e "${entry}" || -L "${entry}" ]] || continue
        base="$(path::base "${entry}" 2>/dev/null || true)"
        [[ -n "${base}" ]] && names+=( "${base}" )
    done

    (( ${#names[@]} > 0 )) || return 0

    case "${sort}" in
        name|"")
            if sys::has sort; then printf '%s\n' "${names[@]}" | LC_ALL=C sort
            else printf '%s\n' "${names[@]}"
            fi
        ;;
        none) printf '%s\n' "${names[@]}" ;;
        reverse|desc)
            if sys::has sort; then printf '%s\n' "${names[@]}" | LC_ALL=C sort -r
            else printf '%s\n' "${names[@]}"
            fi
        ;;
        *) return 1 ;;
    esac

}
dir::list_all () {

    local p="${1-}" entry="" base=""
    local -a names=()

    dir::valid "${p}" || return 1
    [[ -d "${p}" ]] || return 1

    for entry in "${p}"/* "${p}"/.[!.]* "${p}"/..?*; do
        [[ -e "${entry}" || -L "${entry}" ]] || continue
        base="$(path::base "${entry}" 2>/dev/null || true)"
        [[ -n "${base}" ]] && names+=( "${base}" )
    done

    (( ${#names[@]} > 0 )) || return 0

    if sys::has sort; then printf '%s\n' "${names[@]}" | LC_ALL=C sort
    else printf '%s\n' "${names[@]}"
    fi

}
dir::list_files () {

    local p="${1-}" entry="" base=""
    local -a names=()

    dir::valid "${p}" || return 1
    [[ -d "${p}" ]] || return 1

    for entry in "${p}"/* "${p}"/.[!.]*; do
        [[ -f "${entry}" && ! -L "${entry}" ]] || continue
        base="$(path::base "${entry}" 2>/dev/null || true)"
        [[ -n "${base}" ]] && names+=( "${base}" )
    done

    (( ${#names[@]} > 0 )) || return 0

    if sys::has sort; then printf '%s\n' "${names[@]}" | LC_ALL=C sort
    else printf '%s\n' "${names[@]}"
    fi

}
dir::list_dirs () {

    local p="${1-}" entry="" base=""
    local -a names=()

    dir::valid "${p}" || return 1
    [[ -d "${p}" ]] || return 1

    for entry in "${p}"/* "${p}"/.[!.]*; do
        [[ -d "${entry}" && ! -L "${entry}" ]] || continue
        base="$(path::base "${entry}" 2>/dev/null || true)"
        [[ -n "${base}" ]] && names+=( "${base}" )
    done

    (( ${#names[@]} > 0 )) || return 0

    if sys::has sort; then printf '%s\n' "${names[@]}" | LC_ALL=C sort
    else printf '%s\n' "${names[@]}"
    fi

}
dir::list_links () {

    local p="${1-}" entry="" base=""
    local -a names=()

    dir::valid "${p}" || return 1
    [[ -d "${p}" ]] || return 1

    for entry in "${p}"/* "${p}"/.[!.]*; do
        [[ -L "${entry}" ]] || continue
        base="$(path::base "${entry}" 2>/dev/null || true)"
        [[ -n "${base}" ]] && names+=( "${base}" )
    done

    (( ${#names[@]} > 0 )) || return 0

    if sys::has sort; then printf '%s\n' "${names[@]}" | LC_ALL=C sort
    else printf '%s\n' "${names[@]}"
    fi

}
dir::list_hidden () {

    local p="${1-}" entry="" base=""
    local -a names=()

    dir::valid "${p}" || return 1
    [[ -d "${p}" ]] || return 1

    for entry in "${p}"/.[!.]* "${p}"/..?*; do
        [[ -e "${entry}" || -L "${entry}" ]] || continue
        base="$(path::base "${entry}" 2>/dev/null || true)"
        [[ -n "${base}" ]] && names+=( "${base}" )
    done

    (( ${#names[@]} > 0 )) || return 0

    if sys::has sort; then printf '%s\n' "${names[@]}" | LC_ALL=C sort
    else printf '%s\n' "${names[@]}"
    fi

}
dir::list_paths () {

    local p="${1-}" name=""

    dir::valid "${p}" || return 1
    [[ -d "${p}" ]] || return 1

    while IFS= read -r name; do
        printf '%s/%s\n' "${p%/}" "${name}"
    done < <(dir::list "${p}")

}

dir::glob () {

    local p="${1-}" pattern="${2:-*}" old_nullglob="" old_dotglob="" entry="" base=""
    local -a matches=()

    dir::valid "${p}" || return 1
    [[ -d "${p}" ]] || return 1
    [[ -n "${pattern}" ]] || return 1

    old_nullglob="$(shopt -p nullglob)"
    old_dotglob="$(shopt -p dotglob)"

    shopt -s nullglob

    case "${pattern}" in
        .*) shopt -s dotglob ;;
    esac

    for entry in "${p%/}"/${pattern}; do
        [[ -e "${entry}" || -L "${entry}" ]] || continue
        base="$(path::base "${entry}" 2>/dev/null || true)"
        [[ -n "${base}" ]] && matches+=( "${base}" )
    done

    eval "${old_nullglob}"
    eval "${old_dotglob}"

    (( ${#matches[@]} > 0 )) || return 0

    if sys::has sort; then printf '%s\n' "${matches[@]}" | LC_ALL=C sort
    else printf '%s\n' "${matches[@]}"
    fi

}
dir::find () {

    local p="${1-}" name="${2:-*}" type="${3:-any}" depth="${4:-}" find_type=""

    dir::valid "${p}" || return 1
    [[ -d "${p}" ]] || return 1

    sys::has find || return 1

    case "${type}" in
        any|"") find_type="" ;;
        file)   find_type="-type f" ;;
        dir)    find_type="-type d" ;;
        link)   find_type="-type l" ;;
        *)      return 1 ;;
    esac

    if [[ -n "${depth}" ]]; then
        [[ "${depth}" =~ ^[0-9]+$ ]] || return 1
        # shellcheck disable=SC2086
        find "${p}" -mindepth 1 -maxdepth "${depth}" ${find_type} -name "${name}" 2>/dev/null
    else
        # shellcheck disable=SC2086
        find "${p}" -mindepth 1 ${find_type} -name "${name}" 2>/dev/null
    fi

}
dir::find_files () {

    dir::find "${1-}" "${2:-*}" file "${3:-}"

}
dir::find_dirs () {

    dir::find "${1-}" "${2:-*}" dir "${3:-}"

}
dir::find_links () {

    dir::find "${1-}" "${2:-*}" link "${3:-}"

}
dir::walk () {

    local p="${1-}" entry=""

    dir::valid "${p}" || return 1
    [[ -d "${p}" ]] || return 1

    if sys::has find; then
        find "${p}" -mindepth 1 2>/dev/null
        return
    fi

    for entry in "${p%/}"/* "${p%/}"/.[!.]* "${p%/}"/..?*; do
        [[ -e "${entry}" || -L "${entry}" ]] || continue
        printf '%s\n' "${entry}"
        [[ -d "${entry}" && ! -L "${entry}" ]] && dir::walk "${entry}"
    done

}
dir::walk_files () {

    local p="${1-}"

    dir::valid "${p}" || return 1
    [[ -d "${p}" ]] || return 1

    if sys::has find; then
        find "${p}" -mindepth 1 -type f 2>/dev/null
        return
    fi

    while IFS= read -r entry; do
        [[ -f "${entry}" && ! -L "${entry}" ]] && printf '%s\n' "${entry}"
    done < <(dir::walk "${p}")

}
dir::walk_dirs () {

    local p="${1-}"

    dir::valid "${p}" || return 1
    [[ -d "${p}" ]] || return 1

    if sys::has find; then
        find "${p}" -mindepth 1 -type d 2>/dev/null
        return
    fi

    while IFS= read -r entry; do
        [[ -d "${entry}" && ! -L "${entry}" ]] && printf '%s\n' "${entry}"
    done < <(dir::walk "${p}")

}

dir::count () {

    local p="${1-}" entry="" n=0

    dir::valid "${p}" || return 1
    [[ -d "${p}" ]] || return 1

    for entry in "${p}"/* "${p}"/.[!.]* "${p}"/..?*; do
        [[ -e "${entry}" || -L "${entry}" ]] || continue
        n=$(( n + 1 ))
    done

    printf '%s\n' "${n}"

}
dir::count_files () {

    local p="${1-}" entry="" n=0

    dir::valid "${p}" || return 1
    [[ -d "${p}" ]] || return 1

    for entry in "${p}"/* "${p}"/.[!.]*; do
        [[ -f "${entry}" && ! -L "${entry}" ]] || continue
        n=$(( n + 1 ))
    done

    printf '%s\n' "${n}"

}
dir::count_dirs () {

    local p="${1-}" entry="" n=0

    dir::valid "${p}" || return 1
    [[ -d "${p}" ]] || return 1

    for entry in "${p}"/* "${p}"/.[!.]*; do
        [[ -d "${entry}" && ! -L "${entry}" ]] || continue
        n=$(( n + 1 ))
    done

    printf '%s\n' "${n}"

}
dir::count_links () {

    local p="${1-}" entry="" n=0

    dir::valid "${p}" || return 1
    [[ -d "${p}" ]] || return 1

    for entry in "${p}"/* "${p}"/.[!.]*; do
        [[ -L "${entry}" ]] || continue
        n=$(( n + 1 ))
    done

    printf '%s\n' "${n}"

}
dir::count_recursive () {

    local p="${1-}" n=0

    dir::valid "${p}" || return 1
    [[ -d "${p}" ]] || return 1

    if sys::has find; then
        n="$(find "${p}" -mindepth 1 2>/dev/null | wc -l | tr -d '[:space:]')"
        [[ "${n}" =~ ^[0-9]+$ ]] && { printf '%s\n' "${n}"; return 0; }
    fi

    while IFS= read -r _; do
        n=$(( n + 1 ))
    done < <(dir::walk "${p}")

    printf '%s\n' "${n}"

}
dir::size () {

    local p="${1-}" v=""

    dir::valid "${p}" || return 1
    [[ -d "${p}" ]] || return 1

    if sys::has du; then
        v="$(du -sk -- "${p}" 2>/dev/null | awk 'NR==1 {print $1}' | head -n 1)"
        [[ "${v}" =~ ^[0-9]+$ ]] && { printf '%s\n' "$(( v * 1024 ))"; return 0; }
    fi

    return 1

}
dir::depth () {

    local p="${1-}" current="" max=0 d=0

    dir::valid "${p}" || return 1
    [[ -d "${p}" ]] || return 1

    if sys::has find; then

        while IFS= read -r current; do

            d="${current//[!\/]/}"
            d="${#d}"

            (( d > max )) && max="${d}"

        done < <(find "${p}" -type d 2>/dev/null)

        local base_d="${p//[!\/]/}"
        printf '%s\n' "$(( max - ${#base_d} ))"
        return 0

    fi

    return 1

}

dir::cd () {

    local p="${1-}" rc=0

    dir::valid "${p}" || return 1
    [[ -d "${p}" ]] || return 1

    # shellcheck disable=SC2164
    cd -- "${p}" 2>/dev/null
    rc=$?

    return "${rc}"

}
dir::pushd () {

    local p="${1-}" rc=0

    dir::valid "${p}" || return 1
    [[ -d "${p}" ]] || return 1

    # shellcheck disable=SC2164
    pushd -- "${p}" >/dev/null 2>&1
    rc=$?

    return "${rc}"

}
dir::popd () {

    local rc=0

    # shellcheck disable=SC2164
    popd >/dev/null 2>&1
    rc=$?

    return "${rc}"

}
dir::with () {

    local p="${1-}" rc=0

    dir::valid "${p}" || return 1
    [[ -d "${p}" ]] || return 1
    shift || true

    (( $# > 0 )) || return 1

    (
        cd -- "${p}" 2>/dev/null || exit 1
        "$@"
    )

    rc=$?
    return "${rc}"

}

dir::contains () {

    local parent="${1-}" name="${2-}"

    dir::valid "${parent}" || return 1
    [[ -d "${parent}" ]] || return 1
    [[ -n "${name}" ]] || return 1

    [[ -e "${parent%/}/${name}" || -L "${parent%/}/${name}" ]]

}
dir::contains_file () {

    local parent="${1-}" name="${2-}"

    dir::valid "${parent}" || return 1
    [[ -d "${parent}" ]] || return 1
    [[ -n "${name}" ]] || return 1

    [[ -f "${parent%/}/${name}" ]]

}
dir::contains_dir () {

    local parent="${1-}" name="${2-}"

    dir::valid "${parent}" || return 1
    [[ -d "${parent}" ]] || return 1
    [[ -n "${name}" ]] || return 1

    [[ -d "${parent%/}/${name}" ]]

}
dir::has_glob () {

    local p="${1-}" pattern="${2-}" old_nullglob="" old_dotglob="" entry="" found=1
    local -a matches=()

    dir::valid "${p}" || return 1
    [[ -d "${p}" ]] || return 1
    [[ -n "${pattern}" ]] || return 1

    old_nullglob="$(shopt -p nullglob)"
    old_dotglob="$(shopt -p dotglob)"

    shopt -s nullglob

    case "${pattern}" in
        .*) shopt -s dotglob ;;
    esac

    for entry in "${p%/}"/${pattern}; do
        [[ -e "${entry}" || -L "${entry}" ]] && { found=0; break; }
        matches+=( "${entry}" )
    done

    eval "${old_nullglob}"
    eval "${old_dotglob}"

    return "${found}"

}

dir::is_under () {

    path::is_under "$@"

}
dir::is_parent () {

    path::is_parent "$@"

}
dir::same () {

    local a="${1-}" b="${2-}"

    dir::valid "${a}" || return 1
    dir::valid "${b}" || return 1

    [[ -d "${a}" && -d "${b}" ]] || return 1

    path::same "${a}" "${b}"

}

dir::touch () {

    local p="${1-}" name="" entry=""

    dir::valid "${p}" || return 1
    [[ -d "${p}" ]] || return 1
    shift || true

    (( $# > 0 )) || return 1

    for name in "$@"; do
        [[ -n "${name}" ]] || return 1
        entry="${p%/}/${name}"
        : > "${entry}" 2>/dev/null || touch -- "${entry}" 2>/dev/null || return 1
    done

}
dir::ensure_chain () {

    local cur=""

    (( $# > 0 )) || return 1

    for cur in "$@"; do
        dir::ensure "${cur}" || return 1
    done

}

dir::owner () {

    path::owner "$@"

}
dir::group () {

    path::group "$@"

}
dir::mode () {

    local p="${1-}"

    dir::valid "${p}" || return 1
    [[ -d "${p}" ]] || return 1

    path::mode "${p}"

}
dir::mtime () {

    local p="${1-}"

    dir::valid "${p}" || return 1
    [[ -d "${p}" ]] || return 1

    path::mtime "${p}"

}
dir::age () {

    local p="${1-}"

    dir::valid "${p}" || return 1
    [[ -d "${p}" ]] || return 1

    path::age "${p}"

}

dir::abs () {

    local p="${1-}"

    dir::valid "${p}" || return 1
    [[ -d "${p}" ]] || return 1

    path::abs "${p}"

}
dir::resolve () {

    local p="${1-}"

    dir::valid "${p}" || return 1
    [[ -d "${p}" ]] || return 1

    path::resolve "${p}"

}
dir::rel () {

    local target="${1-}" base="${2:-}"

    dir::valid "${target}" || return 1
    [[ -d "${target}" ]] || return 1

    path::rel "${target}" "${base}"

}

dir::archive () {

    local p="${1-}" out="${2-}" parent="" name=""

    dir::valid "${p}" || return 1
    dir::valid "${out}" || return 1

    [[ -d "${p}" ]] || return 1
    sys::has tar || return 1

    parent="$(path::dir "${p}" 2>/dev/null || true)"
    name="$(path::base "${p}" 2>/dev/null || true)"

    [[ -n "${parent}" && -n "${name}" ]] || return 1

    case "${out}" in
        *.tar.gz|*.tgz) tar -czf "${out}" -C "${parent}" "${name}" 2>/dev/null ;;
        *.tar.bz2|*.tbz2) tar -cjf "${out}" -C "${parent}" "${name}" 2>/dev/null ;;
        *.tar.xz|*.txz) tar -cJf "${out}" -C "${parent}" "${name}" 2>/dev/null ;;
        *.tar.zst|*.tzst) tar --zstd -cf "${out}" -C "${parent}" "${name}" 2>/dev/null ;;
        *.tar) tar -cf "${out}" -C "${parent}" "${name}" 2>/dev/null ;;
        *.zip)
            sys::has zip || return 1
            ( cd -- "${parent}" 2>/dev/null && zip -qr -- "${out}" "${name}" ) 2>/dev/null
        ;;
        *) return 1 ;;
    esac

}
dir::extract () {

    local archive="${1-}" to="${2:-}" v=""

    [[ -n "${archive}" ]] || return 1
    [[ -f "${archive}" ]] || return 1
    [[ -n "${to}" ]] || to="$(path::dir "${archive}" 2>/dev/null || printf '.')"

    dir::valid "${to}" || return 1
    dir::ensure "${to}" || return 1

    case "${archive}" in
        *.tar.gz|*.tgz)
            sys::has tar || return 1
            tar -xzf "${archive}" -C "${to}" 2>/dev/null
        ;;
        *.tar.bz2|*.tbz2)
            sys::has tar || return 1
            tar -xjf "${archive}" -C "${to}" 2>/dev/null
        ;;
        *.tar.xz|*.txz)
            sys::has tar || return 1
            tar -xJf "${archive}" -C "${to}" 2>/dev/null
        ;;
        *.tar.zst|*.tzst)
            sys::has tar || return 1
            tar --zstd -xf "${archive}" -C "${to}" 2>/dev/null
        ;;
        *.tar)
            sys::has tar || return 1
            tar -xf "${archive}" -C "${to}" 2>/dev/null
        ;;
        *.zip)
            if sys::has unzip; then unzip -qo -- "${archive}" -d "${to}" 2>/dev/null
            elif sys::has bsdtar; then bsdtar -xf "${archive}" -C "${to}" 2>/dev/null
            else return 1
            fi
        ;;
        *) return 1 ;;
    esac

}

dir::watch () {

    local p="${1-}" interval="${2:-1}" prev="" cur=""

    dir::valid "${p}" || return 1
    [[ -d "${p}" ]] || return 1

    [[ "${interval}" =~ ^[0-9]+([.][0-9]+)?$ ]] || interval=1

    while :; do

        cur="$(dir::list "${p}" 2>/dev/null | sha1sum 2>/dev/null | awk '{print $1}')"
        [[ -z "${cur}" ]] && cur="$(dir::list "${p}" 2>/dev/null)"

        if [[ "${cur}" != "${prev}" ]]; then
            [[ -n "${prev}" ]] && return 0
            prev="${cur}"
        fi

        sleep "${interval}" 2>/dev/null || return 1

    done

}

dir::config () {

    local app="${1:-}" base=""

    base="$(path::config_dir 2>/dev/null || true)"
    [[ -n "${base}" ]] || return 1

    if [[ -n "${app}" ]]; then printf '%s/%s\n' "${base%/}" "${app}"
    else printf '%s\n' "${base}"
    fi

}
dir::data () {

    local app="${1:-}" base=""

    base="$(path::data_dir 2>/dev/null || true)"
    [[ -n "${base}" ]] || return 1

    if [[ -n "${app}" ]]; then printf '%s/%s\n' "${base%/}" "${app}"
    else printf '%s\n' "${base}"
    fi

}
dir::cache () {

    local app="${1:-}" base=""

    base="$(path::cache_dir 2>/dev/null || true)"
    [[ -n "${base}" ]] || return 1

    if [[ -n "${app}" ]]; then printf '%s/%s\n' "${base%/}" "${app}"
    else printf '%s\n' "${base}"
    fi

}
dir::state () {

    local app="${1:-}" base=""

    base="$(path::state_dir 2>/dev/null || true)"
    [[ -n "${base}" ]] || return 1

    if [[ -n "${app}" ]]; then printf '%s/%s\n' "${base%/}" "${app}"
    else printf '%s\n' "${base}"
    fi

}
dir::logs () {

    local app="${1:-}" base=""

    base="$(path::log_dir 2>/dev/null || true)"
    [[ -n "${base}" ]] || return 1

    if [[ -n "${app}" ]]; then printf '%s/%s\n' "${base%/}" "${app}"
    else printf '%s\n' "${base}"
    fi

}
dir::tmp () {

    local app="${1:-}" base=""

    base="$(path::tmp_dir 2>/dev/null || true)"
    [[ -n "${base}" ]] || return 1

    if [[ -n "${app}" ]]; then printf '%s/%s\n' "${base%/}" "${app}"
    else printf '%s\n' "${base}"
    fi

}
dir::home () {

    path::home_dir

}
