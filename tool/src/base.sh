#!/usr/bin/env bash
set -Eeuo pipefail

APP_NAME="${APP_NAME:-gun}"
APP_TARGET="${APP_TARGET:-release}"
APP_VERSION="${APP_VERSION:-0.1.0}"
APP_BASH_VERSION="${APP_BASH_VERSION:-5.2}"

ROOT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)"
BUILD_DIR="${ROOT_DIR}/target"
SOURCE_DIR="${ROOT_DIR}/src"
ENTRY_FILE="${ROOT_DIR}/src/main.sh"

declare -A APP_MODS=()
declare -a APP_SRCS=()
declare -a APP_TESTS=()
declare -a APP_TEMPS=()

cleanup () {

    for file in "${APP_TEMPS[@]}"; do
        [[ -n "${file:-}" && -e "${file}" ]] || continue
        rm -f -- "${file}" 2>/dev/null || true
    done

    APP_TEMPS=()

}
exec_file () {

    local file="${1:-}"
    chmod +x "${file}" 2>/dev/null || true

}
out_file () {

    local name="${1:-${APP_NAME}}"
    local target="${2:-${APP_TARGET}}"
    local dir="${3:-${BUILD_DIR}}"

    [[ "${name}" == *.sh ]] || name="${name}.sh"
    printf '%s\n' "${dir}/${target}/${name}"

}
tmp_file () {

    local ref="${1:-}" path="${2:-/tmp}" mkt_file=""

    if [[ -z "${ref}"  ]]; then
        printf '[ERR]: missing output variable name\n' >&2
        return 1
    fi
    if [[ ! -d "${path}" ]] && ! path="$(dirname -- "${path}")"; then
        printf '[ERR]: failed to detect dirname of: %s\n' "${path}" >&2
        return 1
    fi
    if ! mkt_file="$(mktemp "${path}/.out.tmp.XXXXXX")"; then
        printf '[ERR]: failed to create temp file in dir: %s\n' "${path}" >&2
        return 1
    fi

    APP_TEMPS+=( "${mkt_file}" )

    local -n out_ref="${ref}"
    out_ref="${mkt_file}"

}
bin_file () {

    local file="${1:-}" name=""

    if [[ ! -f "${file}" ]]; then
        printf '[ERR]: file not found: %s\n' "${file}" >&2
        return 1
    fi

    name="${file##*/}"
    name="${name%.sh}"

    if [[ -n "${XDG_BIN_HOME:-}" ]]; then
        printf '%s\n' "${XDG_BIN_HOME}/${name}"
        return 0
    fi

    printf '%s\n' "${HOME}/.local/bin/${name}"

}
mkdir_file () {

    local file="${1:-}" dir=""

    if ! dir="$(dirname -- "${file}")"; then
        printf '[ERR]: failed to detect dirname of: %s\n' "${file}" >&2
        return 1
    fi
    if [[ -d "${file}" ]]; then
        printf '[ERR]: file is a directory: %s\n' "${file}" >&2
        return 1
    fi
    if ! mkdir -p -- "${dir}"; then
        printf '[ERR]: failed to create directory: %s\n' "${dir}" >&2
        return 1
    fi

}
copy_file () {

    local file="${1:-}" dest="${2:-}"

    if ! cp -- "${file}" "${dest}"; then
        printf '[ERR]: failed to copy file: %s -> %s\n' "${file}" "${dest}" >&2
        return 1
    fi

}
move_file () {

    local file="${1:-}" dest="${2:-}"

    if ! mv -- "${file}" "${dest}"; then
        printf '[ERR]: failed to move temp file: %s -> %s\n' "${file}" "${dest}" >&2
        return 1
    fi

}
minify_file () {

    local file="${1:-}"
    shift || true

    if [[ ! -f "${file}" ]]; then
        printf '[ERR]: file not found: %s\n' "${file}" >&2
        return 1
    fi
    if ! shfmt -ln=bash -s -mn -w "${file}" "$@"; then
        printf '[ERR]: minify file failed: %s\n' "${file}" >&2
        return 1
    fi

}
verify_file () {

    local file="${1:-}" shellcheck="${2:-0}"
    shift 2 || true

    if [[ ! -f "${file}" ]]; then
        printf '[ERR]: file not found: %s\n' "${file}" >&2
        return 1
    fi
    if ! bash -n "${file}"; then
        printf '[ERR]: verify file failed: %s\n' "${file}" >&2
        return 1
    fi
    if (( shellcheck )) && ! shellcheck -e SC2317 "${file}" "$@"; then
        printf '[ERR]: verify file failed: %s\n' "${file}" >&2
        return 1
    fi

}
