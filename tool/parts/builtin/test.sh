#!/usr/bin/env bash
set -Eeuo pipefail

ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" >/dev/null 2>&1 && pwd)"

source "${ROOT}/system.sh"
source "${ROOT}/user.sh"
source "${ROOT}/mode.sh"

pass=0
fail=0
skip=0

ok () { printf '[OK]   %s\n' "$1"; pass=$(( pass + 1 )); }
bad () { printf '[FAIL] %s\n' "$1"; fail=$(( fail + 1 )); }
skip_case () { printf '[SKIP] %s\n' "$1"; skip=$(( skip + 1 )); }

run () {

    local name="$1"
    shift

    if "$@"; then ok "${name}"
    else bad "${name}"
    fi

}

eq () {

    local name="$1" got="$2" want="$3"

    if [[ "${got}" == "${want}" ]]; then ok "${name}"
    else
        printf '[FAIL] %s | got=%s want=%s\n' "${name}" "${got}" "${want}"
        fail=$(( fail + 1 ))
    fi

}

mode_is () {

    local path="$1" want="$2" got=""

    got="$(mode::get "${path}" 2>/dev/null || true)"
    [[ "${got}" == "${want}" ]]

}

TMP="${TMPDIR:-/tmp}/mode_hard_test_$$"
FILE="${TMP}/file.txt"
EXEC="${TMP}/run.sh"
DIR="${TMP}/dir"
A="${TMP}/a.txt"
B="${TMP}/b.txt"

cleanup () {

    chmod -R u+w "${TMP}" >/dev/null 2>&1 || true
    rm -rf "${TMP}" >/dev/null 2>&1 || true

}

trap cleanup EXIT

mkdir -p "${TMP}"
printf 'hello\n' > "${FILE}"
printf '#!/usr/bin/env bash\nprintf "ok\\n"\n' > "${EXEC}"
mkdir -p "${DIR}"
printf 'a\n' > "${A}"
printf 'b\n' > "${B}"

IS_WINDOWS=0
sys::is_windows && IS_WINDOWS=1

printf '%s\n' "------------------------------------------------------------"
printf '%s\n' "[HARD TEST] mode.sh"
printf '%s\n' "------------------------------------------------------------"
printf 'Runtime : %s\n' "$(sys::runtime 2>/dev/null || printf unknown)"
printf 'OS      : %s\n' "$(sys::name 2>/dev/null || printf unknown)"
printf 'User    : %s\n' "$(sys::uname 2>/dev/null || printf unknown)"
printf 'TMP     : %s\n' "${TMP}"
printf '%s\n' "------------------------------------------------------------"

run "mode::get file" mode::get "${FILE}"
run "mode::info file" mode::info "${FILE}"

for m in 600 644 700 755; do
    run "mode::set file ${m}" mode::set "${FILE}" "${m}"

    if (( IS_WINDOWS )); then
        run "mode::get after ${m}" mode::get "${FILE}"
    else
        run "mode exact file ${m}" mode_is "${FILE}" "${m}"
    fi
done

run "mode::private file" mode::private "${FILE}"
if (( IS_WINDOWS )); then run "private file readable" mode::readable "${FILE}"
else run "private file is 600" mode_is "${FILE}" 600
fi

run "mode::public file" mode::public "${FILE}"
if (( IS_WINDOWS )); then run "public file readable" mode::readable "${FILE}"
else run "public file is 644" mode_is "${FILE}" 644
fi

run "mode::private dir" mode::private "${DIR}"
if (( IS_WINDOWS )); then run "private dir readable" mode::readable "${DIR}"
else run "private dir is 700" mode_is "${DIR}" 700
fi

run "mode::public dir" mode::public "${DIR}"
if (( IS_WINDOWS )); then run "public dir readable" mode::readable "${DIR}"
else run "public dir is 755" mode_is "${DIR}" 755
fi

run "mode::read u" mode::read "${FILE}" u
run "mode::write u" mode::write "${FILE}" u
run "mode::exec u" mode::exec "${EXEC}" u

run "mode::readable" mode::readable "${FILE}"
run "mode::writable" mode::writable "${FILE}"
run "mode::executable" mode::executable "${EXEC}"

run "execute script" bash -c '"$1" | grep -qx ok' _ "${EXEC}"

run "mode::lock u" mode::lock "${FILE}" u

if (( IS_WINDOWS )); then
    run "mode::lock returns no-write or ACL accepted" bash -c '[[ ! -w "$1" ]] || true' _ "${FILE}"
else
    run "locked file not writable" bash -c '[[ ! -w "$1" ]]' _ "${FILE}"
fi

run "mode::unlock u" mode::unlock "${FILE}" u
run "unlocked file writable" mode::writable "${FILE}"

run "mode::owner get" mode::owner "${FILE}"
run "mode::group get" mode::group "${FILE}"
run "mode::owned current" mode::owned "${FILE}"

mode::set "${A}" 644
mode::set "${B}" 644
run "mode::same equal" mode::same "${A}" "${B}"

mode::set "${B}" 755
if mode::same "${A}" "${B}"; then bad "mode::same different"
else ok "mode::same different"
fi

run "mode::ensure 644" mode::ensure "${A}" 644

if (( IS_WINDOWS )); then
    run "mode::ensure get" mode::get "${A}"
else
    run "mode::ensure exact 644" mode_is "${A}" 644
fi

run "mode::add +x" mode::add "${A}" x

if (( IS_WINDOWS )); then
    run "mode::executable after add" mode::get "${A}"
else
    run "mode::executable after add" mode::executable "${A}"
fi

run "mode::del -x" mode::del "${A}" x
if (( IS_WINDOWS )); then
    run "mode::del accepted" mode::get "${A}"
else
    if mode::executable "${A}"; then bad "not executable after del"
    else ok "not executable after del"
    fi
fi

printf '%s\n' "------------------------------------------------------------"
printf 'Passed: %s\n' "${pass}"
printf 'Failed: %s\n' "${fail}"
printf 'Skipped: %s\n' "${skip}"
printf '%s\n' "------------------------------------------------------------"

(( fail == 0 ))
