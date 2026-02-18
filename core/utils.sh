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

    local name="${1:-}" ext1="${2:-}" ext2="${3:-}"
    local base="${name%%-*}"

    if [[ -n "${ext1}" && -f "${name}.${ext1}" ]]; then printf '%s\n' "${name}.${ext1}"; return 0; fi
    if [[ -n "${ext1}" && -f ".${name}.${ext1}" ]]; then printf '%s\n' ".${name}.${ext1}"; return 0; fi
    if [[ -n "${ext2}" && -f "${name}.${ext2}" ]]; then printf '%s\n' "${name}.${ext2}"; return 0; fi
    if [[ -n "${ext2}" && -f ".${name}.${ext2}" ]]; then printf '%s\n' ".${name}.${ext2}"; return 0; fi

    if [[ "${base}" != "${name}" ]]; then
        if [[ -n "${ext1}" && -f "${base}.${ext1}" ]]; then printf '%s\n' "${base}.${ext1}"; return 0; fi
        if [[ -n "${ext1}" && -f ".${base}.${ext1}" ]]; then printf '%s\n' ".${base}.${ext1}"; return 0; fi
        if [[ -n "${ext2}" && -f "${base}.${ext2}" ]]; then printf '%s\n' "${base}.${ext2}"; return 0; fi
        if [[ -n "${ext2}" && -f ".${base}.${ext2}" ]]; then printf '%s\n' ".${base}.${ext2}"; return 0; fi
    fi

    printf '\n'

}
ignore_list () {

    printf '%s\n' \
        ".git" \
        ".vscode" \
        ".idea" \
        ".DS_Store" \
        "Thumbs.db" \
        \
        "out" \
        "dist" \
        "build" \
        "coverage" \
        "target" \
        "vendor" \
        \
        "node_modules" \
        ".nyc_output" \
        ".next" \
        ".nuxt" \
        ".turbo" \
        \
        "__pycache__" \
        ".venv" \
        "venv" \
        ".pytest_cache" \
        ".mypy_cache" \
        ".ruff_cache" \
        ".cache" \
        \
        ".dart_tool" \
        ".flutter-plugins" \
        ".flutter-plugins-dependencies" \
        "pubspec.lock" \
        \
        ".gradle" \
        ".mvn" \
        "obj" \
        ".vs" \
        \
        ".xmake" \
        ".build" \
        ".ccls-cache" \
        "compile_commands.json" \
        \
        ".zig-cache" \
        "zig-out" \
        \
        ".mojo" \
        ".modular"

}
which_lang () {

    local dir="${1:-${PWD}}"

    [[ -d "${dir}" ]] || dir="$(dirname "${dir}")"
    [[ -d "${dir}" ]] || { printf '%s' "null"; return 0; }

    while :; do

        if [[ -f "${dir}/Cargo.toml" ]]; then
            printf '%s' "rust"
            return 0
        fi
        if [[ -f "${dir}/build.zig" || -f "${dir}/build.zig.zon" ]]; then
            printf '%s' "zig"
            return 0
        fi
        if [[ -f "${dir}/go.mod" || -f "${dir}/go.work" ]]; then
            printf '%s' "go"
            return 0
        fi
        if compgen -G "${dir}/*.sln" >/dev/null || compgen -G "${dir}/*.csproj" >/dev/null || compgen -G "${dir}/*.fsproj" >/dev/null || [[ -f "${dir}/Directory.Build.props" || -f "${dir}/Directory.Build.targets" || -f "${dir}/global.json" ]]; then
            printf '%s' "csharp"
            return 0
        fi
        if [[ -f "${dir}/settings.gradle" || -f "${dir}/settings.gradle.kts" || -f "${dir}/build.gradle" || -f "${dir}/build.gradle.kts" || -f "${dir}/pom.xml" || -f "${dir}/gradlew" || -f "${dir}/mvnw" ]]; then
            printf '%s' "java"
            return 0
        fi
        if [[ -f "${dir}/pubspec.yaml" ]]; then
            printf '%s' "dart"
            return 0
        fi
        if [[ -f "${dir}/composer.json" || -f "${dir}/artisan" ]]; then
            printf '%s' "php"
            return 0
        fi
        if [[ -f "${dir}/pyproject.toml" || -f "${dir}/uv.toml" || -f "${dir}/uv.lock" || -f "${dir}/requirements.txt" || -f "${dir}/Pipfile" || -f "${dir}/poetry.lock" ]]; then
            printf '%s' "python"
            return 0
        fi
        if [[ -f "${dir}/mojoproject.toml" || -f "${dir}/mod.toml" || -n "$(find "${dir}" -maxdepth 3 -type f -name '*.mojo' -print -quit 2>/dev/null || true)" ]]; then
            printf '%s' "mojo"
            return 0
        fi
        if [[ -f "${dir}/bun.lockb" || -f "${dir}/bun.lock" || -f "${dir}/bunfig.toml" ]]; then
            printf '%s' "bun"
            return 0
        fi
        if [[ -f "${dir}/package.json" ]]; then
            printf '%s' "node"
            return 0
        fi
        if [[ -f "${dir}/xmake.lua" || -f "${dir}/CMakeLists.txt" || -f "${dir}/meson.build" || -f "${dir}/Makefile" || -f "${dir}/conanfile.txt" || -f "${dir}/conanfile.py" ]]; then

            local hit="$(find "${dir}" -maxdepth 6 -type f \( \
                -name '*.cpp' -o -name '*.cc' -o -name '*.cxx' -o -name '*.C' -o \
                -name '*.hpp' -o -name '*.hh' -o -name '*.hxx' -o \
                -name '*.ipp' -o -name '*.inl' -o \
                -name '*.ixx' -o -name '*.cppm' -o -name '*.cxxm' \
            \) -print -quit 2>/dev/null || true)"

            if [[ -n "${hit}" ]]; then
                printf '%s' "cpp"
                return 0
            fi

            printf '%s' "c"
            return 0

        fi
        if [[ -f "${dir}/rocks.toml" ]] || compgen -G "${dir}/*.rockspec" >/dev/null; then
            printf '%s' "lua"
            return 0
        fi
        if [[ -n "$(find "${dir}" -maxdepth 2 -type f -name '*.lua' -print -quit 2>/dev/null || true)" ]]; then
            printf '%s' "lua"
            return 0
        fi
        if [[ -n "$(find "${dir}" -maxdepth 2 -type f -name '*.sh' -print -quit 2>/dev/null || true)" ]]; then
            printf '%s' "bash"
            return 0
        fi
        if [[ "$(dirname "${dir}")" != "${dir}" ]]; then
            dir="$(dirname "${dir}")"
            continue
        fi

        break

    done

    printf '%s' "null"

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
