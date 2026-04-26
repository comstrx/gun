#!/usr/bin/env bash
# path_brutal_test.sh
# Brutal production CI test suite for tool/parts/builtin/path.sh
#
# Usage:
#   bash path_brutal_test.sh [path/to/path.sh]
#
# Modes:
#   GUN_TEST_VERBOSE=1    print every passing assertion
#   GUN_TEST_SLOW=1       enable heavier archive/snapshot/checksum stress
#   GUN_TEST_WATCH=0      disable watch tests
#   GUN_TEST_SHELLCHECK=1 also run shellcheck on target when available
#
# This test intentionally creates, deletes, moves, copies, archives, extracts,
# chmods, hardlinks, symlinks, fifos, sockets, unicode paths, spaces, dash files,
# and path traversal cases inside a temporary sandbox.

set -u

PATH_LIB="${1:-${PATH_LIB:-tool/parts/builtin/path.sh}}"
TEST_ROOT=""
MAIN_PID="${BASHPID:-$$}"
TOTAL=0
PASS=0
FAIL=0
SKIP=0
VERBOSE="${GUN_TEST_VERBOSE:-0}"
SLOW="${GUN_TEST_SLOW:-0}"
DO_WATCH="${GUN_TEST_WATCH:-1}"
DO_SHELLCHECK="${GUN_TEST_SHELLCHECK:-0}"

# -----------------------------------------------------------------------------
# Minimal sys::* compatibility layer for standalone testing.
# Your real system.sh may be sourced before this test; these won't clobber it.
# -----------------------------------------------------------------------------

declare -F sys::has >/dev/null 2>&1 || sys::has () { command -v -- "${1:-}" >/dev/null 2>&1; }
declare -F sys::is_linux >/dev/null 2>&1 || sys::is_linux () { [[ "${OSTYPE:-}" == linux* ]]; }
declare -F sys::is_macos >/dev/null 2>&1 || sys::is_macos () { [[ "${OSTYPE:-}" == darwin* ]]; }
declare -F sys::is_windows >/dev/null 2>&1 || sys::is_windows () { [[ "${OS:-}" == Windows_NT || "${OSTYPE:-}" == msys* || "${OSTYPE:-}" == cygwin* || "${OSTYPE:-}" == win32* ]]; }
declare -F sys::is_wsl >/dev/null 2>&1 || sys::is_wsl () { [[ -n "${WSL_DISTRO_NAME:-}${WSL_INTEROP:-}" ]] && return 0; grep -qi microsoft /proc/sys/kernel/osrelease 2>/dev/null; }
declare -F sys::uhome >/dev/null 2>&1 || sys::uhome () { printf '%s\n' "${HOME:-${USERPROFILE:-}}"; }

# -----------------------------------------------------------------------------
# Harness
# -----------------------------------------------------------------------------

declare -A TESTED_FUNCS=()

cleanup () {
    [[ "${BASHPID:-$$}" == "${MAIN_PID}" ]] || return 0
    if [[ -n "${TEST_ROOT:-}" && -d "${TEST_ROOT:-}" ]]; then
        chmod -R u+rwX -- "${TEST_ROOT}" 2>/dev/null || true
        rm -rf -- "${TEST_ROOT}" 2>/dev/null || true
    fi
}
trap 'cleanup; exit 130' INT TERM

note () { printf '\n\033[1;36m[%s]\033[0m\n' "$*"; }

mark () {
    local fn="${1:-}"
    [[ -n "${fn}" ]] && TESTED_FUNCS["${fn}"]=1
}

ok () {
    TOTAL=$(( TOTAL + 1 ))
    PASS=$(( PASS + 1 ))
    [[ "${VERBOSE}" == 1 ]] && printf '  \033[32mPASS\033[0m %s\n' "$1"
    return 0
}

fail () {
    TOTAL=$(( TOTAL + 1 ))
    FAIL=$(( FAIL + 1 ))
    printf '  \033[31mFAIL\033[0m %s\n' "$1"
    return 1
}

skip () {
    TOTAL=$(( TOTAL + 1 ))
    SKIP=$(( SKIP + 1 ))
    printf '  \033[33mSKIP\033[0m %s\n' "$1"
    return 0
}

assert_true () {
    local label="$1"; shift
    if "$@"; then ok "${label}"; else fail "${label}"; fi
}

assert_false () {
    local label="$1"; shift
    if "$@"; then fail "${label}"; else ok "${label}"; fi
}

assert_eq () {
    local label="$1" expected="$2" actual="$3"
    if [[ "${actual}" == "${expected}" ]]; then
        ok "${label}"
    else
        fail "${label} :: expected=[${expected}] actual=[${actual}]"
    fi
}

assert_ne () {
    local label="$1" a="$2" b="$3"
    if [[ "${a}" != "${b}" ]]; then ok "${label}"; else fail "${label} :: both=[${a}]"; fi
}

assert_match () {
    local label="$1" value="$2" regex="$3"
    if [[ "${value}" =~ ${regex} ]]; then ok "${label}"; else fail "${label} :: value=[${value}] regex=[${regex}]"; fi
}

assert_file () {
    local label="$1" p="$2"
    [[ -f "${p}" ]] && ok "${label}" || fail "${label} :: missing file ${p}"
}

assert_dir () {
    local label="$1" p="$2"
    [[ -d "${p}" ]] && ok "${label}" || fail "${label} :: missing dir ${p}"
}

assert_link () {
    local label="$1" p="$2"
    [[ -L "${p}" ]] && ok "${label}" || fail "${label} :: missing link ${p}"
}

assert_missing () {
    local label="$1" p="$2"
    [[ ! -e "${p}" && ! -L "${p}" ]] && ok "${label}" || fail "${label} :: still exists ${p}"
}

run_timeout () {
    local seconds="$1"; shift
    if command -v timeout >/dev/null 2>&1; then
        timeout "${seconds}" "$@"
    elif command -v gtimeout >/dev/null 2>&1; then
        gtimeout "${seconds}" "$@"
    else
        "$@"
    fi
}

can_exact_chmod () {
    sys::is_windows && return 1
    return 0
}

can_symlink () {
    local target="${1:-}" link="${2:-}"
    [[ -n "${target}" && -n "${link}" ]] || return 1
    ln -s "${target}" "${link}" 2>/dev/null || return 1
    [[ -L "${link}" ]] || { rm -f -- "${link}" 2>/dev/null || true; return 1; }
    rm -f -- "${link}" 2>/dev/null || true
    return 0
}

can_unix_socket () {
    sys::is_windows && return 1
    command -v python3 >/dev/null 2>&1
}

portable_sleep () {
    sleep "${1:-0.2}" 2>/dev/null || sleep 1
}

# -----------------------------------------------------------------------------
# Load target
# -----------------------------------------------------------------------------

if [[ ! -f "${PATH_LIB}" ]]; then
    printf 'Target path.sh not found: %s\n' "${PATH_LIB}" >&2
    exit 2
fi

if ! bash -n "${PATH_LIB}" 2>/dev/null; then
    printf 'Syntax check failed: %s\n' "${PATH_LIB}" >&2
    bash -n "${PATH_LIB}"
    exit 2
fi

if [[ "${DO_SHELLCHECK}" == 1 ]]; then
    if command -v shellcheck >/dev/null 2>&1; then
        shellcheck "${PATH_LIB}" -e SC2148
    else
        printf 'shellcheck unavailable; skipping static check\n' >&2
    fi
fi

# shellcheck source=/dev/null
source "${PATH_LIB}"

if ! declare -F path::valid >/dev/null 2>&1; then
    printf 'Failed to load path functions from: %s\n' "${PATH_LIB}" >&2
    exit 2
fi

TEST_ROOT="$(mktemp -d 2>/dev/null || mktemp -d -t pathbrutal)"
mkdir -p -- \
    "${TEST_ROOT}/space dir" \
    "${TEST_ROOT}/src/a/b" \
    "${TEST_ROOT}/dst" \
    "${TEST_ROOT}/archives" \
    "${TEST_ROOT}/extract" \
    "${TEST_ROOT}/dash-dir"

printf 'alpha\n' > "${TEST_ROOT}/file.txt"
printf 'beta\n' > "${TEST_ROOT}/space dir/file with spaces.txt"
printf 'gamma\n' > "${TEST_ROOT}/src/a/b/deep.txt"
printf 'hidden\n' > "${TEST_ROOT}/.hidden"
printf 'unicode\n' > "${TEST_ROOT}/unicodé-ملف.txt"
printf 'dash\n' > "${TEST_ROOT}/dash-dir/-dash-file"

unalias -a 2>/dev/null || true

note "target"
printf 'file: %s\nroot: %s\n' "${PATH_LIB}" "${TEST_ROOT}"

# -----------------------------------------------------------------------------
# Basic validation / existence
# -----------------------------------------------------------------------------

note "basic predicates"

mark path::valid
assert_true  "valid accepts normal path" path::valid "${TEST_ROOT}/file.txt"
assert_true  "valid accepts spaces" path::valid "${TEST_ROOT}/space dir/file with spaces.txt"
assert_true  "valid accepts unicode" path::valid "${TEST_ROOT}/unicodé-ملف.txt"
assert_false "valid rejects empty" path::valid ""
assert_false "valid rejects newline" path::valid $'bad\npath'
assert_false "valid rejects carriage return" path::valid $'bad\rpath'

mark path::exists
assert_true  "exists file" path::exists "${TEST_ROOT}/file.txt"
assert_true  "exists dir" path::exists "${TEST_ROOT}/src"
assert_false "exists missing" path::exists "${TEST_ROOT}/missing"

mark path::missing
assert_true  "missing true for missing" path::missing "${TEST_ROOT}/missing"
assert_false "missing false for existing" path::missing "${TEST_ROOT}/file.txt"

mark path::empty
: > "${TEST_ROOT}/empty.txt"
mkdir -p "${TEST_ROOT}/empty-dir" "${TEST_ROOT}/non-empty-dir"
printf x > "${TEST_ROOT}/non-empty-dir/x"
assert_true  "empty file" path::empty "${TEST_ROOT}/empty.txt"
assert_false "non-empty file" path::empty "${TEST_ROOT}/file.txt"
assert_true  "empty dir" path::empty "${TEST_ROOT}/empty-dir"
assert_false "non-empty dir" path::empty "${TEST_ROOT}/non-empty-dir"
assert_false "empty missing fails" path::empty "${TEST_ROOT}/missing"

mark path::filled
assert_true  "filled file" path::filled "${TEST_ROOT}/file.txt"
assert_true  "filled dir" path::filled "${TEST_ROOT}/non-empty-dir"
assert_false "filled empty file" path::filled "${TEST_ROOT}/empty.txt"
assert_false "filled missing" path::filled "${TEST_ROOT}/missing"

# -----------------------------------------------------------------------------
# Pure path semantics
# -----------------------------------------------------------------------------

note "pure path semantics"

mark path::is_abs
assert_true  "is_abs POSIX" path::is_abs "/tmp"
assert_true  "is_abs Windows drive" path::is_abs "C:/Windows"
assert_true  "is_abs backslash root" path::is_abs "\\server"
assert_false "is_abs relative" path::is_abs "foo/bar"

mark path::is_rel
assert_true  "is_rel relative" path::is_rel "foo/bar"
assert_false "is_rel absolute" path::is_rel "/foo"
assert_false "is_rel empty" path::is_rel ""

mark path::is_drive
assert_true  "is_drive C:" path::is_drive "C:/x"
assert_true  "is_drive drive-relative" path::is_drive "C:foo"
assert_false "is_drive POSIX" path::is_drive "/tmp"

mark path::slashify
assert_eq    "slashify backslashes" "C:/A/B" "$(path::slashify 'C:\A\B')"
assert_false "slashify rejects newline" path::slashify $'a\nb'

mark path::posix
assert_eq    "posix C:/Users" "/c/Users" "$(path::posix 'C:/Users')"
assert_false "posix rejects drive-relative" path::posix "C:Users"
assert_eq    "posix slashifies plain" "a/b" "$(path::posix 'a\b')"

mark path::windows
assert_eq "windows /mnt/c/Users" 'C:\Users' "$(path::windows '/mnt/c/Users')"
assert_eq "windows drive uppercases" 'C:\Users' "$(path::windows 'c:/Users')"
if sys::is_windows; then
    assert_eq "windows /c/Users on windows" 'C:\Users' "$(path::windows '/c/Users')"
else
    assert_eq "windows plain POSIX style converts" '\usr\bin' "$(path::windows '/usr/bin')"
fi

mark path::normalize
assert_eq "normalize collapses slash and dot" "/a/c" "$(path::normalize '/a//b/../c/.')"
assert_eq "normalize relative up" "../a" "$(path::normalize '../x/../a')"
assert_eq "normalize root" "/" "$(path::normalize '////')"
assert_eq "normalize drive absolute" "C:/a/c" "$(path::normalize 'C:/a/b/../c')"
assert_eq "normalize drive-relative preserves C:" "C:" "$(path::normalize 'C:foo/..')"
assert_eq "normalize UNC" "//server/share" "$(path::normalize '//server/share/dir/..')"

mark path::resolve
resolved_file="$(path::resolve "${TEST_ROOT}/src/a/../a/b/deep.txt")"
assert_match "resolve file absolute" "${resolved_file}" '^/'
assert_eq "resolve basename" "deep.txt" "$(path::basename "${resolved_file}")"

mark path::join
assert_eq "join simple" "a/b/c" "$(path::join a b c)"
assert_eq "join resets on absolute" "/x/y" "$(path::join a b /x y)"
assert_eq "join handles empty segments" "a/b" "$(path::join '' a '' b)"
assert_eq "join normalizes traversal" "a/c" "$(path::join a b .. c)"

mark path::cwd
assert_eq "cwd equals pwd logical" "$(pwd)" "$(path::cwd)"

mark path::pwd
[[ -n "$(path::pwd)" ]] && ok "pwd returns something" || fail "pwd returns something"

mark path::abs
assert_match "abs relative becomes absolute" "$(path::abs 'abc')" '^/'
assert_eq "abs absolute normalized" "/tmp/x" "$(path::abs '/tmp/a/../x')"

mark path::rel
assert_eq "rel same" "." "$(path::rel "${TEST_ROOT}/src" "${TEST_ROOT}/src")"
assert_eq "rel child" "a/b/deep.txt" "$(path::rel "${TEST_ROOT}/src/a/b/deep.txt" "${TEST_ROOT}/src")"
assert_eq "rel sibling" "../dst" "$(path::rel "${TEST_ROOT}/dst" "${TEST_ROOT}/src")"
assert_eq "rel dot path" "src/a" "$(cd "${TEST_ROOT}" && path::rel "./src/a" ".")"

mark path::expand
assert_eq "expand ~" "${HOME:-}" "$(path::expand '~')"
assert_eq "expand ~/x" "${HOME:-}/x" "$(path::expand '~/x')"
assert_eq "expand plain" "plain" "$(path::expand 'plain')"
assert_false "expand invalid user chars" path::expand '~bad:user'

mark path::parts
mapfile -t __parts < <(path::parts "/a/b/c")
assert_eq "parts count" "4" "${#__parts[@]}"
assert_eq "parts root" "/" "${__parts[0]}"
assert_eq "parts leaf" "c" "${__parts[3]}"

mark path::depth
assert_eq "depth /a/b/c" "4" "$(path::depth '/a/b/c')"
assert_eq "depth relative" "2" "$(path::depth 'a/b')"

mark path::common
assert_eq "common posix" "${TEST_ROOT}/src" "$(path::common "${TEST_ROOT}/src/a" "${TEST_ROOT}/src/b")"
assert_eq "common one arg" "$(path::abs "${TEST_ROOT}/src/a")" "$(path::common "${TEST_ROOT}/src/a")"
assert_false "common no args fails" path::common

mark path::dirname
assert_eq "dirname file" "${TEST_ROOT}" "$(path::dirname "${TEST_ROOT}/file.txt")"
assert_eq "dirname no slash" "." "$(path::dirname "file.txt")"
assert_eq "dirname root child" "/" "$(path::dirname "/file.txt")"
assert_eq "dirname drive-relative" "C:" "$(path::dirname "C:foo")"
assert_eq "dirname drive absolute" "C:/foo" "$(path::dirname "C:/foo/bar")"

mark path::basename
assert_eq "basename file" "file.txt" "$(path::basename "${TEST_ROOT}/file.txt")"
assert_eq "basename trailing slash" "src" "$(path::basename "${TEST_ROOT}/src/")"
assert_eq "basename root" "" "$(path::basename "/")"

mark path::drive
assert_eq    "drive extracts C:" "C:" "$(path::drive 'C:/x')"
assert_false "drive fails posix" path::drive "/tmp"

mark path::stem
assert_eq "stem normal" "file.tar" "$(path::stem 'file.tar.gz')"
assert_eq "stem no ext" "file" "$(path::stem 'file')"
assert_eq "stem dotfile" ".bashrc" "$(path::stem '.bashrc')"
assert_eq "stem double-dot hidden" "..hidden" "$(path::stem '..hidden')"
assert_eq "stem dotdot" ".." "$(path::stem '..')"
assert_eq "stem triple dot" "..." "$(path::stem '...')"

mark path::ext
assert_eq "ext normal" "gz" "$(path::ext 'file.tar.gz')"
assert_eq "ext none" "" "$(path::ext 'file')"
assert_eq "ext dotfile none" "" "$(path::ext '.bashrc')"
assert_eq "ext double-dot hidden none" "" "$(path::ext '..hidden')"

mark path::dotext
assert_eq "dotext normal" ".gz" "$(path::dotext 'file.tar.gz')"
assert_eq "dotext none" "" "$(path::dotext '.bashrc')"

mark path::chname
assert_eq "chname file" "${TEST_ROOT}/renamed.md" "$(path::chname "${TEST_ROOT}/file.txt" "renamed.md")"
assert_eq "chname plain" "renamed.md" "$(path::chname "file.txt" "renamed.md")"
assert_false "chname empty name fails" path::chname "${TEST_ROOT}/file.txt" ""

mark path::chstem
assert_eq "chstem file" "${TEST_ROOT}/hello.txt" "$(path::chstem "${TEST_ROOT}/file.txt" "hello")"
assert_eq "chstem no ext" "hello" "$(path::chstem "file" "hello")"
assert_false "chstem empty stem fails" path::chstem "${TEST_ROOT}/file.txt" ""

mark path::chext
assert_eq "chext file" "${TEST_ROOT}/file.md" "$(path::chext "${TEST_ROOT}/file.txt" "md")"
assert_eq "chext dot ext" "${TEST_ROOT}/file.md" "$(path::chext "${TEST_ROOT}/file.txt" ".md")"
assert_eq "chext remove ext" "${TEST_ROOT}/file" "$(path::chext "${TEST_ROOT}/file.txt" "")"

# -----------------------------------------------------------------------------
# Roots / relation / types / metadata
# -----------------------------------------------------------------------------

note "roots, relations, types, metadata"

mark path::chmod
chmod_target="${TEST_ROOT}/chmod.txt"
printf z > "${chmod_target}"
assert_true "chmod 600" path::chmod "${chmod_target}" 600
if can_exact_chmod; then
    assert_match "chmod mode applied" "$(path::mode "${chmod_target}")" '600$|0600$'
else
    skip "chmod exact mode unsupported on Windows ACL/MSYS"
fi
assert_false "chmod rejects bad mode" path::chmod "${chmod_target}" 'bad-mode'

mark path::is_root
assert_true  "is_root slash" path::is_root "/"
assert_true  "is_root drive" path::is_root "C:/"
assert_false "is_root non-root" path::is_root "/tmp"
assert_false "is_root empty" path::is_root ""

mark path::is_unc
assert_true  "is_unc POSIX double slash" path::is_unc "//server/share"
assert_true  "is_unc Windows double backslash" path::is_unc "\\\\server\\share"
assert_false "is_unc normal" path::is_unc "/tmp"

mark path::is_same
assert_true  "is_same self" path::is_same "${TEST_ROOT}/file.txt" "${TEST_ROOT}/file.txt"
assert_false "is_same different" path::is_same "${TEST_ROOT}/file.txt" "${TEST_ROOT}/empty.txt"

mark path::is_under
assert_true  "is_under child" path::is_under "${TEST_ROOT}/src/a" "${TEST_ROOT}/src"
assert_false "is_under same" path::is_under "${TEST_ROOT}/src" "${TEST_ROOT}/src"
assert_false "is_under sibling" path::is_under "${TEST_ROOT}/dst" "${TEST_ROOT}/src"
assert_false "is_under parent root refused" path::is_under "${TEST_ROOT}" "/"

mark path::is_parent
assert_true  "is_parent parent" path::is_parent "${TEST_ROOT}/src" "${TEST_ROOT}/src/a"
assert_false "is_parent sibling" path::is_parent "${TEST_ROOT}/src" "${TEST_ROOT}/dst"

mark path::is_file
assert_true  "is_file" path::is_file "${TEST_ROOT}/file.txt"
assert_false "is_file dir" path::is_file "${TEST_ROOT}/src"

mark path::is_dir
assert_true  "is_dir" path::is_dir "${TEST_ROOT}/src"
assert_false "is_dir file" path::is_dir "${TEST_ROOT}/file.txt"

mark path::is_link
if can_symlink "${TEST_ROOT}/file.txt" "${TEST_ROOT}/link-file.probe"; then
    if path::symlink "${TEST_ROOT}/file.txt" "${TEST_ROOT}/link-file" && [[ -L "${TEST_ROOT}/link-file" ]]; then
        assert_true "is_link" path::is_link "${TEST_ROOT}/link-file"
    else
        skip "is_link symlink creation unavailable through path::symlink"
    fi
else
    skip "is_link symlink unavailable on this OS/session"
fi

mark path::is_pipe
if command -v mkfifo >/dev/null 2>&1 && mkfifo "${TEST_ROOT}/fifo" 2>/dev/null; then
    assert_true "is_pipe fifo" path::is_pipe "${TEST_ROOT}/fifo"
else
    skip "is_pipe mkfifo unavailable"
fi

mark path::is_socket
if can_unix_socket; then
    if python3 - "${TEST_ROOT}/sock" <<'PY' >/dev/null 2>&1
import os, socket, sys
p = sys.argv[1]
try:
    os.unlink(p)
except FileNotFoundError:
    pass
s = socket.socket(socket.AF_UNIX, socket.SOCK_STREAM)
s.bind(p)
s.close()
PY
    then
        assert_true "is_socket unix socket" path::is_socket "${TEST_ROOT}/sock"
    else
        skip "is_socket unix socket creation unavailable"
    fi
else
    skip "is_socket unix socket unsupported"
fi

mark path::is_block
if [[ -b /dev/sda ]]; then assert_true "is_block /dev/sda" path::is_block /dev/sda
else assert_false "is_block regular file" path::is_block "${TEST_ROOT}/file.txt"
fi

mark path::is_char
if [[ -c /dev/null ]]; then assert_true "is_char /dev/null" path::is_char /dev/null; else skip "is_char no /dev/null char"; fi

mark path::readable
assert_true "readable file" path::readable "${TEST_ROOT}/file.txt"

mark path::writable
assert_true "writable file" path::writable "${TEST_ROOT}/file.txt"

mark path::executable
printf '#!/usr/bin/env bash\nexit 0\n' > "${TEST_ROOT}/run.sh"
chmod +x "${TEST_ROOT}/run.sh"
assert_true  "executable file" path::executable "${TEST_ROOT}/run.sh"
assert_false "non executable file" path::executable "${TEST_ROOT}/file.txt"

mark path::type
assert_eq "type file" "file" "$(path::type "${TEST_ROOT}/file.txt")"
assert_eq "type dir" "dir" "$(path::type "${TEST_ROOT}/src")"
[[ -L "${TEST_ROOT}/link-file" ]] && assert_eq "type link" "link" "$(path::type "${TEST_ROOT}/link-file")"

mark path::size
assert_match "size file numeric" "$(path::size "${TEST_ROOT}/file.txt")" '^[0-9]+$'
assert_match "size dir numeric" "$(path::size "${TEST_ROOT}/src")" '^[0-9]+$'

mark path::mtime
assert_match "mtime numeric" "$(path::mtime "${TEST_ROOT}/file.txt")" '^[0-9]+$'

mark path::atime
assert_match "atime numeric" "$(path::atime "${TEST_ROOT}/file.txt")" '^[0-9]+$'

mark path::ctime
assert_match "ctime numeric" "$(path::ctime "${TEST_ROOT}/file.txt")" '^[0-9]+$'

mark path::age
assert_match "age numeric" "$(path::age "${TEST_ROOT}/file.txt")" '^[0-9]+$'

mark path::owner
[[ -n "$(path::owner "${TEST_ROOT}/file.txt")" ]] && ok "owner non-empty" || fail "owner non-empty"

mark path::group
[[ -n "$(path::group "${TEST_ROOT}/file.txt")" ]] && ok "group non-empty" || fail "group non-empty"

mark path::mode
assert_match "mode octal" "$(path::mode "${TEST_ROOT}/file.txt")" '^[0-7]{3,4}$'

mark path::inode
assert_match "inode numeric" "$(path::inode "${TEST_ROOT}/file.txt")" '^[0-9]+$'

mark path::which
assert_true  "which bash" path::which bash
assert_false "which missing" path::which "definitely-not-a-real-command-xyz"
assert_false "which newline rejected" path::which $'bash\nls'

mark path::which_all
which_all_bash="$(path::which_all bash || true)"
if [[ -n "${which_all_bash}" ]]; then ok "which_all bash returns entries"; else fail "which_all bash returned empty"; fi

mark path::root
assert_eq    "root empty defaults slash" "/" "$(path::root '')"
assert_eq    "root posix" "/" "$(path::root '/a/b')"
assert_eq    "root drive" "C:/" "$(path::root 'C:/a/b')"
assert_eq    "root unc" "//server/" "$(path::root '//server/share/x')"
assert_false "root relative fails" path::root "a/b"

mark path::script
[[ -n "$(path::script "${PATH_LIB}")" ]] && ok "script target resolves" || fail "script target resolves"

mark path::script_dir
assert_eq "script_dir target dir" "$(path::dirname "$(path::abs "${PATH_LIB}")")" "$(path::script_dir "${PATH_LIB}")"

# -----------------------------------------------------------------------------
# Standard directories
# -----------------------------------------------------------------------------

note "standard directories"

for fn in home_dir tmp_dir config_dir data_dir cache_dir state_dir runtime_dir log_dir bin_dir desktop_dir downloads_dir documents_dir pictures_dir music_dir videos_dir public_dir templates_dir; do
    mark "path::${fn}"
    value="$("path::${fn}" 2>/dev/null || true)"
    if [[ -n "${value}" ]]; then ok "${fn} returns non-empty: ${value}"; else fail "${fn} returned empty/failure"; fi
done

# -----------------------------------------------------------------------------
# Mutations and destructive safety
# -----------------------------------------------------------------------------

note "filesystem mutations and safety"

mark path::remove
printf x > "${TEST_ROOT}/remove-me.txt"
assert_true "remove file" path::remove "${TEST_ROOT}/remove-me.txt"
assert_missing "remove deleted file" "${TEST_ROOT}/remove-me.txt"
mkdir -p "${TEST_ROOT}/remove-dir/a"
assert_true "remove dir" path::remove "${TEST_ROOT}/remove-dir"
assert_missing "remove deleted dir" "${TEST_ROOT}/remove-dir"
assert_false "remove refuses root" path::remove "/"
if can_symlink "/" "${TEST_ROOT}/link-to-root"; then
    ln -s "/" "${TEST_ROOT}/link-to-root" 2>/dev/null || true
    assert_false "remove refuses symlink resolving to root" path::remove "${TEST_ROOT}/link-to-root"
    assert_link "root symlink remains after refused remove" "${TEST_ROOT}/link-to-root"
    rm -f -- "${TEST_ROOT}/link-to-root"
else
    skip "remove symlink-to-root safety unavailable"
fi

mark path::clear
mkdir -p "${TEST_ROOT}/clear-dir/sub"
printf x > "${TEST_ROOT}/clear-dir/sub/x"
printf y > "${TEST_ROOT}/clear-dir/.hidden"
assert_true "clear dir" path::clear "${TEST_ROOT}/clear-dir"
assert_true "clear dir empty after" path::empty "${TEST_ROOT}/clear-dir"
printf x > "${TEST_ROOT}/clear-file.txt"
assert_true "clear file" path::clear "${TEST_ROOT}/clear-file.txt"
assert_true "clear file empty after" path::empty "${TEST_ROOT}/clear-file.txt"
assert_false "clear refuses root" path::clear "/"
if can_symlink "${TEST_ROOT}/file.txt" "${TEST_ROOT}/clear-link"; then
    ln -s "${TEST_ROOT}/file.txt" "${TEST_ROOT}/clear-link" 2>/dev/null || true
    before_clear_link="$(cat "${TEST_ROOT}/file.txt")"
    assert_false "clear refuses symlink to file" path::clear "${TEST_ROOT}/clear-link"
    after_clear_link="$(cat "${TEST_ROOT}/file.txt")"
    assert_eq "clear symlink target untouched" "${before_clear_link}" "${after_clear_link}"
else
    skip "clear symlink safety unavailable"
fi
if can_symlink "/" "${TEST_ROOT}/clear-link-root"; then
    ln -s "/" "${TEST_ROOT}/clear-link-root" 2>/dev/null || true
    assert_false "clear refuses symlink to root" path::clear "${TEST_ROOT}/clear-link-root"
    rm -f -- "${TEST_ROOT}/clear-link-root"
else
    skip "clear symlink-to-root safety unavailable"
fi

mark path::rename
printf x > "${TEST_ROOT}/old-name.txt"
assert_true "rename file" path::rename "${TEST_ROOT}/old-name.txt" "${TEST_ROOT}/new-name.txt"
assert_file "rename destination exists" "${TEST_ROOT}/new-name.txt"
assert_missing "rename source gone" "${TEST_ROOT}/old-name.txt"

mark path::move
printf x > "${TEST_ROOT}/move-old.txt"
assert_true "move alias" path::move "${TEST_ROOT}/move-old.txt" "${TEST_ROOT}/move-new.txt"
assert_file "move destination exists" "${TEST_ROOT}/move-new.txt"

mark path::copy
printf copy > "${TEST_ROOT}/copy-src.txt"
assert_true "copy file" path::copy "${TEST_ROOT}/copy-src.txt" "${TEST_ROOT}/copy-dst.txt"
assert_eq "copy file content" "copy" "$(cat "${TEST_ROOT}/copy-dst.txt")"
mkdir -p "${TEST_ROOT}/copy-src-dir/n"
printf deep > "${TEST_ROOT}/copy-src-dir/n/deep.txt"
assert_true "copy dir" path::copy "${TEST_ROOT}/copy-src-dir" "${TEST_ROOT}/copy-dst-dir"
assert_file "copy dir deep file" "${TEST_ROOT}/copy-dst-dir/n/deep.txt"
assert_true "copy dash file" path::copy "${TEST_ROOT}/dash-dir/-dash-file" "${TEST_ROOT}/dash-dir/-dash-copy"
assert_file "copy dash destination" "${TEST_ROOT}/dash-dir/-dash-copy"

mark path::link
if ln "${TEST_ROOT}/file.txt" "${TEST_ROOT}/hardlink-manual" 2>/dev/null; then
    rm -f -- "${TEST_ROOT}/hardlink-manual"
    assert_true "hard link" path::link "${TEST_ROOT}/file.txt" "${TEST_ROOT}/hardlink"
    assert_true "hard link same inode" path::is_same "${TEST_ROOT}/file.txt" "${TEST_ROOT}/hardlink"
else
    skip "hard link unsupported"
fi

mark path::symlink
if can_symlink "${TEST_ROOT}/file.txt" "${TEST_ROOT}/symlink-manual"; then
    if path::symlink "${TEST_ROOT}/file.txt" "${TEST_ROOT}/symlink" && [[ -L "${TEST_ROOT}/symlink" ]]; then
        ok "symlink"
        assert_true "symlink is link" path::is_link "${TEST_ROOT}/symlink"
    else
        skip "symlink requires privileges/developer mode"
    fi
else
    skip "symlink unsupported"
fi

mark path::readlink
if [[ -L "${TEST_ROOT}/symlink" ]]; then
    assert_eq "readlink symlink" "${TEST_ROOT}/file.txt" "$(path::readlink "${TEST_ROOT}/symlink")"
else
    skip "readlink no symlink"
fi

mark path::touch
assert_true "touch nested file" path::touch "${TEST_ROOT}/touch/a/b/t.txt"
assert_file "touch created file" "${TEST_ROOT}/touch/a/b/t.txt"
assert_true "touch dash file" path::touch "${TEST_ROOT}/dash-dir/-touched"
assert_file "touch dash file exists" "${TEST_ROOT}/dash-dir/-touched"

mark path::mkdir
assert_true "mkdir nested dir" path::mkdir "${TEST_ROOT}/made/a/b"
assert_dir "mkdir created nested" "${TEST_ROOT}/made/a/b"
assert_false "mkdir refuses existing file" path::mkdir "${TEST_ROOT}/file.txt"
if can_exact_chmod; then
    assert_true "mkdir with mode" path::mkdir "${TEST_ROOT}/mode-dir" 700
    assert_match "mkdir mode applied" "$(path::mode "${TEST_ROOT}/mode-dir")" '700$|0700$'
else
    skip "mkdir mode exact unsupported on Windows ACL/MSYS"
fi

mark path::mkparent
assert_true "mkparent creates parent" path::mkparent "${TEST_ROOT}/parent/a/b/file.txt"
assert_dir "mkparent parent exists" "${TEST_ROOT}/parent/a/b"

mark path::mktemp
tmp_file="$(path::mktemp brutal .tmp)"
assert_file "mktemp creates file" "${tmp_file}"
assert_match "mktemp suffix" "${tmp_file}" '\.tmp$'
rm -f -- "${tmp_file}"

mark path::mktemp_dir
tmp_dir="$(path::mktemp_dir brutal)"
assert_dir "mktemp_dir creates dir" "${tmp_dir}"
rmdir -- "${tmp_dir}" 2>/dev/null || true

# -----------------------------------------------------------------------------
# Snapshot / checksum
# -----------------------------------------------------------------------------

note "checksum and snapshot"

mark path::checksum
checksum_file="$(path::checksum "${TEST_ROOT}/file.txt" sha256 2>/dev/null || true)"
assert_match "checksum file sha256" "${checksum_file}" '^[0-9a-fA-F]{64}$'
checksum_md5="$(path::checksum "${TEST_ROOT}/file.txt" md5 2>/dev/null || true)"
if [[ -n "${checksum_md5}" ]]; then assert_match "checksum file md5" "${checksum_md5}" '^[0-9a-fA-F]{32}$'; else skip "checksum md5 tool unavailable"; fi
checksum_dir_1="$(path::checksum "${TEST_ROOT}/src" sha256 2>/dev/null || true)"
checksum_dir_2="$(path::checksum "${TEST_ROOT}/src" sha256 2>/dev/null || true)"
assert_match "checksum dir sha256" "${checksum_dir_1}" '^[0-9a-fA-F]{64}$'
assert_eq "checksum dir deterministic same run" "${checksum_dir_1}" "${checksum_dir_2}"
assert_false "checksum rejects bad algo" path::checksum "${TEST_ROOT}/file.txt" nope

mark path::snapshot
snapshot_file="$(path::snapshot "${TEST_ROOT}/file.txt" 2>/dev/null || true)"
assert_match "snapshot file line" "${snapshot_file}" '^file	[0-9]+	[0-9]+	[0-7]+	-	'
snapshot_dir="$(path::snapshot "${TEST_ROOT}/src" 2>/dev/null || true)"
if [[ "${snapshot_dir}" == *$'file\t'*"deep.txt"* ]]; then ok "snapshot dir includes deep file"; else fail "snapshot dir missing deep file"; fi
if [[ -L "${TEST_ROOT}/symlink" ]]; then
    snapshot_link="$(path::snapshot "${TEST_ROOT}/symlink" 2>/dev/null || true)"
    assert_match "snapshot link line" "${snapshot_link}" '^link	-	-	-	'
else
    skip "snapshot symlink unavailable"
fi

# -----------------------------------------------------------------------------
# Archive / extract / backup / strip / sync
# -----------------------------------------------------------------------------

note "archive extract backup strip sync"

mark path::strip
strip_root="${TEST_ROOT}/strip-root"
mkdir -p "${strip_root}/outer/inner"
printf stripped > "${strip_root}/outer/inner/file.txt"
if sys::has tar; then
    assert_true "strip dir one component" path::strip "${strip_root}" 1
    assert_file "strip removes first real component" "${strip_root}/inner/file.txt"
else
    skip "strip requires tar"
fi
assert_false "strip rejects file target" path::strip "${TEST_ROOT}/file.txt" 1
assert_false "strip rejects root" path::strip "/" 1
assert_false "strip rejects non numeric" path::strip "${TEST_ROOT}/src" bad

mark path::archive
archive_src="${TEST_ROOT}/archive-src"
mkdir -p "${archive_src}/top/nested" "${archive_src}/skip"
printf keep > "${archive_src}/top/nested/keep.txt"
printf skip > "${archive_src}/skip/skip.txt"
tar_out="${TEST_ROOT}/archives/archive.tar.gz"
if sys::has tar; then
    archive_print="$(path::archive "${archive_src}" "${tar_out}" --exclude='skip/*' 2>/dev/null || true)"
    [[ -f "${tar_out}" ]] && ok "archive tar.gz output exists" || fail "archive tar.gz output missing"
    assert_eq "archive prints output path" "${tar_out}" "${archive_print}"
else
    skip "archive tar.gz requires tar"
fi
zip_out="${TEST_ROOT}/archives/archive.zip"
if sys::has zip || sys::has 7z; then
    assert_true "archive zip" path::archive "${archive_src}" "${zip_out}" --format=zip
    assert_file "archive zip exists" "${zip_out}"
else
    skip "archive zip requires zip or 7z"
fi
assert_false "archive rejects bad format" path::archive "${archive_src}" "${TEST_ROOT}/bad.out" --format=nope

mark path::extract
if [[ -f "${tar_out}" ]]; then
    extract_to="${TEST_ROOT}/extract/tar"
    extract_print="$(path::extract "${tar_out}" "${extract_to}" 2>/dev/null || true)"
    assert_eq "extract tar.gz prints target" "${extract_to}" "${extract_print}"
    assert_file "extract tar.gz content" "${extract_to}/archive-src/top/nested/keep.txt"
    assert_missing "extract excluded file absent" "${extract_to}/archive-src/skip/skip.txt"

    extract_strip="${TEST_ROOT}/extract/tar-strip"
    assert_true "extract tar.gz --strip=1" path::extract "${tar_out}" "${extract_strip}" --strip=1
    assert_file "extract strip content" "${extract_strip}/top/nested/keep.txt"
else
    skip "extract tar.gz no tar archive"
fi
if [[ -f "${zip_out}" ]]; then
    extract_zip="${TEST_ROOT}/extract/zip"
    assert_true "extract zip" path::extract "${zip_out}" "${extract_zip}"
    assert_file "extract zip content" "${extract_zip}/archive-src/top/nested/keep.txt"
else
    skip "extract zip no zip archive"
fi
assert_false "extract rejects bad strip" path::extract "${tar_out:-/missing}" "${TEST_ROOT}/bad-strip" --strip=bad

mark path::backup
if sys::has tar; then
    explicit_backup="${TEST_ROOT}/archives/explicit-backup.tar.gz"
    backup_print="$(path::backup "${archive_src}" "${explicit_backup}" 2>/dev/null || true)"
    assert_eq "backup prints archive path" "${explicit_backup}" "${backup_print}"
    assert_file "backup explicit exists" "${explicit_backup}"
else
    skip "backup requires tar"
fi

mark path::sync
mkdir -p "${TEST_ROOT}/sync-src/a" "${TEST_ROOT}/sync-dst/old"
printf sync > "${TEST_ROOT}/sync-src/a/file.txt"
printf old > "${TEST_ROOT}/sync-dst/old/file.txt"
assert_true "sync dir" path::sync "${TEST_ROOT}/sync-src" "${TEST_ROOT}/sync-dst"
assert_file "sync copied file" "${TEST_ROOT}/sync-dst/a/file.txt"
assert_missing "sync removed old destination tree" "${TEST_ROOT}/sync-dst/old/file.txt"
printf one > "${TEST_ROOT}/sync-file-src.txt"
assert_true "sync file" path::sync "${TEST_ROOT}/sync-file-src.txt" "${TEST_ROOT}/sync-file-dst.txt"
assert_file "sync file copied" "${TEST_ROOT}/sync-file-dst.txt"
assert_eq "sync file content" "one" "$(cat "${TEST_ROOT}/sync-file-dst.txt")"
assert_false "sync refuses root target" path::sync "${TEST_ROOT}/sync-src" "/"

# -----------------------------------------------------------------------------
# Watch
# -----------------------------------------------------------------------------

note "watch"

mark path::watch
if [[ "${DO_WATCH}" != 1 ]]; then
    skip "watch disabled by GUN_TEST_WATCH=0"
else
    watch_file="${TEST_ROOT}/watch.txt"
    printf before > "${watch_file}"
    (
        if sys::is_windows; then portable_sleep 1; else portable_sleep 0.35; fi
        printf after >> "${watch_file}"
    ) &
    watcher_mod_pid=$!

    if run_timeout 12 bash -c '
        set -u
        declare -F sys::has >/dev/null 2>&1 || sys::has () { command -v -- "${1:-}" >/dev/null 2>&1; }
        declare -F sys::is_linux >/dev/null 2>&1 || sys::is_linux () { [[ "${OSTYPE:-}" == linux* ]]; }
        declare -F sys::is_macos >/dev/null 2>&1 || sys::is_macos () { [[ "${OSTYPE:-}" == darwin* ]]; }
        declare -F sys::is_windows >/dev/null 2>&1 || sys::is_windows () { [[ "${OS:-}" == Windows_NT || "${OSTYPE:-}" == msys* || "${OSTYPE:-}" == cygwin* || "${OSTYPE:-}" == win32* ]]; }
        declare -F sys::is_wsl >/dev/null 2>&1 || sys::is_wsl () { [[ -n "${WSL_DISTRO_NAME:-}${WSL_INTEROP:-}" ]]; }
        declare -F sys::uhome >/dev/null 2>&1 || sys::uhome () { printf "%s\n" "${HOME:-${USERPROFILE:-}}"; }
        source "$1"
        path::watch "$2" 0.1 "" once >/dev/null
    ' _ "${PATH_LIB}" "${watch_file}"; then
        ok "watch file once detects modification"
    else
        fail "watch file once detects modification"
    fi
    wait "${watcher_mod_pid}" 2>/dev/null || true

    watch_dir="${TEST_ROOT}/watch-dir"
    mkdir -p "${watch_dir}"
    (
        if sys::is_windows; then portable_sleep 1; else portable_sleep 0.35; fi
        printf created > "${watch_dir}/created.txt"
    ) &
    watcher_dir_pid=$!

    if run_timeout 12 bash -c '
        set -u
        declare -F sys::has >/dev/null 2>&1 || sys::has () { command -v -- "${1:-}" >/dev/null 2>&1; }
        declare -F sys::is_linux >/dev/null 2>&1 || sys::is_linux () { [[ "${OSTYPE:-}" == linux* ]]; }
        declare -F sys::is_macos >/dev/null 2>&1 || sys::is_macos () { [[ "${OSTYPE:-}" == darwin* ]]; }
        declare -F sys::is_windows >/dev/null 2>&1 || sys::is_windows () { [[ "${OS:-}" == Windows_NT || "${OSTYPE:-}" == msys* || "${OSTYPE:-}" == cygwin* || "${OSTYPE:-}" == win32* ]]; }
        declare -F sys::is_wsl >/dev/null 2>&1 || sys::is_wsl () { [[ -n "${WSL_DISTRO_NAME:-}${WSL_INTEROP:-}" ]]; }
        declare -F sys::uhome >/dev/null 2>&1 || sys::uhome () { printf "%s\n" "${HOME:-${USERPROFILE:-}}"; }
        source "$1"
        path::watch "$2" 0.1 "" once >/dev/null
    ' _ "${PATH_LIB}" "${watch_dir}"; then
        ok "watch dir once detects create"
    else
        fail "watch dir once detects create"
    fi
    wait "${watcher_dir_pid}" 2>/dev/null || true

    callback_file="${TEST_ROOT}/watch-callback.count"
    callback_script="${TEST_ROOT}/watch-callback.sh"
    cat > "${callback_script}" <<CB
#!/usr/bin/env bash
printf x >> "${callback_file}"
CB
    chmod +x "${callback_script}"
    printf before > "${watch_file}"
    (
        if sys::is_windows; then portable_sleep 1; else portable_sleep 0.35; fi
        printf again >> "${watch_file}"
    ) &
    watcher_cb_pid=$!

    if run_timeout 12 bash -c '
        set -u
        declare -F sys::has >/dev/null 2>&1 || sys::has () { command -v -- "${1:-}" >/dev/null 2>&1; }
        declare -F sys::is_linux >/dev/null 2>&1 || sys::is_linux () { [[ "${OSTYPE:-}" == linux* ]]; }
        declare -F sys::is_macos >/dev/null 2>&1 || sys::is_macos () { [[ "${OSTYPE:-}" == darwin* ]]; }
        declare -F sys::is_windows >/dev/null 2>&1 || sys::is_windows () { [[ "${OS:-}" == Windows_NT || "${OSTYPE:-}" == msys* || "${OSTYPE:-}" == cygwin* || "${OSTYPE:-}" == win32* ]]; }
        declare -F sys::is_wsl >/dev/null 2>&1 || sys::is_wsl () { [[ -n "${WSL_DISTRO_NAME:-}${WSL_INTEROP:-}" ]]; }
        declare -F sys::uhome >/dev/null 2>&1 || sys::uhome () { printf "%s\n" "${HOME:-${USERPROFILE:-}}"; }
        source "$1"
        path::watch "$2" 0.1 "$3" once >/dev/null
    ' _ "${PATH_LIB}" "${watch_file}" "${callback_script}"; then
        [[ -s "${callback_file}" ]] && ok "watch callback fires" || fail "watch callback did not write"
    else
        fail "watch callback run"
    fi
    wait "${watcher_cb_pid}" 2>/dev/null || true
fi

# -----------------------------------------------------------------------------
# Optional slow stress
# -----------------------------------------------------------------------------

if [[ "${SLOW}" == 1 ]]; then
    note "slow stress"

    stress_dir="${TEST_ROOT}/stress"
    mkdir -p "${stress_dir}"
    for i in $(seq 1 600); do
        mkdir -p "${stress_dir}/d$(( i % 31 ))"
        printf '%s\n' "${i}" > "${stress_dir}/d$(( i % 31 ))/file-${i}.txt"
    done

    assert_true "slow common many" path::common "${stress_dir}/d1/file-1.txt" "${stress_dir}/d1/file-32.txt"

    stress_sum_1="$(path::checksum "${stress_dir}" sha256 2>/dev/null || true)"
    stress_sum_2="$(path::checksum "${stress_dir}" sha256 2>/dev/null || true)"
    assert_match "slow checksum 600 files" "${stress_sum_1}" '^[0-9a-fA-F]{64}$'
    assert_eq "slow checksum deterministic" "${stress_sum_1}" "${stress_sum_2}"

    snap_count="$(path::snapshot "${stress_dir}" 2>/dev/null | wc -l | tr -d '[:space:]')"
    assert_match "slow snapshot count numeric" "${snap_count}" '^[0-9]+$'

    if sys::has tar; then
        stress_archive="${TEST_ROOT}/archives/stress.tar.gz"
        assert_true "slow archive 600 files" path::archive "${stress_dir}" "${stress_archive}"
        assert_true "slow extract 600 files" path::extract "${stress_archive}" "${TEST_ROOT}/extract/stress"
        assert_file "slow extract sample" "${TEST_ROOT}/extract/stress/stress/d1/file-1.txt"
    fi
fi

# -----------------------------------------------------------------------------
# Coverage gate: every path::* function from target must be marked.
# -----------------------------------------------------------------------------

note "coverage gate"

mapfile -t ALL_FUNCS < <(declare -F | awk '{print $3}' | grep '^path::' | sort)
missing=()

for fn in "${ALL_FUNCS[@]}"; do
    [[ -n "${TESTED_FUNCS[${fn}]:-}" ]] || missing+=( "${fn}" )
done

if (( ${#missing[@]} == 0 )); then
    ok "all ${#ALL_FUNCS[@]} path::* functions covered"
else
    fail "missing coverage: ${missing[*]}"
fi

# Expected exact count for the current API generation.
# If you intentionally add/remove functions, update EXPECTED_FUNC_COUNT.
EXPECTED_FUNC_COUNT="${GUN_EXPECTED_PATH_FUNCS:-100}"
if [[ "${#ALL_FUNCS[@]}" == "${EXPECTED_FUNC_COUNT}" ]]; then
    ok "expected function count ${EXPECTED_FUNC_COUNT}"
else
    fail "expected ${EXPECTED_FUNC_COUNT} path::* functions, found ${#ALL_FUNCS[@]}"
fi

# -----------------------------------------------------------------------------
# Summary
# -----------------------------------------------------------------------------

printf '\n'
printf '============================================================\n'
printf ' path.sh brutal test summary\n'
printf '============================================================\n'
printf 'Target : %s\n' "${PATH_LIB}"
printf 'Root   : %s\n' "${TEST_ROOT}"
printf 'Total  : %s\n' "${TOTAL}"
printf 'Pass   : %s\n' "${PASS}"
printf 'Fail   : %s\n' "${FAIL}"
printf 'Skip   : %s\n' "${SKIP}"
printf 'Funcs  : %s/%s covered\n' "$(( ${#ALL_FUNCS[@]} - ${#missing[@]} ))" "${#ALL_FUNCS[@]}"
printf '============================================================\n'

if [[ "${GUN_TEST_KEEP_ROOT:-0}" != 1 ]]; then
    cleanup
fi

if (( FAIL > 0 )); then
    exit 1
fi

exit 0
