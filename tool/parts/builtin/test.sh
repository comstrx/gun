#!/usr/bin/env bash
set -Eeuo pipefail

ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" >/dev/null 2>&1 && pwd)"
SYS_FILE="${ROOT}/system.sh"
USER_FILE="${ROOT}/user.sh"
MODE_FILE="${ROOT}/mode.sh"

[[ -f "${SYS_FILE}"  ]] && source "${SYS_FILE}"
[[ -f "${USER_FILE}" ]] && source "${USER_FILE}"
[[ -f "${MODE_FILE}" ]] && source "${MODE_FILE}"

pass=0
fail=0

ok () {

    printf '[OK]   %s\n' "$1"
    pass=$(( pass + 1 ))

}

bad () {

    printf '[FAIL] %s\n' "$1"
    fail=$(( fail + 1 ))

}

test_case () {

    local name="$1"
    shift

    if "$@"; then ok "${name}"
    else bad "${name}"
    fi

}

same_mode () {

    local path="$1" want="$2" got=""

    got="$(mode::get "${path}" 2>/dev/null || true)"
    [[ "${got}" == "${want}" ]]

}

TMP="${TMPDIR:-/tmp}/mode_test_$$"
FILE="${TMP}/file.txt"
EXEC="${TMP}/run.sh"
DIR="${TMP}/dir"

cleanup () {

    rm -rf "${TMP}" >/dev/null 2>&1 || true

}

trap cleanup EXIT

mkdir -p "${TMP}"

printf 'hello\n' > "${FILE}"
printf '#!/usr/bin/env bash\nprintf "ok\\n"\n' > "${EXEC}"
mkdir -p "${DIR}"

printf '%s\n' "------------------------------------------------------------"
printf '%s\n' "[TEST] mode.sh"
printf '%s\n' "------------------------------------------------------------"
printf 'Runtime : %s\n' "$(sys::runtime 2>/dev/null || printf unknown)"
printf 'OS      : %s\n' "$(sys::name 2>/dev/null || printf unknown)"
printf 'User    : %s\n' "$(sys::uname 2>/dev/null || printf unknown)"
printf 'TMP     : %s\n' "${TMP}"
printf '%s\n' "------------------------------------------------------------"

test_case "mode::get file"        mode::get "${FILE}"
test_case "mode::set 600"         mode::set "${FILE}" 600
test_case "mode is 600"           same_mode "${FILE}" 600

test_case "mode::set 644"         mode::set "${FILE}" 644
test_case "mode is 644"           same_mode "${FILE}" 644

test_case "mode::read u"          mode::read "${FILE}" u
test_case "mode::write u"         mode::write "${FILE}" u
test_case "mode::readable"        mode::readable "${FILE}"
test_case "mode::writable"        mode::writable "${FILE}"

test_case "mode::exec u"          mode::exec "${EXEC}" u
test_case "mode::executable"      mode::executable "${EXEC}"

test_case "mode::private file"    mode::private "${FILE}"
test_case "private file is 600"   same_mode "${FILE}" 600

test_case "mode::public file"     mode::public "${FILE}"
test_case "public file is 644"    same_mode "${FILE}" 644

test_case "mode::private dir"     mode::private "${DIR}"
test_case "private dir is 700"    same_mode "${DIR}" 700

test_case "mode::public dir"      mode::public "${DIR}"
test_case "public dir is 755"     same_mode "${DIR}" 755

test_case "mode::lock file"       mode::lock "${FILE}" u
test_case "file not writable"     bash -c '[[ ! -w "$1" ]]' _ "${FILE}"

test_case "mode::unlock file"     mode::unlock "${FILE}" u
test_case "file writable again"   mode::writable "${FILE}"

test_case "mode::owner get"       mode::owner "${FILE}"
test_case "mode::group get"       mode::group "${FILE}"
test_case "mode::owned current"   mode::owned "${FILE}"

cp "${FILE}" "${TMP}/same.txt"
mode::set "${TMP}/same.txt" "$(mode::get "${FILE}")"
test_case "mode::same"            mode::same "${FILE}" "${TMP}/same.txt"

test_case "mode::info"            mode::info "${FILE}"

printf '%s\n' "------------------------------------------------------------"
printf 'Passed: %s\n' "${pass}"
printf 'Failed: %s\n' "${fail}"
printf '%s\n' "------------------------------------------------------------"

if (( fail > 0 )); then
    exit 1
fi

exit 0
