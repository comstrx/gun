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

# Helpers

cleanup () {
    
    for file in "${APP_TEMPS[@]}"; do

        [[ -n "${file:-}" && -e "${file}" ]] || continue
        rm -f -- "${file}" 2>/dev/null || true

    done

    APP_TEMPS=()

}
tmp_file () {

    local dir="${1:-/tmp}" tmp=""

    if [[ -f "${dir}" ]] && ! dir="$(dirname -- "${dir}")"; then
        printf '[ERR]: failed to detect dirname of: %s\n' "${1:-}" >&2
        return 1
    fi
    if ! tmp="$(mktemp "${dir}/.out.tmp.XXXXXX")"; then
        printf '[ERR]: failed to create temp file in dir: %s\n' "${dir}" >&2
        return 1
    fi

    APP_TEMPS+=( "${tmp}" )
    printf '%s\n' "${tmp}"

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

    local out="${dir}/${target}/${name}"
    printf '%s\n' "${out}"

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
    if (( shellcheck )) && ! shellcheck -e SC2317  "${file}" "$@"; then
        printf '[ERR]: verify file failed: %s\n' "${file}" >&2
        return 1
    fi

}

# Source Mods

use_mod () {

    local line="${1:-}" file=""

    line="${line%$'\r'}"

    [[ "${line}" =~ ^[[:space:]]*use[[:space:]]+([A-Za-z_][A-Za-z0-9_.-]*(::[A-Za-z_][A-Za-z0-9_.-]*)*)[[:space:]]*([#].*)?$ ]] || return 1

    file="${BASH_REMATCH[1]}"
    [[ "${file}" != *..* ]] || return 1
    [[ "${file}" != *--* ]] || return 1
    [[ "${file}" != *.-* ]] || return 1
    [[ "${file}" != *-. ]] || return 1

    printf '%s\n' "${file}"

}
load_mod () {

    local mod="${1:-}" path="" file=""

    if [[ -z "${mod}" ]]; then
        printf '[ERR]: missing module name\n' >&2
        return 1
    fi

    path="${SOURCE_DIR}/${mod//::/\/}"
    file="${path%.sh}.sh"

    [[ -f "${file}" ]] || file="${path%.sh}/mod.sh"

    if [[ ! -f "${file}" ]]; then
        printf '[ERR]: module not found: %s\n' "${mod}" >&2
        return 1
    fi

    printf '%s\n' "${file}"

}
entry_mod () {

    local file="${ENTRY_FILE}" line=""

    if [[ ! -f "${file}" ]]; then
        printf '[ERR]: entry file not found: %s\n' "${file}" >&2
        return 1
    fi

    while IFS= read -r line || [[ -n "${line}" ]]; do

        line="${line%$'\r'}"
        [[ "${line}" =~ ^[[:space:]]*(function[[:space:]]+)?main[[:space:]]*\(\)[[:space:]]*\{[[:space:]]*([#].*)?$ ]] && return 0

    done < "${file}" || { printf '[ERR]: unable to load file: %s\n' "${file}" >&2; return 1; }

    printf '[ERR]: missing required function: main\n' >&2
    return 1

}
walk_mods () {

    local file="${1:-${ENTRY_FILE}}" line="" mod="" dep=""

    if [[ ! -f "${file}" ]]; then
        printf '[ERR]: file not found: %s\n' "${file}" >&2
        return 1
    fi

    [[ -n "${APP_MODS["${file}"]:-}" ]] && return 0
    APP_MODS["${file}"]="loaded"

    while IFS= read -r line || [[ -n "${line}" ]]; do

        line="${line%$'\r'}"

        mod="$(use_mod "${line}")" || continue
        dep="$(load_mod "${mod}")" || return 1

        walk_mods "${dep}" || return 1

    done < "${file}" || { printf '[ERR]: unable to load file: %s\n' "${file}" >&2; return 1; }

    [[ "${file}" == "${ENTRY_FILE}" ]] || APP_SRCS+=( "${file}" )

}
build_mods () {

    local line=""

    for path in "${APP_SRCS[@]}" "${ENTRY_FILE}"; do

        while IFS= read -r line || [[ -n "${line}" ]]; do

            use_mod "${line}" >/dev/null && continue
            printf '%s\n' "${line%$'\r'}"

        done < "${path}" || { printf '[ERR]: unable to read file: %s\n' "${path}" >&2; return 1; }

    done

}

# Source Tests

read_test () {

    local file="${1:-}" line="" fn="" mark=0

    if [[ ! -f "${file}" ]]; then
        printf '[ERR]: file not found: %s\n' "${file}" >&2
        return 1
    fi

    while IFS= read -r line || [[ -n "${line}" ]]; do

        line="${line%$'\r'}"

        if [[ "${line}" =~ ^[[:space:]]*##?[[:space:]]*@?test[[:space:]]*$ ]]; then
            mark=1
            continue
        fi
        if [[ "${line}" =~ ^[[:space:]]*(function[[:space:]]+)?([A-Za-z_][A-Za-z0-9_]*)[[:space:]]*\(\)[[:space:]]*\{ ]]; then

            fn="${BASH_REMATCH[2]}"

            if (( mark )) || [[ "${fn}" == test_* ]]; then
                printf '%s\n' "${fn}"
            fi

            mark=0
            continue

        fi

        [[ "${line}" =~ ^[[:space:]]*$ ]] && continue
        mark=0

    done < "${file}" || { printf '[ERR]: unable to load file: %s\n' "${file}" >&2; return 1; }

}
walk_tests () {

    local file="" fn=""
    local -A seen=() loaded=()

    for file in "${APP_SRCS[@]}" "${ENTRY_FILE}"; do

        [[ -f "${file}" ]] || continue
        [[ -z "${loaded[${file}]:-}" ]] || continue

        loaded["${file}"]=1

        while IFS= read -r fn || [[ -n "${fn}" ]]; do

            [[ -n "${fn}" ]] || continue
            [[ -z "${seen[${fn}]:-}" ]] || continue

            seen["${fn}"]=1
            APP_TESTS+=( "${fn}" )

        done < <(read_test "${file}") || return 1

    done

}
build_tests () {

    local fn="" short=""
    local -A seen=()

    printf '%s\n' "
        ___app_resolve_test___ () {

            local want=\"\${1:-}\"

            [[ -n \"\${want}\" ]] || return 1
            [[ -n \"\${___APP_TEST_MAP___[\${want}]:-}\" ]] || return 1

            printf '%s\n' \"\${___APP_TEST_MAP___[\${want}]}\"

        }
        ___app_run_tests___ () {

            local fn=\"\" rc=0 pass=0 fail=0
            local -a tests=( \"\$@\" )

            (( \${#tests[@]} )) || { printf '[INFO]: no test functions found\n' >&2; return 1; }

            for fn in \"\${tests[@]}\"; do

                printf '==> %s\n' \"\${fn}\"

                if \"\${fn}\"; then
                    printf '[PASS]: %s\n' \"\${fn}\"
                    (( pass++ ))
                else
                    printf '[FAIL]: %s\n' \"\${fn}\" >&2
                    (( fail++ ))
                    rc=1
                fi

                printf '\n'

            done

            printf '[INFO]: total=%s pass=%s fail=%s\n' \"\${#tests[@]}\" \"\${pass}\" \"\${fail}\"
            return \"\${rc}\"

        }
        ___app_test___ () {

            local target=\"\" resolved=\"\"

            if (( \$# == 0 )); then
                ___app_run_tests___ \"\${___APP_TESTS_LIST___[@]}\"
                return \$?
            fi

            target=\"\${1:-}\"
            shift || true

            if ! resolved=\"\$(___app_resolve_test___ \"\${target}\" 2>/dev/null)\"; then
                printf '[FAIL]: test not found: %s\n' \"\${target}\" >&2
                return 1
            fi

            printf '==> %s\n' \"\${resolved}\"

            if \"\${resolved}\" \"\$@\"; then
                printf '[PASS]: %s\n' \"\${resolved}\"
                printf '[INFO]: total=1 pass=1 fail=0\n'
                return 0
            fi

            printf '[FAIL]: %s\n' \"\${resolved}\" >&2
            printf '[INFO]: total=1 pass=0 fail=1\n' >&2
            return 1

        }
        ___app_tests___ () {

            local fn=\"\"

            for fn in \"\${___APP_TESTS_LIST___[@]}\"; do
                printf '%s\n' \"\${fn}\"
            done

        }
    "

    printf 'declare -ag ___APP_TESTS_LIST___=(\n'

    for fn in "${APP_TESTS[@]}"; do
        printf '%q\n' "${fn}"
    done

    printf ')\n'

    printf 'declare -Ag ___APP_TEST_MAP___=(\n'

    for fn in "${APP_TESTS[@]}"; do

        if [[ -z "${seen[${fn}]:-}" ]]; then
            seen["${fn}"]=1
            printf '[%q]=%q\n' "${fn}" "${fn}"
        fi
        if [[ "${fn}" == test_* && "${fn}" != test_ ]]; then

            short="${fn#test_}"

            if [[ -n "${short}" && -z "${seen[${short}]:-}" ]]; then
                seen["${short}"]=1
                printf '[%q]=%q\n' "${short}" "${fn}"
            fi

        fi

    done

    printf ')\n'

}

# Checksum 

new_checksum () {

    local -a targets=( "${SOURCE_DIR}" )

    if ! find "${targets[@]}" -type f -exec sha256sum {} + | LC_ALL=C sort | sha256sum | awk '{print $1}'; then
        printf '[ERR]: failed to calculate sha256sum\n' >&2
        return 1
    fi

}
read_checksum () {

    local file="${1:-}"

    [[ -f "${file}" ]] || return 1
    sed -n "s/^readonly ___APP_SRC_CHECKSUM___='\(.*\)'$/\1/p" "${file}" | head -n 1 || return 1

}
check_checksum () {

    local file="${1:-}" old="" new=""

    old="$(read_checksum "${file}")" || return 1
    new="$(new_checksum)" || return 1

    [[ "${old}" == "${new}" ]]

}
build_checksum () {

    local sum=""
    sum="$(new_checksum)" || return 1
    printf "readonly ___APP_SRC_CHECKSUM___='%s'\n" "${sum}"

}

# Build

build_content () {

    printf '#!/usr/bin/env bash\n'
    printf 'set -Eeuo pipefail\n'

    build_mods     || return 1
    build_tests    || return 1
    build_checksum || return 1

    printf '%s\n' "
        ___app_main___ () {

            main \"\$@\"

        }
        ___app_start___ () {

            local cmd=\"\${1:-}\"
            shift || true

            case \"\${cmd}\" in
                --test)  ___app_test___  \"\$@\" ;;
                --tests) ___app_tests___ \"\$@\" ;;
                *)       ___app_main___  \"\$@\" ;;
            esac

        }
        ___app_start___ \"\$@\"
        exit \$?
    "
}
build_file () {

    local out="${1:-}" logs="${2:-0}" tmp=""
    shift 2 || true

    mkdir_file "${out}" || return 1
    entry_mod           || return 1
    walk_mods           || return 1
    walk_tests          || return 1

    tmp="$(tmp_file "${out}")" || return 1
    { build_content || return 1; } > "${tmp}" || return 1

    verify_file "${tmp}"          || return 1
    minify_file "${tmp}"          || return 1
    move_file   "${tmp}" "${out}" || return 1
    exec_file   "${out}"          || return 1

    (( ! logs )) || printf '[DONE]: %s\n' "${out}"

}

# Actions

install () {

    local out="${1:-}" dest=""

    build_file "${out}" || return 1

    dest="$(bin_file "${out}")" || return 1

    mkdir_file "${dest}"          || return 1
    copy_file  "${out}" "${dest}" || return 1

    printf '[DONE]: %s\n' "${dest}"

}
build () {

    local out="${1:-}"
    shift || true
    build_file "${out}" 1 || return 1

}
check () {

    local out="${1:-}"
    shift || true

    if ! check_checksum "${out}"; then
        build_file "${out}" || return 1
    fi

    verify_file "${out}" 1 || return 1

}
test () {

    local out="${1:-}"
    shift || true

    if ! check_checksum "${out}"; then
        build_file "${out}" || return 1
    fi

    "${out}" --test "$@"

}
run () {

    local out="${1:-}"
    shift || true

    if ! check_checksum "${out}"; then
        build_file "${out}" || return 1
    fi

    "${out}" "$@"

}

# Entry

meta () {

    local out="${1:-}" key="${2:-}"

    walk_mods || true

    case "${key}" in
        name)         printf '%s\n' "${APP_NAME}"; return 0 ;;
        version)      printf '%s\n' "${APP_VERSION}"; return 0 ;;
        bash-version) printf '%s\n' "${APP_BASH_VERSION}"; return 0 ;;
        src-dir)      printf '%s\n' "${SOURCE_DIR}"; return 0 ;;
        entry-file)   printf '%s\n' "${ENTRY_FILE}"; return 0 ;;
        build-dir)    printf '%s\n' "${BUILD_DIR}"; return 0 ;;
        mods)         printf '%s\n' "${!APP_MODS[@]}" | sort; return 0 ;;
        mods-count)   printf '%s\n' "${#APP_MODS[@]}"; return 0 ;;
        *)            printf '[ERR]: unknown meta key: %s\n' "${key}" >&2; return 1 ;;
    esac

}
route () {

    local cmd="${1:-}" name="${2:-}" target="${3:-}" dir="${4:-}"
    shift 4 || true

    local out=""
    out="$(out_file "${name}" "${target}" "${dir}")" || return 1

    case "${cmd}" in
        install) install "${out}" "$@" ;;
        build)   build   "${out}" "$@" ;;
        check)   check   "${out}" "$@" ;;
        test)    test    "${out}" "$@" ;;
        run)     run     "${out}" "$@" ;;
        meta)    meta    "${out}" "$@" ;;
        *)       printf '[ERR]: unknown command: %s\n' "${cmd}" >&2; return 1 ;;
    esac

}
usage () {

    printf '%s\n' \
        "Usage:" \
        "    ${0##*/} <command> [options] [args...]" \
        "" \
        "Commands:" \
        "    install                Install bin into ~/.local/bin" \
        "    build                  Build output bin" \
        "    check                  Validate bin with bash and shellcheck" \
        "    test                   Run embedded tests" \
        "    run                    Run output bin" \
        "" \
        "Options:" \
        "    -n, --name   [value]   Output bin name    [default: ${APP_NAME}]" \
        "    -t, --target [value]   Build bin target   [default: ${APP_TARGET}]" \
        "    -d, --dir    [value]   Explicit build dir [default: ${BUILD_DIR}]" \
        "    -h, --help             Show this help" \

}
main () {

    trap cleanup INT TERM EXIT

    local cmd="${1:-}" name="" target="" dir=""
    local -a rest=()

    case "${cmd}" in
        ""|help|-h|--help|-help)
            usage
            return 0
        ;;
    esac

    shift || true

    while (( $# )); do
        case "${1:-}" in
            --name|-n)
                [[ $# -ge 2 ]] || { printf '[ERR]: missing value for --name\n' >&2; return 1; }
                name="${2:-}"
                shift 2 || true
            ;;
            --target|-t)
                [[ $# -ge 2 ]] || { printf '[ERR]: missing value for --target\n' >&2; return 1; }
                target="${2:-}"
                shift 2 || true
            ;;
            --dir|-d)
                [[ $# -ge 2 ]] || { printf '[ERR]: missing value for --dir\n' >&2; return 1; }
                dir="${2:-}"
                shift 2 || true
            ;;
            --)
                shift || true
                rest+=( "$@" )
                break
            ;;
            *)
                rest+=( "${1}" )
                shift || true
            ;;
        esac
    done

    route "${cmd}" "${name}" "${target}" "${dir}" "${rest[@]}"
    return $?

}

main "$@"
