#!/usr/bin/env bash

lint_check_rust () {

    ensure_pkg rustup clippy
    run cargo clippy --all-targets --all-features "$@"

}
lint_fix_rust () {

    ensure_pkg rustup clippy
    run cargo clippy --fix --allow-dirty --allow-staged --all-targets --all-features "$@"

}

lint_check_go () {

    ensure_pkg golangci-lint

    local -a cmd=()

    local config="$(config_file golangci yml)"
    [[ -f "${config}" ]] && cmd+=( --config "${config}" )

    run golangci-lint run "${cmd[@]}" "$@"

}
lint_fix_go () {

    ensure_pkg golangci-lint

    local -a cmd=()

    local config="$(config_file golangci yml)"
    [[ -f "${config}" ]] && cmd+=( --config "${config}" )

    run golangci-lint run --fix "${cmd[@]}" "$@"

}

lint_check_py () {

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
lint_fix_py () {

    ensure_pkg ruff

    local -a cmd=()

    local config="$(config_file ruff-lint toml)"
    [[ -f "${config}" ]] || config="$(config_file ruff toml)"
    [[ -f "${config}" ]] && cmd+=( --config "${config}" )

    run ruff check --fix "${cmd[@]}" "$@" .

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
lint_fix_node () {

    ensure_pkg npx

    local -a cmd=( npx -y @biomejs/biome check )
    [[ -x node_modules/.bin/biome ]] && cmd=( node_modules/.bin/biome check )

    local config="$(config_file biome-lint json)"
    [[ -f "${config}" ]] || config="$(config_file biome json)"
    [[ -f "${config}" ]] && cmd+=( --config-path "${config}" )

    run "${cmd[@]}" --write "$@" .

}

lint_check_php () {

    ensure_pkg php

    local -a cmd=( phpstan analyse )
    [[ -x vendor/bin/phpstan ]] && cmd=( vendor/bin/phpstan analyse )

    local config="$(config_file phpstan neon)"
    [[ -f "${config}" ]] && cmd+=( -c "${config}" )

    run "${cmd[@]}" "$@" .

}
lint_fix_php () {

    warn "no fixer for phpstan"

}

cmd_lint_check () {

    case "$(which_lang)" in
        rust) lint_check_rust "$@" ;;
        go)   lint_check_go   "$@" ;;
        py)   lint_check_py   "$@" ;;
        node) lint_check_node "$@" ;;
        php)  lint_check_php  "$@" ;;
        *)    die "lint-check: unknown root manager" ;;
    esac

}
cmd_lint_fix () {

    case "$(which_lang)" in
        rust) lint_fix_rust "$@" ;;
        go)   lint_fix_go   "$@" ;;
        py)   lint_fix_py   "$@" ;;
        node) lint_fix_node "$@" ;;
        php)  lint_fix_php  "$@" ;;
        *)    die "lint-fix: unknown root manager" ;;
    esac

}
