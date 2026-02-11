#!/usr/bin/env bash

fmt_check_rust () {

    ensure_pkg rustup rustfmt
    run cargo +"${RUST_NIGHTLY:-nightly}" fmt --all --check "$@"

}
fmt_fix_rust () {

    ensure_pkg rustup rustfmt
    run cargo +"${RUST_NIGHTLY:-nightly}" fmt --all "$@"

}

fmt_check_go () {

    ensure_pkg goimports

    local out="$(goimports -l "$@" . 2>&1)" || { printf '%s\n' "${out}"; return 1; }
    [[ -n "${out}" ]] && { printf '%s\n' "${out}"; return 1; }

    return 0

}
fmt_fix_go () {

    ensure_pkg goimports
    run goimports -w "$@" .

}

fmt_check_py () {

    ensure_pkg ruff

    local -a cmd=()

    local config="$(config_file ruff-fmt toml)"
    [[ -f "${config}" ]] || config="$(config_file ruff toml)"
    [[ -f "${config}" ]] && cmd+=( --config "${config}" )

    run ruff format --check "${cmd[@]}" "$@" .

}
fmt_fix_py () {

    ensure_pkg ruff

    local -a cmd=()

    local config="$(config_file ruff-fmt toml)"
    [[ -f "${config}" ]] || config="$(config_file ruff toml)"
    [[ -f "${config}" ]] && cmd+=( --config "${config}" )

    run ruff format "${cmd[@]}" "$@" .

}

fmt_check_node () {

    ensure_pkg npx

    local -a cmd=( npx -y @biomejs/biome format )
    [[ -x node_modules/.bin/biome ]] && cmd=( node_modules/.bin/biome format )

    local config="$(config_file biome-fmt json)"
    [[ -f "${config}" ]] || config="$(config_file biome json)"
    [[ -f "${config}" ]] && cmd+=( --config-path "${config}" )

    run "${cmd[@]}" "$@" .

}
fmt_fix_node () {

    ensure_pkg npx

    local -a cmd=( npx -y @biomejs/biome format )
    [[ -x node_modules/.bin/biome ]] && cmd=( node_modules/.bin/biome format )

    local config="$(config_file biome-fmt json)"
    [[ -f "${config}" ]] || config="$(config_file biome json)"
    [[ -f "${config}" ]] && cmd+=( --config-path "${config}" )

    run "${cmd[@]}" --write "$@" .

}

fmt_check_php () {

    ensure_pkg php

    local -a cmd=( pint )
    [[ -x vendor/bin/pint ]] && cmd=( vendor/bin/pint )

    local config="$(config_file pint json)"
    [[ -f "${config}" ]] && cmd+=( --config "${config}" )

    run "${cmd[@]}" --test "$@" .

}
fmt_fix_php () {

    ensure_pkg php

    local -a cmd=( pint )
    [[ -x vendor/bin/pint ]] && cmd=( vendor/bin/pint )

    local config="$(config_file pint json)"
    [[ -f "${config}" ]] && cmd+=( --config "${config}" )

    run "${cmd[@]}" "$@" .

}

cmd_fmt_check () {

    case "$(which_lang)" in
        rust) fmt_check_rust "$@" ;;
        go)   fmt_check_go   "$@" ;;
        py)   fmt_check_py   "$@" ;;
        node) fmt_check_node "$@" ;;
        php)  fmt_check_php  "$@" ;;
        *)    die "fmt-check: unknown root manager" ;;
    esac

}
cmd_fmt_fix () {

    case "$(which_lang)" in
        rust) fmt_fix_rust "$@" ;;
        go)   fmt_fix_go   "$@" ;;
        py)   fmt_fix_py   "$@" ;;
        node) fmt_fix_node "$@" ;;
        php)  fmt_fix_php  "$@" ;;
        *)    die "fmt-fix: unknown root manager" ;;
    esac

}
