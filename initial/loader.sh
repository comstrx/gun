#!/usr/bin/env bash
source "$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)/../core/utils.sh"

MODULE_DIR="module"
SORTED_LIST=(git github notify scaffold storage user)

should_skip () {

    local name="${1-}" s=""
    shift || true

    [[ -n "${name}" ]] || return 0
    [[ "${name}" == _* ]] && return 0

    for s in "$@"; do
        [[ -n "${s}" ]] || continue
        [[ "${name}" == "${s}" ]] && return 0
    done

    return 1

}
load_walk () {

    local dir="${1:-}" file="" base="" name="" subdir="" sd="" nullglob_was_set=0
    local -a extra_skip=()
    shift || true

    [[ -n "${dir}" && -d "${dir}" ]] || return 0
    (( $# )) && extra_skip=( "$@" ) || extra_skip=()

    shopt -q nullglob && nullglob_was_set=1
    shopt -s nullglob

    for file in "${dir}"/*.sh; do

        base="${file##*/}"
        name="${base%.sh}"
        [[ -n "${base}" ]] || continue

        should_skip "${name}" "${extra_skip[@]-}" && continue
        source "${file}" || { (( nullglob_was_set )) || shopt -u nullglob; die "Failed to source: ${file}"; }

    done
    for subdir in "${dir}"/*/; do

        sd="${subdir%/}"
        base="${sd##*/}"

        [[ -L "${sd}" ]] && continue
        [[ -n "${base}" ]] || continue

        should_skip "${base}" "${extra_skip[@]-}" && continue
        load_walk "${sd}" "${extra_skip[@]-}" || { (( nullglob_was_set )) || shopt -u nullglob; return $?; }

    done

    (( nullglob_was_set )) || shopt -u nullglob
    return 0

}
load_source () {

    [[ -n "${MODULES_LOADED:-}" ]] && return 0
    MODULES_LOADED=1
    load_walk "${ROOT_DIR}/${MODULE_DIR}"

}
normalize () {

    local s="${1-}"

    s="${s//-/_}"
    s="${s//./_}"

    printf '%s' "${s}"

}
parse_global () {

    YES=0 QUIET=0 VERBOSE=0 CMD="" ARGS=()

    while [[ $# -gt 0 ]]; do
        case "${1}" in
            --yes|-y)       YES=1; shift || true ;;
            --quiet|-q)     QUIET=1; shift || true ;;
            --verbose|-v)   VERBOSE=1; shift || true ;;
            --)             shift || true; break ;;
            -h|--help)      CMD="help"; shift || true ;;
            -*)             die "Unknown global flag: ${1}" ;;
            *)              break ;;
        esac
    done
    if [[ -z "${CMD}" ]]; then
        CMD="${1:-}"
        shift || true
    fi

    ARGS=( "$@" )

}
cmd_list () {

    local fn="" out="" key="" printed=0
    local -A seen=()
    local -A printed_cmd=()
    local -a cmds=()

    while read -r _ _ fn; do

        [[ "${fn}" == cmd_* ]] || continue

        out="${fn#cmd_}"
        out="${out//_/-}"
        cmds+=( "${out}" )
        seen["${out}"]=1

    done < <(declare -F)
    for key in "${SORTED_LIST[@]-}"; do

        [[ -n "${key}" ]] || continue

        if [[ -n "${seen[${key}]-}" && -z "${printed_cmd[${key}]-}" ]]; then
            printf '%s\n' "${key}"
            printed_cmd["${key}"]=1
            printed=1
        fi

    done
    for out in "${cmds[@]-}"; do

        [[ -n "${out}" ]] || continue
        [[ -n "${printed_cmd[${out}]-}" ]] && continue

        printf '%s\n' "${out}"
        printed_cmd["${out}"]=1
        printed=1

    done

    (( printed )) || printf '%s\n' "(no commands)"

}
dispatch () {

    local cmd="${1:-}" sub="${2:-}"
    shift 2 || true

    if [[ -z "${cmd}" || "${cmd}" == "help" || "${cmd}" == "-h" || "${cmd}" == "--help" ]]; then
        cmd_list
        return 0
    fi
    if ! [[ "${cmd}" =~ ^[A-Za-z0-9][A-Za-z0-9_.-]*$ ]]; then
        cmd_list
        return 2
    fi

    local mod="$(normalize "${cmd}")" fn="cmd_${mod}"

    if [[ -n "${sub}" && "${sub}" != -* ]]; then

        local fn_sub="cmd_${mod}_$(normalize "${sub}")"

        if declare -F "${fn_sub}" >/dev/null 2>&1; then
            "${fn_sub}" "$@"
            return $?
        fi

    fi
    if declare -F "${fn}" >/dev/null 2>&1; then
        "${fn}" "$@"
        return $?
    fi

    cmd_list
    return 2

}
load () {

    cd_current_root || die "You must run this command inside a project "

    local old_trap="$(trap -p ERR 2>/dev/null || true)" ec=0
    trap 'on_err "$?"' ERR

    load_source
    parse_global "$@"

    if [[ ${#ARGS[@]} -gt 0 ]]; then dispatch "${CMD}" "${ARGS[@]}" || ec=$?
    else dispatch "${CMD}" || ec=$?
    fi

    if [[ -n "${old_trap}" ]]; then eval "${old_trap}"
    else trap - ERR 2>/dev/null || true
    fi

    return "${ec}"

}
