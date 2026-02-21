#!/usr/bin/env bash

test_rust () {

    ensure_pkg cargo
    source <(parse "$@" -- release:bool)

    local args=()

    (( release )) && args+=( --release )
    [[ -f Cargo.lock ]] && args+=( --locked )

    if has cargo-nextest; then run cargo nextest run "${args[@]}" "${kwargs[@]}"
    else run cargo test "${args[@]}" "${kwargs[@]}"
    fi

}
test_go () {

    ensure_pkg go
    source <(parse "$@" -- release:bool)

    run go test -count=1 -buildvcs=false ./... "${kwargs[@]}"

}
test_python () {

    source <(parse "$@" -- release:bool)

    if [[ -f pyproject.toml ]]; then
        ensure_pkg uv
        run uv run pytest -q "${kwargs[@]}"
        return 0
    fi

    ensure_pkg python3 pip

    run python3 -m pip install -q pytest
    run python3 -m pytest -q "${kwargs[@]}"

}
test_node () {

    ensure_pkg pnpm
    source <(parse "$@" -- release:bool)

    [[ -f package.json ]] || die "test: node needs package.json"

    if [[ -f pnpm-lock.yaml ]]; then run pnpm install --frozen-lockfile
    else run pnpm install
    fi

    run pnpm test "${kwargs[@]}"

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

    if (( release )); then run composer install --no-interaction --no-progress --prefer-dist --no-dev --optimize-autoloader
    else run composer install --no-interaction --no-progress --prefer-dist
    fi

    if [[ -x vendor/bin/pest ]]; then run vendor/bin/pest "${kwargs[@]}"
    elif [[ -x vendor/bin/phpunit ]]; then run vendor/bin/phpunit "${kwargs[@]}"
    else run composer test "${kwargs[@]}"
    fi

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

        run xmake f -m "${mode}"
        run xmake
        run xmake test "${kwargs[@]}"

        return 0

    fi
    if [[ -f conanfile.py || -f conanfile.txt ]]; then

        ensure_pkg conan cmake ninja

        run mkdir -p "${out}"
        run conan profile detect --force >/dev/null 2>&1 || true
        run conan install . --output-folder "${out}" -s "build_type=${bt}" -b missing

        if [[ -f conanfile.txt ]]; then
            [[ -f "${out}/conan_toolchain.cmake" ]] || die "test: cpp conan missing conan_toolchain.cmake"
            run cmake -S . -B "${out}" -G Ninja -DCMAKE_TOOLCHAIN_FILE="${out}/conan_toolchain.cmake" -DCMAKE_BUILD_TYPE="${bt}"
            run cmake --build "${out}" --parallel
        else
            run conan build . --output-folder "${out}"
        fi

        [[ -f "${out}/CTestTestfile.cmake" ]] || { warn "test: cpp no tests found"; return 0; }
        run ctest --test-dir "${out}" --output-on-failure "${kwargs[@]}"

        return 0

    fi

    die "test: cpp needs xmake.lua or conanfile"

}
test_bash () {

    source <(parse "$@" -- release:bool)
    warn "bash: no test step required"

}
test_lua () {

    source <(parse "$@" -- release:bool)
    warn "lua: no test step required"

}
cmd_test () {

    case "$(which_lang)" in
        rust)    test_rust   "$@" ;;
        go)      test_go     "$@" ;;
        python)  test_python "$@" ;;
        node)    test_node   "$@" ;;
        bun)     test_bun    "$@" ;;
        php)     test_php    "$@" ;;
        csharp)  test_csharp "$@" ;;
        cpp)     test_cpp    "$@" ;;
        bash)    test_bash   "$@" ;;
        lua)     test_lua    "$@" ;;
        *)       die "test: unsupported language" ;;
    esac

}
