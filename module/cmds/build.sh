#!/usr/bin/env bash

build_rust () {

    ensure_pkg cargo
    source <(parse "$@" -- release:bool)

    if (( release )); then
        if [[ -f Cargo.lock ]]; then run cargo build --locked --release "${kwargs[@]}"
        else run cargo build --release "${kwargs[@]}"
        fi
    else
        if [[ -f Cargo.lock ]]; then run cargo build --locked "${kwargs[@]}"
        else run cargo build "${kwargs[@]}"
        fi
    fi

}
build_go () {

    ensure_pkg go
    source <(parse "$@" -- release:bool)

    if (( release )); then run go build -buildvcs=false -trimpath -ldflags="-s -w" "${kwargs[@]}" ./...
    else run go build -buildvcs=false "${kwargs[@]}" ./...
    fi

}
build_python () {

    source <(parse "$@" -- release:bool)

    if [[ -f pyproject.toml ]]; then
        ensure_pkg uv
        run uv build "${kwargs[@]}"
        return 0
    fi

    ensure_pkg python3 pip
    run python3 -m pip install -q --upgrade build
    run python3 -m build "${kwargs[@]}"

}
build_node () {

    ensure_pkg pnpm
    source <(parse "$@" -- release:bool)

    [[ -f package.json ]] || die "build: node needs package.json"

    if [[ -f pnpm-lock.yaml ]]; then run pnpm install --frozen-lockfile
    else run pnpm install
    fi

    run pnpm run build "${kwargs[@]}"

}
build_bun () {

    ensure_pkg bun
    source <(parse "$@" -- release:bool)

    [[ -f package.json ]] || die "build: bun needs package.json"

    if [[ -f bun.lockb || -f bun.lock ]]; then run bun install --frozen-lockfile
    else run bun install
    fi

    run bun run build "${kwargs[@]}"

}
build_php () {

    ensure_pkg php composer
    source <(parse "$@" -- release:bool)

    [[ -f composer.json ]] || die "build: php needs composer.json"

    if (( release )); then
        run composer install --no-interaction --no-progress --prefer-dist --no-dev --optimize-autoloader --classmap-authoritative "${kwargs[@]}"
    else
        run composer install --no-interaction --no-progress --prefer-dist "${kwargs[@]}"
    fi

}
build_csharp () {

    ensure_pkg dotnet
    source <(parse "$@" -- release:bool)

    if (( release )); then run dotnet build -c Release --nologo "${kwargs[@]}"
    else run dotnet build -c Debug --nologo "${kwargs[@]}"
    fi

}
build_cpp () {

    source <(parse "$@" -- release:bool)

    local mode="debug" bt="Debug" out="build/debug"
    (( release )) && { mode="release"; bt="Release"; out="build/release"; }

    if [[ -f xmake.lua ]]; then

        ensure_pkg xmake

        run xmake f -m "${mode}" "${kwargs[@]}"
        run xmake

        return 0

    fi
    if [[ -f conanfile.py ]]; then

        ensure_pkg conan cmake ninja
        mkdir -p "${out}"

        run conan profile detect --force >/dev/null 2>&1 || true

        run conan install . --output-folder "${out}" -s "build_type=${bt}" -b missing "${kwargs[@]}"
        run conan build . --output-folder "${out}" "${kwargs[@]}"

        return 0

    fi
    if [[ -f conanfile.txt ]]; then

        ensure_pkg conan cmake ninja
        mkdir -p "${out}"

        run conan profile detect --force >/dev/null 2>&1 || true
        run conan install . --output-folder "${out}" -s "build_type=${bt}" -b missing "${kwargs[@]}"
        [[ -f "${out}/conan_toolchain.cmake" ]] || die "build: cpp conan missing conan_toolchain.cmake"

        run cmake -S . -B "${out}" -G Ninja -DCMAKE_TOOLCHAIN_FILE="${out}/conan_toolchain.cmake" -DCMAKE_BUILD_TYPE="${bt}"
        run cmake --build "${out}"

        return 0

    fi

    die "build: cpp needs xmake.lua or conanfile.py or conanfile.txt"

}
cmd_build () {

    case "$(which_lang)" in
        rust)   build_rust   "$@" ;;
        go)     build_go     "$@" ;;
        python) build_python "$@" ;;
        node)   build_node   "$@" ;;
        bun)    build_bun    "$@" ;;
        php)    build_php    "$@" ;;
        csharp) build_csharp "$@" ;;
        cpp)    build_cpp    "$@" ;;
        *)      die "build: unknown root manager" ;;
    esac

}
