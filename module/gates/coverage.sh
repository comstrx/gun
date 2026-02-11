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
        go:lcov )       printf '%s' "coverage.out" ;;
        go:* )          printf '%s' "coverage.out" ;;
        py:lcov )       printf '%s' "python.lcov" ;;
        py:json )       printf '%s' "python.json" ;;
        py:xml )        printf '%s' "cobertura.xml" ;;
        py:* )          printf '%s' "python.lcov" ;;
        node:* )        printf '%s' "lcov.info" ;;
        php:* )         printf '%s' "clover.xml" ;;
        c:lcov )        printf '%s' "lcov.info" ;;
        c:* )           printf '%s' "cobertura.xml" ;;
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
coverage_py () {

    ensure_pkg python
    source <(parse "$@" -- mode out)

    cov_prepare_out "${out}"
    run python -m coverage erase

    if (( ${#kwargs[@]} )); then run python -m coverage run --branch --source . "${kwargs[@]}"
    elif python -m pytest --version >/dev/null 2>&1; then run python -m coverage run --branch --source . -m pytest
    else run python -m coverage run --branch --source . -m unittest discover
    fi

    if [[ "${mode}" == "json" ]]; then run python -m coverage json -o "${out}"
    elif [[ "${mode}" == "xml" ]]; then run python -m coverage xml -o "${out}"
    else run python -m coverage lcov -o "${out}"
    fi

}
coverage_node () {

    ensure_pkg node npm
    source <(parse "$@" -- mode out)

    local -a cmd=( npx -y c8 )
    [[ -x node_modules/.bin/c8 ]] && cmd=( node_modules/.bin/c8 )

    cov_prepare_out "${out}"
    run "${cmd[@]}" --reporter=lcovonly --report-dir "$(dirname "${out}")" --all --exclude-after-remap npm test --silent "${kwargs[@]}"

}
coverage_php () {

    ensure_pkg php
    source <(parse "$@" -- mode out)

    local phpunit="phpunit"
    [[ -x vendor/bin/phpunit ]] && phpunit="vendor/bin/phpunit"

    cov_prepare_out "${out}"
    XDEBUG_MODE=coverage run php "${phpunit}" --coverage-clover "${out}" "${kwargs[@]}"

}

cmd_coverage () {

    source <(parse "$@" -- mode=lcov name version flags token out upload:bool)

    local lang="$(which_lang)"
    out="${out:-"${OUT_DIR:-out}/$(cov_default_out "${lang}" "${mode}")"}"

    case "${lang}" in
        rust) coverage_rust "${mode}" "${out}" "${kwargs[@]}" ;;
        go)   coverage_go   "${mode}" "${out}" "${kwargs[@]}" ;;
        py)   coverage_py   "${mode}" "${out}" "${kwargs[@]}" ;;
        node) coverage_node "${mode}" "${out}" "${kwargs[@]}" ;;
        php)  coverage_php  "${mode}" "${out}" "${kwargs[@]}" ;;
        *)    die "coverage: unknown root manager" ;;
    esac

    success "Ok: coverage processed -> ${out}"
    (( upload )) && cov_upload_out "${lang}" "${mode}" "${name}" "${version}"  "${token}" "${flags}" "${out}"

}
