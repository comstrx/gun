#!/usr/bin/env bash

cmd_open_self () {

    local dir="${ROOT_DIR:-.}"

    command -v code >/dev/null 2>&1          && { code "${dir}"; return 0; }
    command -v nautilus >/dev/null 2>&1      && { nautilus "${dir}"; return 0; }

    command -v nemo >/dev/null 2>&1          && { nemo "${dir}"; return 0; }
    command -v thunar >/dev/null 2>&1        && { thunar "${dir}"; return 0; }
    command -v dolphin >/dev/null 2>&1       && { dolphin "${dir}"; return 0; }
    command -v pcmanfm >/dev/null 2>&1       && { pcmanfm "${dir}"; return 0; }

    command -v explorer.exe >/dev/null 2>&1  && { explorer.exe "$(wslpath -w "${dir}" 2>/dev/null)"; return 0; }
    command -v open >/dev/null 2>&1          && { open "${dir}"; return 0; }
    command -v xdg-open >/dev/null 2>&1      && { xdg-open "${dir}"; return 0; }

    printf 'Cannot open: %s\n' "${dir}" >&2
    return 1

}
cmd_new_project () {

    source <(parse "$@" -- :template name dir placeholders:bool=true git:bool=true)

    local root="${ROOT_DIR:-}/template"
    local cdir="${root}/config"

    local src="$(resolve_path "${root}" "${template}")"
    [[ -d "${src}" ]] || die "template not found: ${src}"

    dir="${dir:-${PROJECTS_DIR:-${WORKSPACE_DIR:-${PWD}}}}"
    dir="${dir/#\~/${HOME}}"
    dir="${dir%/}"

    name="${name:-${template##*/}}"
    [[ "${dir##*/}" == "${name}" ]] || dir+="/${name}"

    copy_template "${src}" "${dir}"
    resolve_config "${name}" "${cdir}" "${dir}" "${kwargs[@]}"

    (( placeholders )) && set_placeholders "${dir}" "${name}" "${kwargs[@]}"

    (( git )) && set_git "${dir}" "${name}" "${kwargs[@]}"

    success "OK: ${name} was successfully set up at ${dir}"

}
