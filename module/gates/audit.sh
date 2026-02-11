#!/usr/bin/env bash

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
audit_fix_rust () {

    ensure_pkg cargo
    run cargo update "$@"

}

audit_check_go () {

    ensure_pkg go govulncheck
    run govulncheck "$@" ./...

}
audit_fix_go () {

    ensure_pkg go

    run go get -u "$@" ./... && run go mod tidy

}

audit_check_py () {

    ensure_pkg python3 pip pip-audit
    run pip-audit "$@"

}
audit_fix_py () {

    ensure_pkg python3 pip pip-audit
    run pip-audit --fix "$@"

}

audit_check_node () {

    ensure_pkg pnpm
    run pnpm audit "$@"

}
audit_fix_node () {

    ensure_pkg pnpm
    run pnpm audit --fix "$@" && run pnpm install

}

audit_check_php () {

    ensure_pkg php composer
    run composer audit "$@"

}
audit_fix_php () {

    ensure_pkg php composer
    run composer update --no-interaction "$@"

}

cmd_audit_check () {

    case "$(which_lang)" in
        rust) audit_check_rust "$@" ;;
        go)   audit_check_go   "$@" ;;
        py)   audit_check_py   "$@" ;;
        node) audit_check_node "$@" ;;
        php)  audit_check_php  "$@" ;;
        *)    die "audit-check: unknown root manager" ;;
    esac

}
cmd_audit_fix () {

    case "$(which_lang)" in
        rust) audit_fix_rust "$@" ;;
        go)   audit_fix_go   "$@" ;;
        py)   audit_fix_py   "$@" ;;
        node) audit_fix_node "$@" ;;
        php)  audit_fix_php  "$@" ;;
        *)    die "audit-fix: unknown root manager" ;;
    esac

}
