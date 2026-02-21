#!/usr/bin/env bash

clean_rust () {

    ensure_pkg cargo
    run cargo clean "$@"

}
clean_go () {

    ensure_pkg go

    run go clean -cache -testcache -fuzzcache "$@"
    run rm -rf build bin dist

}
clean_python () {

    if [[ -f pyproject.toml ]]; then
        ensure_pkg uv
        run uv cache clean "$@"
    fi

    run rm -rf build dist .pytest_cache .mypy_cache .ruff_cache .coverage htmlcov .tox .nox .hypothesis
    find . -type d \( -name "__pycache__" -o -name "*.egg-info" \) -prune -exec rm -rf {} + 2>/dev/null || true

}
clean_node () {

    ensure_pkg pnpm
    [[ -f package.json ]] || die "clean: node needs package.json"

    run pnpm run clean "$@" 2>/dev/null || true
    run rm -rf dist build out coverage .nyc_output .next .nuxt .output .vite .parcel-cache .cache node_modules/.cache

}
clean_bun () {

    ensure_pkg bun
    [[ -f package.json ]] || die "clean: bun needs package.json"

    run bun run clean "$@" 2>/dev/null || true
    run rm -rf dist build out coverage .nyc_output .next .nuxt .output .vite .parcel-cache .cache node_modules/.cache

}
clean_php () {

    ensure_pkg php composer
    [[ -f composer.json ]] || die "clean: php needs composer.json"

    run composer run clean "$@" 2>/dev/null || true
    run rm -rf build dist coverage .phpunit.result.cache .phpunit.cache .pest-cache

}
clean_csharp () {

    ensure_pkg dotnet

    run dotnet clean --nologo "$@"
    find . -type d \( -name bin -o -name obj -o -name .vs -o -name TestResults -o -name artifacts \) -prune -exec rm -rf {} + 2>/dev/null || true

}
clean_cpp () {

    if [[ -f xmake.lua ]]; then
        ensure_pkg xmake
        run xmake clean -a
    fi

    run rm -rf build .xmake CMakeFiles CMakeCache.txt cmake_install.cmake compile_commands.json

}
clean_bash () {

    warn "bash: no clean step required"

}
clean_lua () {

    warn "lua: no clean step required"

}
cmd_clean () {

    case "$(which_lang)" in
        rust)    clean_rust   "$@" ;;
        go)      clean_go     "$@" ;;
        py|python) clean_python "$@" ;;
        node)    clean_node   "$@" ;;
        bun)     clean_bun    "$@" ;;
        php)     clean_php    "$@" ;;
        csharp)  clean_csharp "$@" ;;
        cpp)     clean_cpp    "$@" ;;
        bash)    clean_bash   "$@" ;;
        lua)     clean_lua    "$@" ;;
        *)       die "clean: unsupported language" ;;
    esac

}
