#!/usr/bin/env bash
# shellcheck shell=bash

set -u
set -o pipefail

TARGET="${1:-tool/parts/builtin/map.sh}"

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

dump_map () {

    local name="${1:-}" key=""

    local -n ref="${name}"

    for key in "${!ref[@]}"; do
        printf '<%s>=<%s>\n' "${key}" "${ref[$key]}"
    done | LC_ALL=C sort

}

dump_keys0 () {

    local name="${1:-}" key=""

    while IFS= read -r -d '' key; do
        printf '<%s>\n' "${key}"
    done < <(map::keys0 "${name}") | LC_ALL=C sort

}

dump_values0 () {

    local name="${1:-}" value=""

    while IFS= read -r -d '' value; do
        printf '<%s>\n' "${value}"
    done < <(map::values0 "${name}") | LC_ALL=C sort

}

dump_items0 () {

    local name="${1:-}" key="" value=""

    while IFS= read -r -d '' key && IFS= read -r -d '' value; do
        printf '[%q]=[%q]\n' "${key}" "${value}"
    done < <(map::items0 "${name}") | LC_ALL=C sort

}

same_map () {

    local name="${1:-}" want="${2:-}" got=""

    got="$(dump_map "${name}")"
    eq "${name}" "${want}" "${got}"

}

same_keys0 () {

    local name="${1:-}" want="${2:-}" got=""

    got="$(dump_keys0 "${name}")"
    eq "${name}:keys0" "${want}" "${got}"

}

same_values0 () {

    local name="${1:-}" want="${2:-}" got=""

    got="$(dump_values0 "${name}")"
    eq "${name}:values0" "${want}" "${got}"

}

same_items0 () {

    local name="${1:-}" want="${2:-}" got=""

    got="$(dump_items0 "${name}")"
    eq "${name}:items0" "${want}" "${got}"

}

if [[ ! -r "${TARGET}" ]]; then
    printf '%s[ERR]%s target not readable: %s\n' "${red}" "${reset}" "${TARGET}" >&2
    exit 2
fi

source "${TARGET}"

section "existence / public api"

required=(
    map::init
    map::valid
    map::len
    map::empty
    map::filled
    map::has
    map::get
    map::set
    map::put
    map::del
    map::delete
    map::set_once
    map::replace
    map::clear
    map::keys0
    map::values0
    map::items0
    map::keys
    map::values
    map::items
    map::merge
    map::concat
    map::copy
    map::only
    map::without
    map::each
    map::map
    map::filter
    map::all
    map::any
    map::none
    map::print
    map::str
    map::from
    map::from_pairs
    map::from_lines
)

for fn in "${required[@]}"; do
    ok "function exists: ${fn}" declare -F "${fn}"
done

section "init / valid / invalid names"

unset m scalar __bad 2>/dev/null || true

ok "init creates assoc map" rc map::init m
ok "valid existing assoc map" rc map::valid m
eq "len empty" "0" "$(out map::len m)"
ok "empty true" rc map::empty m
no "filled false" rc map::filled m

scalar="x"
no "valid scalar false" rc map::valid scalar
no "init scalar false" rc map::init scalar
no "init invalid empty" rc map::init ""
no "init invalid starts digit" rc map::init "1bad"
no "init invalid dash" rc map::init "bad-name"
no "valid missing false" rc map::valid missing_map_name

section "set / put / get / has / len / empty / filled"

ok "set name" rc map::set m name "Gun"
ok "set empty value" rc map::set m empty ""
ok "set key with spaces" rc map::set m "hello world" "space"
ok "set key with star" rc map::set m "*" "star"
ok "set key with equals" rc map::set m "a=b" "eq"
no "set empty key fails" rc map::set m "" "x"

eq "get name" "Gun" "$(out map::get m name)"
eq "get empty value" "" "$(out map::get m empty DEF)"
eq "get missing default" "DEF" "$(out map::get m missing DEF)"
eq "get empty key returns default" "DEF" "$(out map::get m "" DEF)"

ok "has name" rc map::has m name
ok "has empty value key" rc map::has m empty
no "has missing false" rc map::has m missing
no "has empty key false" rc map::has m ""

eq "len after set" "5" "$(out map::len m)"
no "empty false" rc map::empty m
ok "filled true" rc map::filled m

ok "put alias set" rc map::put m role admin
eq "put alias get" "admin" "$(out map::get m role)"

section "set_once / replace / del / delete / clear"

map::from_pairs once a 1 b 2

ok "set_once existing returns ok" rc map::set_once once a 999
eq "set_once existing unchanged" "1" "$(out map::get once a)"
ok "set_once missing writes" rc map::set_once once c 3
eq "set_once missing value" "3" "$(out map::get once c)"
no "set_once empty key fails" rc map::set_once once "" x

ok "replace existing" rc map::replace once b 22
eq "replace existing value" "22" "$(out map::get once b)"
no "replace missing fails" rc map::replace once z 9
no "replace empty key fails" rc map::replace once "" x

ok "del existing" rc map::del once c
no "del removed missing" rc map::has once c
no "del missing fails" rc map::del once z
no "del empty key fails" rc map::del once ""

ok "delete alias existing" rc map::delete once b
no "delete removed missing" rc map::has once b

ok "clear map" rc map::clear once
eq "clear len zero" "0" "$(out map::len once)"
ok "clear empty true" rc map::empty once

section "from_pairs"

ok "from_pairs creates map" rc map::from_pairs fp \
    name "Ali" \
    email "a@test.com" \
    empty "" \
    "space key" "space value" \
    "*" "star"

same_map fp $'<*>=<star>\n<email>=<a@test.com>\n<empty>=<>\n<name>=<Ali>\n<space key>=<space value>'

ok "from_pairs duplicate last wins" rc map::from_pairs dup a 1 a 2 b 3
eq "duplicate value" "2" "$(out map::get dup a)"
eq "duplicate len" "2" "$(out map::len dup)"

ok "from_pairs zero pairs creates empty" rc map::from_pairs empty_pairs
eq "from_pairs zero len" "0" "$(out map::len empty_pairs)"

no "from_pairs odd args fails" rc map::from_pairs bad_pairs a 1 b
no "from_pairs empty key fails" rc map::from_pairs bad_pairs2 "" x

section "from / from_lines / str"

ok "from default newline" rc map::from mf $'a=1\nb=2\nempty=\nignored\nc=3'
same_map mf $'<a>=<1>\n<b>=<2>\n<c>=<3>\n<empty>=<>'

ok "from custom separators" rc map::from mf2 "a:1;b:2;empty:;bad;c:3" ";" ":"
same_map mf2 $'<a>=<1>\n<b>=<2>\n<c>=<3>\n<empty>=<>'

ok "from duplicate last wins" rc map::from mf3 "a=1,a=2,b=3" "," "="
eq "from duplicate value" "2" "$(out map::get mf3 a)"

ok "from trailing item sep" rc map::from mf4 "a=1,b=2," "," "="
same_map mf4 $'<a>=<1>\n<b>=<2>'

ok "from empty string creates empty" rc map::from mf_empty ""
eq "from empty len" "0" "$(out map::len mf_empty)"

no "from empty item_sep fails" rc map::from mf_bad "a=1" "" "="
no "from empty pair_sep fails" rc map::from mf_bad "a=1" "," ""
no "from empty key fails" rc map::from mf_bad "=x" "," "="

ok "from_lines default" rc map::from_lines ml < <(printf '%s\n' "a=1" "b=2" "ignored" "empty=")
same_map ml $'<a>=<1>\n<b>=<2>\n<empty>=<>'

ok "from_lines custom sep" rc map::from_lines ml2 ":" < <(printf '%s\n' "a:1" "b:2" "bad" "empty:")
same_map ml2 $'<a>=<1>\n<b>=<2>\n<empty>=<>'

ok "from_lines no final newline" rc map::from_lines ml3 < <(printf '%s' "last=value")
eq "from_lines no final newline value" "value" "$(out map::get ml3 last)"

no "from_lines empty sep fails" rc map::from_lines ml_bad ""
no "from_lines empty key fails" rc map::from_lines ml_bad2 < <(printf '%s\n' "=x")

map::from_pairs str_src a 1 b 2 empty ""
text="$(out map::str str_src "," "=")"
ok "str returns parseable text" rc map::from str_dst "${text}" "," "="
same_map str_dst $'<a>=<1>\n<b>=<2>\n<empty>=<>'

text2="$(out map::str str_src $'\n' "=")"
ok "str default newline parseable" rc map::from str_dst2 "${text2}"
same_map str_dst2 $'<a>=<1>\n<b>=<2>\n<empty>=<>'

no "str empty item sep fails" rc map::str str_src "" "="
no "str empty pair sep fails" rc map::str str_src "," ""

section "keys0 / values0 / items0"

map::from_pairs kv \
    b 2 \
    a 1 \
    c 3 \
    empty "" \
    "space key" "space value" \
    "*" "star"

same_keys0 kv $'<*>\n<a>\n<b>\n<c>\n<empty>\n<space key>'
same_values0 kv $'<1>\n<2>\n<3>\n<>\n<space value>\n<star>'
same_items0 kv $'[\\*]=[star]\n[a]=[1]\n[b]=[2]\n[c]=[3]\n[empty]=[\'\']\n[space\\ key]=[space\\ value]'

map::from_pairs weird $'line\nkey' $'line\nvalue' $'tab\tkey' $'tab\tvalue'
ok "keys0 supports newline key" rc map::has weird $'line\nkey'
ok "values0 supports newline value" rc map::has weird $'tab\tkey'
same_items0 weird $'[$\'line\\nkey\']=[$\'line\\nvalue\']\n[$\'tab\\tkey\']=[$\'tab\\tvalue\']'

section "keys / values / items / print"

map::from_pairs printable b 2 a 1 c 3

keys_text="$(out map::keys printable | LC_ALL=C sort)"
eq "keys printable" $'a\nb\nc' "${keys_text}"

values_text="$(out map::values printable | LC_ALL=C sort)"
eq "values printable" $'1\n2\n3' "${values_text}"

items_text="$(out map::items printable | LC_ALL=C sort)"
eq "items printable" $'a\t1\nb\t2\nc\t3' "${items_text}"

print_text="$(out map::print printable | LC_ALL=C sort)"
eq "print alias items" "${items_text}" "${print_text}"

section "copy / merge / concat"

map::from_pairs src a 1 b 2 empty ""
ok "copy src dst" rc map::copy src dst
same_map dst $'<a>=<1>\n<b>=<2>\n<empty>=<>'

ok "copy is independent" rc map::set dst a 999
eq "copy changed dst" "999" "$(out map::get dst a)"
eq "copy source unchanged" "1" "$(out map::get src a)"

ok "copy to self safe" rc map::copy src src
same_map src $'<a>=<1>\n<b>=<2>\n<empty>=<>'

map::from_pairs left a 1 b 2
map::from_pairs right b 22 c 3
ok "merge overwrites and adds" rc map::merge left right
same_map left $'<a>=<1>\n<b>=<22>\n<c>=<3>'
same_map right $'<b>=<22>\n<c>=<3>'

map::from_pairs self_merge a 1 b 2
ok "merge self safe" rc map::merge self_merge self_merge
same_map self_merge $'<a>=<1>\n<b>=<2>'

map::from_pairs concat_left a 1
map::from_pairs concat_right b 2
ok "concat alias merge" rc map::concat concat_left concat_right
same_map concat_left $'<a>=<1>\n<b>=<2>'

section "only / without"

map::from_pairs user \
    name Ali \
    email a@test.com \
    password secret \
    token xyz \
    empty ""

ok "only selected keys" rc map::only user public name email missing empty ""
same_map public $'<email>=<a@test.com>\n<empty>=<>\n<name>=<Ali>'

same_map user $'<email>=<a@test.com>\n<empty>=<>\n<name>=<Ali>\n<password>=<secret>\n<token>=<xyz>'

ok "only self-reference safe" rc map::only user user name email
same_map user $'<email>=<a@test.com>\n<name>=<Ali>'

map::from_pairs secret_user \
    name Ali \
    email a@test.com \
    password secret \
    token xyz \
    empty ""

ok "without removes selected" rc map::without secret_user safe_user password token missing ""
same_map safe_user $'<email>=<a@test.com>\n<empty>=<>\n<name>=<Ali>'

same_map secret_user $'<email>=<a@test.com>\n<empty>=<>\n<name>=<Ali>\n<password>=<secret>\n<token>=<xyz>'

ok "without self-reference safe" rc map::without secret_user secret_user password token
same_map secret_user $'<email>=<a@test.com>\n<empty>=<>\n<name>=<Ali>'

section "callbacks each / map / filter / all / any / none"

cb_seen=()

cb_collect () {

    cb_seen+=( "${1}=${2}" )

}

cb_upper_value () {

    printf '%s' "${2^^}"

}

cb_keep_nonempty () {

    [[ -n "${2:-}" ]]

}

cb_key_is_name () {

    [[ "${1:-}" == "name" ]]

}

cb_value_is_admin () {

    [[ "${2:-}" == "admin" ]]

}

cb_fail_on_email () {

    [[ "${1:-}" != "email" ]]

}

cb_never () {

    return 1

}

map::from_pairs cb \
    name ali \
    email a@test.com \
    role admin \
    empty ""

ok "each collect" rc map::each cb cb_collect

seen_sorted="$(printf '%s\n' "${cb_seen[@]}" | LC_ALL=C sort)"
eq "each collected all" $'email=a@test.com\nempty=\nname=ali\nrole=admin' "${seen_sorted}"

no "each stops on callback failure" rc map::each cb cb_fail_on_email

ok "map upper values" rc map::map cb cb_upper cb_upper_value
same_map cb_upper $'<email>=<A@TEST.COM>\n<empty>=<>\n<name>=<ALI>\n<role>=<ADMIN>'

ok "map self-reference safe" rc map::map cb cb cb_upper_value
same_map cb $'<email>=<A@TEST.COM>\n<empty>=<>\n<name>=<ALI>\n<role>=<ADMIN>'

map::from_pairs cb2 \
    name ali \
    email a@test.com \
    role admin \
    empty ""

ok "filter nonempty values" rc map::filter cb2 cb_filtered cb_keep_nonempty
same_map cb_filtered $'<email>=<a@test.com>\n<name>=<ali>\n<role>=<admin>'

ok "filter self-reference safe" rc map::filter cb2 cb2 cb_keep_nonempty
same_map cb2 $'<email>=<a@test.com>\n<name>=<ali>\n<role>=<admin>'

no "missing callback each fails" rc map::each cb2 missing_callback
no "missing callback map fails" rc map::map cb2 out_missing missing_callback
no "missing callback filter fails" rc map::filter cb2 out_missing missing_callback

map::from_pairs pred name ali role admin
ok "all nonempty true" rc map::all pred cb_keep_nonempty

map::from_pairs pred2 name ali empty ""
no "all nonempty false" rc map::all pred2 cb_keep_nonempty

ok "any key is name true" rc map::any pred2 cb_key_is_name
no "any never false" rc map::any pred2 cb_never

ok "none never true" rc map::none pred2 cb_never
no "none key is name false" rc map::none pred2 cb_key_is_name

ok "any value is admin true" rc map::any pred cb_value_is_admin

section "failure paths / non maps"

bad_scalar="x"

no "len scalar fails" rc map::len bad_scalar
no "empty scalar fails" rc map::empty bad_scalar
no "filled scalar fails" rc map::filled bad_scalar
no "has scalar fails" rc map::has bad_scalar a
no "get scalar fails" rc map::get bad_scalar a
no "set scalar fails" rc map::set bad_scalar a 1
no "del scalar fails" rc map::del bad_scalar a
no "set_once scalar fails" rc map::set_once bad_scalar a 1
no "replace scalar fails" rc map::replace bad_scalar a 1
no "clear scalar fails" rc map::clear bad_scalar
no "keys0 scalar fails" rc map::keys0 bad_scalar
no "values0 scalar fails" rc map::values0 bad_scalar
no "items0 scalar fails" rc map::items0 bad_scalar
no "copy scalar fails" rc map::copy bad_scalar out_map
no "merge scalar left fails" rc map::merge bad_scalar fp
no "merge scalar right fails" rc map::merge fp bad_scalar
no "only scalar fails" rc map::only bad_scalar out_map a
no "without scalar fails" rc map::without bad_scalar out_map a
no "each scalar fails" rc map::each bad_scalar cb_collect
no "map scalar fails" rc map::map bad_scalar out_map cb_upper_value
no "filter scalar fails" rc map::filter bad_scalar out_map cb_keep_nonempty
no "all scalar fails" rc map::all bad_scalar cb_keep_nonempty
no "any scalar fails" rc map::any bad_scalar cb_keep_nonempty
no "str scalar fails" rc map::str bad_scalar

no "copy bad target fails" rc map::copy fp "bad-name"
no "only bad target fails" rc map::only fp "bad-name" a
no "without bad target fails" rc map::without fp "bad-name" a
no "map bad target fails" rc map::map fp "bad-name" cb_upper_value
no "filter bad target fails" rc map::filter fp "bad-name" cb_keep_nonempty

section "property / invariants"

map::from_pairs prop \
    "  a  " "  1  " \
    "b/c" "x/y" \
    "*" "star" \
    "z z" "space" \
    empty ""

before="$(dump_map prop)"

ok "copy invariant" rc map::copy prop prop_copy
eq "copy dump equals original" "${before}" "$(dump_map prop_copy)"

text_prop="$(out map::str prop $'\037' $'\036')"
ok "str/from roundtrip with rare separators" rc map::from prop_round "${text_prop}" $'\037' $'\036'
eq "roundtrip dump equals original" "${before}" "$(dump_map prop_round)"

ok "merge empty into prop" rc map::from_pairs empty_merge
ok "merge empty does not change" rc map::merge prop empty_merge
eq "merge empty invariant" "${before}" "$(dump_map prop)"

ok "only all keys equals original" rc map::only prop prop_only "  a  " "b/c" "*" "z z" empty
eq "only all invariant" "${before}" "$(dump_map prop_only)"

ok "without no keys equals original" rc map::without prop prop_without
eq "without none invariant" "${before}" "$(dump_map prop_without)"

section "transactional from failures"

map::from_pairs tx_keep a 1 b 2
before="$(dump_map tx_keep)"
no "from_pairs failure keeps old map" rc map::from_pairs tx_keep a 1 "" bad b 2
eq "from_pairs transactional invariant" "${before}" "$(dump_map tx_keep)"

map::from_pairs tx_from a old
before="$(dump_map tx_from)"
no "from failure keeps old map" rc map::from tx_from "x=1,=bad,y=2" "," "="
eq "from transactional invariant" "${before}" "$(dump_map tx_from)"

map::from_pairs tx_lines a old
before="$(dump_map tx_lines)"
no "from_lines failure keeps old map" rc map::from_lines tx_lines < <(printf '%s\n' "x=1" "=bad" "y=2")
eq "from_lines transactional invariant" "${before}" "$(dump_map tx_lines)"

section "unset weird keys"

map::from_pairs weird_del \
    'a]b' 1 \
    'x y' 2 \
    '*' 3 \
    $'line\nkey' 4

ok "del key with bracket" rc map::del weird_del 'a]b'
no "bracket key removed" rc map::has weird_del 'a]b'

ok "del key with space" rc map::del weird_del 'x y'
no "space key removed" rc map::has weird_del 'x y'

ok "del key with star" rc map::del weird_del '*'
no "star key removed" rc map::has weird_del '*'

ok "del key with newline" rc map::del weird_del $'line\nkey'
no "newline key removed" rc map::has weird_del $'line\nkey'

section "transactional failures"

map::from_pairs tx_keep a 1 b 2
before="$(dump_map tx_keep)"
no "from_pairs failure keeps old map" rc map::from_pairs tx_keep a 1 "" bad b 2
eq "from_pairs transactional invariant" "${before}" "$(dump_map tx_keep)"

map::from_pairs tx_from a old
before="$(dump_map tx_from)"
no "from failure keeps old map" rc map::from tx_from "x=1,=bad,y=2" "," "="
eq "from transactional invariant" "${before}" "$(dump_map tx_from)"

map::from_pairs tx_lines a old
before="$(dump_map tx_lines)"
no "from_lines failure keeps old map" rc map::from_lines tx_lines < <(printf '%s\n' "x=1" "=bad" "y=2")
eq "from_lines transactional invariant" "${before}" "$(dump_map tx_lines)"

section "delete weird keys"

map::from_pairs weird_del \
    'a]b' 1 \
    'x y' 2 \
    '*' 3 \
    '$key' 4 \
    $'line\nkey' 5

ok "del bracket key" rc map::del weird_del 'a]b'
no "bracket key removed" rc map::has weird_del 'a]b'

ok "del space key" rc map::del weird_del 'x y'
no "space key removed" rc map::has weird_del 'x y'

ok "del star key" rc map::del weird_del '*'
no "star key removed" rc map::has weird_del '*'

ok "del dollar key" rc map::del weird_del '$key'
no "dollar key removed" rc map::has weird_del '$key'

ok "del newline key" rc map::del weird_del $'line\nkey'
no "newline key removed" rc map::has weird_del $'line\nkey'

section "result"

printf '\n%s== result ==%s\n' "${yellow}" "${reset}"
printf 'total: %s\n' "${TOTAL}"
printf '%spass : %s%s\n' "${green}" "${PASS}" "${reset}"
printf '%sfail : %s%s\n' "${red}" "${FAIL}" "${reset}"

if (( FAIL > 0 )); then
    exit 1
fi

exit 0
