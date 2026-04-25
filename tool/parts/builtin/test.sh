#!/usr/bin/env bash
# shellcheck shell=bash

set -u
set -o pipefail

ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" >/dev/null 2>&1 && pwd)"
TARGET="${1:-${ROOT}/log.sh}"

# shellcheck source=/dev/null
source "${TARGET}"

APP_NAME="gun"
APP_ENV="${APP_ENV:-production}"
BUILD_ID="${BUILD_ID:-$(date +%Y%m%d%H%M%S 2>/dev/null || printf 'local')}"
ARTIFACT_DIR="${ARTIFACT_DIR:-/tmp/gun-showcase-artifact}"

step_prepare_workspace () {

    rm -rf "${ARTIFACT_DIR}"
    mkdir -p "${ARTIFACT_DIR}/bin" "${ARTIFACT_DIR}/logs" "${ARTIFACT_DIR}/meta"

    printf 'name=%s\n' "${APP_NAME}" > "${ARTIFACT_DIR}/meta/app.env"
    printf 'env=%s\n' "${APP_ENV}" >> "${ARTIFACT_DIR}/meta/app.env"
    printf 'build_id=%s\n' "${BUILD_ID}" >> "${ARTIFACT_DIR}/meta/app.env"

    sleep 0.4

}
step_resolve_runtime () {

    command -v bash >/dev/null 2>&1
    bash --version >/dev/null 2>&1
    sleep 0.4

}
step_compile_runtime () {

    printf '#!/usr/bin/env bash\nprintf "gun runtime ready\\n"\n' > "${ARTIFACT_DIR}/bin/gun"
    chmod +x "${ARTIFACT_DIR}/bin/gun"

    sleep 0.5

}
step_static_checks () {

    bash -n "${ARTIFACT_DIR}/bin/gun"
    sleep 0.4

}
step_package_artifact () {

    tar -czf "${ARTIFACT_DIR}/gun-${BUILD_ID}.tar.gz" -C "${ARTIFACT_DIR}" bin meta >/dev/null 2>&1
    sleep 0.5

}
step_upload_artifact () {

    sleep 0.5
    printf 'uploaded=%s\n' "gun-${BUILD_ID}.tar.gz" > "${ARTIFACT_DIR}/logs/upload.log"

}
step_smoke_test () {

    "${ARTIFACT_DIR}/bin/gun" >/dev/null
    sleep 0.4

}
step_fail_example () {

    printf 'connecting to production gateway...\n'
    printf 'checking deployment token...\n'
    printf 'boom: token expired for environment %s\n' "${APP_ENV}"
    return 7

}
show_runtime_contract () {

    log::section "Runtime Contract"

    log::table 20 \
        "App" "${APP_NAME}" \
        "Environment" "${APP_ENV}" \
        "Build ID" "${BUILD_ID}" \
        "Artifact Dir" "${ARTIFACT_DIR}" \
        "Color" "$(log::supports_color && printf yes || printf no)" \
        "Unicode" "$(log::supports_unicode && printf yes || printf no)" \
        "Quiet" "$(log::is_quiet && printf yes || printf no)" \
        "Verbose" "$(log::is_verbose && printf yes || printf no)"

}
show_display_modes () {

    log::section "Display Modes"

    log::info "Default flags + bright colors"
    LOG_SYMBOLS=1 log::info "Symbols enabled"
    LOG_SYMBOLS=1 LOG_EMOJIS=1 log::warn "Emoji mode enabled"
    LOG_TIMESTAMP=1 log::step "Timestamp mode enabled"
    LOG_FLAGS=0 LOG_SYMBOLS=1 log::ok "No flags, symbol only"
    LOG_FLAGS=0 LOG_SYMBOLS=0 log::grayln "No flags, no symbols: clean raw message"
    log::no_color log::warn "No-color scoped wrapper"

}
show_pretty_output () {

    log::section "Formatted Output"

    log::subsection "Key / Value"
    log::pair "Repository" "comstrx/gun"
    log::pair "Branch" "main"
    log::pair "Target" "release"
    log::pair "Runtime" "bash"

    log::subsection "List"
    log::list \
        "deterministic output" \
        "quiet-safe rendering" \
        "failure output captured" \
        "terminal color fallback" \
        "progress and spinner support"

    log::subsection "Quoted Block"
    cat <<'TEXT' | log::quote
This block simulates external command output.
It is rendered only when you choose to show it.
Useful for failed builds, deploy logs, and diagnostics.
TEXT

    log::subsection "Indented Block"
    cat <<'TEXT' | log::indent 4
src/
  runtime/
  builtins/
target/
  release/
TEXT

}
show_spinner_pipeline () {

    log::section "Spinner Pipeline"

    log::spinner "Preparing workspace" -- step_prepare_workspace
    log::spinner "Resolving Bash runtime" -- step_resolve_runtime
    log::spinner "Compiling runtime entrypoint" -- step_compile_runtime
    log::spinner "Running static checks" -- step_static_checks
    log::spinner "Packaging artifact" -- step_package_artifact
    log::spinner "Uploading artifact" -- step_upload_artifact
    log::spinner "Running smoke test" -- step_smoke_test

}
show_progress_renderer () {

    local i=0 curr=""

    log::section "Progress Renderer"

    for i in {1..100}; do

        curr="${i}"

        if (( i > 72 )); then
            curr="done"
        fi

        log::progress "${curr}" 100 "Building release" 38

        [[ "${curr}" == "done" ]] && break
        sleep 0.01

    done

    log::done "Progress reached final state cleanly"

}
show_failure_capture () {

    log::section "Failure Capture"

    log::spinner "Deploying to production" -- step_fail_example
    code=$?

    if (( code != 0 )); then
        log::warn "Deploy failed intentionally for showcase"
        log::pair "Captured exit code" "${code}"
    fi

}
show_run_try () {

    log::section "Command Helpers"

    log::run bash -c 'printf "hello from log::run\n"'

    if log::try bash -c 'printf "test output hidden? no, this is direct try output\n"; exit 0'; then
        log::ok "try success branch"
    fi

    log::try bash -c 'printf "simulated failure output\n"; exit 5'
    code=$?

    if (( code != 0 )); then
        log::warn "try returned code ${code}"
    fi

}
show_summary () {

    log::section "Summary"

    log::table 18 \
        "Workspace" "ready" \
        "Runtime" "resolved" \
        "Static Checks" "passed" \
        "Package" "created" \
        "Upload" "done" \
        "Deploy" "failed intentionally"

    log::hr "=" 54
    log::done "Showcase completed"

}
main () {

    log::title "Gun Production Logger Showcase"

    log::pair "Program" "showcase-log.sh"
    log::pair "Using" "${TARGET}"
    log::pair "Mode" "real CLI pipeline simulation"

    show_runtime_contract
    show_display_modes
    show_pretty_output
    show_spinner_pipeline
    show_progress_renderer
    show_failure_capture
    show_run_try
    show_summary

}

main "$@"
