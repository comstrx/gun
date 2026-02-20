#!/usr/bin/env bash

run_rust () {

    ensure_pkg cargo

    if [[ -f Cargo.lock ]]; then run cargo run --locked "$@"
    else run cargo run "$@"
    fi

}
run_go () {

    ensure_pkg go
    run go run -buildvcs=false "$@" .

}
run_python () {

    ensure_pkg python3

    [[ -f pyproject.toml ]] || die "run: python needs pyproject.toml"

    local name="$(python3 -c 'import tomllib; d=tomllib.load(open("pyproject.toml","rb")); print((d.get("project") or {}).get("name",""))' 2>/dev/null || true)"
    name="${name//-/_}"
    
    local mod="${name}" runner=( python3 )
    [[ -n "${mod}" ]] || die "run: python cannot read project.name from pyproject.toml"

    if has uv; then runner=( uv run python ); fi
    run "${runner[@]}" -m "${mod}" "$@"

}
run_node () {

    ensure_pkg pnpm

    [[ -f package.json ]] || die "run: node needs package.json"

    if [[ -f pnpm-lock.yaml ]]; then run pnpm install --frozen-lockfile
    else run pnpm install
    fi

    local script="$(node -p 'const p=require("./package.json"); const s=(p.scripts||{}); (["start","dev","run"].find(k=>s[k])||"")' 2>/dev/null || true)"
    [[ -n "${script}" ]] || die "run: node needs scripts.start/dev/run in package.json"

    run pnpm run "${script}" "$@"

}
run_bun () {

    ensure_pkg bun

    [[ -f package.json ]] || die "run: bun needs package.json"

    if [[ -f bun.lockb || -f bun.lock ]]; then run bun install --frozen-lockfile
    else run bun install
    fi

    local script="$(bun -e 'const p=require("./package.json"); const s=(p.scripts||{}); const k=["start","dev","run"].find(x=>s[x]); if(k) process.stdout.write(k);' 2>/dev/null || true)"
    [[ -n "${script}" ]] || die "run: bun needs scripts.start/dev/run in package.json"

    run bun run "${script}" "$@"

}
run_php () {

    ensure_pkg php composer

    [[ -f composer.json ]] || die "run: php needs composer.json"
    run composer install --no-interaction --no-progress --prefer-dist

    local script="$(php -r '$j=json_decode(file_get_contents("composer.json"),true); $s=$j["scripts"]??[]; foreach(["start","serve","run"] as $k){ if(isset($s[$k])){ echo $k; exit; }}' 2>/dev/null || true)"

    if [[ -n "${script}" ]]; then
        run composer run "${script}" -- "$@"
        return 0
    fi
    if [[ -f artisan ]]; then
        run php artisan serve "$@"
        return 0
    fi
    if [[ -f public/index.php ]]; then
        run php -S 127.0.0.1:8000 -t public
        return 0
    fi
    if [[ -f index.php ]]; then
        run php index.php "$@"
        return 0
    fi

    die "run: php needs composer script (start/serve/run) or artisan/public/index.php/index.php"

}
run_csharp () {

    ensure_pkg dotnet
    source <(parse "$@" -- release:bool)

    if [[ "${release}" == "true" ]]; then run dotnet run -c Release --no-build "${kwargs[@]}"
    else run dotnet run -c Debug --no-build "${kwargs[@]}"
    fi

}
run_cpp () {

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
        run xmake run "${kwargs[@]}"
        return 0

    fi
    if [[ -f conanfile.py || -f conanfile.txt ]]; then

        ensure_pkg conan cmake ninja
        mkdir -p "${out}"

        run conan profile detect --force >/dev/null 2>&1 || true
        run conan install . --output-folder "${out}" -s "build_type=${bt}" -b missing "${kwargs[@]}"

        if [[ -f conanfile.txt ]]; then

            [[ -f "${out}/conan_toolchain.cmake" ]] || die "run: cpp conan missing conan_toolchain.cmake"

            run cmake -S . -B "${out}" -G Ninja -DCMAKE_TOOLCHAIN_FILE="${out}/conan_toolchain.cmake" -DCMAKE_BUILD_TYPE="${bt}"
            run cmake --build "${out}"

        else
            run conan build . --output-folder "${out}" "${kwargs[@]}"
        fi

        local exe="$(find "${out}" -maxdepth 3 -type f -perm -111 \
            ! -name '*.a' ! -name '*.so' ! -name '*.so.*' ! -name '*.dylib' ! -name '*.dll' \
            ! -name '*.o' ! -name '*.obj' ! -name '*.cmake' 2>/dev/null | head -n 1 || true)"

        [[ -n "${exe}" ]] || die "run: cpp conan produced no runnable binary (build in ${out})"
        run "${exe}"

        return 0

    fi

    die "run: cpp needs xmake.lua or conanfile.py or conanfile.txt"

}

cmd_run () {

    case "$(which_lang)" in
        rust)   run_rust   "$@" ;;
        go)     run_go     "$@" ;;
        python) run_python "$@" ;;
        node)   run_node   "$@" ;;
        bun)    run_bun    "$@" ;;
        php)    run_php    "$@" ;;
        csharp) run_csharp "$@" ;;
        cpp)    run_cpp    "$@" ;;
        *)      die "run: unknown root manager" ;;
    esac

}
