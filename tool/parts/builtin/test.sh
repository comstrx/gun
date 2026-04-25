#!/usr/bin/env bash
# shellcheck shell=bash

set -u
set -o pipefail

TARGET="${1:-tool/parts/builtin/input.sh}"

pass=0
fail=0

ok () {

    printf '[PASS] %s\n' "$1"
    pass=$(( pass + 1 ))

}

bad () {

    printf '[FAIL] %s\n  want: [%s]\n  got : [%s]\n' "$1" "$2" "$3"
    fail=$(( fail + 1 ))

}

eq () {

    local name="$1" want="$2" got="$3"

    [[ "${got}" == "${want}" ]] && ok "${name}" || bad "${name}" "${want}" "${got}"

}

no () {

    local name="$1"
    shift

    if "$@"; then bad "${name}" "exit!=0" "exit=0"
    else ok "${name}"
    fi

}

run_no_tty () {

    local code="$1"

    if command -v setsid >/dev/null 2>&1; then
        setsid bash -c 'source "$1"; shift; eval "$1"' _ "${TARGET}" "${code}" 2>/dev/null
    else
        bash -c 'source "$1"; shift; eval "$1"' _ "${TARGET}" "${code}" 2>/dev/null
    fi

}
dump_list () {

    local name="${1:-}" item=""
    local -n ref="${name}"

    for item in "${ref[@]}"; do
        printf '[%q]\n' "${item}"
    done

}
same_list () {

    local name="${1:-}" want="${2:-}" got=""

    got="$(dump_list "${name}")"
    eq "${name}" "${want}" "${got}"

}

source "${TARGET}"

echo "== input::get automated no-tty tests =="

eq "read plain line" \
    "hello" \
    "$(run_no_tty 'printf "hello\n" | input::get')"

eq "preserve spaces" \
    "  hello world  " \
    "$(run_no_tty 'printf "  hello world  \n" | input::get')"

eq "empty line without default" \
    "" \
    "$(run_no_tty 'printf "\n" | input::get')"

eq "empty line uses default" \
    "DEF" \
    "$(run_no_tty 'printf "\n" | input::get "" "DEF"')"

eq "EOF uses default" \
    "DEF" \
    "$(run_no_tty 'printf "" | input::get "" "DEF"')"

no "EOF without default fails" \
    bash -c '
        source "$1"
        if command -v setsid >/dev/null 2>&1; then
            setsid bash -c "source \"\$1\"; printf \"\" | input::get >/dev/null" _ "$1" 2>/dev/null
        else
            printf "" | input::get >/dev/null 2>&1
        fi
    ' _ "${TARGET}"

eq "prompt does not pollute stdout" \
    "hello" \
    "$(run_no_tty 'printf "hello\n" | input::get "Name: "')"

echo
echo "== input::read tests =="

eq "read plain text" \
    "hello" \
    "$(printf 'hello' | input::read)"

eq "read multiline text via command substitution trims final newline" \
    $'line1\nline2' \
    "$(printf 'line1\nline2\n' | input::read)"

bytes="$(printf 'line1\nline2\n' | input::read | wc -c | tr -d ' ')"
eq "read preserves final newline by byte count" \
    "12" \
    "${bytes}"

eq "read empty stdin" \
    "" \
    "$(printf '' | input::read)"

tmp_read_file="$(mktemp)"
printf 'file-line-1\nfile-line-2\n' > "${tmp_read_file}"

file_bytes="$(input::read < "${tmp_read_file}" | wc -c | tr -d ' ')"
eq "read file redirect preserves bytes" \
    "24" \
    "${file_bytes}"

file_text="$(input::read < "${tmp_read_file}")"
eq "read file redirect text via command substitution trims final newline" \
    $'file-line-1\nfile-line-2' \
    "${file_text}"

rm -f "${tmp_read_file}"

echo
echo "== input::lines tests =="

input::lines rows < <(printf 'a\n\nb c\n*\n')
same_list rows $'[a]\n[\'\']\n[b\\ c]\n[\\*]'

input::lines rows_no_final < <(printf 'no-final-newline')
same_list rows_no_final $'[no-final-newline]'

input::lines rows_empty < <(printf '')
same_list rows_empty ""

tmp_lines_file="$(mktemp)"
printf 'file-1\n\nfile 2\n*\n' > "${tmp_lines_file}"

input::lines rows_file < "${tmp_lines_file}"
same_list rows_file $'[file-1]\n[\'\']\n[file\\ 2]\n[\\*]'

rm -f "${tmp_lines_file}"

no "lines invalid target fails" \
    input::lines "bad-name"

scalar_rows="x"

no "lines scalar target fails" \
    input::lines scalar_rows < <(printf 'a\nb\n')

unset rows_tx 2>/dev/null || true
rows_tx=( "old" "data" )
before="$(dump_list rows_tx)"

no "lines invalid target keeps old array untouched" \
    input::lines "bad-name" < <(printf 'new\nvalue\n')

eq "lines transactional invariant" \
    "${before}" \
    "$(dump_list rows_tx)"

echo
echo "== input::bool tests =="

eq "bool yes: y" \
    "1" \
    "$(run_no_tty 'printf "y\n" | input::bool')"

eq "bool yes: yes" \
    "1" \
    "$(run_no_tty 'printf "yes\n" | input::bool')"

eq "bool yes: true" \
    "1" \
    "$(run_no_tty 'printf "true\n" | input::bool')"

eq "bool yes: on" \
    "1" \
    "$(run_no_tty 'printf "on\n" | input::bool')"

eq "bool yes: 1" \
    "1" \
    "$(run_no_tty 'printf "1\n" | input::bool')"

eq "bool yes uppercase" \
    "1" \
    "$(run_no_tty 'printf "YES\n" | input::bool')"

eq "bool no: n" \
    "0" \
    "$(run_no_tty 'printf "n\n" | input::bool')"

eq "bool no: no" \
    "0" \
    "$(run_no_tty 'printf "no\n" | input::bool')"

eq "bool no: false" \
    "0" \
    "$(run_no_tty 'printf "false\n" | input::bool')"

eq "bool no: off" \
    "0" \
    "$(run_no_tty 'printf "off\n" | input::bool')"

eq "bool no: 0" \
    "0" \
    "$(run_no_tty 'printf "0\n" | input::bool')"

eq "bool no uppercase" \
    "0" \
    "$(run_no_tty 'printf "NO\n" | input::bool')"

eq "bool empty uses default yes" \
    "1" \
    "$(run_no_tty 'printf "\n" | input::bool "" "yes" 1')"

eq "bool empty uses default no" \
    "0" \
    "$(run_no_tty 'printf "\n" | input::bool "" "no" 1')"

eq "bool EOF uses default true" \
    "1" \
    "$(run_no_tty 'printf "" | input::bool "" "true" 1')"

eq "bool retries then success" \
    "1" \
    "$(run_no_tty 'printf "bad\nwrong\ny\n" | input::bool "" "" 3')"

no "bool invalid fails after tries" \
    bash -c 'source "$1"; out="$(setsid bash -c "source \"\$1\"; printf \"bad\nwrong\nextra\n\" | input::bool \"\" \"\" 2 >/dev/null" _ "$1" 2>/dev/null)"' _ "${TARGET}"

no "bool zero tries normalized then invalid fails" \
    bash -c 'source "$1"; setsid bash -c "source \"\$1\"; printf \"bad\nbad\nbad\nbad\n\" | input::bool \"\" \"\" 0 >/dev/null" _ "$1" 2>/dev/null' _ "${TARGET}"

no "bool non-numeric tries normalized then invalid fails" \
    bash -c 'source "$1"; setsid bash -c "source \"\$1\"; printf \"bad\nbad\nbad\nbad\n\" | input::bool \"\" \"\" nope >/dev/null" _ "$1" 2>/dev/null' _ "${TARGET}"

echo
echo "== input::confirm tests =="

ok "confirm yes: y" \
    bash -c 'source "$1"; setsid bash -c "source \"\$1\"; printf \"y\n\" | input::confirm >/dev/null" _ "$1" 2>/dev/null' _ "${TARGET}"

ok "confirm yes: yes" \
    bash -c 'source "$1"; setsid bash -c "source \"\$1\"; printf \"yes\n\" | input::confirm >/dev/null" _ "$1" 2>/dev/null' _ "${TARGET}"

ok "confirm yes: true" \
    bash -c 'source "$1"; setsid bash -c "source \"\$1\"; printf \"true\n\" | input::confirm >/dev/null" _ "$1" 2>/dev/null' _ "${TARGET}"

ok "confirm yes: on" \
    bash -c 'source "$1"; setsid bash -c "source \"\$1\"; printf \"on\n\" | input::confirm >/dev/null" _ "$1" 2>/dev/null' _ "${TARGET}"

ok "confirm yes: 1" \
    bash -c 'source "$1"; setsid bash -c "source \"\$1\"; printf \"1\n\" | input::confirm >/dev/null" _ "$1" 2>/dev/null' _ "${TARGET}"

no "confirm no: n" \
    bash -c 'source "$1"; setsid bash -c "source \"\$1\"; printf \"n\n\" | input::confirm >/dev/null" _ "$1" 2>/dev/null' _ "${TARGET}"

no "confirm no: no" \
    bash -c 'source "$1"; setsid bash -c "source \"\$1\"; printf \"no\n\" | input::confirm >/dev/null" _ "$1" 2>/dev/null' _ "${TARGET}"

no "confirm no: false" \
    bash -c 'source "$1"; setsid bash -c "source \"\$1\"; printf \"false\n\" | input::confirm >/dev/null" _ "$1" 2>/dev/null' _ "${TARGET}"

no "confirm no: off" \
    bash -c 'source "$1"; setsid bash -c "source \"\$1\"; printf \"off\n\" | input::confirm >/dev/null" _ "$1" 2>/dev/null' _ "${TARGET}"

no "confirm no: 0" \
    bash -c 'source "$1"; setsid bash -c "source \"\$1\"; printf \"0\n\" | input::confirm >/dev/null" _ "$1" 2>/dev/null' _ "${TARGET}"

ok "confirm uppercase yes" \
    bash -c 'source "$1"; setsid bash -c "source \"\$1\"; printf \"YES\n\" | input::confirm >/dev/null" _ "$1" 2>/dev/null' _ "${TARGET}"

no "confirm uppercase no" \
    bash -c 'source "$1"; setsid bash -c "source \"\$1\"; printf \"NO\n\" | input::confirm >/dev/null" _ "$1" 2>/dev/null' _ "${TARGET}"

ok "confirm default yes on empty" \
    bash -c 'source "$1"; setsid bash -c "source \"\$1\"; printf \"\n\" | input::confirm \"Continue?\" \"Y\" 1 >/dev/null" _ "$1" 2>/dev/null' _ "${TARGET}"

no "confirm default no on empty" \
    bash -c 'source "$1"; setsid bash -c "source \"\$1\"; printf \"\n\" | input::confirm \"Continue?\" \"N\" 1 >/dev/null" _ "$1" 2>/dev/null' _ "${TARGET}"

ok "confirm retries then yes" \
    bash -c 'source "$1"; setsid bash -c "source \"\$1\"; printf \"bad\nwrong\ny\n\" | input::confirm \"Continue?\" \"N\" 3 >/dev/null" _ "$1" 2>/dev/null' _ "${TARGET}"

no "confirm invalid fails after tries" \
    bash -c 'source "$1"; setsid bash -c "source \"\$1\"; printf \"bad\nwrong\nextra\n\" | input::confirm \"Continue?\" \"N\" 2 >/dev/null" _ "$1" 2>/dev/null' _ "${TARGET}"

no "confirm zero tries normalized then invalid fails" \
    bash -c 'source "$1"; setsid bash -c "source \"\$1\"; printf \"bad\nbad\nbad\nbad\n\" | input::confirm \"Continue?\" \"N\" 0 >/dev/null" _ "$1" 2>/dev/null' _ "${TARGET}"

no "confirm non-numeric tries normalized then invalid fails" \
    bash -c 'source "$1"; setsid bash -c "source \"\$1\"; printf \"bad\nbad\nbad\nbad\n\" | input::confirm \"Continue?\" \"N\" nope >/dev/null" _ "$1" 2>/dev/null' _ "${TARGET}"

echo
echo "== input::password tests =="

no "password fails without tty" \
    bash -c 'source "$1"; setsid bash -c "source \"\$1\"; input::password \"Password: \" >/dev/null" _ "$1" 2>/dev/null' _ "${TARGET}"

echo
echo "== input::number tests =="

eq "int positive" \
    "12" \
    "$(run_no_tty 'printf "12\n" | input::int')"

eq "int negative" \
    "-7" \
    "$(run_no_tty 'printf -- "-7\n" | input::int')"

eq "int zero" \
    "0" \
    "$(run_no_tty 'printf "0\n" | input::int')"

eq "int default" \
    "42" \
    "$(run_no_tty 'printf "\n" | input::int "" "42" 1')"

eq "int retries then success" \
    "9" \
    "$(run_no_tty 'printf "bad\n9\n" | input::int "" "" 2')"

no "int rejects float" \
    bash -c 'source "$1"; setsid bash -c "source \"\$1\"; printf \"1.2\n\" | input::int \"\" \"\" 1 >/dev/null" _ "$1" 2>/dev/null' _ "${TARGET}"

no "int rejects alpha" \
    bash -c 'source "$1"; setsid bash -c "source \"\$1\"; printf \"abc\n\" | input::int \"\" \"\" 1 >/dev/null" _ "$1" 2>/dev/null' _ "${TARGET}"

no "int rejects empty without valid default" \
    bash -c 'source "$1"; setsid bash -c "source \"\$1\"; printf \"\n\" | input::int \"\" \"\" 1 >/dev/null" _ "$1" 2>/dev/null' _ "${TARGET}"


eq "uint positive" \
    "12" \
    "$(run_no_tty 'printf "12\n" | input::uint')"

eq "uint zero" \
    "0" \
    "$(run_no_tty 'printf "0\n" | input::uint')"

eq "uint default" \
    "42" \
    "$(run_no_tty 'printf "\n" | input::uint "" "42" 1')"

eq "uint retries then success" \
    "9" \
    "$(run_no_tty 'printf "bad\n9\n" | input::uint "" "" 2')"

no "uint rejects negative" \
    bash -c 'source "$1"; setsid bash -c "source \"\$1\"; printf -- \"-1\n\" | input::uint \"\" \"\" 1 >/dev/null" _ "$1" 2>/dev/null' _ "${TARGET}"

no "uint rejects float" \
    bash -c 'source "$1"; setsid bash -c "source \"\$1\"; printf \"1.2\n\" | input::uint \"\" \"\" 1 >/dev/null" _ "$1" 2>/dev/null' _ "${TARGET}"

no "uint rejects alpha" \
    bash -c 'source "$1"; setsid bash -c "source \"\$1\"; printf \"abc\n\" | input::uint \"\" \"\" 1 >/dev/null" _ "$1" 2>/dev/null' _ "${TARGET}"


eq "float integer" \
    "12" \
    "$(run_no_tty 'printf "12\n" | input::float')"

eq "float decimal" \
    "12.5" \
    "$(run_no_tty 'printf "12.5\n" | input::float')"

eq "float negative integer" \
    "-7" \
    "$(run_no_tty 'printf -- "-7\n" | input::float')"

eq "float negative decimal" \
    "-7.5" \
    "$(run_no_tty 'printf -- "-7.5\n" | input::float')"

eq "float plus sign" \
    "+3.14" \
    "$(run_no_tty 'printf "+3.14\n" | input::float')"

eq "float leading dot" \
    ".3" \
    "$(run_no_tty 'printf ".3\n" | input::float')"

eq "float trailing dot" \
    "3." \
    "$(run_no_tty 'printf "3.\n" | input::float')"

eq "float default" \
    "1.5" \
    "$(run_no_tty 'printf "\n" | input::float "" "1.5" 1')"

eq "float retries then success" \
    "2.5" \
    "$(run_no_tty 'printf "bad\n2.5\n" | input::float "" "" 2')"

no "float rejects alpha" \
    bash -c 'source "$1"; setsid bash -c "source \"\$1\"; printf \"abc\n\" | input::float \"\" \"\" 1 >/dev/null" _ "$1" 2>/dev/null' _ "${TARGET}"

no "float rejects double dot" \
    bash -c 'source "$1"; setsid bash -c "source \"\$1\"; printf \"1.2.3\n\" | input::float \"\" \"\" 1 >/dev/null" _ "$1" 2>/dev/null' _ "${TARGET}"

no "float rejects sign only" \
    bash -c 'source "$1"; setsid bash -c "source \"\$1\"; printf \"-\n\" | input::float \"\" \"\" 1 >/dev/null" _ "$1" 2>/dev/null' _ "${TARGET}"


eq "number alias integer" \
    "8" \
    "$(run_no_tty 'printf "8\n" | input::number')"

eq "number alias float" \
    "8.5" \
    "$(run_no_tty 'printf "8.5\n" | input::number')"

eq "number alias leading dot" \
    ".8" \
    "$(run_no_tty 'printf ".8\n" | input::number')"

no "number alias rejects alpha" \
    bash -c 'source "$1"; setsid bash -c "source \"\$1\"; printf \"abc\n\" | input::number \"\" \"\" 1 >/dev/null" _ "$1" 2>/dev/null' _ "${TARGET}"

echo
echo "== input::char / required / match / select tests =="

eq "char accepts ascii" \
    "a" \
    "$(run_no_tty 'printf "a\n" | input::char')"

eq "char accepts star" \
    "*" \
    "$(run_no_tty 'printf "*\n" | input::char')"

eq "char accepts digit" \
    "7" \
    "$(run_no_tty 'printf "7\n" | input::char')"

eq "char accepts arabic glyph" \
    "ش" \
    "$(run_no_tty 'printf "ش\n" | input::char')"

eq "char default" \
    "Z" \
    "$(run_no_tty 'printf "\n" | input::char "" "Z" 1')"

no "char rejects empty without default" \
    bash -c 'source "$1"; setsid bash -c "source \"\$1\"; printf \"\n\" | input::char \"\" \"\" 1 >/dev/null" _ "$1" 2>/dev/null' _ "${TARGET}"

no "char rejects multi ascii" \
    bash -c 'source "$1"; setsid bash -c "source \"\$1\"; printf \"ab\n\" | input::char \"\" \"\" 1 >/dev/null" _ "$1" 2>/dev/null' _ "${TARGET}"

no "char rejects multi words" \
    bash -c 'source "$1"; setsid bash -c "source \"\$1\"; printf \"hello\n\" | input::char \"\" \"\" 1 >/dev/null" _ "$1" 2>/dev/null' _ "${TARGET}"


eq "required accepts value" \
    "Core Master" \
    "$(run_no_tty 'printf "Core Master\n" | input::required')"

eq "required preserves spaces" \
    "  Core Master  " \
    "$(run_no_tty 'printf "  Core Master  \n" | input::required')"

eq "required default" \
    "DEF" \
    "$(run_no_tty 'printf "\n" | input::required "" "DEF" 1')"

eq "required retries then success" \
    "ok" \
    "$(run_no_tty 'printf "\n\nok\n" | input::required "" "" 3')"

no "required rejects empty after tries" \
    bash -c 'source "$1"; setsid bash -c "source \"\$1\"; printf \"\n\n\n\" | input::required \"\" \"\" 2 >/dev/null" _ "$1" 2>/dev/null' _ "${TARGET}"


eq "match accepts slug" \
    "hi-there-123" \
    "$(run_no_tty 'printf "hi-there-123\n" | input::match "" "^[a-z0-9-]+$"')"

eq "match accepts email-ish" \
    "a@test.com" \
    "$(run_no_tty 'printf "a@test.com\n" | input::match "" "^[^@[:space:]]+@[^@[:space:]]+[.][^@[:space:]]+$"')"

eq "match default valid" \
    "abc123" \
    "$(run_no_tty 'printf "\n" | input::match "" "^[a-z]+[0-9]+$" "abc123" 1')"

eq "match retries then success" \
    "abc123" \
    "$(run_no_tty 'printf "BAD!\nabc123\n" | input::match "" "^[a-z]+[0-9]+$" "" 2')"

no "match rejects invalid after tries" \
    bash -c 'source "$1"; setsid bash -c "source \"\$1\"; printf \"bad!\nwrong!\n\" | input::match \"\" \"^[a-z]+[0-9]+$\" \"\" 2 >/dev/null" _ "$1" 2>/dev/null' _ "${TARGET}"

no "match empty pattern fails" \
    input::match "" ""


eq "select picks first" \
    "dev" \
    "$(run_no_tty 'printf "1\n" | input::select "Pick:" 1 dev stage prod')"

eq "select picks middle" \
    "stage" \
    "$(run_no_tty 'printf "2\n" | input::select "Pick:" 1 dev stage prod')"

eq "select picks last" \
    "prod" \
    "$(run_no_tty 'printf "3\n" | input::select "Pick:" 1 dev stage prod')"

eq "select retries then success" \
    "stage" \
    "$(run_no_tty 'printf "9\n0\n2\n" | input::select "Pick:" 3 dev stage prod')"

eq "select supports spaces" \
    "two words" \
    "$(run_no_tty 'printf "2\n" | input::select "Pick:" 1 one "two words" three')"

eq "select supports empty item" \
    "" \
    "$(run_no_tty 'printf "2\n" | input::select "Pick:" 1 one "" three')"

eq "select supports star" \
    "*" \
    "$(run_no_tty 'printf "2\n" | input::select "Pick:" 1 one "*" three')"

no "select missing items fails" \
    input::select "Pick:" 1

no "select invalid choice fails after tries" \
    bash -c 'source "$1"; setsid bash -c "source \"\$1\"; printf \"9\n8\n\" | input::select \"Pick:\" 2 dev stage >/dev/null" _ "$1" 2>/dev/null' _ "${TARGET}"

no "select non-number fails after tries" \
    bash -c 'source "$1"; setsid bash -c "source \"\$1\"; printf \"x\ny\n\" | input::select \"Pick:\" 2 dev stage >/dev/null" _ "$1" 2>/dev/null' _ "${TARGET}"

echo
echo "== input::path / file / dir tests =="

tmp_dir="$(mktemp -d)"
tmp_file="${tmp_dir}/file.txt"
tmp_exec="${tmp_dir}/run.sh"
tmp_missing="${tmp_dir}/missing"
tmp_space_file="${tmp_dir}/file with spaces.txt"
tmp_space_dir="${tmp_dir}/dir with spaces"

mkdir -p "${tmp_space_dir}"
printf 'data\n' > "${tmp_file}"
printf 'space data\n' > "${tmp_space_file}"
printf '#!/usr/bin/env bash\nexit 0\n' > "${tmp_exec}"
chmod +x "${tmp_exec}"

eq "path any accepts missing" \
    "${tmp_missing}" \
    "$(run_no_tty "printf '%s\n' '${tmp_missing}' | input::path '' '' any 1")"

eq "path exists accepts file" \
    "${tmp_file}" \
    "$(run_no_tty "printf '%s\n' '${tmp_file}' | input::path '' '' exists 1")"

eq "path exists accepts dir" \
    "${tmp_dir}" \
    "$(run_no_tty "printf '%s\n' '${tmp_dir}' | input::path '' '' exists 1")"

eq "path file accepts file" \
    "${tmp_file}" \
    "$(run_no_tty "printf '%s\n' '${tmp_file}' | input::path '' '' file 1")"

eq "path dir accepts dir" \
    "${tmp_dir}" \
    "$(run_no_tty "printf '%s\n' '${tmp_dir}' | input::path '' '' dir 1")"

eq "path readable accepts file" \
    "${tmp_file}" \
    "$(run_no_tty "printf '%s\n' '${tmp_file}' | input::path '' '' readable 1")"

eq "path writable accepts dir" \
    "${tmp_dir}" \
    "$(run_no_tty "printf '%s\n' '${tmp_dir}' | input::path '' '' writable 1")"

eq "path executable accepts executable" \
    "${tmp_exec}" \
    "$(run_no_tty "printf '%s\n' '${tmp_exec}' | input::path '' '' executable 1")"

eq "path supports file with spaces" \
    "${tmp_space_file}" \
    "$(run_no_tty "printf '%s\n' '${tmp_space_file}' | input::path '' '' file 1")"

eq "path supports dir with spaces" \
    "${tmp_space_dir}" \
    "$(run_no_tty "printf '%s\n' '${tmp_space_dir}' | input::path '' '' dir 1")"

eq "path empty input uses valid default" \
    "${tmp_file}" \
    "$(run_no_tty "printf '\n' | input::path '' '${tmp_file}' file 1")"

eq "path retries then success" \
    "${tmp_file}" \
    "$(run_no_tty "printf '%s\n%s\n' '${tmp_missing}' '${tmp_file}' | input::path '' '' file 2")"

no "path invalid mode fails" \
    input::path "" "" bad 1

no "path empty fails" \
    bash -c 'source "$1"; setsid bash -c "source \"\$1\"; printf \"\n\" | input::path \"\" \"\" any 1 >/dev/null" _ "$1" 2>/dev/null' _ "${TARGET}"

no "path file rejects missing" \
    bash -c 'source "$1"; setsid bash -c "source \"\$1\"; printf \"%s\n\" \"\$2\" | input::path \"\" \"\" file 1 >/dev/null" _ "$1" "$2" 2>/dev/null' _ "${TARGET}" "${tmp_missing}"

no "path file rejects dir" \
    bash -c 'source "$1"; setsid bash -c "source \"\$1\"; printf \"%s\n\" \"\$2\" | input::path \"\" \"\" file 1 >/dev/null" _ "$1" "$2" 2>/dev/null' _ "${TARGET}" "${tmp_dir}"

no "path dir rejects file" \
    bash -c 'source "$1"; setsid bash -c "source \"\$1\"; printf \"%s\n\" \"\$2\" | input::path \"\" \"\" dir 1 >/dev/null" _ "$1" "$2" 2>/dev/null' _ "${TARGET}" "${tmp_file}"

no "path exists rejects missing" \
    bash -c 'source "$1"; setsid bash -c "source \"\$1\"; printf \"%s\n\" \"\$2\" | input::path \"\" \"\" exists 1 >/dev/null" _ "$1" "$2" 2>/dev/null' _ "${TARGET}" "${tmp_missing}"

no "path executable rejects normal file" \
    bash -c 'source "$1"; setsid bash -c "source \"\$1\"; printf \"%s\n\" \"\$2\" | input::path \"\" \"\" executable 1 >/dev/null" _ "$1" "$2" 2>/dev/null' _ "${TARGET}" "${tmp_file}"

eq "file wrapper accepts file" \
    "${tmp_file}" \
    "$(run_no_tty "printf '%s\n' '${tmp_file}' | input::file '' '' 1")"

eq "file wrapper supports default" \
    "${tmp_file}" \
    "$(run_no_tty "printf '\n' | input::file '' '${tmp_file}' 1")"

eq "file wrapper retries then success" \
    "${tmp_file}" \
    "$(run_no_tty "printf '%s\n%s\n' '${tmp_missing}' '${tmp_file}' | input::file '' '' 2")"

no "file wrapper rejects dir" \
    bash -c 'source "$1"; setsid bash -c "source \"\$1\"; printf \"%s\n\" \"\$2\" | input::file \"\" \"\" 1 >/dev/null" _ "$1" "$2" 2>/dev/null' _ "${TARGET}" "${tmp_dir}"

no "file wrapper rejects missing" \
    bash -c 'source "$1"; setsid bash -c "source \"\$1\"; printf \"%s\n\" \"\$2\" | input::file \"\" \"\" 1 >/dev/null" _ "$1" "$2" 2>/dev/null' _ "${TARGET}" "${tmp_missing}"

eq "dir wrapper accepts dir" \
    "${tmp_dir}" \
    "$(run_no_tty "printf '%s\n' '${tmp_dir}' | input::dir '' '' 1")"

eq "dir wrapper supports default" \
    "${tmp_dir}" \
    "$(run_no_tty "printf '\n' | input::dir '' '${tmp_dir}' 1")"

eq "dir wrapper retries then success" \
    "${tmp_dir}" \
    "$(run_no_tty "printf '%s\n%s\n' '${tmp_missing}' '${tmp_dir}' | input::dir '' '' 2")"

no "dir wrapper rejects file" \
    bash -c 'source "$1"; setsid bash -c "source \"\$1\"; printf \"%s\n\" \"\$2\" | input::dir \"\" \"\" 1 >/dev/null" _ "$1" "$2" 2>/dev/null' _ "${TARGET}" "${tmp_file}"

no "dir wrapper rejects missing" \
    bash -c 'source "$1"; setsid bash -c "source \"\$1\"; printf \"%s\n\" \"\$2\" | input::dir \"\" \"\" 1 >/dev/null" _ "$1" "$2" 2>/dev/null' _ "${TARGET}" "${tmp_missing}"

rm -rf "${tmp_dir}"

echo
echo "== result =="
echo "pass: ${pass}"
echo "fail: ${fail}"

(( fail == 0 ))