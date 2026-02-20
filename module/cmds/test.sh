#!/usr/bin/env bash

test_rust () {

    ensure_pkg cargo
    source <(parse "$@" -- release:bool)

    if has cargo-nextest; then

        if (( release )); then
            if [[ -f Cargo.lock ]]; then run cargo nextest run --locked --release "${kwargs[@]}"
            else run cargo nextest run --release "${kwargs[@]}"
            fi
        else
            if [[ -f Cargo.lock ]]; then run cargo nextest run --locked "${kwargs[@]}"
            else run cargo nextest run "${kwargs[@]}"
            fi
        fi

        return 0

    fi

    if (( release )); then
        if [[ -f Cargo.lock ]]; then run cargo test --locked --release "${kwargs[@]}"
        else run cargo test --release "${kwargs[@]}"
        fi
    else
        if [[ -f Cargo.lock ]]; then run cargo test --locked "${kwargs[@]}"
        else run cargo test "${kwargs[@]}"
        fi
    fi

}
test_go () {

    ensure_pkg go
    source <(parse "$@" -- release:bool)

    run go test -count=1 -buildvcs=false "${kwargs[@]}" ./...

}
test_python () {

    source <(parse "$@" -- release:bool)

    if [[ -f pyproject.toml ]]; then
        ensure_pkg uv
        run uv run pytest -q "${kwargs[@]}"
        return 0
    fi

    ensure_pkg python3 pip

    run python3 -m pip install -q --upgrade pytest
    run python3 -m pytest -q "${kwargs[@]}"

}
test_node () {

    ensure_pkg pnpm
    source <(parse "$@" -- release:bool)

    [[ -f package.json ]] || die "test: node needs package.json"

    if [[ -f pnpm-lock.yaml ]]; then run pnpm install --frozen-lockfile
    else run pnpm install
    fi

    run pnpm run test "${kwargs[@]}"

}
test_bun () {

    ensure_pkg bun
    source <(parse "$@" -- release:bool)

    [[ -f package.json ]] || die "test: bun needs package.json"

    if [[ -f bun.lockb || -f bun.lock ]]; then run bun install --frozen-lockfile
    else run bun install
    fi

    run bun test "${kwargs[@]}"

}
test_php () {

    ensure_pkg php composer
    source <(parse "$@" -- release:bool)

    [[ -f composer.json ]] || die "test: php needs composer.json"
    run composer install --no-interaction --no-progress --prefer-dist

    if [[ -x vendor/bin/pest ]]; then run vendor/bin/pest "${kwargs[@]}"; return 0; fi
    if [[ -x vendor/bin/phpunit ]]; then run vendor/bin/phpunit "${kwargs[@]}"; return 0; fi

    run composer run test -- "${kwargs[@]}"

}
test_csharp () {

    ensure_pkg dotnet
    source <(parse "$@" -- release:bool)

    if (( release )); then run dotnet test -c Release --nologo "${kwargs[@]}"
    else run dotnet test -c Debug --nologo "${kwargs[@]}"
    fi

}
test_cpp () {

    source <(parse "$@" -- release:bool)

    local mode="debug" bt="Debug" out="build/debug"
    (( release )) && { mode="release"; bt="Release"; out="build/release"; }

    if [[ -f xmake.lua ]]; then

        ensure_pkg xmake

        run xmake f -m "${mode}" "${kwargs[@]}"
        run xmake
        run xmake test "${kwargs[@]}"

        return 0

    fi
    if [[ -f conanfile.py || -f conanfile.txt ]]; then

        ensure_pkg conan cmake ninja
        mkdir -p "${out}"

        run conan profile detect --force >/dev/null 2>&1 || true
        run conan install . --output-folder "${out}" -s "build_type=${bt}" -b missing "${kwargs[@]}"

        if [[ -f conanfile.txt ]]; then
            [[ -f "${out}/conan_toolchain.cmake" ]] || die "test: conan missing conan_toolchain.cmake"

            run cmake -S . -B "${out}" -G Ninja -DCMAKE_TOOLCHAIN_FILE="${out}/conan_toolchain.cmake" -DCMAKE_BUILD_TYPE="${bt}"
            run cmake --build "${out}"
        else
            run conan build . --output-folder "${out}" "${kwargs[@]}"
        fi

        [[ -f "${out}/CTestTestfile.cmake" ]] || return 0
        run ctest --test-dir "${out}" --output-on-failure "${kwargs[@]}"
        return 0

    fi

    die "test: cpp needs xmake.lua or conanfile.py or conanfile.txt"

}
cmd_test () {

    case "$(which_lang)" in
        rust)   test_rust   "$@" ;;
        go)     test_go     "$@" ;;
        python) test_python "$@" ;;
        node)   test_node   "$@" ;;
        bun)    test_bun    "$@" ;;
        php)    test_php    "$@" ;;
        csharp) test_csharp "$@" ;;
        cpp)    test_cpp    "$@" ;;
        *)      die "test: unknown root manager" ;;
    esac

}
