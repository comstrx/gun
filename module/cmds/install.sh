#!/usr/bin/env bash

install_rust () {

    ensure_pkg cargo

    if [[ -f Cargo.lock ]]; then run cargo fetch --locked "$@"
    else run cargo fetch "$@"
    fi

}
install_go () {

    ensure_pkg go

    if [[ -f go.work ]]; then
        run go work sync "$@"
        return 0
    fi

    [[ -f go.mod ]] || die "install: go needs go.mod or go.work"
    run go mod download "$@"

}
install_python () {

    if [[ -f pyproject.toml ]]; then
        ensure_pkg uv
        run uv sync "$@"
        return 0
    fi

    [[ -f requirements.txt ]] || die "install: python needs pyproject.toml or requirements.txt"

    ensure_pkg python3 pip
    run python3 -m pip install -r requirements.txt "$@"

}
install_node () {

    ensure_pkg pnpm node

    [[ -f package.json ]] || die "install: node needs package.json"

    if [[ -f pnpm-lock.yaml ]]; then run pnpm install --frozen-lockfile "$@"
    else run pnpm install "$@"
    fi

}
install_bun () {

    ensure_pkg bun

    [[ -f package.json ]] || die "install: bun needs package.json"

    if [[ -f bun.lockb || -f bun.lock ]]; then run bun install --frozen-lockfile "$@"
    else run bun install "$@"
    fi

}
install_php () {

    ensure_pkg php composer

    [[ -f composer.json ]] || die "install: php needs composer.json"

    if (( release )); then
        run composer install --no-interaction --no-progress --prefer-dist --no-dev --optimize-autoloader --classmap-authoritative "$@"
    else
        run composer install --no-interaction --no-progress --prefer-dist "$@"
    fi

}
install_csharp () {

    ensure_pkg dotnet
    run dotnet restore --nologo "$@"

}
install_cpp () {

    local mode="debug" bt="Debug" out="build/debug"
    (( release )) && { mode="release"; bt="Release"; out="build/release"; }

    if [[ -f xmake.lua ]]; then

        ensure_pkg xmake
        run xmake f -m "${mode}" "$@"
        return 0

    fi
    if [[ -f conanfile.py || -f conanfile.txt ]]; then

        ensure_pkg conan cmake ninja
        mkdir -p "${out}"

        run conan profile detect --force >/dev/null 2>&1 || true
        run conan install . --output-folder "${out}" -s "build_type=${bt}" -b missing "$@"

        [[ -f conanfile.txt && ! -f "${out}/conan_toolchain.cmake" ]] && die "install: cpp conan missing conan_toolchain.cmake"
        return 0

    fi

    die "install: cpp needs xmake.lua or conanfile.py or conanfile.txt"

}
cmd_install () {

    source <(parse "$@" -- release:bool)

    case "$(which_lang)" in
        rust)   install_rust   "${kwargs[@]}" ;;
        go)     install_go     "${kwargs[@]}" ;;
        python) install_python "${kwargs[@]}" ;;
        node)   install_node   "${kwargs[@]}" ;;
        bun)    install_bun    "${kwargs[@]}" ;;
        php)    install_php    "${kwargs[@]}" ;;
        csharp) install_csharp "${kwargs[@]}" ;;
        cpp)    install_cpp    "${kwargs[@]}" ;;
        *)      die "install: unknown root manager" ;;
    esac

}
