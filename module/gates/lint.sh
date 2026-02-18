#!/usr/bin/env bash

lint_git_files () {

    has git || return 1
    git rev-parse --is-inside-work-tree >/dev/null 2>&1 || return 1

    git ls-files "$@"

}
lint_check_c () {

    ensure_pkg clang-tidy

    [[ -f compile_commands.json ]] || die "lint-check: c requires compile_commands.json"

    local -a files=()
    local f=""

    if [[ $# -gt 0 ]]; then
        files=( "$@" )
    else
        while IFS= read -r f; do
            [[ -n "${f}" ]] && files+=( "${f}" )
        done < <(lint_git_files '*.c' 2>/dev/null || true)

        [[ ${#files[@]} -gt 0 ]] || die "lint-check: c requires file args"
    fi

    run clang-tidy -p . --warnings-as-errors='*' "${files[@]}"

}
lint_check_cpp () {

    ensure_pkg clang-tidy

    [[ -f compile_commands.json ]] || die "lint-check: cpp requires compile_commands.json"

    local -a files=()
    local f=""

    if [[ $# -gt 0 ]]; then
        files=( "$@" )
    else
        while IFS= read -r f; do
            [[ -n "${f}" ]] && files+=( "${f}" )
        done < <(lint_git_files \
            '*.cpp' '*.cc' '*.cxx' '*.C' \
            '*.ixx' '*.cppm' '*.cxxm' \
        2>/dev/null || true)

        [[ ${#files[@]} -gt 0 ]] || die "lint-check: cpp requires file args"
    fi

    run clang-tidy -p . --warnings-as-errors='*' "${files[@]}"

}
lint_check_rust () {

    ensure_pkg rustup
    run cargo +"${RUST_NIGHTLY:-nightly}" clippy --all-targets --all-features "$@" -- -D warnings

}
lint_check_zig () {

    ensure_pkg zig
    run zig build test "$@"

}
lint_check_go () {

    ensure_pkg golangci-lint

    local -a cmd=()
    local config="$(config_file golangci yml)"
    [[ -f "${config}" ]] && cmd+=( --config "${config}" )

    run golangci-lint run "${cmd[@]}" "$@"

}
lint_check_python () {

    ensure_pkg ruff pyright

    local -a cmd=() py_cmd=()

    local config="$(config_file ruff-lint toml)"
    [[ -f "${config}" ]] || config="$(config_file ruff toml)"
    [[ -f "${config}" ]] && cmd+=( --config "${config}" )

    run ruff check "${cmd[@]}" "$@" .

    local py_config="$(config_file pyrightconfig json)"
    [[ -f "${py_config}" ]] && py_cmd+=( --project "${py_config}" )

    run pyright "${py_cmd[@]}" "$@"

}
lint_check_mojo () {

    ensure_pkg mojo

    local out="${TMPDIR:-/tmp}/gun-mojo-lint.$RANDOM$RANDOM"
    local src="" i="" has_file=0

    for i in "$@"; do
        [[ "${i}" == *.mojo ]] && { has_file=1; break; }
    done

    if [[ ${has_file} -eq 0 ]]; then
        [[ -f ./src/main.mojo ]] && src="./src/main.mojo"
        [[ -z "${src}" && -f ./main.mojo ]] && src="./main.mojo"
        [[ -n "${src}" ]] || die "lint-check: mojo requires a .mojo file"
        run mojo build --no-optimization --Werror -o "${out}" "$@" "${src}"
    else
        run mojo build --no-optimization --Werror -o "${out}" "$@"
    fi

    rm -f "${out}" || true

}
lint_check_php () {

    ensure_pkg php

    local -a cmd=( phpstan analyse )
    [[ -x vendor/bin/phpstan ]] && cmd=( vendor/bin/phpstan analyse )

    local config="$(config_file phpstan neon)"
    [[ -f "${config}" ]] && cmd+=( -c "${config}" )

    run "${cmd[@]}" "$@" .

}
lint_check_node () {

    ensure_pkg npx

    local -a cmd=( npx -y @biomejs/biome check )
    [[ -x node_modules/.bin/biome ]] && cmd=( node_modules/.bin/biome check )

    local config="$(config_file biome-lint json)"
    [[ -f "${config}" ]] || config="$(config_file biome json)"
    [[ -f "${config}" ]] && cmd+=( --config-path "${config}" )

    run "${cmd[@]}" --error-on-warnings "$@" .

}
lint_check_bun () {

    ensure_pkg bun

    local -a cmd=( bunx @biomejs/biome check )
    [[ -x node_modules/.bin/biome ]] && cmd=( node_modules/.bin/biome check )

    local config="$(config_file biome-lint json)"
    [[ -f "${config}" ]] || config="$(config_file biome json)"
    [[ -f "${config}" ]] && cmd+=( --config-path "${config}" )

    run "${cmd[@]}" --error-on-warnings "$@" .

}
lint_check_csharp () {

    ensure_pkg dotnet
    run dotnet format --verify-no-changes "$@"

}
lint_check_java () {

    ensure_pkg java

    if [[ -x ./gradlew ]]; then
        run ./gradlew -q check "$@"
        return 0
    fi
    if [[ -x ./mvnw ]]; then
        run ./mvnw -q verify "$@"
        return 0
    fi

    die "lint-check: java requires gradlew/mvnw"

}
lint_check_dart () {

    ensure_pkg dart
    run dart analyze --fatal-infos --fatal-warnings "$@" .

}
lint_check_lua () {

    ensure_pkg luacheck
    run luacheck "$@" .

}
lint_check_bash () {

    ensure_pkg shellcheck

    local -a files=()
    local f=""

    if [[ $# -gt 0 ]]; then
        files=( "$@" )
    else
        while IFS= read -r f; do
            [[ -n "${f}" ]] && files+=( "${f}" )
        done < <(lint_git_files '*.sh' 2>/dev/null || true)

        [[ ${#files[@]} -gt 0 ]] || die "lint-check: bash requires file args"
    fi

    run shellcheck "${files[@]}"

}

lint_fix_c () {

    ensure_pkg clang-tidy

    [[ -f compile_commands.json ]] || die "lint-fix: c requires compile_commands.json"

    local -a files=()
    local f=""

    if [[ $# -gt 0 ]]; then
        files=( "$@" )
    else
        while IFS= read -r f; do
            [[ -n "${f}" ]] && files+=( "${f}" )
        done < <(lint_git_files '*.c' 2>/dev/null || true)

        [[ ${#files[@]} -gt 0 ]] || die "lint-fix: c requires file args"
    fi

    run clang-tidy -p . -fix --warnings-as-errors='*' "${files[@]}"

}
lint_fix_cpp () {

    ensure_pkg clang-tidy

    [[ -f compile_commands.json ]] || die "lint-fix: cpp requires compile_commands.json"

    local -a files=()
    local f=""

    if [[ $# -gt 0 ]]; then
        files=( "$@" )
    else
        while IFS= read -r f; do
            [[ -n "${f}" ]] && files+=( "${f}" )
        done < <(lint_git_files \
            '*.cpp' '*.cc' '*.cxx' '*.C' \
            '*.ixx' '*.cppm' '*.cxxm' \
        2>/dev/null || true)

        [[ ${#files[@]} -gt 0 ]] || die "lint-fix: cpp requires file args"
    fi

    run clang-tidy -p . -fix --warnings-as-errors='*' "${files[@]}"

}
lint_fix_rust () {

    ensure_pkg rustup
    run cargo +"${RUST_NIGHTLY:-nightly}" clippy --fix --allow-dirty --allow-staged --all-targets --all-features "$@" -- -D warnings

}
lint_fix_zig () {

    warn "no fixer for zig"

}
lint_fix_go () {

    ensure_pkg golangci-lint

    local -a cmd=()
    local config="$(config_file golangci yml)"
    [[ -f "${config}" ]] && cmd+=( --config "${config}" )

    run golangci-lint run --fix "${cmd[@]}" "$@"

}
lint_fix_python () {

    ensure_pkg ruff

    local -a cmd=()

    local config="$(config_file ruff-lint toml)"
    [[ -f "${config}" ]] || config="$(config_file ruff toml)"
    [[ -f "${config}" ]] && cmd+=( --config "${config}" )

    run ruff check --fix "${cmd[@]}" "$@" .

}
lint_fix_mojo () {

    warn "no fixer for mojo"

}
lint_fix_php () {

    warn "no fixer for phpstan"

}
lint_fix_node () {

    ensure_pkg npx

    local -a cmd=( npx -y @biomejs/biome check )
    [[ -x node_modules/.bin/biome ]] && cmd=( node_modules/.bin/biome check )

    local config="$(config_file biome-lint json)"
    [[ -f "${config}" ]] || config="$(config_file biome json)"
    [[ -f "${config}" ]] && cmd+=( --config-path "${config}" )

    run "${cmd[@]}" --write "$@" .

}
lint_fix_bun () {

    ensure_pkg bun

    local -a cmd=( bunx @biomejs/biome check )
    [[ -x node_modules/.bin/biome ]] && cmd=( node_modules/.bin/biome check )

    local config="$(config_file biome-lint json)"
    [[ -f "${config}" ]] || config="$(config_file biome json)"
    [[ -f "${config}" ]] && cmd+=( --config-path "${config}" )

    run "${cmd[@]}" --write "$@" .

}
lint_fix_csharp () {

    ensure_pkg dotnet
    run dotnet format "$@"

}
lint_fix_java () {

    warn "no fixer for java"

}
lint_fix_dart () {

    ensure_pkg dart
    run dart fix --apply "$@" .

}
lint_fix_lua () {

    warn "no fixer for lua"

}
lint_fix_bash () {

    warn "no fixer for bash"

}

cmd_lint_check () {

    case "$(which_lang)" in
        c)      lint_check_c      "$@" ;;
        cpp)    lint_check_cpp    "$@" ;;
        rust)   lint_check_rust   "$@" ;;
        zig)    lint_check_zig    "$@" ;;
        go)     lint_check_go     "$@" ;;
        python) lint_check_python "$@" ;;
        mojo)   lint_check_mojo   "$@" ;;
        php)    lint_check_php    "$@" ;;
        node)   lint_check_node   "$@" ;;
        bun)    lint_check_bun    "$@" ;;
        csharp) lint_check_csharp "$@" ;;
        java)   lint_check_java   "$@" ;;
        dart)   lint_check_dart   "$@" ;;
        lua)    lint_check_lua    "$@" ;;
        bash)   lint_check_bash   "$@" ;;
        *)      die "lint-check: unknown root manager" ;;
    esac

}
cmd_lint_fix () {

    case "$(which_lang)" in
        c)      lint_fix_c      "$@" ;;
        cpp)    lint_fix_cpp    "$@" ;;
        rust)   lint_fix_rust   "$@" ;;
        zig)    lint_fix_zig    "$@" ;;
        go)     lint_fix_go     "$@" ;;
        python) lint_fix_python "$@" ;;
        mojo)   lint_fix_mojo   "$@" ;;
        php)    lint_fix_php    "$@" ;;
        node)   lint_fix_node   "$@" ;;
        bun)    lint_fix_bun    "$@" ;;
        csharp) lint_fix_csharp "$@" ;;
        java)   lint_fix_java   "$@" ;;
        dart)   lint_fix_dart   "$@" ;;
        lua)    lint_fix_lua    "$@" ;;
        bash)   lint_fix_bash   "$@" ;;
        *)      die "lint-fix: unknown root manager" ;;
    esac

}
