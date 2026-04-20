
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

new_dir () {

    local path="${1:-}"
    [[ -n "${path}" ]] || return 1

    command mkdir -p -- "${path}"

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
