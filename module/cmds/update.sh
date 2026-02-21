#!/usr/bin/env bash

update_rust () {

    ensure_pkg cargo
    source <(parse "$@" -- release:bool)

    run cargo update "${kwargs[@]}"

}
update_go () {

    ensure_pkg go
    source <(parse "$@" -- release:bool)

    [[ -f go.work ]] && run go work sync

    if [[ -f go.mod ]]; then
        run go get -u "${kwargs[@]}" ./...
        run go mod tidy
        return 0
    fi

    [[ -f go.work ]] && return 0
    die "update: go needs go.mod or go.work"

}
update_python () {

    source <(parse "$@" -- release:bool)

    if [[ -f pyproject.toml ]]; then

        ensure_pkg uv

        local -a args=()
        (( release )) && args+=( --no-dev --no-editable )
        [[ -f uv.lock ]] && (( release )) && args+=( --locked )

        run uv sync --upgrade "${args[@]}" "${kwargs[@]}"
        return 0

    fi
    if [[ -f requirements.txt ]]; then

        ensure_pkg python3 pip
        run python3 -m pip install --no-input -U -r requirements.txt "${kwargs[@]}"
        return 0

    fi

    die "update: python needs pyproject.toml or requirements.txt"

}
update_node () {

    ensure_pkg pnpm
    source <(parse "$@" -- release:bool)

    [[ -f package.json ]] || die "update: node needs package.json"
    run pnpm up "${kwargs[@]}"

}
update_bun () {

    ensure_pkg bun
    source <(parse "$@" -- release:bool)

    [[ -f package.json ]] || die "update: bun needs package.json"
    run bun update "${kwargs[@]}"

}
update_php () {

    ensure_pkg php composer
    source <(parse "$@" -- release:bool)

    [[ -f composer.json ]] || die "update: php needs composer.json"
    run composer update --no-interaction --no-progress --prefer-dist "${kwargs[@]}"

}
update_csharp () {

    ensure_pkg dotnet
    source <(parse "$@" -- release:bool)

    local -a args=( --nologo )
    [[ -f packages.lock.json ]] && args+=( --locked-mode )

    run dotnet package update "${kwargs[@]}" || run dotnet restore "${args[@]}" "${kwargs[@]}"

}
update_cpp () {

    source <(parse "$@" -- release:bool)

    local mode="debug" bt="Debug" out="build/debug"
    (( release )) && { mode="release"; bt="Release"; out="build/release"; }

    if [[ -f xmake.lua ]]; then

        ensure_pkg xmake

        run xmake f -m "${mode}"
        run xmake require --upgrade "${kwargs[@]}" 2>/dev/null || true

        return 0

    fi
    if [[ -f conanfile.py || -f conanfile.txt ]]; then

        ensure_pkg conan cmake ninja

        run mkdir -p "${out}"

        run conan profile detect --force >/dev/null 2>&1 || true
        run conan install . --output-folder "${out}" -s "build_type=${bt}" --build=missing --update "${kwargs[@]}"

        [[ -f conanfile.txt && ! -f "${out}/conan_toolchain.cmake" ]] && die "update: cpp conan missing conan_toolchain.cmake"

        return 0

    fi

    die "update: cpp needs xmake.lua or conanfile"

}
update_bash () {

    warn "bash: no update step required"

}
update_lua () {

    warn "lua: no update step required"

}
cmd_update () {

    case "$(which_lang)" in
        rust)    update_rust   "$@" ;;
        go)      update_go     "$@" ;;
        python)  update_python "$@" ;;
        node)    update_node   "$@" ;;
        bun)     update_bun    "$@" ;;
        php)     update_php    "$@" ;;
        csharp)  update_csharp "$@" ;;
        cpp)     update_cpp    "$@" ;;
        bash)    update_bash   "$@" ;;
        lua)     update_lua    "$@" ;;
        *)       die "update: unsupported language" ;;
    esac

}
