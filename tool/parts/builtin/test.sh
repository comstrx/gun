#!/usr/bin/env bash
# shellcheck shell=bash

set -u

TEST_FILE="${1:-tool/parts/builtin/path.sh}"

if [[ ! -f "${TEST_FILE}" ]]; then
    printf '[FAIL] path.sh not found: %s\n' "${TEST_FILE}" >&2
    exit 1
fi

if ! declare -F sys::is_linux >/dev/null 2>&1; then
sys::is_linux () { [[ "$(uname -s 2>/dev/null)" == "Linux" ]]; }
fi
if ! declare -F sys::is_macos >/dev/null 2>&1; then
sys::is_macos () { [[ "$(uname -s 2>/dev/null)" == "Darwin" ]]; }
fi
if ! declare -F sys::is_wsl >/dev/null 2>&1; then
sys::is_wsl () {
    [[ -n "${WSL_DISTRO_NAME:-}" || -n "${WSL_INTEROP:-}" ]] && return 0
    [[ -r /proc/sys/kernel/osrelease ]] && grep -qi microsoft /proc/sys/kernel/osrelease 2>/dev/null
}
fi
if ! declare -F sys::is_windows >/dev/null 2>&1; then
sys::is_windows () {
    case "$(uname -s 2>/dev/null)" in
        MINGW*|MSYS*|CYGWIN*) return 0 ;;
    esac
    [[ -n "${OS:-}" && "${OS}" == "Windows_NT" ]]
}
fi
if ! declare -F sys::uhome >/dev/null 2>&1; then
sys::uhome () {
    [[ -n "${HOME:-}" ]] && { printf '%s\n' "${HOME}"; return 0; }
    [[ -n "${USERPROFILE:-}" ]] && { printf '%s\n' "${USERPROFILE}"; return 0; }
    return 1
}
fi

# shellcheck source=/dev/null
source "${TEST_FILE}"

TOTAL=0
PASS=0
FAIL=0
SKIP=0

ROOT=""
OLDPWD_TEST="$(pwd 2>/dev/null || printf '.')"

say () {
    printf '%s\n' "$*"
}

ok () {
    TOTAL=$(( TOTAL + 1 ))
    PASS=$(( PASS + 1 ))
    printf '[ OK ] %s\n' "$*"
}

bad () {
    TOTAL=$(( TOTAL + 1 ))
    FAIL=$(( FAIL + 1 ))
    printf '[FAIL] %s\n' "$*" >&2
}

skip () {
    TOTAL=$(( TOTAL + 1 ))
    SKIP=$(( SKIP + 1 ))
    printf '[SKIP] %s\n' "$*"
}

expect_ok () {

    local name="${1:-}" ; shift || true

    if "$@" >/dev/null 2>&1; then ok "${name}"
    else bad "${name}"
    fi

}
expect_fail () {

    local name="${1:-}" ; shift || true

    if "$@" >/dev/null 2>&1; then bad "${name}"
    else ok "${name}"
    fi

}
expect_eq () {

    local name="${1:-}" want="${2-}" got="${3-}"

    if [[ "${got}" == "${want}" ]]; then ok "${name}"
    else
        bad "${name} | want=[${want}] got=[${got}]"
    fi

}
expect_ne () {

    local name="${1:-}" a="${2-}" b="${3-}"

    if [[ "${a}" != "${b}" ]]; then ok "${name}"
    else bad "${name} | both=[${a}]"
    fi

}
expect_match () {

    local name="${1:-}" got="${2-}" re="${3-}"

    if [[ "${got}" =~ ${re} ]]; then ok "${name}"
    else bad "${name} | got=[${got}] regex=[${re}]"
    fi

}
capture () {
    "$@" 2>/dev/null
}

cleanup () {
    local code=$?

    cd "${OLDPWD_TEST}" >/dev/null 2>&1 || true

    if [[ -n "${ROOT}" && -d "${ROOT}" ]]; then
        rm -rf -- "${ROOT}" 2>/dev/null || true
    fi

    if (( FAIL > 0 )); then
        printf '\n[RESULT] FAIL | total=%s pass=%s fail=%s skip=%s\n' "${TOTAL}" "${PASS}" "${FAIL}" "${SKIP}" >&2
        exit 1
    fi

    printf '\n[RESULT] PASS | total=%s pass=%s fail=%s skip=%s\n' "${TOTAL}" "${PASS}" "${FAIL}" "${SKIP}"
    exit "${code}"
}
trap cleanup EXIT INT TERM

make_root () {

    if command -v mktemp >/dev/null 2>&1; then
        ROOT="$(mktemp -d 2>/dev/null || mktemp -d -t path-test.XXXXXXXX 2>/dev/null || true)"
    fi

    if [[ -z "${ROOT}" ]]; then
        ROOT="/tmp/path-test.$$.$RANDOM$RANDOM"
        mkdir -p -- "${ROOT}" || exit 1
    fi

    mkdir -p -- "${ROOT}/a/b/c" "${ROOT}/empty-dir" "${ROOT}/non-empty-dir" "${ROOT}/space dir"
    printf 'hello\n' > "${ROOT}/a/file.txt"
    printf 'payload' > "${ROOT}/a/b/c/app.tar.gz"
    printf 'x' > "${ROOT}/non-empty-dir/item"
    : > "${ROOT}/zero"
    printf 'abc' > "${ROOT}/small"

}

section () {
    printf '\n---- %s ----\n' "$*"
}

make_root

section "syntax / function presence"

expect_ok "bash -n path.sh" bash -n "${TEST_FILE}"

for fn in \
    path::has path::valid path::exists path::missing path::empty path::filled \
    path::is_abs path::is_rel path::is_root path::is_unc path::has_drive \
    path::slashify path::posix path::win path::join path::norm path::resolve \
    path::cwd path::pwd path::drive path::abs path::rel path::expand \
    path::parts path::depth path::common path::dirname path::basename \
    path::stem path::ext path::dotext path::chext path::chname path::chstem \
    path::is_same path::is_under path::is_parent path::is_file path::is_dir \
    path::is_link path::is_pipe path::is_socket path::is_block path::is_char \
    path::readable path::writable path::executable path::type path::size \
    path::mtime path::atime path::ctime path::age path::owner path::group \
    path::mode path::inode path::touch path::remove path::rename path::move \
    path::copy path::link path::symlink path::readlink path::root path::script \
    path::script_dir path::home_dir path::tmp_dir path::config_dir path::data_dir \
    path::cache_dir path::state_dir path::runtime_dir path::log_dir path::bin_dir \
    path::desktop_dir path::downloads_dir path::documents_dir path::pictures_dir \
    path::music_dir path::videos_dir path::public_dir path::templates_dir \
    path::mktemp path::mktemp_dir path::which path::which_all
do
    if declare -F "${fn}" >/dev/null 2>&1; then ok "function exists: ${fn}"
    else bad "missing function: ${fn}"
    fi
done

section "valid / exists / missing / empty / filled"

expect_ok   "valid normal" path::valid "abc"
expect_fail "valid empty" path::valid ""
expect_fail "valid newline" path::valid $'a\nb'
expect_fail "valid carriage-return" path::valid $'a\rb'

expect_ok   "exists file" path::exists "${ROOT}/a/file.txt"
expect_ok   "exists dir" path::exists "${ROOT}/a"
expect_fail "exists missing" path::exists "${ROOT}/missing"
expect_ok   "missing true" path::missing "${ROOT}/missing"
expect_fail "missing false" path::missing "${ROOT}/a/file.txt"

expect_ok   "empty file zero" path::empty "${ROOT}/zero"
expect_fail "empty file filled" path::empty "${ROOT}/small"
expect_ok   "empty dir empty" path::empty "${ROOT}/empty-dir"
expect_fail "empty dir filled" path::empty "${ROOT}/non-empty-dir"
expect_ok   "filled file" path::filled "${ROOT}/small"
expect_fail "filled zero" path::filled "${ROOT}/zero"

section "absolute / relative / roots / drive / UNC"

expect_ok   "is_abs /" path::is_abs "/x"
expect_ok   "is_abs backslash root" path::is_abs "\\x"
expect_ok   "is_abs win drive slash" path::is_abs "C:/x"
expect_ok   "is_abs win drive backslash" path::is_abs "C:\\x"
expect_fail "is_abs rel" path::is_abs "a/b"

expect_ok   "is_rel rel" path::is_rel "a/b"
expect_fail "is_rel abs" path::is_rel "/a/b"

expect_ok   "is_root /" path::is_root "/"
expect_ok   "is_root backslash" path::is_root "\\"
expect_ok   "is_root C:" path::is_root "C:"
expect_ok   "is_root C:/" path::is_root "C:/"
expect_fail "is_root C:/x" path::is_root "C:/x"

expect_ok   "is_unc //server" path::is_unc "//server/share"
expect_ok   "is_unc \\\\server" path::is_unc "\\\\server\\share"
expect_fail "is_unc normal" path::is_unc "/normal"

expect_ok   "has_drive C:" path::has_drive "C:/x"
expect_fail "has_drive posix" path::has_drive "/x"

expect_eq "drive C:/x" "C:" "$(capture path::drive "C:/x")"
expect_fail "drive posix fail" path::drive "/x"

section "slashify / posix / win"

expect_eq "slashify windows" "C:/Users/Core/file.txt" "$(capture path::slashify 'C:\Users\Core\file.txt')"
expect_eq "slashify posix unchanged" "/a/b" "$(capture path::slashify "/a/b")"

posix_c="$(capture path::posix 'C:\Users\Core\a.txt')"
expect_match "posix drive conversion" "${posix_c}" '^/(mnt/c|c)/Users/Core/a\.txt$'

win_mnt="$(capture path::win "/mnt/c/Users/Core/a.txt")"
expect_eq "win /mnt/c conversion" 'C:\Users\Core\a.txt' "${win_mnt}"

win_c="$(capture path::win "/c/Users/Core/a.txt")"
expect_eq "win /c conversion" 'C:\Users\Core\a.txt' "${win_c}"

expect_eq "win already drive" 'C:\Users\Core\a.txt' "$(capture path::win "C:/Users/Core/a.txt")"

section "norm / join"

expect_eq "norm dot" "." "$(capture path::norm ".")"
expect_eq "norm simple" "a/b/c" "$(capture path::norm "a//b/./c")"
expect_eq "norm parent relative" "a/c" "$(capture path::norm "a/b/../c")"
expect_eq "norm above relative" "../a" "$(capture path::norm "../a")"
expect_eq "norm abs parent" "/a/c" "$(capture path::norm "/a/b/../c")"
expect_eq "norm root parent clamp" "/" "$(capture path::norm "/..")"
expect_eq "norm win drive" "C:/a/c" "$(capture path::norm "C:\\a\\b\\..\\c")"
expect_eq "norm trailing empty root-ish" "/" "$(capture path::norm "///")"

expect_eq "join simple" "a/b/c" "$(capture path::join "a" "b" "c")"
expect_eq "join trims duplicate" "a/b/c" "$(capture path::join "a/" "b" "c")"
expect_eq "join absolute resets" "/x/y" "$(capture path::join "/a/b" "/x" "y")"
expect_eq "join empty segments" "a/b" "$(capture path::join "" "a" "" "b")"
expect_fail "join no args" path::join

section "cwd / pwd / abs / resolve / rel"

cd "${ROOT}" || exit 1

expect_eq "cwd" "${ROOT}" "$(capture path::cwd)"
expect_eq "pwd physical" "$(pwd -P)" "$(capture path::pwd)"

expect_eq "abs relative" "${ROOT}/a/file.txt" "$(capture path::abs "a/file.txt")"
expect_eq "abs absolute norm" "${ROOT}/a/file.txt" "$(capture path::abs "${ROOT}/a/./file.txt")"

resolved_dir="$(capture path::resolve "${ROOT}/a")"
resolved_file="$(capture path::resolve "${ROOT}/a/file.txt")"

if sys::is_windows; then
    expect_match "resolve existing dir" "${resolved_dir}" '/a$'
    expect_match "resolve existing file parent" "${resolved_file}" '/a/file\.txt$'
else
    expect_eq "resolve existing dir" "$(cd "${ROOT}/a" && pwd -P)" "${resolved_dir}"
    expect_eq "resolve existing file parent" "$(cd "${ROOT}/a" && pwd -P)/file.txt" "${resolved_file}"
fi
expect_match "resolve missing fallback" "$(capture path::resolve "${ROOT}/missing/x")" '/missing/x$'

expect_eq "rel from root to file" "a/file.txt" "$(capture path::rel "${ROOT}/a/file.txt" "${ROOT}")"
expect_eq "rel same" "." "$(capture path::rel "${ROOT}/a" "${ROOT}/a")"
expect_eq "rel child to parent" ".." "$(capture path::rel "${ROOT}/a" "${ROOT}/a/b")"
expect_eq "rel sibling" "../file.txt" "$(capture path::rel "${ROOT}/a/file.txt" "${ROOT}/a/b")"
expect_eq "rel cross drive returns absolute" "D:/x/y" "$(capture path::rel "D:/x/y" "C:/a/b")"

section "expand"

HOME_SAVE="${HOME:-}"
export HOME="${ROOT}/home-user"
mkdir -p -- "${HOME}"

expect_eq "expand non-tilde unchanged" "abc" "$(capture path::expand "abc")"
expect_eq "expand ~" "${HOME}" "$(capture path::expand "~")"
expect_eq "expand ~/" "${HOME}/x/y" "$(capture path::expand "~/x/y")"

if path::has getent && getent passwd "$(id -un 2>/dev/null)" >/dev/null 2>&1; then
    user_name="$(id -un)"
    user_home="$(getent passwd "${user_name}" | awk -F: 'NR==1 {print $6}')"
    expect_eq "expand ~user" "${user_home}" "$(capture path::expand "~${user_name}")"
else
    skip "expand ~user requires getent user"
fi

if [[ -n "${HOME_SAVE}" ]]; then export HOME="${HOME_SAVE}"; else unset HOME; fi

section "parts / depth / common"

parts_out="$(capture path::parts "/a/b/c")"
expect_eq "parts /a/b/c" $'/\na\nb\nc' "${parts_out}"

parts_win="$(capture path::parts "C:/a/b")"
expect_eq "parts C:/a/b" $'C:/\na\nb' "${parts_win}"

expect_eq "depth /a/b/c" "4" "$(capture path::depth "/a/b/c")"
expect_eq "depth a/b" "2" "$(capture path::depth "a/b")"

expect_eq "common same tree" "${ROOT}/a" "$(capture path::common "${ROOT}/a/b/c" "${ROOT}/a/file.txt")"
expect_eq "common root fallback" "/" "$(capture path::common "/x/a" "/y/b")"

section "dirname / basename / stem / ext / dotext / change name"

expect_eq "dirname file" "a/b" "$(capture path::dirname "a/b/c.txt")"
expect_eq "dirname no slash" "." "$(capture path::dirname "file.txt")"
expect_eq "dirname root child" "/" "$(capture path::dirname "/x")"
expect_eq "dirname trailing slash" "a/b" "$(capture path::dirname "a/b/")"

expect_eq "basename file" "c.txt" "$(capture path::basename "a/b/c.txt")"
expect_eq "basename slash" "b" "$(capture path::basename "a/b/")"
expect_eq "basename root" "" "$(capture path::basename "/")"

expect_eq "stem normal" "main" "$(capture path::stem "main.sh")"
expect_eq "stem tar gz" "app.tar" "$(capture path::stem "app.tar.gz")"
expect_eq "stem dotfile" ".env" "$(capture path::stem ".env")"
expect_eq "stem dotted dotfile" ".env" "$(capture path::stem ".env.local")"
expect_eq "ext dotted dotfile" "local" "$(capture path::ext ".env.local")"
expect_eq "dotext dotted dotfile" ".local" "$(capture path::dotext ".env.local")"

expect_eq "ext normal" "sh" "$(capture path::ext "main.sh")"
expect_eq "ext tar gz" "gz" "$(capture path::ext "app.tar.gz")"
expect_eq "ext dotfile empty" "" "$(capture path::ext ".env")"
expect_eq "dotext normal" ".sh" "$(capture path::dotext "main.sh")"
expect_eq "dotext none" "" "$(capture path::dotext "Makefile")"

expect_eq "chext add dot" "src/app.js" "$(capture path::chext "src/app.ts" "js")"
expect_eq "chext with dot" "src/app.js" "$(capture path::chext "src/app.ts" ".js")"
expect_eq "chext remove" "src/app" "$(capture path::chext "src/app.ts" "")"
expect_eq "chname" "src/main.ts" "$(capture path::chname "src/app.ts" "main.ts")"
expect_eq "chstem" "src/main.ts" "$(capture path::chstem "src/app.ts" "main")"

section "relationship / type predicates"

expect_ok   "is_file" path::is_file "${ROOT}/a/file.txt"
expect_fail "is_file dir" path::is_file "${ROOT}/a"

expect_ok   "is_dir" path::is_dir "${ROOT}/a"
expect_fail "is_dir file" path::is_dir "${ROOT}/a/file.txt"

expect_ok   "is_under child" path::is_under "${ROOT}/a/b" "${ROOT}/a"
expect_fail "is_under same false" path::is_under "${ROOT}/a" "${ROOT}/a"
expect_ok   "is_parent" path::is_parent "${ROOT}/a" "${ROOT}/a/b"

expect_ok "readable file" path::readable "${ROOT}/a/file.txt"
expect_ok "writable file" path::writable "${ROOT}/a/file.txt"

chmod +x "${ROOT}/small" 2>/dev/null || true
if [[ -x "${ROOT}/small" ]]; then expect_ok "executable file" path::executable "${ROOT}/small"
else skip "chmod +x unsupported"
fi

expect_eq "type file" "file" "$(capture path::type "${ROOT}/a/file.txt")"
expect_eq "type dir" "dir" "$(capture path::type "${ROOT}/a")"

if command -v mkfifo >/dev/null 2>&1; then
    mkfifo "${ROOT}/pipe" 2>/dev/null || true
    if [[ -p "${ROOT}/pipe" ]]; then
        expect_ok "is_pipe" path::is_pipe "${ROOT}/pipe"
        expect_eq "type pipe" "pipe" "$(capture path::type "${ROOT}/pipe")"
    else
        skip "mkfifo failed"
    fi
else
    skip "mkfifo unavailable"
fi

if [[ -c /dev/null ]]; then
    expect_ok "is_char /dev/null" path::is_char /dev/null
    expect_eq "type char" "char" "$(capture path::type /dev/null)"
else
    skip "char device unavailable"
fi

block_dev=""
for dev in /dev/sda /dev/vda /dev/nvme0n1 /dev/disk0; do
    [[ -b "${dev}" ]] && { block_dev="${dev}"; break; }
done
if [[ -n "${block_dev}" ]]; then expect_ok "is_block ${block_dev}" path::is_block "${block_dev}"
else skip "block device unavailable"
fi

section "metadata"

expect_eq "size small" "3" "$(capture path::size "${ROOT}/small")"
expect_match "size dir numeric" "$(capture path::size "${ROOT}/a")" '^[0-9]+$'

expect_match "mtime numeric" "$(capture path::mtime "${ROOT}/small")" '^[0-9]+$'
expect_match "atime numeric" "$(capture path::atime "${ROOT}/small")" '^[0-9]+$'
expect_match "ctime numeric" "$(capture path::ctime "${ROOT}/small")" '^[0-9]+$'
expect_match "age numeric" "$(capture path::age "${ROOT}/small")" '^[0-9]+$'

expect_match "owner non-empty" "$(capture path::owner "${ROOT}/small")" '.+'
expect_match "group non-empty" "$(capture path::group "${ROOT}/small")" '.+'
expect_match "mode octal" "$(capture path::mode "${ROOT}/small")" '^[0-7]{3,4}$'
expect_match "inode numeric" "$(capture path::inode "${ROOT}/small")" '^[0-9]+$'

section "touch / remove / rename / move / copy / link / symlink / readlink / same"

expect_ok "touch creates parent" path::touch "${ROOT}/new/parent/file.txt"
expect_ok "touch created file exists" path::exists "${ROOT}/new/parent/file.txt"

expect_ok "rename file" path::rename "${ROOT}/new/parent/file.txt" "${ROOT}/new/parent/renamed.txt"
expect_ok "rename target exists" path::exists "${ROOT}/new/parent/renamed.txt"
expect_fail "rename source gone" path::exists "${ROOT}/new/parent/file.txt"

expect_ok "move alias" path::move "${ROOT}/new/parent/renamed.txt" "${ROOT}/new/moved.txt"
expect_ok "move target exists" path::exists "${ROOT}/new/moved.txt"

expect_ok "copy file creates parent" path::copy "${ROOT}/small" "${ROOT}/copy/deep/small.copy"
expect_eq "copy file content size" "3" "$(capture path::size "${ROOT}/copy/deep/small.copy")"

expect_ok "copy dir" path::copy "${ROOT}/a" "${ROOT}/copy/a-copy"
expect_ok "copy dir nested file" path::exists "${ROOT}/copy/a-copy/file.txt"

expect_ok "remove file" path::remove "${ROOT}/copy/deep/small.copy"
expect_fail "removed file missing" path::exists "${ROOT}/copy/deep/small.copy"
expect_ok "remove missing no-op" path::remove "${ROOT}/no-such-file"
expect_fail "remove root guarded /" path::remove "/"

if path::has ln; then
    expect_ok "hard link" path::link "${ROOT}/small" "${ROOT}/small.hard"
    if [[ -e "${ROOT}/small.hard" ]]; then
        expect_ok "is_same hardlink" path::is_same "${ROOT}/small" "${ROOT}/small.hard"
        expect_eq "hardlink inode same" "$(capture path::inode "${ROOT}/small")" "$(capture path::inode "${ROOT}/small.hard")"
    else
        skip "hardlink not created"
    fi
else
    skip "ln unavailable for hardlink"
fi

if path::has ln || path::has cmd.exe; then
    if path::symlink "${ROOT}/small" "${ROOT}/small.sym" >/dev/null 2>&1 && [[ -L "${ROOT}/small.sym" ]]; then
        expect_ok "is_link symlink" path::is_link "${ROOT}/small.sym"
        expect_eq "type link" "link" "$(capture path::type "${ROOT}/small.sym")"
        expect_match "readlink symlink" "$(capture path::readlink "${ROOT}/small.sym")" 'small$|small$'
        expect_ok "is_same symlink target" path::is_same "${ROOT}/small" "${ROOT}/small.sym"
    else
        skip "symlink unavailable or permission denied"
    fi
else
    skip "symlink tools unavailable"
fi

section "root / script / script_dir"

expect_eq "root default" "/" "$(capture path::root)"
expect_eq "root posix" "/" "$(capture path::root "/a/b")"
expect_eq "root win" "C:/" "$(capture path::root "C:/a/b")"
expect_eq "root unc simple" "//server/" "$(capture path::root "//server/share/x")"
expect_fail "root relative fail" path::root "a/b"

script_path="$(capture path::script "${TEST_FILE}")"
expect_match "script explicit path" "${script_path}" 'path.*\.sh$|/'

script_dir="$(capture path::script_dir "${TEST_FILE}")"

if [[ -d "${script_dir}" ]]; then
    ok "script_dir is dir"
else
    bad "script_dir is dir | got=[${script_dir}] TEST_FILE=[${TEST_FILE}]"
fi

section "standard dirs"

expect_match "home_dir" "$(capture path::home_dir)" '.+'
expect_ok "tmp_dir exists" path::is_dir "$(capture path::tmp_dir)"
expect_match "config_dir non-empty" "$(capture path::config_dir)" '.+'
expect_match "data_dir non-empty" "$(capture path::data_dir)" '.+'
expect_match "cache_dir non-empty" "$(capture path::cache_dir)" '.+'
expect_match "state_dir non-empty" "$(capture path::state_dir)" '.+'
expect_match "runtime_dir non-empty" "$(capture path::runtime_dir)" '.+'
expect_match "log_dir non-empty" "$(capture path::log_dir)" '.+'
expect_match "bin_dir non-empty" "$(capture path::bin_dir)" '.+'

expect_match "desktop_dir non-empty" "$(capture path::desktop_dir)" '.+'
expect_match "downloads_dir non-empty" "$(capture path::downloads_dir)" '.+'
expect_match "documents_dir non-empty" "$(capture path::documents_dir)" '.+'
expect_match "pictures_dir non-empty" "$(capture path::pictures_dir)" '.+'
expect_match "music_dir non-empty" "$(capture path::music_dir)" '.+'
expect_match "videos_dir non-empty" "$(capture path::videos_dir)" '.+'
expect_match "public_dir non-empty" "$(capture path::public_dir)" '.+'
expect_match "templates_dir non-empty" "$(capture path::templates_dir)" '.+'

section "mktemp / mktemp_dir"

tmp_file="$(capture path::mktemp "gun-path-test" ".tmp")"
expect_ok "mktemp output exists" path::is_file "${tmp_file}"
expect_match "mktemp suffix" "${tmp_file}" '\.tmp($|\.)'

tmp_dir="$(capture path::mktemp_dir "gun-path-test-dir")"
expect_ok "mktemp_dir output exists" path::is_dir "${tmp_dir}"

rm -f -- "${tmp_file}" 2>/dev/null || true
rm -rf -- "${tmp_dir}" 2>/dev/null || true

section "which / which_all / has"

expect_ok "has bash/sh" path::has sh
expect_fail "has impossible command" path::has "definitely-not-real-command-xyz-123"

which_sh="$(capture path::which sh)"
expect_match "which sh" "${which_sh}" '.+'

which_all_sh="$(capture path::which_all sh)"
expect_match "which_all sh has output" "${which_all_sh}" '.+'

section "hostile inputs"

expect_fail "valid newline path through exists" path::exists $'bad\npath'
expect_fail "norm empty" path::norm ""
expect_fail "join empty no args already tested" path::join
expect_fail "touch empty" path::touch ""
expect_fail "copy missing source" path::copy "${ROOT}/missing" "${ROOT}/x"
expect_fail "rename missing source" path::rename "${ROOT}/missing" "${ROOT}/x"
expect_fail "symlink empty source" path::symlink "" "${ROOT}/x"
expect_fail "readlink non-link" path::readlink "${ROOT}/small"
expect_fail "type missing" path::type "${ROOT}/missing"

section "roundtrip sanity"

joined="$(capture path::join "${ROOT}" "a" "b" ".." "file.txt")"
expect_eq "join+norm roundtrip" "${ROOT}/a/file.txt" "${joined}"

abs_rel="$(capture path::rel "$(capture path::abs "a/file.txt")" "${ROOT}")"
expect_eq "abs+rel roundtrip" "a/file.txt" "${abs_rel}"

changed="$(capture path::chstem "$(capture path::chext "${ROOT}/a/file.txt" "log")" "server")"
expect_eq "chext+chstem" "${ROOT}/a/server.log" "${changed}"

say ""
say "All path.sh tests executed."
