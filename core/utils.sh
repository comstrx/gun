#!/usr/bin/env bash

[[ "${BASH_SOURCE[0]}" != "${0}" ]] || { printf '%s\n' "utils.sh: this file should not be run externally." >&2; exit 2; }
[[ -n "${UTILS_LOADED:-}" ]] && return 0

UTILS_LOADED=1
source "$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)/parse.sh"

year () {

    LC_ALL=C command date '+%Y'

}
month () {

    LC_ALL=C command date '+%m'

}
day () {

    LC_ALL=C command date '+%d'

}
date_only () {

    LC_ALL=C command date '+%Y-%m-%d'

}
time_only () {

    LC_ALL=C command date '+%H:%M:%S'

}
datetime () {

    LC_ALL=C command date '+%Y-%m-%d %H:%M:%S'

}

slugify () {

    local s="${1-}"
    [[ -n "${s}" ]] || { printf '%s' ""; return 0; }

    s="$(LC_ALL=C printf '%s' "${s}" | tr '[:upper:]' '[:lower:]' | tr -cs 'a-z0-9_-' '-')"
    s="${s#-}"
    s="${s%-}"

    printf '%s' "${s}"

}
uc_first () {

    local s="${1:-}"
    [[ -n "${s}" ]] || { printf '%s' ""; return 0; }

    printf '%s%s' "$(printf '%s' "${s:0:1}" | tr '[:lower:]' '[:upper:]')" "${s:1}"

}
unique_list () {

    local -n in="${1}"
    local -a out=()
    local -A seen=()
    local x=""

    for x in "${in[@]-}"; do

        [[ -n "${x}" ]] || continue
        [[ -n "${seen["$x"]+x}" ]] && continue

        seen["$x"]=1
        out+=( "$x" )

    done

    in=( "${out[@]}" )

}
validate_alias () {

    local a="${1:-}"

    [[ -n "${a}" ]] || die "Invalid alias: ${a}"
    [[ "${a}" != *"/"* && "${a}" != *"\\"* ]] || die "Invalid alias: ${a}"
    [[ "${a}" =~ ^[A-Za-z_][A-Za-z0-9_-]*$ ]] || die "Invalid alias: ${a}"

    return 0

}
config_file () {

    local name="${1:-}" ext1="${2:-}" ext2="${3:-}" file=""

    [[ -n "${ext1}" && -f "${name}.${ext1}" ]]  && file="${name}.${ext1}"
    [[ -n "${ext1}" && -f ".${name}.${ext1}" ]] && file=".${name}.${ext1}"
    [[ -n "${ext2}" && -f "${name}.${ext2}" ]]  && file="${name}.${ext2}"
    [[ -n "${ext2}" && -f ".${name}.${ext2}" ]] && file=".${name}.${ext2}"

    printf '%s\n' "${file}"

}
which_lang () {

    local dir="${1:-${PWD}}" p=""

    [[ -d "${dir}" ]] || dir="$(dirname -- "${dir}")"
    [[ -d "${dir}" ]] || { printf '%s' "null"; return 0; }

    while :; do

        if [[ -f "${dir}/Cargo.toml" ]]; then
            printf '%s' "rust"
            return 0
        fi
        if [[ -f "${dir}/go.mod" ]]; then
            printf '%s' "go"
            return 0
        fi
        if [[ -f "${dir}/conanfile.txt" || -f "${dir}/conanfile.py" || -f "${dir}/CMakeLists.txt" || -f "${dir}/Makefile" ]]; then
            printf '%s' "c"
            return 0
        fi
        if [[ -f "${dir}/pyproject.toml" || -f "${dir}/requirements.txt" || -f "${dir}/Pipfile" || -f "${dir}/poetry.lock" ]]; then
            printf '%s' "py"
            return 0
        fi
        if [[ -f "${dir}/artisan" || -f "${dir}/composer.json" ]]; then
            printf '%s' "php"
            return 0
        fi
        if [[ -f "${dir}/package.json" ]]; then
            printf '%s' "node"
            return 0
        fi

        p="$(dirname -- "${dir}")"
        [[ "${p}" != "${dir}" ]] || break
        dir="${p}"

    done

    printf '%s' "null"

}
ignore_list () {

    printf '%s\n' \
        ".git" \
        ".vscode" \
        ".idea" \
        ".DS_Store" \
        "Thumbs.db" \
        "out" \
        "coverage" \
        "target" \
        "dist" \
        "build" \
        "vendor" \
        "node_modules" \
        "__pycache__" \
        ".venv" \
        "venv" \
        ".pytest_cache" \
        ".mypy_cache" \
        ".ruff_cache" \
        ".cache" \
        ".nyc_output" \
        ".next" \
        ".nuxt" \
        ".turbo"

}

tmp_dir () {

    local tag="${1:-tmp}" tmpdir="${2:-${TMPDIR:-/tmp}}" tmp=""

    mkdir -p -- "${tmpdir}" 2>/dev/null || true
    tmp="$(mktemp -d "${tmpdir}/${tag}.XXXXXX" 2>/dev/null || true)"

    if [[ -z "${tmp}" || ! -d "${tmp}" ]]; then
        tmp="${tmpdir}/${tag}.$$.$RANDOM"
        mkdir -p -- "${tmp}" 2>/dev/null || die "tmp_dir: failed (${tmpdir})"
        chmod 700 -- "${tmp}" 2>/dev/null || true
    fi

    printf '%s' "${tmp}"

}
tmp_file () {

    local tag="${1:-tmp}" tmpdir="${2:-${TMPDIR:-/tmp}}"

    local dir="$(tmp_dir "${tag}" "${tmpdir}")"
    local tmp="${dir}/${tag}"

    : > "${tmp}" 2>/dev/null || die "tmp_file: failed (${dir})"
    printf '%s' "${tmp}"

}
ensure_dir () {

    local dir="${1:-}"

    [[ -n "${dir}" ]] || die "ensure_dir: missing dir"
    [[ -d "${dir}" ]] && return 0

    run mkdir -p -- "${dir}"

}
ensure_file () {

    local file="${1:-}"

    [[ -n "${file}" ]] || die "ensure_file: missing file"
    [[ -f "${file}" ]] && return 0

    ensure_dir "$(dirname -- "${file}")"
    run touch -- "${file}"

}
ensure_symlink () {

    local src="${1:-}" dst="${2:-}"
    [[ -n "${src}" && -n "${dst}" ]] || die "ensure_symlink: usage: ensure_symlink <src> <dst>"

    run rm -rf -- "${dst}" 2>/dev/null || true
    run ln -s "${src}" "${dst}"

}
ensure_bin_link () {

    local alias_name="${1:-}"
    local target="${2:-}"
    local prefix="${3:-${HOME}/.local}"
    local bin_dir="${prefix}/bin"
    local bin_path="${bin_dir}/${alias_name}"

    [[ -n "${target}" ]] || die "ensure_bin_link: missing target"
    validate_alias "${alias_name}"

    ensure_dir "${bin_dir}"
    ensure_symlink "${target}" "${bin_path}"

}
ensure_pkg () {

    local cmd="${1:-}" pkg="${2:-}" sudo_cmd=""

    [[ -n "${cmd}" ]] || die "ensure_pkg: missing command"
    [[ -n "${pkg}" ]] || pkg="${cmd}"

    has "${cmd}" && return 0

    if (( "$(id -u 2>/dev/null || printf '1')" != 0 )); then
        has sudo || die "Missing sudo (cannot install ${pkg})"
        sudo_cmd="sudo"
    fi

    if has apt-get; then
        run ${sudo_cmd} apt-get update -y
        run ${sudo_cmd} apt-get install -y "${pkg}"
        has "${cmd}" && return 0
    elif has dnf; then
        run ${sudo_cmd} dnf install -y "${pkg}"
        has "${cmd}" && return 0
    elif has yum; then
        run ${sudo_cmd} yum install -y "${pkg}"
        has "${cmd}" && return 0
    elif has pacman; then
        run ${sudo_cmd} pacman -Syu --noconfirm "${pkg}"
        has "${cmd}" && return 0
    elif has apk; then
        run ${sudo_cmd} apk add --no-cache "${pkg}"
        has "${cmd}" && return 0
    elif has brew; then
        run brew install "${pkg}"
        has "${cmd}" && return 0
    fi

    die "Cannot install '${pkg}'"

}
