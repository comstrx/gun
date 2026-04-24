#!/usr/bin/env bash
# shellcheck shell=bash

set -u
set -o pipefail

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

    local name="${1:-}" want="${2:-}" got="${3:-}"

    FAIL=$(( FAIL + 1 ))
    TOTAL=$(( TOTAL + 1 ))

    printf '%s[FAIL]%s %s\n' "${red}" "${reset}" "${name}"
    printf '  want: [%s]\n' "${want}"
    printf '  got : [%s]\n' "${got}"

}

pass () {

    local name="${1:-}"

    PASS=$(( PASS + 1 ))
    TOTAL=$(( TOTAL + 1 ))

    printf '%s[PASS]%s %s\n' "${green}" "${reset}" "${name}"

}

eq () {

    local name="${1:-}" want="${2:-}" got="${3:-}"

    if [[ "${got}" == "${want}" ]]; then
        pass "${name}"
    else
        fail "${name}" "${want}" "${got}"
    fi

}

ok () {

    local name="${1:-}"
    shift || true

    if "$@"; then
        pass "${name}"
    else
        fail "${name}" "exit=0" "exit=$?"
    fi

}

no () {

    local name="${1:-}"
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

    printf '\n%s== %s ==%s\n' "${yellow}" "${1:-}" "${reset}"

}

if [[ ! -r "${TARGET}" ]]; then
    printf '%s[ERR]%s target not readable: %s\n' "${red}" "${reset}" "${TARGET}" >&2
    exit 2
fi

# shellcheck source=/dev/null
source "${TARGET}"

section "existence / public api"

required=(
    str::lower str::upper str::ltrim str::rtrim str::trim str::chomp
    str::repeat str::slice str::reverse str::normalize str::truncate
    str::pad_left str::pad_right str::pad_center str::join_by str::wrap str::quote str::bool
    str::index str::last_index str::starts_with str::ends_with str::find str::contains str::equals str::compare
    str::index_icase str::last_index_icase str::starts_with_icase str::ends_with_icase
    str::find_icase str::contains_icase str::equals_icase str::compare_icase
    str::len str::count str::lines_count str::first_char str::last_char
    str::before str::after str::before_last str::after_last str::between str::between_last
    str::replace str::replace_first str::replace_last str::remove str::remove_first str::remove_last
    str::remove_prefix str::remove_suffix str::ensure_prefix str::ensure_suffix
    str::words str::title str::camel str::pascal str::kebab str::snake str::train str::slug
    str::capitalize str::uncapitalize str::constant str::swapcase
    str::split str::lines str::indent str::dedent
    str::is_empty str::is_blank str::is_lower str::is_upper str::is_alpha str::is_digit str::is_alnum
    str::is_char str::is_int str::is_uint str::is_float str::is_bool str::is_email str::is_url
    str::is_slug str::is_identifier str::escape_regex str::escape_sed str::escape_json str::json_quote
)

for fn in "${required[@]}"; do
    ok "function exists: ${fn}" declare -F "${fn}"
done

section "case / trim / newline cleanup"

eq "lower ascii" "abcxyz123!_" "$(out str::lower "ABCxyz123!_")"
eq "upper ascii" "ABCXYZ123!_" "$(out str::upper "abcXYZ123!_")"
eq "ltrim spaces tabs" "abc  " "$(out str::ltrim $' \t  abc  ')"
eq "rtrim spaces tabs" "  abc" "$(out str::rtrim $'  abc \t ')"
eq "trim spaces tabs newlines" "abc" "$(out str::trim $' \t\n abc \r\n ')"
eq "trim all blank" "" "$(out str::trim $' \t\n\r ')"
eq "trim no-op" "abc" "$(out str::trim "abc")"
eq "chomp LF" "abc" "$(out str::chomp $'abc\n')"
eq "chomp CR" "abc" "$(out str::chomp $'abc\r')"
eq "chomp CRLF" "abc" "$(out str::chomp $'abc\r\n')"
eq "chomp LFCR" "abc" "$(out str::chomp $'abc\n\r')"
eq "chomp many trailing" "abc" "$(out str::chomp $'abc\n\r\n\r')"
eq "chomp does not remove internal CRLF" $'a\r\nb' "$(out str::chomp $'a\r\nb\r\n')"

section "repeat / slice / reverse"

eq "repeat zero" "" "$(out str::repeat "x" 0)"
eq "repeat one" "x" "$(out str::repeat "x" 1)"
eq "repeat power pattern" "abababababababab" "$(out str::repeat "ab" 8)"
eq "repeat empty string" "" "$(out str::repeat "" 10)"
no "repeat rejects negative" rc str::repeat "x" -1
no "repeat rejects plus" rc str::repeat "x" +1
no "repeat rejects text" rc str::repeat "x" abc

eq "slice no count" "cdef" "$(out str::slice "abcdef" 2)"
eq "slice count" "cde" "$(out str::slice "abcdef" 2 3)"
eq "slice count zero" "" "$(out str::slice "abcdef" 2 0)"
eq "slice negative offset" "ef" "$(out str::slice "abcdef" -2)"
eq "slice start zero" "abc" "$(out str::slice "abcdef" 0 3)"
eq "slice beyond end" "" "$(out str::slice "abc" 99)"
no "slice rejects bad start" rc str::slice "abc" x
no "slice rejects bad count negative" rc str::slice "abc" 1 -1
no "slice rejects bad count text" rc str::slice "abc" 1 x

eq "reverse empty" "" "$(out str::reverse "")"
eq "reverse one" "a" "$(out str::reverse "a")"
eq "reverse ascii" "fedcba" "$(out str::reverse "abcdef")"
eq "reverse punctuation" "c_b-a" "$(out str::reverse "a-b_c")"

section "normalize / truncate"

eq "normalize spaces" "a b c" "$(out str::normalize $'  a\t  b\n c  ')"
eq "normalize custom dash" "a-b-c" "$(out str::normalize $'  a\t  b\n c  ' "-")"
eq "normalize custom multi uses first char" "a_x_y" "$(out str::normalize $'a x y' "_SEP")"
eq "normalize empty" "" "$(out str::normalize "")"
eq "normalize blank" "" "$(out str::normalize $' \t\n ')"
eq "truncate shorter" "abc" "$(out str::truncate "abc" 9)"
eq "truncate exact" "abc" "$(out str::truncate "abc" 3)"
eq "truncate default" "ab..." "$(out str::truncate "abcdef" 5)"
eq "truncate custom tail" "ab--" "$(out str::truncate "abcdef" 4 "--")"
eq "truncate tail longer than max" ".." "$(out str::truncate "abcdef" 2 "...")"
eq "truncate max zero" "" "$(out str::truncate "abcdef" 0)"
eq "truncate empty" "" "$(out str::truncate "" 5)"
no "truncate rejects negative max" rc str::truncate "abc" -1
no "truncate rejects text max" rc str::truncate "abc" abc

section "padding / join / wrapping / quote / bool"

eq "pad_left zero" "7" "$(out str::pad_left "7" 0 "0")"
eq "pad_left number" "007" "$(out str::pad_left "7" 3 "0")"
eq "pad_left no-op" "abcdef" "$(out str::pad_left "abcdef" 3 "0")"
eq "pad_left multi char uses first" "aaax" "$(out str::pad_left "x" 4 "abc")"
eq "pad_left empty ch becomes space" "  x" "$(out str::pad_left "x" 3 "")"
eq "pad_right number" "700" "$(out str::pad_right "7" 3 "0")"
eq "pad_right no-op" "abcdef" "$(out str::pad_right "abcdef" 3 "0")"
eq "pad_right multi char uses first" "xaaa" "$(out str::pad_right "x" 4 "abc")"
eq "pad_center odd" "__x__" "$(out str::pad_center "x" 5 "_")"
eq "pad_center even remainder right" "_x__" "$(out str::pad_center "x" 4 "_")"
eq "pad_center no-op" "abcdef" "$(out str::pad_center "abcdef" 3 "_")"
no "pad_left rejects bad width" rc str::pad_left "x" abc "_"
no "pad_right rejects bad width" rc str::pad_right "x" abc "_"
no "pad_center rejects bad width" rc str::pad_center "x" abc "_"
eq "join no args" "" "$(out str::join_by ",")"
eq "join one" "a" "$(out str::join_by "," "a")"
eq "join three" "a,b,c" "$(out str::join_by "," "a" "b" "c")"
eq "join empty values" "a,,c" "$(out str::join_by "," "a" "" "c")"
eq "join multi separator" "a::b::c" "$(out str::join_by "::" "a" "b" "c")"
eq "wrap same" "**x**" "$(out str::wrap "x" "**")"
eq "wrap different" "[x]" "$(out str::wrap "x" "[" "]")"
eq "wrap empty" "[]" "$(out str::wrap "" "[" "]")"
ok "quote spaces returns success" rc str::quote "a b"
eq "bool true on" "true" "$(out str::bool "ON")"
eq "bool false off" "false" "$(out str::bool "off")"
no "bool rejects maybe" rc str::bool "maybe"
no "bool rejects empty" rc str::bool ""

section "search / compare exact"

eq "index first" "2" "$(out str::index "abcdef" "cd")"
eq "index start hit zero" "0" "$(out str::index "abcdef" "ab")"
eq "index empty needle zero" "0" "$(out str::index "abc" "")"
eq "index repeated first" "0" "$(out str::index "aaaa" "aa")"
no "index miss" rc str::index "abcdef" "zz"
no "index longer needle miss" rc str::index "abc" "abcdef"
eq "last_index last" "4" "$(out str::last_index "ababa" "a")"
eq "last_index needle" "2" "$(out str::last_index "abcabc" "ca")"
eq "last_index empty needle len" "3" "$(out str::last_index "abc" "")"
no "last_index miss" rc str::last_index "abc" "z"
eq "find alias" "2" "$(out str::find "abcdef" "cd")"
ok "contains hit" rc str::contains "hello-world" "world"
no "contains miss" rc str::contains "hello-world" "WORLD"
no "contains empty needle false" rc str::contains "hello" ""
ok "starts_with hit" rc str::starts_with "foobar" "foo"
no "starts_with miss" rc str::starts_with "foobar" "bar"
no "starts_with empty false" rc str::starts_with "foobar" ""
ok "ends_with hit" rc str::ends_with "foobar" "bar"
no "ends_with miss" rc str::ends_with "foobar" "foo"
no "ends_with empty false" rc str::ends_with "foobar" ""
ok "equals hit" rc str::equals "abc" "abc"
no "equals miss" rc str::equals "abc" "ABC"
eq "compare equal" "0" "$(out str::compare "abc" "abc")"
eq "compare less" "-1" "$(out str::compare "abc" "abd")"
eq "compare greater" "1" "$(out str::compare "abd" "abc")"

section "search / compare icase"

eq "index_icase hit" "5" "$(out str::index_icase "HelloWorld" "WORLD")"
eq "index_icase empty needle" "0" "$(out str::index_icase "HelloWorld" "")"
no "index_icase miss" rc str::index_icase "HelloWorld" "ZZ"
eq "last_index_icase hit" "4" "$(out str::last_index_icase "abAba" "A")"
eq "find_icase hit" "5" "$(out str::find_icase "HelloWorld" "WORLD")"
ok "contains_icase hit" rc str::contains_icase "HelloWorld" "WORLD"
ok "contains_icase lowercase hit" rc str::contains_icase "HelloWorld" "world"
no "contains_icase empty false" rc str::contains_icase "HelloWorld" ""
no "contains_icase miss" rc str::contains_icase "HelloWorld" "ZZZ"
ok "starts_with_icase hit" rc str::starts_with_icase "FooBar" "foo"
no "starts_with_icase miss" rc str::starts_with_icase "FooBar" "bar"
ok "ends_with_icase hit" rc str::ends_with_icase "FooBar" "BAR"
no "ends_with_icase miss" rc str::ends_with_icase "FooBar" "FOO"
ok "equals_icase hit" rc str::equals_icase "Gun" "gUN"
no "equals_icase miss" rc str::equals_icase "Gun" "gUNx"
eq "compare_icase equal" "0" "$(out str::compare_icase "AbC" "aBc")"
eq "compare_icase less" "-1" "$(out str::compare_icase "abc" "ABD")"
eq "compare_icase greater" "1" "$(out str::compare_icase "ABD" "abc")"

section "length / count / chars"

eq "len empty" "0" "$(out str::len "")"
eq "len ascii" "5" "$(out str::len "hello")"
eq "count empty needle" "0" "$(out str::count "aaaa" "")"
eq "count miss" "0" "$(out str::count "aaaa" "b")"
eq "count non-overlap aa in aaaa" "2" "$(out str::count "aaaa" "aa")"
eq "count separator" "2" "$(out str::count "a,b,c" ",")"
eq "count newline" "2" "$(out str::count $'a\nb\nc' $'\n')"
eq "lines_count empty" "0" "$(out str::lines_count "")"
eq "lines_count one" "1" "$(out str::lines_count "a")"
eq "lines_count two" "2" "$(out str::lines_count $'a\nb')"
eq "lines_count trailing newline" "2" "$(out str::lines_count $'a\n')"
eq "first_char empty" "" "$(out str::first_char "")"
eq "first_char normal" "a" "$(out str::first_char "abc")"
eq "last_char empty" "" "$(out str::last_char "")"
eq "last_char normal" "c" "$(out str::last_char "abc")"

section "before / after / between"

eq "before first delimiter" "abc" "$(out str::before "abc:def:ghi" ":")"
eq "before miss returns original" "abcdef" "$(out str::before "abcdef" ":")"
eq "before empty delimiter returns original" "abcdef" "$(out str::before "abcdef" "")"
eq "after first delimiter" "def:ghi" "$(out str::after "abc:def:ghi" ":")"
no "after miss fails" rc str::after "abcdef" ":"
no "after empty delimiter fails" rc str::after "abcdef" ""
eq "before_last delimiter" "abc:def" "$(out str::before_last "abc:def:ghi" ":")"
eq "before_last miss original" "abcdef" "$(out str::before_last "abcdef" ":")"
eq "after_last delimiter" "ghi" "$(out str::after_last "abc:def:ghi" ":")"
no "after_last miss fails" rc str::after_last "abcdef" ":"
eq "between simple" "middle" "$(out str::between "aa[middle]bb" "[" "]")"
eq "between last" "d" "$(out str::between_last "a<b> c <d>" "<" ">")"
no "between missing left fails" rc str::between "abc" "[" "]"
eq "between missing right returns rest" "middle" "$(out str::between "aa[middle" "[" "]")"

section "replace / remove / affixes"

eq "replace all simple" "xx-bb-xx" "$(out str::replace "aa-bb-aa" "aa" "xx")"
eq "replace first simple" "xx-bb-aa" "$(out str::replace_first "aa-bb-aa" "aa" "xx")"
eq "replace last simple" "aa-bb-xx" "$(out str::replace_last "aa-bb-aa" "aa" "xx")"
eq "replace empty from no-op" "abc" "$(out str::replace "abc" "" "x")"
eq "replace_first empty from no-op" "abc" "$(out str::replace_first "abc" "" "x")"
eq "replace_last empty from no-op" "abc" "$(out str::replace_last "abc" "" "x")"
eq "replace literal star" "aXb" "$(out str::replace "a*b" "*" "X")"
eq "replace literal question" "aXb" "$(out str::replace "a?b" "?" "X")"
eq "replace literal bracket" "aXb" "$(out str::replace "a[b" "[" "X")"
eq "replace literal slash" "aXb" "$(out str::replace "a/b" "/" "X")"
eq "remove all" "bb-aa" "$(out str::remove "aa-bb-aa" "aa-")"
eq "remove first" "bb-aa" "$(out str::remove_first "aa-bb-aa" "aa-")"
eq "remove last" "aa-bb" "$(out str::remove_last "aa-bb-aa" "-aa")"
eq "remove_prefix hit" "bar" "$(out str::remove_prefix "foobar" "foo")"
eq "remove_prefix miss" "foobar" "$(out str::remove_prefix "foobar" "bar")"
eq "remove_prefix empty no-op" "foobar" "$(out str::remove_prefix "foobar" "")"
eq "remove_suffix hit" "foo" "$(out str::remove_suffix "foobar" "bar")"
eq "remove_suffix miss" "foobar" "$(out str::remove_suffix "foobar" "foo")"
eq "remove_suffix empty no-op" "foobar" "$(out str::remove_suffix "foobar" "")"
eq "ensure_prefix hit" "foobar" "$(out str::ensure_prefix "foobar" "foo")"
eq "ensure_prefix add" "foobar" "$(out str::ensure_prefix "bar" "foo")"
eq "ensure_prefix empty no-op" "bar" "$(out str::ensure_prefix "bar" "")"
eq "ensure_suffix hit" "foobar" "$(out str::ensure_suffix "foobar" "bar")"
eq "ensure_suffix add" "foobar" "$(out str::ensure_suffix "foo" "bar")"
eq "ensure_suffix empty no-op" "foo" "$(out str::ensure_suffix "foo" "")"

section "words / naming conversions"

eq "words empty" "" "$(out str::words "")"
eq "words separators" $'hello\nworld\n42' "$(out str::words "hello_world-42")"
eq "words camel acronym" $'http\nserver\nid' "$(out str::words "HTTPServerID")"
eq "words mixed digits split" $'hello\nworld\n42\nx' "$(out str::words "helloWorld42X")"
eq "words consecutive separators" $'a\nb' "$(out str::words "__a--b__")"
eq "title" "Hello World 42" "$(out str::title "hello_world-42")"
eq "camel" "helloWorld42" "$(out str::camel "hello_world-42")"
eq "pascal" "HelloWorld42" "$(out str::pascal "hello_world-42")"
eq "kebab" "hello-world-42" "$(out str::kebab "hello_world-42")"
eq "snake" "hello_world_42" "$(out str::snake "hello-world-42")"
eq "train" "Hello-World-42" "$(out str::train "hello_world-42")"
eq "slug alias" "hello-world-42" "$(out str::slug "hello_world-42")"
eq "constant" "HELLO_WORLD_42" "$(out str::constant "hello-world-42")"
eq "capitalize empty" "" "$(out str::capitalize "")"
eq "capitalize word" "Hello" "$(out str::capitalize "hello")"
eq "uncapitalize empty" "" "$(out str::uncapitalize "")"
eq "uncapitalize word" "hello" "$(out str::uncapitalize "Hello")"
eq "swapcase ascii" "aBc123_X" "$(out str::swapcase "AbC123_x")"

section "split / lines / indent / dedent"

eq "split simple" $'a\nb\nc' "$(out str::split "a,b,c" ",")"
eq "split keeps empty middle" $'a\n\nb' "$(out str::split "a,,b" ",")"
split_tail=()
mapfile -t split_tail < <(str::split "a," ",")
eq "split keeps empty tail len" "2" "${#split_tail[@]}"
eq "split keeps empty tail first" "a" "${split_tail[0]}"
eq "split keeps empty tail second" "" "${split_tail[1]}"
split_head=()
mapfile -t split_head < <(str::split ",a" ",")
eq "split keeps empty head len" "2" "${#split_head[@]}"
eq "split keeps empty head first" "" "${split_head[0]}"
eq "split keeps empty head second" "a" "${split_head[1]}"
split_empty=()
mapfile -t split_empty < <(str::split "" ",")
eq "split empty input emits one empty field" "1" "${#split_empty[@]}"
eq "split empty input field empty" "" "${split_empty[0]}"
no "split empty separator fails" rc str::split "abc" ""
eq "lines empty" "" "$(out str::lines "")"
eq "lines one" "abc" "$(out str::lines "abc")"
eq "lines multi command-substitution strips final newline" $'a\nb' "$(out str::lines $'a\nb')"
eq "indent empty" "" "$(out str::indent "" "> ")"
eq "indent one" "> a" "$(out str::indent "a" "> ")"
eq "indent multi" $'> a\n> b' "$(out str::indent $'a\nb' "> ")"
eq "indent preserves middle empty" $'> a\n> \n> b' "$(out str::indent $'a\n\nb' "> ")"
eq "dedent empty" "" "$(out str::dedent "")"
eq "dedent simple" $'a\n  b' "$(out str::dedent $'    a\n      b')"
eq "dedent blank lines" $'\na\n  b' "$(out str::dedent $'\n    a\n      b')"
eq "dedent no indent" $'a\nb' "$(out str::dedent $'a\nb')"

section "predicates"
ok "is_empty empty" rc str::is_empty ""
no "is_empty space false" rc str::is_empty " "
ok "is_blank empty" rc str::is_blank ""
ok "is_blank spaces tabs newlines" rc str::is_blank $' \t\n'
no "is_blank text false" rc str::is_blank " x "
ok "is_lower a" rc str::is_lower "a"
no "is_lower A false" rc str::is_lower "A"
no "is_lower multi false" rc str::is_lower "ab"
no "is_lower empty false" rc str::is_lower ""
ok "is_upper A" rc str::is_upper "A"
no "is_upper a false" rc str::is_upper "a"
no "is_upper multi false" rc str::is_upper "AB"
ok "is_alpha lower" rc str::is_alpha "z"
ok "is_alpha upper" rc str::is_alpha "Z"
no "is_alpha digit false" rc str::is_alpha "1"
no "is_alpha underscore false" rc str::is_alpha "_"
ok "is_digit" rc str::is_digit "9"
no "is_digit letter false" rc str::is_digit "a"
no "is_digit multi false" rc str::is_digit "12"
ok "is_alnum letter" rc str::is_alnum "a"
ok "is_alnum digit" rc str::is_alnum "1"
no "is_alnum symbol false" rc str::is_alnum "_"
ok "is_char one" rc str::is_char "x"
no "is_char empty false" rc str::is_char ""
no "is_char many false" rc str::is_char "xy"
ok "is_int positive" rc str::is_int "+123"
ok "is_int negative" rc str::is_int "-123"
ok "is_int zero" rc str::is_int "0"
no "is_int empty false" rc str::is_int ""
no "is_int float false" rc str::is_int "1.2"
ok "is_uint zero" rc str::is_uint "0"
ok "is_uint number" rc str::is_uint "123"
no "is_uint signed false" rc str::is_uint "+1"
no "is_uint negative false" rc str::is_uint "-1"
ok "is_float int-compatible" rc str::is_float "1"
ok "is_float decimal" rc str::is_float "-1.25"
ok "is_float leading dot" rc str::is_float ".25"
ok "is_float trailing dot" rc str::is_float "1."
no "is_float dot false" rc str::is_float "."
no "is_float exponent unsupported false" rc str::is_float "1e3"
ok "is_bool true" rc str::is_bool "true"
ok "is_bool on uppercase" rc str::is_bool "ON"
ok "is_bool zero" rc str::is_bool "0"
no "is_bool maybe false" rc str::is_bool "maybe"
no "is_bool empty false" rc str::is_bool ""
ok "is_email basic" rc str::is_email "a.b+c@example.co"
ok "is_email subdomain" rc str::is_email "x@y.example.com"
no "is_email no tld false" rc str::is_email "a@b"
no "is_email spaces false" rc str::is_email "a b@example.com"
ok "is_url http" rc str::is_url "http://example.com/a?b=c"
ok "is_url https" rc str::is_url "https://example.com"
no "is_url ftp false" rc str::is_url "ftp://example.com"
no "is_url spaces false" rc str::is_url "https://example.com/a b"
ok "is_slug simple" rc str::is_slug "abc-123-x"
no "is_slug uppercase false" rc str::is_slug "Abc"
no "is_slug leading dash false" rc str::is_slug "-abc"
no "is_slug trailing dash false" rc str::is_slug "abc-"
ok "is_identifier simple" rc str::is_identifier "_abc123"
ok "is_identifier caps" rc str::is_identifier "Abc_123"
no "is_identifier leading digit false" rc str::is_identifier "1abc"
no "is_identifier dash false" rc str::is_identifier "a-b"

section "escaping"
eq "escape_sed slash amp backslash" 'a\/b\&c\\d' "$(out str::escape_sed 'a/b&c\d')"
regex_raw='a.b*c+d?e[f]g^h$i(j)k{l}m|n\o'
regex_escaped="$(out str::escape_regex "${regex_raw}")"
if [[ "${regex_raw}" =~ ${regex_escaped} ]]; then
    pass "escape_regex literal matches raw"
else
    fail "escape_regex literal matches raw" "regex matches raw" "regex did not match"
fi
no "escape_regex literal does not overmatch" rc bash -c 'raw="axb"; escaped="a\.b"; [[ "$raw" =~ $escaped ]]'
json_in=$'a"b\\c\b\f\n\r\t'
json_want='a\"b\\c\b\f\n\r\t'
eq "escape_json specials" "${json_want}" "$(out str::escape_json "${json_in}")"
ctrl_in="$(printf 'a\001b')"
ctrl_want='a\u0001b'
eq "escape_json control U+0001" "${ctrl_want}" "$(out str::escape_json "${ctrl_in}")"
eq "json_quote quoted" '"a\"b"' "$(out str::json_quote 'a"b')"
eq "json_quote empty" '""' "$(out str::json_quote '')"

section "properties / invariants"
sample="  HelloWorld-42_test  "
trimmed="$(out str::trim "${sample}")"
eq "property trim idempotent" "${trimmed}" "$(out str::trim "${trimmed}")"
normalized="$(out str::normalize "${sample}")"
eq "property normalize idempotent" "${normalized}" "$(out str::normalize "${normalized}")"
lowered="$(out str::lower "${sample}")"
eq "property lower idempotent" "${lowered}" "$(out str::lower "${lowered}")"
uppered="$(out str::upper "${sample}")"
eq "property upper idempotent" "${uppered}" "$(out str::upper "${uppered}")"
snake="$(out str::snake "${sample}")"
eq "property snake stable" "${snake}" "$(out str::snake "${snake}")"
kebab="$(out str::kebab "${sample}")"
eq "property kebab stable" "${kebab}" "$(out str::kebab "${kebab}")"
eq "property ensure_prefix idempotent" "pre-value" "$(out str::ensure_prefix "$(out str::ensure_prefix "value" "pre-")" "pre-")"
eq "property ensure_suffix idempotent" "value-end" "$(out str::ensure_suffix "$(out str::ensure_suffix "value" "-end")" "-end")"
eq "property remove_prefix inverse simple" "value" "$(out str::remove_prefix "$(out str::ensure_prefix "value" "pre-")" "pre-")"
eq "property remove_suffix inverse simple" "value" "$(out str::remove_suffix "$(out str::ensure_suffix "value" "-end")" "-end")"

section "summary"
printf '\nTOTAL=%s PASS=%s FAIL=%s\n' "${TOTAL}" "${PASS}" "${FAIL}"

if (( FAIL > 0 )); then
    printf '%sBROKEN: fix failures above.%s\n' "${red}" "${reset}" >&2
    exit 1
fi

printf '%sGAME OVER: string.sh passed the savage suite.%s\n' "${green}" "${reset}"
exit 0
