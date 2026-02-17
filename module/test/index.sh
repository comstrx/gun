#!/usr/bin/env bash

cinema__auto_template () {

    local root="${ROOT_DIR:-.}/template"
    [[ -d "${root}" ]] || { printf '%s' ""; return 0; }

    find "${root}" -mindepth 1 -maxdepth 2 -type d 2>/dev/null | head -n 1 || true

}
cmd_cinema_type () {

    source <(parse "$@" -- shell:bool expect:int cps:int pause:float no_sound:bool no_color:bool dry:bool script report)

    CINEMA_CPS="${cps:-${CINEMA_CPS}}"
    CINEMA_PAUSE="${pause:-${CINEMA_PAUSE}}"
    CINEMA_NO_SOUND="${no_sound:-${CINEMA_NO_SOUND}}"
    CINEMA_NO_COLOR="${no_color:-${CINEMA_NO_COLOR}}"
    CINEMA_DRY_RUN="${dry:-${CINEMA_DRY_RUN}}"

    CINEMA_SCRIPT_OUT="${script:-${CINEMA_SCRIPT_OUT}}"
    CINEMA_REPORT_OUT="${report:-${CINEMA_REPORT_OUT}}"

    cinema_traps
    cinema_set_prompt "${PWD}"

    if (( shell )); then

        local cmd_str="${kwargs[*]-}"
        [[ -n "${cmd_str}" ]] || die "cinema-type: missing command"

        if [[ -n "${expect}" ]]; then cinema_run_typed --shell --expect "${expect}" "${cmd_str}"
        else cinema_run_typed --shell "${cmd_str}"
        fi

        return 0

    fi

    (( ${#kwargs[@]} )) || die "cinema-type: missing command"

    if [[ -n "${expect}" ]]; then cinema_run_typed --expect "${expect}" "${kwargs[@]}"
    else cinema_run_typed "${kwargs[@]}"
    fi

}
cmd_cinema_show () {

    source <(parse "$@" -- tmp_dir name template full:bool cps:int pause:float no_sound:bool no_color:bool keep:bool)

    CINEMA_CPS="${cps:-${CINEMA_CPS}}"
    CINEMA_PAUSE="${pause:-${CINEMA_PAUSE}}"
    CINEMA_NO_SOUND="${no_sound:-0}"
    CINEMA_NO_COLOR="${no_color:-0}"

    cinema_traps

    local base="${tmp_dir:-}"
    [[ -n "${base}" ]] || base="$(tmp_dir gun-cinema)"

    local project="${name:-demo}"
    local tpl="${template:-}"
    [[ -n "${tpl}" ]] || tpl="$(cinema__auto_template)"

    [[ -n "${tpl}" ]] || die "cinema-show: cannot auto-detect template (pass --template)"

    if (( keep )); then :; else trap 'rm -rf -- "'"${base}"'" 2>/dev/null || true' RETURN; fi

    run mkdir -p -- "${base}"
    cinema_set_prompt ""

    run clear 2>/dev/null || true
    cinema_say "Hi ya boss 😎  Welcome to gun cinema"

    cinema_run_typed --shell "mkdir -p ${base}"
    cinema_run_typed --shell "cd ${base}"
    cd -- "${base}" || die "cinema-show: cannot cd"
    cinema_set_prompt "${base}"

    run clear 2>/dev/null || true
    cinema_say "Create new project from template"
    cinema_run_typed --shell "gun new ${tpl} ${project} ${base}"

    cd -- "${base}/${project}" 2>/dev/null || cd -- "${base}" || true
    cinema_set_prompt "$(pwd -P)"

    run clear 2>/dev/null || true
    cinema_say "Show command surface"
    cinema_run_typed gun --help

    run clear 2>/dev/null || true
    cinema_say "Quick local checks (no network)"
    cinema_run_typed gun status || true
    cinema_run_typed gun is-repo || true

    if (( full )); then

        run clear 2>/dev/null || true
        cinema_say "Full gates (may install tools / take time)"
        cinema_run_typed gun fmt-check
        cinema_run_typed gun lint-check
        cinema_run_typed gun audit-check
        cinema_run_typed gun semver || true
        cinema_run_typed gun coverage || true
        cinema_run_typed gun trivy || true
        cinema_run_typed gun leaks || true

    else

        run clear 2>/dev/null || true
        cinema_say "Tip: run full show with --full for the scary stuff 👹"

    fi

    run clear 2>/dev/null || true
    cinema_say "Done. gun is not a CLI… it's a weapon."

}
cmd_cinema_smoke () {

    source <(parse "$@" -- level:int=1 tmp_dir template name keep:bool report out)

    CINEMA_NO_SOUND=1
    CINEMA_NO_COLOR=1
    CINEMA_CPS=999999
    CINEMA_PAUSE=0

    local base="${tmp_dir:-}"
    [[ -n "${base}" ]] || base="$(tmp_dir gun-smoke)"

    if (( keep )); then :; else trap 'rm -rf -- "'"${base}"'" 2>/dev/null || true' RETURN; fi

    local out="${out:-${OUT_DIR:-out}/smoke.json}"
    CINEMA_REPORT_OUT="${report:-${out}}"
    : > "${CINEMA_REPORT_OUT}" 2>/dev/null || true

    local ok=0 fail=0

    smoke__ok () { ok=$(( ok + 1 )); }
    smoke__fail () { fail=$(( fail + 1 )); }

    smoke__run () {

        local label="${1-}"; shift || true

        if "$@"; then
            smoke__ok
            cinema__emit_report pass "${label}" 0
            return 0
        fi

        local rc="$?"
        smoke__fail
        cinema__emit_report fail "${label}" "${rc}"
        return 1

    }

    run mkdir -p -- "${base}"
    cd -- "${base}" || die "cinema-smoke: cannot cd"

    smoke__run "gun_help" gun --help

    run mkdir -p -- "${base}/repo"
    cd -- "${base}/repo" || die "cinema-smoke: cannot cd repo"

    if has git; then
        smoke__run "git_init" git init -q
        smoke__run "gun_is_repo" gun is-repo
        smoke__run "gun_status" gun status || true
    fi

    run mkdir -p -- "${base}/fs"
    cd -- "${base}/fs" || die "cinema-smoke: cannot cd fs"

    smoke__run "new_dir" gun new-dir "${base}/fs/a/b" 755
    smoke__run "new_file" gun new-file "${base}/fs/a/b/x.txt" 644

    printf '%s\n' "hello" > "${base}/fs/a/b/x.txt"

    smoke__run "copy" gun copy "${base}/fs/a/b/x.txt" "${base}/fs/a/b/y.txt"
    smoke__run "diff" gun diff "${base}/fs/a/b/x.txt" "${base}/fs/a/b/y.txt"

    smoke__run "move" gun move "${base}/fs/a/b/y.txt" "${base}/fs/a/b/z.txt"
    smoke__run "remove" gun remove "${base}/fs/a/b/z.txt"

    if (( level >= 2 )); then

        local tpl="${template:-}"
        [[ -n "${tpl}" ]] || tpl="$(cinema__auto_template)"

        if [[ -n "${tpl}" ]]; then
            local project="${name:-demo}"
            smoke__run "gun_new" gun new "${tpl}" "${project}" "${base}"
        fi

    fi
    if (( level >= 3 )); then
        smoke__run "fmt_check" gun fmt-check || true
        smoke__run "lint_check" gun lint-check || true
        smoke__run "audit_check" gun audit-check || true
    fi
    if (( fail )); then
        die "cinema-smoke: failed=${fail}, ok=${ok} (report: ${CINEMA_REPORT_OUT})" 1
    fi

    success "cinema-smoke: ok=${ok} (report: ${CINEMA_REPORT_OUT})"

}
cmd_extract_gif () {

    ensure_pkg ffmpeg
    source <(parse "$@" -- :path out start="00:00:00" duration:float=10 fps:float=20 width:int=720 speed:float=1 quality=normal loop:bool)

    [[ -f "${path}" ]] || die "extract-gif: file not found: ${path}" 2
    [[ -n "${out}" ]] || out="${path%.*}.gif"

    local inv="$(awk -v s="${speed}" 'BEGIN{ if (s <= 0) s = 1; printf "%.10f", 1/s }')"
    local vf="" ff_loop="-1"
    (( loop )) && ff_loop="0"

    case "${quality}" in
        high) vf="setpts=${inv}*PTS,fps=${fps},scale=${width}:-1:flags=lanczos,split[s0][s1];[s0]palettegen=stats_mode=full[p];[s1][p]paletteuse=dither=bayer:bayer_scale=5" ;;
        *)    vf="setpts=${inv}*PTS,fps=${fps},scale=${width}:-1:flags=lanczos,split[s0][s1];[s0]palettegen[p];[s1][p]paletteuse" ;;
    esac

    ffmpeg -hide_banner -loglevel error -nostdin -y -ss "${start}" -t "${duration}" -i "${path}" -vf "${vf}" -loop "${ff_loop}" "${out}"

}
