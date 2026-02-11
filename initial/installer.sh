#!/usr/bin/env bash
source "$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)/../core/utils.sh"

ensure_line_once () {

    ensure_pkg grep

    local file="${1:-}"
    local line="${2:-}"

    [[ -n "${file}" ]] || die "ensure_line_once: missing file"
    [[ -n "${line}" ]] || die "ensure_line_once: missing line"
    [[ -L "${file}" ]] && die "Refusing to modify symlink: ${file}"

    ensure_file "${file}"

    LC_ALL=C grep -Fqx -- "${line}" "${file}" 2>/dev/null && return 0
    LC_ALL=C grep -Fqx -- "${line}"$'\r' "${file}" 2>/dev/null && return 0

    printf '%s\n' "${line}" >> "${file}" || die "Failed writing: ${file}"

}
ensure_path_once () {

    local alias_name="${1:-}"
    local rc="$(rc_path)"

    [[ -n "${rc}" ]] || die "ensure_path_once: missing rc"
    [[ -L "${rc}" ]] && die "Refusing to modify symlink: ${rc}"

    ensure_file "${rc}"
    ensure_line_once "${rc}" "# ${alias_name}"

    case "${rc}" in
        */.config/fish/config.fish) ensure_line_once "${rc}" 'set -gx PATH $HOME/.local/bin $PATH' ;;
        *) ensure_line_once "${rc}" 'export PATH="$HOME/.local/bin:$PATH"' ;;
    esac

}
install_launcher () {

    local root="${1:-}"
    local alias_name="${2:-}"

    local run_sh="${root}/run.sh"
    local bin_dir="$(home_path)/.local/bin"
    local bin="${bin_dir}/${alias_name}"

    validate_alias "${alias_name}"

    [[ -n "${root}" ]] || die "install_launcher: missing root"
    [[ -f "${run_sh}" ]] || die "Missing: ${run_sh}"

    ensure_dir "${bin_dir}"
    run chmod +x -- "${run_sh}" 2>/dev/null || true

    [[ -e "${bin}" && ! -f "${bin}" ]] && die "Refusing: target exists but not a file: ${bin}"
    [[ -L "${bin}" ]] && die "Refusing to overwrite symlink: ${bin}"

    if [[ -e "${bin}" && ! (( YES )) ]]; then confirm "Overwrite ${bin}?" "N" || die "Canceled."; fi
    local root_q=""; printf -v root_q '%q' "${root}"

    printf '%s\n' \
        '#!/usr/bin/env bash' \
        'set -Eeuo pipefail' \
        '' \
        "ROOT=${root_q}" \
        '' \
        'exec /usr/bin/env bash "${ROOT}/run.sh" "$@"' \
        > "${bin}" || die "Failed writing: ${bin}"

    run chmod +x -- "${bin}" || die "chmod failed: ${bin}"
    printf '%s' "${bin}"

}
install () {

    local alias_name="${1:-}"
    local bin_path="$(install_launcher "${ROOT_DIR}" "${alias_name}")"

    ensure_path_once "${alias_name}"
    success "Installed: ( ${alias_name} ) at ${bin_path}"

}
