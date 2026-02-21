#!/usr/bin/env bash

install_rust () {

    ensure_pkg cargo
    source <(parse "$@" -- release:bool)

    if [[ -f Cargo.lock ]]; then run cargo fetch --locked "${kwargs[@]}"
    else run cargo fetch "${kwargs[@]}"
    fi

}
install_go () {

    ensure_pkg go
    source <(parse "$@" -- release:bool)

    if [[ -f go.work ]]; then run go work sync "${kwargs[@]}"
    else run go mod download "${kwargs[@]}"
    fi

}
install_python () {

    source <(parse "$@" -- release:bool)

    if [[ -f pyproject.toml ]]; then

        ensure_pkg uv

        local -a args=()
        (( release )) && args+=( --no-dev --no-editable )
        [[ -f uv.lock ]] && (( release )) && args+=( --locked )

        run uv sync "${args[@]}" "${kwargs[@]}"
        return 0

    fi
    if [[ -f requirements.txt ]]; then

        ensure_pkg python3 pip
        run python3 -m pip install --no-input -r requirements.txt "${kwargs[@]}"
        return 0

    fi

    die "install: python needs pyproject.toml or requirements.txt"

}
install_node () {

    ensure_pkg pnpm
    source <(parse "$@" -- release:bool)

    [[ -f package.json ]] || die "install: node needs package.json"

    if [[ -f pnpm-lock.yaml ]]; then
        if (( release )); then run pnpm install --frozen-lockfile --prod "${kwargs[@]}"
        else run pnpm install --frozen-lockfile "${kwargs[@]}"
        fi
    else
        if (( release )); then run pnpm install --prod "${kwargs[@]}"
        else run pnpm install "${kwargs[@]}"
        fi
    fi

}
install_bun () {

    ensure_pkg bun
    source <(parse "$@" -- release:bool)

    [[ -f package.json ]] || die "install: bun needs package.json"

    if [[ -f bun.lockb || -f bun.lock ]]; then
        if (( release )); then run bun install --frozen-lockfile --production "${kwargs[@]}"
        else run bun install --frozen-lockfile "${kwargs[@]}"
        fi
    else
        if (( release )); then run bun install --production "${kwargs[@]}"
        else run bun install "${kwargs[@]}"
        fi
    fi

}
install_php () {

    ensure_pkg php composer
    source <(parse "$@" -- release:bool)

    [[ -f composer.json ]] || die "install: php needs composer.json"

    if (( release )); then run composer install --no-interaction --no-progress --prefer-dist --no-dev --optimize-autoloader "${kwargs[@]}"
    else run composer install --no-interaction --no-progress --prefer-dist "${kwargs[@]}"
    fi

}
install_csharp () {

    ensure_pkg dotnet
    source <(parse "$@" -- release:bool)

    local -a args=( --nologo )
    [[ -f packages.lock.json ]] && args+=( --locked-mode )

    run dotnet restore "${args[@]}" "${kwargs[@]}"

}
install_cpp () {

    source <(parse "$@" -- release:bool)

    local mode="debug" bt="Debug" out="build/debug"
    (( release )) && { mode="release"; bt="Release"; out="build/release"; }

    if [[ -f xmake.lua ]]; then

        ensure_pkg xmake

        run xmake f -m "${mode}"
        run xmake "${kwargs[@]}"

        return 0

    fi
    if [[ -f conanfile.py || -f conanfile.txt ]]; then

        ensure_pkg conan cmake ninja

        run mkdir -p "${out}"
        run conan profile detect --force >/dev/null 2>&1 || true
        run conan install . --output-folder "${out}" -s "build_type=${bt}" --build=missing "${kwargs[@]}"

        if [[ -f conanfile.txt ]]; then

            [[ -f "${out}/conan_toolchain.cmake" ]] || die "install: cpp conan missing conan_toolchain.cmake"
            run cmake -S . -B "${out}" -G Ninja -DCMAKE_TOOLCHAIN_FILE="${out}/conan_toolchain.cmake" -DCMAKE_BUILD_TYPE="${bt}"

        fi

        return 0

    fi

    die "install: cpp needs xmake.lua or conanfile"

}
install_bash () {

    warn "bash: no install step required"

}
install_lua () {

    warn "lua: no install step required"

}
cmd_install () {

    case "$(which_lang)" in
        rust)    install_rust   "$@" ;;
        go)      install_go     "$@" ;;
        python)  install_python "$@" ;;
        node)    install_node   "$@" ;;
        bun)     install_bun    "$@" ;;
        php)     install_php    "$@" ;;
        csharp)  install_csharp "$@" ;;
        cpp)     install_cpp    "$@" ;;
        bash)    install_bash   "$@" ;;
        lua)     install_lua    "$@" ;;
        *)       die "install: unsupported language" ;;
    esac

}
