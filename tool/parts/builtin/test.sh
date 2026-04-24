#!/usr/bin/env bash
set -Eeuo pipefail

TARGET="${1:-tool/parts/builtin/string.sh}"

PASS=0
FAIL=0
TOTAL=0

red=""
green=""
yellow=""
reset=""

if [[ -t 1 ]]; then
    red=$'\033[31m'
    green=$'\033[32m'
    yellow=$'\033[33m'
    reset=$'\033[0m'
fi

fail () {

    local name="${1-}" want="${2-}" got="${3-}"

    FAIL=$(( FAIL + 1 ))
    TOTAL=$(( TOTAL + 1 ))

    printf '%s[FAIL]%s %s\n' "${red}" "${reset}" "${name}"
    printf '  want: [%s]\n' "${want}"
    printf '  got : [%s]\n' "${got}"

}

pass () {

    local name="${1-}"

    PASS=$(( PASS + 1 ))
    TOTAL=$(( TOTAL + 1 ))

    printf '%s[PASS]%s %s\n' "${green}" "${reset}" "${name}"

}

eq () {

    local name="${1-}" want="${2-}" got="${3-}"

    if [[ "${got}" == "${want}" ]]; then
        pass "${name}"
    else
        fail "${name}" "${want}" "${got}"
    fi

}

ok () {

    local name="${1-}"
    shift || true

    if "$@"; then
        pass "${name}"
    else
        fail "${name}" "exit=0" "exit=$?"
    fi

}

no () {

    local name="${1-}"
    shift || true

    if "$@"; then
        fail "${name}" "exit!=0" "exit=0"
    else
        pass "${name}"
    fi

}

out () {

    "$@"

}

rc () {

    "$@" >/dev/null 2>&1

}

section () {

    printf '\n%s== %s ==%s\n' "${yellow}" "${1-}" "${reset}"

}

if [[ ! -r "${TARGET}" ]]; then
    printf '%s[ERR]%s target not readable: %s\n' "${red}" "${reset}" "${TARGET}" >&2
    exit 2
fi

# shellcheck source=/dev/null
source "${TARGET}"

section "syntax / existence"

for fn in \
    str::len str::lower str::upper str::ltrim str::rtrim str::trim str::chomp \
    str::repeat str::slice str::reverse str::truncate str::normalize \
    str::pad_left str::pad_right str::pad_center str::join_by str::wrap str::quote \
    str::index str::index_ci str::last_index str::last_index_ci str::find str::find_ci \
    str::contains str::contains_ci str::starts_with str::starts_with_ci str::ends_with str::ends_with_ci \
    str::equals str::equals_ci str::count str::lines_count str::first_char str::last_char \
    str::before str::after str::before_last str::after_last str::between str::between_last \
    str::replace str::replace_first str::replace_last str::remove str::remove_first str::remove_last \
    str::remove_prefix str::remove_suffix str::ensure_prefix str::ensure_suffix \
    str::words str::title str::camel str::pascal str::kebab str::snake str::train str::constant str::slug \
    str::capitalize str::uncapitalize str::swapcase str::split str::lines str::indent str::dedent \
    str::is_empty str::is_blank str::is_lower str::is_upper str::is_alpha str::is_digit str::is_alnum \
    str::is_char str::is_int str::is_uint str::is_float str::is_bool str::is_email str::is_url \
    str::is_slug str::is_identifier str::bool str::escape_regex str::escape_sed str::escape_json str::json_quote
do
    ok "function exists: ${fn}" declare -F "${fn}"
done

section "basic transform"

eq "len empty" "0" "$(out str::len "")"
eq "len ascii" "5" "$(out str::len "hello")"
eq "lower" "abcxyz123" "$(out str::lower "ABCxyz123")"
eq "upper" "ABCXYZ123" "$(out str::upper "abcXYZ123")"
eq "trim spaces" "hello" "$(out str::trim "   hello   ")"
eq "ltrim tabs/spaces" "hello  " "$(out str::ltrim $'\t  hello  ')"
eq "rtrim tabs/spaces" "  hello" "$(out str::rtrim $'  hello\t  ')"
eq "chomp LF" "abc" "$(out str::chomp $'abc\n')"
eq "chomp CRLF once" "abc" "$(out str::chomp $'abc\r\n')"

section "repeat / slice / reverse / truncate / normalize"

eq "repeat zero" "" "$(out str::repeat "x" 0)"
eq "repeat one" "x" "$(out str::repeat "x" 1)"
eq "repeat many" "abababab" "$(out str::repeat "ab" 4)"
no "repeat rejects negative" rc str::repeat "x" -1
no "repeat rejects text" rc str::repeat "x" abc

eq "slice from start" "cdef" "$(out str::slice "abcdef" 2)"
eq "slice count" "cde" "$(out str::slice "abcdef" 2 3)"
eq "slice negative" "ef" "$(out str::slice "abcdef" -2)"
no "slice bad start" rc str::slice "abcdef" x
no "slice bad count" rc str::slice "abcdef" 1 -1

eq "reverse empty" "" "$(out str::reverse "")"
eq "reverse ascii" "fedcba" "$(out str::reverse "abcdef")"
eq "truncate short" "abc" "$(out str::truncate "abc" 10)"
eq "truncate exact" "abc" "$(out str::truncate "abc" 3)"
eq "truncate zero" "" "$(out str::truncate "abcdef" 0)"
eq "truncate default tail" "ab..." "$(out str::truncate "abcdef" 5)"
eq "truncate tiny tail clipped" ".." "$(out str::truncate "abcdef" 2 "...")"
eq "normalize spaces" "a b c" "$(out str::normalize $'  a\t b\n c  ')"
eq "normalize custom sep" "a-b-c" "$(out str::normalize $'  a\t b\n c  ' "-")"

section "padding / join / wrap / quote"

eq "pad left" "___x" "$(out str::pad_left "x" 4 "_")"
eq "pad right" "x___" "$(out str::pad_right "x" 4 "_")"
eq "pad center odd" "__x__" "$(out str::pad_center "x" 5 "_")"
eq "pad center even remainder right" "_x__" "$(out str::pad_center "x" 4 "_")"
eq "pad no-op" "hello" "$(out str::pad_left "hello" 3 "_")"
no "pad bad width" rc str::pad_left "x" abc "_"
eq "join none" "" "$(out str::join_by ",")"
eq "join one" "a" "$(out str::join_by "," "a")"
eq "join many" "a,b,c" "$(out str::join_by "," "a" "b" "c")"
eq "wrap symmetric" "[x]" "$(out str::wrap "x" "[ " "]" | sed 's/\[ /\[/')"
eq "wrap same" "**x**" "$(out str::wrap "x" "**")"
ok "quote returns something" rc str::quote "a b"

section "search / compare"

eq "index first" "2" "$(out str::index "abcdef" "cd")"
eq "index empty needle" "0" "$(out str::index "abc" "")"
no "index miss rc" rc str::index "abc" "z"
eq "index_ci" "2" "$(out str::index_ci "abCDef" "cd")"
eq "last_index" "4" "$(out str::last_index "ababa" "a")"
eq "last_index empty needle" "3" "$(out str::last_index "abc" "")"
no "last_index miss rc" rc str::last_index "abc" "z"
eq "last_index_ci" "4" "$(out str::last_index_ci "abAba" "A")"

ok "contains" rc str::contains "hello world" "world"
no "contains empty needle false" rc str::contains "hello" ""
no "contains miss" rc str::contains "hello" "WORLD"
ok "contains_ci" rc str::contains_ci "hello world" "WORLD"

ok "starts_with" rc str::starts_with "foobar" "foo"
no "starts_with empty false" rc str::starts_with "foobar" ""
no "starts_with miss" rc str::starts_with "foobar" "bar"
ok "starts_with_ci" rc str::starts_with_ci "FooBar" "foo"

ok "ends_with" rc str::ends_with "foobar" "bar"
no "ends_with empty false" rc str::ends_with "foobar" ""
no "ends_with miss" rc str::ends_with "foobar" "foo"
ok "ends_with_ci" rc str::ends_with_ci "FooBar" "BAR"

ok "equals" rc str::equals "a" "a"
no "equals miss" rc str::equals "a" "A"
ok "equals_ci" rc str::equals_ci "a" "A"

section "count / lines / char"

eq "count non-overlap" "2" "$(out str::count "aaaa" "aa")"
eq "count miss" "0" "$(out str::count "aaaa" "b")"
eq "count empty needle" "0" "$(out str::count "aaaa" "")"
eq "lines_count empty" "0" "$(out str::lines_count "")"
eq "lines_count one" "1" "$(out str::lines_count "a")"
eq "lines_count two" "2" "$(out str::lines_count $'a\nb')"
eq "first_char empty" "" "$(out str::first_char "")"
eq "first_char" "a" "$(out str::first_char "abc")"
eq "last_char empty" "" "$(out str::last_char "")"
eq "last_char" "c" "$(out str::last_char "abc")"

section "before / after / between"

eq "before hit" "abc" "$(out str::before "abc:def:ghi" ":")"
eq "before miss returns original" "abcdef" "$(out str::before "abcdef" ":")"
eq "before empty delimiter returns original" "abcdef" "$(out str::before "abcdef" "")"
eq "after hit" "def:ghi" "$(out str::after "abc:def:ghi" ":")"
no "after miss rc" rc str::after "abcdef" ":"
no "after empty delimiter rc" rc str::after "abcdef" ""
eq "before_last hit" "abc:def" "$(out str::before_last "abc:def:ghi" ":")"
eq "after_last hit" "ghi" "$(out str::after_last "abc:def:ghi" ":")"
eq "between hit" "middle" "$(out str::between "aa[middle]bb" "[" "]")"
eq "between_last hit" "d" "$(out str::between_last "a<b> c <d>" "<" ">")"

section "replace / remove / prefix / suffix"

eq "replace all simple" "xx-bb-xx" "$(out str::replace "aa-bb-aa" "aa" "xx")"
eq "replace first simple" "xx-bb-aa" "$(out str::replace_first "aa-bb-aa" "aa" "xx")"
eq "replace last simple" "aa-bb-xx" "$(out str::replace_last "aa-bb-aa" "aa" "xx")"

# These are intentionally brutal: string replacement should be literal, not glob-pattern replacement.
eq "replace literal star" "aXb" "$(out str::replace "a*b" "*" "X")"
eq "replace literal question" "aXb" "$(out str::replace "a?b" "?" "X")"
eq "replace literal bracket" "aXb" "$(out str::replace "a[b" "[" "X")"

eq "remove all" "bb-aa" "$(out str::remove "aa-bb-aa" "aa-")"
eq "remove first" "bb-aa" "$(out str::remove_first "aa-bb-aa" "aa-")"
eq "remove last" "aa-bb" "$(out str::remove_last "aa-bb-aa" "-aa")"
eq "remove_prefix hit" "bar" "$(out str::remove_prefix "foobar" "foo")"
eq "remove_prefix miss" "foobar" "$(out str::remove_prefix "foobar" "bar")"
eq "remove_suffix hit" "foo" "$(out str::remove_suffix "foobar" "bar")"
eq "remove_suffix miss" "foobar" "$(out str::remove_suffix "foobar" "foo")"
eq "ensure_prefix hit" "foobar" "$(out str::ensure_prefix "foobar" "foo")"
eq "ensure_prefix miss" "bar" "$(out str::ensure_prefix "bar" "")"
eq "ensure_prefix add" "foobar" "$(out str::ensure_prefix "bar" "foo")"
eq "ensure_suffix hit" "foobar" "$(out str::ensure_suffix "foobar" "bar")"
eq "ensure_suffix add" "foobar" "$(out str::ensure_suffix "foo" "bar")"

section "case conversions"

eq "words camel acronym" $'http\nserver\nid' "$(out str::words "HTTPServerID")"
eq "words mixed" $'hello\nworld\n42\nx' "$(out str::words "helloWorld42X")"
eq "title" "Hello World 42" "$(out str::title "hello_world-42")"
eq "camel" "helloWorld42" "$(out str::camel "hello_world-42")"
eq "pascal" "HelloWorld42" "$(out str::pascal "hello_world-42")"
eq "kebab" "hello-world-42" "$(out str::kebab "hello_world-42")"
eq "snake" "hello_world_42" "$(out str::snake "hello-world-42")"
eq "train" "Hello-World-42" "$(out str::train "hello_world-42")"
eq "constant" "HELLO_WORLD_42" "$(out str::constant "hello-world-42")"
eq "slug alias" "hello-world" "$(out str::slug "hello_world")"
eq "capitalize" "Hello" "$(out str::capitalize "hello")"
eq "uncapitalize" "hello" "$(out str::uncapitalize "Hello")"
eq "swapcase" "aBc123" "$(out str::swapcase "AbC123")"

section "split / lines / indent / dedent"

eq "split simple" $'a\nb\nc' "$(out str::split "a,b,c" ",")"
eq "split keeps empty middle" $'a\n\nb' "$(out str::split "a,,b" ",")"

split_tail=()
mapfile -t split_tail < <(str::split "a," ",")

eq "split keeps empty tail len" "2" "${#split_tail[@]}"
eq "split keeps empty tail first" "a" "${split_tail[0]}"
eq "split keeps empty tail second" "" "${split_tail[1]}"

no "split empty sep rc" rc str::split "abc" ""
eq "lines empty" "" "$(out str::lines "")"
eq "lines one" "abc" "$(out str::lines "abc")"
eq "indent multi" $'> a\n> b' "$(out str::indent $'a\nb' "> ")"
eq "dedent simple" $'a\n  b' "$(out str::dedent $'    a\n      b')"
eq "dedent blank lines" $'\na\n  b' "$(out str::dedent $'\n    a\n      b')"

section "predicates"

ok "is_empty true" rc str::is_empty ""
no "is_empty false" rc str::is_empty " "
ok "is_blank empty" rc str::is_blank ""
ok "is_blank spaces" rc str::is_blank $' \t\n'
no "is_blank false" rc str::is_blank " x "

ok "is_lower" rc str::is_lower "a"
no "is_lower multi false" rc str::is_lower "ab"
ok "is_upper" rc str::is_upper "A"
ok "is_alpha lower" rc str::is_alpha "z"
ok "is_alpha upper" rc str::is_alpha "Z"
no "is_alpha digit false" rc str::is_alpha "1"
ok "is_digit" rc str::is_digit "9"
ok "is_alnum alpha" rc str::is_alnum "a"
ok "is_alnum digit" rc str::is_alnum "1"
no "is_alnum symbol false" rc str::is_alnum "_"
ok "is_char one" rc str::is_char "x"
no "is_char empty false" rc str::is_char ""
no "is_char many false" rc str::is_char "xy"

ok "is_int positive" rc str::is_int "+123"
ok "is_int negative" rc str::is_int "-123"
no "is_int float false" rc str::is_int "1.2"
ok "is_uint zero" rc str::is_uint "0"
no "is_uint signed false" rc str::is_uint "+1"
ok "is_float int-compatible" rc str::is_float "1"
ok "is_float decimal" rc str::is_float "-1.25"
ok "is_float leading dot" rc str::is_float ".25"
ok "is_float trailing dot" rc str::is_float "1."
no "is_float bad false" rc str::is_float "."
ok "is_bool true" rc str::is_bool "ON"
no "is_bool false input" rc str::is_bool "maybe"
ok "is_email simple" rc str::is_email "a.b+c@example.co"
no "is_email bad false" rc str::is_email "a@b"
ok "is_url http" rc str::is_url "http://example.com/a?b=c"
ok "is_url https" rc str::is_url "https://example.com"
no "is_url ftp false" rc str::is_url "ftp://example.com"
ok "is_slug" rc str::is_slug "abc-123-x"
no "is_slug uppercase false" rc str::is_slug "Abc"
ok "is_identifier" rc str::is_identifier "_abc123"
no "is_identifier leading digit false" rc str::is_identifier "1abc"

section "bool conversion"

eq "bool true" "true" "$(out str::bool "yes")"
eq "bool false" "false" "$(out str::bool "OFF")"
no "bool invalid rc" rc str::bool "maybe"

section "escaping"

eq "escape_sed slash amp backslash" 'a\/b\&c\\d' "$(out str::escape_sed 'a/b&c\d')"

# Regex escaping should make each regex metacharacter literal.
regex_raw='a.b*c+d?e[f]g^h$i(j)k{l}m|n\o'
regex_escaped="$(out str::escape_regex "${regex_raw}")"
if [[ "${regex_raw}" =~ ${regex_escaped} ]]; then
    pass "escape_regex produces matching literal regex"
else
    fail "escape_regex produces matching literal regex" "regex matches raw" "regex did not match"
fi

json_in=$'a"b\\c\b\f\n\r\t'
json_want='a\"b\\c\b\f\n\r\t'
eq "escape_json specials" "${json_want}" "$(out str::escape_json "${json_in}")"

ctrl_in="$(printf 'a\001b')"
ctrl_want='a\u0001b'
eq "escape_json control U+0001" "${ctrl_want}" "$(out str::escape_json "${ctrl_in}")"

eq "json_quote" '"a\"b"' "$(out str::json_quote 'a"b')"

section "properties / invariants"

sample="  HelloWorld-42_test  "

trimmed="$(out str::trim "${sample}")"
eq "property trim idempotent" "${trimmed}" "$(out str::trim "${trimmed}")"

lowered="$(out str::lower "${sample}")"
eq "property lower idempotent" "${lowered}" "$(out str::lower "${lowered}")"

uppered="$(out str::upper "${sample}")"
eq "property upper idempotent" "${uppered}" "$(out str::upper "${uppered}")"

snake="$(out str::snake "${sample}")"
eq "property snake is stable through words" "${snake}" "$(out str::snake "${snake}")"

kebab="$(out str::kebab "${sample}")"
eq "property kebab is stable through words" "${kebab}" "$(out str::kebab "${kebab}")"

section "summary"

printf '\nTOTAL=%s PASS=%s FAIL=%s\n' "${TOTAL}" "${PASS}" "${FAIL}"

if (( FAIL > 0 )); then
    printf '%sBROKEN: fix failures above.%s\n' "${red}" "${reset}" >&2
    exit 1
fi

printf '%sLOCKED: string.sh passed the brutal suite.%s\n' "${green}" "${reset}"
exit 0
