#!/usr/bin/env bash

update_rust () {

    ensure_pkg cargo
    run cargo update "${kwargs[@]}"

}
update_go () {

    ensure_pkg go

    if [[ -f go.work && ! -f go.mod ]]; then
        run go work sync
        return 0
    fi

    [[ -f go.mod ]] || die "update: go needs go.mod or go.work"
    [[ -f go.work ]] && run go work sync

    run go get -u "${kwargs[@]}" ./...
    run go mod tidy

}
update_python () {

    if [[ -f pyproject.toml ]]; then
        ensure_pkg uv
        run uv sync --upgrade "${kwargs[@]}"
        return 0
    fi

    [[ -f requirements.txt ]] || die "update: python needs pyproject.toml or requirements.txt"

    ensure_pkg python3 pip
    run python3 -m pip install -q --upgrade pip
    run python3 -m pip install -U -r requirements.txt "${kwargs[@]}"

}
update_node () {

    ensure_pkg pnpm

    [[ -f package.json ]] || die "update: node needs package.json"
    run pnpm up "${kwargs[@]}"

}
update_bun () {

    ensure_pkg bun

    [[ -f package.json ]] || die "update: bun needs package.json"
    run bun update "${kwargs[@]}"

}
update_php () {

    ensure_pkg php composer
    [[ -f composer.json ]] || die "update: php needs composer.json"

    if (( release )); then
        run composer update --no-interaction --no-progress --prefer-dist --no-dev --optimize-autoloader --classmap-authoritative "${kwargs[@]}"
    else
        run composer update --no-interaction --no-progress --prefer-dist "${kwargs[@]}"
    fi

}
update_csharp () {

    ensure_pkg dotnet
    run dotnet package update "${kwargs[@]}" || run dotnet restore --nologo "${kwargs[@]}"

}
update_cpp () {

    local mode="debug" bt="Debug" out="build/debug"
    (( release )) && { mode="release"; bt="Release"; out="build/release"; }

    if [[ -f xmake.lua ]]; then

        ensure_pkg xmake
        run xmake f -m "${mode}" "${kwargs[@]}"
        run xmake require --upgrade "${kwargs[@]}" || true
        return 0

    fi
    if [[ -f conanfile.py || -f conanfile.txt ]]; then

        ensure_pkg conan cmake ninja
        mkdir -p "${out}"

        run conan profile detect --force >/dev/null 2>&1 || true
        run conan install . --output-folder "${out}" -s "build_type=${bt}" -b missing --update "${kwargs[@]}"

        [[ -f conanfile.txt && ! -f "${out}/conan_toolchain.cmake" ]] && die "update: cpp conan missing conan_toolchain.cmake"
        return 0

    fi

    die "update: cpp needs xmake.lua or conanfile.py or conanfile.txt"

}
cmd_update () {

    source <(parse "$@" -- release:bool)

    case "$(which_lang)" in
        rust)   update_rust   ;;
        go)     update_go     ;;
        python) update_python ;;
        node)   update_node   ;;
        bun)    update_bun    ;;
        php)    update_php    ;;
        csharp) update_csharp ;;
        cpp)    update_cpp    ;;
        *)      die "update: unknown root manager" ;;
    esac

}
