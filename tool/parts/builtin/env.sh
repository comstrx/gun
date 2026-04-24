
env::valid () {

    local key="${1:-}"

    [[ -n "${key}" ]] || return 1
    [[ "${key}" =~ ^[a-zA-Z_][a-zA-Z0-9_]*$ ]]

}
env::die () {

    local msg="${1:-}" code="${2:-1}"

    [[ "${code}" =~ ^[0-9]+$ ]] || code=1
    [[ -n "${msg}" ]] && printf '[ERR] %s\n' "${msg}" >&2
    [[ "${-}" == *i* ]] && return "${code}"

    exit "${code}"

}

env::has () {

    local key="${1:-}"

    env::valid "${key}" || return 1
    [[ -n "${!key+x}" ]]

}
env::has_any () {

    local key=""

    (( $# > 0 )) || return 1

    for key in "$@"; do
        env::has "${key}" && return 0
    done

    return 1

}
env::has_all () {

    local key=""

    (( $# > 0 )) || return 1

    for key in "$@"; do
        env::has "${key}" || return 1
    done

    return 0

}

env::need () {

    local key=""

    (( $# > 0 )) || return 1

    for key in "$@"; do
        env::filled "${key}" || env::die "missing env: ${key}"
    done

}
env::need_any () {

    local key=""

    (( $# > 0 )) || return 1

    for key in "$@"; do
        env::filled "${key}" && return 0
    done

    env::die "need at least one env"

}
env::need_all () {

    local key=""

    (( $# > 0 )) || return 1

    for key in "$@"; do
        env::filled "${key}" || env::die "missing env: ${key}"
    done

}

env::equal () {

    local key="${1:-}" value="${2-}"

    env::valid "${key}" || return 1
    [[ "${!key-}" == "${value}" ]]

}
env::true () {

    local key="${1:-}" value=""

    env::valid "${key}" || return 1

    value="${!key-}"
    value="${value,,}"

    [[ "${value}" == "1" || "${value}" == "true" || "${value}" == "yes" || "${value}" == "y" || "${value}" == "on" ]]

}
env::false () {

    local key="${1:-}" value=""

    env::valid "${key}" || return 1

    value="${!key-}"
    value="${value,,}"

    [[ "${value}" == "0" || "${value}" == "false" || "${value}" == "no" || "${value}" == "n" || "${value}" == "off" ]]

}
env::empty () {

    local key="${1:-}"

    env::valid "${key}" || return 1
    [[ -z "${!key-}" ]]

}
env::filled () {

    local key="${1:-}"

    env::valid "${key}" || return 1
    [[ -n "${!key-}" ]]

}
env::missing () {

    local key="${1:-}"

    env::has "${key}" && return 1
    return 0

}

env::get () {

    local key="${1:-}" def="${2-}"

    env::valid "${key}" || { printf '%s' "${def}"; return 0; }

    if [[ -n "${!key+x}" ]]; then printf '%s' "${!key}"
    else printf '%s' "${def}"
    fi

}
env::unset () {

    local key="${1:-}"

    env::valid "${key}" || return 1
    unset "${key}"

}
env::set () {

    local key="${1:-}" value="${2-}"

    env::valid "${key}" || return 1
    export "${key}=${value}"

}
env::set_once () {

    local key="${1:-}" value="${2-}"

    env::valid "${key}" || return 1
    env::has "${key}" && return 0
    env::set "${key}" "${value}"

}

env::get_all () {

    local key=""

    (( $# > 0 )) || return 1

    for key in "$@"; do env::valid "${key}" || return 1; done
    for key in "$@"; do printf '%s=%s\n' "${key}" "${!key-}"; done

}
env::unset_all () {

    local key=""

    (( $# > 0 )) || return 1

    for key in "$@"; do env::valid "${key}" || return 1; done
    for key in "$@"; do env::unset "${key}" || return 1; done

}
env::set_all () {

    local pair="" key="" value=""

    (( $# > 0 )) || return 1

    for pair in "$@"; do

        [[ "${pair}" == *=* ]] || return 1
        key="${pair%%=*}"

        env::valid "${key}" || return 1

    done

    for pair in "$@"; do

        key="${pair%%=*}"
        value="${pair#*=}"

        env::set "${key}" "${value}" || return 1

    done

}
env::set_all_once () {

    local pair="" key="" value=""

    (( $# > 0 )) || return 1

    for pair in "$@"; do

        [[ "${pair}" == *=* ]] || return 1
        key="${pair%%=*}"

        env::valid "${key}" || return 1

    done

    for pair in "$@"; do

        key="${pair%%=*}"
        value="${pair#*=}"

        env::has "${key}" && continue
        env::set "${key}" "${value}" || return 1

    done

}

env::list () {

    local prefix="${1:-}" key=""

    while IFS= read -r key; do

        [[ -n "${prefix}" && "${key}" != "${prefix}"* ]] && continue
        printf '%s=%s\n' "${key}" "${!key-}"

    done < <(compgen -e | sort)

}
env::keys () {

    local prefix="${1:-}" key=""

    while IFS= read -r key; do

        [[ -n "${prefix}" && "${key}" != "${prefix}"* ]] && continue
        printf '%s\n' "${key}"

    done < <(compgen -e | sort)

}
env::values () {

    local prefix="${1:-}" key=""

    while IFS= read -r key; do

        [[ -n "${prefix}" && "${key}" != "${prefix}"* ]] && continue
        printf '%s\n' "${!key-}"

    done < <(compgen -e | sort)

}

env::map () {

    local name="${1:-}" prefix="${2:-}" key=""

    [[ -n "${name}" ]] || return 1

    local -n __std_env_ref__="${name}"
    __std_env_ref__=()

    while IFS= read -r key; do

        [[ -n "${prefix}" && "${key}" != "${prefix}"* ]] && continue
        __std_env_ref__["${key}"]="${!key-}"

    done < <(compgen -e | sort)

}
env::list_ref () {

    local name="${1:-}" prefix="${2:-}" key=""

    [[ -n "${name}" ]] || return 1

    # shellcheck disable=SC2178
    local -n __std_env_ref__="${name}"
    __std_env_ref__=()

    while IFS= read -r key; do

        [[ -n "${prefix}" && "${key}" != "${prefix}"* ]] && continue
        __std_env_ref__+=( "${key}=${!key-}" )

    done < <(compgen -e | sort)

}
env::keys_ref () {

    local name="${1:-}" prefix="${2:-}" key=""

    [[ -n "${name}" ]] || return 1

    # shellcheck disable=SC2178
    local -n __std_env_ref__="${name}"
    __std_env_ref__=()

    while IFS= read -r key; do

        [[ -n "${prefix}" && "${key}" != "${prefix}"* ]] && continue
        __std_env_ref__+=( "${key}" )

    done < <(compgen -e | sort)

}
env::values_ref () {

    local name="${1:-}" prefix="${2:-}" key=""

    [[ -n "${name}" ]] || return 1

    # shellcheck disable=SC2178
    local -n __std_env_ref__="${name}"
    __std_env_ref__=()

    while IFS= read -r key; do

        [[ -n "${prefix}" && "${key}" != "${prefix}"* ]] && continue
        __std_env_ref__+=( "${!key-}" )

    done < <(compgen -e | sort)

}

env::path_sep () {

    local value="${1:-}"
    [[ "${value}" == *";"* ]] && { printf ';'; return 0; }
    printf ':'

}
env::path_has () {

    local dir="${1:-}" current="${2:-${PATH:-}}" sep=""

    [[ -n "${dir}" ]] || return 1

    sep="$(env::path_sep "${current}")"

    case "${sep}${current}${sep}" in
        *"${sep}${dir}${sep}"*) return 0 ;;
        *)                      return 1 ;;
    esac

}
env::path_prepend () {

    local dir="${1:-}" key="${2:-PATH}" current="" sep=""

    [[ -n "${dir}" ]] || return 1
    env::valid "${key}" || return 1

    current="${!key-}"
    sep="$(env::path_sep "${current}")"

    env::path_has "${dir}" "${current}" && return 0

    if [[ -n "${current}" ]]; then env::set "${key}" "${dir}${sep}${current}"
    else env::set "${key}" "${dir}"
    fi

}
env::path_append () {

    local dir="${1:-}" key="${2:-PATH}" current="" sep=""

    [[ -n "${dir}" ]] || return 1
    env::valid "${key}" || return 1

    current="${!key-}"
    sep="$(env::path_sep "${current}")"

    env::path_has "${dir}" "${current}" && return 0

    if [[ -n "${current}" ]]; then env::set "${key}" "${current}${sep}${dir}"
    else env::set "${key}" "${dir}"
    fi

}
env::path_del () {

    local dir="${1:-}" key="${2:-PATH}" current="" part="" next="" sep=""

    [[ -n "${dir}" ]] || return 1
    env::valid "${key}" || return 1

    current="${!key-}"
    sep="$(env::path_sep "${current}")"
    IFS="${sep}" read -r -a __env_parts__ <<< "${current}"

    for part in "${__env_parts__[@]}"; do

        [[ -z "${part}" || "${part}" == "${dir}" ]] && continue

        if [[ -n "${next}" ]]; then next="${next}${sep}${part}"
        else next="${part}"
        fi

    done

    unset __env_parts__
    [[ "${key}" == "PATH" && -z "${next}" ]] && return 1

    env::set "${key}" "${next}"

}
