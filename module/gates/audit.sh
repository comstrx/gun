#!/usr/bin/env bash

audit_check_c () {

    if has conan && [[ -f conanfile.py || -f conanfile.txt ]]; then
        ensure_pkg conan
        run conan audit scan . "$@"
        return 0
    fi

    warn "No auditor for c"

}
audit_check_cpp () {

    if has conan && [[ -f conanfile.py || -f conanfile.txt ]]; then
        ensure_pkg conan
        run conan audit scan . "$@"
        return 0
    fi

    warn "No auditor for cpp"

}
audit_check_zig () {

    warn "No auditor for zig"

}
audit_check_rust () {

    ensure_pkg cargo

    if [[ -f deny.toml ]] || [[ -f .deny.toml ]]; then
        ensure_pkg cargo-deny
        run cargo deny check "$@"
    else
        ensure_pkg cargo-audit
        run cargo audit "$@"
    fi

}
audit_check_go () {

    ensure_pkg go govulncheck
    run govulncheck "$@" ./...

}
audit_check_python () {

    ensure_pkg python3 pip pip-audit
    run pip-audit "$@"

}
audit_check_node () {

    ensure_pkg pnpm
    run pnpm audit "$@"

}
audit_check_bun () {

    ensure_pkg bun
    run bun audit "$@"

}
audit_check_php () {

    ensure_pkg php composer
    run composer audit "$@"

}
audit_check_csharp () {

    ensure_pkg dotnet
    run dotnet package list --include-transitive --vulnerable "$@"

}
audit_check_java () {

    ensure_pkg java

    if [[ -x ./gradlew ]]; then
        run ./gradlew -q dependencyCheckAnalyze "$@"
        return 0
    fi
    if [[ -x ./mvnw ]]; then
        run ./mvnw -q org.owasp:dependency-check-maven:check "$@"
        return 0
    fi

    die "audit-check: java requires gradlew/mvnw"

}
audit_check_mojo () {

    warn "No auditor for mojo"

}
audit_check_dart () {

    ensure_pkg dart osv-scanner
    [[ -f pubspec.lock ]] && run osv-scanner --lockfile=pubspec.lock "$@" || run osv-scanner "$@"

}
audit_check_lua () {

    warn "No auditor for lua"

}
audit_check_bash () {

    warn "No auditor for bash"

}

audit_fix_c () {

    if has conan && [[ -f conanfile.py || -f conanfile.txt ]]; then
        ensure_pkg conan
        run conan install . --update "$@"
        return 0
    fi

    warn "No audit fixer for c"

}
audit_fix_cpp () {

    if has conan && [[ -f conanfile.py || -f conanfile.txt ]]; then
        ensure_pkg conan
        run conan install . --update "$@"
        return 0
    fi

    warn "No audit fixer for cpp"

}
audit_fix_zig () {

    warn "No audit fixer for zig"

}
audit_fix_rust () {

    ensure_pkg cargo
    run cargo update "$@"

}
audit_fix_go () {

    ensure_pkg go
    run go get -u "$@" ./...
    run go mod tidy

}
audit_fix_python () {

    ensure_pkg python3 pip pip-audit
    run pip-audit --fix "$@"

}
audit_fix_node () {

    ensure_pkg pnpm
    run pnpm audit --fix "$@"
    run pnpm install

}
audit_fix_bun () {

    ensure_pkg bun
    run bun update "$@"

}
audit_fix_php () {

    ensure_pkg php composer
    run composer update --no-interaction "$@"

}
audit_fix_csharp () {

    ensure_pkg dotnet
    run dotnet package update --vulnerable "$@"

}
audit_fix_java () {

    warn "No audit fixer for java"

}
audit_fix_mojo () {

    if [[ -f pixi.toml ]]; then
        ensure_pkg pixi
        run pixi update "$@"
        return 0
    fi

    warn "No audit fixer for mojo"

}
audit_fix_dart () {

    ensure_pkg dart
    run dart pub upgrade "$@"

}
audit_fix_lua () {

    warn "No audit fixer for lua"

}
audit_fix_bash () {

    warn "No audit fixer for bash"

}

cmd_audit_check () {

    case "$(which_lang)" in
        c)      audit_check_c      "$@" ;;
        cpp)    audit_check_cpp    "$@" ;;
        zig)    audit_check_zig    "$@" ;;
        rust)   audit_check_rust   "$@" ;;
        go)     audit_check_go     "$@" ;;
        python) audit_check_python "$@" ;;
        php)    audit_check_php    "$@" ;;
        node)   audit_check_node   "$@" ;;
        bun)    audit_check_bun    "$@" ;;
        csharp) audit_check_csharp "$@" ;;
        java)   audit_check_java   "$@" ;;
        mojo)   audit_check_mojo   "$@" ;;
        dart)   audit_check_dart   "$@" ;;
        lua)    audit_check_lua    "$@" ;;
        bash)   audit_check_bash   "$@" ;;
        *)      die "audit-check: unknown root manager" ;;
    esac

}
cmd_audit_fix () {

    case "$(which_lang)" in
        c)      audit_fix_c      "$@" ;;
        cpp)    audit_fix_cpp    "$@" ;;
        zig)    audit_fix_zig    "$@" ;;
        rust)   audit_fix_rust   "$@" ;;
        go)     audit_fix_go     "$@" ;;
        python) audit_fix_python "$@" ;;
        php)    audit_fix_php    "$@" ;;
        node)   audit_fix_node   "$@" ;;
        bun)    audit_fix_bun    "$@" ;;
        csharp) audit_fix_csharp "$@" ;;
        java)   audit_fix_java   "$@" ;;
        mojo)   audit_fix_mojo   "$@" ;;
        dart)   audit_fix_dart   "$@" ;;
        lua)    audit_fix_lua    "$@" ;;
        bash)   audit_fix_bash   "$@" ;;
        *)      die "audit-fix: unknown root manager" ;;
    esac

}
