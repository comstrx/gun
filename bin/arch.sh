
readonly APP_NAME="gun"
readonly APP_VERSION="0.1.0"

readonly ROOT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd -P)"
readonly BUILD_DIR="${ROOT_DIR}/target"
readonly SOURCE_DIR="${ROOT_DIR}/src"
readonly ENTRY_FILE="${ROOT_DIR}/src/main.sh"
readonly TOML_FILE="${ROOT_DIR}/Bash.toml"

declare -A APP_CONTEXT=()
declare -a APP_FILES=()

map_toml () {

    local map_name="${1:-}" file="${2:-${TOML_FILE:-bash.toml}}"
    local line="" num=0 section="" key="" value="" full="" match=""

    if [[ ! -f "${file}" ]]; then

        local dir="$(dirname -- "${file}")"
        local base="$(basename -- "${file}")"

        [[ -d "${dir}" ]] || dir="."

        while IFS= read -r match; do
            file="${dir%/}/${match}"
            break
        done < <(find "${dir}" -maxdepth 1 -type f \( -iname "${base}" \) -printf '%f\n' 2>/dev/null)

    fi
    if [[ ! -f "${file}" ]]; then
        printf '[ERR]: toml file not found: %s\n' "${file}" >&2
        return 1
    fi
    if [[ -z "${map_name}" ]]; then
        printf '[ERR]: missing output map name\n' >&2
        return 1
    fi

    local -n out="${map_name}"
    out=()

    while IFS= read -r line || [[ -n "${line}" ]]; do

        (( num++ ))

        line="${line%$'\r'}"
        line="${line#"${line%%[![:space:]]*}"}"
        line="${line%"${line##*[![:space:]]}"}"

        if [[ -z "${line}" || "${line}" == \#* ]]; then
            continue
        fi
        if [[ "${line}" =~ ^\[([A-Za-z0-9_.-]+)\]$ ]]; then
            section="${BASH_REMATCH[1]}"
            continue
        fi
        if [[ "${line}" != *=* ]]; then
            printf '[ERR]: invalid toml syntax at line %s: %s\n' "${num}" "${line}" >&2
            return 1
        fi

        key="${line%%=*}"
        value="${line#*=}"

        key="${key#"${key%%[![:space:]]*}"}"
        key="${key%"${key##*[![:space:]]}"}"

        value="${value#"${value%%[![:space:]]*}"}"
        value="${value%"${value##*[![:space:]]}"}"

        if [[ ! "${key}" =~ ^[A-Za-z0-9_.-]+$ ]]; then
            printf '[ERR]: invalid toml key at line %s: %s\n' "${num}" "${key}" >&2
            return 1
        fi

        if [[ "${value}" == \"*\" ]]; then

            if [[ ! "${value}" =~ ^\"([^\"\\]|\\.)*\"$ ]]; then
                printf '[ERR]: invalid double-quoted string at line %s\n' "${num}" >&2
                return 1
            fi

            value="${value:1:${#value}-2}"
            value="${value//\\n/$'\n'}"
            value="${value//\\t/$'\t'}"
            value="${value//\\r/$'\r'}"
            value="${value//\\\"/\"}"
            value="${value//\\\\/\\}"

        elif [[ "${value}" == \'*\' ]]; then

            if [[ ! "${value}" =~ ^\'.*\'$ ]]; then
                printf '[ERR]: invalid single-quoted string at line %s\n' "${num}" >&2
                return 1
            fi

            value="${value:1:${#value}-2}"

        elif [[ "${value}" =~ ^(true|false)$ || "${value}" =~ ^-?[0-9]+$ || "${value}" =~ ^-?([0-9]+\.[0-9]+|\.[0-9]+|[0-9]+\.)$ ]]; then

            :

        else

            printf '[ERR]: unsupported toml value at line %s: %s\n' "${num}" "${value}" >&2
            return 1

        fi

        full="${key}"
        [[ -n "${section}" ]] && full="${section}.${key}"

        if [[ -v "out[${full}]" ]]; then
            printf '[ERR]: duplicate toml key at line %s: %s\n' "${num}" "${full}" >&2
            return 1
        fi

        out["${full}"]="${value}"

    done < "${file}"

}
meta_build () {

    local key=""
    local -A meta=()

    map_toml meta "$@" || return 1

    printf 'meta(){ local key="${1:-}"; case "${key}" in\n'

    while IFS= read -r key; do
        printf '%q) printf '\''%%s\\n'\'' %q ;;\n' "${key}" "${meta["${key}"]}"
    done < <(printf '%s\n' "${!meta[@]}" | sort)

    printf '*) return 1 ;;\nesac; }\n'

}


use () {

    local mod="${1:-}"
    local path="${SOURCE_DIR}/${mod//::/\/}"
    local file="${path%.sh}.sh"

    [[ -n "${mod}" ]] || { printf '[ERR]: missing module name\n' >&2; return 1; }
    [[ -n "${APP_CONTEXT["mod::${file}"]:-}" ]] && return 0
    [[ -n "${APP_CONTEXT["mod::${path}/mod.sh"]:-}" ]] && return 0
    [[ -f "${file}" ]] || file="${path%.sh}/mod.sh"

    builtin source "${file}" || { printf '[ERR]: failed to load module: %s\n' "${file}" >&2; return 1; }
    APP_CONTEXT["mod::${file}"]="loaded"
    [[ "${file}" == "${ENTRY_FILE}" ]] || APP_FILES+=( "${file}" )

}
build () {

    APP_CONTEXT=()
    APP_FILES=()

    local target="${1:-release}" bin_dir="" path=""
    local name="${2:-${APP_NAME:-run}}"
    local out="${BUILD_DIR}/${target}/${name}"

    [[ "${out}" == *.sh ]] || out="${out}.sh"
    bin_dir="$(dirname -- "${out}")"

    mkdir -p -- "${bin_dir}" || { printf '[ERR]: failed to create output directory: %s\n' "${bin_dir}" >&2; return 1; }
    builtin source "${ENTRY_FILE}" || { printf '[ERR]: failed to load entry file: %s\n' "${ENTRY_FILE}" >&2; return 1; }
    declare -F main >/dev/null || { printf '[ERR]: missing required function: main\n' >&2; return 1; }

    {

        printf '#!/usr/bin/env bash\n'
        printf 'set -Eeuo pipefail\n\n'

        printf 'use () { return 0; }\n'
        printf 'readonly -f use\n\n'

        meta_build
        printf 'readonly -f meta\n\n'

        for path in "${APP_FILES[@]}"; do
            cat -- "${path}" || { printf '[ERR]: failed to load source file: %s\n' "${path}" >&2; return 1; }
            printf '\n'
        done

        cat -- "${ENTRY_FILE}" || { printf '[ERR]: failed to load entry file: %s\n' "${ENTRY_FILE}" >&2; return 1; }
        printf '\n'

        printf 'start () {\n\n'
        printf '    main "$@"\n'
        printf '    exit $?\n\n'
        printf '}\n\n'
        printf 'start "$@"\n'

    } > "${out}" || { printf '[ERR]: failed to write output file: %s\n' "${out}" >&2; return 1; }

    if command -v shellcheck >/dev/null 2>&1; then
        shellcheck "${out}" || { printf '[ERR]: shellcheck failed: %s\n' "${out}" >&2; return 1; }
    fi
    if command -v shfmt >/dev/null 2>&1; then
        shfmt -ln=bash -s -mn -w "${out}" || { printf '[ERR]: shfmt failed: %s\n' "${out}" >&2; return 1; }
    fi

    chmod +x "${out}" 2>/dev/null || true
    printf '%s\n' "${out}"

}
install () {

    local target="${1:-release}" out="" dest=""
    local name="${2:-${APP_NAME:-run}}"
    local bin_dir="${3:-${HOME}/.local/bin}"

    out="$(build "${target}" "${name}")" || return 1
    dest="${bin_dir}/${name}"
    [[ "${dest}" == *.sh ]] && dest="${dest%.sh}"

    mkdir -p -- "${bin_dir}" || { printf '[ERR]: failed to create bin directory: %s\n' "${bin_dir}" >&2; return 1; }
    [[ -d "${dest}" ]] && { printf '[ERR]: destination is a directory: %s\n' "${dest}" >&2; return 1; }
    cp -- "${out}" "${dest}" || { printf '[ERR]: failed to copy file: %s -> %s\n' "${out}" "${dest}" >&2; return 1; }

    chmod +x "${dest}" 2>/dev/null || true
    printf '%s\n' "${dest}"

}
run () {

    local out=""
    out="$(build)" || return 1
    "${out}" "$@"

}
