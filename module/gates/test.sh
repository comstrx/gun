#!/usr/bin/env bash

test_rust () {

    ensure_pkg cargo

    if has cargo-nextest; then
   
        if [[ -f Cargo.lock ]]; then run cargo nextest run --locked "$@"
        else run cargo nextest run "$@"
        fi

        return 0

    fi

    if [[ -f Cargo.lock ]]; then run cargo test --locked "$@"
    else run cargo test "$@"
    fi

}
test_go () {

    ensure_pkg go
    run go test -count=1 "$@" ./...

}
test_python () {

    [[ -f pyproject.toml ]] || die "test: python needs pyproject.toml"

    if has uv; then
        run uv run pytest -q "$@"
        return 0
    fi

    ensure_pkg python3 pip

    run python3 -m pip install -q --upgrade pytest
    run python3 -m pytest -q "$@"

}
test_node () {

    ensure_pkg pnpm

    [[ -f package.json ]] || die "test: node needs package.json"

    if [[ -f pnpm-lock.yaml ]]; then run pnpm install --frozen-lockfile
    else run pnpm install
    fi

    run pnpm test "$@"

}
test_bun () {

    ensure_pkg bun

    [[ -f package.json ]] || die "test: bun needs package.json"

    if [[ -f bun.lockb || -f bun.lock ]]; then run bun install --frozen-lockfile
    else run bun install
    fi

    run bun test "$@"

}
test_php () {

    ensure_pkg php composer

    [[ -f composer.json ]] || die "test: php needs composer.json"
    run composer install --no-interaction --no-progress --prefer-dist

    if [[ -x vendor/bin/pest ]]; then
        run vendor/bin/pest "$@"
        return 0
    fi
    if [[ -x vendor/bin/phpunit ]]; then
        run vendor/bin/phpunit "$@"
        return 0
    fi

    run composer run test -- "$@"

}
test_csharp () {

    ensure_pkg dotnet
    source <(parse "$@" -- release:bool)

    if [[ "${release}" == "true" ]]; then run dotnet test -c Release --nologo "${kwargs[@]}"
    else run dotnet test -c Debug --nologo "${kwargs[@]}"
    fi

}
test_cpp () {

    source <(parse "$@" -- release:bool)

    local mode="debug" bt="Debug" out="build/debug"

    if (( release )); then
        mode="release"
        bt="Release"
        out="build/release"
    fi
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
        c)      test_c      "$@" ;;
        cpp)    test_cpp    "$@" ;;
        zig)    test_zig    "$@" ;;
        rust)   test_rust   "$@" ;;
        go)     test_go     "$@" ;;
        python) test_python "$@" ;;
        node)   test_node   "$@" ;;
        bun)    test_bun    "$@" ;;
        php)    test_php    "$@" ;;
        csharp) test_csharp "$@" ;;
        java)   test_java   "$@" ;;
        mojo)   test_mojo   "$@" ;;
        dart)   test_dart   "$@" ;;
        lua)    test_lua    "$@" ;;
        bash)   test_bash   "$@" ;;
        *)      die "test: unknown root manager" ;;
    esac

}
