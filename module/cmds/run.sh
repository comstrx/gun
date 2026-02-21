#!/usr/bin/env bash

run_rust () {

    ensure_pkg cargo
    source <(parse "$@" -- release:bool)

    local args=()
    (( release )) && args+=( --release )
    [[ -f Cargo.lock ]] && args+=( --locked )

    run cargo run "${args[@]}" "${kwargs[@]}"

}
run_go () {

    ensure_pkg go
    source <(parse "$@" -- release:bool)

    run go run -buildvcs=false . "${kwargs[@]}"

}
run_python () {

    source <(parse "$@" -- release:bool entry)

    if [[ -z "${entry}" ]]; then
        if [[ -f src/main.py ]]; then entry="src/main.py"
        elif [[ -f main.py ]]; then entry="main.py"
        elif [[ -f src/app.py ]]; then entry="src/app.py"
        elif [[ -f app.py ]]; then entry="app.py"
        else die "run: python needs src/main.py or main.py"
        fi
    fi
    if [[ -f pyproject.toml ]]; then
        ensure_pkg uv
        run uv run python "${entry}" "${kwargs[@]}"
        return 0
    fi

    ensure_pkg python3
    run python3 "${entry}" "${kwargs[@]}"

}
run_node () {

    ensure_pkg pnpm
    source <(parse "$@" -- release:bool)

    [[ -f package.json ]] || die "run: node needs package.json"

    if [[ -f pnpm-lock.yaml ]]; then run pnpm install --frozen-lockfile
    else run pnpm install
    fi
    if (( release )); then run pnpm start "${kwargs[@]}"
    else run pnpm dev "${kwargs[@]}"
    fi

}
run_bun () {

    ensure_pkg bun
    source <(parse "$@" -- release:bool)

    [[ -f package.json ]] || die "run: bun needs package.json"

    if [[ -f bun.lockb || -f bun.lock ]]; then run bun install --frozen-lockfile
    else run bun install
    fi
    if (( release )); then run bun run start "${kwargs[@]}"
    else run bun run dev "${kwargs[@]}"
    fi

}
run_php () {

    ensure_pkg php composer
    source <(parse "$@" -- release:bool)

    [[ -f composer.json ]] || die "run: php needs composer.json"

    if (( release )); then run composer install --no-interaction --no-progress --prefer-dist --no-dev --optimize-autoloader
    else run composer install --no-interaction --no-progress --prefer-dist
    fi

    run composer run start "${kwargs[@]}"

}
run_csharp () {

    ensure_pkg dotnet
    source <(parse "$@" -- release:bool)

    if (( release )); then run dotnet run -c Release --nologo "${kwargs[@]}"
    else run dotnet run -c Debug --nologo "${kwargs[@]}"
    fi

}
run_cpp () {

    source <(parse "$@" -- release:bool)

    local mode="debug" bt="Debug" out="build/debug"
    (( release )) && { mode="release"; bt="Release"; out="build/release"; }

    if [[ -f xmake.lua ]]; then

        ensure_pkg xmake
        run xmake f -m "${mode}"
        run xmake
        run xmake run "${kwargs[@]}"
        return 0

    fi
    if [[ -f conanfile.py || -f conanfile.txt ]]; then

        ensure_pkg conan cmake ninja

        run mkdir -p "${out}"
        run conan profile detect --force >/dev/null 2>&1 || true
        run conan install . --output-folder "${out}" -s "build_type=${bt}" -b missing

        if [[ -f conanfile.txt ]]; then
            [[ -f "${out}/conan_toolchain.cmake" ]] || die "run: cpp conan missing conan_toolchain.cmake"
            run cmake -S . -B "${out}" -G Ninja -DCMAKE_TOOLCHAIN_FILE="${out}/conan_toolchain.cmake" -DCMAKE_BUILD_TYPE="${bt}"
            run cmake --build "${out}" --parallel
        else
            run conan build . --output-folder "${out}"
        fi

        local exe="$(find "${out}" -maxdepth 3 -type f -perm -111 ! -name '*.so' ! -name '*.dylib' ! -name '*.dll' -print -quit 2>/dev/null || true)"
        [[ -n "${exe}" ]] || die "run: cpp no executable found"
        run "${exe}" "${kwargs[@]}"
        return 0

    fi

    die "run: cpp needs xmake.lua or conanfile"

}
run_bash () {

    source <(parse "$@" -- release:bool)
    warn "bash: no run step required (use gun run bash main.sh)"

}
run_lua () {

    source <(parse "$@" -- release:bool)
    warn "lua: no run step required"

}
cmd_run () {

    case "$(which_lang)" in
        rust)    run_rust   "$@" ;;
        go)      run_go     "$@" ;;
        python)  run_python "$@" ;;
        node)    run_node   "$@" ;;
        bun)     run_bun    "$@" ;;
        php)     run_php    "$@" ;;
        csharp)  run_csharp "$@" ;;
        cpp)     run_cpp    "$@" ;;
        bash)    run_bash   "$@" ;;
        lua)     run_lua    "$@" ;;
        *)       die "run: unsupported language" ;;
    esac

}
