#!/usr/bin/env bash
set -Eeuo pipefail

ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" >/dev/null 2>&1 && pwd)"

source "${ROOT}/system.sh"
source "${ROOT}/process.sh"

pass=0
fail=0
skip=0

ok () { printf '[OK]   %s\n' "$1"; pass=$(( pass + 1 )); }
bad () { printf '[FAIL] %s\n' "$1"; fail=$(( fail + 1 )); }
skip_case () { printf '[SKIP] %s\n' "$1"; skip=$(( skip + 1 )); }

run_case () {

    local name="$1"
    shift

    if "$@"; then ok "${name}"
    else bad "${name}"
    fi

}

not_case () {

    local name="$1"
    shift

    if "$@"; then bad "${name}"
    else ok "${name}"
    fi

}

eq_case () {

    local name="$1" got="$2" want="$3"

    if [[ "${got}" == "${want}" ]]; then ok "${name}"
    else
        printf '[FAIL] %s | got=%q want=%q\n' "${name}" "${got}" "${want}"
        fail=$(( fail + 1 ))
    fi

}

contains_case () {

    local name="$1" got="$2" want="$3"

    if [[ "${got}" == *"${want}"* ]]; then ok "${name}"
    else
        printf '[FAIL] %s | missing=%q got=%q\n' "${name}" "${want}" "${got}"
        fail=$(( fail + 1 ))
    fi

}

TMP="${TMPDIR:-/tmp}/proc_hard_test_$$"
BIN_DIR="${TMP}/bin"
LOG="${TMP}/log.txt"

cleanup () {

    rm -rf "${TMP}" >/dev/null 2>&1 || true

}

trap cleanup EXIT

mkdir -p "${BIN_DIR}"
: > "${LOG}"

cat > "${BIN_DIR}/fakever" <<'SH'
#!/usr/bin/env bash
case "${1:-}" in
    --version) printf 'fakever version 1.2.3-alpha+001\n' ;;
    -v)        printf 'fakever v9.9.9\n' ;;
    -V)        printf 'fakever 8.8.8\n' ;;
    version)   printf 'fakever 7.7.7\n' ;;
    *)         printf 'fakever run\n' ;;
esac
SH

cat > "${BIN_DIR}/fakebadver" <<'SH'
#!/usr/bin/env bash
case "${1:-}" in
    --version|-v|-V|version) printf 'no version here\n' ;;
    *) printf 'ok\n' ;;
esac
SH

cat > "${BIN_DIR}/fakecmd" <<'SH'
#!/usr/bin/env bash
printf 'fakecmd:%s\n' "$*"
SH

cat > "${BIN_DIR}/fakefail" <<'SH'
#!/usr/bin/env bash
exit 42
SH

chmod +x "${BIN_DIR}/fakever" "${BIN_DIR}/fakebadver" "${BIN_DIR}/fakecmd" "${BIN_DIR}/fakefail"
export PATH="${BIN_DIR}:${PATH}"

printf '%s\n' "------------------------------------------------------------"
printf '%s\n' "[HARD TEST] process.sh"
printf '%s\n' "------------------------------------------------------------"
printf 'Runtime : %s\n' "$(sys::runtime 2>/dev/null || printf unknown)"
printf 'OS      : %s\n' "$(sys::name 2>/dev/null || printf unknown)"
printf 'Manager : %s\n' "$(sys::manager 2>/dev/null || printf unknown)"
printf 'TMP     : %s\n' "${TMP}"
printf '%s\n' "------------------------------------------------------------"

run_case "proc::has bash" proc::has bash
run_case "proc::has fakecmd" proc::has fakecmd
not_case "proc::has missing" proc::has "definitely_missing_command_zzzz"

run_case "proc::has_any hit" proc::has_any "missing_1" fakecmd "missing_2"
not_case "proc::has_any miss" proc::has_any "missing_1" "missing_2"

run_case "proc::has_all hit" proc::has_all bash fakecmd
not_case "proc::has_all miss" proc::has_all bash "missing_zzzz"

run_case "proc::need bash" proc::need bash
run_case "proc::need_any hit" proc::need_any "missing_x" bash
run_case "proc::need_all hit" proc::need_all bash fakecmd

run_case "proc::run true" proc::run true
not_case "proc::run false" proc::run false

run_case "proc::run_ok true" proc::run_ok true
not_case "proc::run_ok false" proc::run_ok false

tmp_out="${TMP}/run_out.txt"
proc::run fakecmd hello > "${tmp_out}" 2>/dev/null && grep -qx "fakecmd:hello" "${tmp_out}" \
    && ok "proc::run fakecmd" || bad "proc::run fakecmd"

run_case "proc::run_all one" proc::run_all "printf one >> '${LOG}'"
contains_case "run_all wrote one" "$(cat "${LOG}")" "one"

run_case "proc::run_all multiple" proc::run_all "printf two >> '${LOG}'" "printf three >> '${LOG}'"
contains_case "run_all wrote two" "$(cat "${LOG}")" "two"
contains_case "run_all wrote three" "$(cat "${LOG}")" "three"

not_case "proc::run_all fail" proc::run_all "true" "false" "printf never >> '${LOG}'"

run_case "proc::run_all_ok true" proc::run_all_ok "true" "printf hidden"
not_case "proc::run_all_ok fail" proc::run_all_ok "true" "false"

path_fake="$(proc::path fakecmd 2>/dev/null || true)"
[[ -n "${path_fake}" ]] && ok "proc::path fakecmd" || bad "proc::path fakecmd"
[[ "${path_fake}" == *"fakecmd"* ]] && ok "proc::path contains fakecmd" || bad "proc::path contains fakecmd"

path_direct="$(proc::path "${BIN_DIR}/fakecmd" 2>/dev/null || true)"
[[ -n "${path_direct}" ]] && ok "proc::path direct" || bad "proc::path direct"

not_case "proc::path missing" proc::path "definitely_missing_command_zzzz"

ver="$(proc::version fakever 2>/dev/null || true)"
eq_case "proc::version normalized" "${ver}" "1.2.3-alpha.001"

not_case "proc::version no version" proc::version fakebadver
not_case "proc::version missing" proc::version "definitely_missing_command_zzzz"

manager="$(sys::manager 2>/dev/null || true)"
if [[ -n "${manager}" && "${manager}" != "unknown" ]]; then
    run_case "proc::refresh_ok callable" proc::refresh_ok
else
    skip_case "proc::refresh_ok callable"
fi

run_case "proc::install existing no version" proc::install fakecmd fakecmd "" 0 0
run_case "proc::ensure existing no version" proc::ensure fakecmd fakecmd "" 0 0

run_case "proc::install_all existing" proc::install_all "fakecmd:fakecmd::0:0" "bash:bash::0:0"
run_case "proc::ensure_all existing" proc::ensure_all "fakecmd:fakecmd::0:0"

printf '%s\n' "------------------------------------------------------------"
printf 'Passed: %s\n' "${pass}"
printf 'Failed: %s\n' "${fail}"
printf 'Skipped: %s\n' "${skip}"
printf '%s\n' "------------------------------------------------------------"

(( fail == 0 ))
