#!/usr/bin/env bash
# path_brutal_test.sh
# Brutal production test suite for path.sh
#
# Modes:
#   GUN_TEST_SLOW=1       enable slower archive/watch stress cases
#   GUN_TEST_WATCH=0      disable watch tests
#   GUN_TEST_VERBOSE=1    print each assertion

set -u

PATH_LIB="${1:-${PATH_LIB:-tool/parts/builtin/path.sh}}"
TEST_ROOT=""
TOTAL=0
PASS=0
FAIL=0
SKIP=0
CURRENT=""
VERBOSE="${GUN_TEST_VERBOSE:-0}"
SLOW="${GUN_TEST_SLOW:-0}"
DO_WATCH="${GUN_TEST_WATCH:-1}"

# -----------------------------------------------------------------------------
# Minimal sys::* compatibility layer for standalone testing.
# If your real system.sh is already sourced before this file, these won't clobber it.
# -----------------------------------------------------------------------------

declare -F sys::has >/dev/null 2>&1 || sys::has () { command -v -- "${1:-}" >/dev/null 2>&1; }
declare -F sys::is_linux >/dev/null 2>&1 || sys::is_linux () { [[ "${OSTYPE:-}" == linux* ]]; }
declare -F sys::is_macos >/dev/null 2>&1 || sys::is_macos () { [[ "${OSTYPE:-}" == darwin* ]]; }
declare -F sys::is_windows >/dev/null 2>&1 || sys::is_windows () { [[ "${OS:-}" == Windows_NT || "${OSTYPE:-}" == msys* || "${OSTYPE:-}" == cygwin* || "${OSTYPE:-}" == win32* ]]; }
declare -F sys::is_wsl >/dev/null 2>&1 || sys::is_wsl () { [[ -n "${WSL_DISTRO_NAME:-}${WSL_INTEROP:-}" ]] && return 0; grep -qi microsoft /proc/sys/kernel/osrelease 2>/dev/null; }
declare -F sys::uhome >/dev/null 2>&1 || sys::uhome () { printf '%s\n' "${HOME:-}"; }

# -----------------------------------------------------------------------------
# Harness
# -----------------------------------------------------------------------------

cleanup () {
    [[ -n "${TEST_ROOT:-}" && -d "${TEST_ROOT:-}" ]] && rm -rf -- "${TEST_ROOT}" 2>/dev/null || true
}
trap cleanup EXIT INT TERM

note () { printf '\n\033[1;36m[%s]\033[0m\n' "$*"; }
mark () { TESTED_FUNCS["$1"]=1; }

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

assert_match () {
    local label="$1" value="$2" regex="$3"
    if [[ "${value}" =~ ${regex} ]]; then ok "${label}"; else fail "${label} :: value=[${value}] regex=[${regex}]"; fi
}

assert_file () { local label="$1" p="$2"; [[ -f "${p}" ]] && ok "${label}" || fail "${label} :: missing file ${p}"; }
assert_dir () { local label="$1" p="$2"; [[ -d "${p}" ]] && ok "${label}" || fail "${label} :: missing dir ${p}"; }
assert_missing () { local label="$1" p="$2"; [[ ! -e "${p}" && ! -L "${p}" ]] && ok "${label}" || fail "${label} :: still exists ${p}"; }

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

# -----------------------------------------------------------------------------
# Load target
# -----------------------------------------------------------------------------

if [[ ! -f "${PATH_LIB}" ]]; then
    printf 'Target path.sh not found: %s\n' "${PATH_LIB}" >&2
    exit 2
fi

# shellcheck source=/dev/null
source "${PATH_LIB}"

if ! declare -F path::valid >/dev/null 2>&1; then
    printf 'Failed to load path functions from: %s\n' "${PATH_LIB}" >&2
    exit 2
fi

if ! bash -n "${PATH_LIB}" 2>/dev/null; then
    printf 'Syntax check failed: %s\n' "${PATH_LIB}" >&2
    bash -n "${PATH_LIB}"
    exit 2
fi

TEST_ROOT="$(mktemp -d 2>/dev/null || mktemp -d -t pathbrutal)"
mkdir -p -- "${TEST_ROOT}/space dir" "${TEST_ROOT}/src/a/b" "${TEST_ROOT}/dst" "${TEST_ROOT}/archives" "${TEST_ROOT}/extract"
printf 'alpha\n' > "${TEST_ROOT}/file.txt"
printf 'beta\n' > "${TEST_ROOT}/space dir/file with spaces.txt"
printf 'gamma\n' > "${TEST_ROOT}/src/a/b/deep.txt"
printf 'hidden\n' > "${TEST_ROOT}/.hidden"
printf 'unicode\n' > "${TEST_ROOT}/unicodé-ملف.txt"

# avoid alias/function pollution
unalias -a 2>/dev/null || true

declare -A TESTED_FUNCS=()

note "Target"
printf 'file: %s\nroot: %s\n' "${PATH_LIB}" "${TEST_ROOT}"

# -----------------------------------------------------------------------------
# Basic validation/existence predicates
# -----------------------------------------------------------------------------

note "basic predicates"
mark path::valid
assert_true  "valid accepts normal path" path::valid "${TEST_ROOT}/file.txt"
assert_false "valid rejects empty" path::valid ""
assert_false "valid rejects newline" path::valid $'bad\npath'
assert_false "valid rejects carriage return" path::valid $'bad\rpath'

mark path::exists
assert_true "exists file" path::exists "${TEST_ROOT}/file.txt"
assert_true "exists dir" path::exists "${TEST_ROOT}/src"
assert_false "exists missing" path::exists "${TEST_ROOT}/missing"

mark path::missing
assert_true "missing returns true for missing" path::missing "${TEST_ROOT}/missing"
assert_false "missing returns false for existing" path::missing "${TEST_ROOT}/file.txt"

mark path::empty
: > "${TEST_ROOT}/empty.txt"
mkdir -p "${TEST_ROOT}/empty-dir" "${TEST_ROOT}/non-empty-dir"
printf x > "${TEST_ROOT}/non-empty-dir/x"
assert_true "empty file" path::empty "${TEST_ROOT}/empty.txt"
assert_false "non-empty file" path::empty "${TEST_ROOT}/file.txt"
assert_true "empty dir" path::empty "${TEST_ROOT}/empty-dir"
assert_false "non-empty dir" path::empty "${TEST_ROOT}/non-empty-dir"
assert_false "empty missing fails" path::empty "${TEST_ROOT}/missing"

mark path::filled
assert_true "filled file" path::filled "${TEST_ROOT}/file.txt"
assert_true "filled dir" path::filled "${TEST_ROOT}/non-empty-dir"
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

mark path::is_root
assert_true "is_root slash" path::is_root "/"
assert_true "is_root drive" path::is_root "C:/"
assert_false "is_root non-root" path::is_root "/tmp"

mark path::is_unc
assert_true "is_unc POSIX double slash" path::is_unc "//server/share"
assert_true "is_unc Windows double backslash" path::is_unc "\\\\server\\share"
assert_false "is_unc normal" path::is_unc "/tmp"

mark path::has_drive
assert_true "has_drive C:" path::has_drive "C:/x"
assert_true "has_drive drive-relative" path::has_drive "C:foo"
assert_false "has_drive POSIX" path::has_drive "/tmp"

mark path::slashify
assert_eq "slashify backslashes" "C:/A/B" "$(path::slashify 'C:\A\B')"
assert_false "slashify rejects newline" path::slashify $'a\nb'

mark path::posix
assert_eq "posix C:/Users" "/c/Users" "$(path::posix 'C:/Users')"
assert_false "posix rejects drive-relative" path::posix "C:Users"
assert_eq "posix slashifies plain" "a/b" "$(path::posix 'a\b')"

mark path::win
assert_eq "win /mnt/c/Users" 'C:\Users' "$(path::win '/mnt/c/Users')"
assert_eq "win drive uppercases" 'C:\Users' "$(path::win 'c:/Users')"
if sys::is_windows; then
    assert_eq "win cyg style on windows" 'C:\Users' "$(path::win '/c/Users')"
else
    assert_eq "win does not corrupt linux /u/share" '\u\share' "$(path::win '/u/share')"
fi

mark path::norm
assert_eq "norm collapses slash and dot" "/a/c" "$(path::norm '/a//b/../c/.')"
assert_eq "norm relative up" "../a" "$(path::norm '../x/../a')"
assert_eq "norm root" "/" "$(path::norm '////')"
assert_eq "norm drive absolute" "C:/a/c" "$(path::norm 'C:/a/b/../c')"
assert_eq "norm drive-relative preserves C:" "C:" "$(path::norm 'C:foo/..')"
assert_eq "norm UNC" "//server/share" "$(path::norm '//server/share/dir/..')"

mark path::join
assert_eq "join simple" "a/b/c" "$(path::join a b c)"
assert_eq "join resets on absolute" "/x/y" "$(path::join a b /x y)"
assert_eq "join handles empty segments" "a/b" "$(path::join '' a '' b)"

mark path::resolve
resolved_file="$(path::resolve "${TEST_ROOT}/src/a/../a/b/deep.txt")"
assert_match "resolve file absolute" "${resolved_file}" ^/
assert_eq "resolve basename" "deep.txt" "$(path::basename "${resolved_file}")"

mark path::drive
assert_eq "drive extracts C:" "C:" "$(path::drive 'C:/x')"
assert_false "drive fails posix" path::drive "/tmp"

mark path::cwd
assert_eq "cwd non-empty" "$(pwd)" "$(path::cwd)"

mark path::pwd
[[ -n "$(path::pwd)" ]] && ok "pwd returns something" || fail "pwd returns something"

mark path::abs
assert_match "abs relative becomes absolute" "$(path::abs 'abc')" '^/'
assert_eq "abs absolute normalized" "/tmp/x" "$(path::abs '/tmp/a/../x')"

mark path::rel
assert_eq "rel same" "." "$(path::rel "${TEST_ROOT}/src" "${TEST_ROOT}/src")"
assert_eq "rel child" "a/b/deep.txt" "$(path::rel "${TEST_ROOT}/src/a/b/deep.txt" "${TEST_ROOT}/src")"
assert_eq "rel sibling" "../dst" "$(path::rel "${TEST_ROOT}/dst" "${TEST_ROOT}/src")"

mark path::expand
assert_eq "expand ~" "${HOME:-}" "$(path::expand '~')"
assert_eq "expand ~/x" "${HOME:-}/x" "$(path::expand '~/x')"
assert_eq "expand plain" "plain" "$(path::expand 'plain')"

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

mark path::dirname
assert_eq "dirname file" "${TEST_ROOT}" "$(path::dirname "${TEST_ROOT}/file.txt")"
assert_eq "dirname no slash" "." "$(path::dirname "file.txt")"
assert_eq "dirname root child" "/" "$(path::dirname "/file.txt")"
assert_eq "dirname drive-relative" "C:" "$(path::dirname "C:foo")"
assert_eq "dirname drive absolute" "C:/foo" "$(path::dirname "C:/foo/bar")"

mark path::basename
assert_eq "basename file" "file.txt" "$(path::basename "${TEST_ROOT}/file.txt")"
assert_eq "basename trailing slash" "src" "$(path::basename "${TEST_ROOT}/src/")"

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

# -----------------------------------------------------------------------------
# Type and metadata
# -----------------------------------------------------------------------------

note "types and metadata"
mark path::is_file
assert_true "is_file" path::is_file "${TEST_ROOT}/file.txt"
assert_false "is_file dir" path::is_file "${TEST_ROOT}/src"

mark path::is_dir
assert_true "is_dir" path::is_dir "${TEST_ROOT}/src"
assert_false "is_dir file" path::is_dir "${TEST_ROOT}/file.txt"

mark path::is_link
if ln -s "${TEST_ROOT}/file.txt" "${TEST_ROOT}/link-file" 2>/dev/null; then
    assert_true "is_link" path::is_link "${TEST_ROOT}/link-file"
else
    skip "is_link symlink unavailable"
fi

mark path::is_pipe
if command -v mkfifo >/dev/null 2>&1 && mkfifo "${TEST_ROOT}/fifo" 2>/dev/null; then
    assert_true "is_pipe fifo" path::is_pipe "${TEST_ROOT}/fifo"
else
    skip "is_pipe mkfifo unavailable"
fi

mark path::is_socket
if command -v python3 >/dev/null 2>&1; then
    python3 - <<PY >/dev/null 2>&1
import socket, os
p = ${TEST_ROOT@Q} + '/sock'
try:
    os.unlink(p)
except FileNotFoundError:
    pass
s = socket.socket(socket.AF_UNIX, socket.SOCK_STREAM)
s.bind(p)
s.close()
PY
    assert_true "is_socket unix socket" path::is_socket "${TEST_ROOT}/sock"
else
    skip "is_socket python3 unavailable"
fi

mark path::is_char
if [[ -c /dev/null ]]; then assert_true "is_char /dev/null" path::is_char /dev/null; else skip "is_char no /dev/null char"; fi

mark path::is_block
if [[ -b /dev/sda ]]; then assert_true "is_block /dev/sda" path::is_block /dev/sda
else assert_false "is_block regular file" path::is_block "${TEST_ROOT}/file.txt"
fi

mark path::readable
assert_true "readable file" path::readable "${TEST_ROOT}/file.txt"

mark path::writable
assert_true "writable file" path::writable "${TEST_ROOT}/file.txt"

mark path::executable
printf '#!/usr/bin/env bash\nexit 0\n' > "${TEST_ROOT}/run.sh"
chmod +x "${TEST_ROOT}/run.sh"
assert_true "executable file" path::executable "${TEST_ROOT}/run.sh"
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

mark path::is_same
assert_true "is_same self" path::is_same "${TEST_ROOT}/file.txt" "${TEST_ROOT}/file.txt"
if [[ -L "${TEST_ROOT}/link-file" ]]; then assert_true "is_same symlink target" path::is_same "${TEST_ROOT}/file.txt" "${TEST_ROOT}/link-file"; fi
assert_false "is_same different" path::is_same "${TEST_ROOT}/file.txt" "${TEST_ROOT}/empty.txt"

mark path::is_under
assert_true "is_under child" path::is_under "${TEST_ROOT}/src/a" "${TEST_ROOT}/src"
assert_false "is_under same" path::is_under "${TEST_ROOT}/src" "${TEST_ROOT}/src"
assert_false "is_under sibling" path::is_under "${TEST_ROOT}/dst" "${TEST_ROOT}/src"

mark path::is_parent
assert_true "is_parent parent" path::is_parent "${TEST_ROOT}/src" "${TEST_ROOT}/src/a"
assert_false "is_parent sibling" path::is_parent "${TEST_ROOT}/src" "${TEST_ROOT}/dst"

# -----------------------------------------------------------------------------
# Roots, script, standard dirs
# -----------------------------------------------------------------------------

note "roots and user dirs"
mark path::root
assert_eq "root empty defaults slash" "/" "$(path::root '')"
assert_eq "root posix" "/" "$(path::root '/a/b')"
assert_eq "root drive" "C:/" "$(path::root 'C:/a/b')"
assert_eq "root unc" "//server/" "$(path::root '//server/share/x')"
assert_false "root relative fails" path::root "a/b"

mark path::script
[[ -n "$(path::script "${PATH_LIB}")" ]] && ok "script current test resolves" || fail "script current test resolves"

mark path::script_dir
assert_eq "script_dir target dir" "$(path::dirname "$(path::abs "${PATH_LIB}")")" "$(path::script_dir "${PATH_LIB}")"

for fn in home_dir tmp_dir config_dir data_dir cache_dir state_dir runtime_dir log_dir bin_dir desktop_dir downloads_dir documents_dir pictures_dir music_dir videos_dir public_dir templates_dir; do
    mark "path::${fn}"
    value="$("path::${fn}" 2>/dev/null || true)"
    if [[ -n "${value}" ]]; then ok "${fn} returns non-empty: ${value}"; else fail "${fn} returned empty/failure"; fi
done

# -----------------------------------------------------------------------------
# Name changing
# -----------------------------------------------------------------------------

note "name changing"
mark path::chname
assert_eq "chname file" "${TEST_ROOT}/renamed.md" "$(path::chname "${TEST_ROOT}/file.txt" "renamed.md")"
assert_eq "chname plain" "renamed.md" "$(path::chname "file.txt" "renamed.md")"

mark path::chstem
assert_eq "chstem file" "${TEST_ROOT}/hello.txt" "$(path::chstem "${TEST_ROOT}/file.txt" "hello")"
assert_eq "chstem no ext" "hello" "$(path::chstem "file" "hello")"

mark path::chext
assert_eq "chext file" "${TEST_ROOT}/file.md" "$(path::chext "${TEST_ROOT}/file.txt" "md")"
assert_eq "chext dot ext" "${TEST_ROOT}/file.md" "$(path::chext "${TEST_ROOT}/file.txt" ".md")"
assert_eq "chext remove ext" "${TEST_ROOT}/file" "$(path::chext "${TEST_ROOT}/file.txt" "")"

# -----------------------------------------------------------------------------
# Mutations
# -----------------------------------------------------------------------------

note "filesystem mutations"
mark path::chmod
chmod_target="${TEST_ROOT}/chmod.txt"
printf z > "${chmod_target}"
assert_true "chmod 600" path::chmod "${chmod_target}" 600
assert_match "chmod mode applied" "$(path::mode "${chmod_target}")" '600$|0600$'
assert_false "chmod rejects bad mode" path::chmod "${chmod_target}" 'bad-mode'

mark path::make
assert_true "make nested dir" path::make "${TEST_ROOT}/made/a/b"
assert_dir "make created nested" "${TEST_ROOT}/made/a/b"
assert_false "make refuses existing file" path::make "${TEST_ROOT}/file.txt"

mark path::touch
assert_true "touch nested file" path::touch "${TEST_ROOT}/touch/a/b/t.txt"
assert_file "touch created file" "${TEST_ROOT}/touch/a/b/t.txt"

mark path::remove
printf x > "${TEST_ROOT}/remove-me.txt"
assert_true "remove file" path::remove "${TEST_ROOT}/remove-me.txt"
assert_missing "remove deleted file" "${TEST_ROOT}/remove-me.txt"
mkdir -p "${TEST_ROOT}/remove-dir/a"
assert_true "remove dir" path::remove "${TEST_ROOT}/remove-dir"
assert_missing "remove deleted dir" "${TEST_ROOT}/remove-dir"
assert_false "remove refuses root" path::remove "/"

mark path::clear
mkdir -p "${TEST_ROOT}/clear-dir/sub"
printf x > "${TEST_ROOT}/clear-dir/sub/x"
printf y > "${TEST_ROOT}/clear-dir/.hidden"
assert_true "clear dir" path::clear "${TEST_ROOT}/clear-dir"
assert_true "clear dir empty after" path::empty "${TEST_ROOT}/clear-dir"
printf x > "${TEST_ROOT}/clear-file.txt"
assert_true "clear file" path::clear "${TEST_ROOT}/clear-file.txt"
assert_true "clear file empty after" path::empty "${TEST_ROOT}/clear-file.txt"

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

mark path::sync
mkdir -p "${TEST_ROOT}/sync-src/a" "${TEST_ROOT}/sync-dst/old"
printf sync > "${TEST_ROOT}/sync-src/a/file.txt"
printf old > "${TEST_ROOT}/sync-dst/old/file.txt"
assert_true "sync dir" path::sync "${TEST_ROOT}/sync-src" "${TEST_ROOT}/sync-dst"
assert_file "sync copied file" "${TEST_ROOT}/sync-dst/a/file.txt"
assert_missing "sync delete old" "${TEST_ROOT}/sync-dst/old/file.txt"
printf one > "${TEST_ROOT}/sync-file-src.txt"
assert_true "sync file" path::sync "${TEST_ROOT}/sync-file-src.txt" "${TEST_ROOT}/sync-file-dst.txt"
assert_file "sync file copied" "${TEST_ROOT}/sync-file-dst.txt"

mark path::link
if ln "${TEST_ROOT}/file.txt" "${TEST_ROOT}/hardlink-manual" 2>/dev/null; then
    rm -f -- "${TEST_ROOT}/hardlink-manual"
    assert_true "hard link" path::link "${TEST_ROOT}/file.txt" "${TEST_ROOT}/hardlink"
    assert_true "hard link same inode" path::is_same "${TEST_ROOT}/file.txt" "${TEST_ROOT}/hardlink"
else
    skip "hard link unsupported"
fi

mark path::symlink
if ln -s "${TEST_ROOT}/file.txt" "${TEST_ROOT}/symlink-manual" 2>/dev/null; then
    rm -f -- "${TEST_ROOT}/symlink-manual"
    assert_true "symlink" path::symlink "${TEST_ROOT}/file.txt" "${TEST_ROOT}/symlink"
    assert_true "symlink is link" path::is_link "${TEST_ROOT}/symlink"
else
    skip "symlink unsupported"
fi

mark path::readlink
if [[ -L "${TEST_ROOT}/symlink" ]]; then
    assert_eq "readlink symlink" "${TEST_ROOT}/file.txt" "$(path::readlink "${TEST_ROOT}/symlink")"
else
    skip "readlink no symlink"
fi

mark path::mktemp
tmp_file="$(path::mktemp brutal .tmp)"
assert_file "mktemp creates file" "${tmp_file}"
rm -f -- "${tmp_file}"

mark path::mktemp_dir
tmp_dir="$(path::mktemp_dir brutal)"
assert_dir "mktemp_dir creates dir" "${tmp_dir}"
rmdir -- "${tmp_dir}" 2>/dev/null || true

# -----------------------------------------------------------------------------
# Archive / backup / extract / strip
# -----------------------------------------------------------------------------

note "archive extract backup strip"
mark path::archive
archive_src="${TEST_ROOT}/archive-src"
mkdir -p "${archive_src}/top/nested" "${archive_src}/skip"
printf keep > "${archive_src}/top/nested/keep.txt"
printf skip > "${archive_src}/skip/skip.txt"
if sys::has tar; then
    tar_out="${TEST_ROOT}/archives/archive.tar.gz"
    assert_true "archive tar.gz" path::archive "${archive_src}" "${tar_out}" --exclude='skip/*'
    assert_file "archive output exists" "${tar_out}"
else
    skip "archive tar.gz requires tar"
fi
if sys::has zip || sys::has 7z; then
    zip_out="${TEST_ROOT}/archives/archive.zip"
    assert_true "archive zip" path::archive "${archive_src}" "${zip_out}" --format=zip
    assert_file "archive zip exists" "${zip_out}"
else
    skip "archive zip requires zip or 7z"
fi

mark path::backup
if sys::has tar; then
    backup_out="$(cd "${TEST_ROOT}/archives" && path::backup "${archive_src}" 2>/dev/null || true)"
    # backup_out may be relative to cwd depending invocation; test explicit safer
    explicit_backup="${TEST_ROOT}/archives/explicit-backup.tar.gz"
    assert_true "backup explicit" path::backup "${archive_src}" "${explicit_backup}"
    assert_file "backup explicit exists" "${explicit_backup}"
else
    skip "backup requires tar"
fi

mark path::extract
if [[ -f "${tar_out:-}" ]]; then
    extract_to="${TEST_ROOT}/extract/tar"
    assert_true "extract tar.gz" path::extract "${tar_out}" "${extract_to}"
    assert_file "extract tar.gz content" "${extract_to}/archive-src/top/nested/keep.txt"

    extract_strip="${TEST_ROOT}/extract/tar-strip"
    assert_true "extract tar.gz --strip=1" path::extract "${tar_out}" "${extract_strip}" --strip=1
    assert_file "extract strip content" "${extract_strip}/top/nested/keep.txt"
fi
if [[ -f "${zip_out:-}" ]]; then
    extract_zip="${TEST_ROOT}/extract/zip"
    assert_true "extract zip" path::extract "${zip_out}" "${extract_zip}"
    assert_file "extract zip content" "${extract_zip}/archive-src/top/nested/keep.txt"
fi

mark path::strip
strip_root="${TEST_ROOT}/strip-root"
mkdir -p "${strip_root}/outer/inner"
printf stripped > "${strip_root}/outer/inner/file.txt"
assert_true "strip dir one component" path::strip "${strip_root}" 1
# Correct semantic expectation: strip 1 removes outer/, leaving inner/file.txt under root.
assert_file "strip removes first real component" "${strip_root}/inner/file.txt"
assert_false "strip rejects file target" path::strip "${TEST_ROOT}/file.txt" 1
assert_false "strip rejects root" path::strip "/" 1

# -----------------------------------------------------------------------------
# Which / which_all
# -----------------------------------------------------------------------------

note "which"
mark path::which
assert_true "which bash" path::which bash
assert_false "which missing" path::which "definitely-not-a-real-command-xyz"
assert_false "which newline rejected" path::which $'bash\nls'

mark path::which_all
which_all_bash="$(path::which_all bash || true)"
if [[ -n "${which_all_bash}" ]]; then ok "which_all bash returns entries"; else fail "which_all bash returned empty"; fi

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
        sleep 0.35
        printf after >> "${watch_file}"
    ) &
    watcher_mod_pid=$!
    if run_timeout 5 bash -c 'source "$1"; sys::has () { command -v -- "${1:-}" >/dev/null 2>&1; }; sys::is_linux () { [[ "${OSTYPE:-}" == linux* ]]; }; sys::is_macos () { [[ "${OSTYPE:-}" == darwin* ]]; }; sys::is_windows () { [[ "${OS:-}" == Windows_NT || "${OSTYPE:-}" == msys* || "${OSTYPE:-}" == cygwin* ]]; }; sys::is_wsl () { [[ -n "${WSL_DISTRO_NAME:-}${WSL_INTEROP:-}" ]]; }; path::watch "$2" 0.1 "" once >/dev/null' _ "${PATH_LIB}" "${watch_file}"; then
        ok "watch file once detects modification"
    else
        fail "watch file once detects modification"
    fi
    wait "${watcher_mod_pid}" 2>/dev/null || true

    watch_dir="${TEST_ROOT}/watch-dir"
    mkdir -p "${watch_dir}"
    (
        sleep 0.35
        printf created > "${watch_dir}/created.txt"
    ) &
    watcher_dir_pid=$!
    if run_timeout 5 bash -c 'source "$1"; sys::has () { command -v -- "${1:-}" >/dev/null 2>&1; }; sys::is_linux () { [[ "${OSTYPE:-}" == linux* ]]; }; sys::is_macos () { [[ "${OSTYPE:-}" == darwin* ]]; }; sys::is_windows () { [[ "${OS:-}" == Windows_NT || "${OSTYPE:-}" == msys* || "${OSTYPE:-}" == cygwin* ]]; }; sys::is_wsl () { [[ -n "${WSL_DISTRO_NAME:-}${WSL_INTEROP:-}" ]]; }; path::watch "$2" 0.1 "" once >/dev/null' _ "${PATH_LIB}" "${watch_dir}"; then
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
        sleep 0.35
        printf again >> "${watch_file}"
    ) &
    watcher_cb_pid=$!
    if run_timeout 5 bash -c 'source "$1"; sys::has () { command -v -- "${1:-}" >/dev/null 2>&1; }; sys::is_linux () { [[ "${OSTYPE:-}" == linux* ]]; }; sys::is_macos () { [[ "${OSTYPE:-}" == darwin* ]]; }; sys::is_windows () { [[ "${OS:-}" == Windows_NT || "${OSTYPE:-}" == msys* || "${OSTYPE:-}" == cygwin* ]]; }; sys::is_wsl () { [[ -n "${WSL_DISTRO_NAME:-}${WSL_INTEROP:-}" ]]; }; path::watch "$2" 0.1 "$3" once >/dev/null' _ "${PATH_LIB}" "${watch_file}" "${callback_script}"; then
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
    for i in $(seq 1 300); do
        mkdir -p "${stress_dir}/d$(( i % 17 ))"
        printf '%s\n' "${i}" > "${stress_dir}/d$(( i % 17 ))/file-${i}.txt"
    done
    assert_true "slow common many" path::common "${stress_dir}/d1/file-1.txt" "${stress_dir}/d1/file-18.txt"
    if sys::has tar; then
        stress_archive="${TEST_ROOT}/archives/stress.tar.gz"
        assert_true "slow archive 300 files" path::archive "${stress_dir}" "${stress_archive}"
        assert_true "slow extract 300 files" path::extract "${stress_archive}" "${TEST_ROOT}/extract/stress"
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

# -----------------------------------------------------------------------------
# Summary
# -----------------------------------------------------------------------------

printf '\n'
printf '============================================================\n'
printf ' path.sh brutal test summary\n'
printf '================================================------------\n'
printf 'Target : %s\n' "${PATH_LIB}"
printf 'Root   : %s\n' "${TEST_ROOT}"
printf 'Total  : %s\n' "${TOTAL}"
printf 'Pass   : %s\n' "${PASS}"
printf 'Fail   : %s\n' "${FAIL}"
printf 'Skip   : %s\n' "${SKIP}"
printf 'Funcs  : %s/%s covered\n' "$(( ${#ALL_FUNCS[@]} - ${#missing[@]} ))" "${#ALL_FUNCS[@]}"
printf '============================================================\n'

if (( FAIL > 0 )); then
    exit 1
fi

exit 0
