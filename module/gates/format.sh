#!/usr/bin/env bash

fmt_check_c () {

    ensure_pkg clang-format find
    find . -type f \( -name '*.c' -o -name '*.h' \) -exec \
        clang-format -style=file -fallback-style=none --dry-run --Werror "$@" {} +

}
fmt_check_cpp () {

    ensure_pkg clang-format find
    find . -type f \( -name '*.cpp' -o -name '*.hpp' -o -name '*.cc' -o -name '*.hh' \) -exec \
        clang-format -style=file -fallback-style=none --dry-run --Werror "$@" {} +

}
fmt_check_rust () {

    ensure_pkg rustup rustfmt
    run cargo +"${RUST_NIGHTLY:-nightly}" fmt --all --check "$@"

}
fmt_check_zig () {

    ensure_pkg zig
    run zig fmt --check "$@" .

}
fmt_check_go () {

    ensure_pkg goimports

    local out="$(goimports -l "$@" . 2>&1)" || { printf '%s\n' "${out}"; return 1; }
    [[ -n "${out}" ]] && { printf '%s\n' "${out}"; return 1; }
    return 0

}
fmt_check_python () {

    ensure_pkg ruff

    local -a cmd=()

    local config="$(config_file ruff-fmt toml)"
    [[ -f "${config}" ]] || config="$(config_file ruff toml)"
    [[ -f "${config}" ]] && cmd+=( --config "${config}" )

    run ruff format --check "${cmd[@]}" "$@" .

}
fmt_check_mojo () {

    ensure_pkg mojo
    run mojo format --check "$@" .

}
fmt_check_php () {

    ensure_pkg php

    local -a cmd=( pint )
    [[ -x vendor/bin/pint ]] && cmd=( vendor/bin/pint )

    local config="$(config_file pint json)"
    [[ -f "${config}" ]] && cmd+=( --config "${config}" )

    run "${cmd[@]}" --test "$@" .

}
fmt_check_node () {

    ensure_pkg npx

    local -a cmd=( npx -y @biomejs/biome format )
    [[ -x node_modules/.bin/biome ]] && cmd=( node_modules/.bin/biome format )

    local config="$(config_file biome-fmt json)"
    [[ -f "${config}" ]] || config="$(config_file biome json)"
    [[ -f "${config}" ]] && cmd+=( --config-path "${config}" )

    run "${cmd[@]}" "$@" .

}
fmt_check_bun () {

    ensure_pkg bun

    local -a cmd=( bunx @biomejs/biome format )
    [[ -x node_modules/.bin/biome ]] && cmd=( node_modules/.bin/biome format )

    local config="$(config_file biome-fmt json)"
    [[ -f "${config}" ]] || config="$(config_file biome json)"
    [[ -f "${config}" ]] && cmd+=( --config-path "${config}" )

    run "${cmd[@]}" "$@" .

}
fmt_check_csharp () {

    ensure_pkg dotnet
    run dotnet format --verify-no-changes "$@"

}
fmt_check_java () {

    ensure_pkg java

    if [[ -x ./gradlew ]]; then
        run ./gradlew -q spotlessCheck "$@"
        return 0
    fi
    if [[ -x ./mvnw ]]; then
        run ./mvnw -q spotless:check "$@"
        return 0
    fi

    die "fmt-check: java requires gradlew/mvnw"

}
fmt_check_dart () {

    ensure_pkg dart
    run dart format -o none --set-exit-if-changed --line-length 120 "$@" .

}
fmt_check_lua () {

    ensure_pkg stylua
    run stylua --check "$@" .

}
fmt_check_bash () {

    ensure_pkg shfmt
    run shfmt --apply-ignore -d "$@" .

}

fmt_fix_c () {

    ensure_pkg clang-format find
    find . -type f \( -name '*.c' -o -name '*.h' \) -exec \
        clang-format -style=file -fallback-style=none -i "$@" {} +

}
fmt_fix_cpp () {

    ensure_pkg clang-format find
    find . -type f \( -name '*.cpp' -o -name '*.hpp' -o -name '*.cc' -o -name '*.hh' \) -exec \
        clang-format -style=file -fallback-style=none -i "$@" {} +

}
fmt_fix_rust () {

    ensure_pkg rustup rustfmt
    run cargo +"${RUST_NIGHTLY:-nightly}" fmt --all "$@"

}
fmt_fix_zig () {

    ensure_pkg zig
    run zig fmt "$@" .

}
fmt_fix_go () {

    ensure_pkg goimports
    run goimports -w "$@" .

}
fmt_fix_python () {

    ensure_pkg ruff

    local -a cmd=()
    local config="$(config_file ruff-fmt toml)"
    [[ -f "${config}" ]] || config="$(config_file ruff toml)"
    [[ -f "${config}" ]] && cmd+=( --config "${config}" )

    run ruff format "${cmd[@]}" "$@" .

}
fmt_fix_mojo () {

    ensure_pkg mojo
    run mojo format "$@" .

}
fmt_fix_php () {

    ensure_pkg php

    local -a cmd=( pint )
    [[ -x vendor/bin/pint ]] && cmd=( vendor/bin/pint )

    local config="$(config_file pint json)"
    [[ -f "${config}" ]] && cmd+=( --config "${config}" )

    run "${cmd[@]}" "$@" .

}
fmt_fix_node () {

    ensure_pkg npx

    local -a cmd=( npx -y @biomejs/biome format )
    [[ -x node_modules/.bin/biome ]] && cmd=( node_modules/.bin/biome format )

    local config="$(config_file biome-fmt json)"
    [[ -f "${config}" ]] || config="$(config_file biome json)"
    [[ -f "${config}" ]] && cmd+=( --config-path "${config}" )

    run "${cmd[@]}" --write "$@" .

}
fmt_fix_bun () {

    ensure_pkg bun

    local -a cmd=( bunx @biomejs/biome format )
    [[ -x node_modules/.bin/biome ]] && cmd=( node_modules/.bin/biome format )

    local config="$(config_file biome-fmt json)"
    [[ -f "${config}" ]] || config="$(config_file biome json)"
    [[ -f "${config}" ]] && cmd+=( --config-path "${config}" )

    run "${cmd[@]}" --write "$@" .

}
fmt_fix_csharp () {

    ensure_pkg dotnet
    run dotnet format "$@"

}
fmt_fix_java () {

    ensure_pkg java

    if [[ -x ./gradlew ]]; then
        run ./gradlew -q spotlessApply "$@"
        return 0
    fi
    if [[ -x ./mvnw ]]; then
        run ./mvnw -q spotless:apply "$@"
        return 0
    fi

    die "fmt-fix: java requires gradlew/mvnw"

}
fmt_fix_dart () {

    ensure_pkg dart
    run dart format --line-length 120 "$@" .

}
fmt_fix_lua () {

    ensure_pkg stylua
    run stylua "$@" .

}
fmt_fix_bash () {

    ensure_pkg shfmt
    run shfmt --apply-ignore -w "$@" .

}

cmd_fmt_check () {

    case "$(which_lang)" in
        c)      fmt_check_c "$@" ;;
        cpp)    fmt_check_cpp "$@" ;;
        rust)   fmt_check_rust "$@" ;;
        zig)    fmt_check_zig "$@" ;;
        go)     fmt_check_go "$@" ;;
        python) fmt_check_python "$@" ;;
        mojo)   fmt_check_mojo "$@" ;;
        php)    fmt_check_php "$@" ;;
        node)   fmt_check_node "$@" ;;
        bun)    fmt_check_bun "$@" ;;
        csharp) fmt_check_csharp "$@" ;;
        java)   fmt_check_java "$@" ;;
        dart)   fmt_check_dart "$@" ;;
        lua)    fmt_check_lua "$@" ;;
        bash)   fmt_check_bash "$@" ;;
        *)      die "fmt-check: unknown root manager" ;;
    esac

}
cmd_fmt_fix () {

    case "$(which_lang)" in
        c)      fmt_fix_c "$@" ;;
        cpp)    fmt_fix_cpp "$@" ;;
        rust)   fmt_fix_rust "$@" ;;
        zig)    fmt_fix_zig "$@" ;;
        go)     fmt_fix_go "$@" ;;
        python) fmt_fix_python "$@" ;;
        mojo)   fmt_fix_mojo "$@" ;;
        php)    fmt_fix_php "$@" ;;
        node)   fmt_fix_node "$@" ;;
        bun)    fmt_fix_bun "$@" ;;
        csharp) fmt_fix_csharp "$@" ;;
        java)   fmt_fix_java "$@" ;;
        dart)   fmt_fix_dart "$@" ;;
        lua)    fmt_fix_lua "$@" ;;
        bash)   fmt_fix_bash "$@" ;;
        *)      die "fmt-fix: unknown root manager" ;;
    esac

}
