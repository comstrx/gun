#!/usr/bin/env bash

CINEMA_LOADED=1

CINEMA_PROMPT=""
CINEMA_SOUND_PID=""
CINEMA_SOUND_PG=0

CINEMA_CPS="${CINEMA_CPS:-22}"
CINEMA_PAUSE="${CINEMA_PAUSE:-1}"
CINEMA_NO_SOUND="${CINEMA_NO_SOUND:-0}"
CINEMA_NO_COLOR="${CINEMA_NO_COLOR:-0}"
CINEMA_DRY_RUN="${CINEMA_DRY_RUN:-0}"

CINEMA_ASSETS_DIR="${CINEMA_ASSETS_DIR:-${ROOT_DIR:-.}/module/cinema/assets}"
CINEMA_SOUND_CMD="${CINEMA_SOUND_CMD:-cmd.wav}"
CINEMA_SOUND_SAY="${CINEMA_SOUND_SAY:-say.wav}"

CINEMA_SCRIPT_OUT="${CINEMA_SCRIPT_OUT:-}"
CINEMA_REPORT_OUT="${CINEMA_REPORT_OUT:-}"

cinema__now () {

    if has datetime; then datetime
    else LC_ALL=C command date '+%Y-%m-%d %H:%M:%S'
    fi

}
cinema__can_color () {

    (( CINEMA_NO_COLOR )) && return 1
    [[ -n "${NO_COLOR-}" ]] && return 1
    [[ -t 1 && -n "${TERM-}" && "${TERM}" != "dumb" ]]

}
cinema__can_fx () {

    (( CINEMA_DRY_RUN )) && return 1
    [[ -t 1 && -n "${TERM-}" && "${TERM}" != "dumb" ]]

}

cinema_userhost_short () {

    local u="$(id -un 2>/dev/null || printf '%s' "${USER-unknown}")"
    local h="$(hostname 2>/dev/null || printf '%s' "${HOSTNAME-localhost}")"

    h="${h%%.*}"
    printf '%s@%s' "${u}" "${h}"

}
cinema_set_prompt () {

    local path="${1-}"

    if cinema__can_color; then
        CINEMA_PROMPT=$'\e[32m'"$(cinema_userhost_short)"$'\e[0m:\e[34m'"${path}"$'\e[0m\e[37m$ \e[0m'
    else
        CINEMA_PROMPT="$(cinema_userhost_short):${path}$ "
    fi

}
cinema_stop_sound () {

    local pid="${CINEMA_SOUND_PID-}"
    [[ -n "${pid}" ]] || return 0

    if has taskkill.exe; then
        taskkill.exe //T //F //PID "${pid}" >/dev/null 2>&1 || true
    fi

    kill -TERM "${pid}" >/dev/null 2>&1 || true
    (( CINEMA_SOUND_PG )) && kill -TERM -- "-${pid}" >/dev/null 2>&1 || true

    if has pkill; then
        pkill -TERM -P "${pid}" >/dev/null 2>&1 || true
    fi

    local i=0
    for i in 1 2 3 4 5 6 7 8; do
        kill -0 "${pid}" >/dev/null 2>&1 || break
        sleep 0.03
    done

    kill -KILL "${pid}" >/dev/null 2>&1 || true
    (( CINEMA_SOUND_PG )) && kill -KILL -- "-${pid}" >/dev/null 2>&1 || true

    if has pkill; then
        pkill -KILL -P "${pid}" >/dev/null 2>&1 || true
    fi

    wait "${pid}" 2>/dev/null || true

    CINEMA_SOUND_PID=""
    CINEMA_SOUND_PG=0

}
cinema_play_sound () {

    local file="${1-}" mode="${2-}" win_path="" cmd=""

    cinema_stop_sound

    [[ -n "${file}" ]] || return 0
    [[ -f "${file}" ]] || return 0

    (( CINEMA_NO_SOUND )) && return 0
    [[ -n "${NO_SOUND-}" || "${SOUND-1}" == "0" ]] && return 0
    cinema__can_fx || return 0

    [[ "${mode}" == "loop" ]] || mode="once"

    if has mpv; then

        if [[ "${mode}" == "loop" ]]; then
            if has setsid; then
                setsid mpv --no-video --loop-file=inf --really-quiet "${file}" >/dev/null 2>&1 & CINEMA_SOUND_PID=$!
                CINEMA_SOUND_PG=1
            else
                mpv --no-video --loop-file=inf --really-quiet "${file}" >/dev/null 2>&1 & CINEMA_SOUND_PID=$!
                CINEMA_SOUND_PG=0
            fi
        else
            mpv --no-video --loop-file=no --really-quiet "${file}" >/dev/null 2>&1 & CINEMA_SOUND_PID=$!
            CINEMA_SOUND_PG=0
        fi

        return 0

    fi
    if has afplay; then

        if [[ "${mode}" == "loop" ]]; then
            if has setsid; then
                setsid bash -c 'while :; do afplay "$1" >/dev/null 2>&1 || exit 0; done' _ "${file}" & CINEMA_SOUND_PID=$!
                CINEMA_SOUND_PG=1
            else
                ( while :; do afplay "${file}" >/dev/null 2>&1 || exit 0; done ) & CINEMA_SOUND_PID=$!
                CINEMA_SOUND_PG=0
            fi
        else
            afplay "${file}" >/dev/null 2>&1 & CINEMA_SOUND_PID=$!
            CINEMA_SOUND_PG=0
        fi

        return 0

    fi
    if has paplay; then

        if [[ "${mode}" == "loop" ]]; then
            if has setsid; then
                setsid bash -c 'while :; do paplay "$1" >/dev/null 2>&1 || exit 0; done' _ "${file}" & CINEMA_SOUND_PID=$!
                CINEMA_SOUND_PG=1
            else
                ( while :; do paplay "${file}" >/dev/null 2>&1 || exit 0; done ) & CINEMA_SOUND_PID=$!
                CINEMA_SOUND_PG=0
            fi
        else
            paplay "${file}" >/dev/null 2>&1 & CINEMA_SOUND_PID=$!
            CINEMA_SOUND_PG=0
        fi

        return 0

    fi
    if has aplay; then

        if [[ "${mode}" == "loop" ]]; then
            if has setsid; then
                setsid bash -c 'while :; do aplay -q "$1" >/dev/null 2>&1 || exit 0; done' _ "${file}" & CINEMA_SOUND_PID=$!
                CINEMA_SOUND_PG=1
            else
                ( while :; do aplay -q "${file}" >/dev/null 2>&1 || exit 0; done ) & CINEMA_SOUND_PID=$!
                CINEMA_SOUND_PG=0
            fi
        else
            aplay -q "${file}" >/dev/null 2>&1 & CINEMA_SOUND_PID=$!
            CINEMA_SOUND_PG=0
        fi

        return 0

    fi
    if has powershell.exe; then

        win_path="${file}"
        has wslpath && win_path="$(wslpath -w "${file}" 2>/dev/null || printf '%s' "${file}")"
        win_path="${win_path//\'/\'\'}"

        if [[ "${mode}" == "loop" ]]; then
            cmd="\$p='${win_path}'; \$sp=New-Object Media.SoundPlayer \$p; while(\$true){ \$sp.PlaySync() }"
        else
            cmd="(New-Object Media.SoundPlayer '${win_path}').PlaySync()"
        fi

        powershell.exe -NoProfile -NonInteractive -Command "${cmd}" >/dev/null 2>&1 & CINEMA_SOUND_PID=$!
        CINEMA_SOUND_PG=0

        return 0

    fi

    return 0

}

cinema_traps () {

    trap 'cinema_stop_sound; exit 130' INT
    trap 'cinema_stop_sound' TERM
    trap 'cinema_stop_sound' EXIT

}
cinema__emit_script () {

    local line="${1-}"
    [[ -n "${CINEMA_SCRIPT_OUT}" ]] || return 0

    ensure_dir "$(dirname -- "${CINEMA_SCRIPT_OUT}")"
    [[ -f "${CINEMA_SCRIPT_OUT}" ]] || printf '%s\n' '#!/usr/bin/env bash' > "${CINEMA_SCRIPT_OUT}"
    printf '%s\n' "${line}" >> "${CINEMA_SCRIPT_OUT}"

}
cinema__emit_report () {

    local kind="${1-}" value="${2-}" rc="${3-0}"
    [[ -n "${CINEMA_REPORT_OUT}" ]] || return 0

    ensure_dir "$(dirname -- "${CINEMA_REPORT_OUT}")"

    local ts="$(cinema__now)"
    printf '{"ts":"%s","kind":"%s","value":"%s","rc":%s}\n' \
        "${ts//\"/\\\"}" "${kind//\"/\\\"}" "${value//\"/\\\"}" "${rc}" >> "${CINEMA_REPORT_OUT}"

}

cinema_type_line () {

    local s="${1-}" kind="${2:-cmd}" sound="${3-}" mode="${4:-once}"
    local cps="${5:-${CINEMA_CPS}}" pause="${6:-${CINEMA_PAUSE}}"
    local delay="" i=0

    [[ -n "${sound}" ]] || { [[ "${kind}" == "say" ]] && sound="${CINEMA_SOUND_SAY}" || sound="${CINEMA_SOUND_CMD}"; }

    [[ "${kind}" != "say" ]] && printf '%b' "${CINEMA_PROMPT}"

    (( pause > 0 )) && sleep "${pause}" 2>/dev/null || true
    delay="$(awk -v r="${cps}" 'BEGIN{ if (r <= 0) r = 22; printf "%.6f", 1/r }')"

    cinema_play_sound "${CINEMA_ASSETS_DIR}/${sound}" "${mode}"

    while (( i < ${#s} )); do
        printf '%s' "${s:i:1}"
        sleep "${delay}" 2>/dev/null || true
        i=$(( i + 1 ))
    done

    cinema_stop_sound
    printf '\n'

}
cinema_say () {

    local msg="${1-}" new_line="${2:-1}"
    (( new_line )) && { printf '\n'; }

    cinema_type_line "          👉  ${msg}" say "${CINEMA_SOUND_SAY}" once
    printf '\n'

    cinema__emit_report say "${msg}" 0

}
cinema_run_typed () {

    local expect="" shell=0 rc=0 shown="" cmd_str=""
    local -a cmd=( )

    while (( $# )); do
        case "${1}" in
            --expect) expect="${2-}"; shift 2 ;;
            --shell) shell=1; shift ;;
            --) shift; break ;;
            *) break ;;
        esac
    done

    (( $# )) || return 0

    if (( shell )); then

        cmd_str="${1}"
        shown="${cmd_str}"
        cinema_type_line "${shown}" cmd "${CINEMA_SOUND_CMD}" loop
        cinema__emit_script "${cmd_str}"
        cinema__emit_report cmd "${shown}" 0

        (( CINEMA_DRY_RUN )) && return 0

        bash -lc "${cmd_str}" || rc=$?
        [[ -z "${expect}" || "${rc}" == "${expect}" ]] || die "cinema: expected rc=${expect}, got rc=${rc}"

        cinema__emit_report rc "${shown}" "${rc}"
        return "${rc}"

    fi

    cmd=( "$@" )

    if (( ${#cmd[@]} == 1 )); then
        shown="${cmd[0]}"
    else
        shown="$(printf '%q ' "${cmd[@]}")"
        shown="${shown% }"
    fi

    cinema_type_line "${shown}" cmd "${CINEMA_SOUND_CMD}" loop
    cinema__emit_script "${shown}"
    cinema__emit_report cmd "${shown}" 0

    (( CINEMA_DRY_RUN )) && return 0

    "${cmd[@]}" || rc=$?
    [[ -z "${expect}" || "${rc}" == "${expect}" ]] || die "cinema: expected rc=${expect}, got rc=${rc}"

    cinema__emit_report rc "${shown}" "${rc}"
    return "${rc}"

}
