#!/usr/bin/env bash

cov_prepare_out () {

    local out="${1:-}"

    [[ -n "${out}" ]] || return 0
    [[ "${out}" == */* ]] && run mkdir -p -- "${out%/*}"

    : > "${out}"

}
cov_default_out () {

    case "${1:-}:${2:-lcov}" in
        rust:codecov )  printf '%s' "codecov.json" ;;
        rust:json )     printf '%s' "llvm-cov.json" ;;
        rust:* )        printf '%s' "lcov.info" ;;

        go:* )          printf '%s' "coverage.out" ;;

        python:json )   printf '%s' "python.json" ;;
        python:xml )    printf '%s' "cobertura.xml" ;;
        python:* )      printf '%s' "python.lcov" ;;

        node:* )        printf '%s' "lcov.info" ;;
        bun:* )         printf '%s' "lcov.info" ;;

        php:* )         printf '%s' "clover.xml" ;;

        c:xml )         printf '%s' "cobertura.xml" ;;
        c:* )           printf '%s' "lcov.info" ;;
        cpp:xml )       printf '%s' "cobertura.xml" ;;
        cpp:* )         printf '%s' "lcov.info" ;;

        csharp:* )      printf '%s' "cobertura.xml" ;;
        java:* )        printf '%s' "jacoco.xml" ;;

        dart:* )        printf '%s' "lcov.info" ;;
        lua:* )         printf '%s' "lcov.info" ;;

        * )             printf '%s' "lcov.info" ;;
    esac

}
cov_upload_out () {

    ensure_pkg curl chmod mv mkdir
    source <(parse "$@" -- lang mode name version token flags out)

    [[ -n "${flags}" ]] || flags="${lang}"
    [[ -n "${name}"  ]] || name="coverage-${lang}-${GITHUB_RUN_ID:-local}"

    [[ -n "${version}" ]] || version="latest"
    [[ -n "${version}" && "${version}" != "latest" && "${version}" != v* ]] && version="v${version}"
    [[ -n "${out}" ]] || out="$(cov_default_out "${lang}" "${mode}")"

    [[ -n "${token}" ]] || token="${CODECOV_TOKEN:-}"
    [[ -n "${token}" ]] || die "codecov: CODECOV_TOKEN is missing."

    [[ -f "${out}" ]] || die "codecov: file not found: ${out}"

    local os="$(uname -s | tr '[:upper:]' '[:lower:]')"
    local arch="$(uname -m)" dist="linux"

    if [[ "${os}" == "darwin" ]]; then dist="macos"; fi
    if [[ "${dist}" == "linux" && ( "${arch}" == "aarch64" || "${arch}" == "arm64" ) ]]; then dist="linux-arm64"; fi

    local cache_dir="${TMPDIR:-/tmp}/.codecov/cache" resolved="${version}"
    local bin="${cache_dir}/codecov-${dist}-${resolved}"

    mkdir -p -- "${cache_dir}"

    if [[ "${version}" == "latest" ]]; then

        local latest_page="$(curl -fsSL "https://cli.codecov.io/${dist}/latest" 2>/dev/null || true)"
        local v="$(printf '%s\n' "${latest_page}" | grep -Eo 'v[0-9]+\.[0-9]+\.[0-9]+' | head -n 1 || true)"

        [[ -n "${v}" ]] && resolved="${v}"
        bin="${cache_dir}/codecov-${dist}-${resolved}"

    fi
    if [[ ! -x "${bin}" ]]; then

        local url_a="https://cli.codecov.io/${dist}/${resolved}/codecov"
        local url_b="https://cli.codecov.io/${resolved}/${dist}/codecov"
        local sha_a="https://cli.codecov.io/${dist}/${resolved}/codecov.SHA256SUM"
        local sha_b="https://cli.codecov.io/${resolved}/${dist}/codecov.SHA256SUM"
        local sig_a="https://cli.codecov.io/${dist}/${resolved}/codecov.SHA256SUM.sig"
        local sig_b="https://cli.codecov.io/${resolved}/${dist}/codecov.SHA256SUM.sig"

        local tmp_dir="$(mktemp -d "${cache_dir}/codecov.tmp.XXXXXX" 2>/dev/null || true)"

        if [[ -z "${tmp_dir}" || ! -d "${tmp_dir}" ]]; then
            tmp_dir="${cache_dir}/codecov.tmp.$$"
            mkdir -p -- "${tmp_dir}" || die "Codecov: failed to create temp dir."
        fi

        local tmp_bin="${tmp_dir}/codecov"
        local tmp_sha="${tmp_dir}/codecov.SHA256SUM"
        local tmp_sig="${tmp_dir}/codecov.SHA256SUM.sig"

        trap 'rm -rf -- "${tmp_dir:-}" 2>/dev/null || true; trap - RETURN' RETURN
        rm -f -- "${tmp_bin}" "${tmp_sha}" "${tmp_sig}" 2>/dev/null || true

        run curl -fsSL -o "${tmp_bin}" "${url_a}" || run curl -fsSL -o "${tmp_bin}" "${url_b}"
        run curl -fsSL -o "${tmp_sha}" "${sha_a}" || run curl -fsSL -o "${tmp_sha}" "${sha_b}"

        curl -fsSL -o "${tmp_sig}" "${sig_a}" 2>/dev/null || curl -fsSL -o "${tmp_sig}" "${sig_b}" 2>/dev/null || rm -f -- "${tmp_sig}" 2>/dev/null || true

        if [[ -f "${tmp_sig}" ]] && has gpg; then

            local keyring="${tmp_dir}/trustedkeys.gpg"
            local keyfile="${tmp_dir}/codecov.pgp.asc"
            local want_fp="27034E7FDB850E0BBC2C62FF806BB28AED779869"

            run curl -fsSL -o "${keyfile}" "https://keybase.io/codecovsecurity/pgp_keys.asc"
            gpg --no-default-keyring --keyring "${keyring}" --import "${keyfile}" >/dev/null 2>&1 || true

            local got_fp="$(gpg --no-default-keyring --keyring "${keyring}" --fingerprint --with-colons 2>/dev/null | awk -F: '$1=="fpr"{print $10; exit}' || true)"

            [[ -n "${got_fp}" ]] || die "Codecov: cannot read PGP fingerprint."
            [[ "${got_fp}" == "${want_fp}" ]] || die "Codecov: PGP fingerprint mismatch."

            gpg --no-default-keyring --keyring "${keyring}" --verify "${tmp_sig}" "${tmp_sha}" >/dev/null 2>&1 || die "Codecov: SHA256SUM signature verification failed."

        fi

        local got="" want="$(awk '$2 ~ /(^|\/)codecov$/ { print $1; exit }' "${tmp_sha}" 2>/dev/null || true)"
        [[ -n "${want}" ]] || die "Codecov: invalid SHA256SUM file."

        if has sha256sum; then got="$(sha256sum "${tmp_bin}" 2>/dev/null | awk '{print $1}' || true)"
        elif has shasum; then got="$(shasum -a 256 "${tmp_bin}" 2>/dev/null | awk '{print $1}' || true)"
        elif has openssl; then got="$(openssl dgst -sha256 "${tmp_bin}" 2>/dev/null | awk '{print $NF}' || true)"
        else die "Codecov: no SHA256 tool found (need sha256sum or shasum or openssl)."
        fi

        [[ -n "${got}" ]] || die "Codecov: failed to compute checksum."
        [[ "${got}" == "${want}" ]] || die "Codecov: checksum mismatch."

        run chmod +x "${tmp_bin}"
        run mv -f -- "${tmp_bin}" "${bin}"
        run "${bin}" --version >/dev/null 2>&1

    fi

    export CODECOV_TOKEN="${token}"
    local -a args=( --verbose upload-process --disable-search --fail-on-error -f "${out}" )

    [[ -n "${flags}" ]] && args+=( -F "${flags}" )
    [[ -n "${name}"  ]] && args+=( -n "${name}" )

    run "${bin}" "${args[@]}"
    success "Ok: Codecov file uploaded."

}

coverage_c () {

    ensure_pkg gcovr
    source <(parse "$@" -- mode out)

    cov_prepare_out "${out}"

    if [[ "${mode}" == "xml" ]]; then
        run gcovr -r . --cobertura-pretty -o "${out}" "${kwargs[@]}"
        return 0
    fi

    run gcovr -r . --lcov -o "${out}" "${kwargs[@]}"

}
coverage_cpp () {

    ensure_pkg gcovr
    source <(parse "$@" -- mode out)

    cov_prepare_out "${out}"

    if [[ "${mode}" == "xml" ]]; then
        run gcovr -r . --cobertura-pretty -o "${out}" "${kwargs[@]}"
        return 0
    fi

    run gcovr -r . --lcov -o "${out}" "${kwargs[@]}"

}
coverage_zig () {

    warn "No coverage for zig"

}
coverage_rust () {

    ensure_pkg cargo cargo-llvm-cov
    source <(parse "$@" -- mode out)

    local -a args=( --exclude bloats --exclude fuzz --"${mode}" )

    cov_prepare_out "${out}"

    run_cargo llvm-cov clean --workspace
    run_cargo llvm-cov --workspace --all-targets --all-features "${args[@]}" --output-path "${out}" --remap-path-prefix "${kwargs[@]}"

}
coverage_go () {

    ensure_pkg go
    source <(parse "$@" -- mode out)

    cov_prepare_out "${out}"
    run go test -covermode=atomic -coverprofile="${out}" "${kwargs[@]}" ./...

}
coverage_python () {

    ensure_pkg python3
    source <(parse "$@" -- mode out)

    cov_prepare_out "${out}"
    run python3 -m coverage erase

    if (( ${#kwargs[@]} )); then run python3 -m coverage run --branch --source . "${kwargs[@]}"
    elif python3 -m pytest --version >/dev/null 2>&1; then run python3 -m coverage run --branch --source . -m pytest
    else run python3 -m coverage run --branch --source . -m unittest discover
    fi

    if [[ "${mode}" == "json" ]]; then
        run python3 -m coverage json -o "${out}"
        return 0
    fi
    if [[ "${mode}" == "xml" ]]; then
        run python3 -m coverage xml -o "${out}"
        return 0
    fi

    run python3 -m coverage lcov -o "${out}"

}
coverage_mojo () {

    warn "No coverage for mojo"

}
coverage_node () {

    ensure_pkg node pnpm
    source <(parse "$@" -- mode out)

    local out_dir="$(dirname "${out}")"
    local tmp="${out_dir}/lcov.info"
    local -a c8=( pnpm dlx c8 )

    [[ -x node_modules/.bin/c8 ]] && c8=( node_modules/.bin/c8 )

    cov_prepare_out "${out}"

    run "${c8[@]}" --reporter=lcovonly --report-dir "${out_dir}" --all --exclude-after-remap pnpm test --silent "${kwargs[@]}"
    [[ "${tmp}" == "${out}" ]] || { [[ -f "${tmp}" ]] && run mv -f "${tmp}" "${out}"; }

}
coverage_bun () {

    ensure_pkg bun
    source <(parse "$@" -- mode out)

    cov_prepare_out "${out}"

    run bun test --coverage --coverage-reporter=lcov "${kwargs[@]}"

    if [[ -f coverage/lcov.info ]]; then
        run cp coverage/lcov.info "${out}"
        return 0
    fi

    warn "bun coverage file not found (expected coverage/lcov.info)"

}
coverage_php () {

    ensure_pkg php
    source <(parse "$@" -- mode out)

    local phpunit="phpunit"
    [[ -x vendor/bin/phpunit ]] && phpunit="vendor/bin/phpunit"

    cov_prepare_out "${out}"
    XDEBUG_MODE=coverage run php "${phpunit}" --coverage-clover "${out}" "${kwargs[@]}"

}
coverage_csharp () {

    ensure_pkg dotnet
    source <(parse "$@" -- mode out)

    cov_prepare_out "${out}"
    run dotnet test --collect:"XPlat Code Coverage" "${kwargs[@]}"

    local got="$(find . -type f -name 'coverage.cobertura.xml' -path '*TestResults*' 2>/dev/null | head -n 1 || true)"
    [[ -n "${got}" ]] || { warn "No cobertura file found for csharp"; return 0; }

    run cp "${got}" "${out}"

}
coverage_java () {

    ensure_pkg java
    source <(parse "$@" -- mode out)

    cov_prepare_out "${out}"

    if [[ -x ./gradlew ]]; then
        run ./gradlew -q test jacocoTestReport "${kwargs[@]}"

        local got="build/reports/jacoco/test/jacocoTestReport.xml"
        [[ -f "${got}" ]] || got="$(find . -type f -name 'jacocoTestReport.xml' -path '*build/reports/jacoco*' 2>/dev/null | head -n 1 || true)"
        [[ -f "${got}" ]] || { warn "No jacoco xml found"; return 0; }

        run cp "${got}" "${out}"
        return 0
    fi
    if [[ -x ./mvnw ]]; then
        run ./mvnw -q test jacoco:report "${kwargs[@]}"

        local got="target/site/jacoco/jacoco.xml"
        [[ -f "${got}" ]] || got="$(find . -type f -name 'jacoco.xml' -path '*target/site/jacoco*' 2>/dev/null | head -n 1 || true)"
        [[ -f "${got}" ]] || { warn "No jacoco xml found"; return 0; }

        run cp "${got}" "${out}"
        return 0
    fi

    warn "No coverage for java (need gradlew/mvnw)"

}
coverage_dart () {

    ensure_pkg dart
    source <(parse "$@" -- mode out)

    cov_prepare_out "${out}"

    if has flutter && [[ -f pubspec.yaml ]] && grep -qE '^[[:space:]]*flutter:' pubspec.yaml 2>/dev/null; then

        run flutter test --coverage "${kwargs[@]}"

        [[ -f coverage/lcov.info ]] || { warn "No lcov file found for flutter"; return 0; }
        run cp coverage/lcov.info "${out}"

        return 0

    fi

    run dart test --coverage=coverage "${kwargs[@]}"

    local pkg=""
    [[ -f .dart_tool/package_config.json ]] && pkg=".dart_tool/package_config.json"
    [[ -z "${pkg}" && -f .packages ]] && pkg=".packages"

    if has format_coverage; then

        [[ -n "${pkg}" ]] && run format_coverage --lcov --in=coverage --out="${out}" --report-on=lib --packages="${pkg}" || \
            run format_coverage --lcov --in=coverage --out="${out}" --report-on=lib

        return 0

    fi

    run dart pub global activate coverage >/dev/null 2>&1 || true

    if dart pub global run coverage:format_coverage --help >/dev/null 2>&1; then

        [[ -n "${pkg}" ]] && run dart pub global run coverage:format_coverage --lcov --in=coverage --out="${out}" --report-on=lib --packages="${pkg}" || \
            run dart pub global run coverage:format_coverage --lcov --in=coverage --out="${out}" --report-on=lib

        return 0

    fi

    warn "No coverage formatter for dart (need coverage:format_coverage)"

}
coverage_lua () {

    if ! has lua || ! has luacov; then
        warn "No coverage for lua"
        return 0
    fi
    if ! luacov -r lcov --help >/dev/null 2>&1; then
        warn "lua coverage requires luacov-reporter-lcov"
        return 0
    fi

    source <(parse "$@" -- mode out)

    cov_prepare_out "${out}"

    if has busted; then
        run busted -c "${kwargs[@]}"
    else
        warn "No lua test runner (need busted)"
        return 0
    fi

    run luacov -r lcov

    [[ -f luacov.report.out ]] || { warn "No luacov report found"; return 0; }
    run cp luacov.report.out "${out}"

}
coverage_bash () {

    warn "No coverage for bash"

}

cmd_coverage () {

    source <(parse "$@" -- mode=lcov name version flags token out upload:bool)

    local lang="$(which_lang)"
    out="${out:-"${OUT_DIR:-out}/$(cov_default_out "${lang}" "${mode}")"}"

    case "${lang}" in
        c)      coverage_c       "${mode}" "${out}" "${kwargs[@]}" ;;
        cpp)    coverage_cpp     "${mode}" "${out}" "${kwargs[@]}" ;;
        zig)    coverage_zig     "${mode}" "${out}" "${kwargs[@]}" ;;
        rust)   coverage_rust    "${mode}" "${out}" "${kwargs[@]}" ;;
        go)     coverage_go      "${mode}" "${out}" "${kwargs[@]}" ;;
        python) coverage_python  "${mode}" "${out}" "${kwargs[@]}" ;;
        node)   coverage_node    "${mode}" "${out}" "${kwargs[@]}" ;;
        bun)    coverage_bun     "${mode}" "${out}" "${kwargs[@]}" ;;
        php)    coverage_php     "${mode}" "${out}" "${kwargs[@]}" ;;
        csharp) coverage_csharp  "${mode}" "${out}" "${kwargs[@]}" ;;
        java)   coverage_java    "${mode}" "${out}" "${kwargs[@]}" ;;
        mojo)   coverage_mojo    "${mode}" "${out}" "${kwargs[@]}" ;;
        dart)   coverage_dart    "${mode}" "${out}" "${kwargs[@]}" ;;
        lua)    coverage_lua     "${mode}" "${out}" "${kwargs[@]}" ;;
        bash)   coverage_bash    "${mode}" "${out}" "${kwargs[@]}" ;;
        *)      die "coverage: unknown root manager" ;;
    esac

    success "Ok: coverage processed -> ${out}"
    (( upload )) && cov_upload_out "${lang}" "${mode}" "${name}" "${version}" "${token}" "${flags}" "${out}"

}
