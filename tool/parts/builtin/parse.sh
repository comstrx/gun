
get () {

    local long="${1:-}" short="${2:-}" position="${3:-}" def="${4-}" ref_name="${5-}"
    local x="" next="" alt="" value="" found=0 i=0 pos=0
    shift 5 || true

    local -a args=( "$@" )
    local -a rest=()

    [[ -z "${long}"  || "${long}"  == --* ]] || long=""
    [[ -z "${short}" || "${short}" == -?  ]] || short=""
    [[ "${position}" =~ ^[1-9][0-9]*$ ]] || position=0
    [[ -n "${long}" ]] && alt="-${long#--}"

    for (( i=0; i<${#args[@]}; i++ )); do

        x="${args[$i]}"

        local matched=0
        (( ! found )) && [[ -n "${long}"  && "${x}" == "${long}"  ]] && matched=1
        (( ! found )) && [[ -n "${short}" && "${x}" == "${short}" ]] && matched=1
        (( ! found )) && [[ -n "${alt}"   && "${x}" == "${alt}"   ]] && matched=1

        if [[ "${x}" == "--" ]]; then

            for (( ; i<${#args[@]}; i++ )); do
                rest+=( "${args[$i]}" )
            done

            break

        fi
        if (( ! found )) && [[ -n "${long}" && "${x}" == "${long}"=* ]]; then
            value="${x#*=}"
            found=1
            continue
        fi
        if (( ! found )) && [[ -n "${alt}" && "${x}" == "${alt}"=* ]]; then
            value="${x#*=}"
            found=1
            continue
        fi
        if (( matched )); then

            if (( i + 1 < ${#args[@]} )); then

                next="${args[$(( i + 1 ))]}"

                if [[ "${next}" == "--" ]]; then
                    value="true"
                    found=1
                    continue
                fi
                if [[ "${next}" =~ ^[+-]?([0-9]+([.][0-9]+)?|[.][0-9]+)$ ]]; then
                    value="${next}"
                    found=1
                    (( i++ ))
                    continue
                fi
                if [[ "${next}" != --* && "${next}" != -?* ]]; then
                    value="${next}"
                    found=1
                    (( i++ ))
                    continue
                fi

            fi

            value="true"
            found=1
            continue

        fi

        pos=$(( pos + 1 ))

        if (( ! found && position > 0 && pos == position )); then

            if [[ "${x}" != --* && "${x}" != -?* ]] || [[ "${x}" =~ ^[+-]?([0-9]+([.][0-9]+)?|[.][0-9]+)$ ]]; then
                value="${x}"
                found=1
                continue
            fi

        fi

        rest+=( "${x}" )

    done

    if [[ -n "${ref_name}" ]]; then
        local -n out_ref="${ref_name}"
        out_ref=( "${rest[@]}" )
    fi

    (( found )) && printf '%s' "${value}" || printf '%s' "${def}"

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
