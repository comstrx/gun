#!/usr/bin/env bash

clean_rust () {

    ensure_pkg cargo
    run cargo clean "$@"

}
clean_go () {

    ensure_pkg go
    run go clean -cache -testcache "$@"
    run rm -rf build bin dist

}
clean_python () {

    ensure_pkg python3

    [[ -f pyproject.toml ]] || die "clean: python needs pyproject.toml"
    run rm -rf build dist .pytest_cache .mypy_cache .ruff_cache .coverage htmlcov .tox .nox .hypothesis

    find . -type d -name "__pycache__" -prune -exec rm -rf {} + 2>/dev/null || true
    find . -maxdepth 4 -type d -name "*.egg-info" -prune -exec rm -rf {} + 2>/dev/null || true

}
clean_node () {

    ensure_pkg pnpm

    [[ -f package.json ]] || die "clean: node needs package.json"

    local script="$(node -p 'const p=require("./package.json"); const s=(p.scripts||{}); (s.clean ? "clean" : "")' 2>/dev/null || true)"
    run pnpm run "${script}" "$@" || true

    run rm -rf dist build out coverage .nyc_output .next .turbo .vite .parcel-cache .cache node_modules/.cache

}
clean_bun () {

    ensure_pkg bun

    [[ -f package.json ]] || die "clean: bun needs package.json"

    local script="$(bun -e 'const p=require("./package.json"); const s=(p.scripts||{}); if(s.clean) process.stdout.write("clean");' 2>/dev/null || true)"
    [[ -n "${script}" ]] && run bun run "${script}" "$@" || true

    run rm -rf dist build out coverage .nyc_output .next .turbo .vite .parcel-cache .cache node_modules/.cache

}
clean_php () {

    ensure_pkg php composer

    [[ -f composer.json ]] || die "clean: php needs composer.json"

    local script="$(php -r '$j=json_decode(file_get_contents("composer.json"),true); $s=$j["scripts"]??[]; echo isset($s["clean"]) ? "clean" : "";' 2>/dev/null || true)"
    [[ -n "${script}" ]] && run composer run "${script}" -- "$@" || true

    run rm -rf build dist coverage .phpunit.result.cache .phpunit.cache .pest-cache

}
clean_csharp () {

    ensure_pkg dotnet

    run dotnet clean --nologo "$@"
    find . -type d \( -name bin -o -name obj -o -name .vs \) -prune -exec rm -rf {} + 2>/dev/null || true

}
clean_cpp () {

    if [[ -f xmake.lua ]]; then
        ensure_pkg xmake
        run xmake clean -a "$@"
    fi
    if [[ -f conanfile.py || -f conanfile.txt ]]; then
        ensure_pkg conan
    fi

    run rm -rf build .xmake CMakeFiles CMakeCache.txt cmake_install.cmake compile_commands.json

}

cmd_clean () {

    case "$(which_lang)" in
        rust)   clean_rust   "$@" ;;
        go)     clean_go     "$@" ;;
        python) clean_python "$@" ;;
        node)   clean_node   "$@" ;;
        bun)    clean_bun    "$@" ;;
        php)    clean_php    "$@" ;;
        csharp) clean_csharp "$@" ;;
        cpp)    clean_cpp    "$@" ;;
        *)      die "clean: unknown root manager" ;;
    esac

}
