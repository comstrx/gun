#!/usr/bin/env bash

cmd_open_self () {

    local dir="${ROOT_DIR:-.}"

    command -v code >/dev/null 2>&1          && { code "${dir}"; return 0; }
    command -v nautilus >/dev/null 2>&1      && { nautilus "${dir}"; return 0; }
    command -v nemo >/dev/null 2>&1          && { nemo "${dir}"; return 0; }
    command -v thunar >/dev/null 2>&1        && { thunar "${dir}"; return 0; }
    command -v dolphin >/dev/null 2>&1       && { dolphin "${dir}"; return 0; }
    command -v pcmanfm >/dev/null 2>&1       && { pcmanfm "${dir}"; return 0; }
    command -v explorer.exe >/dev/null 2>&1  && { explorer.exe "$(wslpath -w "${dir}" 2>/dev/null || printf '%s' "${dir}")"; return 0; }
    command -v open >/dev/null 2>&1          && { open "${dir}"; return 0; }
    command -v xdg-open >/dev/null 2>&1      && { xdg-open "${dir}"; return 0; }

    printf 'Cannot open: %s\n' "${dir}" >&2
    return 1

}
cmd_new_project () {

    source <(parse "$@" -- :type :name dir alias user repo branch description discord docs site host placeholders:bool=true git:bool=true)

    local tdir="${TEMPLATE_DIR:-${ROOT_DIR:-}/template}"
    local tpl="$(resolve_template "${type}" "${tdir}")"
    local src="${tdir}/${tpl}" base="${tdir}/base"
    local dest="${dir:-${PROJECTS_DIR:-${PWD}}}"

    dest="${dest/#\~/${HOME}}"
    dest="${dest%/}"

    [[ -d "${src}" ]] || die "template not found: ${src}"
    [[ "${dest##*/}" == "${name}" ]] || dest+="/${name}"

    copy_template "${src}" "${dest}"
    copy_missing_files "${base}" "${dest}" "${type}"

    if (( placeholders )); then

        prepare_placeholders \
            "${dest}" "${name}" "${alias}" "${user}" "${repo}" "${branch}" "${description}" \
            "${discord}" "${docs}" "${site}" "${host}"

    fi
    if (( git )); then

        prepare_git "${dest}" "${name}" "${repo}" "${branch}" "${host}" "${kwargs[@]}"

    fi

    success "OK: ${tpl} was successfully set up at ${dest}"

}
