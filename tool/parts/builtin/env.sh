
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
env::set () {

    local key="${1:-}" value="${2-}"

    env::valid "${key}" || return 1
    export "${key}=${value}"

}
env::unset () {

    local key="${1:-}"

    env::valid "${key}" || return 1
    unset "${key}"

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

    for key in "$@"; do
        env::valid "${key}" || return 1
        printf '%s=%s\n' "${key}" "${!key-}"
    done

}
env::set_all () {

    local pair="" key="" value=""

    (( $# > 0 )) || return 1

    for pair in "$@"; do

        [[ "${pair}" == *=* ]] || return 1

        key="${pair%%=*}"
        value="${pair#*=}"

        env::set "${key}" "${value}" || return 1

    done

}
env::unset_all () {

    local key=""

    (( $# > 0 )) || return 1

    for key in "$@"; do
        env::unset "${key}" || return 1
    done

}
env::set_all_once () {

    local pair="" key="" value=""

    (( $# > 0 )) || return 1

    for pair in "$@"; do

        [[ "${pair}" == *=* ]] || return 1

        key="${pair%%=*}"
        value="${pair#*=}"

        env::valid "${key}" || return 1
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

    declare -n ref="${name}"
    ref=()

    while IFS= read -r key; do

        [[ -n "${prefix}" && "${key}" != "${prefix}"* ]] && continue
        ref["${key}"]="${!key-}"

    done < <(compgen -e | sort)

}
env::list_ref () {

    local name="${1:-}" prefix="${2:-}" key=""

    env::valid "${name}" || return 1

    local -n ref="${name}"
    ref=()

    while IFS= read -r key; do
        [[ -n "${prefix}" && "${key}" != "${prefix}"* ]] && continue
        ref+=( "${key}=${!key-}" )
    done < <(compgen -e | sort)

}
env::keys_ref () {

    local name="${1:-}" prefix="${2:-}" key=""

    env::valid "${name}" || return 1

    local -n ref="${name}"
    ref=()

    while IFS= read -r key; do
        [[ -n "${prefix}" && "${key}" != "${prefix}"* ]] && continue
        ref+=( "${key}" )
    done < <(compgen -e | sort)

}
env::values_ref () {

    local name="${1:-}" prefix="${2:-}" key=""

    env::valid "${name}" || return 1

    local -n ref="${name}"
    ref=()

    while IFS= read -r key; do
        [[ -n "${prefix}" && "${key}" != "${prefix}"* ]] && continue
        ref+=( "${!key-}" )
    done < <(compgen -e | sort)

}

env::path_has () {

    local dir="${1:-}" current="${2:-${PATH:-}}"

    [[ -n "${dir}" ]] || return 1

    case ":${current}:" in
        *:"${dir}":*) return 0 ;;
        *)            return 1 ;;
    esac

}
env::path_prepend () {

    local dir="${1:-}" key="${2:-PATH}" current=""

    [[ -n "${dir}" ]] || return 1
    env::valid "${key}" || return 1

    current="${!key-}"

    env::path_has "${dir}" "${current}" && return 0

    if [[ -n "${current}" ]]; then env::set "${key}" "${dir}:${current}"
    else env::set "${key}" "${dir}"
    fi

}
env::path_append () {

    local dir="${1:-}" key="${2:-PATH}" current=""

    [[ -n "${dir}" ]] || return 1
    env::valid "${key}" || return 1

    current="${!key-}"

    env::path_has "${dir}" "${current}" && return 0

    if [[ -n "${current}" ]]; then env::set "${key}" "${current}:${dir}"
    else env::set "${key}" "${dir}"
    fi
 
}
env::path_del () {

    local dir="${1:-}" key="${2:-PATH}" current="" part="" next=""

    [[ -n "${dir}" ]] || return 1
    env::valid "${key}" || return 1

    current="${!key-}"

    IFS=':' read -r -a __env_parts__ <<< "${current}"

    for part in "${__env_parts__[@]}"; do

        [[ -z "${part}" || "${part}" == "${dir}" ]] && continue

        if [[ -n "${next}" ]]; then next="${next}:${part}"
        else next="${part}"
        fi

    done

    unset __env_parts__
    env::set "${key}" "${next}"

}
